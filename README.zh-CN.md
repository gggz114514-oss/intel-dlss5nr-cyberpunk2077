# Intel DLSS5 NR — 赛博朋克 2077

[English](README.md) · [开发依赖和安装说明（英文）](INSTALL.md)

本项目在 **Intel Arc B580 / Windows x64** 上提供 Vulkan NR 后端、游戏桥、DLL 模型提取与构建工具、控制面板。实机使用的组合是：

**NR + FSR XMX 超分辨率 + XeSS 帧生成。**

NR 负责神经图像处理与风格控制；FSR XMX 负责超分；XeSS FG / XeFG 负责帧生成。这里不是把 XeSS 超分叫作帧生成，也不是宣称整套 NVIDIA DLSS 功能都在本仓库内。OptiScaler 负责相应路由，超分和帧生成的第三方组件由用户另行准备。

## 两种模型都能从本地 DLL 开始构建

**不再要求用户已经拥有 VK102 包。** 只需提供对应版本的本地 `nvngx_dlssnr.dll` 作为模型输入，再准备下文列出的开发依赖。提取器把 DLL 当数据解析，不加载或执行 DLL。

| 参数 | 模型 | DLL 内资源 | 固定网络 | DLL SHA-256 |
|---|---|---|---|---|
| `-Profile small` | 310.9.16.0 Small | `WEIGHTS_CC_SMALL_FP8` | 76 行 / 118 发 | `2bc19bc09a7b89dd44f73e2ac0108fcc586e2154bdd0830f242f4f040e28789f` |
| `-Profile vk102` | 310.8.0.0 完整模型 | `WEIGHTS_HT` | 152 行 / 266 发 | `8270b350cd82de5ce89806872cdd6b6a9249b80836b91bbeb3573470744cc206` |

两个 DLL 请分别放在不同目录。身份不匹配的版本会被拒绝；也支持包含一个对应 DLL 的 ZIP。这里发布的是现有游戏基线，不包括进行中的 232 发 FP16 或 INT8 研究候选。

仓库不提供模型 DLL、权重、提取后的张量、预编译 SPIR-V、自有二进制安装包或第三方游戏 DLL。所有模型资产和本机二进制均由用户在本地生成。

## 720p 实机性能怎么理解

测试组合：**NR + FSR XMX + XeSS FG**，显卡 B580。用户确认以下数字是 **XeSS 帧生成之前的基础渲染 FPS**：

| NR 后端 | NR 输入分辨率 | 近似基础帧率 |
|---|---|---:|
| VK102 | 1280×720 / 720p | **约 24 FPS** |
| Small | 1280×720 / 720p | **约 34 FPS** |

这是用户本机的观察值，不是跨场景统一基准或帧率保证。本页 Small 截图的瞬时基础帧率约为 30–32 FPS；截图中的约 93–94 / 126–127 FPS 是另外的插帧后呈现读数，不能拿来与基础 FPS 混算。

**720p 指 NR 输入，不等于显示输出。** 当前模型输入固定 1280×720。已有本机 1080p / 1440p 显示输出记录，不代表可以随意修改模型输入尺寸或派发网格。

面板 `total`、`tail` 等数值是桥内区间，包含跨帧重叠等待，不能当成游戏帧时，也不能当成纯后端网络耗时。

## 准备开发依赖

- Windows x64、B580 与满足 Vulkan 功能合同的驱动。
- Python 3.12+，在独立虚拟环境安装 NumPy。
- Visual Studio 2022 C++ Build Tools、Windows SDK、CMake 3.24+。
- **glslang 16.5.0**，不能随意更换编译器版本绕过着色器身份检查。
- Vulkan headers：传入的是含有 `vulkan/vulkan.h` 的 `Include` 或 `include` 目录。
- 与当前桥适配的 OptiScaler 源码依赖，固定提交与所需头文件/Detours 库见 [INSTALL.md](INSTALL.md)。

推荐把项目放在较短、可写的英文路径，例如 `C:\Dev\intel-dlss5nr-cyberpunk2077`。现有原生文件接口仍受 Windows 路径长度限制；不要使用过深目录或中文路径。模型 DLL 放在仓库外。

## 一次构建 Small 或 VK102

在仓库根目录执行：

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-model.txt

# 按自己的开发工具安装位置填写。
$py = ".\.venv\Scripts\python.exe"
$opti = "C:\Dev\OptiScaler"
$glslang = "C:\Tools\glslang\bin\glslang.exe"
$vk = "C:\VulkanSDK\Include"

# Small：生成 local/small 与 local/game-package。
.\tools\Build.ps1 -Profile small -Dll "C:\Models\Small\nvngx_dlssnr.dll" `
  -OptiScalerSource $opti -Glslang $glslang -VulkanInclude $vk -Python $py

# VK102：生成 local/vk102 与 local/game-package-vk102。
.\tools\Build.ps1 -Profile vk102 -Dll "C:\Models\VK102\nvngx_dlssnr.dll" `
  -OptiScalerSource $opti -Glslang $glslang -VulkanInclude $vk -Python $py
