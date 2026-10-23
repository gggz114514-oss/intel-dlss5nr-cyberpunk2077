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

Use a writable ASCII path: the existing Windows bridge uses ANSI file APIs. Keep the model DLL outside the source tree. No system Python, registry or driver changes are made.

## Build

Run the main README command from the repository root with a new/empty `local/small` directory. The script stops on any extraction, shader identity, compile or CPU-check failure.

The two native targets can also be configured after asset preparation:

```powershell
cmake -S source/vulkan -B build/vulkan -A x64 -DNR_MODEL_DIR="C:/path/to/repo/local/small" -DVULKAN_INCLUDE_DIR="C:/VulkanSDK/Include"
cmake --build build/vulkan --config Release
cmake -S source/bridge -B build/bridge -A x64 -DOPTISCALER_SOURCE="C:/Dev/OptiScaler" -DNRB_XESS_IDENTITY_TEST=ON -DNRB_DEFERRED_IDENTITY_TEST=ON -DNRB_LIVE_NR_TEST=ON -DNRB_MULTI_ROUTE_LIVE=ON -DNRB_TAIL_ORDER_PROBE=ON
cmake --build build/bridge --config Release
```

Historical `*_TEST` switches select the existing experimental game path. One-frame readback and developer GPU probes are disabled in the default build. The separate legacy Python/Triton runtime is not part of this publication.

`local/game-package/` contains generated runtime assets, your locally built bridge, D3D12 proxy shader source, panel and configuration. Raw extraction/debug outputs are not copied into it.

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
6. Confirm mounted Small and increasing `processed`. A loaded DLL or idle `attach rc=0` is insufficient.
7. Check motion, appearance, scene cuts, exposure and history reset; use external frame-time measurements.

The local game setup used the OptiScaler NVIDIA spoof preset to expose DLSS input. The panel can edit that preset with the game closed, retaining a backup. Compatible upscaler installation is separate; no unverified third-party signed replacement is bundled/downloaded.

The generated `game-files/plugins/nr_bridge.ini` and panel config point to the same manifest, INI and status paths in your package. If you move it, regenerate those paths before installation; an already copied INI cannot follow a moved folder.

### Keep an existing VK102 backend

The panel also supports Small/VK102 hot switching. To retain an existing VK102 310.8 package, register its manifest directory:

```powershell
python local/game-package/panel/configure_game.py --package local/game-package --game-bin "C:/Games/Cyberpunk2077/bin/x64" --vk102-manifest "C:/NR/VK102/manifest"
```

Keep that package's matching `bin/nrvk_bridge.dll` (or `nrvk_bridge.dll` at its root), runtime, shaders and weights together. The panel then shows **VK102 310.8** alongside Small; select it and Save. The bridge switches at a frame boundary and resets history. Existing appearance settings are retained. Registering VK102 does not replace the Small component in the game folder.

The extraction/build profile in this source release currently builds Small only. This option connects an already built VK102 package; it does not extract a full 310.8 model from the Small DLL. Neither package's generated model assets belong in GitHub.

## Roll back

Close the game. Remove only these introduced files and restore any same-name backups: `plugins/CyberpunkNRBridge.asi`, `plugins/nr_bridge.ini`, `plugins/nr_hdr_proxy.hlsl`, `plugins/NRB-deferred-identity.enable`, `nrvk_bridge.dll`. Leave unrelated game/OptiScaler files alone. For a changed spoof preset, check and restore your intended `OptiScaler.ini.nr-backup`.

## Troubleshooting

- Unsupported DLL: use the supported local profile; the tool does not download a replacement.
- Shader mismatch: use glslang 16.5.0 and unmodified sources; retain hash/precision checks.
- Permission failure: keep the package writable. No elevation or alternate-shell bypass is used.
- Port 8788 busy: close the previous panel or set `NR_PANEL_PORT`.
- Mounted but no processed frames: check fixed input geometry, trigger file, working OptiScaler route and bridge log.
