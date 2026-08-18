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

## 复刻工作法（2026-08-17 起强制，用户决定）

对标成熟逆向复刻工程（OpenMW / DevilutionX / OpenRCT2 / 任天堂系 decomp）的三支柱。用户已明确否决"发现错误→修一处"的打地鼠模式：那样永远修不完。全体后续会话遵循以下硬约束：

1. **原作数据零转译。** 运行时内容只允许来自 `content/`——与语料库 `data/config` 逐字节一致的原作配置。禁止新增配置转换层、自制中间格式或手写内容表；克隆侧文件在语料库无对应物即为违规。改动 `content/` 后必须运行 `tools/check_content_parity.ps1` 且零违规。
2. **原作产物当裁判。** 语料库 `save_samples/`（auto_save / save_slot_000 / global / user_archive）是原作真实存档，即对拍的"标准答案"。涉及游戏状态的批次，验收标准从"GUT 全绿"升级为"GUT 全绿 + 与原作证据对拍"（对拍台建设状态见 `docs/METHOD_MAP.md`）。自写测试只能证明"和昨天一致"，不能证明"和原作一致"。
3. **结构 1:1 映射。** `docs/METHOD_MAP.md` 是复刻主 TODO：新工作从表中取项（🟡 近似 / ❌ 自制 / ⬜ 缺失），不从零散错误报告或实机反馈单独取。实现任何行为前，先在表中登记原作方法背书（`.c` 反编译 + `dump.cs`/配置，双信号）；无背书的新自制结构不允许进入主干，已有自制项按表逐个消灭。每个复刻批次收尾时更新对应行；每个大阶段从 `dump.cs` 类清单做一次增量普查。

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

2026-08-13 曾将复刻置于维护冻结；2026-08-14 用户决定**完全解冻**：当前默认开发方向是尽可能完整地复刻《苏丹的游戏》，以实机游玩反馈驱动修改与验收。规则引擎、Condition/Result DSL 子集、分层结算、苏丹卡循环、CardInstance、v5 存读档与首周四链均已成立，剩余工作是 DSL 键覆盖、内容链铺量与产品化。

**2026-08-15 独立审计与修复批次一/二（307 测试全绿）：** 8 域逆向审计完成
（`docs/AUDIT_2026-08-15.md` 及七份分报告，含总修复清单）。批次一（Critical）：
round 每天无条件 +1（仅抽苏丹卡受门控）；FuncCompare 运算符键尾最长匹配；
玩家确认仪式 = 置 start/start_round/start_life（N 天跨日结算，OnStop 撤回）；
timing_rounds 周期冷却重臂（round_begin_ba:N = 周期，开局链在
`ui/game.gd _start_new_run` 发射第 1 回合）。批次二（High）：通用卡牌寿命
（card_vanishing）+ 仪式槽庇护收窄为"任一槽"；rite 条件 = 实例存在性 +
rite 时机哨兵 1；clean.rite 删其他仪式实例；choose = 随机执行 N 个子操作；
success/failed 按 last_op_status 互斥；have 族跨域计数（tag 值求和/堆叠）；
槽位条件可见已放置卡；装备继承门改 can_inherit；属性表达式完整文法
（递归下降：四则/e() 敌方/sN.tag/counter.N，`slot_entries` 按槽 is_enemy 分敌我）；
counter/global_counter/card_born/game_end 时机发射 + game_end 结局过滤。
剩余批次三（回退链/骰子重掷/auto_result UI/重抽三题/counter 默认 op/UI 时机钩子）
与批次四（Low 打磨）见总修复清单。

**2026-08-17 cost 支付链审计 + 金骰 counter 化（批次 A 续，342 测试全绿）：**
counter 常量表全解（dump.cs:542525-542531）：金骰 = COUNTER_GOLD_DICE 7100006、
回退 = COUNTER_BACK_TO_PREV 7100007（存 global，9999=无限）、额外重抽 =
COUNTER_SUDAN_EXTRA_REDRAW 7100008；GetCounter 对金币 7000105/门客 7000104 为
**派生读**（cards+rites 求和，仪式槽金币计入总额）。cost 支付：IsSatisfied
判定时按 player.cards 枚举序选定付款卡清单记入 need_cost_cards（支付顺序=
最旧优先；扣款执行体未反编译留档）。克隆落地：`gold_dice` 改为 counter 7100006
计算属性（含非负门 + v6 去标量 + 旧值迁移）；`_remove_gold` 扣除顺序改 uid
升序（枚举序）；`gold_total()` 扩展含仪式槽。待迁移：~~7100007（需全局域）~~
（2026-08-18 批次 B 已迁移）、7100008（随重抽族）。

