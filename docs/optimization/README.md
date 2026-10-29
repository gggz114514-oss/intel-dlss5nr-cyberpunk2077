# FP16 优化记录 / FP16 optimization record

截至 2026-10-29，本目录记录已采纳的 Full、最新 Small 和跨帧流式桥接成果。源码发布包含真实 shader、固定编译配方、权重布局变换和执行计划，未上传模型权重、DLL、SPIR-V、游戏截图或诊断采集帧。

**重要致谢：当前 Vulkan 后端大量参考了望月（mochizuki0323）的 [DLSSNR-AMD](https://github.com/mochizuki0323/DLSSNR-AMD) 社区项目。** 参考不仅是模型工具，也包括网络组织、矩阵生产消费、布局与融合思路。Intel XMX 的 lane/fragment 映射、供料调度及生命周期需按本机重新实现和验证，不能把 AMD FP8 的实现或收益直接当作 Intel FP16 的结果。该项目不是 AMD 官方 SDK。见 [来源与边界](AMD-ATTRIBUTION.md) 和仓库 MIT 许可。

## 当前版本

| 入口 | 发布源码 | 规模 | 历史实测口径 |
|---|---|---|---|
| `-Profile vk102`（Full） | `source/network-fp16-20261027` | 152 行、502 buffers、232 派发、39 shader | handoff 18.724 → 17.450 ms，同批节省 1.273430 ms |
| `-Profile small`（新版） | `source/network-small-20261028` | 76 行、222 buffers、108 派发、39 shader | 修正范围的旧 Small 14.324 → 9.980 ms，同批固定输入 |
| 流式桥接 | `source/bridge` + `source/vulkan` | late-latch 默认启用 | 实机帧周期约 34.81 → 29.38 ms，节省约 5.43 ms |

**Small 就是新的约 9 ms 版本，不是旧 118 派发版本。** 两个旧源码目录仍保留作为历史来源和少量共用模块；当前 profile 均指向新目录。Small 不是 Full 权重直接减半：保留自身模型权重、五个偏移专用核、范围修正和新的计划接线。

Full 原研究计划 SHA256：`bc34404c00a52a02b5be77cbb167e71cb3965536f634ecd1bed663c002e45df6`。
Small 原研究计划 SHA256：`cf1d1fac922c33e31793a4a1c828364577c40fb26bef8ff5a6b6a23c5cdaf80b`。
发布计划去除开发机绝对路径和两份图像 fixture，因此计划文件哈希改变；shader、权重、PUSH、绑定、网格、POLICY、HISTORY 分别核对，不能拿新路径哈希冒充原文件哈希。

## 如何阅读

- [优化方法与过程](METHODS.md)：删交接、保留并行、控制寿命及失败后如何追查实现。
- [逐步收益](ACCEPTED-STEPS.md)：13 步采纳、Full 直接组合验证；单点收益不可相加。
- [流式桥接](STREAMING.md)：约 5.43 ms 的来源，与神经网络内部优化分开记账。
- [构建与验证](BUILD-AND-VALIDATION.md)：重建精度约束、Small 特殊资源、验证范围。
- `full-confirm6.json`、`small-timing.json`、`streaming-windows.json`：各自批次的原始汇总数据。

网络时间不是游戏帧周期；固定输入不是连续反馈。Small 对修正后的父计划过门，但与旧版短 descriptor range 的输出不等价；历史长反馈异常不在这里改写成已修复。当前发布没有重新运行 GPU 或游戏，不把 CPU 构建检查写成新 GPU 验收。

## English summary

The default profiles now select the accepted 232-dispatch Full and **108-dispatch optimized Small**, not the legacy 118-dispatch Small. The current Vulkan implementation substantially references **mochizuki0323 / DLSSNR-AMD**, a community MIT project, including network organization and producer/consumer design. Credit is not limited to model extraction tools.

The Full campaign's direct paired gain is 1.273430 ms (95% CI 1.251966–1.294894). Optimized Small measured 9.980 ms in its fixed-input batch. Separately, game late-latch streaming improved frame period by approximately 5.43 ms. These different experiments must not be added together. Build reproduction and historical GPU acceptance are distinct; see the linked records for exact boundaries.
