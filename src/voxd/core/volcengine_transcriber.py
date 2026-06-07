"""
Volcengine (火山引擎/豆包) speech recognition transcriber.

Uses the Seed-ASR / BigModel HTTP flash API:
  POST https://openspeech.bytedance.com/api/v3/auc/bigmodel/recognize/flash

Auth: ``x-api-key`` header + ``X-Api-Resource-Id``.
No WebSocket, no binary protocol — plain JSON in, JSON out.
"""

from __future__ import annotations

import base64
import json
import uuid
from pathlib import Path
from typing import Any

from voxd.utils.libw import verbo, verr

FLASH_URL = "https://openspeech.bytedance.com/api/v3/auc/bigmodel/recognize/flash"
SUCCESS_CODE = 20000000


class VolcengineTranscriber:
    """File-based Volcengine ASR transcriber (HTTP flash API).

    Reads a WAV file, sends it as base64 JSON to the flash recognition
    endpoint, and returns the recognised text.

    Compatible with the ``transcribe(audio_path) -> (text, raw_text)``
    interface used by ``WhisperTranscriber``.
    """

    def __init__(
        self,
        api_key: str,
        resource_id: str = "volc.seedasr.auc",
        *,
        timeout: int = 60,
    ):
        self.api_key = api_key
        self.resource_id = resource_id
        self.timeout = timeout

    def transcribe(self, audio_path: str | Path) -> tuple[str | None, str | None]:
        """Transcribe a WAV file.

        Returns
        -------
        (clean_text, raw_text) — same signature as ``WhisperTranscriber.transcribe``.
        """
        try:
            import requests
        except ImportError:
            verr("[volcengine] 'requests' not available")
            return None, None

        # Read and encode audio
        audio_path = Path(audio_path)
        if not audio_path.exists():
            verr(f"[volcengine] Audio file not found: {audio_path}")
            return None, None

        try:
            with open(audio_path, "rb") as f:
                raw = f.read()
                verbo(f"[volcengine] Read {len(raw)} bytes from {audio_path}")
                if len(raw) < 48:
                    verr(f"[volcengine] Audio file too small (header only): {len(raw)} bytes")
                    return None, None
                audio_b64 = base64.b64encode(raw).decode()
        except Exception as exc:
            verr(f"[volcengine] Failed to read audio: {exc}")
            return None, None

        reqid = uuid.uuid4().hex
        headers = {
            "X-Api-Key": self.api_key,
            "X-Api-Resource-Id": self.resource_id,
            "X-Api-Request-Id": reqid,
            "X-Api-Sequence": "-1",
            "Content-Type": "application/json",
        }
        body: dict[str, Any] = {
            "user": {"uid": "voxd-asr"},
            "audio": {
                "format": audio_path.suffix.lstrip(".").lower() or "wav",
                "data": audio_b64,
            },
            "request": {
                "model_name": "bigmodel",
                "show_utterances": True,
                "enable_itn": True,
            },
        }

        verbo(f"[volcengine] Sending {audio_path.name} to flash API...")
        try:
            resp = requests.post(
                FLASH_URL, headers=headers, json=body, timeout=self.timeout
            )
        except Exception as exc:
            verr(f"[volcengine] HTTP request failed: {exc}")
            return None, None

        if resp.status_code != 200:
            verr(f"[volcengine] API returned {resp.status_code}: {resp.text[:200]}")
            return None, None

        # Check business status code in response header
        status_code = resp.headers.get("X-Api-Status-Code", "")
        status_msg = resp.headers.get("X-Api-Message", "")

        if status_code == "20000003":
            verbo("[volcengine] Silent audio, no transcript")
            return "", ""

        if status_code not in ("20000000", ""):
            verr(f"[volcengine] API error [{status_code}]: {status_msg}")
            return None, None

        try:
            data = resp.json()
        except Exception as exc:
            verr(f"[volcengine] JSON parse failed: {exc}")
            return None, None

        text = self._extract_text(data)
        if text:
            verbo(f"[volcengine] Result: {text[:80]}...")
            return text, text
        verbo("[volcengine] Empty result (no speech detected)")
        return None, None

    @staticmethod
    def _extract_text(data: dict) -> str | None:
        """Extract recognised text from the API response."""
        try:
            # Direct text field
            result = data.get("result", {})
            if isinstance(result, dict):
                text = result.get("text", "")
                if text:
                    return text.strip()
                # Utterances
                utterances = result.get("utterances", [])
                if utterances:
                    texts = []
                    for u in utterances:
                        t = u.get("text", "").strip()
                        if t:
                            texts.append(t)
                    if texts:
                        return " ".join(texts)
            return None
        except Exception as exc:
            verr(f"[volcengine] Failed to extract text: {exc}")
            return None


# ---------------------------------------------------------------------------
# Factory helper — build from AppConfig
# ---------------------------------------------------------------------------

def from_config(cfg) -> VolcengineTranscriber | None:
    """Create a ``VolcengineTranscriber`` from an ``AppConfig`` instance.

    Returns ``None`` if the config doesn't have valid credentials.
    """
    api_key = cfg.data.get("volcengine_access_token", "")
    resource_id = cfg.data.get(
        "volcengine_resource_id", "volc.seedasr.auc"
    )
    if not api_key:
        return None
    return VolcengineTranscriber(api_key=api_key, resource_id=resource_id)