**2026-08-18 回退轮次文件持久化（批次 F，373 测试 / 2293 断言全绿）：**
原作 `DatapoolExtensions.SaveRoundBegin/End` 双写链落地：先刷新 continue，再写
`round_{N}.json` / `round_{N}_end.json`；`IsValidRound/End` 校验 Player 存档门，
`LoadRound/End` 从磁盘恢复并刷新 continue。`GameState.round_snapshots` 保留为同进程
缓存，缓存缺失时自动落到磁盘，因此重启后仍能回退；配额仍在 Global 域，恢复 Player
不会返还消耗。`LoadUserArchive` 按原作删除 `round_*.json`，防止回到旧时间线。
证据：DatapoolExtensions.c 0x3f8d50/0x3f8e70/0x3f8fa0/0x3f9050/0x3f9120 +
dump.cs:418323-418343 + stringliteral `round_{0}`/`round_{0}_end`/`round_*.json`。
新增 `tests/test_round_snapshot_persistence.gd`（4 测试 / 25 断言：双边界跨重启、
损坏文件不扣配额、档案清理旧轮次）。原作 auto_save 导入桥复验 **24/24** 全过。
留档：`last_round_rite_data` 独立语义、BACK_TO_PREV_BEGIN(3) 写点仍未定位。

**2026-08-18 手牌位系统（bag/bagpos/BagIndex，批次 E，369 测试全绿）：**
`Card.bag`@0x48 = 包页 id、`bagpos`@0x4c = 页内 1 基位置（0=未摆放）、
`Player.BagIndex`@0x150 = 当前查看页（IsCurrentHandCard 0x3826a0 = bag==BagIndex
且三标签）；`UpdateHandCardPos` 0x559a70 在 b__6 链（回合开始事件之后）把当前页
手牌排序压缩为 1..N；GenCoin `set_bagpos(1)` 金币前置、GenSudanCard
`set_bag(BagIndex)` 新卡入当前页。样本证据：仅 6 张卡有位置（玩家手动摆放，
bagpos 非类型成员）。克隆落地：`CardInstance.bag/bag_pos`（v7 持久化，向后兼容）、
`round_loop.update_hand_card_pos` 日终压缩（克隆单页 bag=0，不变式 bag_pos=手牌序+1）、
金币/抽卡写点对齐、导入桥 bag/bagpos 透传 + **bag_positions 对拍行（24 项全过）**。
`hand`/`rail_order` 数组部分收敛（字段已承载并维护）；彻底退役阻塞于 IsHandCard
三标签名（字面量间接寻址无法反查，留档）与包页 UI。新增
`tests/test_hand_positions.gd`（6 测试：前置/压缩/跨页保留/往返/抽卡/导入）。

**2026-08-18 苏丹期限真源逆向 + 卡寿命模型统一（批次 D，363 测试全绿）：**
导入桥声明的"苏丹期限近似"升级为**精确**：期限 = 卡寿命通用系统（`GenSudanCard`
L3656-3662 出生抢跑 `模板 card_vanishing − sudan_card_init_life` + 每日 life+1 +
槽位庇护只挡死亡 + `life>=card_vanishing` 处刑走 DoVanish/vanish.over），样本
life=0=7−7 四信号吻合（困难档 7−5=2 抢跑=5 天）。克隆落地：draw_weekly_sudan
出生头起步；`_update_card_lives` 移除苏丹跳过——处刑并入通用死亡（结果 expired/
game_over 由 sudan 旗标映射，over_reason 来自 vanish.over）；days_left 变为
`card_vanishing − life` 的同步镜像（庇护期间可为负，社区"倒计时退到负数"得到
解释）；重抽新卡继承弃卡 **life**（非 days_left）；rebirth 倒计时改按模板
card_vanishing 而非难度值；`_is_sudan_embedded_in_open_rite` 窄门删除（并入通用
庇护）。顺带解出抽牌机制：sudan_card_pool **先 Shuffle 再 RemoveLast**（顺序无
意义，多重集对拍即正确粒度）、重抽 `set_life(旧卡 life)` + 弃卡归 0 随机位回插。
导入桥 days_left 精确化，仅 drawn_round 仍登记近似（难度中途切换后无法反推）。
测试：test_sudan 新增头起步/庇护过期两用例，既有四测试按 life 模型重写 fixture。

