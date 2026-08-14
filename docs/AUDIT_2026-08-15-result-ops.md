# 报告四：Result/Action DSL 执行器语义（2026-08-15 第二批完成）

主文档：[`AUDIT_2026-08-15.md`](AUDIT_2026-08-15.md)。事实来源：`engine_spec/decompiled/*.c`、`dump.cs`、`operations.json`、克隆 `content/` 统计。

## A. 发现清单

**A1.【High】`clean.rite` 语义完全反转：原作是"删除其它仪式实例"，克隆是"清空当前仪式槽位卡"**
- 克隆证据：`sim/result.gd:130-132`（`state.clear_rite_cards(state.active_rite_uid)`）
- 原作证据：`decompiled/CleanRite.c @ Do (0x4f3ae0)`：值是 `SingleOrListValues<int>` 的**仪式配置 ID**；`player.rites(Player+0x90).RemoveAll(...)`。谓词见 `CleanRite.__c__DisplayClass3_0.c @ <Do>b__0 (0x506280)`（值==1 分支：`r == context.rite 则排除`，其余全删）和 `3_2.c @ <Do>b__3 (0x507020)`（`r.configId == value 且 r != context.rite`）。dump.cs:313149（类定义）、313075-313128（显示类）。
- 配置量：审计内 10 处；原始语料 100+ 处（`clean.rite: 5000712` ×52、`clean.rite: 1` ×23 等，含 event 配置）。
- 正确行为：`clean.rite: <rite_id>` 从 player.rites 移除该配置 ID 的仪式实例（若它正是当前结算的仪式则跳过）；`clean.rite: 1` 移除**除当前仪式外全部**仪式。与"清卡"无关。

**A2.【High】`success`/`failed` 被无条件双执行；原作按 last_op_status 互斥分支**
- 克隆证据：`sim/result.gd:281-284`（两键都 `execute(val)` 并 merge）。
- 原作证据：`SuccessOperations.c @ Do (0x3a7930)`：`last_op_status != 1` 才执行，执行后**复位** status=0、tag=""；`FailedOperations.c @ Do (0x39d5a0)`：`== 1` 才执行，同样复位。状态机：`OperationContext.c @ SetLastOpState (0x3a0230)`（success→0/failed→1）、`get_last_op_success (0x3a0b60, !=1)`。`Confirm.c @ Do (0x4f4e30)` 通过 ShowConfirm 的 Promise<bool> 写入该状态——克隆 `confirm` 是空实现（result.gd:246）。
- 正确行为：同一 result 里 success/failed 只能跑一个（由上一个 confirm/option 类操作的结果决定），双跑会重复结算效果。配置中 failed 有 25 处引用。

**A3.【High】`choose` 语义错：原作是从子操作里"随机抽 N 个执行"，克隆做成玩家选择弹窗**
- 克隆证据：`sim/result.gd:100-103, 368-378`（choose → 玩家 choice prompt）。
- 原作证据：`ChooseOperations.c @ ctor (0x4f3a20)`（`choose:N` 后缀，N<1 归 1）；`GetOperations (0x4f3830)`：复制子操作列表，`N <= count` 时 `ListExtensions.Shuffle` + `GetRange(0, N)`——**洗牌取前 N 个**；`Do (0x4f3750)` 顺序执行。105 处引用，实测配置（rite/5000001.json）的 choose 值是 `{pop.xxx: "文案"...}` 字典＝随机弹一条结算文案。
- 正确行为：`choose{...}`（默认）随机执行 1 个子操作；`choose:N{...}` 随机执行 N 个。不是玩家选项（玩家选项是 `option`）。

