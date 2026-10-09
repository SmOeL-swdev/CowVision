# CalvingCatcher — focused notes (current starting point)

CalvingCatcher is the CowCatcher engine (`ai-detector`) running a **calving-detection
YOLO model**. It alerts when a cow is calving, identifying the stage via detected
classes. Goal on the farm: get a Telegram alert the moment calving begins so the
cow can be checked in time.

## Detected classes (calving stages)

`waterbag`, `legs`, `head`, `body`, `calf` — each gets its own confidence score so
you can see how far along the calving is.

## Model

- `https://github.com/CowCatcherAI/CalvingCatcherAI/releases/download/CalvingcatcherV1/calvingcatcherV5.pt`
- `.pt` (PyTorch) for GPU/Docker; use the `.onnx` equivalent for the winml build.
- ⚠️ Confirm the latest CalvingCatcher release/version before deploying (the website
  moves fast; CowCatcher is already on V17.2 while these example configs pin V5).

## Example configs in the repo (`repos/CowCatcherAI/`)

| File | What it shows |
| :--- | :------------ |
| `config_calvingcatcher.json` | Single camera, disk(BEST) + one Telegram chat. Good baseline. |
| `config_calvingcatcher_dual.json` | Two Telegram chats, disk `strategy:"ALL"` (keeps every frame). |
| `config_calvingcatcher_help_dataset.json` | Like above; also `include_image:true` (contribute data back). |
| `config_heat_ and_calving.json` | One machine running heat **and** calving detectors together. |

## Baseline config shape (from `config_calvingcatcher.json`)

- `detection.interval: 0.4`, `frame_retention: 20` (process ~2.5 fps; cheap, calving is slow).
- Per-class `confidence` all `0.8` for YOLO; Telegram re-filters at `0.85` (calf `0.9`).
- Per-class `cooldown: 900s` (15 min) — avoids spamming during one long calving.
- `frames_min: 10`, `timeout: 30`, `time_max: 20`, `imgsz: 640`, `strategy: "LATEST"`.
- Exporters: `disk` (`strategy:"BEST"`, `directory:"dry_cows"`) + `telegram`
  (`include_plot:true`, `include_video:true`, `alert_every:1`, `export_rejected:true`).

Calving tuning differs from heat: calving is a **slow** event, so a longer
`timeout`/`cooldown` and a lower `interval` (fewer frames/sec) are appropriate —
unlike heat/mounting which is fast and needs more frames/sec.

## To deploy CalvingCatcher (short path)

1. Pick target machine + engine build (see `docs/deployment.md`).
2. Point `detection.source` at the calving-pen camera substream (RTSP).
3. Set the model URL to the latest CalvingCatcher release.
4. Fill Telegram `token` + `chat`.
5. Start from `config_calvingcatcher.json`, run, then tune `confidence`/`cooldown`.

## RTSP substream quick reference (common brands)

| Brand | Substream URL |
| :---- | :------------ |
| Reolink | `rtsp://admin:[PASS]@[IP]:554/h264Preview_01_sub` |
| Dahua/Amcrest | `rtsp://admin:[PASS]@[IP]:554/cam/realmonitor?channel=1&subtype=1` |
| Hikvision/Annke | `rtsp://admin:[PASS]@[IP]:554/Streaming/Channels/101` |
| TP-Link Tapo | `rtsp://admin:[PASS]@[IP]:554/stream2` |
| Foscam | `rtsp://admin:[PASS]@[IP]:554/videoSub` |

(Full table in `repos/CowCatcherAI/README.md`.)
