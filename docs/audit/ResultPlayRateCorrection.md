# 结算文字播速：两个档位、来自配置、按自动播放选择（第二十五批，2026-09-10）

A12 原登记为"rite_view result 播速/自动播放已有按钮，OpCard 播放链尚缺 / 按钮状态不代表实际奖励演出完成"。本批先取"播速"一侧的真源，把克隆自制的 x1/x2 循环换成原作的两档选择。

## 原作事实

`RiteResultPanelController.UpdateResultTextSpeed 0x5a74a0`：

- 参数是**布尔**（`param_2`），不是档位序号。
- `param_2 == 0` → 取 `Player.result_text_play_rate@0x68`；否则取 `Player.result_text_auto_play_rate@0x6C`。
- 取值被夹在 `[DAT_181c92b4c, DAT_181c9e4d0]` 之间，写进 `ScrollViewTextController + 0x38`。
- 两个常量按 PE 节 RVA 读 `GameAssembly.dll`：`0x1c92b4c = 0f`（0.5）、`0x1c9e4d0 = 100f`（100.0）。与既有先例（第一批同样用 PE 节读常量）一致。

`RiteResultPanelController.OnAutoPlay 0x5a38d0`：先写 `autoPlay@0x184`，再
`PlayerExtensions.SetRiteAutoResult(player, rite.id, autoPlay)`，**然后**调 `UpdateResultTextSpeed(autoPlay)`；若正等待结果且 `+0x178` 上挂着一个未完成的 Promise（`RSG_Promise +0x40 == 0` 表示进行中），把它 `Resolve` 掉。

字段身份由 dump.cs 独立确认（Player，TypeDefIndex 6274）：
`result_text_play_rate@0x68`、`result_text_auto_play_rate@0x6C`。

**配置实测**：`data/config/variable.json` 里只有两行——
`result_text_play_rate = 1`、`result_text_auto_play_rate = 15`。也就是说两档是 **1× 与 15×**，不是 1×/2×。

**贴图**：语料只导出 `play_speed_x1.png` 与 `play_speed_x2.png` 两张，没有 15× 的专属图。

## 克隆偏差（已修）

1. **自造 x1/x2 循环**：`_toggle_play_rate()` 把速率在 1.0 与 2.0 之间来回翻，完全不是原作的"按自动播放二选一"。2.0 这个数在原作里不存在。
2. **两份配置拷贝**：`_build_dice_surfaces()` 自己 `FileAccess` 读 `content/variable.json` 存进 `_result_text_rates`，而 `GameState.source_result_text_rate` 另有一份读取，两处可能漂移。
3. **速率被乘两次**：`_update` 里先按 `_result_auto_play` 从 `_result_text_rates` 取一档，**再**乘 `_result_play_rate`。自动播放时等于 1×15×15。
4. **`variable.json` 没有正式加载面**：ConfigDB 只加载 tag/cards/rite/event/... 与 init，没有 `variable_config`。

## 修复

- `ConfigDB.variable_config`：`load_all` 里 `_load_single(content_dir + "/variable.json", variable_config)`。
- `GameState.source_result_text_rate(auto_play)`：从 `variable_config` 读对应键，按原作常量夹到 `[0.5, 100.0]`，缺配置退回 1.0。
- `RiteView._refresh_play_rate()` 成为唯一速率写入点：向 `GameState` 取值并按 `_result_auto_play` 选择，同时决定按钮贴图（`<= 1.0` → x1，否则 x2）。两个 toggle 都改为调它。
- 删掉 `_result_text_rates` 字段与 `_build_dice_surfaces` 里的重复读取；`_update` 里的双重相乘改为单一 `_result_play_rate`。

## 验证

- 新增 `tests/test_result_play_rate.gd`（5 测试 / 13 断言）：`variable_config` 已加载且两键为 1 / 15；手动与自动分别取对应键；越界夹到 0.5 / 100.0；缺配置退回 1.0；面板按钮 meta 随自动播放开关在 1.0 ↔ 15.0 切换。
- 全量 GUT 见收尾记录。

## 未完成与新增审计线索（A12 主体仍未完成）

- **OpCard 奖励演出链仍未接**（A12 的核心）：`CardOpContext` / `OpCardNewController` / `RiteResultPanelController.AddCardOp 0x5a0e60` / `DoCachedOp 0x5a1a60` / `MoveOpCardsToResults 0x5a36f0` / `AddCardToResults 0x5a0ff0` 这一族没有落地，`_rebuild_result_lists` 仍是空实现并保留了原注释。本批只处理了播速一侧。
- **`ScrollViewTextController + 0x38` 的消费方式未核**：原作把速率写进这个字段，具体是每个字符的间隔还是整段的时长倍率需要回到 `ScrollViewTextController.c` 确认；克隆目前用 `_delta * 20.0 * rate` 的经验式推进 `visible_characters`，属于等价近似而非复刻，已在 `_update` 内保留原注释位置但未宣称等价。
- **`OnAutoPlay` 的 Promise 分支未接**：原作在"等待结果且有一个进行中的 Promise"时会 `Resolve` 它，克隆没有这条等待链（与 OpCard 链同源）。
- **15× 没有专属贴图**：`play_speed_x1/x2` 两张图覆盖不到 15× 这一档，克隆按 `> 1.0` 显示 x2，属于表现近似，登记。