**A4.【Medium】裸键 ModifyTag/ModifyRare 的"上下文卡优先"规则在原作中不存在；目标域=当前仪式全部卡按选择器过滤**
- 克隆证据：`sim/result.gd:522-537`（`_context_tag_targets`：有 `card_uid` 时只改那一张；无仪式时退回桌面卡）。
- 原作证据：`ModifyTag.c @ PreDo/Do (0x5182f0/0x518180)` 与 `ModifyRare.c (0x517f20/0x517db0)` 都是 `OperationFilter.Filter(filter, context.rite(+0x20), context.self_card_index(+0x14), action)`。dump.cs:394469：`+0x14 = self_card_index`、`+0x20 = rite`。`OperationFilter.c @ Filter(Rite,...) (0x3a15c0)`：`s<n>`→该槽位列表；id→全仪式卡按 id；`self`→self_card_index 处的卡；`parent`；friend/enemy(2/4 位)→同一 GetEnemyCardsWithIndex；all→全部。ctor (0x3a1b50)：数字→Id 位（ConvertIds 走 mod 重映射）、`!`/`~` 前缀→NotIds、比较式→TagCompare；Id/NotIds 过滤排除 IsLost 卡（纯 tag 过滤不排除）。
- 影响评估：当前 287 个裸键/853 处引用**全部**在 rite 结算（审计 kind 统计），且克隆 rite 结算 ctx 不带 card_uid（`round_loop.gd:272-277`），故现网行为≈等价；但事件上下文（带 card_uid）一旦出现裸键即错。架构性偏差，事件侧 `table.*` 已受影响（A6）。
- 正确行为：对**当前仪式的所有卡**执行选择器过滤（id/tag/not-id/self/parent），不存在"上下文卡独占"。

**A5.【Medium】`clean.s<n>`/`clean.<id>` 忽略数量值、缺 card_clean 事件、无堆叠/已装备处理**
- 克隆证据：`sim/result.gd:134-148`（值被丢弃，`clear_slot` 清整槽）；`game_state.gd:1338-1341`。
- 原作证据：`CleanSlot : SingleValue<int>`（dump.cs:313245 区域）；`CleanSlot.c @ OnReaded (0x4f4140)`：`值 < 1 → int.MaxValue`（全清）；PreDo/Do (0x4f4200/0x4f3fe0) 走同一 `Filter(rite, selfIndex)`；`CleanSlot.__c__DisplayClass4_0.c @ <Do>b__0 (0x507570)`：`remove_count` 递减、`card.count > remove_count` 时部分扣除（`Card.set_count`）、清卡发 `GameEventSender.CardClean`、index>15 的已装备卡走 `RemoveEquipByUId` 卸装。
- 配置量：`clean.sN` 共 ~2900 处，值分布 `1`×3363、`99`×27、`2/3/4/5/999` 等。
- 影响评估：克隆每槽只建 1 张卡（`game_state.gd:1420-1423` slot_cards 单值），值=1 清整槽≈原作清 1 张，主卡场景被模型掩盖；但丢失 card_clean 触发、堆叠部分扣除与卸装语义。
- 正确行为：按选择器从当前仪式清最多 `值` 张卡（值<1 全清），可堆叠卡部分扣数，每张发 card_clean 事件。

**A6.【Medium】`table.*`/`g.*` tag/uprare 作用域与收窄错误**
- 克隆证据：`sim/result.gd:766-800`（`_apply_table_tag`：仅 surface 卡 + rite_uid 匹配 + 上下文卡独占 + 数字选择器按 id）；`result.gd:591-602`（table/g uprare 同样按 contextual_uid 收窄）。
- 原作证据：`DesktopModifyTag.c @ DoTemplate (0x50e400)`：`Filter(filter, player.cards(Player+0x88))`——玩家**全部卡**，无仪式/上下文过滤；`DesktopModifyRare.c @ DoTemplate (0x50df50)` 同。dump.cs:391541（Player+0x88 = `List<Card> cards`）。
- 影响评估：`table.*` tag 键当前仅 15 处引用（全在 rite），uprare 裸键 363 处也全在 rite；事件侧带 card_uid 时会漏改原作会改的卡。
- 正确行为：table/g 作用域＝玩家全部卡按选择器过滤，与当前仪式、上下文卡无关。

**A7.【Medium】`card` 数组尾部规格被静默丢弃（count+N / 新卡标签修饰）**
- 克隆证据：`sim/result.gd:92-97`（Array 只取 `val[0]` 入手，其余丢弃）。
- 原作证据：`GenCard.c @ InitGenCard (0x510560)`：值列表 elem[0]=卡 ID（`Utils.TryConvertCardId` 重映射），其余元素若匹配两个 `+` 前缀规格之一→写入生成数量(+0x24)，否则 `TagModifies.AddModify` 作为**新卡的标签修饰**；`Do (0x5101d0)`：`AddCard`→`set_count(数量)`→`TagModifiesExtensions.Modify(tagModifies, 新卡)`→`set_bagpos(1)`→`PutCardOnTable`→`GameController.AddCard(card, onhand=true)`（dump.cs:320049）→card_born 事件。落区 onhand 与克隆入手一致。
- 正确行为：`card: [id, "count+N"或"标签±N"...]` 生成 1 张带数量与运行时标签修饰的新卡。

