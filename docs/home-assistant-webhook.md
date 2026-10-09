# Home Assistant webhook integration

How the AI Detector's `webhook` exporter talks to Home Assistant, the gotchas found in
the engine source (`repos/ai-detector`, `bcd98db`), and a working HA automation example.

## What the detector sends (verified in `exporters/webhook.py`)

- Method defaults to **POST**; URL + optional headers come from config.
- Payload depends on `data_type`:
  - `"binary"` (engine default) -> **multipart/form-data**: text fields
    (`confidence`, `timestamp`, `duration`, `validated`) as form data **plus image/
    video files**.
  - `"base64"` -> **JSON body** with the same text fields, and any media inlined as
    base64 strings.
  - `"none"` -> neither data nor files are attached (empty-ish body).
  - `body` set -> sends that raw string instead.
- Auth header: if `token` is set, it adds `Authorization: <token>` **verbatim**
  (no `Bearer` prefix).

## Three gotchas → our config choices

1. **Field names are `url` and `token`** (via `HttpConfig`) — NOT the
   `webhook_url`/`webhook_token` used in the repo's `config_home-assistant.json`.
   Those old keys fail validation on the current engine. Our configs use `url`.

2. **HA webhooks are unauthenticated.** The `/api/webhook/<id>` endpoint does not use
   a Long-Lived Access Token (those are for the REST API, not webhooks). So **omit
   `token`** entirely. (If set, HA just ignores the header — harmless but pointless.)
   -> This removes the "create a long-lived token" step from Phase 0.

3. **Use JSON, not multipart, for HA.** HA's webhook trigger exposes JSON as
   `trigger.json` and form fields as `trigger.data`, but **binary files in multipart
   are not usable** inside automations. So we set **`data_type: "base64"`** and turn
   **all media off** (`include_image/plot/video: false`) -> HA receives a small, clean
   JSON event (`confidence`, `timestamp`, `duration`, `validated`). The actual image/
   video is kept by the **`disk`** exporter.

## Resulting webhook block (already in our configs)

```json
"webhook": {
  "url": "http://<HA_IP>:8123/api/webhook/<WEBHOOK_ID>",
  "data_type": "base64",
  "confidence": 0.85,
  "include_image": false,
  "include_plot": false,
  "include_video": false
}
```

## Home Assistant side

Create an automation triggered by a webhook. Pick a long, random `webhook_id`.

```yaml
# configuration via Settings -> Automations (YAML mode), or automations.yaml
alias: CalvingCatcher alert
trigger:
  - platform: webhook
    webhook_id: "<WEBHOOK_ID>"        # must match the URL in config.json
    allowed_methods: [POST]
    local_only: true                  # host -> HA VM is local; see networking note
action:
  - service: notify.mobile_app_<your_phone>
    data:
      title: "🐄 Calving detected"
      message: >
        Stage confidence {{ trigger.json.confidence }} at
        {{ trigger.json.timestamp }} (duration {{ trigger.json.duration }}s).
mode: queued
```

Available in `trigger.json`: `confidence`, `timestamp`, `duration`, `validated`.

### Networking note (VirtualBox HA VM)
`local_only: true` only accepts requests from local IPs. The detector runs on the
Windows host and posts to the HA VM:
- If the HA VM uses **bridged** networking (its own LAN IP), use that IP in `<HA_IP>`
  and `local_only: true` works.
- If it uses **NAT** with port-forwarding, the source IP may still be local, but if HA
  rejects it, set `local_only: false` (local LAN only is still safe) or switch the VM
  to bridged. Confirm the host can reach `http://<HA_IP>:8123` first (browser/curl).

### Want the image in the notification later?
Two options (future refinement, not needed to prove the path):
- Share the detector's `detections/` folder (Samba) so the HA VM can read the saved
  image and attach it, or
- Switch `data_type` to `base64` with `include_image: true` and decode it in HA via a
  template/python_script (heavier). For now, metadata-only + disk is simplest.

## Quick manual test (before wiring the detector)
From the Windows host, confirm the webhook fires:
```
curl -X POST -H "Content-Type: application/json" ^
  -d "{\"confidence\":0.99,\"timestamp\":\"test\"}" ^
  http://<HA_IP>:8123/api/webhook/<WEBHOOK_ID>
```
The HA automation should run. This isolates HA setup from the detector.
