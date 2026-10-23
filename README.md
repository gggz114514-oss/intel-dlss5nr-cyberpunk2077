# Intel DLSS5 NR — Cyberpunk 2077

Experimental Vulkan neural rendering for **Intel Arc B580 on Windows x64**, with a loopback control panel for Cyberpunk 2077.

**Supply your own local `nvngx_dlssnr.dll`.** This repository provides source code and the extraction tool, without model weights, game captures, NVIDIA DLLs, compiled shaders or third-party game DLLs. Extraction reads the DLL as data and never executes it.

This packages the existing **310.9.16.0 Small FP16 Vulkan backend**: 76 logical rows / 118 network dispatches. Ongoing full-model FP16 and INT8 research candidates are not included.

## Build from your DLL

Prerequisites: Python 3.12+, Visual Studio 2022 C++ Build Tools and Windows SDK, CMake 3.24+, glslang **16.5.0**, Vulkan headers, and the pinned external OptiScaler source dependency in [INSTALL.md](INSTALL.md).

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-model.txt

.\tools\Build.ps1 `
  -Dll "C:\Models\nvngx_dlssnr.dll" `
  -OptiScalerSource "C:\Dev\OptiScaler" `
  -Glslang "C:\Tools\glslang\bin\glslang.exe" `
  -VulkanInclude "C:\VulkanSDK\Include" `
  -Python ".\.venv\Scripts\python.exe"
```

Run from the repository root. The script extracts and verifies the model, packs B580 resources, compiles all network/bridge shaders, builds the native backend and ASI, runs CPU checks, then assembles **`local/game-package/`**. It does not change the game.

| Supported profile | DLL SHA-256 |
|---|---|
| 310.9.16.0 Small, `WEIGHTS_CC_SMALL_FP8` | `2bc19bc09a7b89dd44f73e2ac0108fcc586e2154bdd0830f242f4f040e28789f` |

Other versions are rejected. No pre-extracted tensors, `.bin`/`.spv` files or developer images are needed. A ZIP containing one model DLL is also accepted. See [ASSETS.md](ASSETS.md) for individual steps.

## Game and panel

Follow [INSTALL.md](INSTALL.md) to configure the package, back up existing files and copy its `game-files/` into Cyberpunk's `bin/x64/`. A compatible, working OptiScaler installation is required separately; this project does not redistribute or automatically install an upscaler.

Start **`local/game-package/Launch-NR-Panel-Game.cmd`**. The panel uses **`127.0.0.1:8788`** and controls enable, style, intensity, structure, tone, skin, mask and display strength. It shares one writable configuration/status location with the ASI. Python runs outside the game process.

The panel does not extract or manage weights. OptiScaler preset edits require the game to be closed and create a backup. Permission failures are reported without elevation or alternate-shell copying.

Have an existing VK102 310.8 package? [Register its manifest](INSTALL.md#keep-an-existing-vk102-backend) to retain Small/VK102 hot switching in the same panel. The included extraction/build profile remains Small.

## Scope and measurements

- B580 (`8086:e20b`), SG32 cooperative matrices, FP16 storage and the documented Vulkan 1.3 feature contract.
- **Fixed NR input: 1280×720.** A larger display output does not change model input geometry.
- The existing local integration produced frames at 1080p and 1440p output. 4K and extended stability remain unverified.
- Clean model/shader builds, native CPU recording/ABI tests and panel checks validate the source package. They do not replace game testing of newly built binaries.
- Remaining Small reference differences are not claimed bit-identical or image-quality accepted.

Measure performance with external game frame time/FPS. Bridge `total`/`tail` intervals overlap adjacent frames and are not game frame time. No performance guarantee is made.

## Source and provenance

GLSL sources rebuild all network shaders. The build verifies the raw compiler SHA before restoring the frozen `NoContraction` pattern, then checks the final shader SHA. No script embeds precompiled SPIR-V payloads.

Reference/model tools: the community [DLSSNR-AMD project](https://github.com/mochizuki0323/DLSSNR-AMD). See [LICENSES.md](LICENSES.md) and [PORTING.md](PORTING.md). This is not an official NVIDIA, Intel, AMD, CD Projekt Red or OptiScaler product.

Generated `local/` and `build/` files remain private. Do not commit or redistribute model outputs or game files.
