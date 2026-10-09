# Deployment plan — CalvingCatcher on the farm Dell OptiPlex

Decided 2026-10-07 from the open-questions session. This is the concrete plan;
`docs/deployment.md` keeps the general option comparison.

## Chosen setup (from user answers)

| Item | Decision |
| :--- | :------- |
| Target machine | **Lely management PC** — Dell OptiPlex MT, i5-13500, ~32 GB DDR, 512 GB SSD, **Windows 11 Pro** |
| GPU | Integrated **Intel UHD Graphics 770** (no discrete GPU) |
| Engine build | **`aidetector-winml-onnx-<ver>.exe`** (any-GPU Windows build) |
| Expected speed | ~200–600 ms/frame (fine — calving is a slow event) |
| Model | **CalvingCatcher** only (classes: waterbag, legs, head, body, calf) |
| Cameras | **3** — mixed brands (Hikvision + Eyesee) |
| Alerts | **Disk** + **Webhook → Home Assistant** (no Telegram) |
| VLM double-check | **No** |
| Sample clip for dry-run | None available |
| End goal | Undecided (run official tool vs later retrain) |

## ⚠️ Key considerations / risks

1. **Shared production PC.** This is the Lely management PC, not a dedicated box.
   Detection adds CPU + integrated-GPU + RAM load that is *shared* with Lely software.
   - Mitigate: keep `interval` at `0.5 s` (or higher) so we process ~2 fps/camera, not
     every frame. Calving is slow, so this is plenty.
   - Watch Task Manager after go-live; if Lely UI lags, raise `interval` or reduce cameras.
   - Fallback if it interferes: a cheap dedicated mini-PC or a Jetson Orin Nano
     (see `docs/deployment.md` options B/C).
2. **3 cameras on integrated graphics.** Combined load ≈ 3 × per-frame cost. UHD 770 is
   capable but not fast; start at `interval: 0.5` and tune. Use **substreams** only.
3. **Webhook field names.** Use `url` and `token` (engine source `bcd98db`). The repo's
   `config_home-assistant.json` example uses the OUTDATED `webhook_url`/`webhook_token`
   keys — those will NOT validate. Our draft already uses the correct keys.
4. **Eyesee RTSP path unknown.** Hikvision substream = `/Streaming/Channels/101`.
   Eyesee path must be confirmed (camera manual / web UI / ONVIF / VLC test). Placeholder
   in the draft config.
5. **Model version.** Example configs pin `calvingcatcherV5.pt` from the
   `CowCatcherAI/CalvingCatcherAI` releases. Verify the latest CalvingCatcher release
   and prefer an `.onnx` asset for the winml build if provided (otherwise `.pt` works;
   the engine exports it to ONNX on first load).

## Step-by-step runbook (on the farm PC)

1. **Create a working folder**, e.g. `C:\CalvingCatcher\`.
2. **Download the engine**: AI Detector Releases → `aidetector-winml-onnx-<ver>.exe`
   → put it in that folder. (Latest release: https://github.com/ESchouten/ai-detector/releases)
3. **Unblock + allow**: right-click `.exe` → Properties → tick **Unblock** → OK;
   on first launch, SmartScreen → **More info → Run anyway**.
4. **Add `config.json`**: copy `configs/calvingcatcher-farm.draft.json` from this repo
   into the folder as `config.json` and fill every `<...>` placeholder:
   - 3 camera RTSP substream URLs (user, password, IP, path per brand).
   - Home Assistant: create a webhook automation trigger (get the webhook ID) and a
     Long-Lived Access Token (HA → profile → Security). Put them in `url` + `token`.
   - Confirm/replace the model URL with the latest CalvingCatcher release.
5. **First run**: double-click the `.exe`. A terminal shows logs. Scrolling logs with no
   red errors = working. If it closes instantly → JSON syntax error in `config.json`.
6. **Verify detections**: saved frames appear under `detections/calving/`. Trigger HA
   and confirm the webhook fires (HA → Developer Tools / automation trace).
7. **Tune** `confidence` / `frames_min` / `cooldown` once real calvings are observed
   (see tuning notes below).
8. **Make it always-on**: use `AI-detector-auto-restart.bat` (from the CowCatcherAI
   repo — rename the exe to `aidetector.exe` or edit the bat) and/or a Windows Task
   Scheduler task "At log on" so it survives reboots/crashes.

## Home Assistant integration outline

- In HA: **Settings → Automations → create automation → trigger: Webhook** → copy the
  generated webhook ID → build the URL `http://<HA_IP>:8123/api/webhook/<WEBHOOK_ID>`.
- No token needed — HA webhooks are unauthenticated (omit `token`).
- Set `data_type:"base64"` with media OFF so the detector POSTs clean JSON to HA;
  keep the image/video via the `disk` exporter. Details + automation example:
  `docs/home-assistant-webhook.md`.
- HA automation can then notify phones, turn on a light, log to history, etc.
- Keep HA reachable on the LAN from the OptiPlex (same subnet / firewall open on 8123).

## Tuning starting points (calving = slow event)

- `interval: 0.5` (≈2 fps/camera) — raise if the PC is loaded, lower for faster catch.
- Per-class `confidence: 0.8` in YOLO; webhook re-filters at `0.85`.
- `cooldown: 900 s` (15 min) per class — avoids repeat alerts during one calving.
- `frames_min: 6` (winml/CPU-ish); lower to `3–4` if events are missed.
- `timeout: 30`, `time_max: 20` — generous grouping for a drawn-out event.

## Open items before go-live (track in docs/open-questions.md)

- [ ] Confirm Eyesee RTSP substream URL.
- [ ] Confirm latest CalvingCatcher model release URL (.onnx preferred).
- [ ] Which pens do the 3 cameras cover? (all calving pens, or mixed?)
- [ ] HA webhook ID + token created.
- [ ] Decide auto-start method (bat loop vs Task Scheduler vs both).
- [ ] Get a sample calving clip to dry-run/tune before trusting it live.
