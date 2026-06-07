# VOXD — Reasonix project context

## Stack

- **Python 3.9+** — with `from __future__ import annotations` in many files for deferred eval.
- **PyQt6** — GUI, tray, and settings dialog (`src/voxd/gui/`, `tray/`).
- **sounddevice + numpy** — audio capture (16 kHz mono via `AudioRecorder` in `core/recorder.py`).
- **whisper.cpp** — local speech-to-text (external C++ binary, built by `setup.sh`).
- **Volcengine ASR** — optional cloud streaming ASR via `volcengine_transcriber.py` (WebSocket binary protocol, requires `websockets`).
- **Hatchling** — build backend, `package-dir = "src"`.

## Layout

| Path | What |
|---|---|
| `src/voxd/core/` | App core: config, recorder, transcriber, volcengine_transcriber, typer, AIPP, logger, model manager |
| `src/voxd/cli/` | CLI entry points (`cli_main.py`) |
| `src/voxd/gui/` | PyQt6 main window + settings dialog |
| `src/voxd/tray/` | System tray UI |
| `src/voxd/flux/` | Voice-activity-detection-driven mode (beta) |
| `src/voxd/utils/` | IPC server/client, languages, performance logging, setup helpers |
| `src/voxd/defaults/` | Default YAML config shipped with package |
| `src/voxd/assets/` | App icons (0–9, PNG) |
| `tests/` | Pytest suite, one file per module, conftest isolates XDG dirs |
| `packaging/` | Packaging scripts, systemd services, udev rules, nfpm YAML |
| `setup.sh` | Idempotent dev installer (system pkgs + venv + whisper.cpp build) |

## Commands

| Action | Command |
|---|---|
| Run app | `voxd` (entry point `voxd.__main__:main`) |
| Download models | `voxd-model` (entry point `voxd.models:_cli`) |
| Test | `python -m pytest` (config: `[tool.pytest.ini_options]` in `pyproject.toml`) |
| Install (dev) | `bash setup.sh` — system pkgs + venv + whisper.cpp build |

No dedicated lint/format command or pre-commit config detected.

## Conventions (visible in code)

- **Package dir**: `src/` layout — all imports prefixed `voxd.*`.
- **Imports**: stdlib → third-party → `voxd.*` (blank-line separation). Heavy deps imported lazily inside methods to break circular imports.
- **Singleton config**: `AppConfig` in `core/config.py` loads `default_config.yaml` + user YAML overlay, accessed via `AppConfig()` (module-level instance).
- **Tests**: pytest with autouse `isolate_xdg_dirs` fixture that mocks `XDG_CONFIG_HOME` / `XDG_DATA_HOME` per test.
- **Session state**: mutable `AppConfig.data` dict — beware of stale reads after side effects.

## Watch out for

- **Circular imports**: `voxd.utils.libw` warns against importing `voxd.paths` or `voxd.core.config` at module top-level. Lazy-import inside function bodies.
- **External binaries**: whisper.cpp and llama.cpp are NOT bundled — `setup.sh` clones + builds them. The `packaging/` dir includes systemd services (`voxd-tray.service`, `ydotoold.service`).
- **`setup.sh` is idempotent** but verbose (logs to a dated `*-setup-log.txt`). Re-running skips completed steps.
- **Config file**: YAML at XDG config home; version string is `"mr.batman"` (manual bump on release).
