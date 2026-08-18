# 原作存档 Schema 与对拍台（阶段一，2026-08-17）

> 复刻工作法支柱 2「原作产物当裁判」的落地。机器真源 = `sim/original_save_schema.gd`
> （60 字段映射表 + 分析/对拍函数）；本文是可读快照，冲突以模块为准。
> 证据：`il2cpp_dump/dump.cs` Player（391488 行，TypeDefIndex 6274，JsonSerializable）
> × 真实存档 `save_samples/auto_save.json`（round 1 / difficulty 1）双信号吻合：
> 60 字段零未知、零类型不符。

## 工具用法

```
godot --headless --script tools/export_save_diff.gd -- \
  --original <原作存档.json> [--compare <克隆v5.json>] [--out <目录>]
```

- 默认 `--original` 指向语料库 auto_save.json；未知字段/类型不符会使退出码非零。
- `--compare`：对 mapped/semantic 字段做逐项值对照（同刻存档才有意义；导入桥建成后使用）。
- GUT：`tests/test_save_diff_harness.gd`（schema 总量 60、金币发现登记、样本分析全过）。

## Player 存档 60 字段（dump.cs 偏移序）

状态：**mapped 11**（同名同义）/ **semantic 11**（有对应但结构或语义漂移）/ **missing 38**（克隆无）。

| 字段 | 类型 | 克隆 v5 | 状态 | 备注 |
| --- | --- | --- | --- | --- |
| configId | int | — | missing | 局内配置身份 |
| configVersion | long | — | missing | 配置版本戳 |
| name | string | — | missing | 玩家名（默认阿尔图） |
| difficulty | int | difficulty_index | semantic | 基数待验证（样本=1） |
| round | int | round_number | semantic | 原作 round 即日；克隆另存 day（原作无） |
| min_round | int | round_snapshots 内部 | semantic | 回退下界，原作显式持久化 |
| saveTime | DateTime | — | missing | 时间戳 |
| card_uid_index | int | next_card_uid | mapped | |
| rite_uid_index | int | next_rite_uid | mapped | |
| sudan_box_show | bool | — | missing | 苏丹卡盒首见 |
| story_unshow | bool | — | missing | 剧情 UI 标志 |
| prestige_unshow | bool | — | missing | 声望 UI 标志 |
| deadline_unshow | bool | — | missing | 死线 UI 标志 |
| helpbtn_unshow | bool | — | missing | 帮助按钮 |
| location_icon_show | int | — | missing | change_location_icon 持久化 |
| change_desk_bg | string | — | missing | change_desk_bg 持久化 |
| after_round_auto_sort | bool | — | missing | 日终自动整理 |
| sudan_card_init_life | int | — | missing | 苏丹卡初始寿命（中途换难度按此值） |
| sudan_redraw_count | int | sudan_redraw_count | mapped | |
| sudan_redraw_times_per_round | int | — | missing | 每回合重抽次数 |
| sudan_redraw_times | int | redraws_left | semantic | 原作记已用，克隆记剩余 |
| sudan_redraw_times_recovery_round | int | — | missing | 恢复回合 |
| wizard_first_show | bool | begin_guide(部分) | semantic | 原作仅存布尔 |
| success | bool | — | missing | 通关标志 |
| over_reason | int | — | missing | int.MinValue=未结局 |
| ithink_card | Card? | — | missing | 俺寻思卡实例 |
| cards | List\<Card\> | card_instances | semantic | 见下「结构差异」 |
| rites | List\<Rite\> | rite_instances | semantic | 槽位下标数组内嵌卡 |
| pins | List\<int\> | — | missing | 桌面图钉 |
| sudan_pool_cards | List\<int\> | sudan_deck(部分) | semantic | 池剩牌 id |
| sudan_pool | string | — | missing | 池变体 |
| sudan_card_pool | List\<Card\> | sudan_deck(部分) | semantic | 手边待选苏丹卡 |
| sudan_pool_pos | Vector2 | — | missing | 池 UI 坐标 |
| sudan_pool_init_count | int | — | missing | |
| sudan_card_show_times | Dict\<int,int\> | — | missing | 展示计数 |
| sudan_remove_count | int | — | missing | |
| counter | Dict\<int,int\> | local_counters | mapped | 骰子疑在此（id 待验证） |
| global_counter_cacher | Dict\<int,int\> | global_counters | semantic | 缓存器；真值在 global.json |
| random_cache | Dict\<string,int\> | — | missing | RNG 续航 |
| only_cards | HashSet\<int\> | — | missing | 唯一卡登记 |
| only_rites | HashSet\<int\> | — | missing | 唯一仪式登记 |
| event_status | Dict\<int,bool\> | event_status | mapped | |
| delay_ops | List\<DelayOp\> | delayed_operations | mapped | {id, round} |
| end_rites | Dict\<int,int\> | ended_rites | mapped | |
| gen_cards | Dict\<int,int\> | — | missing | 生成计数 |
| gen_tags | Dict\<string,int\> | — | missing | 标签生成计数 |
| timing_rounds | Dict\<int,int\> | timing_rounds | mapped | player+0x128 |
| auto_result_rites | HashSet\<int\> | auto_result_rites | mapped | |
| notes | List\<List\<Note\>\> | — | missing | 笔记分页流水账 |
| once_new_rites_is_show | Dict\<int,bool\> | — | missing | 新仪式首见 |
| cached_event | List\<int\> | — | missing | 事件缓存 |
| BagIndex | int | — | missing | 背包索引 |
| last_round_rite_data | Dict\<int,Dict\> | round_snapshots | semantic | 原作按仪式 LastCardData{id,count}；克隆整日快照 |
| rite_auto_result | bool | rite_auto_result | mapped | |
| disable_auto_gen_sudan_card | bool | auto_gen_sudan_card(取反) | mapped | |
| custom_rite_name | Dict\<int,string\> | — | missing | 改名持久化 |
| player_card_name | Dict\<int,string\> | — | missing | 改名持久化 |
| end_open | bool | — | missing | 终局开启 |
| is_armageddon | bool | — | missing | 末日决战态 |
| armageddon_rite_id | int | — | missing | 末日仪式 id |

