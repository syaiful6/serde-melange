{
  mkShell,
  treefmt,
  ocamlPackages,
  pkgs,
}:
let
  # melange-jest is only needed for dev testing, not part of the public overlay
  melange-jest = ocamlPackages.callPackage ./melange-jest.nix { };
in
mkShell {
  inputsFrom = with ocamlPackages; [
    serde-melange
  ];
  buildInputs =
    (with ocamlPackages; [
      ocaml-lsp
      ocamlformat
      merlin
      utop
      odoc
    ])
    ++ [
      melange-jest
      treefmt
      pkgs.nodejs_latest
    ];
}
