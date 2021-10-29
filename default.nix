{ pkgs
, dataset
, hasktorch-datasets-utils
, mach-nix
}:
let
  myPython_ =
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
  pack = { name
         , version
         , sha256
         , format
         , deps
         }:
    with pkgs.python3Packages;
    buildPythonPackage rec {
      pname = name;
      inherit version;
      inherit format;
      src = fetchPypi {
        pname = name;
        inherit version;
        inherit sha256;
      };
      doCheck = false;
      buildInputs = deps;
    };
  sndfile = pack {
    name = "sndfile";
    version = "0.2.0";
    sha256 = "03dr6510npw9b505ir67xa129knnm453sq20i3zyk330402dpylq";
    format = "setuptools";
    deps = [pkgs.libsndfile pkgs.python3Packages.cffi];
  };
  python-Levenshtein = pack {
    name = "python-Levenshtein";
    version = "0.12.2";
    sha256 = "1xj60gymwx1jl2ra9razx2wk8nb9cv1i7l8d14qsp8a8s7xra8yw";
    format = "setuptools";
    deps = [];
  };
  jiwer = pack {
    name = "jiwer";
    version = "2.2.1";
    sha256 = "099mrjm757k5caacl7pvzngaxrsmbl9g9sjg8867dnkwj9i4vmym";
    format = "setuptools";
    deps = [python-Levenshtein];
  };
  myPython =
    pkgs.python39.withPackages(ps: with ps; [
      pytorch-bin
      torchaudio-bin
      sndfile
      pyarrow
      numba
      cython
      datasets
      transformers
      librosa
      jiwer
      mecab-python3
      soundfile
      unidic-lite
    ]);
in
rec {
  inherit myPython;
}
