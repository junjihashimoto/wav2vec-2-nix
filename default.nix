{ pkgs
, dataset
, hasktorch-datasets-utils
, mach-nix
}:
let
  lib = pkgs.lib;
  myPython =
    mach-nix.mkPython rec {
      requirements = builtins.readFile ./requirements.txt;
      _.sndfile.propagatedBuildInputs.add = [pkgs.libsndfile.dev];
      providers = {
        # disallow wheels by default
        _default = "wheel,sdist,nixpkgs";
        soundfile = "nixpkgs";
        mecab-python3 = "wheel";
      };
    };
in
rec {
  inherit myPython;
}
