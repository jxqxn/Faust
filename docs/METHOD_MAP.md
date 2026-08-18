# 原作—克隆方法映射表（METHOD_MAP）

> 2026-08-17 建立（复刻工作法，见 AGENTS.md 同名节）。**本表是复刻工作的主 TODO**：
> 新工作从这里取项，不从零散错误报告取。实现行为前先在此登记原作方法背书
> （`.c` 反编译 + `dump.cs`/配置，双信号）；批次收尾时更新对应行。

## 状态图例

- ✅ **已对齐**：克隆实现有原作方法级 SRC 背书（双信号），语义经反编译验证。
- 🟡 **近似**：行为大体一致，但缺方法级背书、宿主结构自制、或只覆盖原作的一部分。
- ❌ **自制**：克隆存在、原作无对应——待消灭、降级为兼容层、或证明为等价承载。
- ⬜ **缺失**：原作存在、克隆没有——按玩家影响排期补齐。

## A. 已对齐 ✅（核心循环有原作方法背书）

| 原作证据（双信号） | 克隆落点 | 说明 |
| --- | --- | --- |
| `GameController` OnNextRound 链 b__3（round 每天无条件 +1，`player+0x2c`） | `sim/round_loop.gd` `advance_day` | 与是否持苏丹卡无关 |
| `TryGenSudanCard` 0x559730（`HasSudanCard` 门控抽新卡） | `sim/round_loop.gd` | 只有抽卡受门控 |
| `UpdateSingleRite` 0x55ab10（已 start 且 `life >= round_number` 才 Settlement；0 日仪式当日结算） | `sim/round_loop.gd` `_update_rite_instances` | 结算时机唯一入口 |
| `RitePanelController.c` OnConfirm 行 1203-1239（set_start / start_round / start_life）+ OnStop 0x5906e0 撤回 | `ui/rite_view.gd` + `GameState.start_rite_instance` | 创建与开始是两个动作 |
| `StartRite.c` Do 0x51bcf0（DSL `rite` 键只创建实例，不置 start） | `sim/result.gd` `rite` 分支 | 含吸附失败中止 |
| `DoCardUpdate` 0x54d4c0 行 5139-5231（通用卡寿命；庇护 = 身处任一仪式槽） | `sim/round_loop.gd` card_vanishing 链 | 庇护不看 start/round_number |
| `TimingRoundBase.c`（周期事件重臂，`player+0x128`） | `sim/round_loop.gd` timing_rounds | `round_begin_ba:N` = 周期 |
| `OperationFilter.c` Filter 0x3a15c0（s<n>/self/parent/all/enemy/friend/卡牌id 选择器族） | `sim/result.gd` `_slot_target_uids`、`sim/condition.gd` `_selector_condition_cards` | 通用于槽操作/装备/clean/条件 |
| `HasTagTips.c` IsSatisfied 0x3fe3c0（读卡实例 tag_tips 列表） | `sim/condition.gd` `tag_tips.<tag>` + `GameState.record_tag_tip` | 属性检定时记录，运行时不进存档 |
| `RiteResultPanelController.c:1268` → `CardExtensions.DoPostRite`（参战卡+装备逐张结算） | `sim/round_loop.gd` `_run_post_rites` | 卡牌定义 post_rite 执行链 |
| `RebirthSudanCard` 0x519d60 + b__4_0 set_life(0) | `sim/result.gd` `rebirth.s<n>` | 槽卡倒计时重置 |
| FuncCompare 运算符键尾最长匹配 | `sim/condition.gd` dispatch | 审计报告一 |
| `operations.json` / `conditions.json` 全键域 + `case:opN` 子树 + cards.json `post_rite`/`vanish` | `sim/dsl_audit.gd` + `tools/export_dsl_audit.gd` | 三类全支持归零（2134/4001/2522）；新键必须入审计 |
| `over.json` 159 结局表（处刑 vanish.over / 事件 over 值驱动） | `ui` 结局屏 | 名/副题/文本/后日谈标记 |
| `init/*.json` 难度配置 | `sim/result.gd` `_difficulty_choices` | 难度选择发生在游戏内（SetDifficulty 语义） |
| 文本占位符 `[sudan_life_time]` / `[sudan_redraw_total_left_times]` | `sim/game_state.gd` `substitute_text` | 显示前替换运行值 |
| `MapController.c`（桌面底图 + 仪式图钉模型） | `ui/game_screen.gd` 桌面 | 表现层结构依据；点位精确对位见 🟡 |
| `StartScene.unity` / `GameScene.unity` 场景树（GameObject/RectTransform/Sprite GUID） | `ui/main_menu.gd` 等第七波接线 | UI 原作化的证据法 |
| `GameController.GenCard` 0x54f650 → `PlayerExtensions.AddCard` 0x38b620 + `GenCoin.c Do` 0x510b40（金币 = 手牌金币卡 2000029 **多对象** count 之和；每 op 新建对象、count=操作值可为负、bagpos=1 前置、OnCardBorn） | `sim/game_state.gd` coin_count 计算属性 + `_grant_gold`/`_remove_gold`、`sim/result.gd` coin 键、v5→v6 存档迁移 | 2026-08-17 修复；多对象扣除顺序未验证（cost 支付链未审计，现最大面额优先） |
| `CostCondition.IsSatisfied` 0x3f6160（花费判定读卡对象 count，card+0x20；判定时按 player.cards 枚举序选定付款卡清单记入 `ConditionContext.need_cost_cards`） | `sim/condition.gd` 金币/coin 条件（经 coin_count 求和属性）、`game_state._remove_gold`（uid 升序=枚举序，末对象部分扣减等价于移除找零；付款执行体未反编译留档） | 读模型与支付顺序一致 |
| `PlayerExtensions.GetCounter` 0x38ce70 特殊分支（7000105 金币/7000104 门客 = 从 cards+rites 派生求和；7100007 回退配额读 Global） | `game_state.gold_total()`（hand+slot 求和） | 金币总额含仪式槽 |
| dump.cs:542529 常量表 + `PlayerExtensions` Add/SubCounter（**金骰 = COUNTER_GOLD_DICE 7100006**；额外重抽 = 7100008；回退 = 7100007 存 global，9999=无限） | `game_state.gold_dice` 计算属性（counter 存储 + 7100006 非负门 + v6 去标量） | 金骰已修；7100007/7100008 见 ⬜ |

