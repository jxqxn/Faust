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
| `GameController.AddRite/AddRitePin` + `RiteController.Init` + `RitePosition.AddRite` + `Player.pins` + `RiteResultPanelController <Settlement>b__8` + `GameScene.unity` + `{RiteNew,RitePin}.prefab` | `ui/map_controller.gd` + `GameState.rite_pins` + v8 存读档/导入桥 | 2026-08-20 批次 U：地点节点、全部 `RitePosition` 子坐标、`area:N` / `area:[N,M]` 最少占用选择（并列低号）、同子点 +100 横向叠放；live Rite = runtime-UID、可点击 `RiteNew` `(0,-18)/123×133` bound；`Player.pins` = config-ID、有序去重、非交互 `RitePin` `(0,-17.6)/123×133` Icon；结算顺序为先删 live Rite 再写 `final_pin` endpoint。见 `docs/ui_layout/MapController.md` |
| `StartScene.unity` / `GameScene.unity` 场景树（GameObject/RectTransform/Sprite GUID） | `ui/main_menu.gd` 等第七波接线 | UI 原作化的证据法 |
| `CardInfoNew.prefab`（2510×1077 居中面板全真值表）+ `CardInfoNewController.c` Show 0x537000（Name=GetName、Title=CardNode.title@0x20、Content=Card.custom_text@0x58‖CardNode.text@0x28 + Utils.ProcessPlaceholders、RareText=CARD_RARE_{1..4}、TypeIcon=card_type_*、MainIcon=GetPic/GetSudanFullIcon）+ `CardNode`/`Card` 字段 + textstyle.json（CARD_INFO_NAME 40..60 / DESC 18..40 / TYPE 30 / RARE_TEXT 60 / TAG_TITLE 40）+ ui.json（CARD_RARE_1..4、CARD_INFO_STATE_TITLE/ATTRIBUTE_TITLE、CARD_INFO_HELP_*） | `ui/card_info_view.gd`（批次 AF 2026-08-22；GameScreen `_source_overlay_layer` 内源画布，_unity_rect 把 anchors/pos/sizeDelta/pivot 精确换算为 Godot Rect2） | 旧自制 690×340 暗盒已删除（自制详情面板也随之删除）；🟡 登记：TagNode 属性/标签分组旗标（can_visible/can_nagative_and_zero 组合）未精确验证，克隆沿用现有属性/标签数据视图；RareIcon 稀有图标列表（Common+0x48+0xe0 序）未定位；Equips 区内容（已装配列表 vs 可装列表）未知；帮助气泡文案为 zhTW 转简体。**2026-08-22 批次 AK 后澄清**：`CardAttribute.prefab` = 纯文本行（60×40、fs30、全幅 Outline、**无徽记图**）——批次 AJ 留档的"属性徽记图标"系误解（`Resources/image/tags.png` 图集属其他列表，tag_N 帧所在待定位）；`TagInfo/StateBar` = "状态" 标题（fs40 100×50）+ `CardStateTag.prefab`（43×43 可点图标按钮：root Image 43² + Icon 43² + Outline 全幅+10、LayoutElement 43²、Selectable）行 + Left 分隔线（rite_log_sperator），状态语义（哪些状态、点击行为）无控制器背书 ⬜ |
| PromptNew 通用事件提示浮层（GameScene MainUI/Prompt；克隆 `_event_overlay` 旧 1280 暗盒待迁） | 未开工（2026-08-22 普查）：`Resources/prefab/PromptNew.prefab` 全真值表 → `docs/ui_layout/PromptNew.md`；`PromptController.Show 0x58a020`（Utils.ProcessPlaceholders 后 set_Text + **ForceRebuildLayoutImmediate**）+ `PromptControllerBase.ShowInternal 0x589890`（Full=config `full` 字段 sprite 装载 0x589d60 TrySetupFull + IconGroup 3 槽 PromptIconController.SetIcon 按内容项填充）+ `OptionNew/OptionNewItem.prefab`（选项行）+ `OptionController 0x576a40` | 2026-08-23 用户已提供**事件选择实测截图**（苏丹雅兴 3 选项 / 贵族品级 4 选项 / 胡同口事件，16:9 全窗）——结构确认：标题/正文 + 全宽选项行 + 右侧立绘探出 + 底部 A/AUTO 行。**OptionBG 高度 = 运行时布局组计算（ForceRebuildLayoutImmediate）静态不可解，作 🟡 常量（截图量测归一化 + 真值表），用户整窗原图后单点替换** | 中·高（事件主浮层，交互核心面） |
| `GameController.GenCard` 0x54f650 → `PlayerExtensions.AddCard` 0x38b620 + `GenCoin.c Do` 0x510b40（金币 = 手牌金币卡 2000029 **多对象** count 之和；每 op 新建对象、count=操作值可为负、bagpos=1 前置、OnCardBorn） | `sim/game_state.gd` coin_count 计算属性 + `_grant_gold`/`_remove_gold`、`sim/result.gd` coin 键、v5→v6 存档迁移 | 2026-08-17 修复；多对象扣除顺序未验证（cost 支付链未审计，现最大面额优先） |
| `CostCondition.IsSatisfied` 0x3f6160（花费判定读卡对象 count，card+0x20；判定时按 player.cards 枚举序选定付款卡清单记入 `ConditionContext.need_cost_cards`） | `sim/condition.gd` 金币/coin 条件（经 coin_count 求和属性）、`game_state._remove_gold`（uid 升序=枚举序，末对象部分扣减等价于移除找零；付款执行体未反编译留档） | 读模型与支付顺序一致 |
| `PlayerExtensions.GetCounter` 0x38ce70 特殊分支（7000105 金币/7000104 门客 = 从 cards+rites 派生求和；7100007 回退配额读 Global） | `game_state.gold_total()`（hand+slot 求和）、`game_state.get_counter` 7100007 分支读 `global_state` | 金币总额含仪式槽；配额读全局域 |
| dump.cs:542529 常量表 + `PlayerExtensions` Add/SubCounter（**金骰 = COUNTER_GOLD_DICE 7100006**；额外重抽 = 7100008；回退 = 7100007 存 global，9999=无限） | `game_state.gold_dice` 计算属性（counter 存储 + 7100006 非负门 + v6 去标量）；`round_loop.use_redraw` 的普通配额耗尽后消费 7100008 | 金骰、7100007、7100008 均已落地 |
| `Global`（global.json 跨局域）+ `PlayerExtensions` SetCounter 0x38f2d0 7100007 分支（无条件非负 clamp 写 `Global.backToPrevRound`）+ `Datapool.c` StartGame L4497 新局重置 9999 + CorrectPlayerData L4130-4134 档案恢复 | `sim/global_state.gd` GlobalState（user://global.json；backToPrevRound/roundRollback 先行）+ `game_state.set_counter` 7100007 分支 + `setup_new_run` 重置 9999（`apply_resources=false` 供菜单新局延迟到叙事者选择）+ `SaveSystem.load_user_archive` 档案索引恢复 | 2026-08-18 修复；其余 global.json 字段见 ⬜ |
| `GameController` OnPrevRound 0x554f80（min_round 门 + GetBackToPrevCount 配额门 + 9999 不消耗 + IsValidRoundEnd + 确认框）→ PrevRoundInternal 0x555570（UseBackToPrev 先消耗 → `Global.roundRollback = 2` → SaveGlobal → LoadRound(round-1)）；OnBeginRound 0x5537b0 置 rollback=1 | `sim/round_loop.gd` `back_to_prev_round_end`（门控 → 消耗 → 标记 → 全局保存 → 快照恢复；配额在全局域故快照恢复不回滚消耗）+ `advance_day` 置 ROLLBACK_TO_BEGIN | 消耗先于恢复，与原作顺序一致 |
| `DatapoolExtensions` SaveRoundBegin 0x3f9050 / SaveRoundEnd 0x3f9120（先 SavePlayer(auto_save)，再写 `round_{N}.json` / `round_{N}_end.json`）+ LoadRound 0x3f8fa0 / LoadRoundEnd 0x3f8e70 / IsValidRoundEnd 0x3f8d50；LoadUserArchive 0x417350 删除 `round_*.json` | `SaveSystem.save/load_round[_end]` + `RoundLoop` 磁盘回退兜底 + 档案加载清理轮次文件；内存快照仅作同进程缓存 | 2026-08-18 批次 F；重启后仍可回退，文件名和双写顺序对齐 |
| `PlayerExtensions.SetDifficulty` 0x38f530（金骰 = 当前 + 新难度 gold_dice_count **加法**；回退配额 = 当前 − 9999 + 新难度 back_to_prev_round_count；重抽只改 `times_per_round` 与 `card_init_life`） | `game_state._apply_difficulty_resources()`（新局与中途切换共用；`apply_difficulty`） | 离开无限档=重置为新配额；有限切有限=clamp 归零；切回无限档=保留余量（防刷）；本周期已用次数与恢复周期不改 |
| `TimingRoundBase` 键 = 实例 +0x20 **int**（player+0x128 字典键；样本全部 = 事件 id×100，TimingRoundBase.c IsValid 0x465d30/OnStart 0x4660d0） | `event_runtime._timing_key` = event_id*100（2026-08-18 由导入桥发现偏差后修正；1381 个回合时机事件全单桶序号 0；旧字符串键 deserialize 迁移） | 多桶事件的序号分配未验证（当前无此配置） |
| 原作存档 Player 60 字段（dump.cs:391488 × save_samples 双信号） | `sim/original_save_importer.gd` 导入桥（difficulty 1 基 -1；cards[i]↔s{i+1}；装备嵌套→扁平 equipped 链；min_round、苏丹重抽 profile、终局结果、cached_event、HUD 标志族与 `pins` 显式持久化） | 同刻对拍 46/46；仅 drawn_round 与洗牌后牌堆顺序作显式近似登记 |
| `GameController.GenSudanCard` 0x54f6f0 L3656-3662（出生 `set_life(模板 card_vanishing − player.sudan_card_init_life)` 抢跑）+ `UpdateSingleCard` b__1 0x572420（每日 life+1，`life>=card_vanishing` 且无槽位庇护即 DoVanish 处刑）+ `UpdateSudanLife` 0x55aeb0（倒计时显示 = vanish − life，可负） | `round_loop.draw_weekly_sudan`（头起步）+ `_update_card_lives`（苏丹并入通用死亡，days_left 为 vanish−life 镜像）+ rebirth 按模板 | 2026-08-18 批次 D；困难档 7−5=2 抢跑=5 天；b__1 老化豁免标签字面量未反查（无配置命中） |
| `RedrawSudanCard` 0x5558b0 L3823-3842（循环 player+0x68 次 GenSudanCard；新卡 `set_life(弃卡 life)` 继承剩余期限；弃卡 life 归 0 后 `Insert(Random.Range(0,count))` 回池）+ `GenSudanCard` 抽取 = sudan_card_pool **先 Shuffle（sudan_shuffle）再 RemoveLast** | `round_loop.use_redraw`（carried_life = 弃卡实例 life）+ `SudanCards.draw` pop_back 尾抽 | 2026-08-18 批次 D；牌序因每次 Shuffle 无意义，多重集对拍为正确粒度 |
| 手牌位系统：Card `bag`@0x48（包页 id）/`bagpos`@0x4c（页内 1 基位置，0=未摆放）+ `Player.BagIndex`@0x150（当前查看页）+ `IsCurrentHandCard` 0x3826a0（bag==BagIndex 且三标签）+ `UpdateHandCardPos` 0x559a70 L1060-1097（b__6 链内、回合开始事件后：收集当前页手牌→排序→`set_bagpos(i+1)` 压缩 1..N）+ GenCoin `set_bagpos(1)` 金币前置 + GenSudanCard `set_bag(BagIndex)` | `CardInstance.bag/bag_pos`（v7 起持久化）+ `round_loop.update_hand_card_pos`（日终压缩，克隆单页 bag=0）+ `_grant_gold` 前置 + 抽卡 set_bag | 2026-08-18 批次 E；三标签名无法从元数据反查（字面量间接寻址），留档 |

