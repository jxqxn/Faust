# A19 第40批：零数量与存档边界

## 来源与范围

直接重读 `CardSlotController.CardStack 0x53b0a0`：当 cost_count=0 且来源 count>0，余量仍是来源 count，Copy 后 set_count(0)，然后 SetCard 入槽。`Card.c @ set_count 0x383e80` 直接赋值并通知，不夹到1；独立 Card.count@0x20 字段和 CostCondition.PostProcess 0x3f6520 的 Min=0 分支支持该结构边界。

但遍历当前全部 `content/rite/*.json` 的 cards_slot 子树，零值成本、区间下界0、<及<=成本键合计 **0处**。因此这是原方法的边界，不宣称原作当前内容可达，也没有捏造零数量原机截图或原存档实例。

## 改正

- pay_cost_into_slot 接受 needed=0，按原拆分路径生成零数量切片；保留负needed的宿主参数拒绝门。
- CardInstance、SudanPoolCard、原作导入与池对拍行不再将原始count夹到1。原始字段按int保存，默认缺字段仍为1。
- 堆叠性从“字典里有可堆叠键”改为有效值>0。直接源码 `CardExtensions.HasTag 0x382250` 是 GetTag>0；零数量卡的GetTag乘count后为0，不应被认作可堆叠。
- 卡牌数量徽记现有条件count>1，与已有CardRender源指针一致，本批不添加自制零徽记。

## 验证方式

明确边界夹具：在复制的槽定义中设cost=0（不改ConfigDB与content），从4金币生成零数量槽卡，原卡仍4，序列化往返后总金币仍4。原作格式合成夹具同时验证手牌及苏丹池count=0导入与往返不变。该合成夹具不冒充原作实际存档。

既有正成本、替换、卡牌合堆、存档桥及存读档测试一并回归。最终计数收尾追加，日志zero-count-*.log。

## 剩余

A19仍缺完整吸附附加条件、聚合选择器快照边界、特殊标签门及演出/音频。负成本未作为已验证游戏行为开放；零数量往返外的其他GetCount特殊读法仍应按各方法验证。未修改content、未提交或联网。

最终验证：投放11/56、导入桥7/91、堆叠10/56、付款13/39、存档13/147，合计54测试/389断言通过。最终日志无SCRIPT ERROR、ERROR、失败、Orphans或泄漏；git diff --check通过。未重跑全量和实机截图，本批是状态边界测试，原作当前配置没有零成本实例。