```

只用一种模型就只执行对应命令；希望在面板中切换则两种都构建。入口会依次完成：DLL 身份检查 → 解包及张量哈希检查 → B580 冷权重重排 → 网络/桥着色器编译及身份检查 → 原生 DLL/ASI 构建 → CPU 检查 → 游戏包装配。

**不会自动安装或启动游戏。** 模型和包输出目录应为新目录或空目录；再次构建可用 `-Output`、`-PackageOutput` 指定另一个位置，不必覆盖已经在使用的包。

VK102 完整链包括 **599 个原始张量文件、150 个模型冷资源、40 个网络着色器**，不需要旧权重文件或本机输入样本。每个包均包含自己的 `manifest/`、`assets/`、`bin/nrvk_bridge.dll`、`game-files/`、`panel/` 和 `config/`，应整体保留。

## 配置和安装进游戏

先正常退出游戏，保留你已经可用的 OptiScaler、FSR XMX 和 XeSS FG 组件。备份游戏 `bin/x64` 中将被替换的文件及配置；不要删除无关文件。

**只用 Small：**

```powershell
python local/game-package/panel/configure_game.py --package local/game-package --game-bin "C:/Games/Cyberpunk2077/bin/x64"
```

**只用从 DLL 新构建的 VK102：**

```powershell
python local/game-package-vk102/panel/configure_game.py --package local/game-package-vk102 --game-bin "C:/Games/Cyberpunk2077/bin/x64"
```

**两种都用，以 Small 为启动模型：**

```powershell
python local/game-package/panel/configure_game.py --package local/game-package --game-bin "C:/Games/Cyberpunk2077/bin/x64" --vk102-manifest local/game-package-vk102/manifest
```

随后把选定启动包的 **`game-files/` 内部内容**复制到游戏 `bin/x64/`。不要把两个启动包的文件相互覆盖。如果以 VK102 启动，可反过来在 VK102 包中使用 `--small-manifest local/game-package/manifest` 注册新构建的 Small。

配置命令只修改包内路径，不修改游戏文件，不安装超分或帧生成 DLL，并保留已有 NR 风格参数。若移动包目录，需重新配置，再把生成的 `plugins/nr_bridge.ini` 复制到游戏中。

## 面板操作

运行选定启动包中的 `Launch-NR-Panel-Game.cmd`。默认地址 **http://127.0.0.1:8788/**；可通过 `NR_PANEL_PORT` 改端口。本页截图使用 8789，因为当时另一个面板占用了默认端口。

- **后端**：只显示已注册的模型。选 Small 或 VK102 后保存；桥会在帧边界切换，重置 history，并加载对应包自己的组件和权重。
- **启用、经典/自然/电影、强度、局部结构、局部色调、皮肤/遮罩、自动遮罩、风格强度**：逐帧控制，不会重新构建模型。
- **实况**：检查“已挂载”与持续增长的处理计数。单纯 DLL 加载成功不足以说明正在出帧。
- **切镜和重置**：自行检查加载存档、转动镜头、曝光变化、切场景后的画面恢复。
- **OptiScaler 伪装预设**：退出游戏后修改，并在重启游戏后生效。面板会保留 INI 备份，不提权或改系统环境。

本机组合中，OptiScaler 的 FSR 路由为 `Dx12Upscaler=fsr31`，帧生成接入为 `FGInput=DLSSG`、输出为 `FGOutput=XeFG`。`fsr31` 这个路由名并不自动证明任意 FSR DLL 都使用 XMX；仍需另行安装兼容的 FSR XMX 实现。这里不提供或自动替换这些第三方 DLL。

## 实机效果图

以下均为用户提供的完整原图，未修图。原生对照标注为 **NR 关闭**，不表示同时关闭了超分与帧生成。各图面板保留了后端、启用状态和风格；镜头、人物姿态和光照略有变化，因此是效果展示，不是逐像素对齐的画质 A/B。

### 原生画面／NR 关闭

![原生画面，NR关闭](docs/images/nr-off.png)

### VK102 与 Small 的三种风格

| 风格 | VK102 310.8 | Small 310.9.16 |
|---|---|---|
| 经典 | <img src="docs/images/vk102-classic.png" width="480" alt="VK102经典"> | <img src="docs/images/small-classic.png" width="480" alt="Small经典"> |
| 自然 | <img src="docs/images/vk102-natural.png" width="480" alt="VK102自然"> | <img src="docs/images/small-natural.png" width="480" alt="Small自然"> |
| 电影 | <img src="docs/images/vk102-cinematic.png" width="480" alt="VK102电影"> | <img src="docs/images/small-cinematic.png" width="480" alt="Small电影"> |

点击图片可查看原始分辨率。这里只公开用户明确提供的说明截图，不打包模型输入/输出 dump、本机测试样本或游戏运行日志。

## 回滚与实验版范围

正常退出游戏，恢复备份的 `nrvk_bridge.dll`、`plugins/CyberpunkNRBridge.asi`、`plugins/nr_hdr_proxy.hlsl`、`plugins/nr_bridge.ini`、`plugins/NRB-deferred-identity.enable`。只移除本次新增的文件；若改过伪装设置，恢复对应 OptiScaler INI 备份。不要处理无关的游戏文件。

本发布为 **Experimental**。本机用户初测和资产逐字节重建不等于长稳、所有场景画质、4K 或 Small 对参考逐位一致已验收。`local/`、`build/` 中生成的权重、DLL、SPV 等应留在用户本地，不提交到仓库。

构建验证记录见 [BUILD-VERIFICATION.md](BUILD-VERIFICATION.md)。着色器先检查编译器原始输出，再恢复冻结的 `NoContraction` 装饰并核对最终哈希；脚本没有内嵌预编译 SPIR-V。

模型工具及参考来自 [DLSSNR-AMD](https://github.com/mochizuki0323/DLSSNR-AMD)。许可证和来源见 [LICENSES.md](LICENSES.md)、[PORTING.md](PORTING.md)。本项目不是 NVIDIA、Intel、AMD、CD Projekt Red 或 OptiScaler 的官方产品。
