# Linux / Proxmox deployment — do we need to rewrite the source?

Question: the tool looks Windows-reliant for GPU. Can we rewrite it to be
Windows-independent and run on a Proxmox host in a Linux VM?

**Short answer: no rewrite needed. The engine already runs on Linux with GPU.** What
is Windows-only is a *single optional code path* for reaching Intel/AMD GPUs via
**Windows ML**. On Linux, GPU acceleration comes through the normal ONNX Runtime /
PyTorch providers. The real decision for Proxmox is **hardware passthrough**, not
source code.

## What is actually Windows-specific (verified in source `bcd98db`)

- `utils/version.py` sets a build-time `TYPE` (`default` | `windowsml` | `cuda` |
  `tensorrt`).
- `detection/yolo.py`: a `.pt` model on a `cuda`/`tensorrt` build runs through
  **Ultralytics + torch (CUDA / TensorRT)** directly. On other builds it is exported
  to ONNX and run via **ONNX Runtime**.
- `utils/onnx.py`: the Windows ML provider auto-registration only runs when
  `sys.platform == 'win32'` **and** `TYPE == 'windowsml'`. Otherwise it uses
  `ort.get_available_providers()` → on Linux that is **CUDAExecutionProvider**,
  **TensorRTExecutionProvider**, **OpenVINOExecutionProvider**, or **CPU**.
- `utils/onnx.py` already contains explicit handling for **OpenVINO** (Intel) and
  **CoreML** (Apple) EPs — i.e. non-Windows GPU backends are first-class.

Conclusion: Windows ML is just the *Windows* way to reach Intel/AMD GPUs. Linux has
its own (CUDA for NVIDIA, OpenVINO for Intel). The codebase is portable as-is.

## The real constraint on Proxmox: GPU passthrough

Proxmox is **KVM/QEMU**, which — unlike VirtualBox — **supports PCIe passthrough**
(VT-d / IOMMU). So a GPU *can* be handed to a Linux VM. Which GPU matters:

| Scenario | Works on Proxmox Linux VM? | How | Effort |
| :------- | :------------------------- | :-- | :----- |
| **Dedicated NVIDIA GPU passthrough** | ✅ best | VM → Docker `ai-detector` (`runtime: nvidia`) or `cuda` build. Full accel, **zero code changes**. | moderate (IOMMU setup) ⭐ |
| **No passthrough (CPU-only VM)** | ✅ works | Default build on CPU. Slower but fine for slow CalvingCatcher. | easy |
| **Intel iGPU (UHD 770) passthrough** | ⚠️ hard | Would use OpenVINO on Linux. But the iGPU is usually the host's only/primary display; GVT-g is deprecated on 12/13th gen and iGPU SR-IOV is fiddly. | high / not recommended |
| **Apple Silicon** | ✅ (not a VM) | CoreML EP, native macOS. | n/a |

### Why the current Intel box is awkward on Linux specifically
On Windows the UHD 770 is reached via Windows ML. On a Proxmox Linux VM you'd instead
need the iGPU **passed through** (painful on consumer Intel) and run via OpenVINO. That
is why, *for the existing machine*, native Windows is the pragmatic choice — not a code
limitation.

## Recommended shapes

1. **Future dedicated CowVision PC = Proxmox host + NVIDIA GPU passed through to a Linux
   VM, running the Docker image.** This is the clean, future-proof target: full GPU,
   reproducible, auto-restart, no source changes, and it is exactly what the project's
   Docker images are built for. Add heat detection here with headroom.
2. **Interim / low-effort Linux = CPU-only VM.** No passthrough hassle; acceptable for
   CalvingCatcher (slow event). Upgrade to GPU passthrough later.
3. **Avoid** trying to passthrough the consumer Intel iGPU under Proxmox — high effort,
   low payoff. For the current Intel PC, stay on the native Windows winml `.exe`.

## Do we ever need to touch the source?

Only *packaging*, never a rewrite:
- To use an **Intel GPU on Linux**, install an OpenVINO-enabled ONNX Runtime
  (`onnxruntime-openvino`) and build with that extra — the EP handling already exists.
- For **NVIDIA on Linux**, nothing to change: the Docker/`cuda` build already targets it.
- A small, optional contribution upstream could add a documented `linux-openvino`
  dependency extra, but that is convenience, not a dependency rewrite.

So: the path to "Windows-independent deployment" is **buy/allocate an NVIDIA GPU and run
the existing Linux/Docker build** (ideally via Proxmox passthrough) — the software is
already there.
