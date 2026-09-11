# CardOpContext 操作流：从结算到结果面板（第二十九批，2026-09-10）

A12 的主体是"`CardOpContext` → `OpCardNewController` 播放链"。本批先把它**拆成两半**：操作流（数据）已落地，逐张卡动画播放（表现）仍未接。审计原话"按钮状态不代表实际奖励演出完成"，指的就是后者；但在此之前克隆连**操作流本身**都没有。

## 原作事实

- `CardOpType`（dump.cs:394326，TypeDefIndex 6304）共 13 个值：
  `NEW=0 COPY=1 DELETE=2 EQUIP=3 UNEQUIP=4 UNEQUIP_RECOVERY=5 ADD_TAG=6 REMOVE_TAG=7 UPRARE=8 POP=9 HAND_POP=10 THINK_POP=11 REBIRTH_SUDAN_CARD=12`。
- `CardOpContext`（dump.cs:6305）字段：`OpType@0x10 / card@0x18 / tag@0x20 / value@0x28 / count@0x2c / pop@0x30`。
- `RiteResultPanelController.AddCardOp 0x5a0e60`：若"已缓存"标志 `+0x182` 为真先 `MoveOpCardsToResults`；对 `ADD_TAG`/`REMOVE_TAG` 会先检查 `tag+0x41`（`can_visible`），不可见就直接返回、不入队；否则把这条 context 追加到 `+0x1d8` 的待播列表。
- `OpCardNewController`（dump.cs:4476）是播放侧：字段有 `Background@0x20 / Equip@0x28 / Card@0x30 / Special@0x38 / Tag@0x40 / TagModify@0x48 / Animation@0x50 / Pop@0x58 / PopText@0x60 / PopStartTime@0x68 / lifeCount@0x88 / BGEft@0x98 / tagText@0xa0`，`Init 0x572f40` 按 op 类型决定演出，`Update 0x574af0` 推进，`Done 0x572dc0` 收尾。

## 克隆缺口

`rite_view.gd` 的 `_rebuild_result_lists()` 是**空实现**（只清空），三个原作图层 `Op Results`(1105,169) / `Op Hand Results`(1316,175) / `Op Cards`(232,510,1440,800) 一直是空的，因为克隆**没有任何地方产生操作记录**——`ResultExec` 返回的 deferred 里只有 events/logs/clean_* 之类，没有"对哪张卡做了什么"。

## 修复

### 1. 操作流（数据）

- `GameState` 新增 **结果操作日志隔舱**：`card_op_log` + `begin_result_op_log()` / `drain_result_op_log()` / `is_recording_result_ops()`，以及常量 `CARD_OP_NEW/COPY/DELETE/EQUIP/UNEQUIP/UNEQUIP_RECOVERY/UPRARE`（值与 `CardOpType` 逐一对齐）。
- 在**卡牌变更点**记录，因此任何调用方都被覆盖：
  - `create_card_instance` → NEW
  - `copy_card_instance` → COPY（带 `source_uid`）
  - `remove_card_instance_from_play` → DELETE
  - `_remove_slot_instance`（`clean.sN` 走的就是这里）→ DELETE
  - `attach_equipment` → EQUIP（带 `host_uid`、`slot`）
  - `detach_equipment` → UNEQUIP / UNEQUIP_RECOVERY（带 `host_uid`）
  - `modify_card_rarity` → UPRARE（带 `rare_before`/`rare_after`）
- **隔舱是被动的**：不调 `begin_result_op_log()` 就不记录。所以玩家拖动装备、初始化建卡等**不会**污染结算流；只有 `ResultExec.execute` 与延迟效果应用这两处显式开启。
- `ResultExec.execute` 在入口 `begin_result_op_log()`，返回前 `_collect_card_ops()` 把记录并入 deferred 的 `card_ops` 键；`rite_view._apply_deferred_to_world` 同样包一层，把延迟效果的变更也收进同一条流。
- **注意返回形状**：`RiteResolver.resolve` / `ResultExec.execute` 返回的是 **deferred 结构本身**（`res.card_ops` 在顶层），不是 `res.deferred.card_ops`——本批在实现中踩到并按实际形状改正。

### 2. 结果面板渲染

