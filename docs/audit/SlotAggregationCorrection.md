# A19 第41批：替换快照与 SlotHasTag 聚合

## 原作事实

- `SlotHasTag.IsSatisfied 0x408cf0` 将累加器初始化为0，调用 `OperationFilter.Filter`，最后对总值调用一次 `Compare.Check`；闭包 `0x40bfb0` 每次执行 `sum += CardExtensions.GetTag(card, tag, false)`。独立注册与签名见 `dump.cs:417790`，不是逐张任一满足。
- `OperationFilter.Filter 0x3a15c0`：all（低位6）走 `GetAllCardsWithIndex 0x391960`；friend（2）和enemy（4）都走 `GetEnemyCardsWithIndex 0x392140`。
- 后者闭包 `RiteExtensions.__c.<GetEnemyCardsWithIndex>b__5_0 0x3937b0` 仅在 `slot+0x29 == 0` 时构造有效 `(card,index)`，即保留 **is_enemy=false**。`dump.cs:392754` 确认该偏移字段名，`dump.cs:388942` 确认闭包签名。不能按 Enemy 命名自行取反。
- `ForeachCards<ValueTuple<object,int>> 0x71c820` 遍历配置槽，经闭包 `0xd509f0` 读取对应 `Rite.cards`；空卡返回默认元组。没有在这个枚举器里递归装备。属性继承由 GetTag 处理。
- `RitePanelShowController.TryUpdateCard 0x598140` 暂时将目标 `Rite.cards[index]` 设为null后才构造上下文并验证，之后恢复。因此聚合和单槽条件必须观察同一份排除目标的状态。

## 修正范围

`ConditionEval` 的 all/friend/enemy 从统一的槽条目读取：UI替换预检使用显式快照；其他条件调用使用当前仪式的配置槽与实时卡牌。实时分支不再读取缺少is_enemy标记的table条目。所有所选卡的有效标签先求和再比较；空集合的总和为0。

保留原作反直觉的双bit同路和false极性。**不改变 FuncCompare 的 friends/enemys数组规则**：它是另一条独立取值链。原MANIFEST指出共用Enemy方法，但仅有方法名不足以决定实际选中的一侧；此处以闭包方法体和字段偏移为准。

## 验证与限制

新增边界测试明确使用原金币卡、2和3的实例数量以及合成投槽条件，验证求和5、非逐卡阈值、空集合0、反向条件、快照排除、两侧筛选和实时配置读取。生产RiteView测试覆盖替换时排除目标而保留其他槽、拒绝后状态恢复、成功后旧卡回手。

这些是源码契约边界夹具，不将绕过投槽条件放入金币的状态冒充原机可达样本。没有新增原机同帧截图或宣称全局1:1。self/parent索引、完整附加条件、特殊CanPutCard门、演出和音频仍未收口。

最终验证：聚合4/17、投槽12/64、仪式36/175、模拟59/181、原存档导入桥7/91，合计 **118测试、528断言通过**。五组最终日志无SCRIPT ERROR、ERROR、Orphans、泄漏或失败记录；`git diff --check`通过。日志保存在仓库外 `C:/Users/User/Documents/Faust-cleanup-20260911/aggregate-test_*.log`。Godot4.7已重新导入运行资源。未重跑全量、未联网或推送。

## 下一项已经定位的证据（尚未实现）

`CanPutCard 0x3918b0` 在配置条件成功后读取main的 `adsorb_spec` 标签：其有效值>0且 `ConditionContext.is_adsorb_spec@0x21=false` 时拒绝。`stringliteral.json:10791` 将DAT_18258ae08映射为adsorb_spec；`dump.cs:383851`确认标志偏移。`HasTag.c` 的单main分支在TagNode@0x58集合包含adsorb_spec时调用 `SetAdsorbSpec 0x385520`（直接置true），所以不能只增加全局拒绝而省略允许门。需要继续查TagNode字段与配置、条件执行顺序、Cost的is_cost绕过语义，再在共享投槽验证接入。
