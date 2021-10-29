{
  description = "torchvision-fasterrcnn";

  nixConfig = {
#    substituters = [
#      https://hydra.iohk.io
#    ];
#    trusted-public-keys = [
#      hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=
#    ];
    bash-prompt = "\[nix-develop\]$ ";
  };
  
  inputs = {
#    nixpkgs.url = "github:nixos/nixpkgs?rev=1ca6b0a0cc38dbba0441202535c92841dd39d1ae";
    nixpkgs.url = "github:junjihashimoto/nixpkgs?rev=1fece73befd475415b409ef8867ca13ea74c2f58";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:DavHau/mach-nix?rev=4433f74a97b94b596fa6cd9b9c0402104aceef5d";
    hasktorch-datasets.url = "github:hasktorch/hasktorch-datasets?rev=056451ca585f2ecdf1c0b3cfa06ac6cb2a9f2efd";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, hasktorch-datasets }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [
          ];
        };
        customOverrides = self: super: {
          # Overrides go here
        };

        packageName = "wav2vec-2";
        cv-ja = hasktorch-datasets.packages.${system}.datasets-common-voice-ja;
        hasktorch-datasets-utils = hasktorch-datasets.lib.${system}.utils;
        wav2vec = pkgs.callPackage ./default.nix {
          dataset = cv-ja;
          mach-nix = mach-nix.lib.${system};
          inherit hasktorch-datasets-utils;
        };
      in {
        lib = {
        };
        packages = {
          dataset = cv-ja;
        };

        # defaultPackage = self.packages.${system}.${packageName};

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ wav2vec.myPython ];
          inputsFrom = builtins.attrValues self.packages.${system};
          shellHook = ''export LD_LIBRARY_PATH=${pkgs.libsndfile}/lib:$LD_LIBRARY_PATH'';          
        };
      });
}
