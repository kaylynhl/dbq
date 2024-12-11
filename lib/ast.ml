type table_expr =
  | Var of string
  | Load of string
  | Project of string list * table_expr
  | Join of table_expr * table_expr * string

type command =
  | Assign of string * table_expr
  | Print of table_expr
  | Save of table_expr * string

type program = command list
