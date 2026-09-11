# A19 第42批：吸附指定的投槽门

## 原作证据

- `RiteExtensions.CanPutCard 0x3918b0` 先执行槽配置条件；条件失败立即返回。成功后，若main存在且 `GetTag(main, adsorb_spec, false)>0`，只有上下文 `is_adsorb_spec` 为true才允许。
- `HasTag.IsSatisfied 0x3fe5a0` 在单main分支读取 `TagNode.attributes@0x58`，若包含adsorb_spec，调用 `ConditionContext.SetAdsorbSpec 0x385520`；随后才读取被检查标签并Compare。标志不取决于本次比较成功与否。
- `SetAdsorbSpec` 直接将 `context+0x21` 置1；`dump.cs:383851`确认该字段，`TagNode`字段声明确认attributes字典；`stringliteral.json:10791` 将 `0x258AE08` 映射为adsorb_spec。
- 原 `content/tag.json` 囚徒（prisoner）attributes为 `{"吸附指定":1}`，原加载链翻译为code。宿主保留原配置字节，所以读取原名和已翻译code两种表示。
- 原存档 `save_samples/auto_save.json` uid120/id2000346哲瓦德的运行态tag为 `{"adsorb_spec":1}`，配置tag为 `囚徒1、哲瓦德1`。这是实际保存状态，不是本批手写状态。
- 原 `CardStack 0x53b0a0` 仍以is_cost而非CanPutCard布尔值作为后续付款门；不能顺手把特殊标签拒绝改成所有付款的前置拒绝。

## 改动

新增共享 `ConditionEval.can_put_card`，按原条件→特殊门顺序计算；RiteView的手动预检、替换、成本探测及GameState的候选仪式/吸附路径接入。空配置条件仍会经过特殊门。

`eval_acting_tag` 在实际执行该标签条件时、比较之前设置is_adsorb_spec；沿用同一上下文的any/all短路语义。不预扫描整棵条件树，也不把标志存入卡牌或跨探测缓存。

## 验证边界

直接导入原auto_save的哲瓦德验证：空槽条件拒绝、囚徒条件通过、阈值不满足仍拒绝、失败的标签条件可为随后成功的any分支设置标志、被短路跳过的标签条件不能授权。生产View验证拒绝保持手牌、许可后实际入槽；候选/吸附入口使用同一规则。

另有明确合成的金币标记夹具，仅用于验证CardStack忽略CanPutCard布尔而尊重is_cost的边界，不宣称这种金币来自原作存档。

最终回归：特殊投槽4/16、生产投槽13/69、生命周期16/57、卡牌实例11/51、仪式界面36/175、原存档导入桥7/91，合计 **87测试、459断言通过**。六组日志无SCRIPT ERROR、ERROR、Orphans、泄漏或失败；`git diff --check`通过。日志位于仓库外 `C:/Users/User/Documents/Faust-cleanup-20260911/adsorb-test_*.log`。

## 未完成与下一步

投槽门对**已有**原作标记有效，不代表标签属性维护已完整：`CardExtensions.ValidateTagAttributes 0x3831c0` 在源tag有效值>0时对attributes逐项AddTag，否则RemoveTag；AddTag 0x37e6a0、RemoveTag 0x382e40及Copy0x37f4e0有调用。当前宿主的增删标签与新建/Copy仍需系统接入这条链，不能简单从每次读取临时推导，也不能把多个源tag的attributes自行求和替代原作写入顺序。

全量测试、完整自动吸附成本附加条件、self/parent索引、演出与音频仍未完成。本批未修改content、未联网、未提交或推送。