## B. 近似 🟡（行为近似承载，缺背书或部分覆盖）

| 克隆落点 | 缺口 |
| --- | --- |
| `sim/game_state.gd` v8 存档（serialize） | 原作存档 schema 已全解码（60 字段，`docs/ORIGINAL_SAVE_SCHEMA.md` + `sim/original_save_schema.gd`）；**阶段二导入桥已落地**（`sim/original_save_importer.gd` + `tools/export_save_diff.gd --bridge`，语料 auto_save 46/46 同刻对拍全过，含 Player.pins）；续局行为对拍待实机样本 |
| `GameState.pending_operations` / `delayed_operations` | 原作 Promise/Pop 队列模型的宿主等价物；事件日内 Promise 阻塞语义留档未对齐 |
| `sim/condition.gd` AttrExprParser | 文法已对齐（四则/e() 敌方/sN.tag/counter.N）；解析器宿主为自制递归下降，非原作方法映射 |
| `ui/game_audio.gd` GameAudio | 仅 main/tutorial BGM + 部分音效；拖放音、弹窗出现音、BGM 分层（level2/3）、结局 BGM、`sfx_*.json` 全量缺 |
| `ui/begin_guide_bar.gd` 引导条 | 文案/键族/存档对齐；`WizardController` 完整演示宿主与 magic_sudan 演出缺，5310004 后序列未实机校对 |
| `MapController.SetRitesPosition/SetPos` + `RefreshRitePinLines` | 批次 U 已拆出 live `RiteNew/RiteController` 卡层与 `Player.pins` endpoint；批次 V 已补 RiteNew 123×133 bound 的跨点碰撞与 bg 外整位回退（只测 bound 中心、不钳边）；批次 W 已接 8 个原作 `RiteNode.from_pins`：仅已完成 pin 可作起点、终点可为 pin 或 live RiteNew、键为 `(target rite-id, source pin-id)`、原始二次 Bézier/保留区/虚线/箭头参数直读配置。不得把 SetPos 或 from_pins 起点误套到 RitePin 之外的运行时卡 |
| `ui/map_controller.gd` `MapController.SetRitesPosition` / `SetPos` / `RefreshRitePinLines` | `LocationController.RitePosition` 子点、范围选位与同点叠放已精确；批次 V：NORMAL/`[` 组按屏幕中心排序后两两推开，固定特殊仪式只避开该组；候选出 bg 则恢复旧位。批次 W：重建线层等价 `CleanUnexistsPinLines`，且不因 live source 或无关 pin 合成边；已覆盖的 8 条配置同为 50 段、20 像素、起始保留 .08、100/40 箭头、RGBA(207,187,161,255)、虚线。|
| 苏丹卡视觉（稀有边框、倒计时红光） | 部分接入；细节原作化未完成 |
| `ui/*.gd` 旧屏坐标（game_screen / rite_view / card_widget / begin_guide_bar / game_over / ESC·档案 overlay） | **2026-08-18 批次 P 起列入 UI 布局对拍**：视口已切原作 3840×2160 设计空间（旧 `window/size/viewport=Vector2i(...)` 键无效、从未生效，游戏一直跑在引擎默认 1152×648）。**批次 Q 已将 `game_screen` 的桌面 chrome 与手牌带移出 LegacyLayer**；**批次 R 已把桌面地图换为 `ui/map_controller.gd`**；**批次 X 已将 `rite_view` 迁至 `GameScreen.SourceOverlayLayer`**：`RitePanelShow` 固定 3840×2160 源画布，`Position/bg` 4096×2148、`RitePanelTitle` 1148×1124、`CardSlot` 272×496 都直接回放 prefab；`rite_template` 的 `bg_pos/title_pos/slots.{pos,scale,rotation_z}` 按 `RitePanelShowController` 的实际坐标链写入，旧“网格 + 手牌安全区”已删。**批次 Y 已将 `card_widget` 与 `GameScene/MainUI/Hand` 改为源码直连**：CardNew `194×422`、SudanCard `185×330` 分型；Hand 的解析矩形 `516.7349,1726 / 2723.264×430` 和 `HandCardsController` 的 Space=10 / minVisibleWidth=20 直接落地，移除全局 3× mockup 缩放。**批次 Z 已删除无原作桌面对应、且无实际发射点的 `rite_selector` 自制分支**；桌面仪式入口仅保留 `MapController` 的 `RiteNew/RiteController -> RitePanelShow` 直接链。**批次 AA 已将 BeginGuide `Default` 迁至源 3840×2160 坐标，回放 1200×460 面板、400×400 溢出图标、75px 文本和 80px Close**；**批次 AB 已将结局从 LegacyLayer 的自制单页迁到 `OverNewController` 结构：Step1 标题 → 配置 CG → Step3 主菜单；`DoNext` 的 Story/AfterStory 枚举与分支保留，但 after_story 播放宿主仍缺。**批次 AC 已将 ESC 从 LegacyLayer 自制菜单迁至 `ESCGameController` 结构：源 `ESCPanel` 2×根、Mask、1021px ButtonGroup、四个激活项与 `Return/EndGame/MainMenu` 调用链；`NewGame` 保持 prefab 禁用。**批次 AD 已接 `ESCGameController.OnSettings -> SettingsController.ShowSettings(false)`：`SettingsPanel` 2×根、1788×1200 `PanelBG`、四个源 dropdown、音乐/音效 0–100 slider+独立 ON/OFF、数据收集/主播配置和 KeyMap 入口均按 Prefab 真值表重建；音量/开关经 `GameApplication` 等价应用偏好持久化，不进入 Player 存档。平台显示/语言/分辨率/字体和 KeyMap 的 Godot 宿主尚缺，仍显式禁用。**批次 AE 已将手工档案从 LegacyLayer 迁到 `UserArchiveController` 结构**：全屏 3840×2160 `UserArchive`、左侧 28% 信息栏、右侧滚动档位、固定 50 个 2760×240 的 `UserArchiveItem`（空位也显示）、覆盖确认 → 1–20 字 `UserArchiveNameInput`、改名只走 `Datapool.UpdateUserArchive` 等价索引更新而不重写玩家档。`bg_1`/按钮/卷轴原始贴图未从语料导出，保留源几何与逻辑载体，不自制替图。**批次 AJ 按原作运行时截图对拍修正卡牌详情内容行**：属性行顺序改为 体魄/魅力/智慧/**战斗**/社交/支持（原文 cfg 2000001 与截图一致：战斗在社交前；旧实现是社交在前）；标签行改为**纯名称**无数值（截图：男性 贵族 主角 已拥有；旧实现显示"名 值"）。🟡：属性徽记图标（tag_N 精灵资源未独立导出为纹理，仅 Resource/image/*.asset 存在）留待资源提取。**批次 AI 修正声望条槽位几何**：`_build_prestige_strip` 六个槽按 GameScene 真值表 `MainUI/Prestige/710000N` 行的 anchor/pivot 混合（7100001 为 (0,1)+(−6.5)，其余 (0,0)+各 y；pivot 恒 (0.52,0.94)）用 pivot 折叠后的左上角矩形摆放（−80.12/−8.62 … 751.88/43.88）。旧实现把 authored `pos` 当左上角，六槽位置全错（批次 P 时代的未对拍偏差）。补 710000N 勋章贴图与计数标签（宿主视图 🟡，原作计数走 Image/Count 精灵）。**批次 AH 已把改名提示迁至 `ChangeNameView`（`ui/change_name_view.gd`，`GameScreen._source_overlay_layer`）**：`PromptChangeName` 源几何——PromptBG 2534.4×220 居中（prompt_bg）、"修改名称"标题 fs40、InputField 826×90（input_bg，占位符"请输入名称" fs50，`PromptChangeNameController.IsValidName 0x584de0` 的 **1–20 字符**上限——旧克隆 max_length=32 是偏差，一并修正）、Content Invalid Prompt 324×48 校验错误行、Icon 471×1028 卡立绘（(1,0)(−274,66)）、Border decorate 236×324、Confirm rite_op_confirm 325×158、Cancel rite_op_cancel 168×158+"取消" fs24；控制器无显式尺寸写（高度为 ContentSizeFitter PreferredSize，语料无法静态解出）→ **🟡 登记：PromptBG 高度用 220 宿主常量**，子几何全部走 authored 锚点数学，后续实机样本可只替换该常量；i18n `PROMPT_CHANGE_NAME_TITLE/_INPUT_PLACEHOLDER`（zhTW→简体）。**批次 AG 已接桌面帮助**：`GameScreen` 新增 `MainHelpTrigger`（help_button 88×91，top-right pivot (0.5,1) pos (−70,−143.5)，z=50 位于局部模态之下、随 `Player.helpbtn_unshow` 显隐）+ `ui/main_help.gd`（`MainUI/MainHelp` 源浮层：Mask + 指针图 `main.asset` + 11 条 602×200 fs50 气泡，锚点/位置直读 GameScene 真值表；文案 = i18n `MAIN_HELP_*`（zhTW→简体，Unity `<b><color=white><size=86>` 标记转 Godot BBCode））。已知渲染差异：Godot RichTextLabel 的 86px 行内强调字形基线偏移（原作 TMP 无此表现）；InputDisplay 手柄提示未做。**批次 AF 已将卡牌详情迁至 `CardInfoView`（`ui/card_info_view.gd`，`GameScreen` 的 `_source_overlay_layer`）**：源 `CardInfoNew` 面板 2510×1077 居中（3840×2160 设计空间）、`bg_7` 全板、Name（(1911,-89)/435.55×71.58 + 卡名与 TypeIcon fs30 标题）、Content（(270,80)/1550×185 fs34，custom_text‖config.text+占位符）、RareBG（rare_stone 147×249 + CARD_RARE_1..4 石/铜/银/金 fs60）、TagInfo 左列（1336.7×647.76，属性/标签两栏）、MainIconMask（1000×1100 + 471×1028 立绘）、Equips（402.65×500.57 + EquipState 顶部）、Close（checkbox_bg 80×82 + close_2）、BottomDecorate、HelpButton → Help 浮层（card_info 四条 CARD_INFO_HELP_* 气泡）；全部直读 prefab 真值表。详见 `docs/ui_layout/RitePanelShow.md`、`docs/ui_layout/HandCards.md`、`docs/ui_layout/MapController.md`、`docs/ui_layout/BeginGuide.md`、`docs/ui_layout/Over.md`、`docs/ui_layout/ESCPanel.md`、`docs/ui_layout/SettingsPanel.md`、`docs/ui_layout/UserArchive.md`、`docs/ui_layout/CardInfoNew.md`。 |

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
| ~~笔记系统（普查+结构承载）~~ | 已落地（2026-08-18 批次 O）：`Player.notes` List<List<Note>>@0x138 按回合分页（页=round−1），Note={type,id,uid,count}；type 1=仪式创建/2=消亡/3=结算/4=吸附卡(count 存卡 id)/10001=成为随从/10002=获得奖励卡。克隆 `GameState.notes`+`add_note` 进 v7 存读档与导入桥（对拍行过）；运行时写点 1/2/3 已接（StartRite.c L133 / GameController.c L5867 / RiteResultPanelController 链），4/10001 调用方不在反编译子集、10002 的手牌标签门未解——三写点留档 | 中（笔记 UI 未做） |
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
| ~~唯一性登记（only_cards/only_rites）~~ | 已落地（2026-08-18 批次 I）：`only_cards` = 已到桌的 `CardNode.is_only` 配置 id；`only_rites` = 成功 InitRite 的全部仪式 id；type-3 loot 每次抽取前按对应登记集过滤，删卡/删仪式不回退。导入桥对拍两项 | — |
| ~~生成计数（gen_cards/gen_tags）~~ | 已落地（2026-08-18 批次 J）：`gen_cards[id]` 在新建玩家卡时 +1；`gen_tags[code]` 对新卡 `GetTags` 的 HashSet 每个稳定 tag code +1，另承接 `Common.MarkTagGen` 回调语义。苏丹抽卡在池标签复制后显式登记；存档/导入桥双向对拍 | — |
| ~~改名持久化（custom_rite_name/player_card_name）~~ | 已落地（2026-08-18 批次 H）：玩家级配置 ID 覆盖表独立于 Card.custom_name/RiteInstance.custom_name；卡名覆盖优先于实例名，仪式名覆盖优先于配置名。证据：CardExtensions.c 0x37ff50 + Player.c 0x3a4520 / PlayerExtensions.c 0x38dcb0 + dump.cs Player@0x168/@0x170 | — |
| ~~UI 引导标志族（sudan_box_show/story/prestige/deadline/helpbtn、once_new_rites_is_show）~~（结构承载） | 已落地（2026-08-18 批次 N）：五个 Player HUD 标志 + 每仪式首见表进入 v7 存读档/导入桥；`close_*` 操作按原作 0=显示、非零=隐藏写对应字段。原作桌面 HUD 与仪式首见提示 UI 未接，故保持 semantic | 小 |
| ~~苏丹重抽恢复模型（times_per_round/times/recovery_round、sudan_card_init_life）~~ | 已落地（2026-08-18 批次 K）：Player 四字段进入 v7 存读档与导入桥；`RedrawSudanCard` 先用普通配额、再扣 7100008；`SetDifficulty` 只换额度和未来苏丹头起步，保留本周期已用数与 Init 恢复周期；日初按 recovery 周期清已用数 | — |
| ~~结局状态（success/over_reason）~~；~~cached_event（结构承载 + 桌面托盘 UI）~~ | 前者已落地（2026-08-18 批次 L）。后者批次 M 结构承载 + **2026-08-22 批次 AK 桌面托盘 1:1**：载入侧 = `OnCachedListChanged 0x553b70`（cachedEvents@GameController+0x320 字典差量重建：枚举 `Player.cached_event`@0x148 → `CachedEventPrefab`@0xA0 实例化到 `cachedEventContainer`@0x108 → `cachedEvents[id]=controller`；结尾 `SetActive(+0x220, 0<Count)` = **"Next Round Mask For Cached Event"**（GO 47/rect 7639，596×634，Image a=1/255 透明点击吸收器，场景 UnityEvent OnClick→`NoticeCachedEvent 0x5534d0` 摇动托盘））。**条目摆放谜底**：容器 Mono 11735 = HorizontalLayoutGroup 同构字段（m_Padding L0/R100/T0/B0、m_ChildAlignment 5=MiddleRight、m_Spacing 50、m_ReverseArrangement 1、control/expand/scale 全 0）——运行时布局组流式摆放，故 `CachedEventController.Init 0x527900` 无定位代码；条目 rect = 右→左（index 0 最右，right edge=3840−100，步进 112.5+50）。**条目**（`Resources/prefab/CachedEvent.prefab`）：checkbox_bg 112.5×117 + dialog 图标 192²@scale 0.5（视觉 96²居中）+ new 红点 85.5²@锚(1,1) pos(−7.9,−12.7)（顶右探出）+ **禁用** Shaker（positionIntension(0.2,−0.2)、freq 40、time 10、maxSpeed 2、perlin，`CachedEventController.Shake 0x527940` set_enabled(false/true) 重启；`Shaker.c` 已阅）。**点击链** `OnCachedEventClicked 0x5538e0`：`Datapool.can_cached_event_settlements` TryGetValue 命中→OperationMask@0x1C0 + `OperationsExtensions.Start` + b__0 0x5728d0 收尾隐藏+`RemoveCacheEvent`；未命中→直接 `RemoveCacheEvent`。克隆落地：`ui/cached_events_view.gd`（托盘 3840×128 + 右→左条目 + notice 抖动）+ GameScreen 集成（`refresh()` 按 `cached_event` 重建、点击=未命中分支移除、mask 显隐）+ 测试 2 条 + 截图 `docs/ui_layout/cachedevents_screenshot.png` + 新纹理 dialog.png/new.png。🟡/⬜：cached_settlement 结算分支（语料零实例，🟡 未接）；Shaker perlin 曲线/SmoothDamp 轮廓（🟡 视觉近似）；红点在点击后是否隐藏无证据（🟡）；StoryNotifyController 文字通知（另一表面，与托盘图标条目独立，⬜ 未开工） | 小 |
| global.json 其余字段（gameStatistics/doneEvent/doneRite/showedPrompt/choosedOption/showedGalleryCards/图鉴/升级/任务/overRecord/meta counter） | `save_samples/global.json` 29 字段；承载容器 GlobalState 已落地（backToPrevRound/roundRollback 已接） | 中（部分依赖图鉴/升级系统） |
| `[back_to_prev_count]` 文本占位符（Datapool.__c b__389_6 走 GetBackToPrevCount） | 原作配置中未发现该 token 的使用实例，token 拼写无法从语料确认 | 暂缓（不猜测命名） |
| ~~回退快照持久化（Datapool 轮次文件 + IsValidRoundEnd + LoadController.LoadRound）~~ | 已落地（2026-08-18 批次 F）：`round_{N}.json` / `round_{N}_end.json` 双边界持久化、有效性门、磁盘加载刷新 continue、档案恢复清理旧时间线；内存 round_snapshots 降为同进程缓存 | — |
| ~~仪式面板“恢复上次投放”（Player.last_round_rite_data）~~ | 已落地（2026-08-18 批次 G）：`OnConfirm` 按 Rite.id 记录手动槽 guid 的 `{id,count}`，`OnLastState` 按卡牌可用量与当前槽条件逐槽恢复；存读档与原作导入桥均承载。证据：RitePanelController.c 0x58f1c0 / 0x58fdf0 + dump.cs Player@0x158、LastCardData@0x10/@0x14、RiteNode.Slot.open_adsorb@0x20 | — |
| RoundRollbackType.BACK_TO_PREV_BEGIN(3) 的写点 | dump.cs:6186 枚举存在，写点未定位（LoadRoundBegin 疑似） | 小（待双信号） |
| 成就面板 | steam_achievement 空实现 | 可选 |
| 主菜单 ButtonsGroup 三键行（图鉴/商店/剧情，405×174 间距 240）+ Contacts 行 + Version 文本 | `docs/ui_layout/StartScene.md` 真值已备；图鉴/商店/剧情面板本体未复刻（D 表各行），社交链接对克隆无意义 | 随各面板批次接入 |

## 普查程序（如何扩展本表）

1. 从 `engine_spec/dump.cs` 提取运行时类清单（Controller / Manager / Panel 优先，JsonHandler 指路数据域）。
2. 每个类归入四状态之一，登记证据指针（文件 + RVA/行号）；查无克隆对应物即入 ⬜。
3. 每个复刻批次收尾时更新所 touched 的行；每个大阶段做一次 dump.cs 增量普查。
4. 表中新增 ✅ 必须附双信号；只有单信号时写 🟡 并注明缺口。

## 对拍台（验收裁判）

- **资产**：语料库 `save_samples/`（`auto_save.json`、`save_slot_000.json`、`global.json`、`user_archive.json`）= 原作真实存档，明文 JSON。
- **阶段 1 ✅（2026-08-17）**：schema 全解码——Player 60 字段与 dump.cs 双信号吻合，零未知零类型不符；映射表与工具落地（`sim/original_save_schema.gd` + `tools/export_save_diff.gd` + `tests/test_save_diff_harness.gd`，mapped 11 / semantic 11 / missing 38）；快照文档 `docs/ORIGINAL_SAVE_SCHEMA.md`。结构发现：金币=卡 2000029 堆叠（双信号）、骰子疑 counter、手牌=bag/bagpos、仪式槽位内嵌嵌套、UI 队列不持久化、回退双轨、random_cache。
- **阶段 2 ✅（2026-08-18，批次 U 更新）**：导入桥——原作存档 → 克隆 GameState → v8 payload → 同刻值对拍；语料 auto_save **46/46** 全过（含 only_cards / only_rites / gen_cards / gen_tags / 苏丹重抽 profile / 终局结果 / cached_event / HUD 标志族 / Player.pins），差异按 converted / approximated / dropped 防静默登记。此后涉及状态的批次验收 = GUT 全绿 + 对拍零差异（或差异均有原作语义解释）。
- **远期**：固定种子 trace 对拍（同一操作脚本下原作 vs 克隆的事件/结算日志序列）。
- **UI 布局对拍 ✅（2026-08-18 批次 P）**：`tools/export_ui_layout.gd` 解析语料 AssetRipper 场景/prefab YAML，产出 RectTransform 真值表（锚点/位置/尺寸/pivot/缩放 + CanvasScaler + LayoutGroup 参数 + sprite guid→语料路径）至 `docs/ui_layout/`；主画布设计空间 = **3840×2160**。表现层批次的验收 = 每个摆位数字能回指真值表行；视觉证据用 `tools/dev_screenshot_runner.tscn` 截图。
