# 换电脑后的项目恢复手册

恢复分为两部分：**公开 GitHub 保存代码与研究方法；私人存储保存模型、场景输入和原始结果。** 当前已上传的内容可以恢复 FP16 构建和实验工具；私人数据由用户另建存储后备份。

## GitHub 保存什么

| 内容 | 位置 |
|---|---|
| 当前 Full / Small 源码与模型配方 | source/network-fp16-20261027、source/network-small-20261028、tools |
| 游戏桥、流式交接、控制面板 | source/bridge、source/vulkan、panel |
| 可直接使用的实验工具与说明 | tools/experiments |
| 优化历程、最终收益与验证摘要 | docs/optimization |
| 历史研究源码、候选、计划、任务与报告 | source/research-archive |
| 档案文件身份与原始位置 | source/research-archive/INDEX.json |

档案保留 5,699 个研究文件，以 5,013 个内容寻址对象去重存储；INDEX 将每个对象映射回原目录。研究档案覆盖主审计工作目录、DSH INT8 实施与细量化、XMX 验证包、zcode 诊断目录及早期报告。每个文件保留原始 SHA256 和发布版 SHA256。路径匿名化之后发布字节不同，原始身份用于与私人备份核对。

历史 Python/PowerShell 以 `.py.txt` / `.ps1.txt` 保存，防止误点执行挂载、清理或 GPU 脚本。它们是历史实现档案，不参与默认构建，也不自动成为当前采纳版本。当前版本以 tools/model_profiles.json 及源码构建配方为准。

## 恢复步骤

1. 从 main 克隆仓库，保存当前 commit ID。
2. 安装 INSTALL.md 所列构建依赖；安装实验 Python requirements。
3. 从私人存储恢复合法模型 DLL，先构建 Full，再构建 Small。
4. 按 USER-GUIDE 配置实际游戏路径，保留原游戏文件备份，安装选定启动包。
5. 如需继续实验，构建各模型独立的 port_network_model_runner，先执行 CPU plan check。
6. 恢复采集输入、历史、输出、原始计时回执和候选权重，按 SHA256 清单核对。
7. 展开历史研究档案，将占位符指向新电脑路径；只执行本次选定任务，历史挂载/清理脚本先人工核对。
8. GPU 任务统一使用一个锁文件，先重建固定输入参考，再做候选数值门、反馈和计时。

## 展开研究档案

在本地创建 `local/recovery-paths.json`，不要提交个人路径配置：

```json
{
  "@NR_WORKSPACE@": "C:/NR/research",
  "@NR_GPU_WORKSPACE@": "C:/NR/gpu",
  "@NR_GAME@": "C:/Games/Cyberpunk2077",
  "@NR_USER_HOME@": "C:/NR/private-home-restore",
  "@NR_AGENT_DATA@": "C:/NR/agent-data",
  "@NR_LEGACY_WORKSPACE@": "C:/NR/legacy"
}
```

```powershell
python tools/experiments/restore_research.py `
  --paths local/recovery-paths.json --out C:/NR/research
```

输出目录必须尚不存在。工具检查档案哈希，恢复原文件相对路径和脚本扩展名，替换已登记的根路径，不执行任何恢复出的脚本。历史脚本中的其他工具安装路径、外部模型/捕获文件按其任务说明重新配置；INDEX 记录明确排除了生成目录与未纳入的记录。

## 私人存储必须保存的内容

| 优先级 | 数据 | 原因 |
|---|---|---|
| P0 | 原研究工作区完整快照（src、candidates、work、reports 及关联外部路径） | 补齐公开档案范围外的历史依赖与原始文件 |
| P0 | 支持版本的 Full / Small 模型 DLL | 从源码重新构建模型所需 |
| P0 | 正式 24 帧采集的原始 pre/post 输入、实际 PUSH、noise seed、输出和元数据 | 重放同一实验与恢复颜色误差定位 |
| P0 | 采集时的 source plan 及全部关联权重、shader、历史状态 | 采集身份必须与回放资源配套 |
| P0 | 当前已采纳 Full/Small 游戏包与实际游戏桥、配置、回滚备份 | 快速恢复已运行环境 |
| P1 | INT8 标定数据、尺度、重排权重、候选计划和完整结果 | 接续细量化工作 |
| P1 | ordinary 原始回执、逐帧哈希、native/计数器原始捕获 | 重新计算和复查历史结果 |
| P1 | GPU 驱动版本、编译器安装包/版本、GTPin 版本、外部依赖提交号 | 重建实验环境 |
| P2 | 游戏存档与采集场景说明 | 人工实机对比复现 |

模型和游戏文件遵守各自分发许可；密钥、登录凭证不进入公共仓库。

## 建立私人备份清单

先将需要保存的数据整理到私人备份目录，再生成清单：

```powershell
python tools/experiments/inventory_private.py `
  --root C:/NR/private-backup --out C:/NR/private-backup-index.json
```

此工具仅扫描并生成 SHA256，不上传、不复制数据。将数据目录与清单一起备份到用户选定的私人存储，完成后下载一份到新目录重新生成清单并比较路径、大小和哈希。私人存储尚未建立时，原始数据仍只存在本机；公开源码备份不能代替这一步。

## 研究档案的取舍

保留自己的研究源码、候选 shader、计划、关键状态及文档。依赖虚拟环境、厂商工具二进制、编译产物、模型数据、游戏帧、原始 run/evidence 目录不进入公开档案。构建生成物从源码复建，实验原始数据走私人备份。未选中的大文本及路径项在 INDEX 中列明，便于私人备份补齐。
