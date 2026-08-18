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
克隆对应：几乎全缺（归 METHOD_MAP D：全局域）。

## user_archive.json

50 槽索引：`{name, live_days, left_sudan, execution_day, back_to_prev_round, save_time, path}`。克隆已有等价档案索引（字段名不同，语义同）。

## 关键结构发现（驱动后续批次）

1. **金币 = 手牌金币卡对象（id 2000029）的 count 之和（多对象模型）**。双信号：`GenCoin.c Do 0x510b40`（`GameController.GenCard(0x1E849D)` → `PlayerExtensions.AddCard`（**每次新建对象**，无堆叠合并分支）→ `Card.set_count(操作值)` → `set_bagpos(1)` → `OnCardBorn`）× cards.json 2000029（金币/可堆叠/消耗品/已拥有）+ 存档样本旁证（神的乙太 2001090 × 20 个对象各 count=1）。操作值**可为负**（set_count 直写）；花费判定 `CostCondition.IsSatisfied 0x3f6160` 读卡对象 count。克隆原 `coin_count` 标量为结构偏差——**2026-08-17 已修复**：`coin_count` 改为金币卡对象求和的计算属性，`coin` 操作按原作生成卡对象（前置手牌位、发 card_born），v5→v6 存档迁移（标量→单对象）。留档：多对象间的**扣除顺序**未验证（cost 支付执行链未审计，现为最大面额优先）。
2. **骰子无 Player 字段**：金骰数量疑走 counter（样本 counter 7100006=3 值巧合待验证）。→ 待验证。
3. **手牌 = cards 中 bag=0 按 bagpos 排序**，无独立 hand 数组；克隆 `hand`/`rail_order` 为自制承载。
4. **仪式槽位是下标数组**（null=空槽），卡与装备全内嵌；克隆用扁平 zone/rite_uid/slot_key + equipped_uids。导入桥必须做嵌套↔扁平转换。
5. **原作 UI 队列不持久化**：只存 delay_ops + cached_event；克隆持久化全量 pending_operations（语义更重，导入桥需裁剪）。
6. **回退双轨**：原作 global.backToPrevRound（配额）+ player.last_round_rite_data（按仪式卡数据）；克隆 back_to_prev_left（player 侧）+ round_snapshots（整日快照）。
7. **RNG 续航**：random_cache 字典——原作存 RNG 状态保证跨存档续局一致；克隆无。

## 下一步（阶段二：导入桥）

原作存档 → 克隆 GameState 内存态（mapped/semantic 字段全转换，missing 字段登记丢弃清单）→ 立即导出 v5 → 语义对拍报告。达成后，「同刻双存档值对拍」与「续局行为对拍」才可用。
