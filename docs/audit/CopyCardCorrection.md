# CopyCard 复制运行时标签与装备（第二十三批，2026-09-10）

A20 原登记为"result rebirth 注释保留运行时标签复制未证实 / 不能用新生成或复制的近似规则代替"。本批把 `CardExtensions.Copy` 的方法体读出来，确认复制**携带**运行时标签增量、`count` 与装备树，而克隆原来是"从配置新建"。

## 原作事实

`CopyCard` 的执行链（`decompiled/CopyCard.c`）：

- `CopyCard.Do 0x4f51b0` / `PreDo 0x4f5330` 都用 `OperationFilter.Filter` 过滤上下文，再 `ListExtensions.DoSequence` 顺序跑闭包。
- `CopyCard.__c__DisplayClass4_1.c @ <Do>b__1 (0x508090)` 是真正做事的那一步：`CardExtensions.Copy(card, false)`，然后 `OperationContext.AddExtraResult_CardBorn` + `PlayerExtensions.NoteCardBeReward` + 用当前 `player.round@0x2C` 构造 `TimingContext` 触发 `EventTrigger.On`（即 `card_born` 时机）。
- `CopyCard.__c__DisplayClass4_0.c @ <Do>b__0 (0x507430)` 只是 `Where` 谓词（把过滤结果塞进列表），不是复制体。

`CardExtensions.Copy 0x37f4e0` 的正文（三信号一致）：

1. `PlayerExtensions.AddCard(source.id)` —— 新对象按**定义 id** 建，不带任何运行时字段。
2. 遍历 `source.equips@+0x40`，对每个装备递归 `Copy(equip, keep_count=true)`，把复制品 `FUN_1800032d0` 追加到新卡的 `equips`；若复制品有 SFx 或配置 `sfx@+0x80` 非空，触发 `DAT_18258f6c0` 回调。
3. 遍历 `source.tag@+0x30`（运行时增量字典），逐项 `FUN_181040ca0(newCard.tag, key, value)` 写入 —— **运行时标签增量被复制**，随后 `ValidateTagAttributes`。
4. 当 `keep_count == false` 时 `Card.set_count(newCard.count@0x20 = source.count)` —— **count 被复制**；装备递归传 `true`，所以装备复制品不继承源 count。
5. `Card.life@0x24`、`custom_name@0x50`、`custom_text@0x58`、`rareup@0x28`、`bag@0x48`/`bagpos@0x4c` **都不在 Copy 内**。

## 克隆偏差（已修）

1. **`copy.*` 在结果派发里根本没接**：`ResultExec.is_supported_key` 早就把 `copy.s<n>` 判为支持，但 `_apply_key` 里没有对应分支，只有一个永远走不到的处理点。所以配置里 31 处 `copy.*`（`copy.s1`..`copy.s10`）此前是**静默空操作**——不是"近似"，是没执行。
2. **复制语义是"从配置新建"**：修好后原实现仍只做 `state.add_card_to_hand(instance.card_id, db)`，丢掉运行时标签增量、`count` 与装备树，而这三点都由 `CardExtensions.Copy` 明文复制。

## 修复

- 新增 `GameState.copy_card_instance(source_uid, db, zone)`：按定义 id 建新对象 → 复制源增量字典（`duplicate(true)`，不共享）→ 写 `count` → 递归复制装备（递归传 `count=1`）→ `attach_equipment` 挂回宿主 → 入 `hand`。
- `ResultExec._apply_copy_slot` 改为对每个匹配卡调用 `copy_card_instance`；`_apply_key` 开头新增 `copy.s<n>` 分派（此前完全没有）。
- `copy.<n>` 的循环次数沿用配置值（`maxi(int(val), 1)`），对应 `CardExtensions.Copy` 被调用 `count` 次。

## 验证

- 新增 `tests/test_copy_card.gd`（6 测试 / 24 断言）：增量随复制、增量字典不共享、`count` 随复制、`life/custom_name/custom_text/rareup` **不**随复制、装备递归复制（新对象 + 挂到复制品 + 喂进有效标签行）、未知源返回 0、`copy.s1` 逐单位复制。
- 全量 GUT：48 脚本 / 582 测试 / 580 通过 / 4384 断言中 4382 通过（`a20-full.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败仍是既有的 `test_card_flash` 卡面几何与 `test_event_choice_controller` mask 高度，与本批无关。

## 未完成与新增审计线索

- **`rebirth.s<n>` 仍未按源核**：本批只做了 copy 侧。`RebirthSudanCard` 的 `Do 0x519d60` 只被读过一次（克隆把它实现为"槽卡 life 归零 + 活动苏丹倒计时重置"），其第二分支引用的字面量（疑为"不朽"类标签豁免）仍未反查。A20 保持**部分已修**。
- **Copy 的 SFx 回调与 `AddExtraResult_CardBorn`/`NoteCardBeReward`/`EventTrigger.On` 链**：克隆只做了 `add_card_to_hand`（含 MarkCardGen / is_only 登记），没有按 `player.round` 构造时机上下文触发 `card_born`。`result.gd` 里 `card`/`g.card` 分支会触发 `card_born`，`copy.*` 分支未对齐，登记为缺口。
- **`copy.` 的过滤域**：`CopyCard.PreDo/Do` 用的是 `OperationFilter.Filter(ctx)`；克隆按 `copy.<selector>` 走 `_slot_target_uids`，其 `s<n>` 语义已核，但非 `s<n>` 选择器（配置里未出现）未展开。
- **装备递归的 `equip_slots`**：源复制品的槽位列表来自定义（`AddCard(id)`），克隆同；源不复制 `removed_equip_slots`，克隆亦不复制。
