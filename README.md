# CowVision

Workspace for figuring out how to deploy and use **CowCatcher AI** (and the
**CalvingCatcher** model) on a local farm. This folder is the single source of
truth for research, decisions, progress, and hand-off instructions.

- Upstream project / docs: https://jacobsfarm.github.io/website/ (a.k.a. cowcatcherai.com)
- Engine repo: https://github.com/ESchouten/ai-detector
- Models + example configs repo: https://github.com/CowCatcherAI/CowCatcherAI

> **Status:** Research & planning only. Nothing is deployed yet.
> This workstation is *not* a deployment target — see `docs/deployment.md`.

## Folder layout

```
CowVision/
├── README.md              <- you are here (overview + how to use this folder)
├── AGENTS.md              <- instructions for AI agents working in this repo
├── docs/
│   ├── progress.md        <- running log of what was done / decided (append-only)
│   ├── research.md        <- facts gathered about the system & how it works
│   ├── deployment.md      <- deployment options & recommendation for the farm
│   ├── calvingcatcher.md  <- notes specific to the CalvingCatcher tool (current focus)
│   └── open-questions.md  <- things we still need to decide / find out
└── repos/                 <- cloned upstream repos (read-only reference)
    ├── ai-detector/       @ bcd98db (2026-09-18)
    └── CowCatcherAI/      @ f5acd76 (2026-09-05)
```

## How to use this folder

1. Read `docs/research.md` for how the system works.
2. Read `docs/deployment.md` for the deployment plan and recommendation.
3. Append every meaningful action/decision to `docs/progress.md`.
4. Keep `docs/open-questions.md` current so the next person/agent can continue.
