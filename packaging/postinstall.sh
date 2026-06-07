#!/bin/sh
set -e

# Create input group if missing
getent group input >/dev/null 2>&1 || groupadd input || true

# Install udev rule (should already be staged by contents, but ensure reload)
if [ -f "/etc/udev/rules.d/99-uinput.rules" ]; then
  udevadm control --reload-rules || true
  udevadm trigger || true
fi

# Ensure uinput kernel module is loaded now and on boot (Wayland typing requires it)
if ! lsmod 2>/dev/null | grep -q '^uinput\b'; then
  modprobe uinput || true
fi
# Persist across reboots
if [ ! -f "/etc/modules-load.d/uinput.conf" ]; then
  echo uinput > /etc/modules-load.d/uinput.conf 2>/dev/null || true
fi
# Retrigger udev so the new rule takes effect immediately
udevadm trigger /dev/uinput || true

# If installed via sudo, add that user to 'input' group for ydotool permissions
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  usermod -aG input "$SUDO_USER" 2>/dev/null || true
fi

# Optional: load SELinux policy if shipped (rpm-based systems)
if command -v getenforce >/dev/null 2>&1; then
  if [ "$(getenforce 2>/dev/null)" = "Enforcing" ]; then
    if command -v semodule >/dev/null 2>&1 && [ -f "/opt/voxd/packaging/whisper_execmem.pp" ]; then
      semodule -i /opt/voxd/packaging/whisper_execmem.pp || true
    fi
  fi
fi

echo "voxd installed. Each user should run: voxd --setup"

# ── Create venv and install Python deps ──────────────────────────────────────
APPDIR="/opt/voxd"

# Pick a Python >= 3.9
pick_python() {
  for c in python3.12 python3.11 python3.10 python3.9 python3 python; do
    if command -v "$c" >/dev/null 2>&1; then
      ver="$("$c" -c 'import sys; print(sys.version_info.major * 100 + sys.version_info.minor)' 2>/dev/null)"
      # Require Python >= 3.9 (value >= 309)
      [ -n "$ver" ] && [ "$ver" -ge 309 ] 2>/dev/null && echo "$c" && return 0
    fi
  done
  echo ""
}

PY="$(pick_python)"

if [ -z "$PY" ]; then
  echo "[voxd] WARNING: No Python >= 3.9 found. Run 'voxd --setup' manually after installing Python."
else
  echo "[voxd] Setting up Python venv at $APPDIR/.venv ..."
  if [ ! -x "$APPDIR/.venv/bin/python" ]; then
    "$PY" -m venv --system-site-packages "$APPDIR/.venv" 2>&1 || echo "[voxd] WARNING: venv creation failed (install python3-venv). Run 'voxd --setup' manually."
  fi

  if [ -x "$APPDIR/.venv/bin/python" ]; then
    VPY="$APPDIR/.venv/bin/python"
    echo "[voxd] Installing Python dependencies (this may take a minute)..."
    "$VPY" -m pip install --upgrade --disable-pip-version-check -q pip 2>&1 || true
    "$VPY" -m pip install --disable-pip-version-check -q \
      "sounddevice>=0.5" psutil numpy requests pyyaml tqdm pyperclip websockets \
      platformdirs 2>&1 || echo "[voxd] WARNING: Some pip packages failed. Run 'voxd --setup' to retry."
    # Additional optional packages: try silently, warn on failure
    for pkg in importlib-resources PyQt6 pyqtgraph; do
      "$VPY" -c "import ${pkg%%-*}" 2>/dev/null || \
        "$VPY" -m pip install --disable-pip-version-check -q "$pkg" 2>/dev/null || \
        echo "[voxd] WARNING: Optional package '$pkg' not installed. Some features may be unavailable."
    done
    echo "[voxd] Venv setup complete."
  fi
fi

# Audio tip: suggest Pulse/ALSA plugins if 'pulse' input is missing
# Prefer venv Python if available; else fall back to a system Python
AUDIO_PY=""
if [ -x "$APPDIR/.venv/bin/python" ]; then
  AUDIO_PY="$APPDIR/.venv/bin/python"
elif [ -n "${PY:-}" ]; then
  AUDIO_PY="$PY"
elif command -v python3 >/dev/null 2>&1; then
  AUDIO_PY="python3"
elif command -v python >/dev/null 2>&1; then
  AUDIO_PY="python"
fi
if [ -n "$AUDIO_PY" ]; then
  "$AUDIO_PY" - <<'PY' 2>/dev/null || true
import sys
try:
    import sounddevice as sd  # type: ignore
    names = [str(d.get('name','')).lower() for d in sd.query_devices()]
    has_pulse = any('pulse' in n for n in names)
    if not has_pulse:
        print('[voxd] Tip: No "pulse" device detected. Install your distro\'s pulse shim and ALSA plugins:')
        print('  - Debian/Ubuntu: sudo apt install alsa-plugins pavucontrol (ensure pulseaudio or pipewire-pulse active)')
        print('  - Fedora: sudo dnf install alsa-plugins-pipewire pavucontrol (ensure pipewire-pulseaudio active)')
        print('  - openSUSE: sudo zypper install alsa-plugins-pulse pavucontrol (ensure pulse active)')
        print('  - Arch: sudo pacman -S alsa-plugins pipewire-pulse pavucontrol')
except Exception:
    pass
PY
fi


