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
| `PlayerExtensions.GetCounter` 0x38ce70 特殊分支（7000105 金币/7000104 门客 = 从 cards+rites 派生求和；7100007 回退配额读 Global） | `game_state.gold_total()`（hand+slot 求和）、`game_state.get_counter` 7100007 分支读 `global_state` | 金币总额含仪式槽；配额读全局域 |
| dump.cs:542529 常量表 + `PlayerExtensions` Add/SubCounter（**金骰 = COUNTER_GOLD_DICE 7100006**；额外重抽 = 7100008；回退 = 7100007 存 global，9999=无限） | `game_state.gold_dice` 计算属性（counter 存储 + 7100006 非负门 + v6 去标量） | 金骰已修；7100007 已修（见下行）；7100008 见 ⬜ |
| `Global`（global.json 跨局域）+ `PlayerExtensions` SetCounter 0x38f2d0 7100007 分支（无条件非负 clamp 写 `Global.backToPrevRound`）+ `Datapool.c` StartGame L4497 新局重置 9999 + CorrectPlayerData L4130-4134 档案恢复 | `sim/global_state.gd` GlobalState（user://global.json；backToPrevRound/roundRollback 先行）+ `game_state.set_counter` 7100007 分支 + `setup_new_run` 重置 9999（`apply_resources=false` 供菜单新局延迟到叙事者选择）+ `SaveSystem.load_user_archive` 档案索引恢复 | 2026-08-18 修复；其余 global.json 字段见 ⬜ |
| `GameController` OnPrevRound 0x554f80（min_round 门 + GetBackToPrevCount 配额门 + 9999 不消耗 + IsValidRoundEnd + 确认框）→ PrevRoundInternal 0x555570（UseBackToPrev 先消耗 → `Global.roundRollback = 2` → SaveGlobal → LoadRound(round-1)）；OnBeginRound 0x5537b0 置 rollback=1 | `sim/round_loop.gd` `back_to_prev_round_end`（门控 → 消耗 → 标记 → 全局保存 → 快照恢复；配额在全局域故快照恢复不回滚消耗）+ `advance_day` 置 ROLLBACK_TO_BEGIN | 消耗先于恢复，与原作顺序一致 |
| `DatapoolExtensions` SaveRoundBegin 0x3f9050 / SaveRoundEnd 0x3f9120（先 SavePlayer(auto_save)，再写 `round_{N}.json` / `round_{N}_end.json`）+ LoadRound 0x3f8fa0 / LoadRoundEnd 0x3f8e70 / IsValidRoundEnd 0x3f8d50；LoadUserArchive 0x417350 删除 `round_*.json` | `SaveSystem.save/load_round[_end]` + `RoundLoop` 磁盘回退兜底 + 档案加载清理轮次文件；内存快照仅作同进程缓存 | 2026-08-18 批次 F；重启后仍可回退，文件名和双写顺序对齐 |
| `PlayerExtensions.SetDifficulty` 0x38f530（金骰 = 当前 + 新难度 gold_dice_count **加法**；回退配额 = 当前 − 9999 + 新难度 back_to_prev_round_count；redraws 重置） | `game_state._apply_difficulty_resources()`（新局与中途切换共用；`apply_difficulty`） | 离开无限档=重置为新配额；有限切有限=clamp 归零；切回无限档=保留余量（防刷） |
| `TimingRoundBase` 键 = 实例 +0x20 **int**（player+0x128 字典键；样本全部 = 事件 id×100，TimingRoundBase.c IsValid 0x465d30/OnStart 0x4660d0） | `event_runtime._timing_key` = event_id*100（2026-08-18 由导入桥发现偏差后修正；1381 个回合时机事件全单桶序号 0；旧字符串键 deserialize 迁移） | 多桶事件的序号分配未验证（当前无此配置） |
| 原作存档 Player 60 字段（dump.cs:391488 × save_samples 双信号） | `sim/original_save_importer.gd` 导入桥（difficulty 1 基 -1；cards[i]↔s{i+1}；装备嵌套→扁平 equipped 链；min_round 显式持久化） | 同刻对拍 25/25；仅 drawn_round 与洗牌后牌堆顺序作显式近似登记 |
| `GameController.GenSudanCard` 0x54f6f0 L3656-3662（出生 `set_life(模板 card_vanishing − player.sudan_card_init_life)` 抢跑）+ `UpdateSingleCard` b__1 0x572420（每日 life+1，`life>=card_vanishing` 且无槽位庇护即 DoVanish 处刑）+ `UpdateSudanLife` 0x55aeb0（倒计时显示 = vanish − life，可负） | `round_loop.draw_weekly_sudan`（头起步）+ `_update_card_lives`（苏丹并入通用死亡，days_left 为 vanish−life 镜像）+ rebirth 按模板 | 2026-08-18 批次 D；困难档 7−5=2 抢跑=5 天；b__1 老化豁免标签字面量未反查（无配置命中） |
| `RedrawSudanCard` 0x5558b0 L3823-3842（循环 player+0x68 次 GenSudanCard；新卡 `set_life(弃卡 life)` 继承剩余期限；弃卡 life 归 0 后 `Insert(Random.Range(0,count))` 回池）+ `GenSudanCard` 抽取 = sudan_card_pool **先 Shuffle（sudan_shuffle）再 RemoveLast** | `round_loop.use_redraw`（carried_life = 弃卡实例 life）+ `SudanCards.draw` pop_back 尾抽 | 2026-08-18 批次 D；牌序因每次 Shuffle 无意义，多重集对拍为正确粒度 |
| 手牌位系统：Card `bag`@0x48（包页 id）/`bagpos`@0x4c（页内 1 基位置，0=未摆放）+ `Player.BagIndex`@0x150（当前查看页）+ `IsCurrentHandCard` 0x3826a0（bag==BagIndex 且三标签）+ `UpdateHandCardPos` 0x559a70 L1060-1097（b__6 链内、回合开始事件后：收集当前页手牌→排序→`set_bagpos(i+1)` 压缩 1..N）+ GenCoin `set_bagpos(1)` 金币前置 + GenSudanCard `set_bag(BagIndex)` | `CardInstance.bag/bag_pos`（v7 起持久化）+ `round_loop.update_hand_card_pos`（日终压缩，克隆单页 bag=0）+ `_grant_gold` 前置 + 抽卡 set_bag | 2026-08-18 批次 E；三标签名无法从元数据反查（字面量间接寻址），留档 |

