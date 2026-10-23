param(
    [Parameter(Mandatory=$true)][string]$Dll,
    [Parameter(Mandatory=$true)][string]$OptiScalerSource,
    [Parameter(Mandatory=$true)][string]$Glslang,
    [Parameter(Mandatory=$true)][string]$VulkanInclude,
    [string]$Python = "python",
    [string]$CMake = "cmake",
    [string]$Output = "local/small"
)
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $repoRoot
try {
    $modelPath = [IO.Path]::GetFullPath((Join-Path $repoRoot $Output))
    & $Python -B tools/extract_model.py --dll $Dll --out $modelPath
    if ($LASTEXITCODE) { throw "Model extraction failed" }
    & $Python -B tools/build_assets.py --model $modelPath --glslang $Glslang
    if ($LASTEXITCODE) { throw "Shader/plan preparation failed" }
    & $CMake -S source/vulkan -B build/vulkan -G "Visual Studio 17 2022" -A x64 "-DNR_MODEL_DIR=$modelPath" "-DVULKAN_INCLUDE_DIR=$VulkanInclude"
    if ($LASTEXITCODE) { throw "Vulkan configure failed" }
    & $CMake --build build/vulkan --config Release
    if ($LASTEXITCODE) { throw "Vulkan build failed" }
    $ctestPath = Join-Path (Split-Path -Parent (Get-Command $CMake).Source) "ctest.exe"
    & $ctestPath --test-dir build/vulkan -C Release --output-on-failure
    if ($LASTEXITCODE) { throw "Backend/component CPU tests failed" }
    & $CMake -S source/bridge -B build/bridge -G "Visual Studio 17 2022" -A x64 "-DOPTISCALER_SOURCE=$OptiScalerSource" -DNRB_XESS_IDENTITY_TEST=ON -DNRB_DEFERRED_IDENTITY_TEST=ON -DNRB_LIVE_NR_TEST=ON -DNRB_MULTI_ROUTE_LIVE=ON -DNRB_TAIL_ORDER_PROBE=ON
    if ($LASTEXITCODE) { throw "ASI configure failed" }
    & $CMake --build build/bridge --config Release
    if ($LASTEXITCODE) { throw "ASI build failed" }
    & $ctestPath --test-dir build/bridge -C Release --output-on-failure
    if ($LASTEXITCODE) { throw "Bridge CPU tests failed" }
    & $Python -B tools/test_panel.py --out build/panel-test
    if ($LASTEXITCODE) { throw "Panel test failed" }
    & $Python -B tools/assemble_package.py --model $modelPath --out local/game-package
    if ($LASTEXITCODE) { throw "Game package assembly failed" }
    Write-Host "Built local/game-package. Read INSTALL.md before copying game-files. No game files were changed."
} finally { Pop-Location }
