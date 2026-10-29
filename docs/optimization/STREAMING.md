# 跨帧流式处理：约 5.43 ms 的实机收益

这一项属于 D3D12/Vulkan 桥接提交与退休，不是 NR 神经网络内部提速，必须与 Full/Small 内核优化分别记账。

同一游戏生命周期、同一静止 3D 场景，SYNC/LATELATCH 热切换四窗口共 1,067 帧。历史测量：帧周期约 **34.81→29.38 ms**，约 **28.74→34.04 FPS（+18.4%）**；帧间 gap 约 **14.65→9.32 ms**，减少约 **5.33 ms**；CPU tail_wait 平均约 **25.30→4.18 ms**。逐窗口记录见 `streaming-windows.json`。

实现重点是让 CPU 不必在当帧提交尾部立即等全部 GPU 工作完成：保留 GPU 队列依赖，延后回收已提交工作，在真正需要复用资源前检查退休。`source/bridge/src/deferred_identity.cpp` 默认 `g_diag_late_latch{1}`；`nr_gpu_handoff.cpp` 与 Vulkan processor 负责跨 API 交接。资源不能在消费者完成前重写，流式处理不是删掉正确性所需的 fence。

发布携带该已实装源版本及 GPU handoff/资源生命周期配套变更；诊断采集默认不运行。该批超分实际为 **FSR XMX**；旧日志字段 `d3d_deferred_sr` 或历史 XeSS 命名不代表 XeSS SR。`vk_network_266` 也是历史计时字段名，不代表当前 Full 仍有 266 派发。

约 5.43 ms 是这个场景观察到的净帧周期改善，不是对所有场景的固定保证。剩余 gap 不能仅凭差分就断言全是不可优化的游戏工作；“CPU 等待彻底归零”“GPU 气泡全部消除”“纯 GPU-bound 已被证明”不是本记录的结论。该批结果也不测量输入到显示延迟，吞吐改善与延迟应分别讨论。

不得将 5.43 ms 与其他输入、其他基线的网络增量直接相加，或从旧 Small 推算新版 Small 的游戏 FPS。本次 GitHub 发布做源码复建与 CPU 检查，不重新运行游戏。
