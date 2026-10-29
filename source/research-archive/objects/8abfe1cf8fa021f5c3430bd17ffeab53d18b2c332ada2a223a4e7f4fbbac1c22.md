# n08-f08-wg-map — ANALYSIS（六问）

卡：F08 分组 FFN（16 PASS：ordinal 60,64,68,72,76,80,84,88,134,138,142,146,150,154,158,162；plan row 23,27,31,35,39,43,47,51,97,101,105,109,113,117,121,125）
状态：BUILT / AWAITING-GPU（本卡禁止 GPU，未取锁，未部署，未做任何 Vulkan 任务）

## 0. 身份与唯一变量

| 项 | 父（现役基线内） | 候选 | 证据 |
|---|---|---|---|
| SPV | `f08-register-chain-20261027/candidate.spv` sha256 `32291c7ea61b5a17…676709491` | `cards/n08-f08-wg-map/candidate.spv` sha256 `d699bc54b62573af…985d267` | BUILD.json |
| 源码 | `f08-register-chain-20261027/candidate.comp` sha256 `46f693807b…` | 本卡 `candidate.comp`（父 + 2 行索引 + 3 行注释） | SOURCE-DIFF.patch |
| 父字节复现 | 用父源码 glslang 16.5.0 原样重编译 = 父 SPV **字节相同**（两组不同 `-I` 目录各自相同） | — | BUILD.json `parent_rebuild` |
| plan | 基线 `f10-weight-return-separation-20261027/plan.txt` sha256 `a024c3c5…b2befe` | 本卡 `plan.txt` sha256 `6dcb1e5cc897ea3b…bc1c402` | BUILD.json |
| plan 差异 | — | 仅 16 行：这 16 个 PASS 的 SPV 路径 + `66 2 1 → 33 4 1` | BUILD.json `plan.baseline_lines_changed` |
| CPU | — | `CPU_PLAN_OK 152 rows, 232 passes, 502 buffers; no Vulkan loaded` | BUILD.json `cpu_check` |
| SPIR-V 结构 | 1375 条指令 / 5656 word | 1375 条 / 5656 word，**逐序号 opcode 全同**，仅 6 处整数立即数不同 | BUILD.numerics |

**唯一变量**：同一个 `(token8 tile, group)` 工作项被装进哪个 WG。SG 的 tile（M8 × N64 × K512）、每 acc 的 K 序、算术、SLM、scratch、绑定、PUSH 全部不动；WG 总数 132→132 不变。第二候选（扩大每 SG 的 M 复用跨度）本卡**未做**。

## 1. 映射：生产者每个 (lane, component) 代表什么，消费者要什么

### 1.1 形状（从 plan 与 rows 实测，不是假设）

- 每 PASS：`PASS <row> <name> <spv> 32 2048 10 32 66 2 1` → subgroup=32，shared=2048 B，gx=66，gy=2，gz=1。
- `local_size_x=256` = 8 subgroup。token 由 `gl_WorkGroupID.x*16 + (sg%2)*8` 覆盖 → **T = 66×16 = 1056 tokens**；group 由 `gl_WorkGroupID.y*4 + sg/2` 覆盖 → **G = 2×4 = 8 groups**。
- token8 tile 数 = 1056/8 = **132**；`(tile, group)` 对数 = 132×8 = **1056 = 每 PASS 的 SG 槽数**。16 个 PASS 的 grid 完全相同（`CURRENT-232-ROWS.json` 16 行 `header_fields` 全同）。

### 1.2 生产者（每个 SG）

一个 SG 独占一个 `(τ, g)`：

- 输出：token `8τ .. 8τ+7`，channel `64g .. 64g+63`（四个 N16 acc 各 16 通道），K 共 512。
- 寄存器侧：`MC` = coopmat<f32, Subgroup, 8, 16, Accumulator> = 128 元素 / 32 lane = **4 f32 per lane per acc**，4 个 acc = 16 f32 = 64 B/lane；`MA` 8×16 f16 = 4 half/lane，`MB` 16×16 f16 = 8 half/lane。
  lane→(row, col) 的 fragment 内部约定是 Intel DPAS 实现定义，本工作区没有可引证据，本卡**不重新推导**（列 unknown）；但候选与父在这一层完全一致：SPIR-V 每条 opcode 同序、操作数在归一化（result-id 归一 + 常量代入）后只有 6 处整数立即数不同，见 §0 与 BUILD.numerics。
- 内存侧（完全可枚举，本卡模拟核对 1056 个 SG 全覆盖）：
  元素 (token `8τ+r`, channel `64g+16t+c`)，`r∈[0,8) t∈[0,4) c∈[0,16)` →
  `gf[ tiled(8τ+r, 64g+16t, 512) + r*16 + c ]`，`tiled(token,c,C) = ((token/16)*(C/16)+c/16)*256 + (token%16)*16 + c%16`。