## 嵌套 DTO

- **Card（存档形）**：`{uid, id, count, life, rareup, tag{}, equip_slots[], equips[Card], bag, bagpos, custom_name, custom_text}`——装备**嵌套**在宿主卡的 `equips` 里；`bag=0` 且 `bagpos` 决定手牌位。
- **Rite**：`{uid, id, new_born, is_show, start, start_round, start_life, life, cards[按槽位下标, null=空槽, 内嵌 Card], custom_name}`。
- **Player.Note**：`{type, id, uid, count}`（样本 type 10002/10001=卡族、1=仪式；分页组织）。
- **Player.DelayOp**：`{id, round}`。**Player.LastCardData**：`{id, count}`。

## global.json（29 字段，跨局全局）

saveTime / finishTutorial / inGame / totalRound / totalPoint / usedPoint / upgradeState / questState / upgrade{} / quest{} / counter{6} / mods[] / hasEnterSudanBox / hasEnterQuest / **backToPrevRound（回退配额，9999=未用）** / roundRollback / overRecord[] / overID[]（结局图鉴）/ gameStatistics{} / doneRite[] / doneEvent[] / **showedGalleryCards[]（图鉴解锁）** / showedPrompt[] / choosedOption[] / isAutoClassify / autoClassifyBagTags{} / version。
克隆对应：承载容器已落地（`sim/global_state.gd` → user://global.json），backToPrevRound / roundRollback / saveTime 三字段已接；其余仍缺（归 METHOD_MAP D：global.json 其余字段）。

## user_archive.json

50 槽索引：`{name, live_days, left_sudan, execution_day, back_to_prev_round, save_time, path}`。克隆已有等价档案索引（字段名不同，语义同）。

## 关键结构发现（驱动后续批次）

