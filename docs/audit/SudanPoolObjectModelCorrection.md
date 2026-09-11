# 苏丹池对象域：List&lt;Card&gt; 而不是 id 多重集（第二十批，2026-09-10）

A17 原先登记为"待核候选：池中同 id 不同运行态可能丢失"。本批把它核成了**已发生的偏差**，并按原作的 Card 对象模型重建。

## 原作事实

- `Player.sudan_card_pool` 在 `player+0xB0`，dump.cs 与 `Player.c` 构造器（`0x3a5000` 的 `System_Collections_Generic_List__ctor` 写入 `+0xB0`）双信号确认它是 **`List<Card>`**，不是 id 列表。
- `GenSudanCard 0x54f6f0`：取 `player+0xB0`；池空返回 0；若 `param_3 > 0` 则先按谓词找到并 `RemoveAt` 该对象，否则按 `InitNode+0x48`（sudan_shuffle）`ListExtensions.Shuffle` 后 `ListExtensions.RemoveLast`。**取出的就是那个 Card 对象本身**，随后直接 `Card.set_bag(player.BagIndex)`、`Card.set_life(模板 card_vanishing − player.sudan_card_init_life)`、`PlayerExtensions.AddCard(同一个对象)`、`MarkCardGen`、`PutCardOnTable`。
- `RedrawSudanCard 0x5558b0`：数量门通过后循环 `player+0x68` 次 `GenSudanCard`，每次 `Card.set_life(新卡, 弃卡.life)`；末尾 `List.Insert(Random.Range(0, pool.count), 弃卡对象)`——**弃牌对象本身回到池**，其运行时标签随它一起回去。
- `SudanPoolModifyTag 0x51c2e0`（`DoTemplate`）：`OperationFilter.Filter(player+0xB0)` 遍历**每个池对象**并逐个 `AddTag`/`RemoveTag`（闭包 `0x51c6f0` 里对同一个 `param_2` Card 调用）。
- `SudanPoolHaveCardCount.IsSatisfied 0x409760`：同样遍历 `player+0xB0` 计数。
- 配置侧：`init/1.json` 的 `sudan_pool` 是 **28 项**、每 id 两项（`[2010001,2010001,2010002,...]`）。

## 存档证据（决定性）

`save_samples/auto_save.json`（与 `save_slot_000.json` 同构）：

- `sudan_pool_cards` 28 项（配置表），`sudan_card_pool` **27 个对象**（已抽走 1 张），`sudan_pool_init_count=28`、`sudan_remove_count=0`。
- 27 个对象里 **11 个 id 重复**（2010001/2010002/2010003/2010005/2010007/2010009/2010010/2010011/2010013/2010014/2010015 各两份）。
- 每个对象自带 `uid/count/life/tag/bag/bagpos/custom_*/rareup/equips/equip_slots`，其中 `tag={"sudan_pool_index": N}`、且 **uid = N+1**（首项 uid 3 → index 3）。

**结论：按配置 id 建一个标签字典的表示法丢的是真实对象**，不是潜在风险。

## 克隆偏差

1. `sudan_deck: Array[int]` + `sudan_pool_tags: Dictionary[card_id] -> delta`：同 id 的多个池对象被合并成一个条目。
2. 池标签操作因此**只改一个**条目（原实现还显式 `seen_card_ids` 去重），而原作逐个对象施加。
3. `_create_sudan_instance` 从配置新建 CardInstance、另分配 uid，池对象的 `uid/count/life` 与 `sudan_pool_index` 全部丢弃（导入器还显式过滤掉 `sudan_pool_index`）。
4. 重抽把"标签字典"塞回 `sudan_pool_tags[discarded]`，而不是把对象放回池。
5. `sudan_pool_pos`（`Player+0xB8`）未映射。

## 修复

