# A19 第39批：指定槽替换

## 原作与旧偏差

`RitePanelShowController.c @ TryUpdateCard 0x598140` 保存目标索引的 Rite.cards 项，临时设空，以传入卡构造非首放 ConditionContext，调用该索引的 CanPutCard，然后恢复原值并返回结果。独立 `dump.cs:324304` 签名为 TryUpdateCard(int index, Card card)。

`CardDropManager.DropCard 0x4ef4f0` 在 CardStack 返回 false 后调 TryUpdateCard，失败直接拒绝，不寻找另一个空槽。成功进入 `CardSlotController.DropCard 0x53b720`；其首步 `RecoveryCard 0x53c660` 把原 current 通过 PlayerExtensions.AddCard 放回玩家，再清引用。

克隆此前遇到已占槽或不匹配槽会 `_first_satisfied_slot` 自动改投，与上述指定目标路径不符。临时清空仅改UI缓存也不够，条件读取必须看去除目标槽后的快照。

## 改动

- 删除显式拖到槽后的自动改投，先走成本堆叠，剩余路径验证指定目标并替换。
- `_try_update_card` 临时去掉目标槽，检查后恢复。普通槽预检带 use_slot_snapshot，槽号存在性和槽号标签查询使用此快照；结算仍读实时状态。
- 成功后复用既有退回手牌和落槽链。拒绝时原槽与手牌不变。

## 验证

生产投放组10测试/47断言，仪式组36/175通过；包含真实治理家业的贵族角色替换，错误投向金币槽不会自动转投其他槽，临时空目标的正反条件与恢复引用。测试发现一个不存在的2000007夹具，已更换真实2000001，不把无配置对象作为原作验收卡。

扩展 `verify_slot_cost_input.gd`：成本补齐后打开治理家业，把第二个人物实际拖到已占人物槽，检查旧人回手、另一仪式金币不变。1280与1920验证结果见最终日志。

## 保留范围

零成本卡仍未修复；原作特殊标签门、聚合选择器快照全域、自动吸附附加条件、入场缩放/配音仍开放。此次没有原机同帧对拍，不能宣称完整A19或全部清单完成。未修改content、未提交推送。

最终：卡牌堆叠10/56也通过，合计56测试/278断言；1280×720及1920×1080实际GUI拖动PASS。最终五份slot-replacement日志无失败、SCRIPT ERROR、ERROR、Orphans和泄漏，git diff --check通过。未重跑全量；此前两条UI失败和一条无断言风险未在本批修复。
