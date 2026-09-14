# 卡牌、标签与持久化

## 当前采用的规则

卡牌以UID区分实例，模板、运行时增量、装备贡献和堆叠数量分别承载。标签读取不能用一份可变字典代替完整GetTag；自定义名称、译文键和显示文本也不是同一字段。原作Player.cards、仪式槽、嵌套装备、苏丹池是不同对象域。

本次修正：AddTag的非零增加调用登记一次gen_tags，减法和无效重复增加不登记；bag_positions排除removed墓碑。SET/转换、附属属性、装备继承的完整边界必须继续对照源码，不能从当前标签总量倒推历史生成次数。

保存验收同时检查对象、队列、上下文和恢复后的真实输入。旧文的v5/v7/v9数字只对应当时迁移记录，当前兼容门由sim/save_system.gd和测试决定。原作存档未包含完整Unity随机状态，同刻导入一致不证明次日随机结果一致。


## 按状态问题阅读

| 问题 | 合并后的判断与证据 | 当前解释边界 |
|---|---|---|
| 卡牌是什么 | [复制](#e011)、[苏丹池](#e052)、[存档模型](#e066)共同定义对象域和实例身份 | 配置id、运行UID和池中对象不能混同 |
| 标签如何算 | [基准与增量](#e054)、[附属属性生命周期](#e053)、[聚合](#e043)、[零数量](#e055)按读值、写值、生命周期分别处理 | 历史gen_tags计数不是当前属性之和，SET/附属属性完整边界仍待核验 |
| 名称与描述如何变 | [译文](#e015)、[改名键](#e016)、[多目标范围](#e017)、[状态域](#e035)联合约束 | 显示文本、译文键、实例覆盖与玩家级覆盖不可互换 |
| 修改后如何恢复 | [校验](#e036)、[输入面](#e034)、[换装返回页](#e021)、[重生分支](#e032)分别保留来源与输入证据 | 只看最终字段不能证明重建后的UI及等待队列正确 |

## 证据模块

- [CopyCard 复制运行时标签与装备（第二十三批，2026-09-10）](#e011)
- [剧情描述键与详情显示（第十七批，2026-09-10）](#e015)
- [剧情改名键及默认译文纠偏（第十六批，2026-09-10）](#e016)
- [剧情名称/描述的多目标与对象域（第十八批，2026-09-10）](#e017)
- [交互换装返回分页纠偏（2026-09-10）](#e021)
- [A20 复核：`rebirth.s<n>` 的两分支与 冻结 门（第三十一批）](#e032)
- [改名输入表面纠偏（2026-09-10，第十三批）](#e034)
- [改名状态域与持久化纠偏（第十五批，2026-09-10）](#e035)
- [改名输入校验与确认边界（第十四批，2026-09-10）](#e036)
- [A19 第41批：替换快照与 SlotHasTag 聚合](#e043)
- [苏丹池对象域：List&lt;Card&gt; 而不是 id 多重集（第二十批，2026-09-10）](#e052)
- [第43批：标签附属属性生命周期](#e053)
- [卡牌标签模型：配置基准与运行时增量（第十九批，2026-09-10）](#e054)
- [A19 第40批：零数量与存档边界](#e055)
- [原作存档 Schema 与对拍台（阶段一，2026-08-17）](#e066)

<a id="e011"></a>

## CopyCard 复制运行时标签与装备（第二十三批，2026-09-10）

证据范围：`docs/replica/state.md#e011`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### CopyCard 复制运行时标签与装备（第二十三批，2026-09-10）



A20 原登记为"result rebirth 注释保留运行时标签复制未证实 / 不能用新生成或复制的近似规则代替"。本批把 `CardExtensions.Copy` 的方法体读出来，确认复制**携带**运行时标签增量、`count` 与装备树，而克隆原来是"从配置新建"。



### 原作事实



`CopyCard` 的执行链（`decompiled/CopyCard.c`）：



- `CopyCard.Do 0x4f51b0` / `PreDo 0x4f5330` 都用 `OperationFilter.Filter` 过滤上下文，再 `ListExtensions.DoSequence` 顺序跑闭包。

- `CopyCard.__c__DisplayClass4_1.c @ <Do>b__1 (0x508090)` 是真正做事的那一步：`CardExtensions.Copy(card, false)`，然后 `OperationContext.AddExtraResult_CardBorn` + `PlayerExtensions.NoteCardBeReward` + 用当前 `player.round@0x2C` 构造 `TimingContext` 触发 `EventTrigger.On`（即 `card_born` 时机）。

- `CopyCard.__c__DisplayClass4_0.c @ <Do>b__0 (0x507430)` 只是 `Where` 谓词（把过滤结果塞进列表），不是复制体。



`CardExtensions.Copy 0x37f4e0` 的正文（三信号一致）：



1. `PlayerExtensions.AddCard(source.id)` —— 新对象按**定义 id** 建，不带任何运行时字段。

2. 遍历 `source.equips@+0x40`，对每个装备递归 `Copy(equip, keep_count=true)`，把复制品 `FUN_1800032d0` 追加到新卡的 `equips`；若复制品有 SFx 或配置 `sfx@+0x80` 非空，触发 `DAT_18258f6c0` 回调。

3. 遍历 `source.tag@+0x30`（运行时增量字典），逐项 `FUN_181040ca0(newCard.tag, key, value)` 写入 —— **运行时标签增量被复制**，随后 `ValidateTagAttributes`。

4. 当 `keep_count == false` 时 `Card.set_count(newCard.count@0x20 = source.count)` —— **count 被复制**；装备递归传 `true`，所以装备复制品不继承源 count。

5. `Card.life@0x24`、`custom_name@0x50`、`custom_text@0x58`、`rareup@0x28`、`bag@0x48`/`bagpos@0x4c` **都不在 Copy 内**。



### 克隆偏差（已修）



1. **`copy.*` 在结果派发里根本没接**：`ResultExec.is_supported_key` 早就把 `copy.s<n>` 判为支持，但 `_apply_key` 里没有对应分支，只有一个永远走不到的处理点。所以配置里 31 处 `copy.*`（`copy.s1`..`copy.s10`）此前是**静默空操作**——不是"近似"，是没执行。

2. **复制语义是"从配置新建"**：修好后原实现仍只做 `state.add_card_to_hand(instance.card_id, db)`，丢掉运行时标签增量、`count` 与装备树，而这三点都由 `CardExtensions.Copy` 明文复制。



### 修复



- 新增 `GameState.copy_card_instance(source_uid, db, zone)`：按定义 id 建新对象 → 复制源增量字典（`duplicate(true)`，不共享）→ 写 `count` → 递归复制装备（递归传 `count=1`）→ `attach_equipment` 挂回宿主 → 入 `hand`。

- `ResultExec._apply_copy_slot` 改为对每个匹配卡调用 `copy_card_instance`；`_apply_key` 开头新增 `copy.s<n>` 分派（此前完全没有）。

- `copy.<n>` 的循环次数沿用配置值（`maxi(int(val), 1)`），对应 `CardExtensions.Copy` 被调用 `count` 次。



### 验证



- 新增 `tests/test_copy_card.gd`（6 测试 / 24 断言）：增量随复制、增量字典不共享、`count` 随复制、`life/custom_name/custom_text/rareup` **不**随复制、装备递归复制（新对象 + 挂到复制品 + 喂进有效标签行）、未知源返回 0、`copy.s1` 逐单位复制。

- 全量 GUT：48 脚本 / 582 测试 / 580 通过 / 4384 断言中 4382 通过（`a20-full.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败仍是既有的 `test_card_flash` 卡面几何与 `test_event_choice_controller` mask 高度，与本批无关。



### 未完成与新增审计线索



- **`rebirth.s<n>` 仍未按源核**：本批只做了 copy 侧。`RebirthSudanCard` 的 `Do 0x519d60` 只被读过一次（克隆把它实现为"槽卡 life 归零 + 活动苏丹倒计时重置"），其第二分支引用的字面量（疑为"不朽"类标签豁免）仍未反查。A20 保持**部分已修**。

- **Copy 的 SFx 回调与 `AddExtraResult_CardBorn`/`NoteCardBeReward`/`EventTrigger.On` 链**：克隆只做了 `add_card_to_hand`（含 MarkCardGen / is_only 登记），没有按 `player.round` 构造时机上下文触发 `card_born`。`result.gd` 里 `card`/`g.card` 分支会触发 `card_born`，`copy.*` 分支未对齐，登记为缺口。

- **`copy.` 的过滤域**：`CopyCard.PreDo/Do` 用的是 `OperationFilter.Filter(ctx)`；克隆按 `copy.<selector>` 走 `_slot_target_uids`，其 `s<n>` 语义已核，但非 `s<n>` 选择器（配置里未出现）未展开。

- **装备递归的 `equip_slots`**：源复制品的槽位列表来自定义（`AddCard(id)`），克隆同；源不复制 `removed_equip_slots`，克隆亦不复制。


</details>


<a id="e015"></a>

## 剧情描述键与详情显示（第十七批，2026-09-10）

证据范围：`docs/replica/state.md#e015`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 剧情描述键与详情显示（第十七批，2026-09-10）



接续第十六批。原作ChangeCardName同一操作类同时处理name/text；本批将克隆的描述分支接入同一注册、保存、翻译链，不再直接保存展开文字。



### 原作依据



- ChangeCardName构造0x4f2a30组装 `change_card_<类型>_<片段>`；stringliteral.json 0x259a4e0=text。PreDo闭包0x5089e0的text分支调用Card.set_custom_text，参数为已注册键。

- Datapool.BuildCustomText0x40d400 / MergeCustomTextToDefaultLanguage0x417dc0与上批为同一表。当前原配置有28处描述定义、28唯一描述键，无冲突；加上12处/10唯一名称键，共40处/38键。

- CardInfoNewController.Show0x537000（443起）先检查Card.custom_text@0x58：非空则直接Common.Translate，空才读取CardNode.text；之后ProcessPlaceholders。独立字段证据dump.cs:389609，Show签名dump.cs:317628。

- 与GetName不同，这里**没有**“译文等于键则回退”的分支。未知描述键要保留其原字符串。



### 实现



ConfigDB的名称专用表合并为custom_card_translates，键构造与递归登记函数扩展为name/text共用。均是原content的运行时索引，没有新增或改写内容配置。



Result槽位及既有table/total描述入口改写原键；GameState保存完整custom_text，不Trim；详情所取card_data_for在非空custom_text时翻译，然后沿现有详情占位符处理。未知键原样返回，空字符串回退配置正文。



### 验证



- card_evolution17测试/114断言：原作键写入、名称/描述共存、描述键存读档、未知键与名称不同的回退规则、空白保留、空值恢复配置正文。

- 原存档导入桥6测试/83断言（含真实auto_save样本），UI81测试/1073断言。共104测试/1270断言；最终日志无ERROR、SCRIPT ERROR、ObjectDB泄漏或orphan报告。

- verify_card_text_translation.gd：从存档恢复原名称/描述键，打开生产CardInfoView，核对正文译文。1280×720和1920×1080均PASS；截图card_text_translation_preferred_1280.png / 1920.png，已查看1280截图。此为克隆运行验证，不代表原机同帧像素验收。



### 仍待核实



table/total/槽位操作的完整目标选择、复制演出、当前语言/Mod/通用UI翻译键，以及ProcessPlaceholders完整语义仍开放。本批未把描述核验外推为这些链已经等价。沿用旧克隆存档的字面描述会因翻译未命中而保留原文；无需将它猜测成某个原作键。


</details>


<a id="e016"></a>

## 剧情改名键及默认译文纠偏（第十六批，2026-09-10）

证据范围：`docs/replica/state.md#e016`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 剧情改名键及默认译文纠偏（第十六批，2026-09-10）



A08前批区分了玩家输入和剧情名称。本批修复剧情改名将显示文字直接写进Card.custom_name的近似；保留原content不变。



### 事实与来源



- ChangeCardName.c构造函数0x4f2a30：字段0x20拼接 `change_card_` + 类型name + `_` + 操作唯一片段。三个字符串由stringliteral.json地址0x2595cb0/0x25794c0/0x257f458确认。不是完整带选择器的DSL键。

- 同构造调用Common.AddCustomCardText0x384290，注册该键及SingleValue<string>操作对象；PreDo闭包ChangeCardName.__c__DisplayClass6_0.c 0x5089e0将0x20键写入Card.custom_name，随后复制卡演出链另行处理。

- Datapool.BuildCustomText0x40d400将注册列表转为custom_card_text，重复相同值可重复登记，冲突报告；MergeCustomTextToDefaultLanguage0x417dc0将它合入default_language_translates。dump.cs:423235/423239/423295/423297独立确认列表、字典与默认/当前语言域。

- Datapool.Translate0x422740先查当前语言，再查默认语言，均无结果返回输入键；Common.Translate0x384bc0委托此翻译接口。

- CardExtensions.GetName0x37ff50：配置id玩家覆盖优先；custom_name非空才调用Translate，只有译文不同于键才返回，否则进入CardNode名称路径。未知键不能直接显示。



### 实现范围



ConfigDB按已加载的原始配置建立运行时custom_card_name_translates，与原作注册表职责对应；不写新内容表、不导出中间格式。遍历当前content的12处剧情名称定义得到10个唯一键、零值冲突。这里只承载这些默认中文名称；其他UI翻译键、外部语言/Mod覆盖尚未接入。



槽位及table/total既有执行入口现在写 `change_card_name_<id>`；set_card_custom_name不再Trim或截断32，允许原字段清空。card_data_for通过默认名称索引取显示文字，未知键回退配置名/玩家名，配置id玩家覆盖仍优先。



### 验证



- card_evolution 16测试/108断言：原作镜中生灵键的存读档、未解析键回退、字段清空、table实际执行写键、主角玩家名及配置id覆盖优先级。

- 原存档导入桥6测试/83断言，包含真实auto_save样本。该样本并不能单独证明全部10个译文分支，名称键边界另由直接源码及原配置支撑。

- UI81测试/1073断言；合计103测试/1264断言。最终日志无SCRIPT ERROR、ERROR、orphan或泄漏报告；git diff --check通过。

- 两条旧测试曾把直接存中文文字当正确答案，现改用原配置存在的键和译文，未为测试新增虚构翻译记录。



### 未完成项



当前语言/Mod覆盖、其他可作为custom_name的通用翻译键、custom_text同类注册/翻译、NotifyPlayerNameChanged消费者、禁词与TMP仍开放。本次发现table/total既有选择分支包含首次命中即return，选择器域及多目标行为须回原OperationFilter/ChangeCardName.PreDo独立核查；本批仅修它写入的字段值，不据此宣称整个选择器已正确。



既有旧克隆存档若把任意中文文字直接存custom_name，现在会按原作未解析键回退；未盲目将其迁入玩家配置id表，因为那会将单实例历史值扩散到全部同id卡。原作格式的键保持不变。


</details>


<a id="e017"></a>

## 剧情名称/描述的多目标与对象域（第十八批，2026-09-10）

证据范围：`docs/replica/state.md#e017`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 剧情名称/描述的多目标与对象域（第十八批，2026-09-10）



取自A08登记的table/total首次命中return。按scope-filter MANIFEST导航，回到实际调用和列表遍历，未把通用筛选器注释当作行为结论。



### 原作事实



- ChangeCardName构造0x4f2a30的域值：table.=3，total.=5，sudan_pool.=4。字符串地址0x25998a0/0x259c6d0/0x2596bc8交叉确认。

- DoTemplate0x4f2130：table调用Filter(Player.cards@0x88)；total调用Filter(GetTotalCards(player))。PlayerExtensions.GetTotalCards0x38de90复制玩家卡列表，再逐仪式追加Rite.cards@0x30的非空卡，不递归装备。dump.cs:391488 Player / 388887方法签名独立支持。

- OperationFilter.Filter(List)0x3a13c0遍历到列表末尾，对每个匹配对象调用action；不是旁边的FilterFirst0x3a1060。dump.cs:394805起明确有两个不同接口。

- 数字ID的0x40000000标志同时检查IsLost。IsLost0x382870实际为GetTag(lost)>0，stringliteral0x25bf778=lost；tag.json3020270名称“遗世”，文案为失去ID、不可被ID检索。

- **旧导航注释需收窄**：IsMatch0x3a1880并非对任何选择器无条件排除lost；源代码将它放在ID/排除ID分支。本批仅改变数字ID的name/text入口，未把此结论扩展到纯标签选择器。



### 修复



克隆原实现从全部CardInstance挑第一个同ID：table还包含slot，total还包含装备和removed。现在由source_player_cards / source_total_cards映射原作根列表，遍历全部匹配项；total逐仪式按槽序追加，装备不参与。数字ID排除正lost标签，支持原存档code=lost与克隆既有名称=遗世表示；0不排除。



名称/描述仍写上两批恢复的原翻译键。没有将玩家输入的配置id覆盖混入本项。



### 验证



- card_evolution18测试/129断言：两张相同ID手牌全部改、table不改槽卡、total可改槽卡、装备/removed不改、正遗世及原存档lost代码排除、0可重新命中。

- 原存档导入桥新增table_operation_root_membership和total_operation_root_membership两行，直接从原作Player.cards/Rite.cards读取UID，对照宿主成员；真实auto_save及现有边界样本全部通过。桥6测试/83断言。

- 合计24测试/212断言，最终日志无引擎错误、orphan/泄漏报告。该批没有修改UI绘制，不重复截图作为行为正确的替代证据。



### 未完成与新增审计线索



PC手牌/活动苏丹在宿主分成两列，原Player.cards中交错枚举顺序尚未完整恢复；根成员对拍明确排序后比较，不能证明复制演出先后顺序。sudan_pool、非数字筛选、槽位self/parent及复制演出仍开放。通用RuntimeOperationFilter.select_total仍有自己的旧域逻辑，本批未未经全调用方验证就统一替换。



原存档tag使用英文code，而克隆运行时常用中文名称；对正lost已补当前边界适配。原存档tag是否为配置基础值之上的增量、与宿主effective_card_tags合成及同一标签双表示冲突，登记为下一批高优先核查候选，不以本批成员对拍宣称整个属性模型等价。


</details>


<a id="e021"></a>

## 交互换装返回分页纠偏（2026-09-10）

证据范围：`docs/replica/state.md#e021`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 交互换装返回分页纠偏（2026-09-10）



A05 第八批。继续沿替换装备的返回调用核查分页与位置。



### 原作证据



- `CardController.c @ CardEquip 0x528020` 与 `CardInfoNewController.c @ DropCard 0x533550`：两处均调用 `BackToHandOrBag(old, host.bag, 0, true)`，不沿用旧装备原页。

- `CardDropManager.c @ BackToHandOrBag 0x4eef90`（`dump.cs:311018`）：先写 bagpos/bag。普通手牌分支调用 AddCard、UpdateHandCardPos、UpdateCardNumber；CardBagPanel 激活时另走 AddCardInBag/UpdateCardPos。

- `GameController.c @ AddCard 0x54ad40`：add=true 且 bagpos=0 时，用 hand 子节点数量赋 bagpos；`UpdateHandCardPos 0x559a70` 只收集 IsCurrentHandCard，排序后写1..N。CardEquip 对人物再调用一次 BackToHandOrBag，位于新装备 RemoveCard 之后。



### 修复与验证



交互替换（enforce_slot=true）的旧装备在移回手牌前改为 host.bag、bagpos=0，沿现有 rail 末尾追加路径返回。新装备移出后，对当前页按 rail 顺序写1..N；其他页不重新编号，DSL非交互回收不套用本规则。



- card_evolution 14/77：新增人物在第III页、旧装备残留第I页/pos19的换装；返回后第III页为人物/旧装备，pos1/2；第I页另一卡pos7不变。

- hand_pages 6/44、save_import_bridge 6/82（含原作auto_save样本）：合计26测试/203断言通过。

- 1280×720/1920×1080真实GUI槽位装备替换通过：旧装备归到人物第III页末尾，自动打开详情。日志 `approximation-equip-return-input-{1280,1920}.log`。

- 未发现引擎错误或orphan/泄漏报告。未改content。存档样本验证保存结构，不能冒充此操作的原机录制。



### 保留边界



本次验证普通当前手牌页；独立CardBagPanel排序/布局、非当前页直接API调用、IsHandCard完整标签语义、补回手牌标签、配音/RequestUpdateRite及拖起离槽时序仍未完成。原卡节点数量与克隆rail元素在隐藏/非手牌节点混入时的等价性仍需后续原机边界对拍。


</details>


<a id="e032"></a>

## A20 复核：`rebirth.s<n>` 的两分支与 冻结 门（第三十一批）

证据范围：`docs/replica/state.md#e032`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A20 复核：`rebirth.s<n>` 的两分支与 冻结 门（第三十一批）



`ApproximationAudit.md` 的 A20 行原文只说 "`rebirth.s<n>` 分支仍未按源复核"，克隆注释则把第二分支写成"不可恢复的 immortal 标签、且无配置命中"。本批把两件事都查实了：**标签可恢复**（是 `冻结`/`freeze`），**配置确实命中**（8 处写点全在苏丹卡槽上），而且克隆的实现**是错的**。



### 原作事实



### 1. `Do` 只是调度，真正的写点在共享委托里



`RebirthSudanCard.Do 0x519d60` 的流程（`RebirthSudanCard.c`）：



1. 从 `<RebirthSudanCard.<>c>` 的静态字段（`DAT_18259b2f0` 的 `+0xb8`）取/建一个缓存委托——就是 `<Do>b__4_0`；

2. `OperationFilter.Filter(this.filter@+0x20, context+0x20, context+0x14, 该委托)` —— 对**上下文筛出的每张卡**调用它；

3. 然后 `GameController.UpdateSudanLife 0x55aeb0` 刷新可见倒计时。



**`Do` 自己不动 life**。克隆此前把这段读成"`Do` 里 set_life"，于是漏掉了分支，只留下了刷新。



### 2. `<>c.<Do>b__4_0 0x51dec0` 就是那两分支



```c

cVar3 = CardExtensions__HasTag(card, DAT_182596500, 0);   // "freeze"

if (card == null) abort;

if (!cVar3) { Card__set_life(card, 0); return; }          // 分支一：全新抽取

if (card + 0x68 == null) abort;                           // CardNode

iVar1 = *(int *)(card_node + 0x60);                       // card_vanishing

Card__set_life(card, iVar1 - *(int *)(player + 100));      // 分支二

```



- `player + 100 = +0x64` = `Player.sudan_card_init_life`（dump.cs）。

- 所以第二分支 = `life = card_vanishing − sudan_card_init_life`，**就是 `GenSudanCard 0x54f6f0` 给新抽苏丹卡的头起步量**，不是 `card_vanishing` 全长。



### 3. 字面量可查：`freeze`



`DAT_182596500` 与 `DAT_1825ac9e8` 此前被记为"元数据无法反查"。实际用 `il2cpp_dump/stringliteral.json` 按 **VA 去镜像基址 `0x180000000`** 就能查到：



| 反编译符号 | stringliteral.json 地址 | 值 |

| --- | --- | --- |

| `DAT_1825ac9e8` | `0x25ac9e8` | `freeze` |

| `DAT_182596500` | `0x2596500` | `sudan` |



> 记法：`DAT_<VA>` 的键 = VA − `0x180000000`。以前直接拿 `0x182...` 去查当然查不到。



`freeze` 在 `content/tag.json` 里是 `id 3019999 / name 冻结 / code freeze / type attribute / can_add 0 / can_visible 1 / tag_rank 50`——就是"冻结卡牌的时间"那个标签，语义与分支完全吻合。



### 4. 配置侧：8 处写点全部落在苏丹卡槽上



| 仪式 | 写点 | 槽条件 | 槽文本 |

| --- | --- | --- | --- |

| 5000158 逆转时光 | `rebirth.s2` | `{"type":"sudan"}` | 苏丹卡 |

| 5006558 复原的神迹 | `rebirth.s1` ×2 | `{"type":"sudan"}` | 放入苏丹卡 |

| 5000576 莎姬的噩梦 | `rebirth.s1` ×5 | `{"is":2001019}` | 神明的耐心就是莎姬生命的倒计时 |



三个文件的克隆副本与语料 SHA-256 等值。**`is_empty` 全为 0**（槽必须已填），所以 `rebirth` 永远作用于已放置的卡。



语义自证：5006558 的 `tips_text` 写"可以重置苏丹卡的剩余时间 / 你只有3次机会"，正文写重置后"就像是从女术士的宝匣里刚刚抽出来的时候一样"——**"刚抽出来的样子"正是 `card_vanishing − sudan_card_init_life`**。5000576 那条 `card_vanishing=15`（莎姬的信物），冻结分支下 `life=15−5=10`，可见倒计时回 5。



### 克隆偏差



旧实现（`sim/result.gd` 的 `rebirth.s<n>` 分支）：



```gdscript

rebirth_instance.life = 0            # 无条件走分支一

...

asc.days_left = rebirth_lifetime     # = card_vanishing，全长

```



两个错：



1. **`冻结` 分支完全缺失**——被冻结的卡应该回到难度头起步量，克隆却给了它 0（= 满额剩余）。

2. **`days_left` 写成 `card_vanishing`**——等于宣称"恢复到满额期限"，而原作是 `card_vanishing − life`。



**为什么一直没被测出来**：默认难度档 `sudan_life_time` 是 7，而 `2010001` 的 `card_vanishing` 也是 7，于是 `7 − 7 = 0`，两分支恰好同值，`days_left` 也恰好同为 7。旧测试就在这个退化点上，所以"通过"。本批把测试搬到困难档（`sudan_card_init_life = 5`）才把差别暴露出来。



### 修复



`sim/result.gd`：



- 新增 `_has_freeze_tag(instance, state, db)`：把 `freeze` 经 `db.tag_code_to_name` 解析成配置名（默认 `冻结`），再读 `effective_card_tags` 的**有效行**（定义行 + 运行时增量 + 可继承装备），对应 `CardExtensions.HasTag`。

- `rebirth.s<n>` 改为按门分流：

  ```gdscript

  var lifetime: int = db.get_card(card_id).get("card_vanishing", 7)

  if _has_freeze_tag(instance, state, db):

      instance.life = lifetime - int(state.sudan_card_init_life)

  else:

      instance.life = 0

  asc.days_left = lifetime - int(instance.life)      # UpdateSudanLife

  ```

- 注释里补上完整 SRC 指针（含 `0x51dec0`、`player+0x64`、字面量地址与 tag.json id）。



`tests/test_dsl_batch1.gd`：原 `test_rebirth_resets_slot_card_countdown` 拆成两条——



- `test_rebirth_without_freeze_restarts_life_at_zero`：无冻结 → `life == 0`、`days_left == card_vanishing`（7）。

- `test_rebirth_with_freeze_resets_to_the_difficulty_head_start`：加 `冻结` 增量 + `sudan_card_init_life = 5` → `life == card_vanishing − 5`、`days_left == 5`，并显式断言 `days_left != card_vanishing`（钉住"不是满额重置"）。



`test_dsl_batch1.gd` 43/43 通过。



### 仍未做



- `RebirthSudanCard` 的 **CardOp 记录**（`PreDo` 的 `AddCardOp_RebirthSudanCard` 0x39e760 / `<PreDo>b__1` 0x51ffc0，`CardOpType.REBIRTH_SUDAN_CARD = 12`）还没有记录点——属 A12 的表现侧，规则效果本批已可断言。

- `Do` 的共享委托缓存（`<>c.cctor 0x5251e0` 建、`Do` 首调时懒建）是纯粹的分配优化，克隆每次直接算，不需要镜像。

- `UpdateSudanLife` 的**显示**语义（数字精灵、闪动）仍未接，本批只对齐了 `days_left` 数值。


</details>


<a id="e034"></a>

## 改名输入表面纠偏（2026-09-10，第十三批）

证据范围：`docs/replica/state.md#e034`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 改名输入表面纠偏（2026-09-10，第十三批）



从 A08 的输入框/placeholder 候选取项。本批只修已核实的背景绘制、文字内距、横向对齐和独立占位字体；不宣称整个改名流程已完成。



### 本次直接证据



只读 `unity_export/ExportedProject/Assets/Resources/prefab/PromptChangeName.prefab`：



- Image114477046003934300：input_bg，m_Type=0（Simple），PreserveAspect=0。克隆30像素九宫边缘无依据，现独立 TextureRect 整幅缩放。

- Input 根224571718729274231：826×90；TextArea224722951815217645：anchors全幅、pos(0,-.5)、sizeDelta(-20,-13)，换算Rect(10,7,806,77)。克隆40/20内距错误；现透明样式内距10/7/10/6，保持完整根的可点击面积。

- Text114279359913592680：horizontalAlignment=2（居中），文字颜色(1,.9764706,.6862745,1)；TextTranslate114384403120170545 style=@TITLE_H3。当前输入仍为原 Title 字体固定50。

- Placeholder114094320201520353：TextTranslate key=PROMPT_CHANGE_NAME_INPUT_PLACEHOLDER。原 content/textstyle.json 为 xiquemuye SDF，css_size范围40–75；不能与正文共享 LineEdit 的字体和固定50。现用独立标签读取同一原配置并订阅字号变化。

- `TextTranslate.c` UpdateTextInternal 0x1566ad0（144–171）：先按key查TextStyleNode、缺失再按style查，GetFontAsset后set_font；随后UpdateFontSize并按css_size订阅。不是仅靠prefab默认fontAsset推断最终字体。

- `PromptChangeNameController.c` OnEnable 0x585220 与 `dump.cs:323419`：Input@0x78为TMP_InputField，初始化先清空再写现有名字。占位显隐必须覆盖程序设值，不能只监听用户text_changed。



### 验证



`test_prompt_preferred_layout.gd` 4测试/28断言通过，包括826×90命中区域、10/7/10/6内距、两套独立字体、xxl下占位75而正文50，以及程序设置/清空名称后的占位显隐。占位隐藏也检查宿主当前输入法组合串；真实中文IME组合流程未验。



`verify_prompt_preferred_layout.gd` 1280×720、1920×1080 实际输入A、点击确认/取消与共用确认框状态均PASS。最终日志无SCRIPT ERROR、ERROR、ObjectDB或orphan报告。截图为克隆GPU验证，不替代原机对拍。



### 新确认的行为差异，下一批处理



必须保留这些缺口，不能继承过去“改名1:1”的结论：



1. 原Input m_CharacterLimit=0；IsValidName 0x584de0检查.NET UTF-16 String.Length为1–20，而当前克隆直接把输入硬截断20，并以Unicode码点计数。

2. IsValidName使用IsNullOrEmpty，未Trim；克隆strip_edges改变名称。原非法长名称/禁词会禁用Confirm并显示ILLEGAL_NAME，空串禁用且清提示；当前未实时接入。

3. 原Datapool.HasBanWords 0x4131c0经maskWordsHelper@0x2a8调用HasMaskWord。克隆未迁词库载入/判定；不能自制词表或默认为已支持。

4. OnNameSubmit 0x585490只验证并SetSelectionGameObject(Confirm)，不提交。OnConfirm 0x585000还检查Input@0x260状态并经SetCardName后DoClose；当前Enter直提交流程不同，字段0x260须与TMP_InputField dump继续核对。

5. 输入框Selectable的ColorTint、TMP Geometry垂直对齐、placeholder斜体、RectMask负padding、主面板Full图片/遮罩、手柄导航仍未验收。本批没有添加目测补偿。


</details>


<a id="e035"></a>

## 改名状态域与持久化纠偏（第十五批，2026-09-10）

证据范围：`docs/replica/state.md#e035`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 改名状态域与持久化纠偏（第十五批，2026-09-10）



接续 RenameValidationCorrection.md 的状态域缺口，修正 A08 的提交链，而非只改变卡面文字。



### 原作方法与独立信号



- ChangeName.c Do0x4f30e0直接把value@0x18传给GameController.ShowChangeName；没有查询手牌/仪式槽或要求实例存在。

- PromptChangeNameController.c Show0x585890：目标0绑定GetPlayerName/SetPlayerName，其余绑定GetSpecialCardName/SetSpecialCardName。SetPlayerName0x585530直接写Player.name@0x20；SetSpecialCardName0x585600写player_card_name@0x170，以配置id为键，不Trim。

- dump.cs:391488 Player字段、原save_samples/auto_save.json的name、player_card_name独立支持两个持久化域。

- CardExtensions.c GetName0x37ff50 / 0x3801b0：配置id表优先，随后custom_name和CardNode名称路径。CardNode路径对定义的player标签查Player.name。stringliteral.json地址0x25828f8值为player；content/tag.json code=player/name=主角；content/cards.json的2000001含主角标签。当前改动使用定义标签，未把玩家名条件扩大到运行时新增标签。

- GetPlayerName0x584a20：已有Player.name则直接返回；否则从player.cards选HasTag(player)者的配置名，无匹配取配置2000001。独立谓词源码PromptChangeNameController.__c.c 0x59fc10。



### 实现



1. Result._queue_change_name保留原card_id，不再寻找UID、因没有卡而跳过。0目标同样进入提示队列。

2. GameState新增player_display_name，对应Player.name；set_prompt_name按0/配置id分派。配置id名保留原字符串，不再strip_edges；实例custom_name不被提示改名覆盖。

3. GameScreen消费时使用payload.card_id。旧克隆存档的待处理提示缺card_id时，才从旧UID恢复配置id；新操作不走该兼容路径。

4. 提示初始名称取各自原域；配置id覆盖作用于已有及未来生成的同id卡。定义具有主角标签、且没有更高优先名称时，显示Player.name。

5. 玩家名进入SaveSystem序列化/反序列化，以及OriginalSaveImporter导入与同瞬间diff；缺新字段的旧存档默认空字符串。新局清空玩家名和配置id卡名，避免沿用上一局。



### 验证



- card_evolution：15测试/96断言；包括无卡也排队、目标0、同id多实例、未来生成、保留空格、配置id表高于玩家名、待处理提示随存档恢复和新局清空。

- 原存档导入桥：6测试/83断言，含语料auto_save真实样本，name新增同瞬间比较。name不再报告DROPPED。

- UI完整回归：81测试/1073断言。合计102测试/1252断言；最终日志无引擎错误、orphan或泄漏报告。

- verify_rename_state_input.gd：1280×720、1920×1080实际输入带空格的名称、点击确认、检查两个同id实例和序列化恢复后的新卡，均PASS。截图rename_state_preferred_1280.png / 1920.png是克隆实机证据，不冒充原机同帧。



### 保留的未完成项



禁词资源解密/MaskWordsHelper、Cancel与手柄流程、TMP及Full背景仍开放。Card.custom_name在原作中是可翻译键，GetName仅在翻译有效时采用；克隆现有直接显示custom_name行为未在本批改动。Player.NotifyPlayerNameChanged下游其他文字占位/通知消费者尚未全链审计。不得将本批读写边界视为所有名称格式化与所有页面都已完成。


</details>


<a id="e036"></a>

## 改名输入校验与确认边界（第十四批，2026-09-10）

证据范围：`docs/replica/state.md#e036`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 改名输入校验与确认边界（第十四批，2026-09-10）



从 A08 第十三批发现继续实施。原作证据为 `PromptChangeNameController.c` IsValidName0x584de0 / OnNameChanged0x585450 / OnNameSubmit0x585490 / OnConfirm0x585000，独立信号为 `dump.cs:323419` 控制器字段/签名、`dump.cs:361469` TMP_InputField类，以及 PromptChangeName.prefab m_CharacterLimit=0 和 `content/ui.json` ILLEGAL_NAME。



### 已修边界



- 输入框不再硬截断20字符。控制器以 UTF-16 单元计长度：十个非BMP表情=20，追加一个ASCII字符即无效。

- 每次文字变化重新设置Confirm可用性。程序设初始值和清空同样生效。空串禁用并清提示；超长字符串禁用并读取原ILLEGAL_NAME文案。

- 原 String.IsNullOrEmpty 不等于Trim；表面层提交原字符串，不再strip_edges。

- 原OnNameSubmit只将选择移至Confirm。克隆Enter不再直接提交；第二次操作确认按钮才触发submitted。

- 原OnConfirm中Input+0x260已由dump核为m_AllowInput。克隆在输入仍有编辑焦点时拒绝确认；真实鼠标点击先转移焦点再确认。



### 验证



专用测试5项/42断言、UI81项/1073断言，共86项/1115断言通过。最终日志检查无SCRIPT ERROR、ERROR、ObjectDB泄漏、orphan报告。曾因GUT断言的第4参数误传说明文字导致测试内部报错而总计仍显示通过；已纠正调用并重跑，最终数字只取日志干净的结果。



1280×720及1920×1080实际输入：输入A、按下/释放Enter后只选中Confirm且未提交，再点击确认，取消及共用确认框流程均PASS。使用 `tools/verify_prompt_preferred_layout.gd`，日志 `approximation-rename-validation-{1280,1920}.log`。



### 原始存储链仍有偏差，不算整链完成



本次继续打开 `ChangeName.c` Do0x4f30e0、`PromptChangeNameController.c` Show0x585890、SetPlayerName0x585530、SetSpecialCardName0x585600：



1. `ChangeName.Do`直接把操作value@0x18传给ShowChangeName。Show中value=0走Player.name@0x20；非零走Player.player_card_name@0x170按配置ID覆盖。Show无必须找到某张手牌UID的门。

2. 克隆 `_queue_change_name` 先查实例UID，未找到直接返回；payload未保存card_id。GameScreen消费再调用set_card_custom_name，仅写单实例。这是独立的状态域偏差，会影响同ID多张牌及未来新生成牌，下一批必须修调用链，不能只在UI设置一次显示名。

3. `GameState.set_card_custom_name`仍Trim/截断32；`set_player_card_name`仍Trim；Player.name目前由原存档导入器明确列为DROPPED。表面层保留空格的测试不能外推到持久化。

4. HasBanWords仍未迁：Datapool.LoadBanWords0x4145c0读取资源、AES解密后初始化MaskWordsHelper；HasBanWords0x4131c0调用该对象HasMaskWord。不得以本批长度通过替代禁词判定；本批未新增词表或转换配置。

5. Show还将Cancel对象禁用（后续取消/关闭及手柄链待联合核实）。当前取消能力不是本批已验证原作等价行为。



剩余输入ColorTint、TMP文本渲染和Full背景边界沿用第十三批留档。原机同帧及完整输入法生命周期未验收。


</details>


<a id="e043"></a>

## A19 第41批：替换快照与 SlotHasTag 聚合

证据范围：`docs/replica/state.md#e043`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A19 第41批：替换快照与 SlotHasTag 聚合



### 原作事实



- `SlotHasTag.IsSatisfied 0x408cf0` 将累加器初始化为0，调用 `OperationFilter.Filter`，最后对总值调用一次 `Compare.Check`；闭包 `0x40bfb0` 每次执行 `sum += CardExtensions.GetTag(card, tag, false)`。独立注册与签名见 `dump.cs:417790`，不是逐张任一满足。

- `OperationFilter.Filter 0x3a15c0`：all（低位6）走 `GetAllCardsWithIndex 0x391960`；friend（2）和enemy（4）都走 `GetEnemyCardsWithIndex 0x392140`。

- 后者闭包 `RiteExtensions.__c.<GetEnemyCardsWithIndex>b__5_0 0x3937b0` 仅在 `slot+0x29 == 0` 时构造有效 `(card,index)`，即保留 **is_enemy=false**。`dump.cs:392754` 确认该偏移字段名，`dump.cs:388942` 确认闭包签名。不能按 Enemy 命名自行取反。

- `ForeachCards<ValueTuple<object,int>> 0x71c820` 遍历配置槽，经闭包 `0xd509f0` 读取对应 `Rite.cards`；空卡返回默认元组。没有在这个枚举器里递归装备。属性继承由 GetTag 处理。

- `RitePanelShowController.TryUpdateCard 0x598140` 暂时将目标 `Rite.cards[index]` 设为null后才构造上下文并验证，之后恢复。因此聚合和单槽条件必须观察同一份排除目标的状态。



### 修正范围



`ConditionEval` 的 all/friend/enemy 从统一的槽条目读取：UI替换预检使用显式快照；其他条件调用使用当前仪式的配置槽与实时卡牌。实时分支不再读取缺少is_enemy标记的table条目。所有所选卡的有效标签先求和再比较；空集合的总和为0。



保留原作反直觉的双bit同路和false极性。**不改变 FuncCompare 的 friends/enemys数组规则**：它是另一条独立取值链。原MANIFEST指出共用Enemy方法，但仅有方法名不足以决定实际选中的一侧；此处以闭包方法体和字段偏移为准。



### 验证与限制



新增边界测试明确使用原金币卡、2和3的实例数量以及合成投槽条件，验证求和5、非逐卡阈值、空集合0、反向条件、快照排除、两侧筛选和实时配置读取。生产RiteView测试覆盖替换时排除目标而保留其他槽、拒绝后状态恢复、成功后旧卡回手。



这些是源码契约边界夹具，不将绕过投槽条件放入金币的状态冒充原机可达样本。没有新增原机同帧截图或宣称全局1:1。self/parent索引、完整附加条件、特殊CanPutCard门、演出和音频仍未收口。



最终验证：聚合4/17、投槽12/64、仪式36/175、模拟59/181、原存档导入桥7/91，合计 **118测试、528断言通过**。五组最终日志无SCRIPT ERROR、ERROR、Orphans、泄漏或失败记录；`git diff --check`通过。日志保存在仓库外 `C:/Users/User/Documents/Faust-cleanup-20260911/aggregate-test_*.log`。Godot4.7已重新导入运行资源。未重跑全量、未联网或推送。



### 下一项已经定位的证据（尚未实现）



`CanPutCard 0x3918b0` 在配置条件成功后读取main的 `adsorb_spec` 标签：其有效值>0且 `ConditionContext.is_adsorb_spec@0x21=false` 时拒绝。`stringliteral.json:10791` 将DAT_18258ae08映射为adsorb_spec；`dump.cs:383851`确认标志偏移。`HasTag.c` 的单main分支在TagNode@0x58集合包含adsorb_spec时调用 `SetAdsorbSpec 0x385520`（直接置true），所以不能只增加全局拒绝而省略允许门。需要继续查TagNode字段与配置、条件执行顺序、Cost的is_cost绕过语义，再在共享投槽验证接入。


</details>


<a id="e052"></a>

## 苏丹池对象域：List&lt;Card&gt; 而不是 id 多重集（第二十批，2026-09-10）

证据范围：`docs/replica/state.md#e052`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 苏丹池对象域：List&lt;Card&gt; 而不是 id 多重集（第二十批，2026-09-10）



A17 原先登记为"待核候选：池中同 id 不同运行态可能丢失"。本批把它核成了**已发生的偏差**，并按原作的 Card 对象模型重建。



### 原作事实



- `Player.sudan_card_pool` 在 `player+0xB0`，dump.cs 与 `Player.c` 构造器（`0x3a5000` 的 `System_Collections_Generic_List__ctor` 写入 `+0xB0`）双信号确认它是 **`List<Card>`**，不是 id 列表。

- `GenSudanCard 0x54f6f0`：取 `player+0xB0`；池空返回 0；若 `param_3 > 0` 则先按谓词找到并 `RemoveAt` 该对象，否则按 `InitNode+0x48`（sudan_shuffle）`ListExtensions.Shuffle` 后 `ListExtensions.RemoveLast`。**取出的就是那个 Card 对象本身**，随后直接 `Card.set_bag(player.BagIndex)`、`Card.set_life(模板 card_vanishing − player.sudan_card_init_life)`、`PlayerExtensions.AddCard(同一个对象)`、`MarkCardGen`、`PutCardOnTable`。

- `RedrawSudanCard 0x5558b0`：数量门通过后循环 `player+0x68` 次 `GenSudanCard`，每次 `Card.set_life(新卡, 弃卡.life)`；末尾 `List.Insert(Random.Range(0, pool.count), 弃卡对象)`——**弃牌对象本身回到池**，其运行时标签随它一起回去。

- `SudanPoolModifyTag 0x51c2e0`（`DoTemplate`）：`OperationFilter.Filter(player+0xB0)` 遍历**每个池对象**并逐个 `AddTag`/`RemoveTag`（闭包 `0x51c6f0` 里对同一个 `param_2` Card 调用）。

- `SudanPoolHaveCardCount.IsSatisfied 0x409760`：同样遍历 `player+0xB0` 计数。

- 配置侧：`init/1.json` 的 `sudan_pool` 是 **28 项**、每 id 两项（`[2010001,2010001,2010002,...]`）。



### 存档证据（决定性）



`save_samples/auto_save.json`（与 `save_slot_000.json` 同构）：



- `sudan_pool_cards` 28 项（配置表），`sudan_card_pool` **27 个对象**（已抽走 1 张），`sudan_pool_init_count=28`、`sudan_remove_count=0`。

- 27 个对象里 **11 个 id 重复**（2010001/2010002/2010003/2010005/2010007/2010009/2010010/2010011/2010013/2010014/2010015 各两份）。

- 每个对象自带 `uid/count/life/tag/bag/bagpos/custom_*/rareup/equips/equip_slots`，其中 `tag={"sudan_pool_index": N}`、且 **uid = N+1**（首项 uid 3 → index 3）。



**结论：按配置 id 建一个标签字典的表示法丢的是真实对象**，不是潜在风险。



### 克隆偏差



1. `sudan_deck: Array[int]` + `sudan_pool_tags: Dictionary[card_id] -> delta`：同 id 的多个池对象被合并成一个条目。

2. 池标签操作因此**只改一个**条目（原实现还显式 `seen_card_ids` 去重），而原作逐个对象施加。

3. `_create_sudan_instance` 从配置新建 CardInstance、另分配 uid，池对象的 `uid/count/life` 与 `sudan_pool_index` 全部丢弃（导入器还显式过滤掉 `sudan_pool_index`）。

4. 重抽把"标签字典"塞回 `sudan_pool_tags[discarded]`，而不是把对象放回池。

5. `sudan_pool_pos`（`Player+0xB8`）未映射。



### 修复



- 新增 `sim/sudan_pool_card.gd`（`SudanPoolCard`）：一个池对象的载体，字段 `uid/card_id/count/life/tags(delta)/pos`，带存档往返。

- `GameState.sudan_deck` 改为**对象数组**；新增 `build_sudan_pool / add_sudan_pool_card / reset_sudan_pool_to_ids / sudan_pool_size / sudan_deck_ids / draw_sudan_pool_card / insert_sudan_pool_card / sudan_pool_entry / sudan_pool_entry_tags / sudan_pool_tags()(读视图) / set_sudan_pool_tags_for_id`。

- **shuffle 移到抽取时**（`draw_sudan_pool_card` 内 `Shuffle` 后 `pop_back`），因为原作是在 `GenSudanCard` 里原地洗牌；`setup_new_run` 现在保持配置顺序。这是 RNG 时序的行为修正，不是实现细节。

- `round_loop.gd`：`draw_weekly_sudan` 取池对象并 `_promote_sudan_pool_entry`（复用原 uid、保留 count 与 delta、按公式设 life、写 BagIndex）；`use_redraw` 抽新卡后把**弃牌对象本身** `insert_sudan_pool_card` 回池，并从 `card_instances` 移除该运行时实例（同一 uid 不能同时是池对象与桌面实例）。

- `result.gd`：`sudan_card` 操作走 `add_sudan_pool_card`；`sudan_pool.<sel><op><tag>` 去掉 `seen_card_ids` 去重，逐对象在有效行上匹配后写 delta。

- `condition.gd`：`sudan_pool_have` 改为计数池**对象**。

- `save_system.gd`：`sudan_deck` 保存为 Card 对象行 + `sudan_pool_next_uid`；`_restore_sudan_pool` 同时接受新对象行与旧 id 列表（旧格式按 id 铸造对象并挂上旧的 per-id delta）。

- `original_save_importer.gd`：逐个导入源池对象（保留 uid/count/life/tag，不再丢 `sudan_pool_index`）；对拍新增 `sudan_pool_objects` 行（按 uid 比 card_id/count/life/tag）。



### 验证



- `tests/test_sudan.gd`：22 测试 / 590 断言。含"同 id 两个对象都收到标签操作""抽走的是被改的那个对象、剩余对象保持自己的状态""重抽把弃牌对象放回池且保留其 delta""setup 不再洗牌、抽取时才洗"。

- `tests/test_save_system.gd`：13 测试 / 147 断言。含旧 id 列表 + per-id 标签字典升级为对象、新对象行往返、v5 缺字段默认。

- `test_save_import_bridge.gd`：6 测试 / 86 断言，语料 auto_save 新增 `sudan_pool_objects` 行通过。

- 全量 GUT：46 脚本 / 567 测试 / 565 通过 / 4336 断言中 4334 通过（`a17-full.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败与第十九批记录的既有 UI 失败相同（`test_card_flash` 卡面几何、`test_event_choice_controller` mask 高度），基线对照已确认与本批无关。



### 未完成与新增审计线索



- **池对象与运行时实例共用 uid 命名空间**：这是核心承载选择（原作也是同一个 Card 对象换容器）。代价是"已抽出的对象既在 active_sudan 又在池里"这种状态无法表达——与原作一致，但克隆若以后要同时持有两侧引用需重新评估。

- `sudan_pool_pos`（`Player+0xB8`）仍只是每条目存了个 `pos`，没有复现原作的语义；样本里是 `[-1740, 800]`（两个浮点/位置量），来源未定。

- `GenSudanCard` 的 `param_3`（按 uid 定点抽取）分支未接：克隆只有"洗牌后取末位"这一条路径。当前没有配置或调用方命中该分支，登记为缺口。

- `_promote_sudan_pool_entry` 不读池对象的 `life` 字段而按公式重算；当前内容下池对象 life 恒为 0，两者等价，已在该函数注释中登记。

- 苏丹池 UI（`SudanPoolController`）仍未接，本批只改数据层。


</details>


<a id="e053"></a>

## 第43批：标签附属属性生命周期

证据范围：`docs/replica/state.md#e053`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 第43批：标签附属属性生命周期



### 原作事实



`PlayerExtensions.AddCard 0x38b620` 按CardNode.tag键枚举TagNode.attributes并调用AddTag，不先判断配置标签值。`CardExtensions.ValidateTagAttributes 0x3831c0` 在增删后读取源标签的有效值，大于0则添加每个附属属性，否则移除。`Copy 0x37f4e0`先创建卡及装备，再逐项写入源运行态tag并对该项校验，最后赋count；不能先批量复制字典再统一校验。



`Datapool.BuildInTags 0x40d9b0` / `AddBuildInTag 0x40c610` 注册adsorb_spec为不可叠加、不可见内建标签，stringliteral 0x258AE08=adsorb_spec、0x25B3468=吸附指定。AddTag 0x37e6a0对已存在且无配置基值的不可叠加标记保留旧值，RemoveTag 0x382e40移除该键。独立TagNode字段can_add@0x40/attributes@0x58以及原auto_save uid120的adsorb_spec=1支持这一链。



### 改正



GameState新建卡初始化配置标签的附属属性；共享Result标签写入后执行校验。复制与拆分按源字典顺序写入、逐项校验，最后赋数量。当前tag.json中全部非空attributes仅使用吸附指定；其他未移植属性显式报错，未添加运行时内容表，也未修改content。



原作的写入顺序可能让多个来源共用的标记被后一个移除；本批没有自制引用计数或读取时求并集。复制边界测试明确验证两个相同键值、不同插入顺序会产生不同结果。



### 验证与限制



新增测试将新建哲瓦德的标记与原auto_save uid120比较；覆盖移除囚徒后标记删除、重新添加后恢复、重复校验不累加、复制顺序与当前属性键普查。第一次仅因原JSON浮点数和运行时整数的字典严格比较失败，改为数值比较后4测试/72断言通过。



仍未完成：普通标签AddTag/RemoveTag/ConvertToAddOrSub的所有非叠加与SET边界、池对象的附属属性写入、复制事件通知及完整拆分表现。当前Result入口的基础TagSystem语义仍可能影响源标签的有效值；不能用本批属性回调宣称所有标签增删已精确复刻。原作未知/复合tag和其他内建标签尚未全部移植。未联网或推送。



最终验证：属性4/72、标签模型13/47、投槽13/69、特殊门4/16、原存档桥7/91、堆叠10/56、模拟59/181，合计110测试/532断言通过。最终日志无SCRIPT ERROR、ERROR、Orphans、泄漏或失败；git diff --check通过。日志在仓库外Faust-cleanup-20260911的attributes-*.log，属性测试以-rerun结尾日志为最终结果。全量套件未重跑。


</details>


<a id="e054"></a>

## 卡牌标签模型：配置基准与运行时增量（第十九批，2026-09-10）

证据范围：`docs/replica/state.md#e054`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 卡牌标签模型：配置基准与运行时增量（第十九批，2026-09-10）



> 2026-09-11更正：本文关于“装备任一标签can_inherit就继承整行”及“忽略装备count”的旧结论已被原作GetTag/GetTags直接证据推翻。现按所查询标签逐项判门，递归值仍乘装备count，见[本次复核](loop.md#e049)。其他历史验收数字不代表这些错误语义正确。



起于第十八批末登记的"待核查候选"：原存档 tag 用英文 code，克隆运行时用中文名称，且不确定存档存的是整行还是增量。本批回到 `CardExtensions.GetTag` 方法体，再用存档实例与配置算术独立验证，不再沿用"克隆 instance.tags 就是整行"的旧假设。



### 原作事实



- **卡牌有两个 tag 字典**：`Card.data`（CardNode@0x68）的 tag 在 `+0x58`，`Card` 自身的 tag 在 `+0x30`。dump.cs:389759 起 CardNode 字段表与 389593 起 Card 字段表各自独立列出这两个 `Dictionary<string,int>`。

- **GetTag 0x3814a0 是加法**：先读 `Card.data+0x58`（缺失记 0），再读 `Card+0x30`（缺失记 0），相加得 `iVar8`（源码 1585-1601）。

- **装备项**：若 `Common.GetTagNode(tag)` 的 `+0x42`（can_inherit）为真，则遍历 `Card+0x40`（List&lt;Card&gt; equips），对每个装备递归 `GetTag(equip, tag, raw=true)` 并累加（1603-1618）。门控是**该标签能否继承**，但一旦通过就累加装备的**整行**，不是逐标签过滤；`raw=true` 也让装备项跳过下面的非正掩码。

- **非正掩码**：非 raw 且总和 &lt;1 时，只有当 `TagNode+0x43`（can_nagative_and_zero）为假才返回 0（1619-1622）。

- **最后乘 count**：`return iVar8 * *(int *)(Card+0x20)`（1623）。装备的 count 不参与。

- **GetTags 0x381940 是并集**：HashSet 先并入 `Card.data+0x58` 的键，再并入 `Card+0x30` 的键，最后 `UnionWith(GetTags(equip).Where(inheritable))`。它只收集键，不带值，也不乘 count。

- **AddTag 0x37e6a0 只写运行时字典**：非复合标签分支读 `Card+0x30`，写 `Card+0x30`；配置字典 `Card.data+0x58` 只作为"是否已存在"的门（`can_add` 为假且配置里已有该标签时不写）。**配置字典从不被写**。

- **存档证实是增量**：`save_samples/auto_save.json` uid 29（id 2000001）的 `tag` 是 `{"social":1,"charm":1}`；`cards.json` 2000001 的配置行是 `体魄3 魅力2 智慧1 男性1 贵族1 主角1 战斗2 社交1 已拥有1 支持1`。故运行时该卡社交=2、魅力=3。全语料 4 个存档样本只用到 9 个 code，另有 `sudan_pool_index`、`adsorb_spec` 两个非 tag.json 的簿记键。

- tag.json 442 条，name 与 code 各自唯一，可双向映射；`CanAdd`/`can_inherit`/`can_nagative_and_zero` 是三条独立旗标（例：体魄 `1/1/1`，支持 `1/1/0`，已拥有 `0/0/0`，武器 `0/0/0`）。



### 克隆偏差



1. `original_save_importer._base_card_row` 把存档的英文 code 增量字典**原样**写进 `CardInstance.tags`。

2. `GameState.card_data_for` 曾对空 tags 做"惰性填配置行"，于是同一字段有时是整行（中文名）、有时是增量（英文 code）。

3. `effective_card_tags` 只把 `instance.tags` 复制后加一层装备，**既没有配置基准，也没有 ×count，键域还可能是 code**。装备贡献按标签逐个看 can_inherit，与 GetTag 的"整行"语义不符。

4. `operation_filter._matches`、`result.gd` 的 table/total 选择器、`condition.gd` 的状态标签判定都直接读 `instance.tags`，即把增量当整行。

5. `record_card_generation` 遍历 `instance.tags` 的键，增量域会漏掉配置基准键。



### 修复



- `data/db.gd`：新增 `tag_code_to_name`（tag_name_to_code 的反向表），供跨域解析。

- `sim/card_instance.gd`：`tags` 明确为**运行时增量**并加 SRC 注释；存档新增 `tags_are_delta: true` 标记，v9 起写出。

- `sim/game_state.gd`：

  - `effective_card_tags(uid, db)` = (配置行 + 增量 + 每个可继承装备的整行) → 非正掩码 → × count，键统一为配置名域。

  - 新增 `effective_card_tag_names(uid, db)` 实现 GetTags 的键并集（配置键 + 增量键 + 可继承装备的键）。

  - `card_data_for` 的 `tag` 与新增的 `tags` 都取有效行（修正 `condition.gd` 读 `tags` 一直取空的死分支）；`table_card_entries`/`surface_card_entries` 的 `tags` 同样取有效行。

  - `rebase_tag_delta`：把旧克隆存档里的"整行（配置名域）"减回增量；配置未登记的运行态标签（遗世/lost/adsorb_spec）原样保留。

  - `record_card_generation` 改走键并集。

- `sim/save_system.gd`：反序列化后对 `tags_are_delta=false` 的卡逐张 rebase。

- `sim/original_save_importer.gd`：导入行显式声明 `tags_are_delta=true`（原作存档本来就是增量）。

- `core/tag.gd`：`TagSystem.apply` 增加 `effective_value` 参数——`can_add=0` 的门读的是 GetTag 结果，而配置基准永远参与，只看增量会漏判。

- `sim/result.gd`：6 处标签写入点（裸键族、GenCard 的 tag_modify、槽位、table、total、苏丹池）全部改为"写增量、用有效行做门"；苏丹池的 `sudan_pool_tags` 明确为增量，选择器改用"配置行 + 增量"的有效行。

- `sim/operation_filter.gd`：`select_total` 的选择器判定改用有效行。



### 验证



- 新增 `tests/test_tag_model.gd`（12 测试 / 38 断言）：配置与存档的双键域、无增量时等于配置行、code 增量叠加（uid 29 社交 2/魅力 3）、×count、非正掩码（支持 vs 体魄）、装备整行与 can_inherit 门（2000006 通过、2000380 全阻断）、非装备区不参与、GetTags 键并集、`can_add` 门读有效行、v9 增量往返、旧版整行 rebase。

- **原存档对拍**：测试内用"存档 JSON + 配置"独立重算 185 张卡（含装备）的 GetTag 行与 clone 逐标签比较，零不一致。该期望值不调用克隆的 tag 辅助函数。

- 全量 GUT：46 脚本 / 566 测试 / 564 通过 / 4300 断言中 4298 通过（`tag-full4.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。

- 修根因时顺带发现并修掉一个更早的克隆偏差：`create_card_instance` 把**配置整行**塞进运行时增量，在新求值下会让每个数值翻倍（正是"增量当整行"假设的另一面）。现在新卡从空增量开始。



### 两条剩余失败与一批的关系（基线对照）



本批用 `git stash` 在"同一工作区、去掉本批改动"的基线上复跑确认：



- `test_card_flash.gd` 的 `candidate layout keeps the scaled bottom on the rail`：基线 40 条断言失败，本批 1 条；差异属于其他会话未完成的卡面几何，与本批无关，尚未收口。

- `test_event_choice_controller.gd` 的 mask 高度 489 vs 828：基线与本批完全相同的一条失败，属其他会话未完成的 PromptNew 布局，与本批无关。



另有 `test_gold_card.gd` 原先直接断言 `instance.tags` 里的配置标签，已按新语义改为读有效行（5 枚金币堆叠 → 配置值 ×count = 5）。



### 未完成与新增审计线索



- **key 域未全局统一**：本批只保证"物化行"（card_data_for / entries / effective_card_tags）用配置名域，`instance.tags` 仍是原样增量。若某个调用方直接读 `instance.tags` 做条件判定，仍会拿到增量。建议后续把读点全部收口到有效行 API，或改成同名 code 域一次到底。

- **苏丹池仍是按配置 id 合并**（A17 P0）：池内同 id 不同运行态会互相覆盖，本批只保证池增量语义正确，未解决对象域。

- **`result.gd` 的 `copy.*`**：复制是否携带运行时标签仍未证实（源码注释保留）。

- **`AddTag` 的复合标签分支**（`TagNode.is_composite`）与 `ValidateTagAttributes` 未在本批展开。

- `GetTagWithDiff`（0x3811e0）唯一消费者是 `CardInfoNewController.Show`，本批未改卡牌详情的数值展示；详情页现在会显示"配置+增量"的整行，与原件一致，但差分高亮仍未接。


</details>


<a id="e055"></a>

## A19 第40批：零数量与存档边界

证据范围：`docs/replica/state.md#e055`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A19 第40批：零数量与存档边界



### 来源与范围



直接重读 `CardSlotController.CardStack 0x53b0a0`：当 cost_count=0 且来源 count>0，余量仍是来源 count，Copy 后 set_count(0)，然后 SetCard 入槽。`Card.c @ set_count 0x383e80` 直接赋值并通知，不夹到1；独立 Card.count@0x20 字段和 CostCondition.PostProcess 0x3f6520 的 Min=0 分支支持该结构边界。



但遍历当前全部 `content/rite/*.json` 的 cards_slot 子树，零值成本、区间下界0、<及<=成本键合计 **0处**。因此这是原方法的边界，不宣称原作当前内容可达，也没有捏造零数量原机截图或原存档实例。



### 改正



- pay_cost_into_slot 接受 needed=0，按原拆分路径生成零数量切片；保留负needed的宿主参数拒绝门。

- CardInstance、SudanPoolCard、原作导入与池对拍行不再将原始count夹到1。原始字段按int保存，默认缺字段仍为1。

- 堆叠性从“字典里有可堆叠键”改为有效值>0。直接源码 `CardExtensions.HasTag 0x382250` 是 GetTag>0；零数量卡的GetTag乘count后为0，不应被认作可堆叠。

- 卡牌数量徽记现有条件count>1，与已有CardRender源指针一致，本批不添加自制零徽记。



### 验证方式



明确边界夹具：在复制的槽定义中设cost=0（不改ConfigDB与content），从4金币生成零数量槽卡，原卡仍4，序列化往返后总金币仍4。原作格式合成夹具同时验证手牌及苏丹池count=0导入与往返不变。该合成夹具不冒充原作实际存档。



既有正成本、替换、卡牌合堆、存档桥及存读档测试一并回归。最终计数收尾追加，日志zero-count-*.log。



### 剩余



A19仍缺完整吸附附加条件、聚合选择器快照边界、特殊标签门及演出/音频。负成本未作为已验证游戏行为开放；零数量往返外的其他GetCount特殊读法仍应按各方法验证。未修改content、未提交或联网。



最终验证：投放11/56、导入桥7/91、堆叠10/56、付款13/39、存档13/147，合计54测试/389断言通过。最终日志无SCRIPT ERROR、ERROR、失败、Orphans或泄漏；git diff --check通过。未重跑全量和实机截图，本批是状态边界测试，原作当前配置没有零成本实例。


</details>


<a id="e066"></a>

## 原作存档 Schema 与对拍台（阶段一，2026-08-17）

证据范围：`docs/replica/state.md#e066`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 原作存档 Schema 与对拍台（阶段一，2026-08-17）



> 复刻工作法支柱 2「原作产物当裁判」的落地。机器真源 = `sim/original_save_schema.gd`

> （60 字段映射表 + 分析/对拍函数）；本文是可读快照，冲突以模块为准。

> 证据：`il2cpp_dump/dump.cs` Player（391488 行，TypeDefIndex 6274，JsonSerializable）

> × 真实存档 `save_samples/auto_save.json`（round 1 / difficulty 1）双信号吻合：

> 60 字段零未知、零类型不符。



### 工具用法



```

godot --headless --script tools/export_save_diff.gd -- \

  --original <原作存档.json> [--compare <克隆v5.json>] [--out <目录>]

```



- 默认 `--original` 指向语料库 auto_save.json；未知字段/类型不符会使退出码非零。

- `--compare`：对 mapped/semantic 字段做逐项值对照（同刻存档才有意义；导入桥建成后使用）。

- GUT：`tests/test_save_diff_harness.gd`（schema 总量 60、金币发现登记、样本分析全过）。



### Player 存档 60 字段（dump.cs 偏移序）



状态：**mapped 25**（同名同义）/ **semantic 15**（有对应但结构或语义漂移）/ **missing 20**（克隆无）。



| 字段 | 类型 | 克隆 v5 | 状态 | 备注 |

| --- | --- | --- | --- | --- |

| configId | int | — | missing | 局内配置身份 |

| configVersion | long | — | missing | 配置版本戳 |

| name | string | player_display_name | mapped | 玩家名原字符串；空值时显示路径回退配置名称；第十五批纳入导入对拍 |

| difficulty | int | difficulty_index | semantic | 基数待验证（样本=1） |

| round | int | round_number | semantic | 原作 round 即日；克隆另存 day（原作无） |

| min_round | int | round_snapshots 内部 | semantic | 回退下界，原作显式持久化 |

| saveTime | DateTime | — | missing | 时间戳 |

| card_uid_index | int | next_card_uid | mapped | |

| rite_uid_index | int | next_rite_uid | mapped | |

| sudan_box_show | bool | sudan_box_show | semantic | 苏丹卡盒可见标志；2026-08-19 起克隆桌面盒已接，剧情/帮助 HUD 仍缺 |

| story_unshow | bool | story_unshow | semantic | 剧情 HUD 隐藏标志；原作桌面 HUD 未接 |

| prestige_unshow | bool | prestige_unshow | semantic | 声望 HUD 隐藏标志；2026-08-19 起克隆条已接，原作图标/交互仍缺 |

| deadline_unshow | bool | deadline_unshow | semantic | 死线 HUD 隐藏标志；2026-08-19 起克隆条已接，原作装饰/交互仍缺 |

| helpbtn_unshow | bool | helpbtn_unshow | semantic | 帮助按钮隐藏标志；原作桌面 HUD 未接 |

| location_icon_show | int | — | missing | change_location_icon 持久化 |

| change_desk_bg | string | — | missing | change_desk_bg 持久化 |

| after_round_auto_sort | bool | — | missing | 日终自动整理 |

| sudan_card_init_life | int | sudan_card_init_life | mapped | 新抽苏丹卡的 Player 头起步寿命 |

| sudan_redraw_count | int | sudan_redraw_count | mapped | |

| sudan_redraw_times_per_round | int | sudan_redraw_times_per_round | mapped | SetDifficulty 更新 |

| sudan_redraw_times | int | sudan_redraw_times | mapped | 本恢复周期内已用普通重抽次数 |

| sudan_redraw_times_recovery_round | int | sudan_redraw_times_recovery_round | mapped | Init 配置的恢复周期 |

| wizard_first_show | bool | begin_guide(部分) | semantic | 原作仅存布尔 |

| success | bool | success | mapped | SetGameOver 的终局成功标志 |

| over_reason | int | over_reason | mapped | 结局原因；int.MinValue=未终局 |

| ithink_card | Card? | — | missing | 俺寻思卡实例 |

| cards | List\<Card\> | card_instances | semantic | 见下「结构差异」 |

| rites | List\<Rite\> | rite_instances | semantic | 槽位下标数组内嵌卡 |

| pins | List\<int\> | — | missing | 桌面图钉 |

| sudan_pool_cards | List\<int\> | 配置池证据 | semantic | 构造运行时牌池用的 id 表；抽牌后仍保留初始多重集 |

| sudan_pool | string | — | missing | 池变体 |

| sudan_card_pool | List\<Card\> | sudan_deck + sudan_pool_tags | semantic | 实际剩余苏丹牌池；GenSudanCard 从此列表抽牌 |

| sudan_pool_pos | Vector2 | — | missing | 池 UI 坐标 |

| sudan_pool_init_count | int | — | missing | |

| sudan_card_show_times | Dict\<int,int\> | — | missing | 展示计数 |

| sudan_remove_count | int | — | missing | |

| counter | Dict\<int,int\> | local_counters | mapped | 骰子疑在此（id 待验证） |

| global_counter_cacher | Dict\<int,int\> | global_counters | semantic | 缓存器；真值在 global.json |

| random_cache | Dict\<string,int\> | — | missing | RNG 续航 |

| only_cards | HashSet\<int\> | only_cards | mapped | 已生成 is_only 卡的持久化登记；非当前持有表 |

| only_rites | HashSet\<int\> | only_rites | mapped | 成功初始化的仪式 id 持久化登记 |

| event_status | Dict\<int,bool\> | event_status | mapped | |

| delay_ops | List\<DelayOp\> | delayed_operations | mapped | {id, round} |

| end_rites | Dict\<int,int\> | ended_rites | mapped | |

| gen_cards | Dict\<int,int\> | gen_cards | mapped | 新建玩家卡 id 生成次数 |

| gen_tags | Dict\<string,int\> | gen_tags | mapped | 稳定 tag code 生成次数 |

| timing_rounds | Dict\<int,int\> | timing_rounds | mapped | player+0x128 |

| auto_result_rites | HashSet\<int\> | auto_result_rites | mapped | |

| notes | List\<List\<Note\>\> | — | missing | 笔记分页流水账 |

| once_new_rites_is_show | Dict\<int,bool\> | once_new_rites_is_show | semantic | 新仪式首见提示；仪式面板提示 UI 未接 |

| cached_event | List\<int\> | cached_event | semantic | 可点击缓存提示的去重列表；提示 UI/缓存结算未接 |

| BagIndex | int | — | missing | 背包索引 |

| last_round_rite_data | Dict\<int,Dict\> | last_round_rite_data | mapped | 按仪式配置 id + 手动槽 guid 保存 LastCardData{id,count}，用于面板恢复上次投放；不是回退快照 |

| rite_auto_result | bool | rite_auto_result | mapped | |

| disable_auto_gen_sudan_card | bool | auto_gen_sudan_card(取反) | mapped | |

| custom_rite_name | Dict\<int,string\> | custom_rite_names | mapped | 玩家级仪式显示名覆盖（按配置 id） |

| player_card_name | Dict\<int,string\> | player_card_names | mapped | 玩家级卡牌显示名覆盖（按配置 id，优先于 Card.custom_name） |

| end_open | bool | end_open | mapped | 仪式 5010009 的结果面板关闭后置位；地图载入/次日链据此切终局背景 |

| is_armageddon | bool | is_armageddon | mapped | 仪式专属循环音乐状态，不是独立战斗规则模式 |

| armageddon_rite_id | int | armageddon_rite_id | mapped | 当前 `armageddon_music_loop` 仪式配置 id |



### 嵌套 DTO



- **Card（存档形）**：`{uid, id, count, life, rareup, tag{}, equip_slots[], equips[Card], bag, bagpos, custom_name, custom_text}`——装备**嵌套**在宿主卡的 `equips` 里；`bag=0` 且 `bagpos` 决定手牌位。

- **Rite**：`{uid, id, new_born, is_show, start, start_round, start_life, life, cards[按槽位下标, null=空槽, 内嵌 Card], custom_name}`。

- **Player.Note**：`{type, id, uid, count}`（样本 type 10002/10001=卡族、1=仪式；分页组织）。

- **Player.DelayOp**：`{id, round}`。**Player.LastCardData**：`{id, count}`。



### global.json（29 字段，跨局全局）



saveTime / finishTutorial / inGame / totalRound / totalPoint / usedPoint / upgradeState / questState / upgrade{} / quest{} / counter{6} / mods[] / hasEnterSudanBox / hasEnterQuest / **backToPrevRound（回退配额，9999=未用）** / roundRollback / overRecord[] / overID[]（结局图鉴）/ gameStatistics{} / doneRite[] / doneEvent[] / **showedGalleryCards[]（图鉴解锁）** / showedPrompt[] / choosedOption[] / isAutoClassify / autoClassifyBagTags{} / version。

克隆对应：承载容器已落地（`sim/global_state.gd` → user://global.json），backToPrevRound / roundRollback / saveTime 三字段已接；其余仍缺（归 METHOD_MAP D：global.json 其余字段）。



### user_archive.json



50 槽索引：`{name, live_days, left_sudan, execution_day, back_to_prev_round, save_time, path}`。克隆已有等价档案索引（字段名不同，语义同）。



### 关键结构发现（驱动后续批次）



1. **金币 = 手牌金币卡对象（id 2000029）的 count 之和（多对象模型）**。双信号：`GenCoin.c Do 0x510b40`（`GameController.GenCard(0x1E849D)` → `PlayerExtensions.AddCard`（**每次新建对象**，无堆叠合并分支）→ `Card.set_count(操作值)` → `set_bagpos(1)` → `OnCardBorn`）× cards.json 2000029（金币/可堆叠/消耗品/已拥有）+ 存档样本旁证（神的乙太 2001090 × 20 个对象各 count=1）。操作值**可为负**（set_count 直写）；花费判定 `CostCondition.IsSatisfied 0x3f6160` 读卡对象 count。克隆原 `coin_count` 标量为结构偏差——**2026-08-17 已修复**：`coin_count` 改为金币卡对象求和的计算属性，`coin` 操作按原作生成卡对象（前置手牌位、发 card_born），v5→v6 存档迁移（标量→单对象）；扣除顺序已按发现 3 的枚举序对齐。

2. **金骰 = counter 7100006**（已修复）。三重信号：dump.cs:542529 `COUNTER_GOLD_DICE = 7100006` 常量 + PlayerExtensions Add/SubCounter 写点 + 存档样本（difficulty=1 → counter 7100006=3，与 init 难度表 gold_dice_count 精确吻合）。克隆 `gold_dice` 现为该 counter 的计算属性。**常量表顺带解出**：回退配额 = COUNTER_BACK_TO_PREV 7100007（存 global.json backToPrevRound，**2026-08-18 已迁移**，见发现 8）、苏丹额外重抽 = COUNTER_SUDAN_EXTRA_REDRAW 7100008（待克隆迁移）。

3. **cost 支付链**（部分留档）：`CostCondition.IsSatisfied 0x3f6160` 判定时即按 player.cards 枚举序选定付款卡清单（累计 count 覆盖花费即停）记入 `ConditionContext.need_cost_cards`（dump.cs:383873）+ `cost_count`——支付顺序=卡列表顺序（最旧优先），克隆 `_remove_gold` 已按 uid 升序对齐；实际扣款执行体未包含在反编译子集（留档）。

4. **金币/门客总额是派生读**：`GetCounter 0x38ce70` 对 7000105（金币）/7000104（门客数）特殊分支——从 player.cards + player.rites 按谓词求和，**仪式槽内的金币卡计入总额**；克隆 gold_total 已扩展 hand+slot。

5. **手牌 = cards 中 bag=0 按 bagpos 排序**，无独立 hand 数组；克隆 `hand`/`rail_order` 为自制承载。

6. **仪式槽位是下标数组**（null=空槽），卡与装备全内嵌；克隆用扁平 zone/rite_uid/slot_key + equipped_uids。导入桥必须做嵌套↔扁平转换。

7. **原作 UI Promise 队列不持久化**：只存 delay_ops + cached_event。后者是已触发的可点击提示 id 去重列表，不是重放队列：触发时 AddCacheEvent，点击结算完成（或找不到配置）后 RemoveCacheEvent。克隆现已准确持久化/导入该列表；cached settlement 提示 UI 尚未接入，pending_operations 仍是语义更重的临时宿主。Player 另存五个 HUD 可见性偏好与每仪式首见标志；克隆已原样承载，`close_*` 会按原作 0=显示/非零=隐藏更新标志，但桌面 HUD/首见提示尚未接入。

8. **回退与仪式恢复已拆清**：① global.backToPrevRound（配额，即 COUNTER_BACK_TO_PREV 7100007）已迁入 `GlobalState`；② Datapool 轮次 Player 文件已于 **2026-08-18 批次 F** 落地：SaveRoundBegin/End 先刷新 continue，再写 `round_{N}.json` / `round_{N}_end.json`，LoadRound/End 从磁盘恢复并刷新 continue，档案恢复删除旧时间线的 `round_*.json`；③ player.last_round_rite_data 是独立的仪式面板“恢复上次投放”缓存：`OnConfirm` 按 Rite.id 记录每个**手动槽** guid 的 `LastCardData{id,count}`，`OnLastState` 按卡牌可用性和当前槽条件逐槽恢复；它不是回退快照。消耗顺序保持 `UseBackToPrev → Global.roundRollback=2 → SaveGlobal → LoadRound`，故玩家重启后仍可回退且配额不会随 Player 快照回滚。

9. **RNG 续航**：random_cache 字典——原作存 RNG 状态保证跨存档续局一致；克隆无。

10. **苏丹期限 = 卡寿命模型**（2026-08-18 批次 D 解出）：激活苏丹卡无独立期限字段——`GenSudanCard` L3656-3662 出生 `set_life(模板 card_vanishing − player.sudan_card_init_life)`（抢跑量），每日 life+1（老化无条件），`life >= card_vanishing` 且不在任一仪式槽即 DoVanish 处刑（vanish.over 驱动结局）；可见倒计时 = `card_vanishing − life`（UpdateSudanLife 0x55aeb0，庇护期间可为负）。样本 uid11 life=0=7−7 ✓；困难档 7−5=2 抢跑=5 天。重抽新卡 `set_life(弃卡 life)` 继承剩余；抽牌 = sudan_card_pool 先 Shuffle 再 RemoveLast（顺序无意义）。克隆：`_update_card_lives` 苏丹并入通用死亡，days_left 为镜像；导入桥 days_left 精确恢复。

11. **手牌位 = bag/bagpos 双字段**（2026-08-18 批次 E 解出）：`Card.bag`@0x48 = 包页 id（`Player.BagIndex`@0x150 = 当前查看页，GenSudanCard 把新苏丹卡 set_bag 进当前页）；`bagpos`@0x4c = 页内 **1 基**位置，0 = 未摆放（背包列表）；`UpdateHandCardPos` 0x559a70 在 b__6 链（回合开始事件**之后**）收集 `IsCurrentHandCard`（bag==BagIndex 且三标签资格）卡排序后压缩为 1..N；GenCoin `set_bagpos(1)` 金币前置。样本仅 6 张卡有位置（主角/苏丹/妻子/法拉杰/已装备/乙太堆）——bagpos 是玩家手动摆放，非类型成员。克隆：CardInstance.bag/bag_pos 落地 + 日终压缩 + 导入桥透传（bag_positions 对拍行）；三标签名（IsHandCard 资格判据）无法从元数据反查，留档。

12. **笔记 = 按回合分页的日志**（2026-08-18 批次 O 解出）：`Player.notes`@0x138 = List<List<Note>>，**页索引 = round−1**（AddNote 0x38c130 自动增长空页至当前回合）；Note={type@0x10,id@0x14,uid@0x18,count@0x1C}（dump.cs:391430）。type 常量：1=仪式创建（StartRite.c L133）、2=仪式消亡（GameController.c L5867）、3=仪式结算（RiteResultPanelController 链）、4=仪式吸附卡（**count 存被吸卡 id** 的怪癖，NoteRiteAdsorbCard 0x38eb10）、10001=成为随从（0x38e9c0）、10002=获得奖励卡（0x38ea40，GenCard/GenLoot/GenCoin 三调用点，带手牌标签门）。样本 1 页 7 条与开局剧情吻合（10002 乙太服装、10001 法拉杰/梅姬、1×4 初始仪式）。克隆：GameState.notes/add_note 进 v7 与导入桥；写点 1/2/3 已接，4/10001/10002 留档。



### 阶段二：导入桥（2026-08-18 已落地）



`sim/original_save_importer.gd`：原作 Player 存档 → 克隆 v8 payload → 正常 `SaveSystem.deserialize` 路径载入 GameState。`tools/export_save_diff.gd --bridge` 产出同刻对拍报告（user://save_diff/save_diff.md + bridge payload）。语料 auto_save.json 实测 **49/49 项全过**（回合/难度基数/两 uid 指针/计数器/事件状态/时机臂/仪式槽位/装备链接/手牌成员及 bag/bagpos/苏丹多重集及重抽 profile/终局结果/五项 HUD 可见性/每仪式首见标志/per-id 计数/金币 7000105 派生读/仪式上次投放缓存/cached_event 提示 id/两张玩家级名称覆盖表/两组唯一性登记/两组生成计数器/notes 日志/**Player.pins 终局图钉**及 end/armageddon 三字段）。



导入桥当场抓到并修复的结构偏差：



- **timing_rounds 键格式**：原作键 = TimingRoundBase 实例 +0x20 的 **int**（样本全部 = 事件 id×100，如 5300067→530006700；TimingRoundBase.c IsValid 0x465d30/OnStart 0x4660d0 直接以该 int 寻址 player+0x128）。克隆旧自制格式 `"round_begin_ba:5310000"` 已改为 `event_id*100`（全部 1381 个带回合时机的事件均单桶，序号恒 0；多桶序号分配留待原作侧验证），旧字符串键在 deserialize 迁移。

- **difficulty 基数**：1 基确认（样本 difficulty=1 与 counter 7100006=3、per_round=3、global backToPrevRound=9999 四信号同指简单档）；导入时 -1。

- **min_round**：原作显式持久化 player+0x30 且 OnPrevRound 直读；克隆补 `GameState.min_round`（v7 序列化）作回退门。

- **pins**：`Player.pins`@0x98 是有序去重的 `List<int>`（仪式定义 ID，不是运行 Rite UID）。结算尾链先 `RemoveRite`，随后仅在 `RiteNode.final_pin=true` 时 `AddRitePin`；克隆以 `GameState.rite_pins` 进入 v8 存读档与同刻对拍。

- **仪式槽位映射**：原作 `Rite.cards[i]`（0 基数组，长度=配置 s 槽数）↔ 克隆 `s{i+1}`。



报告三类防静默登记：**converted**（含玩家级覆盖与唯一性登记等标量/结构转换）、**approximated**（active_sudan 的 drawn_round 无法在难度中途切换后反推；每抽前 Shuffle 使牌堆顺序无语义，按多重集对拍）、**dropped**（仅列本存档携带非默认值的克隆缺口字段，如 notes）。



### 阶段二遗留（续局对拍前置）



- 4 个 cloned 探针字段（world_* 等）在导入时取默认值，报告未列（原作无对应物）。

- 续局行为对拍（导入后继续玩 N 天与原作存档互证）待实机样本。


</details>