## B. 近似 🟡（行为近似承载，缺背书或部分覆盖）

| 克隆落点 | 缺口 |
| --- | --- |
| `sim/game_state.gd` v7 存档（serialize） | 原作存档 schema 已全解码（60 字段，`docs/ORIGINAL_SAVE_SCHEMA.md` + `sim/original_save_schema.gd`）；**阶段二导入桥已落地**（`sim/original_save_importer.gd` + `tools/export_save_diff.gd --bridge`，语料 auto_save 25/25 同刻对拍全过）；续局行为对拍待实机样本 |
| `GameState.pending_operations` / `delayed_operations` | 原作 Promise/Pop 队列模型的宿主等价物；事件日内 Promise 阻塞语义留档未对齐 |
| `sim/condition.gd` AttrExprParser | 文法已对齐（四则/e() 敌方/sN.tag/counter.N）；解析器宿主为自制递归下降，非原作方法映射 |
| `ui/game_audio.gd` GameAudio | 仅 main/tutorial BGM + 部分音效；拖放音、弹窗出现音、BGM 分层（level2/3）、结局 BGM、`sfx_*.json` 全量缺 |
| `ui/begin_guide_bar.gd` 引导条 | 文案/键族/存档对齐；`WizardController` 完整演示宿主与 magic_sudan 演出缺，5310004 后序列未实机校对 |
| `ui/game_screen.gd` 仪式图钉点位 | 结构依据 MapController；精确坐标需实机对照微调 |
| 桌面地图计数小牌（count chit） | 仍为样式盒，待原作对位 |
| 苏丹卡视觉（稀有边框、倒计时红光） | 部分接入；细节原作化未完成 |

