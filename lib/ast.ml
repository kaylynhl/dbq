type table_expr =
  | Var of string
  | Load of string

type command =
  | Assign of string * table_expr
  | Print of table_expr
  | Save of table_expr * string

type program = command list
