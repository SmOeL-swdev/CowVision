# Deployment: running CowCatcher / CalvingCatcher on a local machine

> **This workstation is not the target.** Clone/read/plan here; the engine runs on
> a dedicated **farm machine** on the same LAN as the barn cameras. Nothing needs to
> be installed on this planning machine.

## Does it need to run *here*? — No.

Running the detector requires: (a) network reachability to the RTSP cameras, and
(b) ideally a GPU for throughput. The farm machine provides both. This machine is
only for research, config authoring, and documentation.

## Deployment options (pick one for the farm)

### Option A — Windows PC  ⭐ recommended for most farms (simplest)
- Any Windows 10/11 PC; NVIDIA GPU ideal but not required.
- Download 1 engine `.exe` from the AI Detector **Releases**, matched to the GPU:
  - `aidetector-winml-onnx-<ver>.exe` → any modern GPU / unsure (start here)
  - `aidetector-nvidia-cuda130-<ver>.exe` → RTX 3000+
  - `aidetector-nvidia-cuda126-<ver>.exe` → GTX 1000 / RTX 2000
- Put `config.json` next to the `.exe`, unblock the file (Properties → Unblock),
  pass SmartScreen (More info → Run anyway), double-click to run.
- First run with no config generates a template.
- For always-on: use `AI-detector-auto-restart.bat` (in CowCatcherAI repo) or a
  scheduled task / Task Scheduler at logon.

### Option B — Docker (Linux / NAS / server)  — robust, auto-restart
- Requirements: Docker Compose + (for GPU) NVIDIA Container Toolkit.
- Image: `ghcr.io/eschouten/ai-detector:latest` (+ `:...-web` for the UI).
- Mount `config.json` and a `detections/` folder; `docker compose up -d`.
- Example stack (`repos/ai-detector/example/`) also serves the web UI on port 80.
- Minimal `compose.yml` and `config.json` are in `CowCatcherAI/docker_installation.md`
  and `repos/ai-detector/compose.yml`.

### Option C — NVIDIA Jetson Orin Nano (dedicated edge device)  — low power, 24/7
- Flash JetPack 6 (BalenaEtcher / SDK Manager), install Docker + NVIDIA Container
  Toolkit, then:
  `sudo docker pull ghcr.io/eschouten/ai-detector:main-jetpack6`
- Use the `runtime: nvidia` compose from the website's Linux/Docker guide.
- Good "appliance" choice: small, quiet, always on.

### Option D — macOS
- Download `aidetector-osx-onnx-<ver>`; CPU / Apple Silicon. Fine for testing, slower.

### Option E — From source (development / this machine for dry-runs only)
```bash
cd repos/ai-detector/detector
uv sync --extra default
uv run --extra default main      # reads ./config.json
uv run generate-schema           # regenerate JSON schema from pydantic models
```
Useful to validate a config against a recorded `.mp4` without any camera/GPU.

## Recommendation (to confirm with user)

For a single barn with a Windows PC already on site → **Option A (winml .exe)**:
zero container tooling, 10-minute setup. If the farm prefers an always-on headless
appliance or runs a NAS/Linux server → **Option B/C (Docker / Jetson)**.

## Minimum viable deployment checklist

- [ ] Choose target machine (A/B/C/D) and confirm it's on the camera LAN.
- [ ] Confirm GPU + pick the matching engine build.
- [ ] Enable RTSP on the camera(s); get IP, user, password, substream path.
- [ ] Create Telegram bot (@BotFather) + get chat ID (@userinfobot).
- [ ] Pick the model + version (CalvingCatcher vs CowCatcher) and its `.pt`/`.onnx` URL.
- [ ] Author `config.json` (start from an example in `CowCatcherAI/`).
- [ ] Dry-run against a recorded clip if possible, then point at the live stream.
- [ ] Tune `confidence` / `frames_min` / `cooldown` to balance misses vs false alarms.
- [ ] Set up auto-restart / run-at-boot.
