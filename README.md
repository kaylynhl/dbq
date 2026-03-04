# dbquery

`dbquery` is a small OCaml package and CLI for parsing and evaluating a query
language over CSV-backed tables.

## Why this is interesting

- Implements a complete language pipeline: lexer, parser, AST, and evaluator.
- Enforces runtime table invariants (non-empty, rectangular CSVs, unique headers).
- Includes deterministic tests for syntax, runtime errors, and data transforms.
- Demonstrates a clean Dune layout for a reusable library plus executable.

## Build, run, and test

```sh
dune build
dune exec dbquery -- data/test1.dbq
dune test
```

## Example usage

Create a program file:

```text
a := load "data/chem_grades.csv";
b := project ["ID"; "hw2"; "hw1"] from a;
print b;
```

Run it:

```sh
dune exec dbquery -- ./example.dbq
```

## Design decisions

- Programs execute left-to-right with mutable variable bindings.
- `project` preserves requested column order and rejects duplicate column names.
- `join` is an inner join on key equality and emits the key column once.
- Runtime errors are reported as explicit `RuntimeError` messages from the API.

Note: Originally written for coursework and later revisited to improve
structure, tests, and documentation.
