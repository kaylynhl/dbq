(lang dune 3.16)

(name dbquery)

(using menhir 3.0)

(generate_opam_files true)

(source
 (github kkayl/dbquery))

(authors "Kaylyn Lee")

(maintainers "Kaylyn Lee")

(license UNLICENSED)

(documentation https://github.com/kkayl/dbquery#readme)

(package
 (name dbquery)
 (synopsis "A small query language for CSV-backed tabular data")
 (description "A parser and evaluator for a DSL over CSV-backed tables")
 (depends
  ocaml
  dune
  csv
  menhir)
 (tags
  (database csv parser interpreter)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
