# AGENTS.md — Faust Godot 项目

## 项目目标

在 `C:\Users\User\Documents\GitHub\Faust` 维护《苏丹的游戏》规则复刻底座，并以该底座创作发生于“魔力之都”的校园自走棋：让具名角色的养成、关系、校园生活与不可逆后果进入卡牌流转、仪式投放、组队构筑和自动对局的同一核心循环。

## 与用户沟通

用户明确说明自己有 ADHD：创意较多，但阅读大段文字的耐心较低。智能体应降低交流本身的认知负担，但不能因此降低研究和实现的严谨度。

- 默认先用 1—3 句话给出结论、当前需要用户决定的事项和推荐选项；背景与推理按需展开。
- 一次只推进一个核心问题。不要在同一回复中同时抛出大量机制、分支或开放问题。
- 使用短段落、短列表、明确小标题和具体例子；避免连续的大段论文式文字。
- 需要用户选择时，优先给出 2—3 个清楚、互斥的选项，并标出推荐项及其代价。不要要求用户先整理复杂需求。
- 长时间工作时只汇报阶段结果、发现和下一步，不逐条播报工具操作。
- 先区分“已确认”“我的建议”“仍待验证”，防止用户必须从长文中自行辨认结论强度。
- 完整证据、来源、数据过程和详细设计继续写入仓库文档；聊天中提供短摘要和可点击文档入口。
- 如果内容无法避免较长，先给“30 秒版”，再提供可跳过的详细部分；用户说“一点点来”时必须停止扩展，只讨论当前一项。
- 不把 ADHD 当作能力不足，也不擅自提供医疗判断；目标是减少切换、检索、记忆和阅读负担，让用户把注意力用于创意判断。

## 语料库