**2026-08-18 对拍台阶段二导入桥（批次 C，361 测试全绿）：**
`sim/original_save_importer.gd`：原作 Player 存档 → 克隆 v7 payload → 正常
deserialize 路径载入；`tools/export_save_diff.gd --bridge` 产出同刻对拍报告。
语料 auto_save.json 实测 **23/23 项全过**（回合/难度/uid 指针/counter/事件状态/
时机臂/仪式槽位/装备链接/手牌/苏丹/per-id/金币派生读）。导入桥当场抓到并修复
三个结构偏差：① timing_rounds 键 = 原作 **int**（事件 id×100，
TimingRoundBase+0x20 直址 player+0x128），克隆旧自制字符串键已改 + 旧键迁移；
② difficulty **1 基**（样本四信号同指简单档），导入 -1；③ min_round
（player+0x30）克隆补显式字段并作回退门。报告三档防静默登记
（converted/approximated/dropped）：苏丹期限字段与牌堆顺序为登记近似，
notes/only_cards/gen_cards 等为登记丢弃。测试 `tests/test_save_import_bridge.gd`
（合成 fixture + 语料真存档 + 旧键迁移）。遗留：续局行为对拍待实机样本；
多桶事件序号分配未逆向（METHOD_MAP ⬜）；~~激活苏丹期限真源~~（批次 D 已解）。

**2026-08-18 回退配额全局化 + 全局域承载（批次 B，355 测试全绿）：**
`sim/global_state.gd` GlobalState 落地（user://global.json，对应原作 Global；
先行承接 backToPrevRound/roundRollback/saveTime，其余 26 字段见 METHOD_MAP ⬜）。
回退配额迁移为 counter COUNTER_BACK_TO_PREV 7100007 存全局域（GetCounter
0x38ce70 / SetCounter 0x38f2d0 专用分支：读直通、写无条件非负 clamp；9999=
UNLIMIT_BACK_TO_PREV_TIMES 不消耗）。新局链：`Datapool.StartGame` L4497 重置
9999 → 难度选择 `PlayerExtensions.SetDifficulty` 0x38f530 公式（配额 = 当前 −
9999 + 新难度 back_to_prev_round_count：离开无限档重置、有限切有限归零、切回
无限档保留余量；金骰同函数为**加法**——克隆 `apply_difficulty` 两处偏差一并
修正；菜单新局 setup_new_run(apply_resources=false) 延迟到叙事者选择，杜绝双发）。
消耗链 `PrevRoundInternal` 0x555570：先消耗 → Global.roundRollback=2 → SaveGlobal
→ 快照恢复；配额在恢复范围外，克隆"恢复后补回预算"hack 删除。档案恢复
CorrectPlayerData L4130-4134：档案槽记录值覆写全局。v6→v7 局内存档迁移
（payload 去掉 back_to_prev_left，旧值种入全局域）。轮次文件持久化已由批次 F
补齐；BACK_TO_PREV_BEGIN(3) 写点与 last_round_rite_data 仍未定位。

**2026-08-17 金币卡多对象模型（批次 A，337 测试全绿）：** 对拍台发现的首个结构
偏差修复。原作金币 = 手牌金币卡 2000029 **多对象** count 之和：`GenCoin.c Do
0x510b40` 每次 `AddCard` 新建对象（无堆叠合并）、`set_count(操作值)`（可为负）、
`bagpos=1` 前置、OnCardBorn；花费判定 `CostCondition` 读卡对象 count；存档样本
旁证（神的乙太 ×20 对象）。克隆落地：`coin_count` 改为求和**计算属性**（对外
API/测试不变），`coin` 操作生成金币卡对象并触发 card_born，`have.金币` 等条件
自然命中，可堆叠卡在手牌渲染层合并显示（×N 徽章）；**v5→v6 存档迁移**（标量
→单对象，v5 仍可加载，≤v4 拒绝）。留档：多对象扣除顺序未验证（cost 支付执行
链未审计，现为最大面额优先）；金骰疑走 counter 待验证。

