type table_expr =
  | Var of string
  | Load of string
  | Project of string list * table_expr
  | Join of table_expr * table_expr * string
  | Rename of string * string * table_expr
(** A table expression in the query language.
    - [Project (cols, t)] keeps only [cols] from [t], in the listed order.
    - [Join (t1, t2, key)] joins rows from [t1] and [t2] on equality of [key].
    - [Rename (old_name, new_name, t)] renames one column in [t]. *)

type command =
  | Assign of string * table_expr
  | Print of table_expr
  | Save of table_expr * string
(** Top-level commands for programs. *)

type program = command list
(** A program is a sequence of commands evaluated from left to right. *)
