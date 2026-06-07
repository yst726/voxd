# VOXD - Linux 语音输入工具 🗣️⌨️
<div align="center">
  <img src="src/voxd/assets/voxd-1.png" alt="VOXD logo" width="128" />
</div>

在后台运行，在任何 Linux 应用中实现快速**语音转文字输入**。  
使用 <span style="color:#FF4500">**本地**（离线）</span>语音处理，可选 <span style="color:#FF4500">**本地**</span>（离线）AI 文本后处理。  
老旧 CPU 也能流畅运行，无需 GPU。

按下<span style="color:#FF4500">**快捷键**</span> → 说话 → 再次按下快捷键 → 文字即刻出现在光标处，甚至可以用 AI 重写为诗歌或 C++ 代码。

**测试验证过的系统：**
- Arch / Hyprland
- Omarchy 3.0
- Ubuntu 24.04 / GNOME
- Ubuntu 25.04 / Sway
- Fedora 42 / KDE
- Pop!_OS 22 / COSMIC
- Mint 22 / Cinnamon
- openSUSE / Leap 15.6

## 功能亮点

| 特性 | 说明 |
|---|---|
| **Whisper.cpp** 引擎 | 本地离线快速语音识别 |
| **火山引擎 ASR**（云端） | 通过火山引擎/豆包实现的云端流式识别。实时输出中间结果 + 最终修正。中文识别效果更好 |
| **模拟打字** | 直接打字到当前焦点窗口。甚至支持 Wayland！（通过 *ydotool*） |
| **剪贴板** | 自动复制到剪贴板，可按需粘贴 |
| **多语言** | 支持 99+ 种语言。提供默认语言配置和会话级语言覆盖 |
| **AIPP** AI 后处理 | 通过本地或云端 LLM 进行 AI 重写。内置提示词编辑器 |
| **多界面** | CLI、GUI（PyQt6）、系统托盘、FLUX（语音活动检测触发，Beta） |
| **日志 & 性能** | 会话日志 + 可选的本地性能数据记录（CSV） |

## 安装

完成两步：
1. <span style="color:#FF4500">**安装 VOXD**</span>
2. <span style="color:#FF4500">**设置快捷键**</span>

### 1. 安装 VOXD

#### 从 Release 安装（推荐）
从最新 Release 下载对应系统和架构的包，然后用包管理器安装。

