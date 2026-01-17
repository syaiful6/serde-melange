# this package only used for testing, not part of public overlay
{
  buildDunePackage,
  fetchFromGitHub,
  melange,
}:

buildDunePackage {
  pname = "melange-jest";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "melange-community";
    repo = "melange-jest";
    rev = "0.2.0";
    hash = "sha256-H0Y0CLY6t/aLzMg4MD4hdWV9DUu8oN3q7SAps073C34=";
  };

  duneVersion = "3";
  nativeBuildInputs = [ melange ];
  propagatedBuildInputs = [ melange ];
}