1. **金币 = 手牌金币卡对象（id 2000029）的 count 之和（多对象模型）**。双信号：`GenCoin.c Do 0x510b40`（`GameController.GenCard(0x1E849D)` → `PlayerExtensions.AddCard`（**每次新建对象**，无堆叠合并分支）→ `Card.set_count(操作值)` → `set_bagpos(1)` → `OnCardBorn`）× cards.json 2000029（金币/可堆叠/消耗品/已拥有）+ 存档样本旁证（神的乙太 2001090 × 20 个对象各 count=1）。操作值**可为负**（set_count 直写）；花费判定 `CostCondition.IsSatisfied 0x3f6160` 读卡对象 count。克隆原 `coin_count` 标量为结构偏差——**2026-08-17 已修复**：`coin_count` 改为金币卡对象求和的计算属性，`coin` 操作按原作生成卡对象（前置手牌位、发 card_born），v5→v6 存档迁移（标量→单对象）；扣除顺序已按发现 3 的枚举序对齐。
2. **金骰 = counter 7100006**（已修复）。三重信号：dump.cs:542529 `COUNTER_GOLD_DICE = 7100006` 常量 + PlayerExtensions Add/SubCounter 写点 + 存档样本（difficulty=1 → counter 7100006=3，与 init 难度表 gold_dice_count 精确吻合）。克隆 `gold_dice` 现为该 counter 的计算属性。**常量表顺带解出**：回退配额 = COUNTER_BACK_TO_PREV 7100007（存 global.json backToPrevRound，**2026-08-18 已迁移**，见发现 8）、苏丹额外重抽 = COUNTER_SUDAN_EXTRA_REDRAW 7100008（待克隆迁移）。
3. **cost 支付链**（部分留档）：`CostCondition.IsSatisfied 0x3f6160` 判定时即按 player.cards 枚举序选定付款卡清单（累计 count 覆盖花费即停）记入 `ConditionContext.need_cost_cards`（dump.cs:383873）+ `cost_count`——支付顺序=卡列表顺序（最旧优先），克隆 `_remove_gold` 已按 uid 升序对齐；实际扣款执行体未包含在反编译子集（留档）。
4. **金币/门客总额是派生读**：`GetCounter 0x38ce70` 对 7000105（金币）/7000104（门客数）特殊分支——从 player.cards + player.rites 按谓词求和，**仪式槽内的金币卡计入总额**；克隆 gold_total 已扩展 hand+slot。
5. **手牌 = cards 中 bag=0 按 bagpos 排序**，无独立 hand 数组；克隆 `hand`/`rail_order` 为自制承载。
6. **仪式槽位是下标数组**（null=空槽），卡与装备全内嵌；克隆用扁平 zone/rite_uid/slot_key + equipped_uids。导入桥必须做嵌套↔扁平转换。
7. **原作 UI 队列不持久化**：只存 delay_ops + cached_event；克隆持久化全量 pending_operations（语义更重，导入桥需裁剪）。
8. **回退三域已拆清**：① global.backToPrevRound（配额，即 COUNTER_BACK_TO_PREV 7100007）已迁入 `GlobalState`；② Datapool 轮次 Player 文件已于 **2026-08-18 批次 F** 落地：SaveRoundBegin/End 先刷新 continue，再写 `round_{N}.json` / `round_{N}_end.json`，LoadRound/End 从磁盘恢复并刷新 continue，档案恢复删除旧时间线的 `round_*.json`；③ player.last_round_rite_data 是按仪式 LastCardData 的独立字段，仍待确认用途。消耗顺序保持 `UseBackToPrev → Global.roundRollback=2 → SaveGlobal → LoadRound`，故玩家重启后仍可回退且配额不会随 Player 快照回滚。
9. **RNG 续航**：random_cache 字典——原作存 RNG 状态保证跨存档续局一致；克隆无。
10. **苏丹期限 = 卡寿命模型**（2026-08-18 批次 D 解出）：激活苏丹卡无独立期限字段——`GenSudanCard` L3656-3662 出生 `set_life(模板 card_vanishing − player.sudan_card_init_life)`（抢跑量），每日 life+1（老化无条件），`life >= card_vanishing` 且不在任一仪式槽即 DoVanish 处刑（vanish.over 驱动结局）；可见倒计时 = `card_vanishing − life`（UpdateSudanLife 0x55aeb0，庇护期间可为负）。样本 uid11 life=0=7−7 ✓；困难档 7−5=2 抢跑=5 天。重抽新卡 `set_life(弃卡 life)` 继承剩余；抽牌 = sudan_card_pool 先 Shuffle 再 RemoveLast（顺序无意义）。克隆：`_update_card_lives` 苏丹并入通用死亡，days_left 为镜像；导入桥 days_left 精确恢复。
11. **手牌位 = bag/bagpos 双字段**（2026-08-18 批次 E 解出）：`Card.bag`@0x48 = 包页 id（`Player.BagIndex`@0x150 = 当前查看页，GenSudanCard 把新苏丹卡 set_bag 进当前页）；`bagpos`@0x4c = 页内 **1 基**位置，0 = 未摆放（背包列表）；`UpdateHandCardPos` 0x559a70 在 b__6 链（回合开始事件**之后**）收集 `IsCurrentHandCard`（bag==BagIndex 且三标签资格）卡排序后压缩为 1..N；GenCoin `set_bagpos(1)` 金币前置。样本仅 6 张卡有位置（主角/苏丹/妻子/法拉杰/已装备/乙太堆）——bagpos 是玩家手动摆放，非类型成员。克隆：CardInstance.bag/bag_pos 落地 + 日终压缩 + 导入桥透传（bag_positions 对拍行）；三标签名（IsHandCard 资格判据）无法从元数据反查，留档。

