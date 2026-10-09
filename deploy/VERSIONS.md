# Pinned versions (reproducibility)

Pin these exact versions for every deployment so results are reproducible even as the
single-maintainer upstream churns (see `../docs/upstream-assessment.md`). Never float
`latest` in production. Captured 2026-10-07.

## Engine — standalone detector (STABLE, recommended for the farm)

| What | Pin |
| :--- | :-- |
| Release tag | **`detector/v0.7.1`** (stable, non-prerelease; published 2026-06-25; from `main`) |
| Windows/Intel (our PC) | `aidetector-winml-v0.7.1.zip` (~402 MB) |
| URL | https://github.com/ESchouten/ai-detector/releases/download/detector/v0.7.1/aidetector-winml-v0.7.1.zip |
| macOS (reference) | `aidetector-osx-v0.7.1.zip` |

> ⚠️ Our research + configs were derived from upstream `main` @ `bcd98db` (2026-09-18),
> which is **newer** than the `v0.7.1` stable zip (2026-06-25). Before go-live, validate
> `config.json` against the actual downloaded build (run it — the engine reports unknown
> fields). If a field we use is missing, upgrade to the newest **stable** `detector/vX.Y.Z`
> at that time, or adjust the config.

### Newer distribution track (awareness, NOT pinned yet)
The project is actively shipping a new packaged desktop app under **prerelease** tags
`app/test-*` (currently `AI-Detector 0.0.64`, Windows installer + auto-update via
`.nupkg`/`.delta`, plus `.deb`/`.dmg`). Bleeding-edge and auto-updating — not suitable
for a pinned production baseline today, but likely the future install path. Re-evaluate
once it reaches a stable (non-prerelease) release.

## Engine — Docker image (for the FUTURE NVIDIA/Proxmox PC)

| What | Pin |
| :--- | :-- |
| Image | `ghcr.io/eschouten/ai-detector` |
| Pin method | **by digest**, not a tag. At first pull run: `docker pull ghcr.io/eschouten/ai-detector:latest && docker inspect --format '{{index .RepoDigests 0}}' ghcr.io/eschouten/ai-detector:latest` and record the `@sha256:...` here. |
| Jetson variant | `ghcr.io/eschouten/ai-detector:main-jetpack6` (also pin by digest) |
| Recorded digest | _TBD at first pull — paste here_ |

## Model — CalvingCatcher (STABLE pin)

| What | Pin |
| :--- | :-- |
| File | **`calvingcatcherV10.1.pt`** (~44 MB; asset updated 2026-10-01) |
| Release tag | `CalvingcatcherV1` (repo `CowCatcherAI/CalvingCatcherAI`) |
| URL | https://github.com/CowCatcherAI/CalvingCatcherAI/releases/download/CalvingcatcherV1/calvingcatcherV10.1.pt |
| Note | Only `.pt` assets exist; the winml build auto-exports to ONNX on first run. |

> For a fully offline/locked deploy, download the `.pt` once, drop it in `deploy/models/`,
> reference it by local path in `config.json`, and record its sha256:
> `sha256sum calvingcatcherV10.1.pt` → _TBD_.

## Reference source clones (in `../repos/`, read-only)

| Repo | Commit | Date |
| :--- | :----- | :--- |
| `ESchouten/ai-detector` | `bcd98db85823c5f474d75a3fbe926df961be0782` | 2026-09-18 |
| `CowCatcherAI/CowCatcherAI` | `f5acd766e464a110f74aa90c717180f92798315b` | 2026-09-05 |

These are the exact snapshots our configs/docs were written against. To refresh:
`git -C ../repos/<name> fetch && git -C ../repos/<name> log -1`, then re-verify the
config schema and update this file + `../docs/progress.md`.
