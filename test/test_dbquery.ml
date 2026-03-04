open Dbquery

let fail fmt = Printf.ksprintf failwith fmt

let with_temp_file ~contents k =
  let path = Filename.temp_file "dbquery-test-" ".csv" in
  Fun.protect
    ~finally:(fun () -> if Sys.file_exists path then Sys.remove path)
    (fun () ->
      let oc = open_out path in
      output_string oc contents;
      close_out oc;
      k path)

let rec find_repo_root dir depth =
  let data_dir = Filename.concat dir "data" in
  if Sys.file_exists data_dir && Sys.is_directory data_dir then dir
  else if depth = 0 then fail "unable to locate repository root from %s" dir
  else
    let parent = Filename.dirname dir in
    if String.equal parent dir then
      fail "unable to locate repository root from %s" dir
    else find_repo_root parent (depth - 1)

let repo_root = find_repo_root (Sys.getcwd ()) 10
let data_file name = Filename.concat (Filename.concat repo_root "data") name

let eval_program program =
  program |> Frontend.parse |> Evaluator.eval_prog

let expect_runtime_error ?(prefix = None) thunk =
  try
    thunk ();
    fail "expected RuntimeError, but evaluation succeeded"
  with
  | Evaluator.RuntimeError msg -> begin
      match prefix with
      | None -> ()
      | Some p ->
          let plen = String.length p in
          if String.length msg < plen || String.sub msg 0 plen <> p then
            fail "expected RuntimeError prefix %S, got %S" p msg
    end

let expect_syntax_error thunk =
  try
    thunk ();
    fail "expected SyntaxError, but parsing succeeded"
  with Frontend.SyntaxError _ -> ()

let assert_table_equal ~name expected actual =
  if expected <> actual then
    fail "table mismatch in %s" name

let test_parse_success () =
  let prog = "a := load \"data/chem_grades.csv\"; b := a;" in
  match Frontend.parse prog with
  | [ Ast.Assign ("a", Ast.Load _); Ast.Assign ("b", Ast.Var "a") ] -> ()
  | _ -> fail "unexpected AST shape for parse success test"

let test_parse_syntax_error () =
  expect_syntax_error (fun () -> ignore (Frontend.parse "a := load \"x.csv\""))

let test_runtime_unbound_variable () =
  expect_runtime_error ~prefix:(Some "unbound variable: b") (fun () ->
      eval_program "a := b;")

let test_runtime_missing_file () =
  expect_runtime_error ~prefix:(Some "Unable to read file -") (fun () ->
      eval_program "a := load \"this_file_does_not_exist.csv\";")

let test_runtime_empty_csv () =
  with_temp_file ~contents:"" (fun empty_csv ->
      let program = Printf.sprintf "a := load %S;" empty_csv in
      expect_runtime_error ~prefix:(Some "CSV file is empty.") (fun () ->
          eval_program program))

let test_runtime_non_rectangular_csv () =
  with_temp_file ~contents:"a,b\n1\n" (fun bad_csv ->
      let program = Printf.sprintf "a := load %S;" bad_csv in
      expect_runtime_error ~prefix:(Some "CSV file is not rectangular.") (fun () ->
          eval_program program))

let test_runtime_duplicate_projection_columns () =
  let program =
    Printf.sprintf "a := load %S; b := project [\"ID\"; \"ID\"] from a;"
      (data_file "chem_grades.csv")
  in
  expect_runtime_error ~prefix:(Some "Non-unique column names.") (fun () ->
      eval_program program)

let test_runtime_join_key_missing_first_table () =
  let program =
    Printf.sprintf
      "a := load %S; b := load %S; c := join a with b on \"lab1\";"
      (data_file "join1_table1.csv")
      (data_file "join1_table2.csv")
  in
  expect_runtime_error
    ~prefix:(Some "Key column lab1 not found in first table")
    (fun () -> eval_program program)

let test_runtime_join_key_missing_second_table () =
  let program =
    Printf.sprintf
      "a := load %S; b := load %S; c := join a with b on \"exam1\";"
      (data_file "join1_table1.csv")
      (data_file "join1_table2.csv")
  in
  expect_runtime_error
    ~prefix:(Some "Key column exam1 not found in second table")
    (fun () -> eval_program program)

let test_runtime_rename_to_existing_column () =
  let program =
    Printf.sprintf "a := load %S; b := rename \"ID\" to \"exam1\" from a;"
      (data_file "chem_grades.csv")
  in
  expect_runtime_error ~prefix:(Some "Column exam1 already exists.") (fun () ->
      eval_program program)

let test_project_output_is_deterministic () =
  with_temp_file ~contents:"" (fun out_csv ->
      let program =
        Printf.sprintf
          "a := load %S; b := project [\"ID\"; \"hw2\"; \"hw1\"] from a; save b \
           %S;"
          (data_file "chem_grades.csv")
          out_csv
      in
      eval_program program;
      let expected =
        [
          [ "ID"; "hw2"; "hw1" ];
          [ "al912"; "90"; "83" ];
          [ "kfs12"; "95"; "70" ];
          [ "lad339"; "98"; "91" ];
          [ "bk93"; "87"; "93" ];
        ]
      in
      let actual = Csv.load out_csv in
      assert_table_equal ~name:"project output" expected actual)

let test_join_output_is_deterministic () =
  with_temp_file ~contents:"" (fun out_csv ->
      let program =
        Printf.sprintf
          "a := load %S; b := load %S; c := join a with b on \"ID\"; save c %S;"
          (data_file "join1_table1.csv")
          (data_file "join1_table2.csv")
          out_csv
      in
      eval_program program;
      let expected =
        [
          [ "ID"; "exam1"; "exam2"; "hw1"; "hw2"; "lab1"; "lab2" ];
          [ "al912"; "97"; "87"; "83"; "90"; "2"; "1" ];
          [ "kfs12"; "91"; "84"; "70"; "95"; "2"; "2" ];
          [ "lad339"; "83"; "95"; "91"; "98"; "1"; "2" ];
          [ "bk93"; "91"; "92"; "93"; "87"; "2"; "2" ];
        ]
      in
      let actual = Csv.load out_csv in
      assert_table_equal ~name:"join output" expected actual)

let tests =
  [
    ("parse success", test_parse_success);
    ("parse syntax error", test_parse_syntax_error);
    ("runtime unbound variable", test_runtime_unbound_variable);
    ("runtime missing file", test_runtime_missing_file);
    ("runtime empty csv", test_runtime_empty_csv);
    ("runtime non-rectangular csv", test_runtime_non_rectangular_csv);
    ( "runtime duplicate projection columns",
      test_runtime_duplicate_projection_columns );
    ( "runtime join key missing in first table",
      test_runtime_join_key_missing_first_table );
    ( "runtime join key missing in second table",
      test_runtime_join_key_missing_second_table );
    ("runtime rename to existing column", test_runtime_rename_to_existing_column);
    ("project output deterministic", test_project_output_is_deterministic);
    ("join output deterministic", test_join_output_is_deterministic);
  ]

let () =
  let failures = ref [] in
  List.iter
    (fun (name, test_fn) ->
      try test_fn () with
      | exn -> failures := (name, Printexc.to_string exn) :: !failures)
    tests;
  match List.rev !failures with
  | [] ->
      Printf.printf "All %d tests passed.\n" (List.length tests);
      ()
  | failures ->
      List.iter
        (fun (name, err) -> Printf.eprintf "FAIL: %s\n  %s\n" name err)
        failures;
      exit 1
