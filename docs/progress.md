# Progress log (append-only, newest at bottom)

## 2026-10-07 — Session 1: initial research & workspace setup
- Clarified intent: **research & planning only**; starting focus is **CalvingCatcher**;
  topic is how to deploy/use CowCatcher AI on a local farm machine.
- Confirmed this workstation is **not** a deployment target (user does not want to
  run the detector here). Deployment happens on a separate farm machine on the camera LAN.
- Set up workspace: `README.md`, `AGENTS.md`, `docs/`, `repos/`.
- Cloned upstream repos (shallow):
  - `repos/ai-detector` @ `bcd98db` (2026-09-18)
  - `repos/CowCatcherAI` @ `f5acd76` (2026-09-05)
- Read website (home, installation, hardware, download: Windows/macOS/Docker, options,
  projects: cowcatcher/calvingcatcher/ai-detector) + both repo READMEs + detector README
  + example configs.
- Wrote `docs/research.md`, `docs/deployment.md`, `docs/calvingcatcher.md`,
  `docs/open-questions.md`.

### Key takeaways
- Architecture = reusable **AI Detector** engine + swappable **YOLO models**
  (CowCatcher=heat/mounting, CalvingCatcher=calving stages). Single `config.json`.
- Deployment options: Windows `.exe` (simplest) / Docker (Linux/NAS) / Jetson Orin
  Nano (edge appliance) / macOS / from-source (dev dry-runs).
- Recommended default for a single barn: **Windows winml `.exe`**.

### Next step
- Decide the farm target machine + GPU, then draft a real `config.json` for the
  calving-pen camera. See `docs/open-questions.md`.

## 2026-10-07 — Session 2: open questions -> deployment plan
- Ran the open-questions form. Decisions captured in `docs/open-questions.md`.
- Target = **Lely management PC** (Dell OptiPlex, i5-13500, ~32GB, Win11 Pro). GPU is
  integrated **Intel UHD Graphics 770** -> **winml** engine build (~200–600 ms/frame).
- Scope: **CalvingCatcher only**, **3 cameras** (Hikvision + Eyesee), exporters =
  **disk + Home Assistant webhook**, no Telegram, no VLM, no sample clip, end goal TBD.
- Verified in engine source (`bcd98db`): webhook config keys are **`url` / `token`**
  (via `HttpConfig`), NOT `webhook_url`/`webhook_token` as in the repo's HA example.
  Flagged this gotcha; draft uses correct keys.
- Wrote `docs/deployment-plan.md` (tailored runbook + risks + HA outline + tuning).
- Drafted `configs/calvingcatcher-farm.draft.json` (3 cams, disk + HA webhook, placeholders).

### Risks noted
- Detection shares the production Lely PC (CPU/iGPU/RAM) -> keep `interval` >= 0.5 s,
  monitor load, fallback to dedicated mini-PC/Jetson if it interferes.

### Next step
- Close remaining open items: Eyesee RTSP path, latest CalvingCatcher model URL,
  HA webhook ID + token, auto-start method, obtain a calving clip for dry-run.

## 2026-10-07 — Session 3: VM vs Docker vs native + GPU adequacy
- Context added: the OptiPlex is used as a server (Win11 + Lely tools) and already
  runs **VirtualBox hosting a Home Assistant VM**. User asked whether to deploy the
  vision tools as a VBox VM, or if Docker/native is better, and if the iGPU suffices.
- Verified in source (`bcd98db`): GPU accel for the Intel UHD 770 comes only via the
  native Windows **winml** build (`winml.py` uses Windows App SDK ML -> OpenVINO EP;
  gated on `sys.platform=='win32'` + `TYPE=='windowsml'`). Linux guests skip it.
- Conclusion: **native Windows winml .exe** is the right deployment. VirtualBox gives
  NO GPU compute passthrough (CPU-only); Docker on Windows also CPU-only (image is
  NVIDIA-targeted, Intel iGPU not exposed in WSL2). Documented in
  `docs/deployment-vm-vs-docker.md`.
- GPU adequacy: UHD 770 via winml (~200–600 ms/frame) is **good enough for initial
  testing** and likely for CalvingCatcher production (slow event, interval 0.5s,
  LATEST). Test with 1 camera/clip first, then scale to 3.
- Detector will webhook into the existing HA VM over the LAN — keeps the automation
  integration without containerizing.

## 2026-10-07 — Session 4: deployable + transferable bundle
- Goal: make the deployment transferable to a future dedicated (NVIDIA) CowVision PC,
  e.g. when adding heat detection. User asked if Docker is the way.
- Verified engine config loading (`config.py:load_config`): plain `json.load` of
  `config.json`, **no env-var substitution**, and it rewrites the file to add `$schema`
  (so it must NOT be mounted read-only). Secrets therefore live in config.json.
- Key framing: the **portable unit is config.json + model + exporters**, already
  machine-independent. Only the engine BUILD changes per host.
- Built `deploy/` bundle supporting both paths:
  - Path A native Windows winml `.exe` (use now on UHD 770) -> `run-windows.bat`.
  - Path B Docker (future NVIDIA PC) -> `compose.yml` (GPU block commented, enable on
    NVIDIA), `.env.example` to pin image tag.
  - `config.template.json` (committed) + `.gitignore` (real config.json/.env/outputs
    untracked) + `README.md` transfer runbook.
- Recommendation: native now (keeps the iGPU), Docker on the dedicated NVIDIA box
  later; same config.json carries over unchanged.

