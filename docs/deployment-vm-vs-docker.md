# VM vs Docker vs native — deploying on the Lely OptiPlex (Intel UHD 770)

Question: the farm PC is effectively a server running Windows 11 with Lely tools +
VirtualBox hosting a Home Assistant VM. Can we also run the vision tools as a
VirtualBox VM? Is Docker better? Is the Intel GPU good enough for initial testing?

Short answer: **run the native Windows `winml` `.exe`.** A VirtualBox VM is possible
but forces **CPU-only** inference (no GPU), and Docker on this machine would also be
CPU-only. The Intel UHD 770 is **good enough for initial testing** — but only the
native Windows build can actually use it.

## The deciding factor: GPU access

Verified in the engine source (`repos/ai-detector`, commit `bcd98db`):

- `utils/winml.py` registers Windows ML execution providers via the **Windows App SDK
  (`winui3.microsoft.windows.ai.machinelearning`)**. This only activates when
  `sys.platform == "win32"` **and** the build `TYPE == "windowsml"`.
- For an Intel iGPU, that surfaces the **OpenVINO GPU execution provider**
  (`utils/onnx.py` has explicit OpenVINO GPU handling).
- Therefore the **Intel UHD 770 is only usable from the native Windows `winml` build**.
  Any Linux guest (VM or container) does not take this path and falls back to the
  default ONNX Runtime **CPU** provider.

### Why a VirtualBox VM cannot use the GPU
- **VirtualBox has no GPU compute passthrough.** Its virtual display adapter does not
  expose DirectML / OpenVINO / CUDA to the guest. ML inference in a VBox guest = CPU.
- True PCIe passthrough (VT-d) is a **VMware ESXi / KVM** feature, not VirtualBox, and
  would hand the *only* iGPU entirely to one VM (breaking the host display) — not
  practical on a shared management PC.
- Windows ML is Windows-only anyway, so a Linux VM could never use the `winml` path.

### Why Docker on this machine is also CPU-only
- The project's Docker image targets **NVIDIA** GPUs (`compose.yml` uses
  `driver: nvidia`, `runtime: nvidia`). There is no NVIDIA card here.
- Docker Desktop on Windows runs Linux containers under **WSL2**. WSL2 GPU compute is
  mature for NVIDIA CUDA; the **Intel iGPU is not exposed** to the NVIDIA-targeted
  image. Result: the container runs YOLO on **CPU**.

## Option comparison (for THIS Intel-only machine)

| Approach | Uses UHD 770? | Speed | Isolation | Auto-restart | Effort | Verdict |
| :------- | :-----------: | :---- | :-------- | :----------- | :----- | :------ |
| **Native Windows `winml` .exe** | ✅ yes (OpenVINO EP) | ~200–600 ms/frame | low (shares host) | `.bat` loop / Task Scheduler | low | ⭐ **Recommended** |
| **VirtualBox Linux VM** | ❌ no (CPU only) | slower + VM overhead | high (like the HA VM) | VM autostart + container | high | Only if isolation > performance |
| **Docker on Windows (WSL2)** | ❌ no (CPU only) | slower than native | medium | `restart: unless-stopped` | medium | Middle ground, but loses the GPU |
| **Dedicated mini-PC / Jetson** | ✅ (own GPU) | fast | full | native | hardware cost | Best if the shared PC gets loaded |

## Is the Intel UHD 770 good enough for initial testing?

**Yes — for initial testing and likely for production of CalvingCatcher.**

- Via the native `winml` build the UHD 770 runs ~200–600 ms/frame (website figure).
- Calving is a **slow** event: at `interval: 0.5 s` we only process ~2 frames/sec per
  camera and use `strategy: "LATEST"`, so we don't need real-time throughput.
- For a first test, use **1 camera or a recorded clip** — the iGPU handles that
  comfortably. Scale to 3 cameras and watch load.
- Caveat: with all **3 cameras** at once the iGPU may not process every frame within
  the budget, but `LATEST` + the slow nature of calving make this acceptable. If you
  later add fast "heat/mounting" detection, consider a discrete NVIDIA GPU or a
  dedicated device.
- CPU-only fallback (VM/Docker) on the i5-13500 would still *work* for calving testing,
  just slower and competing with Lely + HA for CPU — not recommended.

## Recommendation

1. **Deploy the native Windows `winml` `.exe`** directly on the Windows 11 host, next
   to the Lely tools (see `docs/deployment-plan.md`). It's the only way to use the
   UHD 770 and the simplest to run.
2. Keep it **isolated-enough** via its own folder + its own user/scheduled task; it
   does not need a VM to coexist with Lely and the HA VM.
3. It will **webhook into the existing Home Assistant VM** over the LAN — that already
   gives you the "integrate with the farm automations" benefit without containerizing
   the detector.
4. Reassess only if the shared PC shows load problems → then move to a **dedicated
   mini-PC / Jetson Orin Nano**, not a VBox VM.

### Why not match the HA "run-as-a-VM" pattern?
Home Assistant is pure CPU/IO orchestration, so a VM is a great fit. The vision tool is
**GPU-bound**, and VirtualBox cannot give a guest the GPU — so VM-ifying it throws away
the one accelerator this machine has. Different workload → different packaging.

## Is the UHD 770 a *good* candidate (not just "good enough")?

**Verdict: acceptable for CalvingCatcher, but it's the weakest viable option — a
"good enough starter", not a strong candidate.**

UHD 770 facts: integrated Xe-LP (Gen12.2), 32 EUs, ~0.8 TFLOPS FP32, no dedicated
VRAM (uses system RAM — fine, 32 GB here), and it is **shared with the Windows
display, the Lely tools, and the HA VM host**.

Good for:
- CalvingCatcher: a **slow** event, 3 cams at `interval 0.5s`, `strategy LATEST`.
  ~200–600 ms/frame via OpenVINO is plenty of headroom.
- Zero extra hardware cost; already present.

Weak for:
- **Throughput headroom** — can't process every frame on 3 streams at once; relies on
  frame-dropping. Fine for calving, marginal if you later add **heat/mounting**
  detection (fast event, wants more fps).
- **Resource contention** on a shared production/management PC.
- ~10–20× slower per frame than a modest discrete GPU.

Rough comparison:

| Device | Time/frame | Notes |
| :----- | :--------- | :---- |
| Intel UHD 770 (winml/OpenVINO) | 200–600 ms | present, free, shared, slow |
| GTX 1650 / RTX 2060 (cuda126) | 40–60 ms | cheap, no power connector needed (1650) |
| RTX 3050/4060 (cuda130) | 10–40 ms | big headroom, future-proof for heat too |
| Jetson Orin Nano | edge-class | separate always-on appliance |

Recommendation: **start on the UHD 770** for testing and CalvingCatcher go-live. If
you see missed events, add cameras, add heat detection, or notice the iGPU competing
with Lely/HA, drop in a **low-profile NVIDIA card** (the OptiPlex MT has a PCIe slot;
check the PSU/low-profile clearance — a GTX 1650 LP needs no extra power) or move to a
**dedicated mini-PC / Jetson**. That upgrade switches the engine build to a `cuda`
variant — no config changes needed.