### 1.3 消费者

- l0 dispatch 内部**没有**消费者：跨 SG/WG 零依赖，写集互不相交。
- 后续 dispatch（`split16_b23_l1` 等 l1/l2/l3 与下层）读同一 `gf` 缓冲区（绑定未改、本卡未改其 grid/PUSH）。
- **关键**：候选的写集是**逐元素相同**的（同地址、同数量、同所有权），因此无论消费者用哪种布局，从 `gf` 读到的字节与父完全一致——这一点不依赖对消费者布局的假设。

### 1.4 一一覆盖证明（机器核对，PROOF.json）

| 检查 | 父 `token=x*16+(sg%2)*8; g=y*4+sg/2; grid(66,2,1)` | 候选 `token=x*32+(sg%4)*8; g=y*2+sg/4; grid(33,4,1)` |
|---|---|---|
| WG 数 | 132 | 132（delta 0） |
| SG 槽 | 1056 | 1056 |
| 唯一 (tile, group) 对 | 1056 | 1056 |
| 期望对集合 = 全部 | 是 | 是 |
| 重复分配 | 0 | 0 |
| 缺失 / 多余 | 0 / 0 | 0 / 0 |
| token 范围 | 0..1055（最大 tile 基址 1048） | 0..1055（同左） |
| group 覆盖 | 0..7 | 0..7 |
| 输出元素（half） | 540672（=1056×512），重复 0，等于全集 | 同左，且两集合**相等** |
| 尾块 | T%16=0、G%4=0 → 无尾 | T%32=0、G%2=0 → 无尾，needs_guard=false |

（540672 = 1056 token × 512 channel；两 mapping 的写集集合完全相等 = 无漏写、无重复写、无越界。）

### 1.5 WG→(token, group) 完整枚举

闭式：

- 父：`WG(x,y), x∈[0,66), y∈[0,2)` → tiles `{2x, 2x+1}`（tokens `16x .. 16x+15`），groups `{4y .. 4y+3}`；8 个 SG 中 `sg%2` 选 tile、`sg/2` 选 group。
- 候选：`WG(u,v), u∈[0,33), v∈[0,4)` → tiles `{4u .. 4u+3}`（tokens `32u .. 32u+31`），groups `{2v, 2v+1}`；8 个 SG 中 `sg%4` 选 tile、`sg/4` 选 group。

代表行（全 132+132 行枚举在 `PROOF.json:workgroup_membership`，两套各 132 条，逐条含 tiles/groups/token 首尾）：

| 父 WG | tokens | groups | 候选 WG | tokens | groups |
|---|---|---|---|---|---|
| (0,0) | 0–15 | 0,1,2,3 | (0,0) | 0–31 | 0,1 |
| (1,0) | 16–31 | 0,1,2,3 | (1,0) | 32–63 | 0,1 |
| (65,0) | 1040–1055 | 0,1,2,3 | (32,0) | 1024–1055 | 0,1 |
| (65,1) | 1040–1055 | 4,5,6,7 | (32,3) | 1024–1055 | 6,7 |

每 WG 权重命中集合（`PUSH p2 = (0, 262144, 393216)`，单位 half 元素；每 group 131072 B）：

| WG | stage1 slab（64 KiB/group） | expand（32 KiB/group） | contract（32 KiB/group） | 每 WG 去重权重字节 |
|---|---|---|---|---|
| 父 (x,0) | `[0+32768g, +32768)`，g=0..3 | `[262144+16384g, +16384)` | `[393216+16384g, +16384)` | 4×131072 = **524288** |
| 父 (x,1) | g=4..7 | 同式 | 同式 | **524288** |
| 候选 (u,0) | g=0,1 | 同式 | 同式 | 2×131072 = **262144** |
| 候选 (u,3) | g=6,7 | 同式 | 同式 | **262144** |

## 2. 删掉了什么真实工作

**零条指令。** 这一卡不删任何 send / mov / shuffle / 转换 / SLM 往返 / 屏障：

| 类别 | 本卡变化 | 依据 |
|---|---|---|
| SPIR-V 指令数 | 1375 → 1375 | BUILD.numerics |
| opcode 直方图差 | ∅（全 opcode 计数相同） | BUILD.numerics.opcode_histogram_delta = {} |
| DPAS（OpCooperativeMatrixMulAddKHR） | 21 → 21 | 同上 |
| B tile load / A tile load 条数 | 每 SG 256 / 32，不变 | PROOF.weight_request_accounting |
| SLM（shared） | 2048 B（仅 debugTile）不变 | plan 字段、父 native 2048 |
| scratch | 0，不变 | 父 native scratch0 |
| WG 屏障 | 0（父已 2→0），不变 | f08-register-chain native |
| 输出窄化/舍入点 | 不变 | 源码未动 |

