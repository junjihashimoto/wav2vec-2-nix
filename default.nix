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
  # libsndfile = pkgs.libsndfile.overrideAttrs (old:{
  #   src = pkgs.fetchFromGitHub {
  #     owner = "arthurt";
  #     repo = "libsndfile";
  #     rev = "7d61467fae33b11a705d134af13bbb4f6f8064c0";
  #     sha256 = "1cy1058yd7s1aa8fw3yjgfazq76asnb943vs74gvpv1csmi29rgr";
  #   };
  #   buildInputs = old.buildInputs ++ [pkgs.lame];
  # }
  # );
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

  lang-trans = sdist {
    name = "lang-trans";
    version = "0.6.0";
    sha256 = "0yv30aprc8icwmab16kv43hps27j3vli1b3wwyakp78pp8c3fs19";
    deps = [];
  };
  # socks = sdist {
  #   name = "socks";
  #   version = "0";
  #   sha256 = "0rgpxn8wjp0mpmrz26m9q1352a96mvscf00a6v0021kk4139nzkj";
  #   deps = [];
  # };
  # gdown = (sdist {
  #   name = "gdown";
  #   version = "3.12.2";
  #   sha256 = "1b3b710wrg98wgnqx1qgzmkkkcmlzgw5xwlvjg78vzbvwl0i6fjb";
  #   deps = with pkgs.python3Packages; [filelock six socks tqdm requests];
  # }).overrideAttrs ( old:{
  #   patchPhase = ''
  #     grep -rn socks .
  #     sed -i -e 's/requests\[socks\]/requests/g' \
  #      ./gdown.egg-info/requires.txt \
  #      ./setup.py
  #   '';
  # });
  homoglyphs = sdist {
    name = "homoglyphs";
    version = "2.0.4";
    format = "wheel";
    sha256 = "1j5mpnra7h5gsplbw2m88k894ydza9v4n22iki3vi038qh6b1kdx";
    src = builtins.fetchurl {
      name = "homoglyphs-2.0.4-py3-none-any.whl";
      url = "https://files.pythonhosted.org/packages/37/43/b4f6c03bef205840e966f6cf4845462c6221777388a572b48a46496efbbf/homoglyphs-2.0.4-py3-none-any.whl";
      sha256 = "1j5mpnra7h5gsplbw2m88k894ydza9v4n22iki3vi038qh6b1kdx";
    };
    deps = [];
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
      torch-audiomentations
      audiomentations
      julius
      torch-pitch-shift
      primePy
      homoglyphs
      gdown
      lang-trans
    ]);
in
rec {
  inherit myPython;
  train = pkgs.stdenv.mkDerivation {
    name = "train";
    src = ./src;
    buildInputs = [pkgs.ffmpeg];
    buildPhase = ''
      mkdir -p $out/output
      mkdir -p cache
      export HOME=`pwd`
      export TMP=`pwd`/cache
      export NUMBA_CACHE_DIR=`pwd`/cache
      export MPLCONFIGDIR=`pwd`/cache
      ${myPython}/bin/python train.py \
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
  };
}
