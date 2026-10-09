# Session handoff / resume point

Snapshot so this work can be picked up later (by you or another agent). Last updated
2026-10-07. Read this first, then `AGENTS.md`, then `docs/progress.md`.

## Where we are
**Phase: research & planning complete; ready to execute on the farm PC once camera RTSP
access is available.** Nothing deployed yet (by design — no RTSP access to the cameras
yet). The whole plan, configs, and version pins are prepared and committed to this folder.

## The goal (unchanged)
Deploy **CalvingCatcher** (calving detection) on the farm's **Lely OptiPlex** (Win 11,
Intel UHD 770) using the native **winml** engine build, 3 **Hikvision** cameras, with
alerts to **disk + Home Assistant webhook**. Prove this path works before investing in
dedicated NVIDIA/Proxmox hardware or forking the code.

## Decisions locked in
- Target: native Windows winml `.exe` on the shared Lely PC (not a VM/Docker — the
  Intel iGPU is only usable via native Windows). See `docs/deployment-vm-vs-docker.md`.
- GPU: Intel UHD 770 is "good enough" for calving (slow event); upgrade later if needed.
- No source rewrite needed for Linux later — engine is cross-platform; the future
  dedicated PC = Proxmox + NVIDIA passthrough + Docker. See `docs/linux-proxmox-deployment.md`.
- Don't fork upstream yet — use pinned versions + a thin private layer here; contribute
  general fixes. See `docs/upstream-assessment.md`.
- HA webhook: unauthenticated (no token), `data_type:"base64"` with media off (clean JSON
  trigger); media kept by the disk exporter. See `docs/home-assistant-webhook.md`.

## Pinned versions (see `deploy/VERSIONS.md`)
- Engine: `detector/v0.7.1` → `aidetector-winml-v0.7.1.zip` (stable). Note: our configs
  were written against upstream `main @ bcd98db`, newer than v0.7.1 — validate config at
  download.
- Model: `calvingcatcherV10.1.pt` (tag `CalvingcatcherV1`).
- Docker (future): pin `ghcr.io/eschouten/ai-detector` by digest.
- Reference clones: ai-detector `bcd98db` (2026-09-18), CowCatcherAI `f5acd76` (2026-09-05).

## Deliverables in this folder
- `docs/action-plan.md` — the 7-phase, test-first rollout (also in the session todo DB).
- `deploy/` — portable bundle: `config.template.json`, `compose.yml`, `.env.example`,
  `run-windows.bat`, `VERSIONS.md`, `.gitignore`, `README.md`.
- `configs/calvingcatcher-farm.draft.json` — the farm-specific draft.
- `docs/` — research, deployment options + plan, VM/Docker, Linux/Proxmox, HA webhook,
  upstream assessment, open questions, progress log.
- `repos/` — read-only upstream clones at the pinned commits.

## NEXT ACTIONS (resume here)
Blocked on **camera access** (todo `p0-prereqs` = blocked). When RTSP is available:
1. Get the 3 Hikvision camera IPs + user/pass; build substream URLs
   `rtsp://<user>:<pass>@<ip>:554/Streaming/Channels/101`; verify each in **VLC**.
2. In Home Assistant: create a webhook automation, note the **webhook ID** (no token);
   confirm the HA VM is reachable on `:8123` from the host (mind VirtualBox networking).
3. Fill `deploy/config.template.json` → `config.json` (keep it git-ignored).
4. Execute `docs/action-plan.md` Phase 1 → 6 (smoke test → tune → always-on).

## Open items (see `docs/open-questions.md`)
- Camera IPs/credentials (waiting).
- HA webhook ID + VirtualBox bridged-vs-NAT networking check.
- A recorded calving clip for safe dry-run/tuning (nice to have).
- End goal (run as-is vs retrain) — revisit after first live results.

## How to resume the todo tracker
The 7 phases live in the session SQLite `todos` table (ids `p0-prereqs` … `p6-always-on`,
sequential deps). Query ready work:
```sql
SELECT t.* FROM todos t WHERE t.status IN ('pending','blocked')
AND NOT EXISTS (SELECT 1 FROM todo_deps d JOIN todos dep ON d.depends_on=dep.id
                WHERE d.todo_id=t.id AND dep.status!='done');
```