真正改变的是**同一份请求量的缓存复用关系**（逻辑字节，不是 DRAM 字节）：

| 量 | 父 | 候选 |
|---|---|---|
| 每 PASS 权重请求量（逻辑） | 132 MiB（132 WG × 8 SG × 128 KiB） | 132 MiB（不变） |
| 每 PASS 去重权重字节 | 1 MiB（8×131072 B） | 1 MiB（不变） |
| 每 WG 权重请求 / 去重 = WG 内复用比 | 1 MiB / 512 KiB = **2.0** | 1 MiB / 256 KiB = **4.0** |
| 每 group slab 的 WG 回放次数 | 66 | 33 |
| 每 group slab 的 SG 请求次数 | 132 | 132（不变） |
| 每 WG 去重输入字节 / 复用比 | 16 KiB / 4.0 | 32 KiB / 2.0 |

结论只到这里：**请求量不变，单 WG 需要同时"热"的权重集从 512 KiB 降到 256 KiB，同 slab 的并发流从 2 条升到 4 条**。是否真的减少 L2/DRAM 命中损失，必须靠整体计时，不能由本表推出。

## 3. 重叠：原来怎么重叠，本卡动了哪一点

l0 的正常路径没有任何跨 SG/WG 的数据交接（无 atomics；`debugTile` 是每 SG 私有 `sg*128`，且 `pc.p5.x = 0` 关闭），所以"重叠"发生在两个层面：

**(a) 单 SG 内部三段流水**（源级顺序，编译器排程，本卡未动）：

| 值 | 生产者 | 最后消费者 | 覆盖者 | 冲突 |
|---|---|---|---|---|
| `a`（A 片段，k 步内） | `coopMatLoad` | 4 次 `coopMatMulAdd` | 下一次 k 的 load | RAW→WAR（同 SG 内，k 循环） |
| `b0,b1`（B 片段，stage1） | 2 次 load，4 段 | 2 次 MMA | 下一段 load 覆盖 | WAR |
| `r0..r3`（f32 acc，stage1） | 32 次 k 迭代 | `MH` 窄化 | — | RAW 链，K 序 0,16,…,496 |
| `h0..h3`→`a0..a3`（half A） | stage1 末 | expand 的 4 个 step | — | 长寿命（8 个 hidden 块） |
| `e0,e1`（expand acc） | 每 hidden 块 | `MH` 窄化 + `activation` | 下一 hidden 块 | RAW/WAR |
| `v0,v1`→`va,vb`（half 激活） | 窄化 + activation | contract 2 个 step | — | RAW |
| `o0..o3`（contract acc） | 8 个 hidden 块 | 末尾 `MH` + store | — | RAW 链，K 序不变 |
| `y0..y3` | store | — | — | 写域互斥 |

**(b) 跨 SG/WG**：8 个 SG 在同一 core 上并行推进同一段代码。父/候选的差别只在这里：

- 父：同一 core 上 8 条流分成 4 组 slivers（group 0..3 各 2 条），每条流 2 条 sliver 共享一个 slab；
- 候选：分成 2 组（group `2v,2v+1` 各 4 条），4 条流共享一个 slab。
- 对 A（输入）：父 2 个 tile × 4 group = 8 条流请求 2 个 tile（每 tile 4 条流）；候选 4 个 tile × 2 group（每 tile 2 条流）。
- 写域：两 mapping 都是 132×8 个互斥写域，无 WAW。

保护供料：A/B 的 load 条数、地址表达式结构、每 acc 的 K 序、阶段顺序全部不变（SPIR-V 同序），所以"删工作并保护供料"这件事本卡没有做——本卡做的是"同一份供料下的放置"，这是唯一变量的原因，也是它不能承诺收益的原因。

## 4. 新增成本（全部入账）

| 项 | 父 | 候选 | 说明 |
|---|---|---|---|
| 每 WG 去重输入字节 | 16 KiB | **32 KiB** | +16384 B/WG；总 A 请求量不变（1056 SG × 8 KiB） |
| 每 slab 同 WG 并发流 | 2 SG | **4 SG** | 4 条流若相位漂移会互相挤掉 cache line（风险，量级未知） |
| dispatch 形状 | (66,2,1) | (33,4,1) | 总 WG、总 SG、线程数、SLM、scratch 不变；y 从 2 变 4，WG→core 分配与波次边界未知 |
| 整数立即数 | 16/1/2/4 | 32/3/2/1 | 6 条指令，同长同数；不新增地址计算 |
| 重复权重读取 | 256 B-load/SG | 256 B-load/SG | 不变 |
| 重复 A 读取 | 32 A-load/SG | 32 A-load/SG | 不变 |
| 选择/复制/shuffle/同步 | — | 0 | 无数值转换、无 SLM |
| 有效 lane | 全满 | 全满 | 无尾块（1056%32=0、8%2=0），无 guard，无 idle SG |
| 活值峰值 | — | 期望不变 | 源级 live 集合完全一样；GRF 分配待 native 核对（本卡不能测） |
| 代码体积 | 5656 word | 5656 word | 不变 |

