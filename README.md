# Intel DLSS5 NR — Cyberpunk 2077

**2026-10-29: Default builds now use optimized Full (232 dispatches, ~17.45 ms) and optimized Small (108 dispatches, ~9.98 ms), plus late-latch streaming (~5.43 ms game frame-period improvement in the recorded scene).** See [optimization history and evidence](docs/optimization/README.md). The Vulkan backend substantially references the community **mochizuki0323 / DLSSNR-AMD** project; see [attribution](docs/optimization/AMD-ATTRIBUTION.md). Build Full first, then pass `-FullModel local/vk102` when building Small. Older performance tables below are historical.


[中文说明](README.zh-CN.md) · [Build dependencies and installation](INSTALL.md)

Experimental **NR + FSR XMX upscaling + XeSS Frame Generation** on Intel Arc B580 / Windows x64. This repository supplies the Vulkan **NR backend, game bridge, model extraction/build tools and control panel**. The FSR XMX upscaler and XeSS FG components are installed separately; XeSS FG here means frame generation, not XeSS Super Resolution.

## What you need to supply

Provide the appropriate **local `nvngx_dlssnr.dll`**. Both backends can now be extracted and built from source; **an existing VK102 package is not required**. DLLs are read as data and never executed. No model DLL, weights, extracted tensors, compiled shaders or third-party game DLLs are distributed.

| Build profile | Model DLL | Resource | Frozen network | DLL SHA-256 |
|---|---|---|---|---|
| `small` | 310.9.16.0 Small | `WEIGHTS_CC_SMALL_FP8` | 76 rows / 108 dispatches | `2bc19bc09a7b89dd44f73e2ac0108fcc586e2154bdd0830f242f4f040e28789f` |
| `vk102` | 310.8.0.0 full model | `WEIGHTS_HT` | 152 rows / 232 dispatches | `8270b350cd82de5ce89806872cdd6b6a9249b80836b91bbeb3573470744cc206` |

Use separate folders for the two DLLs. Other DLL identities are rejected. A ZIP containing one supported DLL is accepted too. These are the existing game backends; the accepted 232-pass FP16 chain is now included; INT8 experiments are not included.

## The tested combination and performance

| Component | Role | Supplied here |
|---|---|---|
| Vulkan NR (`small` or `vk102`) | Neural image processing and appearance controls | Source and local build tools |
| FSR XMX | Super resolution on the separately installed compatible XMX implementation | No third-party DLLs |
| XeSS FG / XeFG | Frame generation | No third-party DLLs |
| OptiScaler | Upscaler/frame-generation routing and the working game integration | External dependency |

**User-reported base rendering FPS, before XeSS frame generation**, with 1280×720 NR input on B580:

| NR backend | Input | Approximate base FPS |
|---|---|---:|
| VK102 | 720p | **24 FPS** |
| Small | 720p | **34 FPS** |

These are local observations, not a cross-scene benchmark or a performance guarantee. Live Small screenshots below show roughly 30–32 base FPS at those instants. The higher OSD readings around 93–94 / 126–127 FPS are separate frame-generation presentation readings; do not compare them to base FPS. Panel `total`/`tail` values are internal bridge intervals with cross-frame overlap, not game frame time or isolated network time.

**720p means the NR input, not necessarily the display output.** Keep NR input at 1280×720. Known local 1080p / 1440p display observations do not establish support for arbitrary model input dimensions or all output modes.

## Build either model from its DLL

Required: Windows x64 / B580, Python 3.12+ with NumPy, Visual Studio 2022 C++ Build Tools and Windows SDK, CMake 3.24+, **glslang 16.5.0**, Vulkan headers, and the pinned OptiScaler source dependency described in [INSTALL.md](INSTALL.md). These are development dependencies; an NR package is not one of them. Use a short, writable ASCII path such as `C:\Dev\intel-dlss5nr-cyberpunk2077`; existing native file APIs still have Windows path-length limits.

From the repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-model.txt

# Paths to your separately installed development dependencies.
$py = ".\.venv\Scripts\python.exe"
$opti = "C:\Dev\OptiScaler"
$glslang = "C:\Tools\glslang\bin\glslang.exe"
$vk = "C:\VulkanSDK\Include"

# Small: local/small -> local/game-package
.\tools\Build.ps1 -Profile small -FullModel "local/vk102" -Dll "C:\Models\Small\nvngx_dlssnr.dll" `
  -OptiScalerSource $opti -Glslang $glslang -VulkanInclude $vk -Python $py

# VK102: local/vk102 -> local/game-package-vk102
.\tools\Build.ps1 -Profile vk102 -Dll "C:\Models\VK102\nvngx_dlssnr.dll" `
  -OptiScalerSource $opti -Glslang $glslang -VulkanInclude $vk -Python $py