**2026-08-17 复刻工作法固化 + 对拍台阶段一（327 测试全绿）：** 用户否决打地鼠式
修错，确立三支柱方法论（数据零转译 / 原作产物当裁判 / 结构 1:1 映射，见
「复刻工作法」节）；`docs/METHOD_MAP.md` 成为主 TODO，`tools/check_content_parity.ps1`
守卫 content/ 与语料库字节一致（3808 文件零违规）。**原作存档全解码**：
`save_samples/` 为明文 JSON，Player 60 字段与 dump.cs（391488 行，JsonSerializable）
双信号吻合（零未知零类型不符）；映射表/分析工具/测试落地
（`sim/original_save_schema.gd` + `tools/export_save_diff.gd` +
`tests/test_save_diff_harness.gd`；mapped 11 / semantic 11 / missing 38），
快照见 `docs/ORIGINAL_SAVE_SCHEMA.md`。**重大结构发现**：原作金币 = 手牌金币卡
2000029 的 count（GenCoin.c Do 0x510b40：GenCard+set_count+bagpos=1+card_born，
双信号），克隆 coin_count 标量为结构偏差（METHOD_MAP C，修复批次待排）；骰子
疑走 counter（待验证）；手牌=cards bag=0 按 bagpos；仪式槽位为内嵌下标数组。
下一步 = 对拍台阶段二导入桥（原作存档→GameState→v5 导出→同刻对拍）。

**2026-08-17/18 逻辑层第八波（规则引擎 post_rite/选择器族/审计域扩展，320 测试全绿）：**
**post_rite 执行链**：卡牌定义 post_rite 在所属仪式结算后执行（参战卡+其装备逐张以
自身为上下文）——消耗品 clean.self 自毁、食客 parent-equip 离场、条件计数/结局/事件
全部走通（RiteResultPanelController.c:1268 → CardExtensions.DoPostRite 双信号）。
**选择器族补全**：`<selector>`=s<n>/self/parent/all/enemy/friend/卡牌id 通用于槽标签
操作、装备操作、clean 与 SlotHasTag 条件（OperationFilter.c Filter 0x3a15c0 +
conditions.json selector 组双信号）。**tag_tips**：属性检定求值时记录各卡用过的标签
（运行时、不进存档），HasTagTips 条件读取；`!is_rite` 否定形补齐。**审计域扩展**：
case:opN 子树内部键纳入扫描（hand_card_refresh 曾藏匿）+ cards.json 的
post_rite/vanish 入审计（card 域）；扩域后 result 2134 / condition 4001 / action 2522
全部支持。**文本占位符**：`[sudan_life_time]`/`[sudan_redraw_total_left_times]` 在
prompt/choice/仪式结算文本替换为运行值。**难度选择入游戏内**：difficulty 操作按 init
配置构建叙事者选项（头像+描述+骰率），标题页直接开局、难度页死代码删除。GameState
新增 host_uid_of_equipment/rite_slot_card_uids/remove_card_instance_from_play/
record_tag_tip/clear_tag_tips；CardInstance 新增运行时 tag_tips（不进存档）。
留档项更新：原"parent/self 聚合选择器语义未确认"已由双信号确认并实现；EventOff
小值批量关闭与 headless deferred 顺序仍留档。

**2026-08-17 表现层原作化第七波 + 去 Balatro（311 测试全绿）：** 场景树证据
（StartScene/GameScene.unity 解析）驱动的最后一批"自制表现"清理。主菜单按
StartPanel 1:1（bg_new_0 背景 + button_bg_new 668x140 按钮列 + 退出游戏）；
下一天 = 怀表组合（clock_bg 表盘 + next_day_0 印章，修掉样式盒覆盖顺序 bug）；
回退按钮换 return_last_round；引导条 = text_bg_2 + close_1 + begin_guide 图集
图标；仪式选择器紧凑菜单/事件按钮接 prompt.png/button_bg.png；ESC 菜单与存档
面板接 common_operation_bg；卡牌详情关闭钮/徽章/立绘位全部原作化；HUD 去掉
自制 chrome 条。**卡牌去 Balatro**：删除弹簧积分器、透视/阴影双 shader、
SubViewport 双通道渲染、拖拽速度摆动与 `ui_motion.gd` 全局动效层；悬停/选中 =
CardArea 高亮抬升，发牌/回流 = eased tween，拖拽预览精确跟指针；CardWidget
根改 Control 阻断容器最小尺寸传播。缺图卡（102 张，原作数据本身无立绘）显示
card_type_* 类型图标。遗留：地图计数小牌样式盒、图钉精确对位、
set_world_scene_blocker/world_spawn_id 命名清理（存档兼容需评估）。

