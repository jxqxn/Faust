# 剧情名称/描述的多目标与对象域（第十八批，2026-09-10）

取自A08登记的table/total首次命中return。按scope-filter MANIFEST导航，回到实际调用和列表遍历，未把通用筛选器注释当作行为结论。

## 原作事实

- ChangeCardName构造0x4f2a30的域值：table.=3，total.=5，sudan_pool.=4。字符串地址0x25998a0/0x259c6d0/0x2596bc8交叉确认。
- DoTemplate0x4f2130：table调用Filter(Player.cards@0x88)；total调用Filter(GetTotalCards(player))。PlayerExtensions.GetTotalCards0x38de90复制玩家卡列表，再逐仪式追加Rite.cards@0x30的非空卡，不递归装备。dump.cs:391488 Player / 388887方法签名独立支持。
- OperationFilter.Filter(List)0x3a13c0遍历到列表末尾，对每个匹配对象调用action；不是旁边的FilterFirst0x3a1060。dump.cs:394805起明确有两个不同接口。
- 数字ID的0x40000000标志同时检查IsLost。IsLost0x382870实际为GetTag(lost)>0，stringliteral0x25bf778=lost；tag.json3020270名称“遗世”，文案为失去ID、不可被ID检索。
- **旧导航注释需收窄**：IsMatch0x3a1880并非对任何选择器无条件排除lost；源代码将它放在ID/排除ID分支。本批仅改变数字ID的name/text入口，未把此结论扩展到纯标签选择器。

## 修复

克隆原实现从全部CardInstance挑第一个同ID：table还包含slot，total还包含装备和removed。现在由source_player_cards / source_total_cards映射原作根列表，遍历全部匹配项；total逐仪式按槽序追加，装备不参与。数字ID排除正lost标签，支持原存档code=lost与克隆既有名称=遗世表示；0不排除。

名称/描述仍写上两批恢复的原翻译键。没有将玩家输入的配置id覆盖混入本项。

## 验证

- card_evolution18测试/129断言：两张相同ID手牌全部改、table不改槽卡、total可改槽卡、装备/removed不改、正遗世及原存档lost代码排除、0可重新命中。
- 原存档导入桥新增table_operation_root_membership和total_operation_root_membership两行，直接从原作Player.cards/Rite.cards读取UID，对照宿主成员；真实auto_save及现有边界样本全部通过。桥6测试/83断言。
- 合计24测试/212断言，最终日志无引擎错误、orphan/泄漏报告。该批没有修改UI绘制，不重复截图作为行为正确的替代证据。

## 未完成与新增审计线索

PC手牌/活动苏丹在宿主分成两列，原Player.cards中交错枚举顺序尚未完整恢复；根成员对拍明确排序后比较，不能证明复制演出先后顺序。sudan_pool、非数字筛选、槽位self/parent及复制演出仍开放。通用RuntimeOperationFilter.select_total仍有自己的旧域逻辑，本批未未经全调用方验证就统一替换。

原存档tag使用英文code，而克隆运行时常用中文名称；对正lost已补当前边界适配。原存档tag是否为配置基础值之上的增量、与宿主effective_card_tags合成及同一标签双表示冲突，登记为下一批高优先核查候选，不以本批成员对拍宣称整个属性模型等价。
