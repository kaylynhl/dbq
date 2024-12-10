exception RuntimeError of string

(* [StringTable] is a hash table whose keys are [string]s. *)
module StringTable = Hashtbl.Make (String)

(* The default size of hash table that will be allocated during program
   evaluation. *)
let default_size = 16

(* The type of a table value in the language. *)
type table = string list list

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

  open Ast

  let rec eval_prog = function
    | cmd :: cmds ->
        eval_command cmd;
        eval_prog cmds
    | [] -> ()

  and eval_command = function
    | Print t -> Csv.print_readable (eval_texpr t)
    | Assign (x, t) -> StringTable.add state x (eval_texpr t)
    | Save (t, f) -> (
        try t |> eval_texpr |> Csv.save f
        with Sys_error msg -> raise (RuntimeError msg))

  and eval_texpr = function
    | Var x -> begin
        match StringTable.find_opt state x with
        | None -> raise (RuntimeError ("unbound variable: " ^ x))
        | Some t -> t
      end
    | Load f -> begin
        try
          let table = Csv.load f in
          match table with
          | [] -> raise (RuntimeError "CSV file is empty.")
          | header :: rows ->
              (* Check for non-unique column names *)
              let unique_headers = List.sort_uniq String.compare header in
              if List.length unique_headers <> List.length header then
                raise
                  (RuntimeError "CSV file has non-unique column names.");

              (* Check for rectangularity *)
              if not (Csv.is_square table) then
                raise (RuntimeError "CSV file is not rectangular.");

              table
        with Sys_error msg ->
          raise (RuntimeError ("Unable to read file - " ^ msg))
      end
end

let eval_prog prog =
  let module PE = ProgramEvaluator () in
  PE.eval_prog prog
