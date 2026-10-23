# Build and install

## Build prerequisites

- Windows x64, Intel Arc B580 and a driver exposing the features in `source/vulkan/port_network_bridge_backend.h`.
- Visual Studio 2022 C++ Build Tools / Desktop C++ workload with Windows SDK; CMake 3.24+ on PATH (or `-CMake` to `Build.ps1`).
- Python 3.12+ and NumPy (`requirements-model.txt`).
- [glslang 16.5.0](https://github.com/KhronosGroup/glslang/releases/tag/16.5.0); other compiler output is not interchangeable.
- Vulkan headers: your SDK's `Include` directory or `include` in [Vulkan-Headers](https://github.com/KhronosGroup/Vulkan-Headers).
- External [OptiScaler source](https://github.com/optiscaler/OptiScaler), commit `7534ad00bf9e590eedb99e8dd9fd8c89dae3654f` (v0.9.4 integration). Required: `external/nvngx_dlss_sdk/nvsdk_ngx.h`, `OptiScaler/include/detours/detours.h`, `OptiScaler/library/detours/detours.lib`.

```powershell
git clone https://github.com/optiscaler/OptiScaler.git C:\Dev\OptiScaler
git -C C:\Dev\OptiScaler checkout 7534ad00bf9e590eedb99e8dd9fd8c89dae3654f
```

Use a short, writable ASCII path: the existing Windows bridge uses ANSI file APIs and remains subject to Windows path-length limits. Keep the model DLL outside the source tree. No system Python, registry or driver changes are made.

## Build

Run the commands in [README.md](README.md) or [README.zh-CN.md](README.zh-CN.md) from the repository root. Choose `-Profile small` for the supported 310.9.16.0 Small DLL, or `-Profile vk102` for the supported 310.8.0.0 full-model DLL. Both start from the local DLL; no existing model package is needed. Use new/empty model and package directories. The script stops on any extraction, shader identity, compile or CPU-check failure.

The two native targets can also be configured after asset preparation:

```powershell
cmake -S source/vulkan -B build/vulkan -A x64 -DNR_MODEL_DIR="C:/path/to/repo/local/small" -DVULKAN_INCLUDE_DIR="C:/VulkanSDK/Include"
cmake --build build/vulkan --config Release
cmake -S source/bridge -B build/bridge -A x64 -DOPTISCALER_SOURCE="C:/Dev/OptiScaler" -DNRB_XESS_IDENTITY_TEST=ON -DNRB_DEFERRED_IDENTITY_TEST=ON -DNRB_LIVE_NR_TEST=ON -DNRB_MULTI_ROUTE_LIVE=ON -DNRB_TAIL_ORDER_PROBE=ON
cmake --build build/bridge --config Release
```

Historical `*_TEST` switches select the existing experimental game path. One-frame readback and developer GPU probes are disabled in the default build. The separate legacy Python/Triton runtime is not part of this publication.

The Small output is `local/game-package/`; VK102 uses `local/game-package-vk102/`. Each contains generated runtime assets, its matching component in `bin/`, locally built game bridge, D3D12 proxy shader source, panel and configuration. Raw extraction/debug outputs are not copied into it. The manual native commands above illustrate Small; use `local/vk102` as `NR_MODEL_DIR` for VK102. `Build.ps1` selects it automatically.

## Configure, install, run

Close Cyberpunk. Keep the package at its final writable location:

```powershell
python local/game-package/panel/configure_game.py --package local/game-package --game-bin "C:/Games/Cyberpunk2077/bin/x64"
```

This updates the package's shared manifest/panel/status paths and the panel's OptiScaler path. The target must contain `Cyberpunk2077.exe` and your separately installed `OptiScaler.ini`. It does not install game files or alter upscaler settings.

1. Back up any existing `nrvk_bridge.dll` and same-name files under `plugins/`.
2. Copy the **contents** of `local/game-package/game-files/` into the game's `bin/x64/`.
3. Keep the separately installed working OptiScaler/upscaler. No `dxgi.dll`, NVIDIA/FSR/XeSS or frame-generation DLL is provided.
4. Start `Launch-NR-Panel-Game.cmd` in the package; panel address: `http://127.0.0.1:8788/`.
5. Known 1080p configuration: 1920×1080 display output + DLSS Quality input (1280×720) through the working OptiScaler route. Other output settings must still supply exactly 1280×720 to NR. Do not edit shader grids to unlock model input.
6. Confirm the chosen backend is mounted and `processed` increases. A loaded DLL or idle `attach rc=0` is insufficient.
7. Check motion, appearance, scene cuts, exposure and history reset; use external frame-time measurements.

The local game setup used the OptiScaler NVIDIA spoof preset to expose DLSS input. The panel can edit that preset with the game closed, retaining a backup. Compatible upscaler installation is separate; no unverified third-party signed replacement is bundled/downloaded.

The generated `game-files/plugins/nr_bridge.ini` and panel config point to the same manifest, INI and status paths in your package. If you move it, regenerate those paths before installation; an already copied INI cannot follow a moved folder.

### Use a newly built VK102 backend, alone or alongside Small

Build VK102 with `Build.ps1 -Profile vk102` and its supported full-model DLL. To boot VK102 alone, configure that package and copy its `game-files/` contents:

```powershell
python local/game-package-vk102/panel/configure_game.py --package local/game-package-vk102 --game-bin "C:/Games/Cyberpunk2077/bin/x64"
```

For both models, build both profiles and choose one boot package. Register the other package before installing:

```powershell
# Small boot package, with newly built VK102 available in the selector.
python local/game-package/panel/configure_game.py --package local/game-package --game-bin "C:/Games/Cyberpunk2077/bin/x64" --vk102-manifest local/game-package-vk102/manifest

# Alternatively, VK102 boot package, with Small available.
python local/game-package-vk102/panel/configure_game.py --package local/game-package-vk102 --game-bin "C:/Games/Cyberpunk2077/bin/x64" --small-manifest local/game-package/manifest
```

Install only the chosen boot package's `game-files/`. Keep both packages' matching `bin/nrvk_bridge.dll`, runtime, shaders and weights together. The selector switches at a frame boundary and resets history, preserving appearance settings. The boot key in the installed bridge INI must match the component copied from that boot package. Neither package's generated model assets belong in GitHub.

## Roll back

Close the game. Remove only these introduced files and restore any same-name backups: `plugins/CyberpunkNRBridge.asi`, `plugins/nr_bridge.ini`, `plugins/nr_hdr_proxy.hlsl`, `plugins/NRB-deferred-identity.enable`, `nrvk_bridge.dll`. Leave unrelated game/OptiScaler files alone. For a changed spoof preset, check and restore your intended `OptiScaler.ini.nr-backup`.

## Troubleshooting

- Unsupported DLL: use the supported local profile; the tool does not download a replacement.
- Shader mismatch: use glslang 16.5.0 and unmodified sources; retain hash/precision checks.
- Permission failure: keep the package writable. No elevation or alternate-shell bypass is used.
- Port 8788 busy: close the previous panel or set `NR_PANEL_PORT`.
- Mounted but no processed frames: check fixed input geometry, trigger file, working OptiScaler route and bridge log.
