(lang dune 3.15)

(name trading_simulator)

(generate_opam_files true)
(source
 (github Clearbloo/trading_simulator))

(authors "Clearbloo")

(maintainers "Clearbloo")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name trading_simulator)
 (synopsis "A market and trading simulator")
 (description "4 components: market, broker, portfolio and trader")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
