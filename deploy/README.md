# CowVision deploy bundle

A **portable, transferable** deployment of the AI Detector running the CalvingCatcher
model. Copy this whole `deploy/` folder to any target machine and run it. The only
per-machine difference is *how* you run the engine (native `.exe` vs Docker image),
not *what* it does — `config.json` is identical everywhere.

## What transfers between machines

| Artifact | Portable? | Notes |
| :------- | :-------: | :---- |
| `config.template.json` | ✅ | The canonical config. Copy to `config.json` and fill secrets. |
| model (YOLO `.pt`/`.onnx`) | ✅ | Referenced by URL (auto-downloaded) or dropped in as a local file. |
| `compose.yml` + `.env` | ✅ | For Docker targets. Pin the image tag in `.env`. |
| `detections/` output layout | ✅ | Same folder structure on every host. |
| **Engine runtime** | ❌ per-host | winml `.exe` (Intel/any GPU, Windows) · `cuda` `.exe`/Docker (NVIDIA) · jetpack image (Jetson). |

> There is **no env-var substitution** in the engine — secrets (camera passwords, HA
> token) live in `config.json`. Keep the real `config.json` out of version control
> (see `.gitignore`); only the `*.template.json` is committed.

## Two supported deployment paths

### Path A — Native Windows `.exe`  (use NOW on the Intel UHD 770 PC)
Only path that uses the **Intel iGPU** (via Windows ML / OpenVINO). See
`../docs/deployment-plan.md` for the full runbook. Quick version:
1. Download `aidetector-winml-onnx-<ver>.exe` from the AI Detector releases.
2. Put it in a folder with `config.json` (copied from `config.template.json`, filled in).
3. Run via `run-windows.bat` (auto-restart loop) or a Task Scheduler "At log on" task.

### Path B — Docker  (use on a FUTURE dedicated NVIDIA CowVision PC)
Cleanest reproducible deploy; full GPU with `runtime: nvidia`. On an NVIDIA machine:
```bash
cp config.template.json config.json   # then edit secrets
cp .env.example .env                   # pin the image tag
docker compose up -d
docker compose logs -f aidetector
```
> ⚠️ On the current **Intel-only** PC, Docker runs **CPU-only** (the image is
> NVIDIA-targeted; the iGPU is not exposed). Acceptable for slow CalvingCatcher
> testing, but Path A is preferred there. Docker becomes the right choice once a
> dedicated NVIDIA box exists.

## Moving to a new machine (the "transfer" procedure)

1. Copy this `deploy/` folder (including your filled `config.json`) to the new machine.
2. Pick the engine for that machine's GPU:
   - NVIDIA box → Path B (Docker, uncomment the `deploy:` GPU block in `compose.yml`),
     or the `aidetector-nvidia-cudaXXX-<ver>.exe`.
   - Still Intel/any-GPU Windows → Path A (winml `.exe`).
   - Jetson → Docker image `...:main-jetpack6` with `runtime: nvidia`.
3. Review `config.json`: update camera IPs/paths if the network differs; the model,
   exporters, and tuning carry over **unchanged**.
4. Start it. Verify `detections/` fills and the Home Assistant webhook fires.

That's the whole transfer — because the config is the portable unit, adding heat
detection later on a dedicated PC is just: copy bundle → add a CowCatcher detector
block (or a second config) → run the `cuda`/Docker engine.

## Pinned versions
All exact versions (engine `detector/v0.7.1` winml zip, model `calvingcatcherV10.1.pt`,
Docker digest, and the reference source commits) are recorded in **`VERSIONS.md`**.
Always deploy the pinned versions; never float `latest` in production.

## Files in this bundle
- `config.template.json` — fill in and save as `config.json` (git-ignored).
- `compose.yml` — Docker deployment (GPU block commented; enable on NVIDIA hosts).
- `.env.example` — copy to `.env`; pins the engine image tag/version.
- `run-windows.bat` — native Windows auto-restart launcher.
- `.gitignore` — keeps secrets/outputs/models out of version control.
- `VERSIONS.md` — authoritative version pins + reference source commits.
