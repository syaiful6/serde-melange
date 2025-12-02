(lang dune 3.19)

(cram enable)

(using melange 0.1)

(name serde-melange)

(documentation "github.com/syaiful6/serde-melange")

(source
 (github syaiful6/serde-melange))

(license MIT)

(authors "Syaiful Bahri <syai.bahri6@gmail.com>")

(maintainers "Syaiful Bahri <syai.bahri6@gmail.com>")

(generate_opam_files true)

(package
 (name serde-melange)
 (synopsis "Serialization framework Melange")
 (description "Serialization framework Melange\n  ")
 (depends
  (ocaml
   (>= 5.3))
  (melange
   (>= "4.0.0"))
  dune
  (alcotest :with-test)
  (melange-jest :with-test)
  (ocaml-lsp-server :with-test)
  (ocamlformat
   (and
    (>= "0.27.0")
    :with-test))
  (odoc :with-doc)))
