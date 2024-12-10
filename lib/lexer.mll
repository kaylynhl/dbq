(* The block of code below is the _header_. It will literally be
   copied into the generated "lexer.ml" file. Because of the [open],
   the token names that are declared in [Parser] (which is generated
   from "parser.mly") are in scope inside of all the blocks of code
   in curly braces [{ ... }] at the end of the file. *)
{
open Parser
}

(* These "let" definitions are not quite the same as OCaml's.
   Rather, these define _regular expressions_ to recognize
   sequences of characters. *)
let white = [' ' '\t']+
let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let var = letter (letter | '_' | digit)*
let dquote = '"'
let not_dquote = [^'"']
let string_literal = dquote (not_dquote* as the_string) dquote

(* This lexing rule, named "read", defines which token to 
   return in response to which sequence of characters is read.
   The words "rule" and "parse" below are keywords. *)
rule read =
  parse
  | eof { EOF }
  | white { read lexbuf } (* call [read] again and ignore the whitespace *)
  | '\n' { Lexing.new_line lexbuf; read lexbuf }
    (* not only ignore the newline but also increment a counter for which
       line we are on *)
  | ":=" { ASSIGN }
  | ";" { SEMICOLON }
  | "load" { LOAD } 
  | "print" { PRINT }   
  | "save" { SAVE }
  | var { VAR (Lexing.lexeme lexbuf) }
    (* [Lexing.lexeme lexbuf] is a call into the lexer infrastructure
       that returns the string the currently regular expression
       matched. I.e., it is the variable name that was just lexed. *)      
  | string_literal { STRING_LITERAL the_string }

