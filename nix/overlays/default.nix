final: prev:
let
  ocamlOverlay = final': prev': {
    serde-melange = final'.callPackage ../packages/serde-melange.nix {
      inherit (final.serde-melange) doCheck;
    };
  };
in
{
  ocaml-ng.ocamlPackages_4_14 = prev.ocaml-ng.ocamlPackages_4_14.overrideScope ocamlOverlay;
  ocaml-ng.ocamlPackages_5_2 = prev.ocaml-ng.ocamlPackages_5_2.overrideScope ocamlOverlay;
  ocaml-ng.ocamlPackages_5_3 = prev.ocaml-ng.ocamlPackages_5_3.overrideScope ocamlOverlay;
  ocaml-ng.ocamlPackages_5_4 = prev.ocaml-ng.ocamlPackages_5_4.overrideScope ocamlOverlay;
  ocaml-ng.ocamlPackages = prev.ocaml-ng.ocamlPackages.overrideScope ocamlOverlay;

  serde-melange = final.lib.makeScope final.newScope (self: {
    doCheck = true;
  });
}
