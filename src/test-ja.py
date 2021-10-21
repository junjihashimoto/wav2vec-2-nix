
# https://huggingface.co/vumichien/wav2vec2-large-xlsr-japanese
import torch
import librosa
import torchaudio
from datasets import load_dataset, load_metric
import MeCab
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
import re

#config
wakati = MeCab.Tagger("-Owakati")
chars_to_ignore_regex = '[\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\,\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\、\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\。\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\．\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\「\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\」\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\…\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\？\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\・]'

# load data, processor and model
test_dataset = load_dataset("common_voice", "ja", split="test")
wer = load_metric("wer")
processor = Wav2Vec2Processor.from_pretrained("vumichien/wav2vec2-large-xlsr-japanese")
model = Wav2Vec2ForCTC.from_pretrained("vumichien/wav2vec2-large-xlsr-japanese")
#model.to("cuda")
resampler = lambda sr, y: librosa.resample(y.numpy().squeeze(), sr, 16_000)

# Preprocessing the datasets.
def speech_file_to_array_fn(batch):
    batch["sentence"] = wakati.parse(batch["sentence"]).strip()
    batch["sentence"] = re.sub(chars_to_ignore_regex,'', batch["sentence"]).strip()
    speech_array, sampling_rate = torchaudio.load(batch["path"])
    batch["speech"] = resampler(sampling_rate, speech_array).squeeze()
    return batch
test_dataset = test_dataset.map(speech_file_to_array_fn)

# evaluate function
def evaluate(batch):
    inputs = processor(batch["speech"], sampling_rate=16_000, return_tensors="pt", padding=True)
    with torch.no_grad():
#        logits = model(inputs.input_values.to("cuda"), attention_mask=inputs.attention_mask.to("cuda")).logits
        logits = model(inputs.input_values, attention_mask=inputs.attention_mask).logits
    pred_ids = torch.argmax(logits, dim=-1)
    batch["pred_strings"] = processor.batch_decode(pred_ids)
    return batch
result = test_dataset.map(evaluate, batched=True, batch_size=8)
print("WER: {:2f}".format(100 * wer.compute(predictions=result["pred_strings"], references=result["sentence"])))
