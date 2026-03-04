# dbquery

`dbquery` is a small OCaml library + CLI that parses and evaluates a DSL for
CSV-backed tables.

## What it does

- Parses a query language with assignments and table expressions.
- Evaluates programs left-to-right with mutable variable bindings.
- Supports `load`, `project`, `join`, `rename`, `print`, and `save`.
- Validates CSV/runtime invariants with explicit `RuntimeError` messages.
- Uses a hash-indexed join implementation for faster key joins.

## Requirements

- OCaml
- Dune (`>= 3.16`)
- `csv` library
- `menhir`

## Build and run

```sh
dune build
```

Run a sample program:

```sh
dune exec dbquery -- data/test2.dbq
```

Run tests:

```sh
dune test
```

## Language quick reference

Program shape:

```text
<command>; <command>; ...
```

Commands:

- Assignment: `x := <table_expr>;`
- Print: `print <table_expr>;`
- Save: `save <table_expr> "path/to/file.csv";`

Table expressions:

- Variable: `x`
- Load CSV: `load "data/chem_grades.csv"`
- Project columns:
  `project ["ID"; "hw2"; "hw1"] from x`
- Join on key:
  `join a with b on "ID"`
- Rename column:
  `rename "old" to "new" from x`
- Parenthesized expression: `(<table_expr>)`

## Example

```text
a := load "data/chem_grades.csv";
b := project ["ID"; "hw2"; "hw1"] from a;
print b;
```

Run it:

```sh
dune exec dbquery -- ./example.dbq
```

## Runtime behavior and guarantees

- Loaded CSVs must be non-empty.
- Loaded CSVs must be rectangular.
- Loaded CSV headers must be unique.
- `project` requires requested columns to exist and be unique in the list.
- `join` is an inner join on equality and emits the key column once.
- `join` preserves deterministic row order and indexes the right table by key.
- `rename` fails if the target column name already exists.

## Project layout

- `lib/`: AST, lexer/parser frontend, evaluator.
- `bin/main.ml`: CLI entrypoint.
- `test/`: deterministic parser/runtime/integration tests.
- `data/`: sample CSV inputs and `.dbq` programs.

## Notes

Originally written for coursework and then cleaned up with stronger tests,
clearer invariants, and evaluator optimizations.