- 新增 `sim/sudan_pool_card.gd`（`SudanPoolCard`）：一个池对象的载体，字段 `uid/card_id/count/life/tags(delta)/pos`，带存档往返。
- `GameState.sudan_deck` 改为**对象数组**；新增 `build_sudan_pool / add_sudan_pool_card / reset_sudan_pool_to_ids / sudan_pool_size / sudan_deck_ids / draw_sudan_pool_card / insert_sudan_pool_card / sudan_pool_entry / sudan_pool_entry_tags / sudan_pool_tags()(读视图) / set_sudan_pool_tags_for_id`。
- **shuffle 移到抽取时**（`draw_sudan_pool_card` 内 `Shuffle` 后 `pop_back`），因为原作是在 `GenSudanCard` 里原地洗牌；`setup_new_run` 现在保持配置顺序。这是 RNG 时序的行为修正，不是实现细节。
- `round_loop.gd`：`draw_weekly_sudan` 取池对象并 `_promote_sudan_pool_entry`（复用原 uid、保留 count 与 delta、按公式设 life、写 BagIndex）；`use_redraw` 抽新卡后把**弃牌对象本身** `insert_sudan_pool_card` 回池，并从 `card_instances` 移除该运行时实例（同一 uid 不能同时是池对象与桌面实例）。
- `result.gd`：`sudan_card` 操作走 `add_sudan_pool_card`；`sudan_pool.<sel><op><tag>` 去掉 `seen_card_ids` 去重，逐对象在有效行上匹配后写 delta。
- `condition.gd`：`sudan_pool_have` 改为计数池**对象**。
- `save_system.gd`：`sudan_deck` 保存为 Card 对象行 + `sudan_pool_next_uid`；`_restore_sudan_pool` 同时接受新对象行与旧 id 列表（旧格式按 id 铸造对象并挂上旧的 per-id delta）。
- `original_save_importer.gd`：逐个导入源池对象（保留 uid/count/life/tag，不再丢 `sudan_pool_index`）；对拍新增 `sudan_pool_objects` 行（按 uid 比 card_id/count/life/tag）。

## 验证

- `tests/test_sudan.gd`：22 测试 / 590 断言。含"同 id 两个对象都收到标签操作""抽走的是被改的那个对象、剩余对象保持自己的状态""重抽把弃牌对象放回池且保留其 delta""setup 不再洗牌、抽取时才洗"。
- `tests/test_save_system.gd`：13 测试 / 147 断言。含旧 id 列表 + per-id 标签字典升级为对象、新对象行往返、v5 缺字段默认。
- `test_save_import_bridge.gd`：6 测试 / 86 断言，语料 auto_save 新增 `sudan_pool_objects` 行通过。
- 全量 GUT：46 脚本 / 567 测试 / 565 通过 / 4336 断言中 4334 通过（`a17-full.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败与第十九批记录的既有 UI 失败相同（`test_card_flash` 卡面几何、`test_event_choice_controller` mask 高度），基线对照已确认与本批无关。

## 未完成与新增审计线索

- **池对象与运行时实例共用 uid 命名空间**：这是核心承载选择（原作也是同一个 Card 对象换容器）。代价是"已抽出的对象既在 active_sudan 又在池里"这种状态无法表达——与原作一致，但克隆若以后要同时持有两侧引用需重新评估。
- `sudan_pool_pos`（`Player+0xB8`）仍只是每条目存了个 `pos`，没有复现原作的语义；样本里是 `[-1740, 800]`（两个浮点/位置量），来源未定。
- `GenSudanCard` 的 `param_3`（按 uid 定点抽取）分支未接：克隆只有"洗牌后取末位"这一条路径。当前没有配置或调用方命中该分支，登记为缺口。
- `_promote_sudan_pool_entry` 不读池对象的 `life` 字段而按公式重算；当前内容下池对象 life 恒为 0，两者等价，已在该函数注释中登记。
- 苏丹池 UI（`SudanPoolController`）仍未接，本批只改数据层。