最新构建： [GitHub Releases (Latest)](https://github.com/jakovius/voxd/releases/latest)

#### **Ubuntu / Debian (.deb)**

```bash
sudo apt update
sudo apt install -y ./voxd_*_amd64.deb    # ARM 系统用 voxd_*_arm64.deb
```

---

#### **Fedora (.rpm)**

```bash
sudo dnf update -y
sudo dnf install -y ./voxd-*-x86_64.rpm  # ARM 系统用 arm64 版本
```

---

#### **Arch Linux (.pkg.tar.zst)**

```bash
sudo pacman -Sy
sudo pacman -U ./voxd-*-x86_64.pkg.tar.zst    # ARM 系统用 arm64 版本
```

---

#### **openSUSE (.rpm)**

```bash
sudo zypper refresh
sudo zypper install --force-resolution ./voxd-*-x86_64.rpm   # ARM 系统用 arm64 版本
```

#### 或者从源码安装：

```bash
git clone https://github.com/jakovius/voxd.git
cd voxd && ./setup.sh
# 需要 sudo 安装系统包，Wayland 系统需要重启（ydotool 配置）
# 启动器（GUI、Tray、Flux）会自动安装
```

安装过程非交互式，详细日志会保存在仓库目录下（如 `2025-09-18-setup-log.txt`）。

**重启系统！**（除非在 X11 系统上；现代系统大多是 Wayland，打字需要 ydotool，重启后才能完成用户配置）

### 2. **设置全局快捷键**

a. 打开系统键盘快捷键设置：
   - *GNOME:* 设置 → 键盘 → "自定义快捷键"
   - *KDE / XFCE / Cinnamon:* 类似路径
   - *Hyprland / Sway:* 直接在配置文件中添加键绑定

b. **命令**（必须完全一致）：

`bash -c 'voxd --trigger-record'`

c. 点击 **添加 / 保存**。

首次运行请在终端中执行 `voxd` 或 `voxd --setup` 命令，会进行初始配置（语音模型、AIPP 的 LLM 模型、ydotool 用户设置）。

### <span style="color:#FF4500">准备就绪！→ 用语音在任何地方输入！</span>

---

## 使用方式

### 通过应用启动器或终端启动：

```bash
voxd        # CLI 交互模式；'h' 显示内部命令。首次运行需要初始配置
voxd --rh   # 直接启动快捷键控制的连续录音模式
voxd -h     # 显示顶层帮助和快捷操作
voxd --gui  # 友好的 GUI 窗口——放在后台，用快捷键触发语音输入
voxd --tray # 系统托盘模式；不妨碍其他操作（同样通过快捷键触发）
voxd --flux # VAD（语音活动检测）模式，说话即识别（Beta）
```

VOXD 在后台运行时，到任意想要打字的应用中：

| 按键操作 | VOXD 响应 |
|---|---|
| **第一次按下** | 开始录音 |
| **第二次按下** | 停止录音 → [转写 → 复制到剪贴板] → 打字到当前焦点窗口 |

在 `--flux`（Beta）模式下，**直接说话即可**。

### 开机自启
建议开启 VOXD 用户守护进程，确保始终可用：

- 启用：`voxd --autostart true`
- 禁用：`voxd --autostart false`

启用后会自动在登录时启动 `voxd --tray`，优先使用 systemd 用户服务，否则回退到 XDG 自动启动配置（`~/.config/autostart/voxd-tray.desktop`）。

### 语言设置

- **支持的语言代码**：ISO 639-1（如 `en`、`es`、`de`、`sv`）和 `auto`（自动检测，不推荐）
- **默认语言**：`en`。可每次运行时临时切换或持久化保存
- **CLI 临时切换**（仅本次会话）：
```bash
voxd --gui  --lang auto
voxd --tray --lang es
voxd --flux --lang de
voxd --rh   --lang sv
```
- **CLI 持久化**：`voxd --cfg` 打开配置文件进行编辑：
```yaml
# ~/.config/voxd/config.yaml
language: sv  # 或 'auto'、'es' 等
```
- **GUI/托盘持久化**：菜单 → **Language**，保存到 `~/.config/voxd/config.yaml`
- **模型说明**：非英语语言需要使用多语言 Whisper 模型（不要用 `*.en.bin`）。可通过 GUI "Whisper Models" 或 `voxd-model` 安装/切换（如 `ggml-base.bin`、`small`、`medium`、`large-v3`）
- **提示**：`auto` 模式效果不错，但指定具体语言可以提高准确率。如果使用非英语语言但用的是纯英语模型，VOXD 会发出警告，转写质量可能下降

### ⌨️ 粘贴行为

VOXD **同时尝试 `Ctrl+V` 和 `Ctrl+Shift+V`** 粘贴，确保在 GUI 应用和终端
都能工作，无需手动切换配置。粘贴后自动恢复原剪贴板内容，不污染剪贴板历史。

**如果在某个应用里出现重复文字**（如 Chrome/Chromium），说明该应用同时
支持两种快捷键。解决办法：

1. 打开 `chrome://settings/content/clipboard`
2. 或安装一个拦截某一种粘贴快捷键的扩展
3. 或在 `~/.config/voxd/config.yaml` 设 `ctrl_v_paste: true`，
   只用 `Ctrl+V`（不回退，不重复）


### ☁️ 火山引擎（豆包）云端 ASR

VOXD 支持通过火山引擎实现**云端流式语音识别**，作为本地 whisper.cpp 的替代方案。
它在录音时实时发送音频，显示实时中间结果，并在录音结束后返回最终修正文本。

#### 前提条件
- 可访问 `openspeech.bytedance.com` 的网络
- 火山引擎语音识别服务账号（[控制台](https://console.volcengine.com/speech/app)）
- `websockets` Python 包（voxd >= 1.4.1 已自带）

#### 配置方式

**通过设置界面：** Options → Settings → **Volcengine ASR (cloud)**

**或编辑 `~/.config/voxd/config.yaml`：**
```yaml
volcengine_asr_enabled: true
volcengine_access_token: "你的 API Key"
volcengine_resource_id: "volc.seedasr.auc"
```

#### 行为说明
- 录音过程中，状态栏会**实时显示**中间识别结果
- 停止录音后，服务器返回**最终修正**后的转写文本（基于完整音频上下文）
- 结果会经过 AIPP（如已启用）后，打字到当前焦点窗口

#### 本地与云端切换
```yaml
# whisper.cpp（默认，离线）
volcengine_asr_enabled: false

# 火山引擎云端（流式，中文效果更好）
volcengine_asr_enabled: true
```

### 🎙️ 管理语音模型

VOXD 需要一个 Whisper GGML 模型文件。应用内置了一个默认模型（base.en）。
可通过 GUI 的模型管理器或 CLI 终端获取其他模型。
语音模型下载到 `~/.local/share/voxd/models/`，VOXD 应用会自动识别。

CLI 模型管理示例：
```bash
voxd-model list                     # 显示已下载的模型
voxd-model install tiny.en          # 下载另一个模型
voxd-model --no-check install base.en  # 下载模型并跳过 SHA-1 校验
voxd-model remove tiny.en           # 删除模型
voxd-model use tiny.en              # 设为默认模型（修改 config.yaml）
```

可下载的模型（大小 MB）：

| 模型 | 大小 (MB) | 文件名 |
|-------|----------:|----------|
| tiny | 75 | ggml-tiny.bin |
| tiny-q5_1 | 31 | ggml-tiny-q5_1.bin |
| tiny-q8_0 | 42 | ggml-tiny-q8_0.bin |
| tiny.en | 75 | ggml-tiny.en.bin |
| tiny.en-q5_1 | 31 | ggml-tiny.en-q5_1.bin |
| tiny.en-q8_0 | 42 | ggml-tiny.en-q8_0.bin |
| base | 142 | ggml-base.bin |
| base-q5_1 | 57 | ggml-base-q5_1.bin |
| base-q8_0 | 78 | ggml-base-q8_0.bin |
| base.en | 142 | ggml-base.en.bin |
| base.en-q5_1 | 57 | ggml-base.en-q5_1.bin |
| base.en-q8_0 | 78 | ggml-base.en-q8_0.bin |
| small | 466 | ggml-small.bin |
| small-q5_1 | 181 | ggml-small-q5_1.bin |
| small-q8_0 | 252 | ggml-small-q8_0.bin |
| small.en | 466 | ggml-small.en.bin |
| small.en-q5_1 | 181 | ggml-small.en-q5_1.bin |
| small.en-q8_0 | 252 | ggml-small.en-q8_0.bin |
| small.en-tdrz | 465 | ggml-small.en-tdrz.bin |
| medium | 1500 | ggml-medium.bin |
| medium-q5_0 | 514 | ggml-medium-q5_0.bin |
| medium-q8_0 | 785 | ggml-medium-q8_0.bin |
| medium.en | 1500 | ggml-medium.en.bin |
| medium.en-q5_0 | 514 | ggml-medium.en-q5_0.bin |
| medium.en-q8_0 | 785 | ggml-medium.en-q8_0.bin |
| large-v1 | 2900 | ggml-large-v1.bin |
| large-v2 | 2900 | ggml-large-v2.bin |
| large-v2-q5_0 | 1100 | ggml-large-v2-q5_0.bin |
| large-v2-q8_0 | 1500 | ggml-large-v2-q8_0.bin |
| large-v3 | 2900 | ggml-large-v3.bin |
| large-v3-q5_0 | 1100 | ggml-large-v3-q5_0.bin |
| large-v3-turbo | 1500 | ggml-large-v3-turbo.bin |
| large-v3-turbo-q5_0 | 547 | ggml-large-v3-turbo-q5_0.bin |
| large-v3-turbo-q8_0 | 834 | ggml-large-v3-turbo-q8_0.bin |

---

## ⚙️ 用户配置

在 GUI 和托盘模式（"Settings"）中有可视化界面，但配置文件位置：
`~/.config/voxd/config.yaml`

---

## 🧠 AI 后处理 (AIPP)

你的语音文字可以自动被整理成：整洁的邮件、一首诗、甚至是一段代码！

VOXD 可选地使用**本地**（**llama.cpp**、**Ollama**）或云端 LLM（如 **OpenAI、Anthropic、xAI**）对转写结果进行后处理。
本地方案中，**llama.cpp** 开箱即用，附带默认模型。
你也可以**[安装 Ollama](https://ollama.ai)** 并下载可在本地运行的模型，例如 `ollama pull gemma3:latest`。
所有设置都可以在 GUI 中直接配置和管理。

### 启用 AIPP

在 CLI 模式下，使用 `--aipp` 参数。
在 GUI 或托盘模式下，所有相关设置在 "*AI Post-Processing*" 中。
**选择供应商和模型**——模型与其供应商绑定！
**编辑提示词**——选择 "*Manage prompts*" 或 "*Prompts*"，最多可编辑 4 个提示词。

## 支持的供应商：

- **llama.cpp**（本地）
- **Ollama**（本地）
- **OpenAI**
- **Anthropic**
- **xAI**

---

### AIPP 模型管理

#### **模型存储位置**
```
~/.local/share/voxd/llamacpp_models/
```

#### **添加模型 | 要求**

- **仅支持 GGUF** 格式（`.gguf` 扩展名）
- **推荐使用量化模型**（Q4_0、Q4_1、Q5_0 等）
- ❌ **不支持：** PyTorch（`.pth`）、Safetensors（`.safetensors`）、ONNX

**第一步：** 从 [Hugging Face](https://huggingface.co/models?search=gguf) 下载 `.gguf` 模型
```bash
# 示例：下载到模型目录
cd ~/.local/share/voxd/llamacpp_models/
wget https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf?download=true
```

**第二步：** 重启 VOXD
VOXD 启动时会自动识别模型目录中的所有 `.gguf` 文件并可供选择。

**第三步：** 在 VOXD GUI 中选择
*AI Post-Processing → Provider: `llamacpp_server` → Model: `qwen2.5-3b-instruct`*

#### **AIPP 推荐模型**

| 模型 | 大小 | 内存 | 质量 | 最佳用途 |
|-------|------|-----|---------|----------|
| **qwen2.5-3b-instruct** | 1.9GB | 3GB | 优秀 | 默认，高质量 |
| **qwen2.5-coder-1.5b** | 900MB | 2GB | 良好 | 代码相关任务 |

### 🔧 高级配置

编辑 `~/.config/voxd/config.yaml`：

```yaml
# llama.cpp 设置
llamacpp_server_path: "llama.cpp/build/bin/llama-server"
llamacpp_server_url: "http://localhost:8080"
llamacpp_server_timeout: 30

# 各供应商的已选模型（由 VOXD 自动更新）
aipp_selected_models:
  llamacpp_server: "qwen2.5-3b-instruct-q4_k_m"
```

---

### 🔑 设置云端 API 密钥

出于安全考虑，请注意 API 密钥的存储位置。
要使用云端 AI 供应商，请先设置所需的环境变量再运行 VOXD。
例如，将这些行添加到 `.bashrc`、`.zshrc` 或对应的 shell 配置文件中（替换为你的密钥）：

```sh
# OpenAI
export OPENAI_API_KEY="sk-..."

# Anthropic
export ANTHROPIC_API_KEY="..."

# xAI
export XAI_API_KEY="..."
```

**注意：** 缺少 API 密钥时，对应的云端供应商将（显然）无法工作。

---

## 🩺 故障排查速查表

注意：在非常嘈杂的环境中，应用可能无法完美运行 :)

| 症状 | 可能原因 / 解决方法 |
|---|---|
| *出现随机 [BLANK_AUDIO]、无转写结果或结果很差* | 很可能是麦克风音量过高（削波失真）。VOXD 会尝试自动优化麦克风设置（可配置），但请检查输入音量是否低于 45% |
| *按快捷键无反应* | 用此命令调试：`gnome-terminal -- bash -c "voxd --trigger-record; read -p 'Press Enter...'"` |
| *转写成功但未打字* | Wayland: `ydotool` 未安装或用户不在 `input` 组 → 运行 `setup_ydotool.sh`，重新登录 |
| *"whisper-cli not found"* | 编译失败 — 重新运行 `./setup.sh` 并检查诊断输出 |
| *麦克风无法录音* | 检查系统设置：**输入设备是否存在** / **是否启用** / **是否静音** |
| 剪贴板为空 | 确保安装了 `xclip` 或 `wl-copy`（重新运行 `setup.sh`） |

### 音频故障排查

- 列出设备：`python -m sounddevice`（检查是否有一个名为 "pulse" 的设备）
- 优先使用 PulseAudio/PipeWire：在 `~/.config/voxd/config.yaml` 中设置：

```yaml
audio_prefer_pulse: true
audio_input_device: "pulse"   # 或指定设备名称或索引
```

- 如果没有 `pulse` 设备：
  - Debian/Ubuntu：`sudo apt install alsa-plugins pavucontrol`（确保 `pulseaudio` 或 `pipewire-pulse` 正在运行）
  - Fedora/openSUSE：`sudo dnf install alsa-plugins-pulseaudio pavucontrol`（确保 `pipewire-pulseaudio` 正在运行）
  - Arch：`sudo pacman -S alsa-plugins pipewire-pulse pavucontrol`

- 如果 16kHz 在 ALSA 下失败：VOXD 会自动降级到设备默认采样率，并优先使用 `pulse`（如可用）

---

## 📜 许可证与致谢

* VOXD – © 2025 Jakov Ivkovic – **MIT** 许可证（参见 [`LICENSE`](LICENSE)）。标志和品牌资产：参见 [`ASSETS_LICENSE`](ASSETS_LICENSE)。商标：参见 [`TRADEMARKS.md`](TRADEMARKS.md)。
* 语音引擎基于 [**ggml-org/whisper.cpp**](https://github.com/ggml-org/whisper.cpp)（MIT）和 OpenAI Whisper 模型（MIT）
* 自动打字/粘贴基于 [**ReimuNotMoe/ydotool**](https://github.com/ReimuNotMoe/ydotool)（AGPLv3）
* 转写后处理基于 [**ggml-org/llama.cpp**](https://github.com/ggml-org/llama.cpp)（MIT）

---

## 🗑️ 卸载

### 1. 包管理器安装（deb/rpm/arch）
如果通过原生包管理器安装：

- **Ubuntu/Debian**
```bash
sudo apt remove voxd
```

- **Fedora**
```bash
sudo dnf remove -y voxd
```

- **openSUSE**
```bash
sudo zypper --non-interactive remove voxd
```

- **Arch**
```bash
sudo pacman -R voxd
```

注意：此操作会删除系统文件（如 `/opt/voxd` 和 `/usr/bin/voxd`）。用户数据（模型、配置、日志）会保留，见下方"可选清理"。

### 2. 源码安装（`./setup.sh`）
如果克隆了仓库并运行了 `./setup.sh`，直接运行仓库中的卸载脚本：

```bash
# 在仓库目录中执行
./uninstall.sh
```

### 3. pipx 安装
如果通过 **pipx** 安装：

```bash
pipx uninstall voxd
```

---

尽情享受 Linux 上的无缝语音输入吧！如果你在此基础上构建了有趣的东西，欢迎提交 PR 或打个招呼！
