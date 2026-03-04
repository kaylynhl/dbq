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

rule read =
  parse
  | eof { EOF }
  | white { read lexbuf } 
  | '\n' { Lexing.new_line lexbuf; read lexbuf }
  | ":=" { ASSIGN }
  | ";" { SEMICOLON }
  | "[" { LBRACKET } 
  | "]" { RBRACKET } 
  | "(" { LPAR }
  | ")" { RPAR } 
  | "load" { LOAD } 
  | "print" { PRINT }   
  | "save" { SAVE }
  | "project" { PROJECT }
  | "from" { FROM }
  | "join" { JOIN }
  | "with" { WITH }
  | "on" { ON }
  | "rename" { RENAME }
  | "to" { TO }
  | var { VAR (Lexing.lexeme lexbuf) }    
  | string_literal { STRING_LITERAL the_string }
