exception RuntimeError of string
(** [RuntimeError] is raised to indicate an error during the execution of a
    program. *)

val eval_prog : Ast.program -> unit
(** [eval_prog prog] evaluates [prog], causing its side effects to occur.
    Raises: [RuntimeError] if an error occurs.

    Invariants enforced during evaluation include:
    - loaded CSV tables must be non-empty with unique header names
    - loaded CSV tables must be rectangular
    - projected columns must exist and be unique in the projection list *)
