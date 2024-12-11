%{
    open Ast
%}

%token EOF ASSIGN SEMICOLON LOAD PRINT SAVE PROJECT FROM
%token <string> VAR STRING_LITERAL
%token LBRACKET RBRACKET

%start <Ast.program> prog 

%%

prog:
  | p = nonempty_list(command); EOF { p }
  ;

command:
  | v = VAR; ASSIGN; t = table_expr; SEMICOLON { Assign (v, t) }
  | PRINT; t = table_expr; SEMICOLON { Print t }
  | SAVE; t = table_expr; f = STRING_LITERAL; SEMICOLON { Save (t, f) }
  ;

table_expr:
  | v = VAR { Var v }
  | LOAD; f = STRING_LITERAL; { Load f }
  | PROJECT; LBRACKET names = names_list; RBRACKET; FROM t = table_expr { Project (names, t) }

names_list:
  | name = STRING_LITERAL { [name] }
  | name = STRING_LITERAL; SEMICOLON names = names_list { name :: names }