## B. 近似 🟡（行为近似承载，缺背书或部分覆盖）

| 克隆落点 | 缺口 |
| --- | --- |
| `sim/game_state.gd` v5 存档（to_save_dict） | 原作存档 schema 已全解码（60 字段，`docs/ORIGINAL_SAVE_SCHEMA.md` + `sim/original_save_schema.gd` 对拍工具）；**阶段二导入桥未建**：原作存档→GameState 转换 + 同刻值对拍 |
| `GameState.pending_operations` / `delayed_operations` | 原作 Promise/Pop 队列模型的宿主等价物；事件日内 Promise 阻塞语义留档未对齐 |
| `sim/condition.gd` AttrExprParser | 文法已对齐（四则/e() 敌方/sN.tag/counter.N）；解析器宿主为自制递归下降，非原作方法映射 |
| `ui/game_audio.gd` GameAudio | 仅 main/tutorial BGM + 部分音效；拖放音、弹窗出现音、BGM 分层（level2/3）、结局 BGM、`sfx_*.json` 全量缺 |
| `ui/begin_guide_bar.gd` 引导条 | 文案/键族/存档对齐；`WizardController` 完整演示宿主与 magic_sudan 演出缺，5310004 后序列未实机校对 |
| `GameState.round_snapshots` 回退链 | 原作回退机制未定位方法背书（return_last_round 按钮存在于原作资产）；语义按需自查 |
| `ui/game_screen.gd` 仪式图钉点位 | 结构依据 MapController；精确坐标需实机对照微调 |
| 桌面地图计数小牌（count chit） | 仍为样式盒，待原作对位 |
| 苏丹卡视觉（稀有边框、倒计时红光） | 部分接入；细节原作化未完成 |

## C. 自制 ❌（原作无对应，待消灭/降级）

| 克隆物 | 处置 |
| --- | --- |
| `set_world_scene_blocker`、`world_spawn_id`、`world_position_ratio` 存档字段 | 横版世界探针遗留；清理需评估 v5 存档兼容（GAP 留档） |
| ~~`GameState.coin_count` 标量金币~~ | 已消灭（2026-08-17）：金币卡多对象模型落地，coin_count 变为求和计算属性，v6 存档不再持久化标量 |
| ~~`GameState.gold_dice` 标量骰子~~ | 已消灭（2026-08-17）：金骰 = counter 7100006（dump.cs:542529 + Add/SubCounter + 存档样本三重信号），计算属性落地 |
| `GameState.hand`/`rail_order` 独立手牌数组 | 原作手牌 = cards 中 bag=0 按 bagpos 排序；随金币卡批次一并评估 |
| `MethinksEngine` / `drop_card_on_methinks` 命名族 | 复刻期兼容接口；玩家可见概念统一为"思考"，方向定后重命名 |
| ~~弹簧积分器、透视/阴影 shader、SubViewport 双通道、ui_motion.gd~~ | 已于 2026-08-17 去 Balatro 批次删除（git 历史可恢复） |

## D. 缺失 ⬜（原作有、克隆无）

