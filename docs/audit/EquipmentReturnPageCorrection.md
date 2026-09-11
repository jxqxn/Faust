# 交互换装返回分页纠偏（2026-09-10）

A05 第八批。继续沿替换装备的返回调用核查分页与位置。

## 原作证据

- `CardController.c @ CardEquip 0x528020` 与 `CardInfoNewController.c @ DropCard 0x533550`：两处均调用 `BackToHandOrBag(old, host.bag, 0, true)`，不沿用旧装备原页。
- `CardDropManager.c @ BackToHandOrBag 0x4eef90`（`dump.cs:311018`）：先写 bagpos/bag。普通手牌分支调用 AddCard、UpdateHandCardPos、UpdateCardNumber；CardBagPanel 激活时另走 AddCardInBag/UpdateCardPos。
- `GameController.c @ AddCard 0x54ad40`：add=true 且 bagpos=0 时，用 hand 子节点数量赋 bagpos；`UpdateHandCardPos 0x559a70` 只收集 IsCurrentHandCard，排序后写1..N。CardEquip 对人物再调用一次 BackToHandOrBag，位于新装备 RemoveCard 之后。

## 修复与验证

交互替换（enforce_slot=true）的旧装备在移回手牌前改为 host.bag、bagpos=0，沿现有 rail 末尾追加路径返回。新装备移出后，对当前页按 rail 顺序写1..N；其他页不重新编号，DSL非交互回收不套用本规则。

- card_evolution 14/77：新增人物在第III页、旧装备残留第I页/pos19的换装；返回后第III页为人物/旧装备，pos1/2；第I页另一卡pos7不变。
- hand_pages 6/44、save_import_bridge 6/82（含原作auto_save样本）：合计26测试/203断言通过。
- 1280×720/1920×1080真实GUI槽位装备替换通过：旧装备归到人物第III页末尾，自动打开详情。日志 `approximation-equip-return-input-{1280,1920}.log`。
- 未发现引擎错误或orphan/泄漏报告。未改content。存档样本验证保存结构，不能冒充此操作的原机录制。

## 保留边界

本次验证普通当前手牌页；独立CardBagPanel排序/布局、非当前页直接API调用、IsHandCard完整标签语义、补回手牌标签、配音/RequestUpdateRite及拖起离槽时序仍未完成。原卡节点数量与克隆rail元素在隐藏/非手牌节点混入时的等价性仍需后续原机边界对拍。
