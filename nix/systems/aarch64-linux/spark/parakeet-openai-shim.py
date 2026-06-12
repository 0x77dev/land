"""OpenAI-compatible /v1/audio/transcriptions for Parakeet NIM.

The NVIDIA Parakeet NIM HTTP API exposes a transcription endpoint, but the
served DGX Spark profile does not accept arbitrary OpenAI-style model names; it
selects the model by language/profile. This shim keeps clients on the normal
OpenAI audio API shape while forwarding the request Parakeet actually accepts.
"""

import os
from typing import Annotated

import httpx
import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, Response, UploadFile

DEFAULT_LANGUAGE = os.environ.get("PARAKEET_LANGUAGE", "en-US")
UPSTREAM_URL = os.environ["PARAKEET_UPSTREAM_URL"].rstrip("/")
TIMEOUT_SECONDS = float(os.environ.get("PARAKEET_TIMEOUT_SECONDS", "300"))

app = FastAPI(title="Parakeet OpenAI-compatible transcription shim")


def _as_text(payload: object) -> str:
    if isinstance(payload, dict):
        text = payload.get("text", "")
        return text if isinstance(text, str) else str(text)
    return str(payload)


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
) -> Response | dict[str, str]:
    del model  # Compatibility field only; raw Parakeet NIM rejects arbitrary model ids.

    audio = await file.read()
    data: dict[str, str] = {
        "language": language or DEFAULT_LANGUAGE,
        "response_format": "json",
    }
    if prompt:
        data["prompt"] = prompt
    if temperature is not None:
        data["temperature"] = str(temperature)

    files = {
        "file": (
            file.filename or "audio",
            audio,
            file.content_type or "application/octet-stream",
        )
    }
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

    text = _as_text(payload).strip()
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