**逻辑字节 ≠ DRAM 字节**：上表全部是"被请求/需要驻留"的字节，没有任何一条声称实际 DRAM 流量下降；本卡无 cache counter（见 NATIVE-PREDICTION.md §4）。

## 5. 是否真落到 native（预测 + 判据，详细见 NATIVE-PREDICTION.md）

1. **落地判据（最硬）**：ISA 里 token 的乘法立即数应变成 32、`sg` 的 mask 变成 3/移位 2，group 的乘法立即数变成 2、`sg` 右移 2；若 native 里仍是 16/1/2/4（即 `sg&1`、`sg>>1`、`x*16`、`y*4`），则**实现未落地**（A 类）。
2. **结构判据**：指令数、基本块数、DPAS 站点数、send 站点数、mov 站点数、SLM 2048、scratch 0 应与父 native 完全一致（父 native：4669 / 219 / 132 / 534 / 1035 / 2048 / 0）。任何超出"立即数"的差异必须单独记账，不能当作预期。
3. **形状判据**：capture/派发记录里 grid 必须是 (33,4,1)，132 个 WG；若仍是 (66,2,1) 则 plan 未生效。
4. **不可观察项**：本工具集没有 cache 命中计数器（gtpin mode0 是 ISA/基本块，zprof 只给 GpuTime）。cache 局部性**不能**由 native 证明，只能由整体计时判断——本卡不写"已证明"。

## 6. 整体是否更快：测什么、用什么臂、怎么归因

- **可观测量**：整帧 ordinary 时间（不是 per-pass、不是合成屏障计时；后者有 70–100× 放大反例，且合同禁止当性能证据）。
- **臂**：`base` = 现役基线 `f10-weight-return-separation-20261027/plan.txt`（sha `a024c3c5…`）；`cand` = 本卡 `plan.txt`（sha `6dcb1e5c…`）。两臂 6 组交替、每组 30 样本、warm1、feedback；门：fixed + fb2（frame0 与 frame1 末帧）。
- **归因**：F08 l0 是 232 个 PASS 中的 16 个；候选指令流与父**零差异**，所以测到的任何差值只能来自（i）cache 局部性、（ii）WG→core 分配/波次、（iii）进程间噪声。不允许把差值归到某一条 load 或某个 send。
- **不承诺**：本卡不预测毫秒数。已接受的 F08 整链收益是 19.15 ms 上的 0.0884 ms（0.46%），本卡不改任何工作项，合理预期**小于**该量级，且可能落在 CI 内（D）。
- **预先登记的分诊**：D（INDISTINCT，若 CI 跨 0）为主；若显著变慢 → B，最大副作用是"每 WG 输入足迹 2×+ 同 slab 4 条流相位漂移"；A 已用 SPIR-V 证据排除（6 处立即数 + grid 变更）；E 不适用（写集/算术/K 序不变，gold 门只用来抓驱动/JIT 意外）。C 需整体实测后才能判。

## 7. 未决项（写进 RESUME，不等主代理）

1. lane→(row,col) fragment 内部约定未在本工作区找到可引证据（列为 unknown），但候选/父在该层一致，故不影响本卡结论。
2. B580 每 Xe core cache 容量与权重命中率未知；"WG 的 8 个 SG 同 core"只由每 WG 2048 B workgroup memory 的分配语义推出，未实测。
3. 并发 WG 数未知 → 33 个 WG 的 y 切片能否把并发权重足迹压在 2 个 slab 内，未知。
4. 第二候选（每 SG M 复用跨度）本卡未做，见 RESUME 的下一处改动。

## 8. 停止条件对照（CARD.txt）

| 停止条件 | 本卡状态 |
|---|---|
| 数学/映射不能满足合同 | 未触发：bijection + 写集相等 + SPIR-V 同序（仅整数立即数） |
| 新增溢出无法消除 | 未触发：scratch 0，SLM 2048 不变，寄存器 live 集不变（无新增值） |
| 候选整体已测负收益 | 不能判（本卡禁止 GPU）→ GPU-REQUEST.json |
| 当前工具不能回答具名问题 | 部分：cache 命中率不能回答（已写 unknown，不用它支撑收益） |