**A8.【Medium】`copy.s<n>` 未复制运行时标签/子卡；value 实为未用**
- 克隆证据：`sim/result.gd:563-575`（按配置 ID 新建实例；`copies = max(val,1)` 循环）。
- 原作证据：`CopyCard.__c__DisplayClass4_1.c @ <Do>b__1 (0x508090)`：`CardExtensions.Copy(card, 0)`；`CardExtensions.c @ Copy (0x37f4e0)`：`AddCard(player, card.id)` 新实例 + **复制 card+0x30 标签字典（ValidateTagAttributes）** + 递归复制 card+0x40 子卡列表。`CopyCard.c` PreDo/Do/OpTemplate（0x4f5330/0x4f51b0/0x4f52f0）只读 +0x20 filter，从不读 SingleValue 值——原作每匹配卡固定复制 1 份，值被忽略（配置全部为 1，克隆循环暂无实际偏差）。
- 正确行为：复制=同 ID 新实例 + 运行时标签 + 子卡（装备）递归复制，每匹配卡 1 份。

**A9.【Medium】counter "值 0 → 用上下文卡数量" 规则实现存在但未接线**
- 克隆证据：`core/counter.gd:38` 有 `real_change_value`，但全仓无调用（`sim/result.gd:400-419` 直接 `int(val)`）。
- 原作证据：`ModifyCounter.c @ GetRealChangeValue (0x515d60)`：`op != SET 且 op 值 == 0 → delta = context.cards[0].count(Card+0x20)`。
- 正确行为：`counter+<id>: 0` 表示"加上下文卡的张数"。

**A10.【Low】`table.clean.<非数字选择器>` 声称支持但空转；数字路径作用域也过窄**
- 克隆证据：`sim/result.gd:52`（is_supported 对任意 `table.clean.` 前缀返回 true）vs `result.gd:751-763`（`_apply_table_clean` 要求尾部是纯整数，否则静默 return）；`game_state.gd:1368-1382`（按 rite_uid/card_uid 收窄）。
- 原作证据：`DesktopCleanCard.c @ DoTemplate (0x4f8250)`：尾部进 `OperationFilter`（支持 id/tag/`!id` 多段 AND），数量 `值<1 → 99999999`，对 `player.cards` 全量过滤，无仪式/上下文收窄。
- 配置证据：`table.clean.2001090|正教的乙太` ×15、`table.clean.item|!2000913|...` ×7、`table.clean.正教的乙太` ×6、`table.clean.无主` ×4。
- 正确行为：非数字与多段选择器应按 OperationFilter 语义清玩家卡，或至少回到审计而不是空转。

**A11.【Low】金币建模为字段而非卡**
- 克隆证据：`sim/game_state.gd:597-605`（`coin_count` 字段，`add_coin` 加法）。
- 原作证据：`GenCoin.c @ Do (0x510b40)`：`GenCard(2000029)` 新建金币卡（COIN_CARD_ID=2000029，dump.cs:542407）上桌，`Card.set_count(值)`、`set_bagpos(1)`、`AddExtraResult_CardBorn`、`OnCardBorn` 事件；玩家"当前金币"= `PlayerExtensions.GetCounter (0x38ce70)` 对 id 7000105（COUNTER_CURRENT_COIN_COUNT_ID）**动态求和** player.cards + 全部仪式槽的金币卡。每次 coin 生成新堆 → 总量等效 +N（克隆加法在纯收支流上等价），但无 card_born 事件、金币不可作为卡被 clean/入仪式（`table.clean.2000029` 配置有 4 处）。

**A12.【Low】Id 选择器不排除 lost 卡；`counter` 前缀宽匹配**
- 克隆 `_context_tag_targets`（result.gd:528-537）与 `_apply_slot_tag`（726-748）对 id 选择器不检查 `is_lost`；原作 Id/NotIds 过滤一律排除 IsLost（`OperationFilter.c @ FilterInternal 0x3a1260`、IsMatch 0x3a1880）。另 `is_supported_key:48` 对任何 `counter` 前缀键（如 `counterX`）返回 true 而 parse 失败后静默——原作正则要求 `counter([+-=])(\d{7})`。

## B. 已验证正确（要点）

