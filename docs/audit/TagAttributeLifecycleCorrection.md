# 第43批：标签附属属性生命周期

## 原作事实

`PlayerExtensions.AddCard 0x38b620` 按CardNode.tag键枚举TagNode.attributes并调用AddTag，不先判断配置标签值。`CardExtensions.ValidateTagAttributes 0x3831c0` 在增删后读取源标签的有效值，大于0则添加每个附属属性，否则移除。`Copy 0x37f4e0`先创建卡及装备，再逐项写入源运行态tag并对该项校验，最后赋count；不能先批量复制字典再统一校验。

`Datapool.BuildInTags 0x40d9b0` / `AddBuildInTag 0x40c610` 注册adsorb_spec为不可叠加、不可见内建标签，stringliteral 0x258AE08=adsorb_spec、0x25B3468=吸附指定。AddTag 0x37e6a0对已存在且无配置基值的不可叠加标记保留旧值，RemoveTag 0x382e40移除该键。独立TagNode字段can_add@0x40/attributes@0x58以及原auto_save uid120的adsorb_spec=1支持这一链。

## 改正

GameState新建卡初始化配置标签的附属属性；共享Result标签写入后执行校验。复制与拆分按源字典顺序写入、逐项校验，最后赋数量。当前tag.json中全部非空attributes仅使用吸附指定；其他未移植属性显式报错，未添加运行时内容表，也未修改content。

原作的写入顺序可能让多个来源共用的标记被后一个移除；本批没有自制引用计数或读取时求并集。复制边界测试明确验证两个相同键值、不同插入顺序会产生不同结果。

## 验证与限制

新增测试将新建哲瓦德的标记与原auto_save uid120比较；覆盖移除囚徒后标记删除、重新添加后恢复、重复校验不累加、复制顺序与当前属性键普查。第一次仅因原JSON浮点数和运行时整数的字典严格比较失败，改为数值比较后4测试/72断言通过。

仍未完成：普通标签AddTag/RemoveTag/ConvertToAddOrSub的所有非叠加与SET边界、池对象的附属属性写入、复制事件通知及完整拆分表现。当前Result入口的基础TagSystem语义仍可能影响源标签的有效值；不能用本批属性回调宣称所有标签增删已精确复刻。原作未知/复合tag和其他内建标签尚未全部移植。未联网或推送。

最终验证：属性4/72、标签模型13/47、投槽13/69、特殊门4/16、原存档桥7/91、堆叠10/56、模拟59/181，合计110测试/532断言通过。最终日志无SCRIPT ERROR、ERROR、Orphans、泄漏或失败；git diff --check通过。日志在仓库外Faust-cleanup-20260911的attributes-*.log，属性测试以-rerun结尾日志为最终结果。全量套件未重跑。