## 阶段二：导入桥（2026-08-18 已落地）

`sim/original_save_importer.gd`：原作 Player 存档 → 克隆 v7 payload → 正常 `SaveSystem.deserialize` 路径载入 GameState。`tools/export_save_diff.gd --bridge` 产出同刻对拍报告（user://save_diff/save_diff.md + bridge_payload_v7.json）。语料 auto_save.json 实测 **24/24 项全过**（回合/难度基数/两 uid 指针/计数器/事件状态/时机臂/仪式槽位/装备链接/手牌成员及 bag/bagpos/苏丹多重集/per-id 计数/金币 7000105 派生读等）。

导入桥当场抓到并修复的结构偏差：

- **timing_rounds 键格式**：原作键 = TimingRoundBase 实例 +0x20 的 **int**（样本全部 = 事件 id×100，如 5300067→530006700；TimingRoundBase.c IsValid 0x465d30/OnStart 0x4660d0 直接以该 int 寻址 player+0x128）。克隆旧自制格式 `"round_begin_ba:5310000"` 已改为 `event_id*100`（全部 1381 个带回合时机的事件均单桶，序号恒 0；多桶序号分配留待原作侧验证），旧字符串键在 deserialize 迁移。
- **difficulty 基数**：1 基确认（样本 difficulty=1 与 counter 7100006=3、per_round=3、global backToPrevRound=9999 四信号同指简单档）；导入时 -1。
- **min_round**：原作显式持久化 player+0x30 且 OnPrevRound 直读；克隆补 `GameState.min_round`（v7 序列化）作回退门。
- **仪式槽位映射**：原作 `Rite.cards[i]`（0 基数组，长度=配置 s 槽数）↔ 克隆 `s{i+1}`。

报告三类防静默登记：**converted**（8 项标量/结构转换）、**approximated**（active_sudan 的 drawn_round 无法在难度中途切换后反推；每抽前 Shuffle 使牌堆顺序无语义，按多重集对拍）、**dropped**（仅列本存档携带非默认值的克隆缺口字段，如 notes/only_cards/gen_cards）。

### 阶段二遗留（续局对拍前置）

- 4 个 cloned 探针字段（world_* 等）在导入时取默认值，报告未列（原作无对应物）。
- 续局行为对拍（导入后继续玩 N 天与原作存档互证）待实机样本。
