# Optimized FP16 update — 2026-10-29

Download the **current main branch** using Code → Download ZIP, or clone the repository. The older v0.2.0 release archive contains the earlier 266/118-dispatch backends; the optimized sources described here are on main.

| Component | Current default |
|---|---|
| Full (`vk102`, panel key `102`) | **232 dispatches**, 152 rows, 502 buffers, 39 network shaders, 165 cold resources |
| Small (`small`) | **108 dispatches**, 76 rows, 222 buffers, 39 network shaders, 70 cold resources |
| Full network | **17.450 ms**; latest paired campaign 18.724→17.450 ms |
| Small network | **9.980 ms**; paired fixed-input batch 14.324→9.980 ms |
| Late-latch streaming | **Default ON**; game period 34.81→29.38 ms in the recorded same-scene comparison |

Platform: Intel Arc B580, Windows x64, 1280×720 NR input. Full historical development starts at 50.821 ms. Network inference and game frame period are measured separately.

## Build and use

1. Download main and install the dependencies listed in INSTALL.md.
2. Build Full from the supported 310.8.0.0 model DLL.
3. Build Small from the supported 310.9.16.0 DLL with `-FullModel local/vk102`.
4. Configure the selected boot package and register the other backend.
5. Back up existing bridge files, copy the boot package's game-files contents into Cyberpunk bin/x64.
6. Start the panel script, then launch Cyberpunk from the normal game launcher.

The game uses separately installed OptiScaler + FSR XMX + XeSS FG components. This repository distributes source and build recipes; model DLLs and generated assets remain local. INT8 is a separate development branch.

[中文完整教程](docs/USER-GUIDE.zh-CN.md) · [Install](INSTALL.md) · [Full optimization history](docs/optimization/FULL-HISTORY.md) · [Build verification](BUILD-VERIFICATION.md)

The Vulkan backend substantially references **望月 / mochizuki0323 / DLSSNR-AMD**, including producer/consumer organization, layouts and fusion. MIT source notices and attribution are retained.
