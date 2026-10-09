# Upstream assessment — use as-is, contribute, or fork?

Question: is the project actively developed, and should we pick it up / refactor /
fork to build a better system? Data pulled 2026-10-07 via the GitHub API.

## Activity snapshot

### `ESchouten/ai-detector` (the engine)
| Metric | Value |
| :----- | :---- |
| Created | 2025-10-07 (≈1 year old) |
| Commits last 52 wks | **~472** (bursty: heavy Apr–Jul 2026, quieter Jul–Sep, CI app releases Oct) |
| Authors | **ESchouten 513 commits; next contributor = 1** → effectively one maintainer |
| Stars / forks | 5 / 6 (small audience) |
| PRs | 1 open / 18 closed (PRs are used + merged) |
| Open issues | 1 |
| Active branches | `main`, `dev`, `docker-rework`, `rework-stars`, **`codex/cow-identity`**, `identity`, `dense-cow-identity` |
| Releases | `detector/v0.7.1` (Jun 2026) latest semver; frequent `app/test-*` CI releases this week |
| Primary language | Svelte (web UI) + Python (detector) |

### `CowCatcherAI/CowCatcherAI` (models + example configs)
| Metric | Value |
| :----- | :---- |
| Stars / forks | 20 / 5 (bigger community than the engine) |
| Updated | through Sep 2026 |
| Models | iterating fast — CalvingCatcher → V10.1, CowCatcher → V17.2 |
| Nature | community-driven data/model training (farmers contribute images) |

## Reading of the data

- **Actively developed, but bus-factor = 1.** One author drives ~all engine code. That
  means fast progress and a clean, coherent codebase, but real key-person risk and no
  formal support/SLA.
- **Bursty, not abandoned.** Quiet mid-summer then a burst of app-release automation and
  feature branches in Oct 2026. The `codex/cow-identity` + `identity` branches show a
  **significant new feature in flight: individual cow identification** — directly
  valuable for a farm (tie calving/heat events to a specific animal).
- **Healthy model community.** The models repo (20★) and rapid model versions suggest the
  data/model side is the project's center of gravity and will keep improving regardless
  of the engine's pace.
- **Clean extension points already exist.** The engine is model-agnostic and fully
  config-driven (sources / YOLO / VLM / exporters). Most customization needs **no code
  change** — just config + your own trained model.

## Licensing — important for "a system we make better"

- Engine + models are **AGPL-3.0**, and the CowCatcherAI README states the software and
  trained model are **"not authorized for commercial use or redistribution without
  explicit permission."**
- Implications if you fork/productize:
  - AGPL requires publishing your modifications if you offer it as a network service.
  - Commercial use/redistribution needs **explicit permission** from the authors.
  - => If this ever becomes a product, talk to the maintainer first. For internal
    single-farm use, AGPL is not a problem.

## Recommendation: don't fork (yet) — layer on top + contribute selectively

For the current goal (prove CalvingCatcher on the Intel PC), and likely well beyond it:

1. **Use upstream as-is, with pinned versions.** Pin the engine release/image tag and the
   model version in our `deploy/` bundle so deployments are reproducible even as upstream
   churns. You inherit active development (incl. cow-identity) for free.
2. **Keep a thin private layer in this CowVision repo** — exactly what we're already
   building: configs, Home Assistant automations, deployment/runbook tooling, and
   (later) your own trained models. This is "making it better" without a fork's
   maintenance burden.
3. **Contribute upstream for anything general** (e.g. Linux/OpenVINO packaging, exporter
   tweaks, HA docs). PRs are merged here, so improvements can land for everyone and you
   avoid carrying patches.
4. **Only fork when you have a concrete divergence** you can't get upstream — e.g. a
   custom model you won't share, a feature the maintainer declines, or a productization
   path (then settle licensing first). If you do, prefer a **soft fork** (track `main`,
   carry a small patch set) over a hard fork.

### Why not refactor/fork now
- The codebase is already clean and single-authored; a refactor fork mostly buys you
  maintenance work and upstream drift.
- The farm value is in **deployment + data/models + integration**, which you can own in
  this repo without touching engine internals.
- Bus-factor-1 cuts both ways: a fork makes *you* the sole maintainer of a larger surface.

## Risk register (to revisit)
- [ ] Key-person risk on the engine (mitigate: pin versions, keep this repo able to
      rebuild from the pinned commit we cloned).
- [ ] Unstable release cadence (`app/test-*` tags) → always pin, never float `latest`.
- [ ] AGPL + no-commercial-use on model → clarify with maintainer before any product.
- [ ] Watch `codex/cow-identity` → may add individual-cow ID worth adopting.
