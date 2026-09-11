# NextDay 串行链与每日吸附（第二十一批，2026-09-10）

A13 原登记为"待复核现状：回到同一调用链审计副作用顺序，禁止把事件已修外推到整日"。本批回到 `OnNextRound` 的 Promise 闭包链，落了**链路顺序真值表**，并在链上找到一处真实缺口（每日 `AdsorbCards`）与一处真实偏差（吸附候选随机取）。

## 原作事实：OnNextRound 的闭包链顺序

`GameController.OnNextRound 0x554540` 先 `GameEventSender.NextDay` + `SaveRoundEnd`，随后挂 Promise 闭包。按闭包 RVA 与方法体（`GameController.__c__DisplayClass142_0.c`）：

| 闭包 | RVA | 主体动作（按书写顺序） |
| --- | --- | --- |
| b__0 | 0x5705b0 | — |
| b__1 | 0x570700 | — |
| b__2 | 0x570720 | — |
| b__3 | 0x570790 | 终局门（`+0x2c8`）→ **`player.round(+0x2C) += 1`**（无条件）→ 置 `+0x18=1` |
| b__5 | 0x570850 | `CheckAllRiteKnow` → `SFxManager.SetVolume` → `GetCurrentMusicLevel` → Animator 触发/SetActive → `MapController.ChangeBGToEnd`（终局分支）→ 返回 `+0x1a8` |
| b__6 | 0x570b00 | 终局门 → **遍历 `player+0x90`（`List<Rite>`）逐个 `RiteExtensions.AdsorbCards(rite, player)`** → `UpdateSudanLife` → `+0x300 = (+0x300 - 1) mod 2` → `HandCardAutoSort` → `HandCardAutoClassify` → `UpdateHandCards` → `UpdateHandCardPos` → `CardArrange` → `UpdateHandCardPos` |
| b__7 | 0x570e60 | `TryGenSudanCard`（+ UI 收尾） |
| b__8 | 0x570f90 | — |
| b__9 | 0x571000 | 红点/恢复周期（`round % sudan_redraw_times_recovery_round`）、日志与动画 |

字段身份由 dump.cs 独立确认（`Player`，TypeDefIndex 6274）：`+0x2C round`、`+0x88 List<Card> cards`、`+0x90 List<Rite> rites`、`+0xB0 List<Card> sudan_card_pool`。

**可确证的顺序结论**：

1. `round += 1`（b__3）**早于** b__6 的吸附与手牌整理，且无条件。
2. 每日吸附（b__6 开头）**早于** `UpdateSudanLife` 与 `TryGenSudanCard`（b__7），因此吸附看到的候选是**当回合抽苏丹卡之前**的手牌。
3. 手牌整理在吸附之后，且在 b__7 抽卡之前。

## 原作事实：AdsorbCards 0x38fca0

- 外层以 `player+0xB0`（苏丹池）的**索引**遍历 `rite+0x30`（槽数组）；`rite+0x30[index]` 为空才处理。
- 只处理 `RiteNode.Slot.open_adsorb@+0x20` 为真的槽（dump.cs:392740 起确认该字段布局：`guid@0x10 / condition@0x18 / open_adsorb@0x20 / is_key@0x24 / is_empty@0x28 / is_enemy@0x29`）。
- 内层按 `player+0x88`（`Player.cards`）**顺序**扫描，用 `ConditionContext` + `CanPutCard` 判定，**取第一个命中**：`RemoveCard(player, card.uid)` → `rite.cards[index] = card` → 记 Note(type 4)。
- 调用点有两个：`PlayerExtensions.InitRite`（创建时）与 `OnNextRound b__6`（每日）。

## 克隆偏差（已修）

1. **每日 AdsorbCards 缺失**：克隆只在 `add_available_rite` → `_adsorb_open_slots` 里做创建时吸附，`advance_day` 从不再吸附。结果是"已存在且已开启的 auto 槽永远不会在回合边界吃牌"。
2. **候选是随机取**：`_adsorb_open_slots` 用 `rng.range_int_half_open(0, candidates.size())` 随机挑一个候选，而原作按 `Player.cards` 顺序取**第一个**命中。这会让同一天吸附到哪张牌随 RNG 漂移；也给调用方凭空增加了一次 RNG 消耗。
3. **占用槽被当作中止**：原实现对"槽已有卡"返回 false 并回退整批；原作只是跳过空指针为假的条目。

## 修复

- `GameState.adsorb_open_slots(instance, db, rng)`：单个仪式的开启槽吸附，按槽序、跳过已占用槽、按手牌顺序取首个命中。
- `GameState.adsorb_open_slots_daily(db, rng)`：按 uid 升序遍历全部仪式实例。
- `RoundLoop.advance_day`：在 `day += 1` 之后、`_update_rite_instances` 之前插入每日吸附，结果写入 `result.adsorbed`。
- `_adsorb_open_slots`（创建路径）：去掉随机选择，改为 `candidates[0]`。

## 验证

- `tests/test_rite_view.gd` 36 测试 / 175 断言全绿。两处受影响 fixture 已按真实语义更新：`test_empty_slot_cycles_qualified_bags_and_keeps_empty_match_state` 现在显式断言"open_adsorb 槽取走手牌第一张（主角），因此合格页集合为 [0]"；`test_restore_last_rite_state_is_partial_and_reforms_stack_count` 先把被吸附的卡取回手牌再测 `OnLastState` 恢复，并断言金币堆仍在手。
- 全量 GUT：46 脚本 / 567 测试 / 565 通过 / 4339 断言中 4337 通过（`a13-full2.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败是既有的 `test_card_flash` 卡面几何与 `test_event_choice_controller` mask 高度，已在前批用基线对照确认与本批无关。

## 未完成与新增审计线索

- **Promise 链的精确插序仍未完全确定**：本批只能按闭包书写顺序与各闭包内部调用顺序确证 b__3 → b__6 → b__7 的相对位置。`NextDay`/`OnRoundBeginBa` 事件本身在反编译子集中没有 `GameEventSender` 文件，事件派发相对这些闭包的挂载点未直接读到，克隆现有的 `round_end`/`round_begin_ba` 位置**未改动**。
- **`b__2`/`b__8` 的方法体未被读出**（只在链中出现），其职责仍未知；不要按位置猜测。
- 每日吸附与"吸附后立刻整理手牌"的 UI 时序未接（克隆是数据层）。
- `AdsorbCards` 的 Note 写入（type 4，count 记被吸卡 id）在每日路径上尚未接；创建路径已有记录。
