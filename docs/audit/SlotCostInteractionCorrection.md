# A19 第38批：成本拆分与补齐接入实际拖卡

## 来源与行为

直接复读 `CardSlotController.c @ CardStack 0x53b0a0`：传入卡须可堆叠。空槽/不同配置卡使用首放上下文，同配置已占槽先把两张 count 合在 current 上，再用非首放上下文重算；is_cost 未设置时回滚。该方法只检查 is_cost，不检查 CanPutCard 返回值，所以数量不足但匹配成本选择器仍可部分入槽。

同类合堆余量 = 合计 − cost_count；目标 current.count 写 cost_count，余量大于零写回 incoming.count，否则移除 incoming。`dump.cs` CardSlotController.current@0x148、ConditionContext.is_first_drop@0x22/成本字段独立确认对象身份。`CardDropManager.DropCard 0x4ef4f0` 先 CardStack，再在其返回 false 时走 TryUpdateCard/DropCard。

## 已接入

`RiteView.drop_card_on_slot` 与 `_place_card_in_slot` 先尝试成本分支，空槽调用既有 pay_cost_into_slot，合堆保留原槽卡身份和超额来源卡。`can_drop_card_on_slot` 使用同一成本上下文，允许逐步补齐。悬停查询临时合计后立即恢复计数，无持久写入。

删除槽位路径的通用 stack_cards 调用：无成本条件不能仅凭同配置ID无限合堆。旧卡面转发测试改用真实5000005 s2，不再以清空condition的自制夹具作为正确答案。普通不涉及成本的手牌合堆保持现有共享实现。

## 验证

- 原配置5000005 s2：10金币入槽后付3留7；先放1再放5得到槽3/手3，槽UID不变；先1再2移除来源卡；连续悬停不改数量；无关装备不能借金币支付。
- 跨仪式来源：10枚拆3后原槽保留7；精确3枚整体移动后原槽引用清除。
- `tools/verify_slot_cost_input.gd` 注入真实GUI拖动输入，1280×720与1920×1080均PASS。截图 `docs/ui_layout/slot_cost_{1280,1920}.png`，已查看1280截图。此为克隆输入验收，不是原机同帧像素对拍。
- 既有仪式组36测试/175断言、卡牌堆叠组10/56通过。新增生产落槽组结果见最终日志 `slot-cost-drop.log`。

## 仍开放

本批未声称完整A19：0成本产生的零数量卡、源TryUpdateCard替换/路由全链、自动吸附附加条件及成本执行演出的0.01缩放和配音仍需继续。跨槽数量与归属已测，但拖动起始就离槽的完整原作时序仍登记在A05。没有修改content、没有提交或联网。

最终验证：新增7测试/35断言，合计53测试/266断言通过；最终日志无SCRIPT ERROR、ERROR、Orphans或泄漏。初次同帧连续刷新产生待queue_free容器的中间孤儿报告，测试收尾等待2帧后确认释放，复跑日志干净。git diff --check通过。本批未重跑全量，既有两条UI失败与一条风险项继续保留。
