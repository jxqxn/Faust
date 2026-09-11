# A13 事件派发挂载点真值表（第三十二批）

A13 原文留的是两句不确定："事件派发相对闭包的挂载点仍无源（反编译子集缺 GameEventSender）"和 "b__2/b__8 职责未读"。**两句都作废**，原因如下。

## 更正一：`GameEventSender` 不是事件系统，是 PostHog 埋点

`GameEventSender` 一直都在反编译产物里（`engine_spec/decompiled/GameEventSender.c`，113KB、33 个方法），但它与游戏事件无关：

```
public class GameEventSender : MonoBehaviour // TypeDefIndex: 7251
    public static Dictionary<GameEventSenderType, PostHogSenderConfig> Configs; // 0x0
    public PostHogSender postHogSender; // 0x20
    // StartGame / NewGame / ContinueGame / NextDay / DoneRite / CardBorn /
    // OverGame / QuestFinish / UpgradeBuy / SudanRedraw / RoundBegin / ...
```

它是**遥测**：`PostHogSenderConfig` / `PostHogSender`、`OnApplicationQuit` 上报、`PostHogSender_LogMessageReceived`。方法名（`StartGame`/`NextDay`/`CardBorn`…）看起来像游戏事件，这正是当初误判的来源。

真正的事件系统是：

| 类 | 文件 | 职责 |
| --- | --- | --- |
| `EventTrigger` | `EventTrigger.c`（35KB） | 注册表 + 派发：`Add` 0x4fa9d0 / `Remove` 0x4fc3a0 / `On` 0x4fbc20 / `GetActiveEvents` 0x4fba90 / `DoSettlements` 0x4fb1c0 |
| `EventTriggerExtensions` | `EventTriggerExtensions.c`（30KB） | **28 个 `On*` 入口** |
| `EventNode` | `EventNode.c` | 配置节点 |

## 更正二：`b__2`/`b__8` 有源，只是必须带闭包类前缀

`b__N` 编号**每个闭包类各自从 0 开始**，所以裸写 `b__2` 无从查起。带前缀后 `GameController.__c__DisplayClass142_0.c` 里 `OnNextRound` 的 10 个闭包全可读：

| 闭包 | RVA | 关键内容 |
| --- | --- | --- |
| `<OnNextRound>b__0` | 0x5705b0 | — |
| `<OnNextRound>b__1` | 0x570700 | — |
| **`<OnNextRound>b__2`** | 0x570720 | **`EventTriggerExtensions.OnRoundEnd(controller + 0x298)`** |
| `<OnNextRound>b__3` | 0x570790 | — |
| `<OnNextRound>b__5` | 0x570850 | `CheckAllRiteKnow`、`GetCurrentMusicLevel` |
| `<OnNextRound>b__6` | 0x570b00 | `UpdateSudanLife`、`HandCardAutoSort`、`HandCardAutoClassify`、`UpdateHandCards`、`UpdateHandCardPos`×2、`CardArrange` |
| `<OnNextRound>b__7` | 0x570e60 | `TryGenSudanCard` |
| **`<OnNextRound>b__8`** | 0x570f90 | **无任何调用**（既无 `EventTrigger*` 也无 `GameController*`）——本批读空，职责就是空体 |
| `<OnNextRound>b__9` | 0x571000 | （`timing_rounds` 重臂，已在第二十一批核对） |
| `<OnNextRound>b__10` | 0x570600 | `DoGameOver` + `LogException` |

`round_begin_ba` 的挂载点在同族的 `GameController.__c__DisplayClass141_0.c` 的 `<Start>b__5` 0x56f9c0，第 138 行；它紧跟在 `*(int *)(player + 0x2c) += 1`（`round += 1`）之后——**与克隆第二十一批的结论一致**。

## 派发真值表（源 vs 配置 vs 克隆）

数据来源：`engine_spec/decompiled/*.c` 全量调用点扫描（排除 `EventTriggerExtensions.c` 自身的定义行）× `data/config/event/*.json` 的 `on` 块（1863 个文件）。