### Decision needed
- Interim packaging: **native winml .exe now** (recommended, GPU) vs **Docker now**
  (CPU-only interim, max consistency). See open-questions.

## 2026-10-07 — Session 5: Linux/Proxmox feasibility + source "rewrite" question
- User asked whether the source must be rewritten to drop Windows reliance and run on
  a Proxmox Linux VM.
- Verified in source (`bcd98db`): NOT Windows-locked. `TYPE` is a build-time flag;
  `.pt` on `cuda` build runs via torch+CUDA; otherwise ONNX Runtime. Windows ML
  registration is gated on `sys.platform=='win32'` AND `TYPE=='windowsml'`; else it
  uses `ort.get_available_providers()` (CUDA/TensorRT/OpenVINO/CPU). OpenVINO + CoreML
  EPs already handled in `onnx.py`.
- Conclusion: **no rewrite needed.** Windows ML is only the Windows route to Intel/AMD
  GPUs; Linux uses CUDA (NVIDIA) or OpenVINO (Intel) natively.
- Proxmox is KVM -> supports PCIe passthrough (unlike VirtualBox). Best path for a
  dedicated CowVision PC: NVIDIA GPU passed through to a Linux VM + Docker image =
  full accel, zero code changes. CPU-only VM also works for slow CalvingCatcher.
  Intel iGPU passthrough = high effort / not recommended.
- Wrote `docs/linux-proxmox-deployment.md`.

## 2026-10-07 — Session 6: Intel PC deployment action plan
- Scope set: just prove the path on the current Intel PC (native winml); dedicated
  NVIDIA/Proxmox PC is explicitly future work.
- Wrote `docs/action-plan.md`: test-first phased rollout (P0 prereqs -> P1 smoke ->
  P2 one cam+disk -> P3 HA webhook -> P4 three cams -> P5 tune -> P6 always-on),
  each with a concrete exit test, plus a decision gate after P5.
- Loaded the 7 phases into the session todo tracker with sequential deps
  (p0-prereqs ... p6-always-on).

### Next action (first ready todo)
- p0-prereqs: gather engine exe URL, latest CalvingCatcher model URL, 3 camera RTSP
  creds (incl. Eyesee path), optional calving clip, HA webhook ID + token; verify
  each RTSP URL in VLC.

## 2026-10-07 — Session 7: model version + HA webhook verification
- Latest CalvingCatcher model = **calvingcatcherV10.1.pt** (tag CalvingcatcherV1; only
  .pt assets -> winml exports to ONNX on first run). Updated both config files.
- Read `exporters/webhook.py` end-to-end. HA findings + fixes:
  1. Keys are `url`/`token` (repo HA example's webhook_url/webhook_token are wrong).
  2. HA webhooks are **unauthenticated** -> dropped the long-lived token (Phase 0 lighter).
  3. Engine default `binary` sends multipart w/ files HA can't use -> switched configs to
     `data_type:"base64"` with media OFF (clean JSON trigger); media kept by disk exporter.
- Wrote `docs/home-assistant-webhook.md` (payload behavior, gotchas, HA automation YAML,
  VirtualBox networking note re: local_only, curl test). Updated action-plan,
  open-questions, deployment-plan. Both configs validated as JSON.

## 2026-10-07 — Session 8: upstream activity assessment + Hikvision-only
- Cameras simplified to **all Hikvision** (Eyesee dropped; `/Streaming/Channels/101`).
  Updated both configs + action-plan + open-questions. No RTSP access yet (Phase 0 waits).
- Assessed upstream via GitHub API -> `docs/upstream-assessment.md`:
  - ai-detector: ~472 commits/52wks but **single maintainer** (ESchouten), bursty cadence,
    5★/6 forks, PRs merged (1 open/18 closed). Active feature branches incl.
    **codex/cow-identity** (individual cow ID in flight). Latest semver detector/v0.7.1.
  - CowCatcherAI models: 20★, community data/model training, fast model iteration.
  - License: AGPL-3.0 + model "no commercial use/redistribution without permission".
- Recommendation: **don't fork yet.** Use upstream as-is with **pinned versions**, keep a
  thin private layer (configs/HA/deploy/own-models) in this repo, contribute general
  improvements upstream, and only (soft-)fork on a concrete divergence (settle licensing
  first if commercial). Logged key-person + licensing + release-cadence risks.

## 2026-10-07 — Session 9: version pins + session save/handoff
- Captured exact release pins -> `deploy/VERSIONS.md`:
  - Engine stable `detector/v0.7.1` -> `aidetector-winml-v0.7.1.zip` (~402 MB). Caveat:
    our configs came from `main @ bcd98db` (newer than v0.7.1) -> validate schema at download.
    Noted newer prerelease `app/test-*` desktop-app track (v0.0.64) for future.
  - Model `calvingcatcherV10.1.pt` (tag CalvingcatcherV1, ~44 MB).
  - Docker `ghcr.io/eschouten/ai-detector` -> pin by DIGEST (recorded at first pull);
    Jetson `:main-jetpack6`. Reference clones: ai-detector `bcd98db`, CowCatcherAI `f5acd76`.
- Wired pins into `deploy/README.md`, `deploy/compose.yml`, rewrote `deploy/.env.example`.
- Created `docs/SESSION-HANDOFF.md` (resume point: state, decisions, pins, next actions).
- Todo `p0-prereqs` set to **blocked** (waiting on camera RTSP access + HA webhook ID).
- Session saved; pick up from SESSION-HANDOFF.md when RTSP access is available.
