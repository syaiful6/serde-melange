{ ocamlPackages, packages, pkgs }:

with ocamlPackages;

pkgs.mkShell {
  inputsFrom = with packages; [ serde-melange ];
  buildInputs = [
    ocaml
    dune
    ocaml-lsp
    ocamlformat
    melange-jest
    merlin
    utop
    odoc
    pkgs.nodejs_latest
    pkgs.pkg-config
    pkgs.openssl
  ];
}