| timing | 源定义 | 源调用点 | 配置实例 | 克隆 |
| --- | --- | --- | --- | --- |
| `round_begin_ba` | ✓ 0x4fa570 | `DisplayClass141_0.<Start>b__5` 0x56f9c0 | **1381** | 派发 ✓ |
| `round_end` | ✓ 0x4fa730 | `DisplayClass142_0.<OnNextRound>b__2` 0x570720 | 0 | 派发 ✓（保留，有源） |
| `round_begin_fr` | ✓ 0x4fa650 | **无** | 0 | **本批移除** |
| `rite_end` | ✓ 0x4fa390 | `RiteResultPanelController.c` 1289 | 357 | 派发 ✓ |
| `card_clean` | ✓ 0x4f9110 | `RiteResultPanelController.__c__DisplayClass56_4.c` 16、`DesktopCleanCard.__c__DisplayClass4_1.c` 28 | 68 | 派发 ✓ |
| `counter` | （`OnCounterChanged` 无调用点） | counter 写入链 | 16 | 派发 ✓ |
| `game_end` | ✓ 0x4f9950 | `GameController.c` 2868 | 10 | 派发 ✓ |
| `rite_start` | ✓ 0x4fa480 | 2 处 | 7 | 派发 ✓ |
| `close_wizard` | ✓ 0x4f9690 | 2 处 | 5 | 派发 ✓ |
| `card_born` | ✓ 0x4f9020 | `GenCard.c` 298、`GenCoin.c` 125、`GenLoot.__c__DisplayClass16_0.c` 16 | 4 | 派发 ✓ |
| `close_begin_guide` | ✓ 0x4f94d0 | 2 处 | 3 | 派发 ✓ |
| `rite_cancel` | ✓ 0x4fa1b0 | 2 处 | 2 | 派发 ✓ |
| `sudan_redraw_start` | ✓ 0x4fa8f0 | 2 处 | 2 | 派发 ✓ |
| `open_rite_end` | ✓ 0x4f9c10 | 2 处 | 1 | 派发 ✓ |
| `close_prompt` | ✓ 0x4f95b0 | `PromptController.c` 133 | 1 | 派发 ✓ |
| `rite_can_fill` | ✓ 0x4f9ee0 | 2 处 | 1 | 派发 ✓ |
| `back_to_prev_round_end` | ✓ 0x4f8e60 | `DisplayClass141_2.<Start>b__13` 0x5701b0（53 行） | 1 | 派发 ✓ |
| `open_card_info_end` | ✓ 0x4f92f0 | 2 处 | 1 | 派发 ✓ |
| `rite_can_stop` | ✓ 0x4fa0c0 | 2 处 | 1 | 派发 ✓ |
| `open_rite` | ✓ 0x4f9d00 | 3 处 | 1 | 派发 ✓ |
| `open_card_info` | ✓ 0x4f93e0 | `GameController.c` 4714 | 1 | 派发 ✓ |
| `show_wizard_option` | ✓ 0x4fa810 | 2 处 | 1 | 派发 ✓ |
| `rite_can_start` | ✓ 0x4f9fd0 | 3 处 | 1 | 派发 ✓ |
| **`card_dead`** | ✓ 0x4f9200 | **无** | **0** | **本批移除** |
| `rite_begin` | ✓ 0x4f9df0 | `GameController.__c__DisplayClass193_0.c` 21、`RitePanelController.__c__DisplayClass34_0.c` 42 | 0 | 未派发 |
| `rite_clean` | ✓ 0x4fa2a0 | `CleanRite.__c__DisplayClass3_1.c` 24、`__DisplayClass3_3.c` 24、`RiteExtensions.c` 49 | 0 | 未派发 |
| `OnCounterChanged` | ✓ 0x4f9770 | **无** | —（配置用 `counter`） | 用 `counter` ✓ |
| `OnGlobalCounterChanged` | ✓ 0x4f9a30 | **无** | — | 用 `global_counter` ✓ |

### 三条结论

1. **无源且无配置 → 从克隆移除**：`round_begin_fr`、`card_dead`。原作的死亡面是卡自己的 `vanish` 块 + `card_clean`，不是 `card_dead` 时机。克隆此前两处自发派发（`round_loop._update_card_lives` 与 `event_runtime._matches_trigger`）属自制，已删。实测零影响：全 1863 个事件配置的 `on` 块里没有 `card_dead`，所以那次 `fire()` 本来就匹配不到任何事件——但它会去碰 `timing_rounds` 的臂位，且把"存在 card_dead 时机"写进了克隆的公开行为。
2. **`OnCounterChanged` / `OnGlobalCounterChanged` 无调用点**，但配置里确实有 `counter` 时机（16 个实例）。克隆用 `counter` / `global_counter` 字符串派发，与配置键一致——**保留**。这两个方法名对应的机制在别处（counter 写入链），不是死代码问题。
3. **`rite_begin` / `rite_clean` 有源调用点但 0 配置实例**。克隆当前不派发 `rite_begin`；`rite_clean` 在 `round_loop` 里有派发。两边都无实例可验，**登记为低优先待接**（需要时按调用点补，不必现在动）。

## 本批改动

- `sim/event_runtime.gd`：`ROUND_TIMINGS` 由 `["round_begin_ba", "round_begin_fr", "round_end"]` 收窄为 `["round_begin_ba", "round_end"]`（`round_begin_fr` 从未被 `fire` 过，是名单里的死项）；`_matches_trigger` 的卡牌时机组去掉 `card_dead`；上下文文档同步。
- `sim/round_loop.gd`：`_update_card_lives` 不再 `trigger_events("card_dead", ...)`，改为注释记录为什么不能派发（含完整 SRC 指针）。

## 验证

- 全量 GUT：53 脚本 / 618 测试 / 615 通过 / 4547 断言中 4545 通过，零 SCRIPT ERROR、零 orphan、零泄漏；两条失败仍是既有 `test_card_flash` 与 `test_event_choice_controller`。
- 未改任何测试断言——移除的两条派发本来就匹配不到事件，所以没有测试依赖它们（这正是"自制行为被钉在测试里"的反面：这里没有钉子，说明它确实是空转）。

## 仍未做（A13 剩项）

- **`rite_begin` / `rite_clean` 派发**：有源调用点，0 配置实例，低优先。
- **`EventTrigger.DoSettlements` 0x4fb1c0 的结算链**：配置 `settlement` 块的执行顺序未与本表交叉验证。
- **`+0x298` 的连接方式**：`On*` 全部取 `controller + 0x298` 作为 `EventTrigger`；克隆是 `GameState.event_runtime` 直接持有，等价，但未逐点对照 28 个入口的 owner 是否都是同一个 `+0x298`。