| 原作系统 | 证据入口 | 规模评估 |
| --- | --- | --- |
| after_story 后日谈播放 | `data/config/after_story/` + `AfterStoryNode` + `OverNewAfterStoryItemController.c` | 中（配置已定位，未审流程） |
| 笔记系统 | `Player_Note_JsonHandler.c` + NoteController 族（未审） | 未知，需普查 |
| 图鉴/画廊 | `gallery_cards.json` / `gallery_cg.json` + Gallery*Controller 族 | 中 |
| 向导演示宿主 | `wizard/` 配置 + WizardController（未审） | 中 |
| 音频全量 | `sfx_config.json`、`sfx_settle_card_new.json`、`sfx_npc_role_dub.json`、`over_music_config.json` | 小-中（配置在语料库未接） |
| 未接配置域 | `quest.json`、`upgrade.json`、`variable.json`、`ui.json`、`textstyle.json`、`imagestyle.json`、`dt`、`credits.json`、`mobile_help.json` | 逐域判断用途后接入或说明 |
| Live2D | 语料库 `live2d/` 已提取 | 大（既定策略：第一版静态图） |
| 背包/手牌位系统（bag/bagpos/BagIndex） | 存档字段双信号（`docs/ORIGINAL_SAVE_SCHEMA.md`） | 中（与金币卡/手牌模型联动） |
| 末日决战（end_open/is_armageddon/armageddon_rite_id） | 存档字段双信号；控制器未审 | 未知，需普查 |
| RNG 续航（random_cache） | 存档字段双信号 | 小-中 |
| 唯一性登记（only_cards/only_rites） | 存档字段双信号 | 小 |
| 生成计数（gen_cards/gen_tags） | 存档字段双信号 | 小 |
| 改名持久化（custom_rite_name/player_card_name） | 存档字段双信号（DSL 键已支持，持久化缺） | 小 |
| UI 引导标志族（sudan_box_show/story/prestige/deadline/helpbtn、once_new_rites_is_show） | 存档字段双信号 | 小 |
| 苏丹重抽恢复模型（times_per_round/times/recovery_round、sudan_card_init_life） | 存档字段双信号 + counter 常量 COUNTER_SUDAN_EXTRA_REDRAW 7100008（dump.cs:542531 + PlayerExtensions Add/Sub） | 小 |
| 回退配额 counter 化（COUNTER_BACK_TO_PREV 7100007；**存 global.json backToPrevRound**，9999=UNLIMIT_BACK_TO_PREV_TIMES；克隆现为局内 back_to_prev_left 标量） | dump.cs:542530 + PlayerExtensions GetCounter 0x6c5667 分支读 Common.get_Global + global.json 样本 | 中（需全局域承载） |
| 结局状态（success/over_reason）与 cached_event | 存档字段双信号 | 小 |
| global.json 全局域（回退配额/图鉴解锁/升级/任务/统计/overRecord） | `save_samples/global.json` 29 字段 | 中（部分依赖图鉴/升级系统） |
| 成就面板 | steam_achievement 空实现 | 可选 |

## 普查程序（如何扩展本表）

1. 从 `engine_spec/dump.cs` 提取运行时类清单（Controller / Manager / Panel 优先，JsonHandler 指路数据域）。
2. 每个类归入四状态之一，登记证据指针（文件 + RVA/行号）；查无克隆对应物即入 ⬜。
3. 每个复刻批次收尾时更新所 touched 的行；每个大阶段做一次 dump.cs 增量普查。
4. 表中新增 ✅ 必须附双信号；只有单信号时写 🟡 并注明缺口。

## 对拍台（验收裁判）

- **资产**：语料库 `save_samples/`（`auto_save.json`、`save_slot_000.json`、`global.json`、`user_archive.json`）= 原作真实存档，明文 JSON。
- **阶段 1 ✅（2026-08-17）**：schema 全解码——Player 60 字段与 dump.cs 双信号吻合，零未知零类型不符；映射表与工具落地（`sim/original_save_schema.gd` + `tools/export_save_diff.gd` + `tests/test_save_diff_harness.gd`，mapped 11 / semantic 11 / missing 38）；快照文档 `docs/ORIGINAL_SAVE_SCHEMA.md`。结构发现：金币=卡 2000029 堆叠（双信号）、骰子疑 counter、手牌=bag/bagpos、仪式槽位内嵌嵌套、UI 队列不持久化、回退双轨、random_cache。
- **阶段 2（下一步）**：导入桥——原作存档 → 克隆 GameState 内存态（嵌套↔扁平转换，missing 字段登记丢弃清单）→ 导出 v5 → 同刻值对拍。达成后涉及状态的批次验收 = GUT 全绿 + 对拍零差异（或差异均有原作语义解释）。
- **远期**：固定种子 trace 对拍（同一操作脚本下原作 vs 克隆的事件/结算日志序列）。
