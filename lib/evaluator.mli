exception RuntimeError of string
(** [RuntimeError] is raised to indicate an error during the execution of a
    program. *)

val eval_prog : Ast.program -> unit
(** [eval_prog prog] evaluates [prog], causing its side effects to occur.
    Raises: [RuntimeError] if an error occurs. *)
