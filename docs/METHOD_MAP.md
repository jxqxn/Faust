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

## B. 近似 🟡（行为近似承载，缺背书或部分覆盖）

| 克隆落点 | 缺口 |
| --- | --- |
| `sim/game_state.gd` v5 存档（to_save_dict） | 原作 Player 序列化未解码对拍；`save_samples/` 真实存档尚未成为验收裁判（见「对拍台」） |
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
| 成就面板 | steam_achievement 空实现 | 可选 |

## 普查程序（如何扩展本表）

1. 从 `engine_spec/dump.cs` 提取运行时类清单（Controller / Manager / Panel 优先，JsonHandler 指路数据域）。
2. 每个类归入四状态之一，登记证据指针（文件 + RVA/行号）；查无克隆对应物即入 ⬜。
3. 每个复刻批次收尾时更新所 touched 的行；每个大阶段做一次 dump.cs 增量普查。
4. 表中新增 ✅ 必须附双信号；只有单信号时写 🟡 并注明缺口。

## 对拍台（验收裁判，建设中）

- **资产**：语料库 `save_samples/`（`auto_save.json`、`save_slot_000.json`、`global.json`、`user_archive.json`）= 原作真实存档。
- **阶段 1（未开始）**：解码原作存档 schema——Player 字段定义在 `dump.cs`，序列化规则在各 `Player_*_JsonHandler.c`。
- **阶段 2**：写对照导出器：原作存档字段 vs 克隆同局状态字段，逐项 diff；此后涉及状态的批次验收 = GUT 全绿 + 对拍零差异（或差异均有原作语义解释）。
- **远期**：固定种子 trace 对拍（同一操作脚本下原作 vs 克隆的事件/结算日志序列）。
