open Dbquery

let () =
  if Array.length Sys.argv = 2 then
    try Sys.argv.(1) |> Frontend.parse_file |> Evaluator.eval_prog
    with Evaluator.RuntimeError msg -> Printf.printf "Error: %s\n" msg
  else Printf.printf "Usage: %s <file_name>\n" Sys.argv.(0)
