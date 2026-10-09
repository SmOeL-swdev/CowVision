# Open questions / decisions

Resolved items from the 2026-10-07 session are marked with (resolved). Remaining
open items block go-live. See `docs/deployment-plan.md` for the concrete plan.

## Target machine
- (resolved) Machine: **Lely management PC** — Dell OptiPlex MT, i5-13500, ~32 GB RAM,
  512 GB SSD, **Windows 11 Pro**.
- (resolved) GPU: integrated **Intel UHD Graphics 770** -> use **winml** engine build.
- (resolved) On the camera LAN, always-on (it's the farm's management PC).
- (risk) Shared with Lely software -> watch resource load; keep `interval` >= 0.5 s.
  Fallback = dedicated mini-PC / Jetson if it interferes.

## Cameras
- (resolved) Count: **3**.
- (resolved) Brands: **all Hikvision** (Eyesee dropped for now; easy to add later).
- (resolved) RTSP substream path = Hikvision `/Streaming/Channels/101`.
- [ ] Camera IP(s), username, password — **no RTSP access yet**; fill when available.
- [ ] Which pens do the 3 cameras cover (all calving pens?).
- [ ] Mount height/angle (4–5 m, ~45° down) + night IR present on each?

## Model
- (resolved) Latest CalvingCatcher release = **`calvingcatcherV10.1.pt`** (tag
  `CalvingcatcherV1`; only `.pt`, winml auto-exports to ONNX). In the configs.
- (resolved) Scope: **CalvingCatcher only** (no heat).

## Alerts
- (resolved) Channels: **Disk + Webhook (Home Assistant)**. No Telegram.
- (resolved) VLM double-check: **No** (fully local, no cloud, no API key).
- [ ] Create HA **webhook automation** + note the **webhook ID**. No token needed
  (HA webhooks are unauthenticated). Confirm HA VM reachable on `:8123` from the host.
- [ ] Confirm VirtualBox HA VM networking (bridged vs NAT) for `local_only` webhooks.
- [ ] Design the HA automation (notify phone / light / log).

## Tuning / ops
- [ ] Acceptable miss-vs-false-alarm trade-off (sets `confidence`/`frames_min`/`cooldown`).
- [ ] Get a recorded calving `.mp4` to dry-run + tune before going live (none yet).
- [ ] Auto-start method: `AI-detector-auto-restart.bat` and/or Task Scheduler.

## Scope
- [ ] End goal still **undecided**: run official tool as-is vs later customize/retrain
  for this farm. Revisit after first live results.
