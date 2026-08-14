# 报告五：卡牌实例/区域流转/标签/计数器系统（2026-08-15 第二批完成）

主文档：[`AUDIT_2026-08-15.md`](AUDIT_2026-08-15.md)。事实来源：`engine_spec/decompiled/*.c`、`dump.cs`、`data/config/tag.json`、克隆 `content/` 统计。

## A. 发现清单（按严重度）

**A1【高】装备标签贡献用错标志位：can_nagative_and_zero ≠ 装备继承门**
- 克隆证据：`sim/game_state.gd:227-237`，`_equipment_tag_contributes` 用 `can_nagative_and_zero` 做装备贡献门；其 SRC 注释（234-236 行）明确主张"0x43 是装备继承门而非 can_inherit"。
- 原作证据：`CardExtensions.c @ GetTag (RVA 0x3814a0)` 1604 行——装备递归门是 `tagNode+0x42`；`dump.cs:386944-386950`——0x40=can_add、0x42=can_inherit、0x43=can_nagative_and_zero。0x43 的真实用途在 1619-1622 行：非负标志未置位且合成值 <1 时把**报告值**掩码为 0。
- 量化：tag.json 中 can_inherit=1 且 can_nagative_and_zero=0 的标签 **98 个**（影响力、污名、不满、贵族、部队、弓箭、囚徒、受伤、博爱等），克隆全部不继承装备贡献；反向（neg=1 而 inherit=0）为 0 个，故只有漏继承、无错继承。克隆目前只让 9 个双 1 标签（体魄/魅力/智慧等属性系）继承。
- 一句话正确行为：装备贡献标签的门是 can_inherit(0x42)；can_nagative_and_zero(0x43) 只控制 GetTag 负值掩码。克隆的 SRC 注释被 dump.cs + 反编译双重否定。

**A2【高】total 遍历无条件排除 lost 卡，与原作条件性排除不符**
- 克隆证据：`sim/operation_filter.gd:13`——`is_lost or zone=="removed"` 一律跳过。
- 原作证据：`OperationFilter.c @ IsMatch (RVA 0x3a1880)` 815-832 行、`@ Filter (RVA 0x3a13c0)` 707-721 行——IsLost 排除**仅在**单 id 选择（标志 0x40000000）或 id 排除集（标志 0x20000000）置位时执行；纯标签谓词不过滤 lost。且 `CardExtensions.c @ IsLost (0x382870)`：lost 是标签判定（GetTag>0），lost 卡仍留在 player.cards 中。
- 一句话正确行为：`total.<标签>±X` 在原作会命中 lost 卡，只有 `total.<id>±X` 与 `~<id>` 形式排除 lost。

**A3【中】count 只存不操作：CardStack/CardSplit 全缺 + GetTag 的 ×count 放大缺失**
- 克隆证据：`sim/card_instance.gd:12` count 仅存储/存档，无合并拆分 API；金币走独立 coin_count。
- 原作证据：`CardController.c @ CardStack (0x5286b0)`——同 id 且**双方都有"可堆叠"标签**才合并：dest.count+=src.count 后 `PlayerExtensions.RemoveCard(src)`；`@ CardSplit (0x528580)`——count>n 时原卡减 n、`CardExtensions.Copy` 新卡置 n；`CardExtensions.c @ GetTag (0x3814a0)` 1623 行——最终返回 `值 × card+0x20(count)`。
- 量化：原作 132 张卡带 可堆叠 标签（金币/秘密/洞察/机遇/内幕/预兆/战术/宝石系 14 张/苏丹的耐心系/倒计时…）。克隆里这些卡以独立实例累积，数量语义全部丢失。
- 一句话正确行为：同 id + 双方可堆叠 → 合并计数；标签查询按张数放大。

**A4【中】GetRealChangeValue 回退值：原作取上下文首卡 count，克隆文档写成 tag 值且是死代码**
- 克隆证据：`core/counter.gd:33-41` 注释称 "delta = the acting card tag value (card column[0] +0x20)"；全仓无调用方。
- 原作证据：`ModifyCounter.c @ GetRealChangeValue (0x515d60)` 237-262 行——op≠SET 且静态值=0 时返回上下文卡列表首卡的 +0x20 字段，即 **count**（+0x20=count 由 CardSplit/CardStack 两处交叉确认）。
- 缓解：克隆与原作配置中 `counter±<id>: 0` 均为 0 次（只有 `=<id>: 0`，SET 不走该路径）→ 当前内容不可达；但注释事实错误 + 死代码是待触发陷阱。

**A5【中】`total.change_card_name/text.<rite>_<seq>.<卡id>` 形式未实现**
- 克隆证据：`sim/result.gd:461-465` `_is_change_card_copy_key` 只认 parts[2]=`s<n>`；`total.` 前缀形式无任何分支，落 DSL 审计。
- 原作证据：原作配置 8 处（`total.change_card_name.5321215_01.2000195` 等），且克隆 content 已原样带入这 8 处（rite 5321215-17/5008205 已克隆）→ 克隆内可达但未支持。

**A6【低】SET 语义：克隆直赋 vs 原作相对调整**
- 克隆证据：`core/tag.gd:43-44` `tags[tag]=amount`。
- 原作证据：`CardExtensions.c @ ConvertToAddOrSub (0x37f360)` 1049-1068 行——can_add=true：delta=target-current 走 Add/Remove；can_add=false：current≥1 时 no-op、current<1 且 target≥1 时 Add(target)、target<1 时 Remove(current)。
- 影响面：369 个 can_add=0 标签被 `=` 时行为不同；现内容 `=` 键多在选择器比较位，直接 SET 罕见。

