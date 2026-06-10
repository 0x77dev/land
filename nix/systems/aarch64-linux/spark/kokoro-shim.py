"""OpenAI-compatible /v1/audio/speech on top of Kokoro-82M (CUDA).

Weights, voices, and the listen address arrive via environment variables set
by the kokoro-openai unit in ./default.nix. Serves one-shot requests only —
exactly what Hermes' voice tools and realtime voice-mode clients issue.
"""

import os
import subprocess
import threading

import torch
import uvicorn
from fastapi import FastAPI, HTTPException, Response
from kokoro import KModel, KPipeline
from pydantic import BaseModel

SAMPLE_RATE = 24000  # Kokoro's fixed output rate

# response_format -> (ffmpeg output args, media type). ffmpeg is always fed raw
# f32le mono @ SAMPLE_RATE on stdin; each entry only names the encoder/muxer.
ENCODERS = {
    "mp3": (["-f", "mp3"], "audio/mpeg"),
    "opus": (["-c:a", "libopus", "-f", "ogg"], "audio/ogg"),
    "aac": (["-c:a", "aac", "-f", "adts"], "audio/aac"),
    "flac": (["-f", "flac"], "audio/flac"),
    "wav": (["-f", "wav"], "audio/wav"),
    "pcm": (["-f", "s16le"], "audio/pcm"),  # headerless 16-bit LE, per OpenAI
}

# "name=/path/to/voice.pt,..." — first entry is the default voice.
VOICES = dict(pair.split("=", 1) for pair in os.environ["KOKORO_VOICES"].split(","))
DEFAULT_VOICE = next(iter(VOICES))

model = (
    KModel(
        repo_id="hexgrad/Kokoro-82M",
        config=os.environ["KOKORO_CONFIG"],
        model=os.environ["KOKORO_MODEL"],
    )
    .to("cuda")
    .eval()
)
pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M", model=model)
lock = threading.Lock()  # one GPU, one inference at a time

app = FastAPI()


class SpeechRequest(BaseModel, extra="ignore"):  # tolerate model/instructions/...
    input: str
    voice: str = DEFAULT_VOICE
    response_format: str = "mp3"
    speed: float = 1.0


@app.post("/v1/audio/speech")
def speech(request: SpeechRequest) -> Response:
    if request.response_format not in ENCODERS:
        raise HTTPException(
            400, f"unsupported response_format: {request.response_format}"
        )
    codec, media_type = ENCODERS[request.response_format]
    voice = VOICES.get(request.voice, VOICES[DEFAULT_VOICE])
    with lock:
        chunks = [
            result.audio
            for result in pipeline(request.input, voice=voice, speed=request.speed)
            if result.audio is not None
        ]
    if not chunks:
        raise HTTPException(400, "no speech produced")
    pcm = torch.cat(chunks).cpu().numpy().tobytes()
    ffmpeg = subprocess.run(
        ["ffmpeg", "-f", "f32le", "-ar", str(SAMPLE_RATE), "-ac", "1", "-i", "pipe:0"]
        + codec
        + ["pipe:1"],
        input=pcm,
        capture_output=True,
    )
    if ffmpeg.returncode:
        raise HTTPException(500, ffmpeg.stderr.decode(errors="replace")[-500:])
    return Response(content=ffmpeg.stdout, media_type=media_type)


if __name__ == "__main__":
    uvicorn.run(
        app, host=os.environ["KOKORO_HOST"], port=int(os.environ["KOKORO_PORT"])
    )