`rite_view._rebuild_result_lists(res)` 不再空转：按 `card_ops` 逐条生成一行 `Label`（`CARD_OP_LABELS` 映射成"新增/复制/移除/装备/卸下/升稀有…"），放进原作图层——`NEW/COPY/DELETE/UPRARE` 进 `Op Cards`，其余进 `Op Results`；每行带 `source_card_op` / `source_card_uid` 元数据便于断言与后续替换成真卡片视图。

## 验证

- 新增 `tests/test_card_op_stream.gd`（9 测试 / 20 断言）：日志在未开启时被动；`card` 生成记一条 NEW 且带 uid；`copy.s1` 记 COPY 且带 source_uid；`s1.uprare` 记 UPRARE 且 before/after 正确；`clean.s1` 记 DELETE；`s1+equip` 记 EQUIP 且带 host_uid；`coin` 不产生 UPRARE；结果面板按记录条数渲染行且行内保留 CardOpType 值；空流不残留旧行。
- 全量 GUT：53 脚本 / 612 测试 / 609 通过 / 4522 断言中 4520 通过（`r6-full2.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败仍是既有的 `test_card_flash` 与 `test_event_choice_controller`。
- 过程中抓到并修掉一个真实泄漏：`_clear_result_lists` 原先用 `child.queue_free()`，而结果行会在**同一帧**重建，延迟释放会把旧行留成 orphan；改为同步 `free()` 后 orphan 归零。

## 补记（第三十批，2026-09-10）：ADD_TAG / REMOVE_TAG 入流 + `can_visible` 门

上表"未完成"里列的第一条可独立收口项——标签操作既没有记录点、也没有 `can_visible` 门——本批做掉。

### 关键事实：`can_visible` 是**显示旗标**，不是写入门

`RiteResultPanelController.AddCardOp 0x5a0e60`（0x3335-0x3343）：

```
if (type == 6 || type == 7) {
    if (cardOp.tag@0x20 == null) abort;          // 无标签对象 → 抛异常
    if (tag@0x20 -> +0x41 == 0) return;          // can_visible=0 → 直接返回，不入队
}
... List.Add(cardOp) 在 0x3345，门之后
```

门的**位置**决定了语义：它在结果面板这一侧，而 `CardExtensions.AddTag 0x37e6a0` / `RemoveTag 0x382e40` **从不读 `+0x41`**（全语料 `+0x41` 的读点只有 `HandCardsController` / `HandBagController` / `CardInfoNewController` / `GalleryCardInfo` / `Datapanel` / `TagNode(+0x41)` / 两个 ModifyTag 系列的 PreDo / 结果面板 / `PanelBase` / `MusicFadeOutController`——**全部是消费/显示方**）。

所以：`can_visible=0` 的标签（442 个里 262 个：影响力 / 污名 / 耐心 / 专属 / 出轨 / 各类存货与标记）**照常写入卡牌**，只是**不产生结果行**。

> 本批先按"门 = 写入门"实现，被测试当场打回：`self+影响力` 既没记录、卡也没变。改成"写入无条件、只有记录过门"后两条信号同时成立。留档：这种"门在消费侧而非写入侧"的判断，必须靠**门的调用点位置**（在 List.Add 之前）而不是字段名。

### 改动

- **`ResultExec._mutate_tag()` 成为全部 6 个标签写入源的单点收口**（裸键 / `s<n>` 槽 / `table.` `g.` / `total.` / `sudan_pool.` / `GenCard` 的 operation-local `TagModify`）。原先 6 处各自裸调 `TagSystem.apply`；现在统一走一个 helper：
  ```gdscript
  var changed := TagSystem.apply(tags, tag_name, op, amount, can_add, effective_value)
  if _tag_can_visible(db, tag_name) and state != null and state.has_method("record_tag_op"):
      state.record_tag_op(card_uid, tag_name, op, amount, tags)
  return changed
  ```
- **`TagSystem.apply` 改为返回 `bool`**（存储值是否真的变了）。调用方只有 6 个生产点 + 2 个测试，签名兼容（GDScript 忽略返回值）。
- **`GameState.record_tag_op(uid, tag_name, op, amount, tags)`** 落一张行：`op` 6/7、`tag`、`amount`、`value_after`；沿用隔舱，未 `begin_result_op_log()` 时不记录。
- **记录时机 = 调用点，不是变更点**：原作的 CardOp 建在操作的 **PreDo** 阶段（`DesktopModifyTag.__c__DisplayClass7_1.c` 的 `<PreDo>b__2` 0x521f60 / `b__3` 0x521fb0 → `OperationContext.AddCardOp_AddTag` 0x39dfa0 / `_RemoveTag` 0x39e870），**早于** `Do()` 里的 `can_add` 门。所以 `self+已拥有`（`can_add=0`、卡上已有该标签、实际零改动）**仍然产生一行**。曾短暂加过"没变就不记"的过滤，属自制偏差，已删。
- `GameState` 补常量 `CARD_OP_ADD_TAG = 6` / `CARD_OP_REMOVE_TAG = 7`（此前只有常量表注释，没有值）。`+`/`=` → 6，`-` → 7。

### 验证

- `tests/test_card_op_stream.gd` 从 9 → 13 测试：新增 ADD_TAG 行带 tag/amount/uid、REMOVE_TAG 是 7、`can_visible=0` 写入了但不入流、`can_add` 挡住时仍报一行（且卡确实没变）。
- `tests/test_tag_model.gd` 13/13：`TagSystem.apply` 三种 op 的返回值语义。
- 全量 GUT（第三十批）：53 脚本 / 617 测试 / 614 通过 / 4544 断言中 4542 通过，**零 SCRIPT ERROR、零 orphan、零泄漏**。两条失败仍是既有 `test_card_flash`（"candidate layout keeps the scaled bottom on the rail"，658.99 vs 764.0）与 `test_event_choice_controller`（mask rect 2629×489 vs 2629×828），1 条 Risky 是既有的 `test_rebuild_clears_previous_rows`（GUT 认为无强制断言，非失败）。
- 基线对比：本批前 612 测试 / 4522 断言 → 本批 617 测试 / 4544 断言（+5 测试、+22 断言全部来自本批新增），失败集合未变。
- `tools/check_content_parity.ps1`：3885 文件 / 0 违规（本批未碰 `content/`）。

### A12 仍剩

- **逐张卡的动画播放**（`OpCardNewController.Init 0x572f40`：按 op 切 Background/Equip/Card/Special/Tag 视图、`Animation` 片段、`Pop`/`PopText`/`PopStartTime` 弹出、`BGEft` 特效、`lifeCount` 寿命数字）**未接**；当前渲染的是纯文本行，不是原作演出。
- **`+0x182` 缓存标志与 `MoveOpCardsToResults`**：克隆没有"缓存/立即"两态，所有操作都进同一条流。
- **`+0x183` 门**：`AddCardOp` 开头 `if (*(char *)(param_1 + 0x183) == 0) { ... }`——该位为真时直接跳过入队（另有 `+0x182` 为真时先 `MoveOpCardsToResults`）。两态均未复刻，登记待修。
- `POP` / `HAND_POP` / `THINK_POP` / `REBIRTH_SUDAN_CARD` 四类**尚未记录**。
  - ⚠️ **本文件早先一版写过"`pop.` 键在全量 config 里 0 次出现、属不可达"——那是错的，已作废。** 错因是搜索口径：`pop.` 键不在 `result` 里，而在 **`cards_slot.sN.pops[].action.choose`** 里，例如 rite `5000576` 的 `{"choose": {"pop.5000576_s2_01.s2": "这个方法已经试过了。"}}`。`pop.` 是**卡槽弹出交互**（CardPop）的宿主，配置确实存在。
  - `CardPop` 的实际语义（`CardPop.c`）：构造函数 `(pop_id, selector)` 去重后 `Common.AddPop(pop_id, this)`，把 `OperationFilter(selector)` 挂到 `+0x20`；`PreDo 0x4f1e50` 与 `Do 0x4f1c70` 都只是 `Filter(riteContext+0x20, +0x14, callback)` 后跑 `DoSequence`，`<PreDo>b__1 0x5083a0` 会把 `OperationContext.ProcessPlaceholders` 的结果交给 `AddCardOp_Pop`。**克隆目前把 `pops` 当壳（不实现卡槽弹出交互层）**，因此这类记录要等有了弹出宿主才有意义，不是"缺一行记录"。
  - `REBIRTH_SUDAN_CARD` 的宿主是 `rebirth.s<n>`（规则侧已在第三十一批复核并修好两分支，见 [rebirth 分支证据](RebirthBranchCorrection.md)），缺的只是 `PreDo`（`<PreDo>b__1` 0x51ffc0 → `AddCardOp_RebirthSudanCard` 0x39e760）这一条表现记录。
