# Research: How CowCatcher AI works

Source of truth: https://jacobsfarm.github.io/website/ and the two cloned repos
in `repos/`. Captured 2026-10-07.

## The big picture

CowCatcher AI is a **computer-vision alerting system for dairy farms**. It watches
barn IP cameras 24/7 and sends a phone alert (Telegram) when it sees a trained
behaviour. Everything runs **locally on the farm** — no footage leaves the premises
("Your barn, Your data, Our vision"). Free and open source (AGPL-3.0, built on
Ultralytics YOLO).

Two layers:

| Layer | Repo | Role |
| :---- | :--- | :--- |
| **AI Detector** (engine) | `ESchouten/ai-detector` | Generic software that watches streams, runs a YOLO model per frame, optionally double-checks with a VLM, and exports alerts. Reusable for anything (people, cars, tractors…). |
| **CowCatcher / CalvingCatcher** (models) | `CowCatcherAI/CowCatcherAI` | The trained YOLO models + example `config.json` files that make the engine detect cow-specific behaviour. |

## The three "products" (all the same engine + different models)

- **CowCatcher** — detects **mounting behaviour** = primary sign of **estrus / heat**.
  Latest model `cowcatcherV17.2` (website note mentions V17.2; configs reference V15/V16).
- **CalvingCatcher** — detects **calving** by spotting the *water bag, legs, head,
  body, calf*. Gives a confidence score per calving stage. **(current focus)**
- **AI-Detector** — the raw engine; can be repurposed for your own detection projects.

## Processing pipeline (per detector)

1. **Detection / source** — reads one or more RTSP/HTTP streams or local video files.
2. **YOLO** — fast first pass on every frame; flags objects above a confidence
   threshold (can be per-class). Groups consecutive frames into an "event".
3. **VLM (optional)** — a Vision Language Model (Gemini/OpenAI/local via LiteLLM)
   answers a yes/no question about the clip to filter false alarms. Needs an API
   key (this is the only part that *can* touch the cloud — optional).
4. **Exporters** — where confirmed events go: **Telegram** (phone alert), **Disk**
   (save images/video under `detections/`), **Webhook** (POST to another system,
   e.g. Home Assistant).
5. **Health** (optional) — periodic HTTP ping so a watchdog knows it's alive.

## Config model

A single `config.json` drives everything. Top-level keys: `detectors[]` (required),
plus optional `onnx` and `health`. Each detector has `detection`, `yolo`,
optional `vlm`, and `exporters`. JSON Schema is published so VS Code autocompletes.
Full field reference lives in `repos/ai-detector/detector/README.md`.

Key YOLO tuning knobs:
- `confidence` (single or per-class) — higher = fewer false alerts.
  Heat recommended starting point ≈ **0.87**.
- `frames_min` — consecutive matching frames before it counts (6 on CUDA, else 3).
- `cooldown` — seconds before a new event (per-class) — prevents repeat alerts.
- `time_max` / `timeout` — how frames are grouped into an event.
- `imgsz` — model input size (default 640).

## Camera requirements

- Any IP camera with **RTSP** support; wired LAN strongly preferred over Wi-Fi.
- **Use the substream** (lower-res, e.g. 640x480/720p) to save compute.
- Mount **4–5 m high**, angled ~45° down; ensure night lighting or IR.
- Reolink: RTSP is OFF by default → enable it (Network → Advanced → Server Settings).
  Hikvision/Dahua/Axis/Foscam/UniFi: RTSP on by default (port 554).
- RTSP URL format differs per brand — full table in `CowCatcherAI/README.md` and
  `docs/calvingcatcher.md`.

## Hardware / performance (per-frame latency, from website)

| Build | Hardware | Time/frame |
| :---- | :------- | :--------- |
| `winml` | Windows 11, any GPU (Intel/AMD/NVIDIA) | 200–600 ms |
| `nvidia-cu130` | Win10/11, NVIDIA RTX 3000+ | 10–40 ms |
| `nvidia-cu126` | Win10/11, NVIDIA GTX 1000 / RTX 2000 | 40–60 ms |
| Jetson Orin Nano (Docker) | ARM64 + CUDA | edge-class |
| macOS (onnx) | Apple Silicon / CPU | — |

A faster GPU just means more frames/second → better chance of catching fast events.

## Related tools

- **Image Extractor** (`JacobsFarm/image_extractor`) — grab frames/footage to
  contribute back for model training.
- **HuggingFace Space** — try the model in-browser with no install:
  https://huggingface.co/spaces/CowcatcherAI/CowCatcherAI
- Community: Telegram group + Facebook group + cowcatcherai@gmail.com.