**A7【低】RemoveTag 的整键删除路径未克隆**
- 克隆证据：`core/tag.gd:38-42` 无条件减法，注释称 "no erase"。
- 原作证据：`CardExtensions.c @ RemoveTag (0x382e40)` 2166-2191 行——can_add=false 且键仅在运行时字典（模板 +0x68+0x58 无此键）→ **整键删除**；装备槽标签（tagNode+0x10）→ 转发 RemoveEquipSlot n 次。can_add=true 分支无钳制（克隆主干正确）。
- 说明：克隆把模板/运行时标签合并为一份初始 dict，结构上无法复刻"回退模板值"，可见差异多数被负值掩码抵消（但见 A8）。

**A8【低】GetTag 负值掩码缺失**
- 原作证据：`CardExtensions.c @ GetTag (0x3814a0)` 1619-1622 行——!can_nagative_and_zero 且值<1 → 报 0。克隆 effective_card_tags/matches_card_data 读原始存储值，`<1`/`=-1` 类比较在负值区间分歧。

**A9【低】金币卡 id 注释错误**
- 克隆证据：`sim/game_state.gd:42` 注释称金币卡 2000093；该 id 在原作与克隆 cards.json 均不存在，真实金币卡 **2000029**（变体 2000813/2001185/2001190）。纯文档错误。

**A10【信息】装备卡在 total 作用域的可达性（原作自身不一致）**
- 原作：DSL `+equip`（`ModifyEquip.c @ HandleCard 0x516ab0`）AddCard 后留在 player.cards → total 可达；交互装备（`CardController.c @ CardEquip 0x528020` 2660 行）RemoveCard → total 不可达。
- 克隆：select_total 含 zone="equipped" → 等价于原作 DSL 路径。记录备查即可。

**A11【信息】被排除 scope 选择器的缺口规模 = 0**
- parent/friend/enemy/all/self/~ 在克隆与原作全部可达配置中出现 **0 次**——当前排除无内容缺口。
- 附带澄清：`sudan` 不是 scope 关键字而是**标签谓词**——原作 20 张 sudan 型卡全部带"苏丹卡"标签（tag.json:4334 code=sudancard），`total.sudan` 在原作等价于 苏丹卡>0；克隆用 type=="sudan" 判定，对现有内容等价。

## B. 已验证正确（简短）

1. ADD 的 can_add 门（`can_add or 当前<1`）== ConvertToAddOrSub '+' 分支（0x37f360:1001-1014）。
2. SUB 无钳制主干 == RemoveTag can_add=true 分支。
3. tag.json 与原作字节一致（MD5 4b64ede0…）。
4. Counter op 分发 1/2/3/else（ModifyCounter.c @ Do 0x5159c0:129-141）；Add/Sub 全部经 SetCounter（PlayerExtensions.c:891-915）。
5. SPECIAL_NONNEG_ID=0x6c5667 钳 max(v,0)（SetCounter 0x38f2d0:941-966，另确认该 id 存于全局对象+0x7c 而非 player 字典）；静态注册表钳 0（982-990 行）与克隆 register_nonneg 机制结构对应。
6. +equip 生成新卡再装备（result.gd:657-663）== HandleCard AddCard(1)+AddEquip；-equip 回手牌/~equip 摧毁（result.gd:670）== +0x31 标志。
7. 交互装备门：CanEquip（0x37ec10，手牌宿主+装备标签+槽位交集+容量替换首个占用）与 attach_equipment(recover_replaced=true) 对应；DSL +equip 绕过门 == AddEquip（0x37e5d0）无槽位检查。
8. return_rite_cards 主体 == ReturnCards（0x5016d0，全部 rite.cards → AddCard 回 player）。
9. OperationFilter 结构解析：s1-s99 槽位、int 单 id、`!`/`~` id 排除集、regex 标签比较（缺省值 1）、裸标签谓词，克隆 matches_card_data 的对应关系成立；total 遍历源 = GetTotalCards（player.cards ∪ 各 rite.cards，PlayerExtensions.c:2718-2800）。
10. change_name（排队提示）与 `change_card_name.<x>.s<n>` 形式已覆盖；change_rite_name 在两侧配置 0 出现。

## C. 无法验证（不编造）

1. 5 个 scope 关键字的字面值与 friend/enemy 区分：DAT 常量为 opaque 指针，bit2/bit4 在 Filter 中都路由到 GetEnemyCardsWithIndex，过滤逻辑在 lambda 缓存内不可读。配置 0 出现，不影响现结论。
2. Compare 默认比较子的精确身份（DAT_1825bdfa0）：裸标签缺省比较值=1 已确认，">0"（克隆）vs ">=1"/"==1" 无法从指针分辨。
3. SetCounter 静态非负注册表的成员来源：init/0.json、1.json 均无对应字段；若原作注册表含 0x6c5667 之外的 id，克隆 sub 可为负而原作钳 0。
4. CleanSlot/CleanRite 被清卡的最终落区（是否调 RemoveCard）未逐环验证；DoVanish（0x4f1310）确认只是 vanish-timing 事件分发器，非落区操作。
5. SudanPoolModifyTag 遍历的 player+0xb0 池列表构造细节（已确认复用同一 OperationFilter 列表过滤路径）。
