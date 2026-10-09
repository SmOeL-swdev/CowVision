# AGENTS.md — instructions for AI agents working in CowVision

This file is self-contained so it can be transferred with the folder to another
machine/agent later. Read it fully before acting.

> **Resuming this project?** Read `docs/SESSION-HANDOFF.md` first — it has the current
> state, locked decisions, pinned versions (`deploy/VERSIONS.md`), and the next actions.

## Mission

Help the user **deploy and use CowCatcher AI** (engine `ai-detector`) on a **local
farm machine**, starting with the **CalvingCatcher** model. Current phase:
**research & planning only** — do not deploy or run the detector unless explicitly
asked.

## Ground rules

1. **This workstation is NOT a deployment target.** The detector runs on a separate
   farm machine on the camera LAN. Do not install GPU drivers, Docker images, camera
   stacks, or run the engine here unless the user explicitly requests a local dry-run.
2. **This folder is the source of truth.** Record everything here:
   - Append every meaningful action/decision to `docs/progress.md` (newest at bottom).
   - Put durable facts in `docs/research.md`; deployment plans in `docs/deployment.md`;
     calving specifics in `docs/calvingcatcher.md`; unknowns in `docs/open-questions.md`.
   - Prefer editing existing docs over creating new scattered notes.
3. **Treat `repos/` as read-only reference** (upstream clones). Don't modify upstream
   code; if you need to experiment, copy into a new top-level working dir and note it.
4. **Secrets:** never commit real RTSP passwords, Telegram tokens, chat IDs, or API
   keys. Use placeholders like `<telegram_bot_token>` in any config saved here.
5. **Verify before asserting versions/URLs.** The upstream project moves fast
   (models, release tags). Re-check the latest release before recommending a model URL.
6. Keep answers concise; keep the user informed of what you're doing and why.

## Where things are

- Upstream docs: https://jacobsfarm.github.io/website/
- Engine repo: https://github.com/ESchouten/ai-detector
  (full config reference: `repos/ai-detector/detector/README.md`;
   JSON schema generator: `uv run generate-schema`)
- Models + example configs: https://github.com/CowCatcherAI/CowCatcherAI
  (CalvingCatcher example: `repos/CowCatcherAI/config_calvingcatcher*.json`)
- Pinned clones: ai-detector @ `bcd98db` (2026-09-18), CowCatcherAI @ `f5acd76` (2026-09-05).
  To refresh: `git -C repos/<name> pull` and log it in `docs/progress.md`.

## System model (1-paragraph refresher)

Reusable **AI Detector** engine watches RTSP/HTTP streams → **YOLO** per-frame
detection (per-class confidence, grouped into events) → optional **VLM** double-check
(LiteLLM; the only cloud-capable step) → **exporters** (Telegram / disk / webhook).
All driven by one `config.json`. Swap the YOLO model to switch products:
CowCatcher = heat/mounting, CalvingCatcher = calving stages
(`waterbag,legs,head,body,calf`).

## Deployment options (summary; detail in docs/deployment.md)

Windows `.exe` (simplest, recommended) · Docker on Linux/NAS · Jetson Orin Nano edge
appliance · macOS · from-source for dev dry-runs. Match the engine build to the GPU
(winml / cuda130 / cuda126 / jetpack6 / osx).

## Suggested workflow for the next task

1. Resolve items in `docs/open-questions.md` with the user (target machine, cameras,
   Telegram, model version, tuning trade-off).
2. Author a concrete `config.json` from the calving example, with placeholders for
   secrets; save it in a new `configs/` dir and document it.
3. If a sample calving clip exists, propose a from-source dry-run command to validate
   the config before going live on the farm machine.
4. Produce a step-by-step farm install runbook for the chosen deployment option.
5. Update `docs/progress.md` and `docs/open-questions.md`.

## Definition of done (for the overall effort)

A documented, reproducible plan (and configs) that lets the farmer run CalvingCatcher
on their chosen machine and reliably receive calving alerts, with tuning guidance —
all captured in this folder.
