# Source-package verification

Verified locally on Windows x64, 2026-10-23/24, with MSVC 14.44.35207, Windows SDK 10.0.26100.0, CMake, Python 3.12 / NumPy and glslang 16.5.0.

The clean directory started with the Git source allowlist, the supported user DLL and declared external development dependencies. It had **no previous model blobs, compiled network shaders or game samples**.

| Check | Result |
|---|---|
| DLL extraction and expected tensor hashes | 255/255 |
| B580 model resources, byte hashes vs existing backend | 70/70 |
| Network shaders rebuilt from included source to frozen hash | 40/40 |
| Bridge shaders built from source | 3/3 |
| Vulkan backend/component build | PASS |
| Backend recording and native ABI CPU checks | 2/2 PASS |
| ASI build and bridge CPU checks | 11/11 PASS |
| Panel loopback, token rejection, shared INI/state roundtrip | PASS |
| Local game-package assembly | PASS |
| Relocated runtime asset hash/probe and reconfigured shared paths | PASS |

The end-to-end `Build.ps1` completed with exit 0. A final startup-path ordering change was rebuilt and reran the 11 bridge checks; package relocation/configuration was checked separately. Developer GPU probes were not dispatched. Legacy Python runtime tests do not apply to this Vulkan-only package.

These build checks made no game, stable-package, driver or global Python changes. The clean-built Small package was subsequently installed locally with a complete backup; the user reported no obvious problem. This is user smoke-test feedback, not a detailed image-quality or stability acceptance. Small reference limitations remain as described in the README.

The panel's optional Small/VK102 selection was restored and checked through loopback HTTP and INI roundtrips, including preservation of appearance settings. The existing local VK102 package passed its matching component's CPU manifest/hash self-test. The user subsequently confirmed local game smoke testing after restoration. This does not establish extended stability or formal image-quality acceptance. No GPU work was submitted by the CPU checks. The source build profile remains Small only.
