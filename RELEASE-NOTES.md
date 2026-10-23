# v0.1.0 Experimental

Source release of the existing Cyberpunk 2077 Vulkan NR backend and control panel for Intel Arc B580 / Windows x64.

## Included

- Extraction tools for a user-supplied **310.9.16.0 Small** `nvngx_dlssnr.dll`, verified by SHA-256.
- B580 resource packing, GLSL sources, native Vulkan/D3D12 bridge sources, and the end-to-end `tools/Build.ps1` entry point.
- Loopback control panel for enable, appearance settings and optional Small/VK102 hot switching.
- Configuration, backup and rollback instructions.

Download the **Source code (zip)** below, or clone this repository. Follow [README.md](https://github.com/gggz114514-oss/intel-dlss5nr-cyberpunk2077#readme) and [INSTALL.md](https://github.com/gggz114514-oss/intel-dlss5nr-cyberpunk2077/blob/main/INSTALL.md).

**No weights, extracted model data, compiled shaders, game captures, native binary installers or third-party DLLs are included.** Users supply their own supported local DLL and the documented development dependencies, and build locally. A compatible OptiScaler installation is required separately.

## Scope

- The included build profile produces **Small: 76 rows / 118 dispatches**. It does not build the full VK102 310.8 model or include ongoing FP16/INT8 research candidates.
- An existing VK102 package can be registered through `configure_game.py --vk102-manifest`; its own matching component, plan, shaders and weights must remain together.
- NR input is fixed at **1280 x 720**. Display resolution is separate.
- Clean extraction, shader identity, native CPU checks and panel checks passed. The user confirmed local game smoke testing after installation and restoration of the backend selector. Extended stability, all scenes/resolutions and formal image-quality acceptance remain unverified.
- Remaining Small reference differences are documented; this is an **Experimental prerelease**, with no performance or image-quality guarantee. Back up existing game files before installation.

This is a community project, not an official NVIDIA, Intel, AMD, CD Projekt Red or OptiScaler product. See LICENSES.md for source provenance and third-party notices.