## C. 自制 ❌（原作无对应，待消灭/降级）

| 克隆物 | 处置 |
| --- | --- |
| `set_world_scene_blocker`、`world_spawn_id`、`world_position_ratio` 存档字段 | 横版世界探针遗留；清理需评估 v5 存档兼容（GAP 留档） |
| ~~`GameState.coin_count` 标量金币~~ | 已消灭（2026-08-17）：金币卡多对象模型落地，coin_count 变为求和计算属性，v6 存档不再持久化标量 |
| ~~`GameState.gold_dice` 标量骰子~~ | 已消灭（2026-08-17）：金骰 = counter 7100006（dump.cs:542529 + Add/SubCounter + 存档样本三重信号），计算属性落地 |
| ~~`GameState.back_to_prev_left` 局内回退配额标量~~ | 已消灭（2026-08-18）：配额 = counter 7100007 存全局域 GlobalState（原作 Global.backToPrevRound），v7 局内存档不再携带；快照恢复后"补回预算"hack 一并删除（配额天然在恢复范围外） |
| ~~`event_runtime._timing_key` 字符串键 `"timing:event_id"`~~ | 已消灭（2026-08-18，导入桥发现）：改为原作 int 键 event_id×100（TimingRoundBase+0x20 int 直址 player+0x128），旧键加载时迁移 |
| `GameState.hand`/`rail_order` 独立手牌数组 | 部分收敛（2026-08-18 批次 E）：CardInstance 已承载 bag/bag_pos 并由日终压缩维护（bag_pos = 手牌序+1 不变式）；数组彻底退役仍阻塞于 IsHandCard 三标签名未反查（成员资格判据）与包页 UI 缺失 |
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
| ~~背包/手牌位系统（bag/bagpos/BagIndex）~~ | 已落地（2026-08-18 批次 E）：CardInstance.bag/bag_pos 持久化 + 日终压缩 + 导入桥透传与对拍（24 项）；三标签资格判据与多页包 UI 未做（三标签名留档） | — |
| 末日决战（end_open/is_armageddon/armageddon_rite_id） | 存档字段双信号；控制器未审 | 未知，需普查 |
| RNG 续航（random_cache） | 存档字段双信号 | 小-中 |
| ~~激活苏丹卡的期限存档承载~~ | 已解（2026-08-18 批次 D）：期限 = 卡寿命模型（出生抢跑 + 每日 life+1 + 模板 card_vanishing 死亡），存档承载即 Card.life 本身；导入桥 days_left = vanish−life 精确恢复，仅 drawn_round 仍近似（难度中途切换后不可反推） | — |
| ~~原作苏丹抽牌序（sudan_pool_cards 顺序语义）~~ | 已解（2026-08-18 批次 D）：sudan_shuffle 开启时每次抽取先 Shuffle 再 RemoveLast，顺序无意义；克隆 pop_back 尾抽对齐 | — |
| 唯一性登记（only_cards/only_rites） | 存档字段双信号 | 小 |
| 生成计数（gen_cards/gen_tags） | 存档字段双信号 | 小 |
| 改名持久化（custom_rite_name/player_card_name） | 存档字段双信号（DSL 键已支持，持久化缺） | 小 |
| UI 引导标志族（sudan_box_show/story/prestige/deadline/helpbtn、once_new_rites_is_show） | 存档字段双信号 | 小 |
| 苏丹重抽恢复模型（times_per_round/times/recovery_round、sudan_card_init_life） | 存档字段双信号 + counter 常量 COUNTER_SUDAN_EXTRA_REDRAW 7100008（dump.cs:542531 + PlayerExtensions Add/Sub） | 小 |
| 结局状态（success/over_reason）与 cached_event | 存档字段双信号 | 小 |
| global.json 其余字段（gameStatistics/doneEvent/doneRite/showedPrompt/choosedOption/showedGalleryCards/图鉴/升级/任务/overRecord/meta counter） | `save_samples/global.json` 29 字段；承载容器 GlobalState 已落地（backToPrevRound/roundRollback 已接） | 中（部分依赖图鉴/升级系统） |
| `[back_to_prev_count]` 文本占位符（Datapool.__c b__389_6 走 GetBackToPrevCount） | 原作配置中未发现该 token 的使用实例，token 拼写无法从语料确认 | 暂缓（不猜测命名） |
| ~~回退快照持久化（Datapool 轮次文件 + IsValidRoundEnd + LoadController.LoadRound）~~ | 已落地（2026-08-18 批次 F）：`round_{N}.json` / `round_{N}_end.json` 双边界持久化、有效性门、磁盘加载刷新 continue、档案恢复清理旧时间线；内存 round_snapshots 降为同进程缓存 | — |
| ~~仪式面板“恢复上次投放”（Player.last_round_rite_data）~~ | 已落地（2026-08-18 批次 G）：`OnConfirm` 按 Rite.id 记录手动槽 guid 的 `{id,count}`，`OnLastState` 按卡牌可用量与当前槽条件逐槽恢复；存读档与原作导入桥均承载。证据：RitePanelController.c 0x58f1c0 / 0x58fdf0 + dump.cs Player@0x158、LastCardData@0x10/@0x14、RiteNode.Slot.open_adsorb@0x20 | — |
| RoundRollbackType.BACK_TO_PREV_BEGIN(3) 的写点 | dump.cs:6186 枚举存在，写点未定位（LoadRoundBegin 疑似） | 小（待双信号） |
| 成就面板 | steam_achievement 空实现 | 可选 |

