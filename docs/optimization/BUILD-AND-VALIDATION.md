# 构建与验证

继续使用根目录 `tools/Build.ps1`。`vk102` 现指向优化 Full 232 派发；`small` 指向新版 Small 108 派发。模型 DLL 身份保持原有要求。

先构建 Full，再构建 Small 时增加 `-FullModel <Full模型输出目录>`（例如 `local/vk102`，不是 game-package 目录）。这个依赖用于复现实机 Small 沿用 Full 的末端 blend scalar；其余权重仍从 Small DLL 提取。此项是已有实机版本身份，不宣称是重新校准后的 Small 模型数学。不要默默替换成旧 Small scalar。

`weight-transforms.json` 的 offset/count 单位为 half 元素。变换只重排 uint16，保持位值；每条变换检查输入与输出 SHA256，最后逐个核对 cold 资源清单。Full 165、Small 70 个 cold 资源；两版各 39 个网络 shader。五个 Small 偏移核中三份随新源码发布，另外两份复用仓库已有、相同身份的 Small 专用源配方。

`recipes.json` 绑定 glslang 16.5.0 原始编译哈希，再恢复已采纳 NoContraction 装饰并验证最终哈希。所有 shader 必须与已采纳二进制相同，不能仅以编译成功替代。构建目录和模型权重只存在本地，不上传。

本次验证记录见 `publication-validation.json`。历史 GPU 门：Full fixed 与双帧反馈位一致；Small fixed / 短反馈与修正 descriptor range 的父臂一致，旧短范围父臂不作为等价参考。历史长反馈问题与游戏人工观察分别保留，不把固定输入验证泛化为所有序列稳定。

本次只发布和做 CPU 构建/计划/ABI 检查，没有新 GPU 计时、没有重新部署到游戏。历史帧/模型数据不公开，因而外部不能仅用本仓库复现原 fixture 哈希；可用自己的合法模型与输入执行独立验证。
