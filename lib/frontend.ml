exception SyntaxError of string

let location_message lexbuf =
  let open Lexing in
  let start = lexeme_start_p lexbuf in
  let finish = lexeme_end_p lexbuf in
  Printf.sprintf "line %d, characters %d-%d" start.pos_lnum
    (start.pos_cnum - start.pos_bol)
    (finish.pos_cnum - finish.pos_bol)

let syntax_error_message lexbuf =
  Printf.sprintf "Syntax error, %s: %s" (location_message lexbuf)
    (Lexing.lexeme lexbuf)

let parse_buffer lexbuf =
  try
    let ast = Parser.prog Lexer.read lexbuf in
    ast
  with Parser.Error -> raise (SyntaxError (syntax_error_message lexbuf))

let parse s =
  let lexbuf = Lexing.from_string s in
  parse_buffer lexbuf

let parse_file f =
  let lexbuf = Lexing.from_channel (open_in f) in
  parse_buffer lexbuf

(* Note: the lexing functions below are provided for convenience in debugging
   and experimentation. Internally, they are never used by the parsing functions
   above in this module. That's because the Menhir-generated parser makes
   incremental calls to the lexer itself. *)

let lex_buffer lexbuf =
  let[@tail_mod_cons] rec loop () =
    match Lexer.read lexbuf with
    | Parser.EOF -> []
    | token -> token :: loop ()
  in
  loop ()

let lex s =
  let lexbuf = Lexing.from_string s in
  lex_buffer lexbuf

let lex_file f =
  let lexbuf = Lexing.from_channel (open_in f) in
  lex_buffer lexbuf
