# Local assets

The only model input is the supported local `nvngx_dlssnr.dll` or its ZIP. Extraction parses PE resources without executing the DLL.

```powershell
python tools/extract_model.py --dll "C:/Models/nvngx_dlssnr.dll" --out local/small
python tools/build_assets.py --model local/small --glslang "C:/Tools/glslang/bin/glslang.exe"
```

The first command checks **255** tensor SHA-256 hashes, packs NRMODEL1 and generates **70** FP16/FP32 model cold resources. NumPy is needed for B580 packing. `--raw-only` performs standard-library extraction only, not backend preparation.

The second builds **40** network modules and three bridge shaders from GLSL, restores/verifies the frozen precision identity, writes the 118-dispatch plan, and generates C++ build identity includes. Asset paths are relative to the manifest. The built backend checks the manifest, plan and every model/shader file before mounting.

Two old image bundles were developer fixtures, not weights, and are absent. The runtime initializes their buffers to zero, then game gather/controls/history provide frame data. The first pass selects procedural noise from the current frame seed. No developer screenshot, captured activation or pre-exported blob is needed.

`Build.ps1` runs both steps. `local/`, `assets/`, `models/`, `weights/` and `build/` are ignored. Generated weights, SPIR-V, CUDA code and proprietary binaries are not repository contents and are not covered by the source license.
