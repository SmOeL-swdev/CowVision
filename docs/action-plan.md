# Action plan — deploying CalvingCatcher on the current Intel PC

Target: **Lely OptiPlex, Win 11, Intel UHD 770 → native `winml` `.exe`.** Goal of this
phase is to **prove the path works** (does the detector run, use the iGPU, detect
calving, and reach Home Assistant) before any dedicated-hardware/Linux future work.

Principle: **test smallest-first.** Prove the engine runs → one camera → disk → HA
webhook → three cameras → tune → make it always-on. Each phase has a clear exit test.

---

## Phase 0 — Prerequisites (gather, don't install yet)
Collect everything so later phases don't stall. Nothing here touches the PC yet.
- [ ] Engine build: latest `aidetector-winml-onnx-<ver>.exe` URL from
      https://github.com/ESchouten/ai-detector/releases
- [ ] Model: confirmed latest **CalvingCatcher** release = `calvingcatcherV10.1.pt`
      (tag `CalvingcatcherV1`). Only `.pt` assets exist; winml auto-exports to ONNX on
      first run. URL in `deploy/config.template.json`.
- [ ] Camera 1 (Hikvision): IP, username, password → substream
      `rtsp://<user>:<pass>@<ip>:554/Streaming/Channels/101`
- [ ] Camera 2 (Hikvision): same pattern.
- [ ] Camera 3 (Hikvision): same pattern. (All cameras are Hikvision — Eyesee dropped for now.)
- [ ] (Optional but ideal) a **recorded calving clip** `.mp4` for offline testing.
- [ ] Home Assistant: create a **webhook automation** (note the webhook ID). **No
      token needed** — HA webhooks are unauthenticated. Confirm the HA VM is reachable
      on `:8123` from the host (see `docs/home-assistant-webhook.md`).
**Exit test:** every RTSP URL opens in **VLC** (Media → Open Network Stream) on the PC.

## Phase 1 — Engine smoke test (no cameras)
Prove the `.exe` runs and the iGPU is used.
- [ ] Make `C:\CowVision\` ; put the `.exe` + a `config.json` there.
- [ ] Use the **recorded clip** (or one camera) as the only `source`.
- [ ] Right-click `.exe` → Properties → **Unblock**; first run → SmartScreen →
      More info → Run anyway.
- [ ] Run it; watch the log.
**Exit test:** logs scroll with **no red errors**; log shows a GPU/OpenVINO execution
provider being registered (not CPU-only); a detection writes a frame to
`detections/`. If the window closes instantly → JSON error in `config.json`.

## Phase 2 — One live camera + disk only
- [ ] Set `source` to **camera 1** substream; keep only the `disk` exporter.
- [ ] Run for a while during normal barn activity.
**Exit test:** stable stream (no constant "connection failed"); frames land in
`detections/calving/`; CPU/iGPU load in Task Manager is acceptable alongside Lely+HA.

## Phase 3 — Add the Home Assistant webhook
- [ ] Add the `webhook` exporter (keys **`url`**, `data_type: "base64"`, media off —
      sends clean JSON to HA; media stays on disk). **No `token`** (HA webhooks are
      unauthenticated). See `docs/home-assistant-webhook.md`.
- [ ] In HA, have the webhook automation log/notify so you can see hits.
**Exit test:** a detection triggers the HA automation (HA → Settings → Automations →
trace, or Developer Tools → Logbook). Confirm image/plot arrives as configured.

## Phase 4 — Scale to all three cameras
- [ ] Put all 3 Hikvision substreams in the `source` list.
- [ ] Keep `interval: 0.5`, `strategy: "LATEST"`.
**Exit test:** all three connect; the iGPU keeps up enough (frames still processed;
Lely UI remains responsive). If overloaded → raise `interval` or reduce cameras and
note it.

## Phase 5 — Tune detection quality
- [ ] Review saved detections for **false positives / misses**.
- [ ] Adjust per-class `confidence` (↑ fewer false alarms, ↓ catches more),
      `frames_min` (↓ to 3–4 if missing fast bits), `cooldown` (repeat-alert spacing).
- [ ] Re-run against the recorded clip after each change if available.
**Exit test:** a real (or replayed) calving produces a timely alert with an acceptable
false-alarm rate agreed with the user.

## Phase 6 — Make it always-on + hand over
- [ ] Launch via `deploy/run-windows.bat` (auto-restart) and/or a **Task Scheduler**
      task "At log on" (survives reboot/crash).
- [ ] Confirm it restarts after a reboot and after killing the process.
- [ ] Save the final `config.json` into the portable `deploy/` bundle (secrets stay
      local / git-ignored) and update `docs/progress.md`.
**Exit test:** reboot the PC → detector comes back automatically and still alerts.

---

## Decision gate (after Phase 5)
Is the Intel UHD 770 path **good enough** for production CalvingCatcher?
- **Yes** → run it; revisit a dedicated NVIDIA/Proxmox PC only when adding heat detection.
- **No** (too slow / too much contention with Lely+HA) → the portable `config.json`
  moves unchanged to a `cuda` `.exe` or the Docker/NVIDIA future PC.

## Reference
- Full field reference + runbook: `docs/deployment-plan.md`
- Config to start from: `deploy/config.template.json`
- Why native (not VM/Docker) on this PC: `docs/deployment-vm-vs-docker.md`
