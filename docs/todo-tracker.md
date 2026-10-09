# Todo tracker (exported snapshot)

The live phase tracker ran in the CLI session's SQLite DB, which does **not** travel with
this folder. This file is the folder-resident copy so nothing is lost on transfer.
Exported 2026-10-07T14:23 (local). The authoritative narrative is in `action-plan.md`.

Status legend: `pending` · `in_progress` · `done` · `blocked`.

| id | status | title | depends on |
| :-- | :----- | :---- | :--------- |
| p0-prereqs | **blocked** | Gathering prerequisites | — |
| p1-smoke | pending | Smoke-testing the engine | p0-prereqs |
| p2-one-cam-disk | pending | Testing one live camera to disk | p1-smoke |
| p3-ha-webhook | pending | Adding Home Assistant webhook | p2-one-cam-disk |
| p4-three-cams | pending | Scaling to three cameras | p3-ha-webhook |
| p5-tune | pending | Tuning detection quality | p4-three-cams |
| p6-always-on | pending | Making it always-on + handover | p5-tune |

## Details

### p0-prereqs — Gathering prerequisites — **BLOCKED**
DONE: engine pinned (`detector/v0.7.1` winml zip), model pinned (`calvingcatcherV10.1.pt`),
HA webhook approach decided (unauthenticated, `data_type` base64).
BLOCKED/waiting: no RTSP access yet — need the 3 Hikvision camera IPs/user/pass
(substream `/Streaming/Channels/101`) and the HA webhook ID created.
Exit: every RTSP URL opens in VLC on the PC.

### p1-smoke — Smoke-testing the engine — pending
Run winml `.exe` in `C:\CowVision` with a recorded clip or one camera. Unblock + pass
SmartScreen. Exit: logs scroll no errors, GPU/OpenVINO EP registered (not CPU-only), a
frame saved to `detections/`.

### p2-one-cam-disk — Testing one live camera to disk — pending
Source = camera 1 substream, disk exporter only. Exit: stable stream, frames in
`detections/calving/`, acceptable load alongside Lely + HA.

### p3-ha-webhook — Adding Home Assistant webhook — pending
Add webhook exporter (`url` key only — HA webhooks are unauthenticated, no token),
`data_type` base64, media off. Exit: a detection triggers the HA automation (trace/logbook).

### p4-three-cams — Scaling to three cameras — pending
All 3 Hikvision substreams in the source list. interval 0.5, strategy LATEST. Exit: all
connect, iGPU keeps up, Lely UI responsive.

### p5-tune — Tuning detection quality — pending
Review detections; adjust per-class confidence, `frames_min`, cooldown. Re-run vs clip.
Exit: timely calving alert with acceptable false-alarm rate.

### p6-always-on — Making it always-on + handover — pending
Run via `run-windows.bat` and/or Task Scheduler (At-log-on). Exit: survives reboot +
process kill, still alerts; final `config.json` saved to the `deploy/` bundle.

---

To re-import into a fresh session DB (ids + deps), run equivalent `INSERT`s into the
`todos` / `todo_deps` tables and set `p0-prereqs` to `blocked`.
