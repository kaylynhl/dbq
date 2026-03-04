exception RuntimeError of string

(* [StringTable] is a hash table whose keys are [string]s. *)
module StringTable = Hashtbl.Make (String)

(* The default size of hash table that will be allocated during program
   evaluation. *)
let default_size = 16

(* The type of a table value in the language. *)
type table = string list list

open Ast

let runtime_error msg = raise (RuntimeError msg)

let split_table = function
  | [] -> runtime_error "internal invariant violated: empty table"
  | header :: rows -> (header, rows)

let find_index_exn ~not_found_msg xs target =
  let rec loop i = function
    | [] -> runtime_error not_found_msg
    | x :: tl -> if x = target then i else loop (i + 1) tl
  in
  loop 0 xs

let ensure_unique_names names ~err_msg =
  let unique_names = List.sort_uniq String.compare names in
  if List.length unique_names <> List.length names then runtime_error err_msg

let build_join_index ~key_index rows =
  let index = StringTable.create default_size in
  List.iter
    (fun row ->
      let key = List.nth row key_index in
      let prev = Option.value ~default:[] (StringTable.find_opt index key) in
      StringTable.replace index key (row :: prev))
    rows;
  StringTable.iter (fun key rs -> StringTable.replace index key (List.rev rs)) index;
  index

(* A functor that can be used to evaluate a program. Every program should be
   evaluated with a distinct program evaluator, otherwise, their side effects
   could interfere. *)
module ProgramEvaluator () : sig
  val eval_prog : Ast.command list -> unit
  val eval_command : Ast.command -> unit
  val eval_texpr : Ast.table_expr -> table
end = struct
  (* The [state] of evaluation is the mapping from variable names to the table
     value they contain. *)
  let state : table StringTable.t = StringTable.create default_size

  let rec eval_prog = function
    | cmd :: cmds ->
        eval_command cmd;
        eval_prog cmds
    | [] -> ()

  and eval_command = function
    | Print t -> Csv.print_readable (eval_texpr t)
    | Assign (x, t) -> StringTable.replace state x (eval_texpr t)
    | Save (t, f) -> (
        try t |> eval_texpr |> Csv.save f
        with Sys_error msg -> runtime_error msg)

  and eval_texpr = function
    | Var x -> begin
        match StringTable.find_opt state x with
        | None -> runtime_error ("unbound variable: " ^ x)
        | Some t -> t
      end
    | Load f -> (
        try
          let table = Csv.load f in
          let header =
            match table with
            | [] -> runtime_error "CSV file is empty."
            | header :: _ -> header
          in

          (* Check for non-unique column names. *)
          ensure_unique_names header ~err_msg:"CSV file has non-unique column names.";

          (* Check for rectangularity. *)
          if not (Csv.is_square table) then
            runtime_error "CSV file is not rectangular.";

          table
        with Sys_error msg -> runtime_error ("Unable to read file - " ^ msg))
    | Project (names, t) ->
        let table = eval_texpr t in
        let header, rows = split_table table in

        ensure_unique_names names ~err_msg:"Non-unique column names.";

        let indices =
          List.map
            (fun name ->
              let idx =
                find_index_exn header name
                  ~not_found_msg:("Column " ^ name ^ " does not exist.")
              in
              (name, idx))
            names
        in
        let project_row row = List.map (fun (_, idx) -> List.nth row idx) indices in
        let projected_rows = List.map project_row rows in
        let projected_header = List.map fst indices in
        projected_header :: projected_rows
    | Join (t1, t2, key) ->
        let table1 = eval_texpr t1 in
        let table2 = eval_texpr t2 in
        let header1, rows1 = split_table table1 in
        let header2, rows2 = split_table table2 in
        let key_index1 =
          find_index_exn header1 key
            ~not_found_msg:("Key column " ^ key ^ " not found in first table")
        in
        let key_index2 =
          find_index_exn header2 key
            ~not_found_msg:("Key column " ^ key ^ " not found in second table")
        in
        let index2 = build_join_index ~key_index:key_index2 rows2 in
        let join_with_matches row1 =
          let key_val = List.nth row1 key_index1 in
          let matches = Option.value ~default:[] (StringTable.find_opt index2 key_val) in
          List.map
            (fun row2 ->
              List.append row1 (List.filteri (fun i _ -> i <> key_index2) row2))
            matches
        in
        let joined_rows = List.concat_map join_with_matches rows1 in
        let new_header = List.append header1 (List.filter (fun col -> col <> key) header2) in
        new_header :: joined_rows
    | Rename (old_name, new_name, t) ->
        let table = eval_texpr t in
        let header, rows = split_table table in

        if List.mem new_name header then
          runtime_error ("Column " ^ new_name ^ " already exists.")
        else
          let new_header =
            List.map (fun col -> if col = old_name then new_name else col) header
          in
          new_header :: rows
end

let eval_prog prog =
  let module PE = ProgramEvaluator () in
  PE.eval_prog prog
