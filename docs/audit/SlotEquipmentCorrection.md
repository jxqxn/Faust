# 槽位装备来源与自动详情纠偏（2026-09-10）

ApproximationAudit A05 第七批。沿上批槽出合堆继续查通用拖放分支，没有以另一套目测参数替换原作规则。

## 已确认原作事实

- `decompiled/CardExtensions.c @ CanEquip (0x37ec10, dump.cs:388255)`：目标调用 IsHandCard；来源检查 GetTag(equipment)>0，以及来源类别与目标 equip_slots 的交集。**来源没有必须位于手牌的条件**。
- 独立调用链：`CardDropManager.c @ DropCard (0x4ef4f0)` 对手牌目标先 CardStack 再 CardEquip；`CardController.c @ CardEquip (0x528020, dump.cs:317123)` 对同一个来源调用上述 CanEquip，替换旧装备、AddEquip、RemoveCard(source)。
- 槽位拖动仍受 `RitePanelShowController.Show 0x596450` 的 `!open_adsorb && !rite.start` 门控制。原作槽位来源在 OnBeginDrag 解除关联；克隆暂在成功落下时解除，此时序尚未完成。
- `CardController.CardEquip` 尾部调用 `GameController.ShowCardInfo 0x556c60`。后者检查的 `+0x128` 是 WizardController（dump.cs:319777），不能误认作仪式面板；`+0x118` 才是 RitePanelShowController。原作仪式打开时仍能进入人物详情流程。
- `CardInfoNewController.DropCard 0x533550` 对已打开详情执行 RefreshAllEquips/RefreshAllTags。不能把更新当作点击同一卡而切换关闭。

## 修正

1. 移除 GameScreen 和 attach_equipment(enforce_slot) 中装备来源必须 hand 的自制限制，允许可编辑槽位来源；状态层仍校验运行中/自动吸附槽不可移动。
2. UI 从 CardInstance 的真实 UID/zone/rite_uid/slot_key 检查来源，复用合堆的宿主 pending/committed 阻塞校验，不相信过时 payload 的来源描述。
3. 合堆/装备共用离槽通知：只重载原仪式实例槽位，不重新加入来源卡到手牌。来源装备保留 UID，zone 改 equipped；旧装备正常返回。
4. 成功装备后首次自动打开目标人物详情；同一人物已打开则刷新，避免触发点击切换关闭。

## 验证与证据限度

- card_evolution 13/70、card_stacking 10/56、hand_preview_source 5/24、save_import_bridge 6/82、UI 81/1073：**115 测试/1305 断言通过**。日志前缀 `approximation-slot-equip-`，未发现引擎错误、orphan/泄漏报告。
- 新回归覆盖源槽运行锁、结算 pending 锁、直接状态调用、替换旧装备、新装备离槽/入人物、槽位缓存更新、首次详情打开及重复回调。
- `verify_slot_hand_stack_input.gd -- --equipment` 在1280×720/1920×1080验证真实GUI拖动、sticky、武器替换、来源槽清空、自动详情。截图 `docs/ui_layout/slot_hand_equip_{1280,1920}.png`。
- `verify_card_equipment_input.gd` 同两种分辨率验证手牌装备自动开详情、再拖第二武器到详情替换及UI更新。
- auto_save 样本导入对拍证明本批未破坏现有保存结构验证；它不是原作本操作的运行录像。截图为克隆实机，不作为原机同帧像素一致证据。

## 仍需继续

IsHandCard 本身是三类标签判定，不等于克隆 zone；目标域完整等价尚未恢复。装备类别查找/占位计数的 runtime tag 读取、旧装备回到目标bag及位置、补回手牌标签、配音、RequestUpdateRite、拖起立即离槽/取消回位仍须单独迁移。保留在A05，不将本次通过外推为完整装备链完成。
