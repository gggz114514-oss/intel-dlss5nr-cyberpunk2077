# v0.2.0 Experimental — Small + VK102

> 2026-10-29 optimized update: current Full/Small build identities, streaming changes and validation are documented in [docs/optimization](docs/optimization/README.md). Older entries below describe the earlier release.


Source release for **NR + FSR XMX upscaling + XeSS Frame Generation**, Intel Arc B580 / Windows x64 / Cyberpunk 2077. FSR XMX and XeSS FG components are separate dependencies.

## New in this release

- **VK102 now builds directly from a user-supplied local 310.8.0.0 DLL. No existing VK102 package is needed.** Complete extraction of 599 tensors, B580 packing of 150 model resources, source compilation of 40 network shaders, native bridge build and game-package assembly.
- Small retains its complete local 310.9.16.0 DLL workflow. Select `Build.ps1 -Profile small` or `-Profile vk102`; each package can boot alone, or register the other for panel switching.
- Detailed [English instructions](https://github.com/gggz114514-oss/intel-dlss5nr-cyberpunk2077/blob/main/README.md) and [中文说明](https://github.com/gggz114514-oss/intel-dlss5nr-cyberpunk2077/blob/main/README.zh-CN.md), including model hashes, build, installation, controls and rollback.
- Seven original user-provided game screenshots: NR disabled, VK102 and Small in Classic / Natural / Cinematic styles.
- Reported 720p NR-input performance: **VK102 approximately 24 base FPS; Small approximately 34 base FPS, before XeSS frame generation**. Screenshot instants vary. These are user observations, not a benchmark guarantee.

Download **Source code (zip)** below, or clone the repository. Follow the README and [INSTALL.md](https://github.com/gggz114514-oss/intel-dlss5nr-cyberpunk2077/blob/main/INSTALL.md).

## Validation and scope

Both profiles were built in separate clean directories using only the source allowlist, their supported local DLL and declared developer dependencies. Extraction, frozen resource/shader hashes, native CPU checks, panel checks and package assembly passed. The installed earlier baseline received user smoke testing; new source-build checks do not replace extended game acceptance. See [BUILD-VERIFICATION.md](https://github.com/gggz114514-oss/intel-dlss5nr-cyberpunk2077/blob/main/BUILD-VERIFICATION.md).

- NR input remains **1280×720**. Display resolution is separate.
- Small: **76 rows / 118 dispatches**. VK102: **152 rows / 266 dispatches**. Ongoing 232-pass FP16 / INT8 research candidates are excluded.
- No model weights, extracted tensors, compiled shaders, native installers, local runtime fixtures or third-party DLLs are included. Only the seven authorized documentation screenshots are published.
- This is an **Experimental prerelease**. Small reference differences, all-scene quality, extended stability and arbitrary display modes are not certified. Back up your game environment before installation.

This is a community project, not an official NVIDIA, Intel, AMD, CD Projekt Red or OptiScaler product. See LICENSES.md for source provenance and third-party notices.
