# Implementation boundary

This packages the existing Small game backend, preserving network mathematics, grids, bindings, push constants, half-rounding, history copies and the Vulkan feature/synchronization contract.

Publication changes:

1. Local DLL extraction and B580 packing replace developer asset paths.
2. All 40 deployed network shaders have source recipes. Exact raw compiler hashes bind precision-decoration maps; final hashes bind the result.
3. Developer image files are replaced with the existing zero-initialized buffer path. Game gather, controls, history and procedural noise supply runtime inputs.
4. Paths are manifest-relative. Frozen hash includes and component-reported identity are generated from the user's actual assets.
5. `nr_bridge.ini` supplies shared panel INI/state paths alongside manifest/status paths.
6. The prep-list bisect file is removed from the published path; normal complete preparation is always recorded.
7. Panel port is 8788, POSTs require the existing token, and write errors are reported without alternate-shell bypass. The panel never handles weights.
8. CPU checks retain ABI, queue/history, hooks, HDR shader, resource lease and handoff checks. Unrelated legacy Python tests are not part of this Vulkan publication; GPU probes are excluded from default builds. Existing test expectations were updated for the actual four-entry HDR shader and enabled deferred pool.

Known limits: 1280×720 input, ANSI Windows paths, B580-specific resources, Small reference differences, unverified 4K/extended stability and game acceptance of newly built portable binaries. CPU/build success does not certify picture quality or game performance.
