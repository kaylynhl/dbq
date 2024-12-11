{
open Parser
}

let white = [' ' '\t']+
let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let var = letter (letter | '_' | digit)*
let dquote = '"'
let not_dquote = [^'"']
let string_literal = dquote (not_dquote* as the_string) dquote
let name = ['a'-'z' 'A'-'Z' '0'-'9' '_']+  
let column_names = "[" white* (name (white* ";" white* name)*)? white* "]" 

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
  | "project" { PROJECT }
  | "from" { FROM }
  | "[" { LBRACKET } 
  | "]" { RBRACKET }  
  | var { VAR (Lexing.lexeme lexbuf) }
    (* [Lexing.lexeme lexbuf] is a call into the lexer infrastructure
       that returns the string the currently regular expression
       matched. I.e., it is the variable name that was just lexed. *)      
  | string_literal { STRING_LITERAL the_string }