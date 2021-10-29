{ pkgs
, dataset
, hasktorch-datasets-utils
, mach-nix
}:
let
#  myPython_ =
#    mach-nix.mkPython rec {
#      requirements = builtins.readFile ./requirements.txt;
#      _.sndfile.propagatedBuildInputs.add = [pkgs.libsndfile.dev];
#      providers = {
#        # disallow wheels by default
#        _default = "wheel,sdist,nixpkgs";
#        soundfile = "nixpkgs";
#        mecab-python3 = "wheel";
#      };
#    };
  sdist = { name
         , version
         , sha256 ? ""
         , deps
         , format ? "setuptools"
         , src ? pkgs.python3Packages.fetchPypi {
             pname = name;
             inherit version;
             inherit sha256;
           }
         }:
    with pkgs.python3Packages;
    buildPythonPackage rec {
      pname = name;
      inherit version;
      inherit src;
      inherit format;
      doCheck = false;
      propagatedBuildInputs = deps;
    };
  sndfile = sdist {
    name = "sndfile";
    version = "0.2.0";
    sha256 = "03dr6510npw9b505ir67xa129knnm453sq20i3zyk330402dpylq";
    deps = [pkgs.libsndfile pkgs.python3Packages.cffi];
  };
  python-Levenshtein = sdist {
    name = "python-Levenshtein";
    version = "0.12.2";
    sha256 = "1xj60gymwx1jl2ra9razx2wk8nb9cv1i7l8d14qsp8a8s7xra8yw";
    deps = [];
  };
  jiwer = sdist {
    name = "jiwer";
    version = "2.2.1";
    sha256 = "099mrjm757k5caacl7pvzngaxrsmbl9g9sjg8867dnkwj9i4vmym";
    deps = [python-Levenshtein];
  };
  primePy = sdist {
    name = "primePy";
    version = "1.3";
    sha256 = "0sa6vs9aryxywjccj87g1cc1zksg0ngxhxack2jqj1sb6hjpxz95";
    deps = [];
  };
  torch-pitch-shift = sdist {
    name = "torch-pitch-shift";
    version = "1.2.0";
    # src = pkgs.fetchFromGitHub {
    #   owner = "KentoNishi";
    #   repo = "torch-pitch-shift";
    #   rev = "cf9a7079c0f6af075290d2c8601a4bfd6b0deb7e";
    #   sha256 = "0s44a3ip2dvpibjnymgbsgmwnxil4ilk08n4ybq9l2i177sgn5fb";
    # };
    src = builtins.fetchurl {
      name = "torch_pitch_shift-1.2.0-py3-none-any.whl";
      url = "https://files.pythonhosted.org/packages/2d/56/2b051b152b28c54a4f82ad390c9d6a209938a28f1fbe2cfc81adc2a320f3/torch_pitch_shift-1.2.0-py3-none-any.whl";
      sha256 = "18hagpxjl3pl8d6k7m9agkc5zay7sy25pgbqhf19rw2vjp5bhxz1";
    };
    format = "wheel";
    deps = with pkgs.python3Packages; [pytorch-bin torchaudio-bin primePy];
  };
  julius = sdist {
    name = "julius";
    version = "0.2.6";
    sha256 = "1l39n3lyi88x68k53px3ydwh6b9g062rj331m18fxy4rgf77h2i3";
    deps = with pkgs.python3Packages; [pytorch-bin torchaudio-bin];
  };
  audiomentations = sdist {
    name = "audiomentations";
    version = "0.19.0";
    sha256 = "1k1dygrpgd51hw5igrr24r4822rbn3fgl4vj2zclj7gmka6bbc9p";
    deps = with pkgs.python3Packages; [pytorch-bin torchaudio-bin julius torch-pitch-shift librosa primePy pydub];
  };
  torch-audiomentations = (sdist {
    name = "torch-audiomentations";
    version = "0.9.0";
    sha256 = "10mpm5a5fhnmy70k4m7lw0h2m0aldgclb420dz8wc2ljlfc9hk0y";
    deps = with pkgs.python3Packages; [pytorch-bin torchaudio-bin julius torch-pitch-shift librosa primePy];
  }).overrideAttrs ( old:{
    patchPhase = ''
      grep -rn 3.9 .
      sed -i -e 's/3.9/3.10/g' \
       ./torch_audiomentations.egg-info/PKG-INFO \
       ./setup.py \
       ./PKG-INFO
    '';
  });
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
      torch-audiomentations
      audiomentations
      julius
      torch-pitch-shift
      primePy
    ]);
in
rec {
  inherit myPython;
  train = pkgs.runCommand "train" {} ''
    mkdir -p $out/output
    mkdir -p cache
    python train.py \
    --model_name_or_path="facebook/wav2vec2-large-xlsr-53" \
    --dataset_config_name="ja" \
    --output_dir=$out/output \
    --cache_dir=cache \
    --overwrite_output_dir \
    --num_train_epochs="1" \
    --per_device_train_batch_size="32" \
    --per_device_train_batch_size="32" \
    --evaluation_strategy="steps" \
    --learning_rate="3e-4" \
    --warmup_steps="500" \
    --fp16 \
    --freeze_feature_extractor \
    --save_steps="10" \
    --eval_steps="10" \
    --save_total_limit="1" \
    --logging_steps="10" \
    --group_by_length \
    --feat_proj_dropout="0.0" \
    --layerdrop="0.1" \
    --gradient_checkpointing \
    --do_train --do_eval \
    --max_train_samples 100 --max_val_samples 100
  '';
}
