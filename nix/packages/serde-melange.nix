{
  buildDunePackage,
  lib,
  melange,
  ppxlib,
  doCheck ? true,
}:

buildDunePackage {
  pname = "serde-melange";
  version = "0.1.0";

  src =
    let
      fs = lib.fileset;
    in
    fs.toSource {
      root = ../..;
      fileset = fs.unions [
        ../../src
        ../../dune-project
        ../../serde-melange.opam
      ];
    };

  duneVersion = "3";
  nativeBuildInputs = [ melange ];
  propagatedBuildInputs = [
    melange
    ppxlib
  ];
  inherit doCheck;
}
