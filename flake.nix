{
  description = "torchvision-fasterrcnn";

  nixConfig = {
    substituters = [
      # https://iohk.cachix.org
      https://hydra.iohk.io
    ];
    trusted-public-keys = [
      hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=
    ];
    bash-prompt = "\[nix-develop\]$ ";
  };
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?rev=8deeda2c607a3f64d2fa935f1ad9d29a9b88dab4";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:DavHau/mach-nix";
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