- **uprare 数值语义**：值=增量写入 `rareup`（Card+0x28），生效品级 `clamp(rareup+config.rare, 1, 4)`（`Card.c @ get_Rare 0x383c30` + `Utils.c @ ValidateCardRare 0x3ad230`）；克隆 `modify_card_rarity`（game_state.gd:257-265）delta+clamp 一致；负值合法（降品级，下限 1）。
- **delay_off**：单值 1 → `ClearDelayOp`（全清）；否则逐 id `RemoveDelayOp`（`DelayOff.c @ Do 0x4f7eb0`）——克隆 `_apply_delay_off` 逐字对应。
- **equip 族**：`+equip`：值→装备卡 ID 的 OperationFilter（add 模式要求 Id 位，`InitData 0x5171c0`），`AddCard` 新实例 + `CardExtensions.AddEquip` 直连，**无替换门**（`HandleCard 0x516ab0`）——克隆 `enforce_slot=false` 直连一致；`-equip`：`RemoveEquipByUId` 且不回卡；`~equip`：卸下后 `PlayerExtensions.AddCard(装备卡)` 归还玩家（+0x31 标志）——克隆 `detach(..., recover=true)` 一致。
- **Option/Case 结构**：`OptionBase {id,text,icon,items[{text,icon,tag}]}`（dump.cs:391107/391154）与克隆 `_apply_option` 的 payload 读取一致；`case:opN` 匹配 `status-2`、tag 匹配 `last_op_tag`、`def` 仅在 `status-2>=3` 时生效、命中后复位状态（`CaseOperations.c @ Do 0x399570`）——克隆注释与实现一致。
- **counter 基础**：add/sub/set = Get→Set（`PlayerExtensions.c 0x38be50/0x38f8a0/0x38f2d0`），注册集内 id 负值钳 0，特殊 id 0x6c5667 恒非负——克隆 `SPECIAL_NONNEG_ID := 0x6c5667` 相同。
- **GenCard 落区**：新卡 → onhand（`PutCardOnTable` + `AddCard(card, onhand:true)`），克隆入手一致；单 int 值路径正确。
- **total. 作用域**：`GetTotalCards` = player.cards + 全部仪式槽卡（`PlayerExtensions.c 0x38de90`）≈ 克隆 `select_total`。
- **正则注册表**：`sim/result.gd` 头注引用的 operations.json 各正则逐条一致。

## C. 无法验证的部分与原因

- **`<sel><op>s<n>`（"标签位"是槽名）的 equipIndex 语义**：`ModifyTag ctor (0x518500)` 里 TryGetTagData 失败后 `Utils.TryGetSlotIndex` 把槽名写入 +0x40，但消费逻辑在 PreDo 显示类 lambda（0x523780/0x524a70）内，本轮未读，无法断言其效果（疑似"移动到槽位"）。
- **friend/enemy 是否等价**：`Filter(Rite)` 中 Friend(2) 与 Enemy(4) 位都路由到 `GetEnemyCardsWithIndex`（0x3a15c0:595-598），未读 RiteExtensions 无法确认二者实际差异；克隆两者都拒绝（保持审计可见，安全）。
- **CleanSlot 全清卡的最终去向**：完整移除后的后续 ops 在 `CleanSlot.__c__DisplayClass4_1.c (0x507EC0)`，其中出现 `player` 与 `Card.get_Type`，未完整反编译，无法断言是删除还是按类型返还。
- **counter 负值钳制集合的完整成员**：原作是静态 HashSet（`DAT_1825885f0+0xb8+0x80`），在其 cctor 中填充，本轮未读；克隆用运行时注册制，成员等价性未证。
- **ChooseOperations.Shuffle 的 RNG 来源**（是否吃种子）未查；对克隆无现网影响。
- **事件上下文 rite=null 时裸键是否真的 NRE**：静态读代码显示会抛 NullReferenceException（`Filter(Rite)` 对 rite=0 直接 throw），但当前语料所有裸键都在 rite 结算中，无法用实机复核该边界。

**审计结论摘要**：克隆最严重的三个偏差是 clean.rite（语义反转）、choose（随机 vs 玩家选择）、success/failed（互斥分支被双跑）；其余为作用域/收窄类偏差，多数被"当前引用全在 rite 结算且每槽单卡"的克隆模型暂时掩盖。uprare、equip、delay_off、counter 基础、Option/Case 结构与原作一致。
