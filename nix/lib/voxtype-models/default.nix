{
  lib,
  ...
}:
{
  mkVoxtypeModel =
    {
      fetchurl,
      model,
      runCommand,
    }:
    let
      files = map (
        file:
        file
        // {
          path = fetchurl {
            inherit (file) hash;
            name = "${model.pname}-${builtins.baseNameOf file.source}";
            url = "https://huggingface.co/${model.repo}/resolve/${model.revision}/${file.source}";
          };
        }
      ) model.files;
    in
    runCommand "${model.pname}-${model.version}"
      {
        outputHash = model.hash;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        passthru = {
          inherit (model)
            files
            hash
            repo
            revision
            ;
          modelSize = lib.foldl' (total: file: total + file.size) 0 model.files;
        };
        meta = {
          inherit (model)
            description
            homepage
            license
            ;
          platforms = lib.platforms.all;
        };
      }
      ''
        mkdir -p "$out"
        ${lib.concatMapStringsSep "\n" (file: ''
          cp --reflink=auto -- ${file.path} "$out/${file.target}"
        '') files}
      '';

  voxtypeModels = {
    cohere-fp16 = {
      pname = "voxtype-model-cohere-fp16";
      version = "31b1c6211c90";
      repo = "onnx-community/cohere-transcribe-03-2026-ONNX";
      revision = "31b1c6211c9000d76b077ddd23b74c9090badeba";
      hash = "sha256-W9UdkcrpwJfKnN0d1sjSP7dDhd6OF5cnxOskVwckXqs=";
      description = "Cohere Transcribe FP16 model for Voxtype";
      homepage = "https://huggingface.co/onnx-community/cohere-transcribe-03-2026-ONNX";
      license = lib.licenses.asl20;
      files = [
        {
          source = "onnx/encoder_model_fp16.onnx";
          target = "encoder_model.onnx";
          hash = "sha256-FVBG6CwCK7N6Q8oTwNeDe8D9BGsVLVeNgxL8HhBWfoo=";
          size = 1192583;
        }
        {
          source = "onnx/encoder_model_fp16.onnx_data";
          target = "encoder_model_fp16.onnx_data";
          hash = "sha256-fDCf2ErKZodw2/jgNwyjsOUjrJFbNo196ihHAs04R80=";
          size = 2094166528;
        }
        {
          source = "onnx/encoder_model_fp16.onnx_data_1";
          target = "encoder_model_fp16.onnx_data_1";
          hash = "sha256-dysrv1D9/CSN+DIzPwbiL8b51BMWq76nK4JSb3KmBQ8=";
          size = 1698889728;
        }
        {
          source = "onnx/decoder_model_merged_fp16.onnx";
          target = "decoder_model_merged.onnx";
          hash = "sha256-iOJyrLe0NuftAcQ8LE1jpdk/HD0yT/9jKbTGU4dDVj8=";
          size = 155297;
        }
        {
          source = "onnx/decoder_model_merged_fp16.onnx_data";
          target = "decoder_model_merged_fp16.onnx_data";
          hash = "sha256-SurT19KgSoQAFpDZkpRbuotFoQgttrCBLD81IYkyPik=";
          size = 337993728;
        }
        {
          source = "tokenizer.json";
          target = "tokenizer.json";
          hash = "sha256-4mPAuhO+DwgDcFsAJ1aQj4TvxudaTCcyMaAcQ3GQiis=";
          size = 1152395;
        }
        {
          source = "tokenizer_config.json";
          target = "tokenizer_config.json";
          hash = "sha256-TI/sBsnhlRgCmds7qjcNAJC+aOxhHK3PVMQyF6MGygU=";
          size = 4549;
        }
        {
          source = "config.json";
          target = "config.json";
          hash = "sha256-Cc7I+5pE6MJ4sj79K4r78p5WDC6ytcGmtEjYszpmMr8=";
          size = 5102;
        }
        {
          source = "generation_config.json";
          target = "generation_config.json";
          hash = "sha256-3VdWOeA7JlHC7K1SwaUeYSbSpRZ4DP6F57RRfwW9l1Q=";
          size = 233;
        }
        {
          source = "processor_config.json";
          target = "processor_config.json";
          hash = "sha256-s2LblTjGldhL5GIyAl2EiEI71HoPo0EtYBnsMsBhWUA=";
          size = 634;
        }
      ];
    };

    parakeet-tdt-v3 = {
      pname = "voxtype-model-parakeet-tdt-v3";
      version = "8f23f0c03c87";
      repo = "istupakov/parakeet-tdt-0.6b-v3-onnx";
      revision = "8f23f0c03c8761650bdb5b40aaf3e40d2c15f1ce";
      hash = "sha256-vWEdCCg33Ny+qmGm7CNi9cIUoqM3UqgSxH/f4ZwK+d0=";
      description = "Parakeet TDT 0.6B v3 ONNX model for Voxtype";
      homepage = "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx";
      license = lib.licenses.cc-by-40;
      files = [
        {
          source = "encoder-model.onnx";
          target = "encoder-model.onnx";
          hash = "sha256-mKdLIbTMABfB5wMDGaSpb0qVBuUPBwjzpRbQKnfJa7E=";
          size = 41770866;
        }
        {
          source = "encoder-model.onnx.data";
          target = "encoder-model.onnx.data";
          hash = "sha256-miLTcsUUVcNPE0BdolILrvtxJb0WmBOXVhQj7TLSTzY=";
          size = 2435420160;
        }
        {
          source = "decoder_joint-model.onnx";
          target = "decoder_joint-model.onnx";
          hash = "sha256-6Xjd9miFJxgsEP3i60uDBoQhZImF7yP3qGvnMr6HBsE=";
          size = 72520893;
        }
        {
          source = "vocab.txt";
          target = "vocab.txt";
          hash = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
          size = 93939;
        }
        {
          source = "config.json";
          target = "config.json";
          hash = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
          size = 97;
        }
      ];
    };

    moonshine-base = {
      pname = "voxtype-model-moonshine-base";
      version = "b1e9b6aae3c3";
      repo = "onnx-community/moonshine-base-ONNX";
      revision = "b1e9b6aae3c3c7298f10c3798393fdf38e8fbbad";
      hash = "sha256-MbIvpvnr9IaDBFaR0MvbH4VKjsWNSFslyzG2Sd/06EY=";
      description = "Moonshine Base ONNX model for Voxtype";
      homepage = "https://huggingface.co/onnx-community/moonshine-base-ONNX";
      license = lib.licenses.mit;
      files = [
        {
          source = "onnx/encoder_model.onnx";
          target = "encoder_model.onnx";
          hash = "sha256-FT4Sjnq9ZKdO5H8sP1hcMXHE1Gy7NosDKCeTTE4B53k=";
          size = 80818781;
        }
        {
          source = "onnx/decoder_model_merged.onnx";
          target = "decoder_model_merged.onnx";
          hash = "sha256-WHeHY8qEOJYxkCRNayZXK9yizt7FakuR6Cjz8tae88U=";
          size = 166211345;
        }
        {
          source = "tokenizer.json";
          target = "tokenizer.json";
          hash = "sha256-e5E0BL3QOa9HVngyGK9EQLwH+31tgljWd+NPlbPsQW8=";
          size = 3761754;
        }
      ];
    };

    silero-vad = {
      pname = "voxtype-model-silero-vad";
      version = "9ffd54a1e1ee";
      repo = "ggml-org/whisper-vad";
      revision = "9ffd54a1e1ee413ddf265af9913beaf518d1639b";
      hash = "sha256-986/Xr/7dz6qzSTvHPfc0dU8Cha/EGDjXcDYvnyugus=";
      description = "Silero VAD GGML model for Voxtype";
      homepage = "https://huggingface.co/ggml-org/whisper-vad";
      license = lib.licenses.mit;
      files = [
        {
          source = "ggml-silero-v6.2.0.bin";
          target = "ggml-silero-vad.bin";
          hash = "sha256-KqJpt4XutTqCmDogUB3ffB2cSOM6tjpBORrGyff7aYc=";
          size = 885098;
        }
      ];
    };

    whisper-large-v3 = {
      pname = "voxtype-model-whisper-large-v3";
      version = "5359861c739e";
      repo = "ggerganov/whisper.cpp";
      revision = "5359861c739e955e79d9a303bcbc70fb988958b1";
      hash = "sha256-W/KyywkMhSSnJA2WLUEt4g0SQ5V3SdaD3Ezhf4Xsao4=";
      description = "Whisper Large-v3 GGML model for Voxtype";
      homepage = "https://huggingface.co/ggerganov/whisper.cpp";
      license = lib.licenses.mit;
      files = [
        {
          source = "ggml-large-v3.bin";
          target = "ggml-large-v3.bin";
          hash = "sha256-ZNGCtEC5jVIDxPm9VBVE2ExgUZbE97hF36EfsjWU0eI=";
          size = 3095033483;
        }
      ];
    };
  };
}
