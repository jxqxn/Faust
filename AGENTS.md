 # AGENTS.md — 苏丹的游戏 Godot 克隆项目

 本文件是接手智能体的必读入口。每次开 session 第一件事就是读它。

 ## 项目目标

 在本仓库（`C:\Users\User\Documents\GitHub\Faust`）用 Godot 4.x 克隆 Unity 游戏《苏丹的游戏》。游戏的完整逆向产物在另一个仓库（只读语料库，不拷贝、不修改）。

 ## 语料库（事实源，只读）

 所有逆向产物在 `C:\Users\User\Documents\GitHub\Faust-local-source\_unpack\`（下文记为 `$UNPACK`）。这是只读的，本仓库不复制它。

 ## 信任层级（最重要的一条）

 同一个事实有多种来源时，可信度严格分层：

 1. `$UNPACK\engine_spec\decompiled\*.c` — Ghidra 反编译伪代码（最高，事实本身）
 2. `$UNPACK\il2cpp_dump\dump.cs` — 类定义/字段偏移/方法签名/RVA（符号，无方法体）
 3. `$UNPACK\data\config\*.json` — 游戏配置数据（数值、描述文本）
 4. `$UNPACK\engine_spec\*.md` — 人类解读和总结（最低，**仅作索引，不是事实**）

 **.md 文档是反编译结果的解读层，不是事实本身。** 它的价值是告诉你"去哪个 .c 文件第几行找这个结论"，不是让你直接信它。本项目的所有重大错误都源于把 .md 当事实信了。

 ## 三条硬规则

 ### 规则 1：任何结论必须挂可验证源指针，否则当编造

 文档里的结论要用这种格式标注，才能被信任：

 ```
 [SRC: decompiled/FuncCompare.c @ IsSatisfied (RVA 0x3fc060, dump.cs:416912)]
 ```

 接手智能体的责任：读到一条结论要落地前，用 `rg`/`Select-String` 核对指针——RVA 真在该 .c 里吗？该类真在 dump.cs 该行吗？**指针核不上 = 当编造处理，重新从 .c 推导。** 这条直接防止"自己编"——当年"骰值<属性值"那条要是必须挂具体行号，作者写的时候就被迫打开文件，一打开就穿帮。

 自封的可信度标签（如 `[反汇编坐实]`）**不再是权威信号**——它是过去失败的载体。取代它的是机器可验证的指针。

 ### 规则 2：高风险结论类强制双信号

 "高风险"是一个封闭枚举，凡属这五类的结论必须有两个独立信号才落地：

 - **比较方向**（`<` vs `>=` vs `!=`）—— 这一类害过两次
 - **边界含闭**（`[` vs `(`）
 - **off-by-one**（计数、索引、长度）
 - **正负号**
 - **是否钳零/截断**（clamp）

双信号 = 一个来自 `.c` 代码行，一个来自**另一类**证据（config 描述文本、存档样本、权重算术）。骰子方向就是教科书例子：代码给"骰值≥Y"，config 的 `desc` 写"成功率60%"，而权重 `(300+300)/1000=60%` 正好命中 `>=` 方向。两路独立命中，方向必然是 `>=`。

注意：困难档 `desc` 写"成功率33%"，但实际权重 `[150,150,150,150,200,200]` 按 5/6 两面成功计算为 40%。这是已解释的文案/实现不一致：移植结算按权重表；若复刻原 UI 文案，可保留原文案并标备注。

 config 里的"神谕"俯拾皆是（`init/1.json` 三档难度都带描述文本），所以这条强制要求的边际成本极低，可以无负担地硬性执行。

 ### 规则 3：接手功能域，先过 MANIFEST 全部文件

 `$UNPACK\engine_spec\handoff\` 下按功能域（dice/loot/counter/tag/scope-filter/save/seed…）放了 MANIFEST，穷举该域涉及的所有源文件（.c + dump.cs 类行号 + 相关 config 路径）。

 接手一个功能域前，必须把它的 MANIFEST 里列的文件全部过一遍再动手。这防止"漏看"——本项目曾把"金骰子机制"标成开放项，但完整反编译代码一直躺在 `PlayerExtensions.c` / `RiteResultDiceCountPromptController.c` 里，没人读。"不在 MANIFEST 里"不等于"不存在"，但 MANIFEST 是该域的强制起点集。

 ## 真实未知项的处理：双轨制（不要一刀切）

 **信号冲突 → 必须停止，禁止默认。** 当两个信号对不上（代码说 `<`，config 只支持 `>=`），这是即将重蹈骰子覆辙的信号本身。绝不默认、绝不继续，停下来把冲突摆出来。标记为 `[CONFLICT]`。联调原游戏前不许动。

**真实运行时未知、无神谕可验 → 保守默认 + 标记 + 继续。** 纯运行时机制（如精确动画时序），确实查不到硬证据时：选保守默认值、标 `[RUNTIME_OPEN]`、继续推进。一刀切"总是停"会让移植在每个运行时未知上死锁。到了能联调原游戏对照数值时，`RUNTIME_OPEN` 可逐个用真实存档/实机数据升格为坐实。

 两种标记都要有类型、可检索（`rg RUNTIME_OPEN` 能找到全部开放项），不能只是散文 TODO。

 ## 结论索引的演化史规则

 `$UNPACK\engine_spec\handoff\verified-conclusions.md` 是已验证结论的索引。每条带 `[SRC]` 指针 + 交叉验证信号。

 **被推翻过的结论保留修订历史**（紧凑格式，v1错→v2错→v3对）。IsSatisfied 这种"改过三次"的条目，保留历史能让接手智能体天然警觉、更愿意亲自复核——"反复修订过"本身就是高风险信号。从未被推翻的结论保留干净的最终结论即可，不增加噪音。

 ## 导航工具（加速器，不是守门人）

 `$UNPACK\engine_spec\` 下有现成的 JS 工具：`show_func.js`（按方法名找 .c 函数）、`trace_addr.js`（RVA→符号）、`count_funcs.js`。用 `node` 跑。它们是半成品，文档在 handoff 里会补。

 **关键：这些工具永远只是加速器，绝不变成守门人。** 即使脚本全没了、没装，靠 `rg`/`Select-String`/`cat` 加本文件里写死的路径，照样能完成 SRC 核对、双信号交叉、MANIFEST 过文件。工具失效/报错时降级到裸 `rg`，不要卡住。脚本能做的事不要升级成 MCP server——新增失效面正是当年"指向不存在引擎的 skill"失败的原因。

 对称规则：**工具说 FuncCompare 在某 .c，就 `cat` 一眼确认**——把"不信解读层"的原则同样施加在工具身上。

 ## 已接受的降级方案

- Live2D 贴图/物理/motion 运行时绑定：静态提取已穷尽；Godot 克隆阶段明确采用静态图替代，不再作为阻塞项。后续若要恢复动态 Live2D，再用 AssetStudio GUI 或实机 hook 追贴图/动作绑定。

当前没有阻塞 Godot 克隆启动的逆向开放项。

 ## 已解决的命名陷阱

 - `DICE_SEED = 5751802824474857500` 名字误导：它不是骰子 RNG seed，也没有接到 `UnityEngine.Random.InitState`。实际接线在 `$UNPACK\engine_spec\decompiled\Datapool._Init_d__151.c` / `Datapool.c` 的资源包解密 seed 数组。唯一游戏侧 `UnityEngine.Random.InitState` 在 `GameApplicationCreator.Awake` 中临时生成 `CARD_SEED` 后恢复状态。详见 `$UNPACK\engine_spec\handoff\MANIFEST-seed.md` 和 `verified-conclusions.md` 第 4b 条。

 ## 反编译文件命名约定（降低漏看）

 `.c` 文件按**类名**命名（`FuncCompare.c`、`PlayerExtensions.c`、`AddSudanCard.c`…3572 个），不是按地址。所以"类 → 源文件"解析几乎零成本、零歧义。dump.cs 同时给字段偏移和 RVA，能当"地址簿"用。两个特性合起来意味着：任何结论都能用一句 `rg` 在几秒内核完。

 ## 第一件事

 读 `$UNPACK\engine_spec\handoff\verified-conclusions.md` 拿到已验证结论索引。读 `$UNPACK\engine_spec\AUDIT_2026-06-29.md` 了解这次逆向经历过哪些错误修正（含教训）。然后按上面的规则开干。