## 普查程序（如何扩展本表）

1. 从 `engine_spec/dump.cs` 提取运行时类清单（Controller / Manager / Panel 优先，JsonHandler 指路数据域）。
2. 每个类归入四状态之一，登记证据指针（文件 + RVA/行号）；查无克隆对应物即入 ⬜。
3. 每个复刻批次收尾时更新所 touched 的行；每个大阶段做一次 dump.cs 增量普查。
4. 表中新增 ✅ 必须附双信号；只有单信号时写 🟡 并注明缺口。

## 对拍台（验收裁判）

- **资产**：语料库 `save_samples/`（`auto_save.json`、`save_slot_000.json`、`global.json`、`user_archive.json`）= 原作真实存档，明文 JSON。
- **阶段 1 ✅（2026-08-17）**：schema 全解码——Player 60 字段与 dump.cs 双信号吻合，零未知零类型不符；映射表与工具落地（`sim/original_save_schema.gd` + `tools/export_save_diff.gd` + `tests/test_save_diff_harness.gd`，mapped 11 / semantic 11 / missing 38）；快照文档 `docs/ORIGINAL_SAVE_SCHEMA.md`。结构发现：金币=卡 2000029 堆叠（双信号）、骰子疑 counter、手牌=bag/bagpos、仪式槽位内嵌嵌套、UI 队列不持久化、回退双轨、random_cache。
- **阶段 2 ✅（2026-08-18）**：导入桥——原作存档 → 克隆 GameState → v7 payload → 同刻值对拍；语料 auto_save **25/25** 全过，差异按 converted / approximated / dropped 防静默登记。此后涉及状态的批次验收 = GUT 全绿 + 对拍零差异（或差异均有原作语义解释）。
- **远期**：固定种子 trace 对拍（同一操作脚本下原作 vs 克隆的事件/结算日志序列）。
