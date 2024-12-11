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
  | white { read lexbuf } 
  | '\n' { Lexing.new_line lexbuf; read lexbuf }
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
  | string_literal { STRING_LITERAL the_string }