完整逆向产物在 `C:\Users\User\Documents\GitHub\Faust-local-source\_unpack\`（只读，不拷贝、不修改）。

## 逆向参考与验证

实现游戏逻辑时，使用 `$faust-clone-reference` skill。它提供：信任层级、SRC 指针验证、双信号规则、功能域 MANIFEST 导航、已知陷阱清单。该 skill 提供逆向方法论和验证流程。注意：skill 本身也是 .md 文档——语料库里的 .c 反编译和 dump.cs 才是事实本身，skill 教你怎么找到并验证它们。

## 设计研究证据入口

新会话在引用既往游戏设计研究或提出数值规则前，先读 `docs/research/README.md`，再按其中导航使用 `docs/research/faust-game-design-data-research.md` 的主张登记表、来源登记表和证据缺口。

- 引用《苏丹的游戏》静态配置数字前，运行 `tools/export_design_research_snapshot.ps1 -Check`；配置存在不等于单局可见、运行时可达或玩家实际经历。
- 判断原作运行时行为时仍必须使用 `$faust-clone-reference`，不能让研究总报告替代 `.c`、`dump.cs` 与独立信号。
- 当前没有 Faust 正式玩家实验、逐局遥测、NASA-TLX/DRT 结果，也没有经验证的手牌上限、候选数量或自动化层级。后续智能体不得把研究方案、外部类比或用户确认的方向写成已测参数。
- 讨论具名人物、条件式战术和自动战斗叙事时，先读 `docs/design/unicorn-overlord-autobattle-narrative-reference.md`。不得把《圣兽之王》直接登记为酒馆战棋式自走棋；它验证的是完整叙事、长期人物与自动局部战斗可以共存，随机供给、出售替换和逐轮阵容转换仍是 Faust 自己的未决问题。
- 修改研究总报告、快照或核心设计研究后，运行 `tools/check_design_research.ps1`。

## 当前进度

Godot 工程具备横版主场景、近距 NPC 交互、场景出口与位置恢复、仪式浮层、事件队列、运行时卡牌/仪式实例、v5 存读档与第一批常驻仪式。卡牌 UID、运行时标签、数量和仪式槽位归属均由 `CardInstance` 维护；v4 及更早存档明确拒绝加载且不显示继续游戏。

当前已验收克隆内容统一映射到一个稳定的玩家行动主体 `player_actor_uid`：
阿尔图。其他人物是被卷入行动的相关人物，物品是可用事物，苏丹卡是
外部压力；它们保留原有规则与结算，不会因为进入仪式而切换玩家角色。

已验收治理家业/俺寻思/淘书生成存读档链，以及“上朝 -> 权力的游戏 -> 标签移除”实例链。全配置中未支持的 DSL 键必须继续由 `tools/export_dsl_audit.gd` 按配置 ID、次数和位置报告，不得静默视为支持。

2026-08-14 解冻后批次一已验收（310 测试 / 2221 断言全绿）：result 裸键族 `<选择器><+|-|=>标签`（ModifyTag）与 `<选择器>.uprare`（ModifyRare）、`copy.s<n>`（CopyCard）、`delay_off`（DelayOff）、`steam_achievement`/`debug`/`error`/`warn` 空实现；condition 的 `rite_end.<id>`、`rite_have.<id>.<sel><op>`、`round<op>`；`GameState.ended_rites` 记录并入 v5 存档。语义引用见 `sim/result.gd`、`sim/condition.gd` 内 SRC 注释与 `engine_spec/operations.json`、`conditions.json`。当前剩余审计缺口：result 仅 `rebirth.s<n>`（8 处，分支语义待双信号确认后再实现，勿猜测）；action 94 键，主体为新手引导 UI 族（`hand_pop.*`/`rite_pop.*`/`focus.*`/`close_*`/`begin_guide`/`slide` 等）加 `difficulty`、`magic_sudan`、`table.*~equip`、`total.change_card_*`。

## 项目阶段：完全复刻冲刺 + 校园自走棋长期方向（2026-08-14 解冻）

2026-08-13 曾将复刻置于维护冻结；2026-08-14 用户决定**完全解冻**：当前默认开发方向是尽可能完整地复刻《苏丹的游戏》，以实机游玩反馈驱动修改与验收。规则引擎、Condition/Result DSL 子集、分层结算、苏丹卡循环、CardInstance、v5 存读档与首周四链均已成立（最近一次完整验收为 310 个测试全绿），剩余工作是 DSL 键覆盖、内容链铺量与产品化。

**默认行为：**

- 复刻**完全解冻**。按 DSL 审计、可达性元数据与实机游玩反馈持续扩展苏丹的内容链、仪式与 DSL 覆盖。每批内容须经过逆向验证（双信号）与 GUT 测试后才能接入正常开局；禁止把未验证配置一次性全量倾倒进正常开局。
- 强约束不变：未支持的 DSL 键必须继续进入 `tools/export_dsl_audit.gd` 审计而不是被静默吞掉；Queue/Save 边界与 v5 存档语义不得隐式破坏；测试保持全绿。
- `docs/design/autobattler-campus-direction.md` 仍是**长期产品方向基线**，约束原创设计与校园自走棋的目标形态；其第 7 节“不以补齐苏丹内容为默认工作”已被 2026-08-14 完全解冻决定取代（该文档已同步记录此变更）。
- 项目**不设默认核心问题或强制讨论焦点**。`docs/design/mahjong-autobattler-common-origin.md` 第 9 节记录了“首次成型后继续运转”的候选结构研究（做牌/阵容成长/循环），仅作为可查阅的研究材料，不是必须回答的问题；用户的新问题、新证据或更有价值的切入点可随时改变讨论顺序。
- `docs/design/single-character-will-simulation.md` 降为“角色内在状态与行动主体连续性”的从属研究材料。玩家与角色控制层、盲点、惯性等假说只有在服务于校园自走棋的具名角色养成、关系和后果时才能进入原型，不能取代队伍与校园方向。
- “当前周期目标—有限活跃手牌—进行中人物”是解决手牌负担的候选架构，不是已批准答案；可以与其他问题并行比较或在更合适的时机讨论。
- 横版场景是**表现与交互探针**，不是创新命题本身。场景表现参考《大骑士物语》的图板棋子结构与《圣兽之王》的手绘奇幻画面；不得把视觉相似视为机制成立。场景内不再保留“思考云/思考模式”（十三机兵式语法已移除）；桌面“拖入卡牌以思考”投放区作为复刻兼容链保留。
- 用户已明确授权在 Faust 主工程中实施机制原型。允许复用现有 Queue、Save、CardInstance、Rite 和结算边界，并继续用苏丹内容占位；但占位内容只能验证技术链，不能作为原创体验成立的证据。
- 当前不进入原创内容生产：不要新增人格名册、技能台词、剧情包、题材设定或“思维内阁”内容。先修正设计问题、建立机制假说和无内容的体验验收标准。
- `MethinksEngine`、`drop_card_on_methinks` 等命名属于复刻期兼容接口。玩家可见概念统一为“思考”；在机制方向确定前，不因命名不理想而破坏已验收的旧链。
- 复刻期的强约束在创新期依然适用：未支持的规则要进入审计而不是被静默吞掉；存档/队列边界要保留；不要按配置数量机械安排内容。

## 语料库的角色

2026-08-14 完全解冻后，逆向语料库（`Faust-local-source/_unpack/`）恢复为**实现依据**：复刻 DSL 键、内容链与运行时行为时，必须遵循 `faust-clone-reference` 的信任层级与双信号规则，以 `.c` 反编译、`dump.cs` 与配置数据为事实来源。它同时保留"设计参考"用途，供原创设计假说引用原作结构。

## 仪式时序模型（认知防坑指南，2026-07-19 建立）

这一节是为了防止后续读者（包括 AI 会话）重犯两类已确认的错误：(1) 把所有仪式都当成"立即结算的事件"，(2) 误判"苏丹卡在仪式槽里时 deadline 怎么走"。

**两条时序轴必须分开：**

- **0 天仪式**（`round_number == 0`）：玩家在 UI 点"开始"后**立即结算**，`RiteInstance.life` 永远 ≥ `round_number`。事件驱动。
- **N 天仪式**（`round_number >= 1`）：玩家 start 后，`RiteInstance.life` 在每次 `RoundLoop.advance_day` 的 `_update_rite_instances` 里递增；只有 `life >= round_number` 时才结算。时间驱动（跨日批量结算）。**这才是"点下一天批量掷骰"节奏的真正发生地。**

读代码时如果只看 `_resolve_rite_instance` + `RiteResolver.resolve`，会误以为所有仪式都"被调用即结算"。真正的时序控制在 `_update_rite_instances`（`sim/round_loop.gd`）的 `life < round_number` gate 上——0 天仪式因为 life 初始为 0、round_number 也是 0，所以"立即结算"，但这不是事件驱动，是时间驱动在 round_number=0 时的退化情形。

**苏丹卡安全期规则（2026-07-19 修复并写入测试）：**

苏丹卡倒计时**无条件每天递减**，但**处刑检查会被跳过**——只要这张卡当前 `zone == "slot"` 且 `rite_uid` 指向一个 `start == true` 且 `life < round_number` 的仪式。即：嵌入在进行中的 N 天仪式槽里时，倒计时照减（甚至可降到 0 或更低），但不 game_over。一旦仪式结算（卡被放回 sudan zone 或被消耗），同一次 `advance_day` 的后续 deadline 检查会立即抓到它。

- 实现在 `RoundLoop._is_sudan_embedded_in_open_rite`（`sim/round_loop.gd`）。
- 测试在 `tests/test_rite_lifecycle.gd` 的 `test_sudan_card_in_started_rite_does_not_trigger_execution` 和 `test_sudan_card_executes_again_after_shelter_rite_settles`。
- 规则来源：知乎专栏 p/1909509257005831882、巴哈姆特 snA=111、BWIKI 新手指南（三源交叉确认）。
- 仍不确定：shelter 结算当天 vs 次日才处刑，资料未明确；当前实现是结算当天（settlement 先于 deadline 检查）。

## 技术栈

- 引擎：Godot 4.7
- 脚本：GDScript
- 测试：GUT（`tools/run_gut.ps1`，会拦截 Godot `SCRIPT ERROR`、`ERROR`、orphan 与全部泄漏诊断）
- Live2D：第一版用静态图替代，后续按需接入

## Queue and Save Boundary

- `GameState.pending_operations` is the only mutable event/prompt/choice UI
  queue. Preserve occurrence context (`card_uid`, `rite_uid`) when adding a
  new operation type; do not deduplicate by configuration ID.
- `delayed_operations` persists v5 delay payloads and runs once at the Next
  Day boundary. Old v5 split queues are synthesized on load; v4 and earlier
  saves remain rejected without migration.
- Manual user archives are separate from `user://save.json`: use the
  `SaveSystem` archive APIs so index metadata and slot payloads stay together.
  Loading an archive refreshes the continue save; deletion removes both the
  index record and payload. Keep the 50-slot limit and the v5 player-save gate.
- Every clone-content batch (rites, events, cards, DSL keys) must pass
  reverse verification and green GUT tests before entering normal play.
  Keep all remaining DSL gaps in the machine-readable audit rather than
  silently marking them supported.
- Use the reachability metadata in `tools/export_dsl_audit.gd` to choose the
  next content batch. It is a conservative static graph, not a replacement for
  source-backed runtime verification or a reason to mark every short-hop key
  supported.
