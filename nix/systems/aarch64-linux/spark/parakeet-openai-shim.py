"""OpenAI-compatible /v1/audio/transcriptions for Parakeet NIM.

The NVIDIA Parakeet NIM HTTP API exposes a transcription endpoint, but the
served DGX Spark profile does not accept arbitrary OpenAI-style model names; it
selects the model by language/profile. This shim keeps clients on the normal
OpenAI audio API shape while forwarding the request Parakeet actually accepts.

Streaming: when the request sets ``stream=true`` the response is Server-Sent
Events (``text/event-stream``) in OpenAI's transcription format —
``transcript.text.delta`` fragments followed by a terminal
``transcript.text.done`` carrying the full text — so OpenAI clients work
unmodified. The served NIM profile is offline (``mode=ofl``, one-shot HTTP),
so there are no native partial hypotheses to proxy; the shim runs the same
one-shot recognition and replays the final transcript as word-level deltas.
The non-streaming path is unchanged.
"""

import json
import os
import re
from collections.abc import AsyncIterator
from typing import Annotated

import httpx
import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, Response, UploadFile
from fastapi.responses import StreamingResponse

DEFAULT_LANGUAGE = os.environ.get("PARAKEET_LANGUAGE", "en-US")
UPSTREAM_URL = os.environ["PARAKEET_UPSTREAM_URL"].rstrip("/")
TIMEOUT_SECONDS = float(os.environ.get("PARAKEET_TIMEOUT_SECONDS", "300"))

app = FastAPI(title="Parakeet OpenAI-compatible transcription shim")


def _as_text(payload: object) -> str:
    if isinstance(payload, dict):
        text = payload.get("text", "")
        return text if isinstance(text, str) else str(text)
    return str(payload)


def _normalize_language(lang: str | None) -> str:
    """Map a client language code to a locale the NIM actually serves.

    The DGX Spark Parakeet profile loads specific locales (e.g. ``en-US``) and
    returns 404 "Model not found for language <x>" for bare/alias codes like
    ``en`` — which is exactly what Home Assistant sends. When the requested
    language shares its base language with the configured default
    (``DEFAULT_LANGUAGE``), use the default's full locale so those clients work.
    Genuinely different languages pass through unchanged (the NIM rejects the
    ones it has no model for, which is the correct, honest failure).
    """
    lang = (lang or "").strip()
    if not lang:
        return DEFAULT_LANGUAGE
    if lang.split("-")[0].lower() == DEFAULT_LANGUAGE.split("-")[0].lower():
        return DEFAULT_LANGUAGE
    return lang


async def _transcribe(
    audio: bytes,
    filename: str,
    content_type: str,
    language: str | None,
    prompt: str | None,
    temperature: float | None,
) -> str:
    """Run one-shot recognition against the Parakeet NIM and return the text."""
    data: dict[str, str] = {
        "language": _normalize_language(language),
        "response_format": "json",
    }
    if prompt:
        data["prompt"] = prompt
    if temperature is not None:
        data["temperature"] = str(temperature)

    files = {"file": (filename, audio, content_type)}
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
            upstream = await client.post(UPSTREAM_URL, data=data, files=files)
    except httpx.HTTPError as exc:
        raise HTTPException(502, f"Parakeet upstream request failed: {exc}") from exc

    if upstream.status_code >= 400:
        raise HTTPException(upstream.status_code, upstream.text)

    try:
        payload = upstream.json()
    except ValueError as exc:
        raise HTTPException(
            502, "Parakeet upstream returned non-JSON response"
        ) from exc

    return _as_text(payload).strip()


def _sse(event: dict[str, str]) -> str:
    return f"data: {json.dumps(event)}\n\n"


@app.get("/v1/health/ready")
async def health_ready() -> dict[str, str]:
    return {"status": "ready"}


@app.post("/v1/audio/transcriptions", response_model=None)
async def transcriptions(
    file: Annotated[UploadFile, File(description="Audio file to transcribe")],
    model: Annotated[
        str | None, Form()
    ] = None,  # OpenAI clients require it; NIM ignores it.
    language: Annotated[str | None, Form()] = None,
    prompt: Annotated[str | None, Form()] = None,
    response_format: Annotated[str | None, Form()] = "json",
    temperature: Annotated[float | None, Form()] = None,
    stream: Annotated[bool | None, Form()] = None,
) -> Response | dict[str, str]:
    del model  # Compatibility field only; raw Parakeet NIM rejects arbitrary model ids.

    audio = await file.read()
    filename = file.filename or "audio"
    content_type = file.content_type or "application/octet-stream"

    # Resolve the transcript up front so upstream failures surface as normal
    # HTTP errors instead of mid-stream; the offline NIM yields no partials.
    text = await _transcribe(
        audio, filename, content_type, language, prompt, temperature
    )

    if stream:
        # OpenAI streaming-transcription SSE: incremental transcript.text.delta
        # fragments (concatenating to the full text), then a terminal
        # transcript.text.done. Fragments preserve trailing whitespace so a
        # client that joins deltas reconstructs the transcript exactly.
        async def events() -> AsyncIterator[str]:
            for fragment in re.findall(r"\S+\s*", text):
                yield _sse({"type": "transcript.text.delta", "delta": fragment})
            yield _sse({"type": "transcript.text.done", "text": text})

        return StreamingResponse(
            events(),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    fmt = (response_format or "json").lower()
    if fmt == "text":
        return Response(text, media_type="text/plain")
    if fmt in {"json", "verbose_json"}:
        return {"text": text}
    raise HTTPException(400, f"unsupported response_format: {response_format}")


if __name__ == "__main__":
    uvicorn.run(
        app,
        host=os.environ.get("PARAKEET_HOST", "127.0.0.1"),
        port=int(os.environ.get("PARAKEET_PORT", "8102")),
    )