```

Build only the model you want, or run both commands for switching. The entry point verifies the DLL and extracted tensors, packs the exact B580 weight layout, compiles the frozen network and bridge shaders, builds the native component and ASI, runs CPU checks and assembles a local game package. **It does not install or start the game.** Use new/empty model and package output directories; `-Output` and `-PackageOutput` can select different locations for another build.

Each package contains its own `manifest/`, generated `assets/`, matching `bin/nrvk_bridge.dll`, `game-files/`, `panel/` and `config/`. Keep it together at its final location. The new VK102 path verifies **599 tensor files, 150 model-derived cold resources and 40 network shaders**; developer fixture images are not used.

## Configure and install

Close the game and keep its existing working OptiScaler + FSR XMX + XeSS FG installation. Back up the existing game `bin/x64` files and settings before copying anything.

For **Small only**:

```powershell
python local/game-package/panel/configure_game.py --package local/game-package --game-bin "C:/Games/Cyberpunk2077/bin/x64"
```

For **VK102 only**, built from your full-model DLL above:

```powershell
python local/game-package-vk102/panel/configure_game.py --package local/game-package-vk102 --game-bin "C:/Games/Cyberpunk2077/bin/x64"
```

For **both**, boot Small and register the newly built VK102 package:

```powershell
python local/game-package/panel/configure_game.py --package local/game-package --game-bin "C:/Games/Cyberpunk2077/bin/x64" --vk102-manifest local/game-package-vk102/manifest
```

Copy the **contents** of the chosen boot package's `game-files/` into the game's `bin/x64/`. Do not install both sets over one another. A VK102 boot package can instead register Small with `--small-manifest local/game-package/manifest`.

The configuration command updates paths inside the package only. It requires your game EXE and OptiScaler INI to exist, preserves NR appearance settings, and does not edit the game or install upscaler/FG DLLs. If you move a package, rerun configuration and recopy its generated `plugins/nr_bridge.ini`.

## Use the panel

Run `Launch-NR-Panel-Game.cmd` from the chosen boot package. Default address: **http://127.0.0.1:8788/**. To use another port, set `NR_PANEL_PORT` before launching. Local screenshots use port 8789 because another panel was already running.

- **Backend**: only configured backends are shown. Select Small or VK102 and Save. The bridge switches at a frame boundary, resets history and uses that model's own component and assets.
- **Enabled / style / strength / structure / tone / skin / mask / display strength**: per-frame appearance controls; they do not rebuild a model. Styles are Classic, Natural and Cinematic.
- **Mounted + increasing processed count**: check actual processing, not just DLL loading. Inspect scene cuts, loading/reset, motion and exposure changes yourself.
- **OptiScaler spoof presets**: game restart required. Edit only with the game closed; the panel retains an INI backup. No elevation or alternate-shell bypass is used.

In the local working combination, OptiScaler used `Dx12Upscaler=fsr31` for its FSR4/XMX-capable route, `FGInput=DLSSG` and `FGOutput=XeFG`. The route name alone does not prove that an arbitrary FSR DLL is XMX accelerated. Supply compatible components separately, following their own installation instructions. This repository does not silently replace them or the global driver environment.

## Real game screenshots

Original user-supplied screenshots, preserved without retouching. “Original” below means **NR disabled**, not proof that upscaling and frame generation are disabled. The panel states identify the selected model/style. Camera, NPC pose and lighting vary, so these are appearance examples rather than pixel-aligned A/B measurements.

### NR disabled / original image

![Original game image, NR disabled](docs/images/nr-off.png)

### VK102 and Small styles

| Style | VK102 310.8 | Small 310.9.16 |
|---|---|---|
| Classic | <img src="docs/images/vk102-classic.png" width="480" alt="VK102 Classic"> | <img src="docs/images/small-classic.png" width="480" alt="Small Classic"> |
| Natural | <img src="docs/images/vk102-natural.png" width="480" alt="VK102 Natural"> | <img src="docs/images/small-natural.png" width="480" alt="Small Natural"> |
| Cinematic | <img src="docs/images/vk102-cinematic.png" width="480" alt="VK102 Cinematic"> | <img src="docs/images/small-cinematic.png" width="480" alt="Small Cinematic"> |

Click an image for its original resolution. Screenshots are documentation assets explicitly supplied for publication; model/input/output fixture dumps are excluded.

## Rollback and limitations

Close the game. Restore your backed-up `nrvk_bridge.dll`, `plugins/CyberpunkNRBridge.asi`, `plugins/nr_hdr_proxy.hlsl`, `plugins/nr_bridge.ini` and `plugins/NRB-deferred-identity.enable`; remove only files introduced by this installation. Restore the intended OptiScaler INI backup if you changed spoof settings. Leave unrelated game files alone.

This is an Experimental source release. Local user smoke tests and byte-verified asset builds do not establish extended stability, all-scene quality, 4K support or bit-identical Small reference output. Keep generated `local/` and `build/` data private. Do not commit DLLs, extracted model data or game fixture captures.

[BUILD-VERIFICATION.md](BUILD-VERIFICATION.md) records build checks. GLSL builds verify raw compiler output before restoring the frozen `NoContraction` decorations, then verify final SPIR-V hashes. No precompiled shader payload is embedded in scripts.

Reference/model tools: [DLSSNR-AMD](https://github.com/mochizuki0323/DLSSNR-AMD). See [LICENSES.md](LICENSES.md) and [PORTING.md](PORTING.md). This is not an official NVIDIA, Intel, AMD, CD Projekt Red or OptiScaler product.
