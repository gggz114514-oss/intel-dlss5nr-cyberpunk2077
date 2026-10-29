# Current source-build verification — 2026-10-29

| Check | Full | Optimized Small |
|---|---:|---:|
| Runtime rows / buffers / dispatches | 152 / 502 / 232 | 76 / 222 / 108 |
| Network shaders rebuilt to accepted byte hashes | 39/39 | 39/39 |
| Cold resources matched to accepted game assets | 165/165 | 70/70 |
| Backend CPU checks | 2/2 PASS | 2/2 PASS |
| Bridge CPU checks | 11/11 PASS | shared bridge |
| Panel/configuration checks | PASS | PASS |
| PowerShell syntax and publication checks | PASS | PASS |

The plans reproduce bindings, PUSH values, dispatch grids, POLICY and HISTORY from the accepted packages after path normalization. Weight transforms preserve uint16 bits and validate input/output hashes. Shader recipes use glslang 16.5.0, restore the accepted NoContraction decorations and validate final SPIR-V hashes.

Small keeps its five offset-specific kernels and its own weights. Build Full first: Small reads the shared final blend scalar from that output to reproduce the accepted game package.

[Current build details](docs/optimization/BUILD-AND-VALIDATION.md) · [Recorded GPU results](docs/optimization/README.md) · [Earlier source-build record](docs/optimization/BUILD-VERIFICATION-20261024.md)