**2026-08-16 完全复刻冲刺二（DSL 全归零+引导+结局，330 测试全绿）：**
新手引导系统：`BeginGuideBar`（15 类指引文案+手柄绑定提示，点击关闭）、
`begin_guide`/`close_begin_guide` 安装清除指令、92 个引导表现键（hand_pop/rite_pop/
focus/slide/close_* 等）入 `guide_cues` 队列，全部进存档。**DSL 三类全支持归零**：
result 2119/2119、condition 3988/3988、action 2285/2285（最后补齐 table/total 域
equip、scoped change_card_name/text）。结局系统：over.json 159 结局表接入，
处刑（苏丹 vanish.over）与事件 over 值驱动 ending id，结局屏显示名/副题/文本/
后日谈标记。剩余路线图见 `docs/GAP_FULL_GAME.md`（向导剧情流、after_story 后日谈
播放、图钉对位、笔记/图鉴、Live2D、实机验收）。

**2026-08-15 完全复刻冲刺一（表现层，322 测试全绿）：** 原作表现层三件套
接入：卡面 1190/1292（`assets/original/cards/`，无图 102 张回退自制纸面）；桌面双层底图
（table.png + table-map.png）；音频系统 `GameAudio`（main/tutorial BGM + 下一日/确认/
重抽/苏丹四族抽卡/骰子/金骰音效）。DSL 收口：`rebirth.s<n>`（槽卡倒计时重置，
RebirthSudanCard）、`difficulty`（中途难度切换 apply_difficulty）、`magic_sudan`
（引导演示指令，无向导宿主记 no-op）——result 2119/2119 全支持、condition 全支持，
action 剩 92 键全部属于新手引导 UI 演示族。剩余路线图见
`docs/GAP_FULL_GAME.md`（引导系统/结局后日谈/图钉对位/笔记图鉴/Live2D）。

**2026-08-15 修复批次三/四（审计修复全部收口）：** 批次三：
回退上一回合整链（`GameState.round_snapshots` 每日双快照、min_round/预算门控、整体恢复、
`back_to_round_begin` 键、桌面"回退"按钮）；骰子重掷（配额 = 槽卡 重投 标签求和）；
auto_result UI 静默结算；重抽三题（失败不回插不消耗/弃卡标签回写池/额外重抽 7100008）；
counter 无后缀默认 >=；game over 保留继续存档；think 多分支全执行（ProcessPop 语义）；
open_card_info/close_prompt/sudan_redraw_start 时机钩子。批次四：拖放自动路由到首个
满足槽；`is` 无 acting 卡时查槽卡；r1 单数值形式；round<=/round!= 原作退化 Equal 怪癖；
auto_begin 不复查 open_condition。**留档项**（实机反馈或新证据驱动，见总修复清单）：
事件日内 Promise 阻塞模型、headless deferred 顺序（上朝链依赖 finalize-first）、
parent/self 聚合选择器、EventOff 小值批量关闭、向导类时机钩子。审计八域的
Critical/High/Medium/Low 修复建议至此全部落地或明确留档。

**默认行为：**

- 复刻**完全解冻**。复刻工作项从 `docs/METHOD_MAP.md` 取（三支柱见上文「复刻工作法」），结合 DSL 审计、可达性元数据与实机游玩反馈排定优先级，持续扩展苏丹的内容链、仪式与 DSL 覆盖。每批内容须经过逆向验证（双信号）与 GUT 测试后才能接入正常开局；禁止把未验证配置一次性全量倾倒进正常开局。
- **2026-08-15 目标升级（用户决定）**：交付目标是**完全复刻、完整可玩的最终游戏**，不是 MVP 或 demo。中断复刻后加入的独立创新表现层必须剔除出游戏（横版世界场景、小丑牌式手牌动效、桌面棋子导航等探针，删除即可，git 历史保留可恢复）；表现层以原作结构为准（桌面背景 + 仪式图钉模型，MapController.c 为证据）。校园自走棋仍是长期产品方向，但其探针代码不再保留在主工程运行路径中。
- 强约束不变：未支持的 DSL 键必须继续进入 `tools/export_dsl_audit.gd` 审计而不是被静默吞掉；Queue/Save 边界与 v5 存档语义不得隐式破坏；测试保持全绿；`content/` 与语料库的字节一致由 `tools/check_content_parity.ps1` 守卫（见「复刻工作法」）。
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

