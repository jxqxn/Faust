# 槽卡拖回手牌合堆纠偏（2026-09-10）

属于 ApproximationAudit A05；只修本交互边界，不代表卡牌系统全部完成。

## 原作事实

- `decompiled/CardController.c @ CardStack (RVA 0x5286b0, dump.cs:317120)`：双方配置 id 相等，双方 HasTag(stackable)，目标 count 加来源 count，PlayerExtensions.RemoveCard(source.uid)，销毁来源 Controller，目标回到自身 bag/bagpos。方法没有来源必须手牌的限制。
- 独立调用信号：`CardDropManager.c @ DropCard (0x4ef4f0)` 调用 CardController.CardStack，再尝试 CardEquip；占用槽位目标另走 CardSlotController.CardStack。
- `CardController.c @ OnBeginDrag (0x5294e0)` 的槽位分支解除原槽关联，再进入统一拖动分支。克隆目前在落下成功时才更新槽位，属于尚未消除的时序差异；本次不声称原拖起/撤销全生命周期一致。
- 槽位可移动门沿用 `RitePanelShowController.Show 0x596450` 的 `!open_adsorb && !rite.start`，由共享 rite_slot_access 承载。结算 pending/committed 是克隆宿主阻塞状态，继续通过所在 RiteView 校验。

## 偏差与修正

1. CardWidget 原来拒绝所有 source=slot，导致可拖回手牌却不能放到同 id 卡上合堆。现在允许宿主校验后的槽位来源；槽位作为目标仍委托给槽控制器。
2. GameScreen 落下时从实际 CardInstance 检查来源所在域、仪式 UID、槽位以及运行状态，不信任 payload 声称的来源。重复落下已消费来源不会再次增加数量。
3. 成功合堆后，由原仪式面板重新读取实例槽位并刷新视图；不调用普通 return_card_to_hand，避免重新插入已消费来源。
4. 修正两处错误来源地址：CardSplit 实为 0x528580（不是 CardMoveUp 的 0x528390）；CardDropManager.DropCard 为 0x4ef4f0。

## 验证

- `test_card_stacking.gd`：10 测试/56 断言，新增真实 GameScreen/RiteView/CardWidget 链，覆盖运行中锁定、pending 锁定、消耗后的槽缓存、重复回调。
- `test_hand_preview_source.gd`：5/24；`test_rite_view.gd`：36/172。
- `test_save_import_bridge.gd`：6/82，包含原作 auto_save 样本导入对拍。该样本验证保存结构，**不是原作槽出合堆操作录制**；本动作语义证据来自上述原作方法与独立调用链。
- `verify_slot_hand_stack_input.gd`：1280×720 和 1920×1080 实际 GUI 拖动通过；手牌金币 5+槽位金币 3=8，来源消费，源槽状态和 UI 均清空。截图 `docs/ui_layout/slot_hand_stack_{1280,1920}.png`。
- UI 全组 81/1073，记录于 `approximation-slot-hand-ui.log`。本批合计138测试/1407断言通过，无引擎错误、orphan或泄漏报告；本批各日志前缀 `approximation-slot-`。

## 尚未完成

原作拖起即解除槽位与失败返回的完整时序、完整 active RectTransform 子树、独立 InputManager 选择/手柄持牌、槽位来源装备到人物，以及 A06–A24 的其他审计项仍需继续。不能将本批存档回归或克隆输入通过登记为原机同帧视觉验收。
