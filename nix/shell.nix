{ ocamlPackages, packages, pkgs }:

with ocamlPackages;

pkgs.mkShell {
  inputsFrom = with packages; [ serde-melange ];
  buildInputs = [
    ocaml
    dune
    ocaml-lsp
    ocamlformat
    merlin
    utop
    odoc
    pkgs.pkg-config
    pkgs.openssl
  ];
}