## 仪式时序模型（2026-08-15 按反编译证据重写；旧版社区资料结论已废止）

2026-07-19 旧版基于社区攻略（知乎/巴哈姆特/BWIKI）的部分结论已被 2026-08-15
独立审计的反编译证据推翻。本节为现行依据；完整证据见
`docs/AUDIT_2026-08-15.md` 及其分报告（报告一 A1/A2/A4、报告八）。

**创建与开始是两个动作（RitePanelController.c OnConfirm 链，行 1203-1239）：**

- DSL `rite` 键（`StartRite.c @ Do 0x51bcf0`）只**创建实例**（含吸附，失败中止），不置 start、不校验槽满。
- 玩家按下"开始"= 校验（CheckConfirm）→ `set_start(1)` → `start_round=player.round` → `start_life=life`；可通过 OnStop（0x5906e0）撤回：`start=false`、life 回滚 start_life、卡留槽。
- **结算只发生在** `UpdateSingleRite`（0x55ab10）：已 start 且 `life >= round_number` 才 Settlement。`round_number==0` 仪式在 start 后当日结算。

**round 推进（GameController OnNextRound 链，b__3）：**

- round **每天无条件 +1**（`player+0x2c`），与是否持有苏丹卡无关；只有**抽新苏丹卡**受 `HasSudanCard` 门控（`TryGenSudanCard 0x559730`）。
- 事件 `round_begin_ba` 每天触发；周期事件的"下次触发回合"记在 `player+0x128`（timing_rounds 字典），触发后重臂（`TimingRoundBase.c`）——`round_begin_ba: 5` = 每 5 回合复发，不是"仅第 5 回合"。

**卡牌生命庇护与苏丹期限（2026-08-18 按反编译证据定型）：**

- 通用系统（DoCardUpdate 0x54d4c0 → UpdateSingleCard b__1 0x572420）：每张活卡
  每天 life+1（**老化无条件，庇护只挡死亡**）；`life >= 模板 card_vanishing`
  且未受庇护即死亡（vanish 操作 + card_dead）。
- 庇护条件是"身处**任一**仪式槽（`rite.cards`，即 (Card, flag) 快照 flag=1）"，
  **不看该仪式是否 start、不看到没到 round_number**。
- **苏丹卡走同一系统**：`GenSudanCard 0x54f6f0` L3656-3662 出生时
  `set_life(模板 card_vanishing − player.sudan_card_init_life)`（抢跑量；困难档
  7−5=2，故期限 5 天）；死亡即处刑（vanish.over 驱动结局屏）。庇护期间 life 照常
  递增，可见倒计时（UpdateSudanLife 0x55aeb0：`card_vanishing − life`）可为负。
  难度切换经 SetDifficulty 更新 sudan_card_init_life，只影响**之后**的抽卡。
- 抽卡：`TryGenSudanCard`（HasSudanCard 门控）→ `GenSudanCard` 从
  player.sudan_card_pool **先 Shuffle（sudan_shuffle）再 RemoveLast**；重抽
  `RedrawSudanCard 0x5558b0`：新卡 `set_life(弃卡 life)`（继承剩余期限）、弃卡
  life 归 0 后 `Insert(Random.Range(0,count))` 回池。
- 留档：b__1 的老化豁免标签（DAT_1825ac9e8，非苏丹卡；疑为"不朽"类标签，
  RebirthSudanCard 第二分支也引用同类）字面量无法从元数据反查，无配置命中。

**旧版遗留的不确定项**（"shelter 结算当天 vs 次日"）已被反编译证据替代：
处刑检查在结算管线之后（b__6），结算当天庇护失效即当日可处刑。

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
