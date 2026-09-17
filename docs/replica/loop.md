# 仪式、事件与每日循环

## 正常结算消耗品纠错（2026-09-17）

原先正常结算复用了超时的 `ReturnCards`，导致浴场费用与投入的情报被返还。原作正常路径是 `RiteResultPanelController.DisplayClass56_0.<Settlement>b__5`（0x5b3e20，dump.cs:324962），条件为 `consumable && own && !recovery`；消费回调为 DisplayClass56_4.b__14（0x5b5010），调用 OnCardClean。字段字符串与原始 card/tag/rite 配置提供独立信号；浴场 5001501 不需要额外写 clean 才能消费。

| 输入/路径 | 结算行为 |
|---|---|
| 玩家拥有的消耗品，无回收 | 不回手；幸存者全部返还后，逐张触发 OnCardClean |
| 有回收，或非玩家拥有，或非消耗品 | 返还；按 RemoveTag 0x382e40 移除非叠加 recovery 覆盖；不存在的标签不制造负值 |
| 超时 Dead | 沿用 ReturnCards 0x5016d0，不套用正常结算消费规则 |
| 堆叠金币支付 | 仅消费实际进入槽位的切片，不删除手中余款 |

消费对象仍在 Rite.cards 中供 finalOperations 访问，直到移除旧仪式；不凭空添加 DELETE 表现。复刻使用可保存的 return_cards 阶段及逐张 clean_cursor，遇提示暂停，读档后不重复触发已派发的清理事件。已结算完毕的旧存档不追溯补扣，以免猜测历史投入。

证据强度见 [当前验收](verification.md)：规则与克隆交互回归已验证，原作浴场同输入实机对拍仍未采集，不宣称十天原作结算等价。

## 当前采用的规则

创建、吸附、开始、成熟、支付、结算、返卡、后置操作、移除与次日是独立步骤。运行时直接使用content原始JSONC及重复成员顺序；条件的卡牌域、仪式UID和操作发生上下文要贯穿等待与存读档。

本次纠错：have.<卡id>.<标签>先筛指定卡再求标签数量；不能把整个表达式当标签名。普通吸附收集候选后随机选取，单候选不消耗随机数；此前“总取第一张”的总结撤回。特殊cost堆叠上下文是另一条分支，不据普通随机分支推定已通过。

家业空槽结算、标签生成计数和遗漏仪式入口已修；完整第4→5天仍以verification中的最新实际对拍为准。相同整数seed不足以证明Unity与Godot轨迹一致。所有历史“通过”只约束原报告的局部边界。


## 按实际操作阅读

| 环节 | 合并后的判断与证据 | 尚不能据此推定 |
|---|---|---|
| 建立仪式 | [开局去重](#e050)、[初始人物与吸附](#e049)：创建、自动吸附与开始分开 | 创建成功不代表已开始；普通随机吸附不证明cost堆叠分支 |
| 投放与支付 | [成本语义](#e012)、[上下文](#e013)、[付款](#e014)、[拖卡接入](#e044)共同解释条件与实际支付 | cost不是被拖卡的静态属性，条件通过不代表支付已完成 |
| 修改投放 | [装备](#e045)、[堆叠返还](#e046)、[槽替换](#e047)必须保留实例归属 | 不能仅凭卡id相同把不同UID视作同一张 |
| 结算并跨日 | [事件派发](#e022)、[串行次日](#e025)、[开场奖励](#e028)共同约束顺序 | 存档同刻导入通过不代表执行一天后的状态通过 |
| 页面可用 | [真实投放](#e039)、[家业页面](#e114)、[模板覆盖](#e118)、[俺寻思](#e119)对应不同输入边界 | 模板数量与几何通过不能代替状态、过场、保存恢复闭环 |

## 证据模块

- [cost.* 是交易而不是被拖卡牌的属性（第二十二批，2026-09-10）](#e012)
- [A19 第三十七批：成本上下文与比较符](#e013)
- [A19 付款执行体：`CardSlotController.CardStack`（第三十六批）](#e014)
- [A13 事件派发挂载点真值表（第三十二批）](#e022)
- [NextDay 串行链与每日吸附（第二十一批，2026-09-10）](#e025)
- [开场奖励、抽卡顺序与遗留提示修正（2026-09-11）](#e028)
- [仪式复刻复核法与逐项验收表](#e038)
- [仪式手牌输入与槽位高亮复核（2026-09-11）](#e039)
- [仪式系统根因自审与重新验收](#e040)
- [A19 第38批：成本拆分与补齐接入实际拖卡](#e044)
- [槽位装备来源与自动详情纠偏（2026-09-10）](#e045)
- [槽卡拖回手牌合堆纠偏（2026-09-10）](#e046)
- [A19 第39批：指定槽替换](#e047)
- [初始人物、可见手牌与自动吸附（2026-09-11）](#e049)
- [开局仪式重复：空配置被自制默认值覆盖](#e050)
- [审计报告八：仪式结算管线余项（2026-08-15）](#e060)
- [治理家业页面续修验收](#e114)
- [RitePanelShow — 原作布局真值与克隆映射](#e115)
- [全仪式模板布局普查与修正](#e118)
- [仪式槽与俺寻思交互修复（2026-09-11）](#e119)

<a id="e012"></a>

## cost.* 是交易而不是被拖卡牌的属性（第二十二批，2026-09-10）

证据范围：`docs/replica/loop.md#e012`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### cost.* 是交易而不是被拖卡牌的属性（第二十二批，2026-09-10）



> **2026-09-11 第三十七批更正**：此标题和下文将枚举分支外推到所有成本的结论错误。原作以 is_adsorb 分流；普通落槽确实只判断当前卡。比较符、候选域及首放成本已重新核对，参见 [CostContextCorrection.md](loop.md#e013)。本文保留为历史过程，不作为当前验收依据。



A19 原登记为"只核数量不够，还需付款对象与顺序"。本批回到 `CostCondition.IsSatisfied`，确认克隆把 cost 当成了"被拖动那张卡的标签"，并把它改成原作的**枚举式付款判定**。



### 原作事实



`CostCondition.IsSatisfied 0x3f6160`（`decompiled/CostCondition.c`）：



- **候选来源是 `player+0x88`（`Player.cards`）**，用 `List_Enumerator` 顺序遍历；不是 `GetHandCards`，也不是 `GetTotalCards`。

- 对每个候选先跑内层 `Compare`（构造函数 `0x3f6880` 把选择器解析成 int：`>= 2000000` 走卡牌 id 分支，否则走标签分支），再跑 `param_1+0x20` 的附加条件列表（`ListExtensions.AllSatisfied`）。

- 命中的卡 `FUN_1800032d0` 收进一个局部 `List<Card>`，并 `iVar10 += card.count@0x20`；`iVar10 >= min` 时停止遍历。

- 末尾 `ConditionContext.SetNeedCosts(count, cards)`，返回值 `min <= iVar10`。字段布局由 dump.cs 独立确认：`is_cost@0x60 / cost_count@0x64 / need_cost_cards@0x68 / self_card_index@0x70`（dump.cs:383873 附近）。

- 交付数量（`iVar9`）的取值规则：`max == int.MaxValue` 且 `total >= min` 时交付 `min`；否则 `total >= min && max < total` 时交付 `max`；其余交付累计值 `total`。

- `PostProcess 0x3f6520` 决定 `[min,max]`：值有两个元素时读 `[0]`/`[1]`；单元素且某标志位为 0（对应"卡牌 tag 分支"）时 min 与 max 都取该值；否则按标志位选择"至少/至多"形态。



**配置实测**（`_unpack/data/config` 全量扫描）：`cost.*` 键 **909 个**，标量 746 / 二元组 163；**39 个不同选择器**（38 个 tag + 1 个卡牌 id）。分布高度集中：`金币` 382、`消耗品` 370，两者占 83%。关键点：`2000029 金币` 本身就带 `消耗品` 标签，所以 `cost.消耗品` 常常由金币直接满足。



### 克隆偏差（已修）



原 `eval_cost`：



```

var card := ctx.get("acting_card", {})

var tag_name := k.substr("cost.".length())

return int(card.get("tag", {}).get(tag_name, 0)) >= int(val)

```



三个问题：



1. **只检查被拖动的那张卡**。原作是"玩家手上有对应资源就能付"，克隆变成"拖动的这张卡自己必须带这个标签"。对 `cost.消耗品` 这类由金币满足的常见写法，拖动非金币卡时槽位会错误地判定为不可放。

2. **不累加 count**：原作按 `Card.count` 累加到下限，克隆只比单个标签值。

3. **忽略 `[min,max]` 的语义**：原文注释把它当"资源标签值 >= 下限"，完全没取 max。



### 修复



- `ConditionEval.eval_cost`：改为枚举 `GameState.cost_candidate_cards()`，按 `cost_selector()` 解出的选择器逐个判定，累加 `Card.count` 到下限即停，把选中卡写入 `ctx["need_cost_cards"]`、交付量写入 `ctx["cost_count"]`。

- 新增 `ConditionEval.cost_selector()`（剥掉 `op` 后缀）、`ConditionEval.cost_count_for()`（上述交付量规则）、`ConditionEval._cost_card_matches()`（数字选择器比 `card_id`，否则查有效标签行）。

- 新增 `GameState.cost_candidate_cards()`：按 uid 升序取 `hand / sudan / slot` 三个 zone 的卡，对应 `Player.cards` 的插入序，且**包含槽内卡**（原作是一个 list）。

- 标签判定走 `effective_card_tags`，因此包含运行时增量与 ×count，与第十九批的 tag 模型一致。



### 验证



- 新增 `tests/test_cost_condition.gd`（9 测试 / 21 断言）：无关 acting 卡不阻断可付的 cost、无匹配卡则失败、`Card.count` 累加、达到下限即停并选中**第一个**匹配卡、`[1,2]` 的 max 封顶、`>=` 后缀与数字选择器、有效标签行（配置行 + 增量 + ×count）、槽内卡仍计入、金币满足 `cost.消耗品`。

- 全量 GUT：47 脚本 / 576 测试 / 574 通过 / 4360 断言中 4358 通过（`a19-full.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败仍是既有的 `test_card_flash` 卡面几何与 `test_event_choice_controller` mask 高度，与本批无关。



### 未完成与新增审计线索



- **付款执行体仍未接**：`SetNeedCosts` 只把选择记进 `ConditionContext`；`ClearNeedCosts 0x385470` 在反编译子集里**没有任何调用方**，真正扣卡的那段代码不在子集内。克隆目前只在槽位预检里用 cost 做"能不能放"的门，没有实际扣除，也没有把 `need_cost_cards` 交给结算链。这是 A19 剩下的主体。

- **`cost_count` 为 0 的早期分支**：`IsSatisfied` 开头有一条 `param_2+0x20 == 0` 的路径（读 `+0x10` 的单卡），本批未展开其字段归属，克隆不建模这条分支。

- **标量的 min/max 语义**：`PostProcess` 对单元素值会按标志位决定 "至多" 或 "恰好"，本批按"标量即下限、max 视作无上限"处理并已在代码注释登记；163 个二元组键是确定按 `[min,max]` 读的。

- **`self_card_index@0x70`** 未使用；它在"槽内自卡"类 cost 里的作用未核。


</details>


<a id="e013"></a>

## A19 第三十七批：成本上下文与比较符

证据范围：`docs/replica/loop.md#e013`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A19 第三十七批：成本上下文与比较符



第二十二批只移植了 CostCondition 的枚举分支，却把普通落槽也改成枚举；第三十六批又从完整条件中抽出首个 cost 键。本批纠正这两个根因，不宣称完整付款已接入游戏。



### 原作证据



- `CostCondition.c @ IsSatisfied 0x3f6160`：`is_adsorb@0x20=false` 检查 main@0x10 的选择器和附加条件，然后读取 main.count；数量不足仍 SetNeedCosts(count,null) 后返回 false；选择器未匹配不写成本字段。成功时夹到 Max，is_first_drop@0x22 为 true 时取 Min。

- adsorb 分支枚举 Player.cards@0x88，有限 Max 时累加至 Max，无限时至 Min。Rite.cards 不在该根列表中。

- `ConditionContext.c @ SetNeedCosts 0x385540` 同时写 is_cost=true、cost_count 和 need_cost_cards。独立 `dump.cs:383846` 确认全部字段布局。

- `CostCondition.c @ PostProcess 0x3f6520`：数组指定 Min/Max；标量按 modifier 建界。`Compare.c @ ctor 0x3852a0` 初值 modifier=0，成本无比较后缀时不调用 Update，因此裸键为 Min=Max。

- `Compare.c @ Update 0x384eb0` 与独立 `dump.cs:384167` 枚举 EQUAL=2、LESS=4、GREATER=8：`>`=[N+1,INT_MAX]，`>=`=[N,INT_MAX]，`<`=[0,N-1]，`<=`=[0,N]，等号/无后缀=[N,N]。

- `CostCondition.__c__DisplayClass12_1.c @ 0x40bf70` 数字 id 选择器还排除 IsLost；标签选择器闭包 `DisplayClass12_0 @ 0x40bf50` 调 HasTag。

- `RiteExtensions.CanPutCard 0x3918b0` 运行完整槽条件列表，不能单独执行 DFS 提取的成本叶子。



### 改动与真实配置边界



ConditionEval 按显式 is_adsorb 分流，恢复首放最小量、比较上下界、枚举停止阈值和成本状态字段。slot_cost_needed 删除首键 DFS，运行完整条件；RiteView 预检携带实际 UID 与首放标志。数字 id 成本排除遗世卡，枚举候选排除仪式内卡。



原配置 5000001 s4 同时有 !金币 和 any 内 cost.消耗品=1；旧测试错误地允许金币通过，现在拒绝。5000005 s2 的裸 cost.金币:3 仍要求3枚。新增测试分别覆盖首放、非首放、吸附、数量不足但记录成本、别的手牌不能代付以及枚举至有限上限。



### 未完成



尚未接付款辅助函数到 UI；CardStack 已占槽同类分支、吸附 PostProcess 附加条件、根列表精确顺序及 CanPutCard 特殊标签门仍未统一。未做原作实机同帧对拍，不把此边界的测试通过当作 A19 完成。未修改 content。



### 验证



成本14/40、付款辅助13/40、仪式UI36/175、存档桥6/87通过（测试数/断言数）。模拟组首次出现一条旧测试没有构造运行时当前卡 UID；已修正测试夹具，复跑结果收尾追加。日志 cost-context-*.log。



最终：模拟59/181通过；合计128测试/523断言通过，最终五份日志无失败、SCRIPT ERROR、ERROR、orphan或泄漏报告。git diff --check通过。本批为针对性回归，未重新跑全量；此前两项UI失败和一项无断言风险仍未在本批处理。


</details>


<a id="e014"></a>

## A19 付款执行体：`CardSlotController.CardStack`（第三十六批）

证据范围：`docs/replica/loop.md#e014`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A19 付款执行体：`CardSlotController.CardStack`（第三十六批）



> **2026-09-11 接手复核：本批只落地辅助函数，尚未接入游戏，不能标作 A19 已完成。**

> `ui/rite_view.gd::_place_card_in_slot` 仍直接调用 `add_card_to_slot`；下文“三分支”只覆盖 `CardStack` 的部分路径。

> 原方法 `current@0x148` 非空且同配置 ID、双方可堆叠时，先合并数量，再调用 `CanPutCard`，按 `is_cost/cost_count` 回滚或分配余量；本批未移植此分支。

> 第37批已移除 `slot_cost_needed` 的首键 DFS，改为完整条件求值，并纠正普通成本被错误枚举的问题，详 [CostContextCorrection.md](loop.md#e013)；付款执行接线仍未完成。

> 此外 `CardStack` 对不可堆叠卡返回 false；整张落槽属于另外的 `DropCard(0x53b720)` 路径，不能归入 CardStack 已验证分支。

> 证据：直接重读 `CardSlotController.c @ CardStack 0x53b0a0 / DropCard 0x53b720`；`dump.cs:317918` 的 current/Slot/panel 字段与 `dump.cs:318014` 方法签名。

> 方法尾部存在 `SFxManager.SFxPlayCharacterDub` 调用，故“卡牌配音触发时机全在未导出控制器里”也不成立；完整音频选择算法仍需另查。



A19 的留档写着：



> **付款执行体仍缺**：`ClearNeedCosts 0x385470` 无反编译调用方，克隆未实际扣卡



**三个事实错误叠在一起**：



1. `ClearNeedCosts` 不是付款执行体，它只是 `ConditionContext` 的**字段重置**（`+0x60=0`、`+0x64=0`、`+0x68=null`），而且**全语料零调用方**——它没有调用方是正常的，因为它本来就是死方法。

2. `CostCondition.PostProcess 0x3f6520` 也不是付款，它是**配置加载期**的一遍：`Datapool.LoadRitePostProcess 0x4163c0` 遍历仪式节点，对每个卡的 tag 名跑 `TranslateTag`，然后调 `PostProcess(List<ICondition>)` 把 `Min`/`Max` 解析并缓存下来。它的签名收的是**条件列表**，不是 `ConditionContext`。

3. 真正的付款执行体在**别处**，而且是反编译产物里完整存在的：`CardSlotController.CardStack 0x53b0a0`。



### 原作事实



### `CardSlotController.CardStack 0x53b0a0`



方法开头就有一道门（第 856-860 行）：



```c

lVar1 = *(longlong *)(param_2 + 0x118);              // 被落槽的卡

if (!CardExtensions.HasTag(lVar1, "stackable")) return 0;

```



字面量 `DAT_182593720` 在 `stringliteral.json` 里 = **`stackable`**（`content/tag.json` 的 `可堆叠`）。也就是说**只有可堆叠卡**才走这套拆分逻辑。



然后（第 861-892 行）：



```c

ConditionContext___ctor(ctx, rite+0x90, 0, 0, card, 0, 1, 0);

RiteExtensions.CanPutCard(rite, ctx);                 // 会填 +0x60/+0x64/+0x68

if (ctx.is_cost@0x60 == 0) return 0;                  // 不是付款槽 → 不付

iVar8 = card.count@0x20 - ctx.cost_count@0x64;        // 余量

if (iVar8 < 1) {

    PlayerExtensions.RemoveCard(player, card.id@0x18); // 整张卡离手

    this+0x180 = 1; this+0x184 = 0x3c23d70a;           // 0.01f，缩放入场

    lVar7 = card;                                      // 落槽的就是这张卡本身

} else {

    Card.set_count(card, iVar8);                       // 余量留在手牌

    lVar7 = CardExtensions.Copy(card, keep_count=true); // 复制一张

    Card.set_count(lVar7, ctx.cost_count@0x64);         // 只带应付数量

}

RecoveryCard(); SetCard(lVar7);                        // 付出去的那份进槽

```



**这就是完整规格**：



| 情形 | 行为 |

| --- | --- |

| 不可堆叠卡 | 整张移入槽（`HasTag(stackable)` 门直接返回 0 之前就分好路了） |

| 可堆叠、`count <= cost` | **整张卡**离手并落槽（不拆分、count 不改写） |

| 可堆叠、`count > cost` | 手牌那张 `count -= cost` 留下，**复制**一张 `count = cost` 落槽 |



`cost_count` 的来源是 `CostCondition.IsSatisfied 0x3f6160` 尾段算出的 `iVar9`（第二十二批已复核），也就是克隆的 `cost_count_for()`。



### 槽的 cost 条件在配置里的真实分布



`cost.` 不是罕见的：**1863 个仪式文件里 653 个**在槽条件里带 `cost.`，共 **46 个不同键**。最常见：



| 键 | 出现次数 |

| --- | --- |

| `cost.消耗品=` | 333 |

| `cost.金币` | 323 |

| `cost.金币=` | 57 |

| `cost.可堆叠=` | 27 |

| `cost.不满` | 13 |



操作符是**键的一部分**（`=` / 无 / 其他），且 `cost.` 可以嵌在 `any`/`all`/`none` 里面，例如 `content/rite/5000001.json` 的 s4：



```json

"condition": { "type": "item", "!金币": 1,

               "any": { "cost.消耗品=": 1, "is": 2001303, "空屋": 1 } }

```



`content/rite/5000005.json` 的 s2 是平铺的 `{"type":"item","cost.金币":3}`，槽文案写着"只用花费3金币就行,多花了也没用"。



### 克隆缺口



克隆此前**没有付款执行体**：`add_card_to_slot()` 一律把**整张卡**移进槽，不区分"付出 cost_count"与"填充槽位"。于是：



- 3 金币的槽，玩家拿一张 `count=10` 的金币卡落槽 → 克隆把 10 个金币全放进槽（原作只付 3，余 7 留手牌）；

- 克隆也**没有**槽 cost 查询，落槽前不判断这张卡够不够付。



（第二十二批已把 `IsSatisfied` 的枚举判定做对了，缺的正是"判定→执行"这一步。）



### 修复



### 1. `GameState.pay_cost_into_slot(card_uid, slot, needed, db, rite_uid)` —— 付款执行体



按上表三分支实现：不可堆叠**或**余量 < 1 → 整张移入槽；否则手牌 `count -= needed`、复制一张 `count = needed` 入槽。复制失败时回滚手牌 count。落槽复用现有 `add_card_to_slot`，因此槽位登记、rail 清理、zone 归属都与既有路径一致。



### 2. `GameState.slot_cost_needed(slot, card_uid, db, rite_uid)` —— 槽 cost 查询



深度优先在 `any`/`all`/`none` 里找第一个 `cost.*` 键，取它的值，把解析/比较/夹取全部交给既有的 `ConditionEval.eval_cost`（避免第二份运算符解析），返回上下文里的 `cost_count`；不满足则返回 0。另加 `slot_definition(slot, rite_uid)` 作为槽定义查询。



### 3. 顺手修正一处**幽灵引用**



`condition.gd` 的 `cost_count_for` 文档写着"the count **PayCosts** would hand over"。`PayCosts` 这个名字在 `dump.cs` 里**命中 0 次**——它是编造的。已改为引用真实的 `CardSlotController.CardStack`，并写明这次回归的原因。



### 验证



新增 `tests/test_cost_payment.gd`（**13 测试**），全部对着真实内容与真实偏移：



- 三分支各自的 count/zone/in_hand/slot_key 断言（`count=5` 付 1 → 余 4 留手牌 + 复制 1 入槽；`count=3` 付 3 → 同一 uid 整体移动；`count=1` 付 4 → 整体移动且不改 count）；

- 不可堆叠卡任何 cost 下都整体移动（`HasTag("stackable")` 门的语义）；

- 参数边界（slot 0 / cost 0 / 负 cost / 未知 uid）一律返回 0 且不动手牌；

- 付款切片继承源卡运行时标签增量（`CardExtensions.Copy` 复制 `Card.tag@0x30`）；

- 切片在结算流里记一条 `COPY` 行；

- 槽 cost 查询对着真实配置：`5000005` s2 的 `cost.金币=3` 在 `count=3` 时查得 3、在 `count=1` 时查得 0（条件确实在把关）、`5000001` s4 的 `cost.消耗品=` 能穿过 `any` 找到且要 1、`5000001` s1 没有 cost 键时不发明；

- 分布哨兵：独立重扫 `db.rites` 断言 **653** 个仪式带槽 cost（防文档里的数字腐烂）。



### 仍开放



- **`CanPutCard` 的完整槽接受判定**（槽 type/is/tag 条件 + cost）未接：克隆目前只有 cost 查询，落槽前的完整复核仍走原有路径。本批只保证"该付多少"与"怎么付"两点正确，不宣称整条落槽校验已完成。

- 付款时的 `+0x180/+0x184`（`0.01f`）入场缩放属表现层，未接。

- `cost.<tag>` 无操作符时默认比较符（`Compare` 的 `>=`）由既有 `eval_cost` 决定，本批未改动。


</details>


<a id="e022"></a>

## A13 事件派发挂载点真值表（第三十二批）

证据范围：`docs/replica/loop.md#e022`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A13 事件派发挂载点真值表（第三十二批）



A13 原文留的是两句不确定："事件派发相对闭包的挂载点仍无源（反编译子集缺 GameEventSender）"和 "b__2/b__8 职责未读"。**两句都作废**，原因如下。



### 更正一：`GameEventSender` 不是事件系统，是 PostHog 埋点



`GameEventSender` 一直都在反编译产物里（`engine_spec/decompiled/GameEventSender.c`，113KB、33 个方法），但它与游戏事件无关：



```

public class GameEventSender : MonoBehaviour // TypeDefIndex: 7251

    public static Dictionary<GameEventSenderType, PostHogSenderConfig> Configs; // 0x0

    public PostHogSender postHogSender; // 0x20

    // StartGame / NewGame / ContinueGame / NextDay / DoneRite / CardBorn /

    // OverGame / QuestFinish / UpgradeBuy / SudanRedraw / RoundBegin / ...

```



它是**遥测**：`PostHogSenderConfig` / `PostHogSender`、`OnApplicationQuit` 上报、`PostHogSender_LogMessageReceived`。方法名（`StartGame`/`NextDay`/`CardBorn`…）看起来像游戏事件，这正是当初误判的来源。



真正的事件系统是：



| 类 | 文件 | 职责 |

| --- | --- | --- |

| `EventTrigger` | `EventTrigger.c`（35KB） | 注册表 + 派发：`Add` 0x4fa9d0 / `Remove` 0x4fc3a0 / `On` 0x4fbc20 / `GetActiveEvents` 0x4fba90 / `DoSettlements` 0x4fb1c0 |

| `EventTriggerExtensions` | `EventTriggerExtensions.c`（30KB） | **28 个 `On*` 入口** |

| `EventNode` | `EventNode.c` | 配置节点 |



### 更正二：`b__2`/`b__8` 有源，只是必须带闭包类前缀



`b__N` 编号**每个闭包类各自从 0 开始**，所以裸写 `b__2` 无从查起。带前缀后 `GameController.__c__DisplayClass142_0.c` 里 `OnNextRound` 的 10 个闭包全可读：



| 闭包 | RVA | 关键内容 |

| --- | --- | --- |

| `<OnNextRound>b__0` | 0x5705b0 | — |

| `<OnNextRound>b__1` | 0x570700 | — |

| **`<OnNextRound>b__2`** | 0x570720 | **`EventTriggerExtensions.OnRoundEnd(controller + 0x298)`** |

| `<OnNextRound>b__3` | 0x570790 | — |

| `<OnNextRound>b__5` | 0x570850 | `CheckAllRiteKnow`、`GetCurrentMusicLevel` |

| `<OnNextRound>b__6` | 0x570b00 | `UpdateSudanLife`、`HandCardAutoSort`、`HandCardAutoClassify`、`UpdateHandCards`、`UpdateHandCardPos`×2、`CardArrange` |

| `<OnNextRound>b__7` | 0x570e60 | `TryGenSudanCard` |

| **`<OnNextRound>b__8`** | 0x570f90 | **无任何调用**（既无 `EventTrigger*` 也无 `GameController*`）——本批读空，职责就是空体 |

| `<OnNextRound>b__9` | 0x571000 | （`timing_rounds` 重臂，已在第二十一批核对） |

| `<OnNextRound>b__10` | 0x570600 | `DoGameOver` + `LogException` |



`round_begin_ba` 的挂载点在同族的 `GameController.__c__DisplayClass141_0.c` 的 `<Start>b__5` 0x56f9c0，第 138 行；它紧跟在 `*(int *)(player + 0x2c) += 1`（`round += 1`）之后——**与克隆第二十一批的结论一致**。



### 派发真值表（源 vs 配置 vs 克隆）



数据来源：`engine_spec/decompiled/*.c` 全量调用点扫描（排除 `EventTriggerExtensions.c` 自身的定义行）× `data/config/event/*.json` 的 `on` 块（1863 个文件）。



| timing | 源定义 | 源调用点 | 配置实例 | 克隆 |

| --- | --- | --- | --- | --- |

| `round_begin_ba` | ✓ 0x4fa570 | `DisplayClass141_0.<Start>b__5` 0x56f9c0 | **1381** | 派发 ✓ |

| `round_end` | ✓ 0x4fa730 | `DisplayClass142_0.<OnNextRound>b__2` 0x570720 | 0 | 派发 ✓（保留，有源） |

| `round_begin_fr` | ✓ 0x4fa650 | **无** | 0 | **本批移除** |

| `rite_end` | ✓ 0x4fa390 | `RiteResultPanelController.c` 1289 | 357 | 派发 ✓ |

| `card_clean` | ✓ 0x4f9110 | `RiteResultPanelController.__c__DisplayClass56_4.c` 16、`DesktopCleanCard.__c__DisplayClass4_1.c` 28 | 68 | 派发 ✓ |

| `counter` | （`OnCounterChanged` 无调用点） | counter 写入链 | 16 | 派发 ✓ |

| `game_end` | ✓ 0x4f9950 | `GameController.c` 2868 | 10 | 派发 ✓ |

| `rite_start` | ✓ 0x4fa480 | 2 处 | 7 | 派发 ✓ |

| `close_wizard` | ✓ 0x4f9690 | 2 处 | 5 | 派发 ✓ |

| `card_born` | ✓ 0x4f9020 | `GenCard.c` 298、`GenCoin.c` 125、`GenLoot.__c__DisplayClass16_0.c` 16 | 4 | 派发 ✓ |

| `close_begin_guide` | ✓ 0x4f94d0 | 2 处 | 3 | 派发 ✓ |

| `rite_cancel` | ✓ 0x4fa1b0 | 2 处 | 2 | 派发 ✓ |

| `sudan_redraw_start` | ✓ 0x4fa8f0 | 2 处 | 2 | 派发 ✓ |

| `open_rite_end` | ✓ 0x4f9c10 | 2 处 | 1 | 派发 ✓ |

| `close_prompt` | ✓ 0x4f95b0 | `PromptController.c` 133 | 1 | 派发 ✓ |

| `rite_can_fill` | ✓ 0x4f9ee0 | 2 处 | 1 | 派发 ✓ |

| `back_to_prev_round_end` | ✓ 0x4f8e60 | `DisplayClass141_2.<Start>b__13` 0x5701b0（53 行） | 1 | 派发 ✓ |

| `open_card_info_end` | ✓ 0x4f92f0 | 2 处 | 1 | 派发 ✓ |

| `rite_can_stop` | ✓ 0x4fa0c0 | 2 处 | 1 | 派发 ✓ |

| `open_rite` | ✓ 0x4f9d00 | 3 处 | 1 | 派发 ✓ |

| `open_card_info` | ✓ 0x4f93e0 | `GameController.c` 4714 | 1 | 派发 ✓ |

| `show_wizard_option` | ✓ 0x4fa810 | 2 处 | 1 | 派发 ✓ |

| `rite_can_start` | ✓ 0x4f9fd0 | 3 处 | 1 | 派发 ✓ |

| **`card_dead`** | ✓ 0x4f9200 | **无** | **0** | **本批移除** |

| `rite_begin` | ✓ 0x4f9df0 | `GameController.__c__DisplayClass193_0.c` 21、`RitePanelController.__c__DisplayClass34_0.c` 42 | 0 | 未派发 |

| `rite_clean` | ✓ 0x4fa2a0 | `CleanRite.__c__DisplayClass3_1.c` 24、`__DisplayClass3_3.c` 24、`RiteExtensions.c` 49 | 0 | 未派发 |

| `OnCounterChanged` | ✓ 0x4f9770 | **无** | —（配置用 `counter`） | 用 `counter` ✓ |

| `OnGlobalCounterChanged` | ✓ 0x4f9a30 | **无** | — | 用 `global_counter` ✓ |



### 三条结论



1. **无源且无配置 → 从克隆移除**：`round_begin_fr`、`card_dead`。原作的死亡面是卡自己的 `vanish` 块 + `card_clean`，不是 `card_dead` 时机。克隆此前两处自发派发（`round_loop._update_card_lives` 与 `event_runtime._matches_trigger`）属自制，已删。实测零影响：全 1863 个事件配置的 `on` 块里没有 `card_dead`，所以那次 `fire()` 本来就匹配不到任何事件——但它会去碰 `timing_rounds` 的臂位，且把"存在 card_dead 时机"写进了克隆的公开行为。

2. **`OnCounterChanged` / `OnGlobalCounterChanged` 无调用点**，但配置里确实有 `counter` 时机（16 个实例）。克隆用 `counter` / `global_counter` 字符串派发，与配置键一致——**保留**。这两个方法名对应的机制在别处（counter 写入链），不是死代码问题。

3. **`rite_begin` / `rite_clean` 有源调用点但 0 配置实例**。克隆当前不派发 `rite_begin`；`rite_clean` 在 `round_loop` 里有派发。两边都无实例可验，**登记为低优先待接**（需要时按调用点补，不必现在动）。



### 本批改动



- `sim/event_runtime.gd`：`ROUND_TIMINGS` 由 `["round_begin_ba", "round_begin_fr", "round_end"]` 收窄为 `["round_begin_ba", "round_end"]`（`round_begin_fr` 从未被 `fire` 过，是名单里的死项）；`_matches_trigger` 的卡牌时机组去掉 `card_dead`；上下文文档同步。

- `sim/round_loop.gd`：`_update_card_lives` 不再 `trigger_events("card_dead", ...)`，改为注释记录为什么不能派发（含完整 SRC 指针）。



### 验证



- 全量 GUT：53 脚本 / 618 测试 / 615 通过 / 4547 断言中 4545 通过，零 SCRIPT ERROR、零 orphan、零泄漏；两条失败仍是既有 `test_card_flash` 与 `test_event_choice_controller`。

- 未改任何测试断言——移除的两条派发本来就匹配不到事件，所以没有测试依赖它们（这正是"自制行为被钉在测试里"的反面：这里没有钉子，说明它确实是空转）。



### 仍未做（A13 剩项）



- **`rite_begin` / `rite_clean` 派发**：有源调用点，0 配置实例，低优先。

- **`EventTrigger.DoSettlements` 0x4fb1c0 的结算链**：配置 `settlement` 块的执行顺序未与本表交叉验证。

- **`+0x298` 的连接方式**：`On*` 全部取 `controller + 0x298` 作为 `EventTrigger`；克隆是 `GameState.event_runtime` 直接持有，等价，但未逐点对照 28 个入口的 owner 是否都是同一个 `+0x298`。


</details>


<a id="e025"></a>

## NextDay 串行链与每日吸附（第二十一批，2026-09-10）

证据范围：`docs/replica/loop.md#e025`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### NextDay 串行链与每日吸附（第二十一批，2026-09-10）



A13 原登记为"待复核现状：回到同一调用链审计副作用顺序，禁止把事件已修外推到整日"。本批回到 `OnNextRound` 的 Promise 闭包链，落了**链路顺序真值表**，并在链上找到一处真实缺口（每日 `AdsorbCards`）与一处真实偏差（吸附候选随机取）。



### 原作事实：OnNextRound 的闭包链顺序



`GameController.OnNextRound 0x554540` 先 `GameEventSender.NextDay` + `SaveRoundEnd`，随后挂 Promise 闭包。按闭包 RVA 与方法体（`GameController.__c__DisplayClass142_0.c`）：



| 闭包 | RVA | 主体动作（按书写顺序） |

| --- | --- | --- |

| b__0 | 0x5705b0 | — |

| b__1 | 0x570700 | — |

| b__2 | 0x570720 | — |

| b__3 | 0x570790 | 终局门（`+0x2c8`）→ **`player.round(+0x2C) += 1`**（无条件）→ 置 `+0x18=1` |

| b__5 | 0x570850 | `CheckAllRiteKnow` → `SFxManager.SetVolume` → `GetCurrentMusicLevel` → Animator 触发/SetActive → `MapController.ChangeBGToEnd`（终局分支）→ 返回 `+0x1a8` |

| b__6 | 0x570b00 | 终局门 → **遍历 `player+0x90`（`List<Rite>`）逐个 `RiteExtensions.AdsorbCards(rite, player)`** → `UpdateSudanLife` → `+0x300 = (+0x300 - 1) mod 2` → `HandCardAutoSort` → `HandCardAutoClassify` → `UpdateHandCards` → `UpdateHandCardPos` → `CardArrange` → `UpdateHandCardPos` |

| b__7 | 0x570e60 | `TryGenSudanCard`（+ UI 收尾） |

| b__8 | 0x570f90 | — |

| b__9 | 0x571000 | 红点/恢复周期（`round % sudan_redraw_times_recovery_round`）、日志与动画 |



字段身份由 dump.cs 独立确认（`Player`，TypeDefIndex 6274）：`+0x2C round`、`+0x88 List<Card> cards`、`+0x90 List<Rite> rites`、`+0xB0 List<Card> sudan_card_pool`。



**可确证的顺序结论**：



1. `round += 1`（b__3）**早于** b__6 的吸附与手牌整理，且无条件。

2. 每日吸附（b__6 开头）**早于** `UpdateSudanLife` 与 `TryGenSudanCard`（b__7），因此吸附看到的候选是**当回合抽苏丹卡之前**的手牌。

3. 手牌整理在吸附之后，且在 b__7 抽卡之前。



### 原作事实：AdsorbCards 0x38fca0



- 外层以 `player+0xB0`（苏丹池）的**索引**遍历 `rite+0x30`（槽数组）；`rite+0x30[index]` 为空才处理。

- 只处理 `RiteNode.Slot.open_adsorb@+0x20` 为真的槽（dump.cs:392740 起确认该字段布局：`guid@0x10 / condition@0x18 / open_adsorb@0x20 / is_key@0x24 / is_empty@0x28 / is_enemy@0x29`）。

- 内层按 `player+0x88`（`Player.cards`）**顺序**扫描，用 `ConditionContext` + `CanPutCard` 判定，**取第一个命中**：`RemoveCard(player, card.uid)` → `rite.cards[index] = card` → 记 Note(type 4)。

- 调用点有两个：`PlayerExtensions.InitRite`（创建时）与 `OnNextRound b__6`（每日）。



### 克隆偏差（已修）



1. **每日 AdsorbCards 缺失**：克隆只在 `add_available_rite` → `_adsorb_open_slots` 里做创建时吸附，`advance_day` 从不再吸附。结果是"已存在且已开启的 auto 槽永远不会在回合边界吃牌"。

2. **候选是随机取**：`_adsorb_open_slots` 用 `rng.range_int_half_open(0, candidates.size())` 随机挑一个候选，而原作按 `Player.cards` 顺序取**第一个**命中。这会让同一天吸附到哪张牌随 RNG 漂移；也给调用方凭空增加了一次 RNG 消耗。

3. **占用槽被当作中止**：原实现对"槽已有卡"返回 false 并回退整批；原作只是跳过空指针为假的条目。



### 修复



- `GameState.adsorb_open_slots(instance, db, rng)`：单个仪式的开启槽吸附，按槽序、跳过已占用槽、按手牌顺序取首个命中。

- `GameState.adsorb_open_slots_daily(db, rng)`：按 uid 升序遍历全部仪式实例。

- `RoundLoop.advance_day`：在 `day += 1` 之后、`_update_rite_instances` 之前插入每日吸附，结果写入 `result.adsorbed`。

- `_adsorb_open_slots`（创建路径）：去掉随机选择，改为 `candidates[0]`。



### 验证



- `tests/test_rite_view.gd` 36 测试 / 175 断言全绿。两处受影响 fixture 已按真实语义更新：`test_empty_slot_cycles_qualified_bags_and_keeps_empty_match_state` 现在显式断言"open_adsorb 槽取走手牌第一张（主角），因此合格页集合为 [0]"；`test_restore_last_rite_state_is_partial_and_reforms_stack_count` 先把被吸附的卡取回手牌再测 `OnLastState` 恢复，并断言金币堆仍在手。

- 全量 GUT：46 脚本 / 567 测试 / 565 通过 / 4339 断言中 4337 通过（`a13-full2.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败是既有的 `test_card_flash` 卡面几何与 `test_event_choice_controller` mask 高度，已在前批用基线对照确认与本批无关。



### 未完成与新增审计线索



- **Promise 链的精确插序仍未完全确定**：本批只能按闭包书写顺序与各闭包内部调用顺序确证 b__3 → b__6 → b__7 的相对位置。`NextDay`/`OnRoundBeginBa` 事件本身在反编译子集中没有 `GameEventSender` 文件，事件派发相对这些闭包的挂载点未直接读到，克隆现有的 `round_end`/`round_begin_ba` 位置**未改动**。

- **`b__2`/`b__8` 的方法体未被读出**（只在链中出现），其职责仍未知；不要按位置猜测。

- 每日吸附与"吸附后立刻整理手牌"的 UI 时序未接（克隆是数据层）。

- `AdsorbCards` 的 Note 写入（type 4，count 记被吸卡 id）在每日路径上尚未接；创建路径已有记录。


</details>


<a id="e028"></a>

## 开场奖励、抽卡顺序与遗留提示修正（2026-09-11）

证据范围：`docs/replica/loop.md#e028`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 开场奖励、抽卡顺序与遗留提示修正（2026-09-11）



### 用户反馈与根因



1. 对话确认贴图已有勾号，`EventPromptView._build_confirm` 又向同一 Button 写入“确认/继续”，造成叠绘。原作 `PromptNew.prefab` 的 Confirm（325×158）为图片加独立 InputDisplay，不包含这行居中文字。

2. 卡牌上方的棕色“某卡 放入 S1”来自 `RiteView` 自制 `RiteOverlayToast`，不是卡牌材质、原作槽位提示或原作文字动画。移除节点与内部写点，保留对外 set_log 空接收兼容宿主；原有槽位提示/高亮/合法性判定仍走各自控制器。

3. `ResultExec._apply_table_tag` 遍历 `surface_card_entries`，实际只含槽位卡和独立苏丹卡，遗漏 Player.cards 中的所有普通初始卡。又额外用 context.card_uid/rite_uid 缩小作用域。这使妻子获得追随者、家传铠甲获得已拥有、法拉杰获得追随者等原始开局配置不生效。

4. `Game._start_new_run` 发起开场事件后立即抽苏丹卡，忽略事件 Promise 等待选择的边界。



### 原作证据



- `decompiled/DesktopModifyTag.c` DoTemplate RVA 0x50e400：直接取 Player+0x88，交给 `OperationFilter.Filter(List<Card>)`；不读取 context 的卡/仪式归属。

- `il2cpp_dump/dump.cs:314110–314147`：table/g 注册至 DesktopModifyTag；`OperationFilter.c` Filter RVA 0x3a13c0 为列表谓词入口。

- `data/config/event/5310000.json` op3 给主角专属2增加已拥有并去除专属标记；5310002 op2 给主角专属1增加追随者；5310003 所有分支给妻子增加追随者。未改写或复制任何配置。

- `GameController.__c__DisplayClass141_0.c` b__5 RVA 0x56f9c0：OnRoundBeginBa 后 Promise 链绑定元数据 0x25ac328 / 0x25ac3a0 / 0x25ac058；对应 b__8 检查终局、b__9 HandCardArrange、b__10 TryGenSudanCard（检查 Player.disable_auto_gen_sudan_card）。

- `save_samples/auto_save.json` 首日 notes 的 10002/10001 独立记录家传铠甲2000368、法拉杰2000372、妻子2000006。不是所有开局分支的统一奖励表。



### 实现与验证边界



- table/g 标签操作使用既有匹配器，在普通未入槽卡和已抽出苏丹卡中匹配；不含仪式槽、装备与未抽卡池。

- 开场复用已可存档的 `round_transition`，增加 opening_events → opening_draw → opening_complete；待原始操作队列结清再排列手牌和抽卡，期间不会推进到第2天。

- `tests/test_opening_ui.gd` 走真实主场景 `_start_new_run` 和 OptionGroup/Confirm 按钮信号。按原作存档对应分支选军事贵族、言辞、法拉杰、智慧妻子；逐步骤验证奖励可见，全部开场等待期间无苏丹任务卡，结束后一张。普通手牌 ID 与原作 notes 推导的四张一致。

- `tests/test_startup_rites.gd` 验证等待中存读档、重复 resume 不重复抽卡，以及 context 不得把桌面标签操作窄化到仪式槽。

- 旧 card_instance 测试把人物苏丹2000024伪装为独立倒计时卡，初始人口完整后因此多造一张。改用原有初始人物；保险事件按原 `table_have.2000024` 前提放在桌面，不伪造无归属仪式槽。

- UI 布局测试的跳过开场辅助函数现在明确清除整条开场过渡；它是几何测试夹具，不能当开局验收。真实开局另由上述 UI 测试负责。



截图：`docs/ui_layout/opening_wife_confirm.png`、`opening_reward_hand.png`、`rite_drop_no_toast.png`。截图来自克隆实际 Vulkan 窗口；本批未重启原作进行新的双窗像素差分。当前验证不代表所有开场地图/动画、所有 DSL 方法已完整还原。



旧存档已消费的错误开场选择不会被静默重放或补发奖励；需新游戏验证完整开场。本批未提交或推送，保留此前会话的工作区改动。



### 本批最终检查



- 七组定向 GUT：140/140 测试，1901 断言通过（startup_rites、opening_ui、event_choice_controller、card_instance、sudan、rite_input_contract、ui_layout）。未重跑全库。

- `opening_ui` 在实际 1920×1080 Vulkan 窗口复验，并检查最终截图；屏幕测试画布取真实逻辑视口尺寸，避免测试夹具缩成半幅。

- `tools/verify_rite_slot_input.gd` 实际鼠标输入走查 PASS；拖入后断言不存在 RiteOverlayToast，截图无旧文字。

- 上述最终日志无 SCRIPT ERROR、ERROR、orphan 或泄漏诊断；`git diff --check` 通过。

- 原作配置未改动。日志在 `C:/Users/User/Documents/GitHub/Faust-artifacts/Faust-cleanup-20260911/opening-*.log`。


</details>


<a id="e038"></a>

## 仪式复刻复核法与逐项验收表

证据范围：`docs/replica/loop.md#e038`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 仪式复刻复核法与逐项验收表



2026-09-11。主入口仍为 METHOD_MAP；本表细分它的仪式待办，不另立“已完成”口径。

本次修正与原作实机观察见 [RiteInputCorrection](loop.md#e039)。



### 为什么之前会错



| 失败方式 | 已暴露实例 | 今后的纠正方式 |

| --- | --- | --- |

| 把源码注释当行为证明 | 启动链注释误写 auto-begin | 回到方法体，恢复 script.json 的委托地址，核对被调函数 |

| 只搬一个组件或一层贴图 | 卡槽 Highlight、Outline、OutlineNew 混同 | prefab 全组件列表 → 状态处理器 → 材质开关/动画曲线分别登记 |

| 忽略调用时机 | 打开/读档时直接启动家业 | 每个写点登记触发入口；展示操作不能冒充次日逻辑 |

| 只测人工构造的成功态 | 测试手动 stop，绕过启动 bug | 从真实入口进入；不能用状态修补把失败前提抹掉 |

| 单仪式成功推及全系统 | 浴场可用，家业锁死 | 按配置差异选代表，复用相同输入序列，不添加 ID 特判 |

| 用总绿灯掩盖未测分支 | 节点存在即宣称完成 | 每条独立记规则、输入、表现、持久化四类证据；有缺口不总括完成 |



### 如何找到原作做法



1. 从 METHOD_MAP 取一个共同边界，确定行为域；有 MANIFEST 先按其文件清单阅读。

2. 原始配置确定数据与变体，不能把配置存在当作运行时可达。

3. prefab/scene 找到全部组件、引用、UnityEvent、父级、命中区、遮挡顺序。

4. dump.cs 核对字段偏移和签名，再读 `.c`；间接委托通过 script.json 解到实际方法。

5. 表现查 Sprite → Material → shader variant，以及 AnimationClip 的曲线/事件/重入。

   缺失反编译参数的分支标未知，必要时反汇编或实机验证，不能猜。

6. 原作执行“进入前 → 单次输入 → 中间态 → 稳定态 → 离开/重入”，对照卡 UID、

   槽归属、start/life、候选列表、焦点和各图层；高风险边界必须有独立第二信号。

7. 将公共规则落到共同入口，回归先保留能复现旧 bug 的真实前提，再增加反例。

8. GUT 扫错误/孤儿/泄漏；GUI 真输入；原作状态对拍；视觉单列。分别记结论，不能相互替代。



### 向仪式每个细节推广



“待复核”包含已有实现但证据或覆盖不足；“局部通过”只覆盖链接中的已记录条件。



| 域 / 细节 | 源码或资源导航入口 | 必测差异 | 当前验收 |

| --- | --- | --- | --- |

| 创建、UID、同 ID 多实例 | StartRite / InitRite | 创建/显示/开始分离、同 ID 两实例 | 待完整原作差分 |

| 开放与吸附、槽庇护 | RiteExtensions / Slot.open_adsorb | 条件变化、被占用、跨仪式卡 | 待复核 |

| 地图入口与面板重开 | AddRitePin / ShowRite / Start | 准备、运行、到期、隐藏 | 本批重建不变更 start 已测 |

| 模板几何与层级 | RitePanelShow / CardSlot prefab | 旋转、缩放、前景遮挡、透明命中 | 不以模板遍历替代像素验收 |

| 悬停与提示 | SD_SelectableHelper / SlotTips | 空槽、卡子节点、移入/移出、模态 | 家业/浴场普通路径局部通过 |

| 按下/松开/选择 | CardSlotController / GameObjectActiveProcessor | 有/无合格卡、键鼠/手柄切换 | 有合格卡已测；其余开放 |

| 点击筛卡、首张选择、分页 | HandCardSortByCondition / ClearQualifiedBags | 多页、重复点击、换槽、零结果 | 当前页局部通过；全分页待对拍 |

| 拖动合格槽广播 | DragCard / ShowSatisfiedSlot | 空槽、运行、吸附、部分费用 | 输入回归局部通过 |

| 拖放、替换、退回 | CardDropManager / TryUpdateCard | 槽/背景/卡面命中、外部拖动、无效落点 | 家业/浴场局部通过 |

| 费用与数量 | CanPutCard / cost context | 不足、恰好、超额、堆叠拆合、拒绝不变 | 部分费用已测，边界待完整对拍 |

| 卡牌详情、右键、模态 | CardController / OnPointerUp | 左右键组合、详情遮挡、关闭恢复 | 实际输入局部通过 |

| 恢复上次投放 | OnLastState / LastCardData | 缺卡、数量不足、条件改变、吸附槽 | 已有实现，仍需同存档对拍 |

| 开始与停止 | OnConfirm / OnStop | start_round/start_life/life、事件等待 | 不能由输入通过推及生命周期 |

| 自动开始 / 跨日 / 到期 | OnNextRound 委托 / DoStartAutoBeginRite | 新局不提前开始、读档不重启、多个到期 | 本批修时序，次日集成通过 |

| 候选 prior/normal/extra | EnqueueSettlement / SelectSettlements | prior 排他、装备 extra、自身 scope | 见 RiteSystemRootCause，仍需完整差分 |

| PreStart/PreDo 与骰子 | RiteResultPanelController / Dice controllers | 每条结果的准备、投骰、金骰、重投 | 明确未完成逐项演出 |

| 结果文字、卡操作演出 | ResultPanel / CardController | 跳字、逐段、自动、获得/变化/失去 | 文字部分已接，卡演出未完成 |

| 归还、action、关闭 | ReturnCards / OnClose 委托 | result 与 action 顺序、关闭后处理、final_pin | OnClose 时机仍开放 |

| 事件附加结算 | EventTrigger.DoSettlements | 普通/附加项、等待选项、嵌套事件 | 未整合完成 |

| 俺寻思锁卡/对白/动画 | ThinkController / SlotPop / clips | 连续投放、终止、effect/Folder/搬移 | 共享结算已接；表现仍开放 |

| 帮助与提示层 | RitePanelTitle / Prompt | 父级坐标、滚动、取消、遮挡 | 几何已有来源，交互组合待复核 |

| 存读档与回退 | Player / Datapool / 原作 save_samples | 各等待阶段、重启、同 ID、多仪式 | 准备/运行重建已测；结果呈现恢复开放 |

| 音效、粒子与动画同步 | Animator/Animation events / sfx config | 重入、打断、加速、暂停 | 不用自制时长冒充原作，待逐项普查 |



### 收尾门槛



每项记录配置 ID、进入方式、前置状态、输入、原作观察、克隆结果、原始来源、测试和剩余差异。

代表覆盖至少包括自动家业、手动浴场、费用槽、吸附槽、俺寻思、多实例与等待中断。

后续新发现必须加入对应行并扩展反例；不得继续把未知项埋在“1:1 完成”后的脚注里。


</details>


<a id="e039"></a>

## 仪式手牌输入与槽位高亮复核（2026-09-11）

证据范围：`docs/replica/loop.md#e039`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 仪式手牌输入与槽位高亮复核（2026-09-11）



这是仪式整体整改中的输入批次，不是整套仪式完成声明。



### 根因与修正



| 原作入口 / 证据 | 克隆偏差 | 本批修正 |

| --- | --- | --- |

| CardController.OnPointerUp 0x52afe0 | 槽内普通单击直接回手 | 与手牌共用详情入口，保持槽归属 |

| CardController.OnPointerDown 0x52abc0、OnPointerUp 0x52afe0；dump.cs:264038–264042 Mouse 按键偏移 | 右键快捷分支未接 | 右键手牌向打开的仪式投放，右键槽卡取回；运行/吸附槽仍锁定 |

| CardDropManager.DropCard 0x4ef4f0；RitePanelShowController.TryUpdateCard 0x598140 | 仅精确命中槽位才可投放 | 面板空白处按顺序先试空槽，再试已占用槽；目标替换仍调用原条件检查与付款链 |

| GameController.DragCard 0x54ef50 → RitePanelShowController.ShowSatisfiedSlot 0x596070 | 没有拖动开始/结束的合格槽广播 | 提示全部可移动空槽；CanPutCard 或 is_cost 成立即提示；结束淡出 |

| CardSlot.prefab Highlight + slot_highlight.mat | 直接绘制 card_outline.png，漏掉原作内描边材质 | 复用已核实的 GUI SSU 八邻域内描边 shader，使用该材质自己的颜色、宽度与 fade |

| CardSlot.prefab OutlineNew + riteslot/show/hide/flash.anim | 缺独立合格槽图层与动画 | 197×423、中心偏移 (0,-19)，按原始 alpha 时间和零切线 Hermite 曲线播放 |

| 原作打开 RitePanelShow 后仍可从手牌 DragCard/DropCard | Godot 只提高 hand z_index，整屏遮罩仍先接到点击 | 仪式单独打开时调整手牌/分页节点输入顺序；详情等模态打开时恢复模态优先 |



### 材质与动画证据



原始路径均在只读语料 `unity_export/ExportedProject/Assets/`：



- `Resources/materials/rite/slot_highlight.mat`：GUI SSU，启用 InnerOutline + OutlineOnly；

  `_InnerOutlineFade=1`、`_InnerOutlineWidth=.08`、颜色 `(0.94639033,0.8695029,0.6157619,1)`。

- 当前 `ui/card_flash.gdshader` 对应已导出的 DXBC `docs/ui_layout/shader_evidence/184_118.asm`：

  四轴 + 四个 `.705` 对角采样，最小 alpha、宽度×100/texture size、保留源软 alpha。

  本批重新读取指令并核对材质开关；没有沿用 CardFlash 的金色和默认 fade=0。

- `Resources/anims/riteslot/show.anim`、`hide.anim`：OutlineNew alpha 在 `0..0.33333334s`

  间 `0→1` / `1→0`，两端切线为零。flash 在 `0.6666667s` 回到零。

- `Sprite/outline_new.asset`：200×424，完整纹理。新增 `rite_slot_outline.png` 为原纹理直拷，

  SHA256 `8F1357F87D25005E595869F5119DC61CE1B8068FB78BC0A65F27B635DA9E2489` 与源文件相同。



### 验证



仓库外日志：`C:/Users/User/Documents/GitHub/Faust-artifacts/Faust-cleanup-20260911/`。



- `rite-input-contract-final.log`：4/4，26 断言，真实配置覆盖空槽优先、替换、运行锁、

  1 金币对 3 金币成本槽的部分投放、拖动与鼠标高亮分离。

- `rite-interaction-view-final.log`：37/37，188 断言。

- `rite-interaction-ui-final.log`：81/81，1077 断言。

- 上述日志无 SCRIPT ERROR、ERROR、孤儿、泄漏。早期测试日志出现的已释放前一帧节点计数

  和无 UI fixture 触发动画错误已经修正；不拿早期日志的绿色汇总作验收。

- `tools/verify_rite_slot_input.gd` 使用实际 viewport 鼠标事件与 Godot 拖放系统。

  1920×1080 和 2560×1440 分别 PASS：普通悬停/提示、拖动广播、面板投放、左键详情、

  详情遮挡手牌、右键取回/投放、空槽优先、拖到已占用卡替换、运行锁、解锁后拖回。

  **撤回该轮启动流程验收**：旧测试先 stop 治理家业，掩盖了克隆提前自动开始的错误。

  该轮只能证明人工准备态内的输入路径；下方二次复核已删除这一绕过。

- 截图：`docs/ui_layout/rite_drag_slots.png`、`rite_hover_material.png`。



### 尚未验收



1. 本批没有重新做原作同存档、同帧截图差分，不能声称像素已完全一致。

2. CheckSlotPops 投放后的角色对话，以及 Prompt 材质参数动画尚未完整迁移。

3. 前批记录的逐项 PreDo/骰子/卡牌演出、附加事件结算、OnClose 时机、读档恢复仍开放。

4. 模态/输入顺序已通过这里列出的流程，未冒称所有仪式、所有模态组合遍历完成。



### 二次复核：共同根因而非仪式特例



### 已确认



`ui/game.gd` 在 `_start_new_run` 和 `_show_game` 都调用自动开始，导致治理家业

`auto_begin=1` 在玩家操作前变成运行态，而手动浴场未受影响。随后 `_can_edit_slot`

正确拒绝运行槽，连带阻断点击空槽的合格手牌选择；焦点留在槽上，Selected 又使

Highlight 隐藏。这是 **错误时序 → 正确的运行锁 → 输入回调提前返回 → 焦点/轮廓异常**。

不能靠解除运行锁、忽略 Godot 焦点、给家业写特殊高亮修好。



旧注释声称原作启动链有 auto-begin；直接读取以下委托后推翻该结论：



| script.json 方法元数据 RVA | 实际函数 | 行为 |

| --- | --- | --- |

| 0x25ac328 | DisplayClass141_0.b__8 0x56ff30 | 检查 game_over，抛异常 |

| 0x25ac3a0 | b__9 0x56ffa0 | HandCardArrange |

| 0x25ac058 | b__10 0x56f780 | TryGenSudanCard |

| 0x25abc98 | c.b__141_11 0x56f3d0 | SaveRoundBegin / SaveGlobal |

| 0x25ac490 | DisplayClass141_2.b__13 0x5701b0 | 回退事件 |

| 0x25ac508 | b__15 0x570310 | 恢复 HUD、手牌可用性、笔记和首选项 |

| 0x2599300 | DoStartAutoBeginRite 0x54ebc0 | 引用于 OnNextRound 的 Promise 链 |



`GameController.c Start 0x557e10` 与 `DisplayClass141_0.b__5 0x56f9c0` 是入口。

读取 `.c` 时必须恢复间接委托，不能根据函数次序猜测、也不能因搜索不到直接调用就判无调用。

`RitePanelShowController.Show 0x596450` 的 `!open_adsorb && !start` 仍保留，未放松运行锁。



### 本次原作实机观察



Computer Use，运行版 1.0.2feaceb3，2560×1440，继续现有存档：



- 治理家业准备态：悬停空人物槽有内轮廓与“任何可以辅佐的人”；点击后合格手牌

  被突出并选中首张，鼠标仍在槽上时轮廓保留；移开隐藏、再移回恢复提示与轮廓。

- 浴场里的消息：点击空人物槽同样突出合格人物、选中首张、保留槽内轮廓。

- `CardSlotController.OnSubmit` 调用 `HandCardSortByCondition(..., select_first=1)`；

  `SD_SelectableHelper.get_currentSelectionStaet 0x433bf0` 优先级为 Disabled > Pressed >

  Selected > Highlight > Normal。不能将独立的 OutlineNew 拖动动画当鼠标悬停。

- 鼠标点击后由手牌承接选择，故这条有合格卡路径不需要自制“点击后强制高亮”。

  **无合格卡、手柄选择及 AssociateInputDevice 分支仍待单独核验**；其 `.c` 丢失部分

  bool 参数，不能凭字段名猜开关极性。



### 修正与复验



删除两个提前自动开始调用；`_show_game` 保留准备/运行状态，自动开始仍由次日链负责。

不自动改旧存档 start：无法可靠区分旧错误写入和玩家确实启动的仪式。



- `rite-input-systemic-final.log`：5/5、30 断言；含重复重建保留准备态、真正运行态和 start_round。

- `rite-start-integration-final.log`：14/14、73 断言；自动开始模拟链仍通过。

- `rite-slot-cross-rite-final.log`：`RITE_SLOT_INPUT: PASS`，1920×1080；删除开局 stop，

  治理家业点击/移开/移回、面板投放、替换、详情遮挡、运行锁、回手全部通过；

  浴场复用同一套点击/移开/移回、拖放和右键回手。

- 上述三日志无 ERROR、SCRIPT ERROR、orphan、泄漏。原作观察与克隆输入测试不是

  同存档逐帧像素差分，不能据此将所有仪式或所有渲染分支标记完成。



### 2026-09-11 槽卡拖出：归属切换时点



根因：此前隐藏拖动源贴图，却把卡一直保留在源槽中，直到松手才移出；

无效落点又恢复原槽贴图。于是拖动期间槽底、属性汇总和后续判定都仍含旧卡。



原作依据：`CardController.OnBeginDrag 0x5294e0` 检查 CanMove 后调用

ICardSlot 的 slot 3，随后清空 CardSlot@0x120、标记 isRemovedFromSlot@0x189。

`dump.cs:312101–312118` 确认 slot 3 是 RemoveCard；

`CardSlotController.RemoveCard 0x53c7b0` 立即 SetCard(null)。

`OnEndDrag 0x52a570` 已由目标处理则返回，否则将移出槽的卡 AddCard 后

BackToHandOrBag。原作没有“无效落点恢复旧槽”的分支。



共享修正：CardWidget 发出拖动开始/结束；RiteView 开始时即解除槽归属、

刷新空槽和汇总，临时保存不可见源节点以接收 Godot DRAG_END。有效落点保留新归属；

无效落点走手牌回收动画；面板移出场景树时回收悬持 UID。

`drag` 是宿主输入适配器的临时归属，不是原作配置格式，也未改动 content。

装备与合堆入口同步接受已通过 CanMove 并脱槽的卡，结束回调不会复活已合堆的源 UID。

拖动预览沿用源码背书的归一化姿态及 CardNew.prefab 的 dragAlpha=0.6；

没有为槽卡另造尺寸或透明度参数。



验证（日志在仓库外 `C:/Users/User/Documents/GitHub/Faust-artifacts/Faust-cleanup-20260911/`）：



- `rite-detach-gut.log`：11 测试 / 56 断言，含拖起即脱槽、失败回手、跨槽、

  关闭面板、运行锁、装备和合堆不重复返卡。

- `drag-test_rite_view.log`：37 / 188。旧夹具只有裸 Button，补齐其必需的

  SourceHighlight 子节点后复跑，消除渲染函数中断及孤儿节点。

- `drag-test_card_stacking.log`：10 / 56；`drag-test_card_evolution.log`：18 / 129。

- `drag-test_save_import_bridge.log`：7 / 91，原作存档证据对拍保持通过。

- `rite-detach-input-final.log`：1920×1080 真实 viewport 输入 PASS，覆盖

  按住不松手时空槽/实例已清空、无效落点回手、直接拖回手牌、跨槽、家业与浴场。

- 最终上述日志无 ERROR / SCRIPT ERROR / orphan / 泄漏；git diff --check 通过。



原作实机范围：1.0.2feaceb3 / 2560×1440，继续存档、家业快捷投放梅姬，

观察到卡上方“招待客人的菜肴都准备好了”气泡和属性汇总变化。Computer Use 的

drag 尝试没有建立可确认的拖动状态，因此本批拖出规则的原作证据是 .c + 接口声明，

不宣称已完成原作拖出动画的逐帧像素对拍。悬持时存档/读档边界亦未专项验收。



### 保留的下一项：SlotPop



已定位 CheckSlotPops 0x53b490 → AddSlotPops 0x592370 → DoSlotPops 0x5931d0

→ CardPop.Do 0x4f1c70 → CardController.ShowPop 0x52c010。

家业配置 cards_slot.*.pops 是条件与任意 action 序列，不能简化为手写台词表。

原作是卡牌锚定气泡；现有通用 prompt 不是该表面。队列取消、self_slot、初始

FAILED 状态、拖动打断及动态宽度仍须完整接入，**本批未实现 SlotPop**。


</details>


<a id="e040"></a>

## 仪式系统根因自审与重新验收

证据范围：`docs/replica/loop.md#e040`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 仪式系统根因自审与重新验收



2026-09-11。用户要求完整复刻原作仪式：外观、交互、动画、规则、时序与存读档都在范围内。

旧的局部完成标记不构成整套仪式的验收。



### 根因



1. 用 prefab 布局覆盖率代替运行流程覆盖率；1495 个配置能打开，不等于每个仪式能完成。

2. 源码注释替代了字段核验：ProcessPop 的 +0xB0 被误当 settlement，实际是 cards_slot，

   闭包是 SlotPop。该错误造成独立的全匹配俺寻思结算器长期存在。

3. 三套执行入口分叉：RiteView 全存档预演/回滚，RoundLoop 无交互即时结束，Methinks 自制循环。

4. 测试锁定了错误契约，例如“投卡不应处于 thinking”；绿灯只能证明测试期望被满足。

5. 未完成项被追加到越来越长的日志，而没有阻止同一模块继续标记“1:1”。



### 本次直接核实的结构冲突



| 原作事实与双信号 | 当前冲突 | 整改入口 |

| --- | --- | --- |

| EnqueueSettlement 0x5a2d10；dump.cs:325472–325474 settlements/finalResults/finalOperations 三队列 | 选一项就执行 result/action，后续条件可被提前结果改变 | RiteResolver：分离选择与执行 |

| DisplayClass56_0 b__4 0x5b3a50 执行 finalResults，b__7 0x5b45c0 执行 finalOperations；二者之间有卡牌处理和 NoteRiteDone | normal.action 提前于 extra.result | 全部 result 队列在 action 队列前 |

| ThinkController.OnCardLocked 0x5c2d10 → GameController.Settlement；RiteNode 定义/5000002 配置 | Methinks 绕过 prior、extra、公共结算器 | 删除独立分支规则 |

| OperationsExtensions.Start 0x500a70 / Promise.Sequence；现有事件链已可保存 continuation | 仪式遇到选项仍提前执行后续结果/移除仪式 | 将仪式接入可暂停操作链 |



### 整体验收清单（尚未完成，不得缩减成外观工作）



- 创建、实例 UID、开放/吸附条件、地图定位与可见性。

- 准备：提示、高亮、合规卡筛选、拖入/替换/付款/回手、恢复投放、帮助。

- 开始/运行：必填与代价、开始日/寿命、停止、跨日、自动开始/到期。

- 结算：prior/normal/extra 与卡牌装备 extra、PreDo、骰子阶段、金骰/重投。

- 串行演出：文字等待、操作卡列表、卡牌变化、归还、action、结束与 final_pin。

- 俺寻思：SlotPop、原动画事件、共享结算、ithink_card、卡归属和再次投放。

- 同状态存读档/回退、提示中断、两个以上同时到期、多个同 ID 实例。

- 原作同存档状态/输入/截图对拍。专项测试和模板截图不能替代此项。



本文件是重新验收入口，具体修复及未通过项持续追加；没有原作背书的边界不得用直觉补全。



### 已落地的结构整改（2026-09-11，整体验收仍开放）



- `RiteResolver.select_settlements` 只收集结果，不预先发奖励；删除 UI 全存档预演/回滚。

  prior 命中跳过 normal/仪式 extra，卡牌与递归装备的 post_rite 仍参与，每项保留自己的 self。

- `RiteSettlement` 将桌面、跨日、俺寻思接到同一持久化执行链：所有 result → 归还卡 →

  所有 action → 移除实例。提示和选择未完成时不进入下一阶段；保存原始操作顺序与执行位置，

  避免存档 JSON 排序改变 case/option 顺序。各项独立重置操作状态。

- `ThinkController.ProcessPop 0x5c38b0` 改按 SlotPop 处理；等待提示后进入原 ThinkOver

  2 秒锁卡边界，再走公共结算。`ithink_card_uid`、think_session、结算 continuation 可保存。

  精灵帧/关键帧时间来自原始 .anim；effect/Folder 曲线和卡牌解锁搬移动画尚未完成。

- `OnConfirm 0x58f1c0` 的开始事件从“打开面板”迁到“确认开始”，保留 start_life 后将 life

  清零，并串行等待 rite_start → rite_begin。自动开始不是该手动确认入口。

- 区分 `auto_result` 配置能力、`auto_result_rites` 单仪式跳过演出、`rite_auto_result` 全局

  文字自动播放；不能再由配置能力直接提交结果。

- 跨日按实例顺序逐一处理到期仪式，当前仪式等待时不预先增加后续仪式 life；重复下一天被挡住。

- 保存恢复使配置数字成为 JSON float 时，装备选择器仍按整数 ID 解析，修复 parent-equip 失效。



以上是已经实现的边界，不是完整复刻结论。正在重跑全量 GUT；以最终日志计数为准。



### 新核实的剩余差异（不可用旧完成标记覆盖）



### 委托反查发现的既有结论冲突



`GameController.OnNextRound 0x554540` 不仅有显式调用，还有传给 Promise.Then 的方法地址。

`il2cpp_dump/script.json.ScriptMetadataMethod` 给出独立映射：



| 方法元数据地址（RVA） | 实际委托 |

| --- | --- |

| 0x2599300 | DoStartAutoBeginRite 0x54ebc0 |

| 0x25991a0 | DoCardUpdate 0x54d4c0 |

| 0x2599870 | UpdateSudanLife 0x55aeb0 |

| 0x2592010 | OnRoundBeginFr 0x4fa650 |

| 0x2599288 | DoRiteUpdate 0x54ea40 |

| 0x2599218 | DoDelayOpertions 0x54da50 |

| 0x2591fa0 | OnRoundBeginBa 0x4fa570 |



由 OnNextRound 的 Then 链得到：SaveRoundEnd → 自动开始 → 卡牌更新 → RoundEnd → round+1 →

RoundBeginFr → 清除结束的 delay → 仪式更新 → 延迟操作 → RoundBeginBa → 吸附/整理 → 苏丹抽卡 →

重抽恢复。旧文档“round_begin_fr 无调用”和“先仪式后卡衰减”均错误，不能继续作为依据。

根因补充：**搜索不到直接函数名，不等于没有委托调用**；今后无调用结论必须同时查方法元数据引用。



| 边界 | 原作证据 | 状态 |

| --- | --- | --- |

| 未开始仪式到期 | RiteExtensions.Dead 0x501460 → DisplayClass0_0 b__0 0x505130：先筛选全部 timeout 项，再全部 result → ReturnCards → 全部 action → b__1 0x505630 RemoveRite；dump.cs:312039–312078 / RiteNode.waiting_round_end_action@0x58 | 已迁入可等待执行链，保存恢复与阶段顺序回归通过；不再凭 result_text 生成原作不存在的弹窗 |

| 卡牌后处理 | CardExtensions.DoPostRite 0x4f0d70 检查装备，DisplayClass2_0 b__0 0x506010 检查宿主寿命，不增加 life；CardNode.post_rite@0x88 是另一条结算候选链 | 寿命处理已接，装备继承宿主庇护；UI 的后处理仍早于原作 OnClose，尚未完成相同时机验收 |

| 逐项演出 | ResultPanel PreStart/PreDo、文本/骰子/卡操作阶段 | 已改点击正文逐段追加、确认完成后开放；仍缺逐项骰子与 PreDo 卡操作演出，不得算全链还原 |

| 事件附加结算 | EventTrigger.DoSettlements 与结果面板回调 | 尚未整合到仪式候选流 |

| 跨日完整队列 | GameController.OnNextRound 0x554540 的 Promise 委托顺序 | 已重排并持久化等待阶段；两仪式实际输入测试通过。延迟取消/清理与原作完整差分仍待完成 |

| 原作存档/实机 | 原作运行版 1.0.2feaceb3；语料样本与同输入截图 | 仍缺完整结果流程对拍；不得拿 Godot 输入测试替代 |



### 归还后作用域与实机复验



- `RiteExtensions.ReturnCards 0x5016d0` 遍历 Rite.cards@0x30 并调用 AddCard，**没有清空该列表**。

  克隆将卡牌移回手牌时清空物理槽位，因而新增结算内的存活卡引用，供 finalOperations 的

  sN/all/id/侧别选择器继续寻址；清理后的卡不会恢复，引用随等待序列存读档。

- `GameController.DoCardUpdate 0x54d4c0` 枚举 player.cards 后枚举 rite.cards，快照其庇护标志；

  `DisplayClass196_0 b__0 0x572220` 先更新装备，b__1 0x572420 再更新宿主。

  已排除实例注册表中的未持有对象，并让装备继承宿主庇护。装备过期后先从宿主解绑。

- `ThinkController.ProcessPop 0x5c38b0` 明确 SetLastOpState(1)，dump.cs:394463 为 FAILED。

  俺寻思 SlotPop 的初始状态已修正。最终结果 `DisplayClass56_3 b__13 0x5b4f20` 与

  最终行动 `DisplayClass56_5 b__15 0x5b5070` 也明确设置 FAILED；已分别传入初始状态，

  普通操作和 Dead 的新 context 默认状态仍为 SUCCESS。专项新增两阶段起始分支回归。

- 原作实机观察：权力的游戏先显示介绍，正文点击逐段追加，底部确认此时不可跳过；

  后续左盘出现“谗言／新出现！”卡牌演出。最后一项仍是克隆的明确缺口。

- `tools/verify_rite_round_input.gd` 实际注入鼠标事件，验证两个到期 UID 依次展示、

  正文逐段点击、底部确认解锁、重复跨日被挡、奖励各一次；输出 `RITE_ROUND_INPUT: PASS`。

- `tools/verify_rite_think_input.gd` 复验拖书→锁卡→生成淘书仪式、动画回 idle、

  再次可投卡以及槽提示/高亮；输出 `RITE_THINK_INPUT: PASS`。



### 仍阻止“彻底克隆完成”的项目



1. PreStart/PreDo 与每项结果对应的骰子、卡牌演出；当前纯文字操作行不能替代原作卡动画。

2. EventTrigger.DoSettlements 的附加结算接入。

3. 原作 OnClose 后处理时机、结果面板保存后的呈现恢复。

4. Think effect/Folder 曲线、锁卡/解锁搬移动画与 SlotPop 原气泡。

5. 完整原作同存档、同输入的状态差分；当前模板普查、GUT 和两条 GUI 流均不足以关闭此项。

6. 每日更新虽然已修复装备庇护和未持有对象误更新，但玩家卡/活动苏丹卡的原作交错枚举顺序、

   每个宿主轮到更新时才枚举其装备的边界仍需补齐，不能把当前快照实现称为完整 DoCardUpdate。



### 验收纪律



- 方法签名和 prefab 几何仅作为该项证据，不能汇总成“仪式完成率 100%”。

- 任一新结果展示路径必须经过真实点击到下一仪式，不能仅断言某个面板节点存在。

- 每次 GUT 必须同时扫描 SCRIPT ERROR/ERROR、孤儿和泄漏；本次一个 fixture 曾在仪式

  已结算移除后访问 life，GUT 仍判绿。已改成独立长寿命 fixture，旧绿色日志不作验收。

- 异步提示必须由产生提示的回调刷新表面。ThinkOver 锁卡回调此前只写状态而不刷新 UI，

  玩家看不到提示，循环却一直等待；该漏接已修复并由 81 项界面测试及实际拖卡复验覆盖。



### 卡牌演出差异的直接证据



`GenCard.PreDo 0x510830` 读取配置名与数量，AppendSeperate 后调用

`OperationContext.AddCardOp_NewCard`；`GenCard.Do 0x5101d0` 才通过

`GameController.GenCard` / `PlayerExtensions.AddCard` 创建设定数量的对象并记奖励。

两者不是“先执行奖励再回滚”的关系。`OpCardNewController.Init 0x572f40` 对 NEW 使用

配置 id/count、对 COPY 使用原 Card 引用，交给 `OpCardShowRender.AddOpCard` 独立渲染，

不是把手牌对象直接移动过来，也不是从执行后的状态日志倒推。



已用语料导出器新增三张原始布局真值表：

[`OpCard`](layout.md#e104)（29 节点）、

[`OpCardShow`](layout.md#e105)（1 节点）、

[`RiteResultPanel`](layout.md#e117)（209 节点）。

OpCard 根 564×661，CardShow/Equip 各 256×512，NewGet 200×60 / fs30，

TagBg 200×100；它们目前只是证据，**未宣称对应渲染器或 PreDo 已实现**。

必须按这条独立演出链补全，不允许再恢复全状态预演回滚或用 DSL 文本行替代。



### 本次验证记录



日志均位于仓库外 `C:/Users/User/Documents/GitHub/Faust-artifacts/Faust-cleanup-20260911/`。



- `rite-full-final.log`：61 脚本、710/710 测试断言通过、6357 断言；但旧版

  DayTimingProbe fixture 存在一次空对象脚本错误，因此**不称此日志为干净全绿**。

  该进程缓存了修复前的测试脚本；对应 fixture 已改用独立长寿命仪式。

- 修复 fixture 并补上最终队列 FAILED 初始状态后：`rite-status-final.log`

  18/18、93 断言；`rite-status-integration.log` 14/14、73 断言，均无脚本错误或泄漏。

- 界面专项 `rite-ui-final.log` 81/81、1077 断言，包含异步俺寻思提示；

  结果页 `rite-paragraph-validation2.log` 37/37、188 断言；笔记专项 5/5、17 断言。

- 实际输入 `rite-status-round-input.log`、`rite-think-input-final2.log` 均 PASS，

  无引擎错误/孤儿/泄漏记录。前者在最终状态码修正后重新运行。

- `rite-content-parity.log`：3889 个文件、0 违规。原作存档导入桥已包含在全量验证中；

  这是同瞬间字段对拍，**不是完整仪式同输入差分**。

- `git diff --check` 通过。本批作为阶段性修复提交；不代表仪式整体验收完成。



本次完成根因审计与已列明的核心执行整改；上面的六项缺口仍阻止整套仪式的最终验收。


</details>


<a id="e044"></a>

## A19 第38批：成本拆分与补齐接入实际拖卡

证据范围：`docs/replica/loop.md#e044`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A19 第38批：成本拆分与补齐接入实际拖卡



### 来源与行为



直接复读 `CardSlotController.c @ CardStack 0x53b0a0`：传入卡须可堆叠。空槽/不同配置卡使用首放上下文，同配置已占槽先把两张 count 合在 current 上，再用非首放上下文重算；is_cost 未设置时回滚。该方法只检查 is_cost，不检查 CanPutCard 返回值，所以数量不足但匹配成本选择器仍可部分入槽。



同类合堆余量 = 合计 − cost_count；目标 current.count 写 cost_count，余量大于零写回 incoming.count，否则移除 incoming。`dump.cs` CardSlotController.current@0x148、ConditionContext.is_first_drop@0x22/成本字段独立确认对象身份。`CardDropManager.DropCard 0x4ef4f0` 先 CardStack，再在其返回 false 时走 TryUpdateCard/DropCard。



### 已接入



`RiteView.drop_card_on_slot` 与 `_place_card_in_slot` 先尝试成本分支，空槽调用既有 pay_cost_into_slot，合堆保留原槽卡身份和超额来源卡。`can_drop_card_on_slot` 使用同一成本上下文，允许逐步补齐。悬停查询临时合计后立即恢复计数，无持久写入。



删除槽位路径的通用 stack_cards 调用：无成本条件不能仅凭同配置ID无限合堆。旧卡面转发测试改用真实5000005 s2，不再以清空condition的自制夹具作为正确答案。普通不涉及成本的手牌合堆保持现有共享实现。



### 验证



- 原配置5000005 s2：10金币入槽后付3留7；先放1再放5得到槽3/手3，槽UID不变；先1再2移除来源卡；连续悬停不改数量；无关装备不能借金币支付。

- 跨仪式来源：10枚拆3后原槽保留7；精确3枚整体移动后原槽引用清除。

- `tools/verify_slot_cost_input.gd` 注入真实GUI拖动输入，1280×720与1920×1080均PASS。截图 `docs/ui_layout/slot_cost_{1280,1920}.png`，已查看1280截图。此为克隆输入验收，不是原机同帧像素对拍。

- 既有仪式组36测试/175断言、卡牌堆叠组10/56通过。新增生产落槽组结果见最终日志 `slot-cost-drop.log`。



### 仍开放



本批未声称完整A19：0成本产生的零数量卡、源TryUpdateCard替换/路由全链、自动吸附附加条件及成本执行演出的0.01缩放和配音仍需继续。跨槽数量与归属已测，但拖动起始就离槽的完整原作时序仍登记在A05。没有修改content、没有提交或联网。



最终验证：新增7测试/35断言，合计53测试/266断言通过；最终日志无SCRIPT ERROR、ERROR、Orphans或泄漏。初次同帧连续刷新产生待queue_free容器的中间孤儿报告，测试收尾等待2帧后确认释放，复跑日志干净。git diff --check通过。本批未重跑全量，既有两条UI失败与一条风险项继续保留。


</details>


<a id="e045"></a>

## 槽位装备来源与自动详情纠偏（2026-09-10）

证据范围：`docs/replica/loop.md#e045`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 槽位装备来源与自动详情纠偏（2026-09-10）



ApproximationAudit A05 第七批。沿上批槽出合堆继续查通用拖放分支，没有以另一套目测参数替换原作规则。



### 已确认原作事实



- `decompiled/CardExtensions.c @ CanEquip (0x37ec10, dump.cs:388255)`：目标调用 IsHandCard；来源检查 GetTag(equipment)>0，以及来源类别与目标 equip_slots 的交集。**来源没有必须位于手牌的条件**。

- 独立调用链：`CardDropManager.c @ DropCard (0x4ef4f0)` 对手牌目标先 CardStack 再 CardEquip；`CardController.c @ CardEquip (0x528020, dump.cs:317123)` 对同一个来源调用上述 CanEquip，替换旧装备、AddEquip、RemoveCard(source)。

- 槽位拖动仍受 `RitePanelShowController.Show 0x596450` 的 `!open_adsorb && !rite.start` 门控制。原作槽位来源在 OnBeginDrag 解除关联；克隆暂在成功落下时解除，此时序尚未完成。

- `CardController.CardEquip` 尾部调用 `GameController.ShowCardInfo 0x556c60`。后者检查的 `+0x128` 是 WizardController（dump.cs:319777），不能误认作仪式面板；`+0x118` 才是 RitePanelShowController。原作仪式打开时仍能进入人物详情流程。

- `CardInfoNewController.DropCard 0x533550` 对已打开详情执行 RefreshAllEquips/RefreshAllTags。不能把更新当作点击同一卡而切换关闭。



### 修正



1. 移除 GameScreen 和 attach_equipment(enforce_slot) 中装备来源必须 hand 的自制限制，允许可编辑槽位来源；状态层仍校验运行中/自动吸附槽不可移动。

2. UI 从 CardInstance 的真实 UID/zone/rite_uid/slot_key 检查来源，复用合堆的宿主 pending/committed 阻塞校验，不相信过时 payload 的来源描述。

3. 合堆/装备共用离槽通知：只重载原仪式实例槽位，不重新加入来源卡到手牌。来源装备保留 UID，zone 改 equipped；旧装备正常返回。

4. 成功装备后首次自动打开目标人物详情；同一人物已打开则刷新，避免触发点击切换关闭。



### 验证与证据限度



- card_evolution 13/70、card_stacking 10/56、hand_preview_source 5/24、save_import_bridge 6/82、UI 81/1073：**115 测试/1305 断言通过**。日志前缀 `approximation-slot-equip-`，未发现引擎错误、orphan/泄漏报告。

- 新回归覆盖源槽运行锁、结算 pending 锁、直接状态调用、替换旧装备、新装备离槽/入人物、槽位缓存更新、首次详情打开及重复回调。

- `verify_slot_hand_stack_input.gd -- --equipment` 在1280×720/1920×1080验证真实GUI拖动、sticky、武器替换、来源槽清空、自动详情。截图 `docs/ui_layout/slot_hand_equip_{1280,1920}.png`。

- `verify_card_equipment_input.gd` 同两种分辨率验证手牌装备自动开详情、再拖第二武器到详情替换及UI更新。

- auto_save 样本导入对拍证明本批未破坏现有保存结构验证；它不是原作本操作的运行录像。截图为克隆实机，不作为原机同帧像素一致证据。



### 仍需继续



IsHandCard 本身是三类标签判定，不等于克隆 zone；目标域完整等价尚未恢复。装备类别查找/占位计数的 runtime tag 读取、旧装备回到目标bag及位置、补回手牌标签、配音、RequestUpdateRite、拖起立即离槽/取消回位仍须单独迁移。保留在A05，不将本次通过外推为完整装备链完成。


</details>


<a id="e046"></a>

## 槽卡拖回手牌合堆纠偏（2026-09-10）

证据范围：`docs/replica/loop.md#e046`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 槽卡拖回手牌合堆纠偏（2026-09-10）



属于 ApproximationAudit A05；只修本交互边界，不代表卡牌系统全部完成。



### 原作事实



- `decompiled/CardController.c @ CardStack (RVA 0x5286b0, dump.cs:317120)`：双方配置 id 相等，双方 HasTag(stackable)，目标 count 加来源 count，PlayerExtensions.RemoveCard(source.uid)，销毁来源 Controller，目标回到自身 bag/bagpos。方法没有来源必须手牌的限制。

- 独立调用信号：`CardDropManager.c @ DropCard (0x4ef4f0)` 调用 CardController.CardStack，再尝试 CardEquip；占用槽位目标另走 CardSlotController.CardStack。

- `CardController.c @ OnBeginDrag (0x5294e0)` 的槽位分支解除原槽关联，再进入统一拖动分支。克隆目前在落下成功时才更新槽位，属于尚未消除的时序差异；本次不声称原拖起/撤销全生命周期一致。

- 槽位可移动门沿用 `RitePanelShowController.Show 0x596450` 的 `!open_adsorb && !rite.start`，由共享 rite_slot_access 承载。结算 pending/committed 是克隆宿主阻塞状态，继续通过所在 RiteView 校验。



### 偏差与修正



1. CardWidget 原来拒绝所有 source=slot，导致可拖回手牌却不能放到同 id 卡上合堆。现在允许宿主校验后的槽位来源；槽位作为目标仍委托给槽控制器。

2. GameScreen 落下时从实际 CardInstance 检查来源所在域、仪式 UID、槽位以及运行状态，不信任 payload 声称的来源。重复落下已消费来源不会再次增加数量。

3. 成功合堆后，由原仪式面板重新读取实例槽位并刷新视图；不调用普通 return_card_to_hand，避免重新插入已消费来源。

4. 修正两处错误来源地址：CardSplit 实为 0x528580（不是 CardMoveUp 的 0x528390）；CardDropManager.DropCard 为 0x4ef4f0。



### 验证



- `test_card_stacking.gd`：10 测试/56 断言，新增真实 GameScreen/RiteView/CardWidget 链，覆盖运行中锁定、pending 锁定、消耗后的槽缓存、重复回调。

- `test_hand_preview_source.gd`：5/24；`test_rite_view.gd`：36/172。

- `test_save_import_bridge.gd`：6/82，包含原作 auto_save 样本导入对拍。该样本验证保存结构，**不是原作槽出合堆操作录制**；本动作语义证据来自上述原作方法与独立调用链。

- `verify_slot_hand_stack_input.gd`：1280×720 和 1920×1080 实际 GUI 拖动通过；手牌金币 5+槽位金币 3=8，来源消费，源槽状态和 UI 均清空。截图 `docs/ui_layout/slot_hand_stack_{1280,1920}.png`。

- UI 全组 81/1073，记录于 `approximation-slot-hand-ui.log`。本批合计138测试/1407断言通过，无引擎错误、orphan或泄漏报告；本批各日志前缀 `approximation-slot-`。



### 尚未完成



原作拖起即解除槽位与失败返回的完整时序、完整 active RectTransform 子树、独立 InputManager 选择/手柄持牌、槽位来源装备到人物，以及 A06–A24 的其他审计项仍需继续。不能将本批存档回归或克隆输入通过登记为原机同帧视觉验收。


</details>


<a id="e047"></a>

## A19 第39批：指定槽替换

证据范围：`docs/replica/loop.md#e047`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### A19 第39批：指定槽替换



### 原作与旧偏差



`RitePanelShowController.c @ TryUpdateCard 0x598140` 保存目标索引的 Rite.cards 项，临时设空，以传入卡构造非首放 ConditionContext，调用该索引的 CanPutCard，然后恢复原值并返回结果。独立 `dump.cs:324304` 签名为 TryUpdateCard(int index, Card card)。



`CardDropManager.DropCard 0x4ef4f0` 在 CardStack 返回 false 后调 TryUpdateCard，失败直接拒绝，不寻找另一个空槽。成功进入 `CardSlotController.DropCard 0x53b720`；其首步 `RecoveryCard 0x53c660` 把原 current 通过 PlayerExtensions.AddCard 放回玩家，再清引用。



克隆此前遇到已占槽或不匹配槽会 `_first_satisfied_slot` 自动改投，与上述指定目标路径不符。临时清空仅改UI缓存也不够，条件读取必须看去除目标槽后的快照。



### 改动



- 删除显式拖到槽后的自动改投，先走成本堆叠，剩余路径验证指定目标并替换。

- `_try_update_card` 临时去掉目标槽，检查后恢复。普通槽预检带 use_slot_snapshot，槽号存在性和槽号标签查询使用此快照；结算仍读实时状态。

- 成功后复用既有退回手牌和落槽链。拒绝时原槽与手牌不变。



### 验证



生产投放组10测试/47断言，仪式组36/175通过；包含真实治理家业的贵族角色替换，错误投向金币槽不会自动转投其他槽，临时空目标的正反条件与恢复引用。测试发现一个不存在的2000007夹具，已更换真实2000001，不把无配置对象作为原作验收卡。



扩展 `verify_slot_cost_input.gd`：成本补齐后打开治理家业，把第二个人物实际拖到已占人物槽，检查旧人回手、另一仪式金币不变。1280与1920验证结果见最终日志。



### 保留范围



零成本卡仍未修复；原作特殊标签门、聚合选择器快照全域、自动吸附附加条件、入场缩放/配音仍开放。此次没有原机同帧对拍，不能宣称完整A19或全部清单完成。未修改content、未提交推送。



最终：卡牌堆叠10/56也通过，合计56测试/278断言；1280×720及1920×1080实际GUI拖动PASS。最终五份slot-replacement日志无失败、SCRIPT ERROR、ERROR、Orphans和泄漏，git diff --check通过。未重跑全量；此前两条UI失败和一条无断言风险未在本批修复。


</details>


<a id="e049"></a>

## 初始人物、可见手牌与自动吸附（2026-09-11）

证据范围：`docs/replica/loop.md#e049`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 初始人物、可见手牌与自动吸附（2026-09-11）



**后续状态：** 原始 StreamingAssets/config 已成为运行与校验基准，重复操作/条件/时机完整保留。此前缺失的宫廷与浴场已由真实开局事件恢复，四个开局仪式及奖励手牌按原 auto_save notes 对拍通过。UID统一分配和旧池碰撞兼容见 [RemainingCloneConvergence](verification.md#e033)。



### 根因与本批范围



旧 ConfigDB 用四卡常量替代原作 init/1.json 的 default_cards，误把正式人物初始表

当作测试卡表。另一方面，hand 数组承载的是未占用仪式槽的 Player.cards，UI 和

hand_have 却未执行原作 IsHandCard：直接恢复初始表会把 NPC 全摆成手牌，甚至因为

未归属玩家的受伤 NPC 误生成医院。两层必须同时修正。



本批使用原始配置，创建全部初始条目（按原作规则合并可堆叠重复项），恢复四组初始装备，

按有效归属标签筛选普通手牌。自动吸附仍访问完整未占槽集合，保持人物 UID，

未归属玩家的人物返回该集合后仍不显示；“恢复上次投放”不能取走隐藏 NPC。



复核中还修正了装备继承的旧误读：GetTag 检查的是正在查询的 TagNode.can_inherit，

不是“装备有任一可继承标签就传递整行”。后者会让装备上的own/adherent/player泄漏到

隐藏NPC。GetTags的0x393980谓词独立确认逐标签筛选；递归raw=true仅跳过非正值屏蔽，

仍乘装备自身count，再乘宿主count。标签值、标签名并集和对应旧错误测试一起修正。



### 原作证据



| 边界 | 直接证据 | 独立信号 |

| --- | --- | --- |

| 初始卡牌 | Datapool.InitPlayer 0x413700，原二进制 0x413b65–0x413c24 | dump.cs:390539 default_cards@0x58；init/1.json |

| 重复条目 | 0x413b8a HasTag(stackable)，0x413b9c GetCardById，0x413bb1 count+1，否则0x413bd0 AddCard(false,false) | stringliteral 0x2593720=stackable；重复条目配置及卡片标签 |

| 初始装备 | Datapool.c 初始装备循环：0x413d53 AddCard(true,false)，0x413d69 AddEquip | dump.cs:390541 card_equips@0x60；auto_save 的嵌套装备 |

| 普通手牌 | CardExtensions.IsHandCard 0x3827c0，三个 GetTag>0 的 OR；二进制0x382802–0x382866复核 | dump.cs:388147；stringliteral 0x2580360=own / 0x258AC48=adherent / 0x25828F8=player；tag.json |

| 取手牌 | PlayerExtensions.GetHandCards 0x38d430，谓词0x3938f0调用IsHandCard | RitePanelController.OnLastState 0x58fdf0 调用 GetHandCards |

| 手牌条件 | HandHaveCardCount.IsSatisfied 0x3fd4f0枚举Player.cards再调用IsHandCard | 事件5300073使用hand_have.受伤/生病触发医院 |

| 桌面条件 | TableHaveCardCount.IsSatisfied 0x409b10只枚举Player.cards，无仪式遍历 | HaveCardCount 0x3fed80另行枚举Player.cards及每个Rite.cards |

| 分页位置 | GameController.UpdateHandCardPos 0x559a70过滤IsCurrentHandCard | IsCurrentHandCard 0x3826a0明确先比较BagIndex；原存档NPC bagpos=0 |

| 老板吸附 | RiteExtensions.AdsorbCards 0x38fca0读取Player.cards；InitRite 0x38e140创建时调用 | rite/5002006 s5强制吸附2000199；auto_save已有书店实例 |



注意：InitPlayer 的 `.c` 在 default_cards 循环中漏掉成功分支，看起来像无条件 LogError。

不能据此断言原作不创建卡片。本批只读原始 GameAssembly.dll，反汇编确认成功路径和堆叠分支，

未修改语料。初始装备的 no_add=true 不执行 MarkCardGen，不能用“先加入手牌再装备”替代。



### 验收边界



- tests/test_startup_card_population.gd：初始顺序/堆叠、隐藏老板吸附与返回、三类归属标签、

  跨页hand_have、table_have与have范围、原存档手牌筛选、初始装备、存读档和实际UI组件。

- tests/test_startup_rites.gd：真实开场选项链、首日书店、医院误触发反例、第二/三日家业后继、

  存读档保留合法重复仪式。

- 保留现有活动苏丹卡的独立手牌带呈现；原样本普通牌4张、活动苏丹牌1张。

  **三标签方法本身不包含苏丹卡特例。** 苏丹牌呈现与原版运行时重建之间的完整接线

  不在本批验收范围，不将保留的宿主路径冒充为IsHandCard原逻辑。



### 未完成



本批开场路径能自然生成家业、书店，仍未得到原存档中的宫廷5001001、浴场5001501。

它们不能凭“样本有”就变成默认常量；首次创建入口仍待对照原作启动/剧情链查清。

苏丹池与普通卡使用独立UID分配器，尚不能宣称新局UID和原作逐项相同。

本批不迁移旧局缺失人物，不删除旧局重复仪式，不修改content，不覆盖用户存档。



### 验证记录



日志在 `C:/Users/User/Documents/GitHub/Faust-artifacts/Faust-cleanup-20260911/`。



- `population-full-fixed.log`：全量64脚本、730测试，710通过、20失败。

  旧夹具仍把人物集合当成可见手牌、依赖四卡开局，旧table_have断言也错误包含仪式槽；

  其中手牌预览触发越界。逐项修复夹具/错误预期，而非恢复生产常量。

- 最终 `population-final-*.log`：17套件、307测试、2956断言全部通过，

  覆盖所有失败套件及新增的标签继承、原存档对照、装备、复制、槽位属性与投放边界。

  标签域补测还纠正了旧“独立重算”脚本里的同一整行继承误读；它独立读取存档与配置，

  不调用克隆标签助手，但旧解释仍可能错，因此始终必须回到.c原方法。

- 最终17份日志无SCRIPT ERROR、ERROR、失败断言、孤儿节点或资源泄漏诊断。

  这是全量发现后的相关套件复跑，**不称为一次新的全量全绿运行**。

- `population-slot-input.log`：1920×1080、Vulkan实际窗口输入PASS，

  家业/浴场悬停、点击、手牌投放、拖出、回手和运行锁沿共用入口验证。

  此工具显式建立仪式夹具，不能证明浴场首次生成已正确。

- `population-parity.log`：3889文件逐字节一致，零违规；git diff --check通过。

- 最终严格开场路径打印 `[5000001, 5002006]`，不再误生成医院，跨第2/3日保持单份家业后继。



未提交或推送；保留前批未提交改动与用户旧存档。


</details>


<a id="e050"></a>

## 开局仪式重复：空配置被自制默认值覆盖

证据范围：`docs/replica/loop.md#e050`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 开局仪式重复：空配置被自制默认值覆盖



**后续修正（2026-09-11）：本文以下记录早期批次。** 原始 JSONC 的重复操作曾被 data/config 导出丢弃；现已获用户授权换用 StreamingAssets 原文件。5300066 的真实顺序为宫廷5001001 → 浴场5001501 → event_on5300029（生成书店5002006）→ 家业5000001。真实新游戏操作及原 auto_save notes 已验证四个仪式、奖励卡与出现顺序。初始人物表也已恢复。下文“未完成：初期地图”不再代表当前状态，最新证据见 [RemainingCloneConvergence](verification.md#e033)。



### 已确认的根因



`ConfigDB.get_default_rites()` 原先在 `init_config.default_rite` 为空时使用

`NORMAL_DEFAULT_RITES`，然后按 loot/card 生成来源过滤。这个分支没有原作背书。

过滤也不能把一张“看起来合理”的初期地图变成原作的事件生成链。



- `Datapool.c InitPlayer 0x413700` L4442–4465：逐项遍历 InitNode@0x68，调用 InitRite。

- `dump.cs:390543`：InitNode.default_rite 的 backing field 正是 @0x68。

- 原作与克隆 `init/1.json` 的 `default_rite` 都是 `[]`：空数组不生成仪式。

- `event/5300066.json`：开场剧情 action.rite=5000001，随后启用书店事件5300029。

- `rite/5000001.json`：选中的家业结算 action 创建后继5000001。

- 本批只读检查的本地 save.json 含两个5000001，UID12/13，均在round3运行。

  notes中上一轮UID8/10各生成一份后继，说明问题已经进入实例状态，不只是地图绘制。



因此，提前生成的假家业与剧情生成的真家业会进入两条后继链。

不能用全局按名称/配置ID去重修复：原作InitRite允许同ID的独立实例。



### 修正



删除自制仪式常量及过滤函数。`get_default_rites()` 只返回原配置数组的副本，

保留顺序与重复项；`setup_new_run()` 继续按配置创建实例。

加载已有存档仍读取其持久化实例，不迁移、不删除用户进度。



此前将家业“默认存在”写进测试的夹具，现在显式创建它们需要操作的实例。

这不是放松生产逻辑断言：另有专门开局回归验证真实事件生成。



### 开场与跨日回归



`tests/test_startup_rites.gd` 从setup_new_run(false)开始，触发第1回合

round_begin_ba并执行启动期苏丹抽取。明确选择哈桑、商人家族、言辞、保守、

英武妻子、接受游戏；执行实际OperationsSequence续接，不丢弃选项队列。

随后走RoundLoop至第2、3回合，验证家业始终只有一个，旧UID消失且存读档不新增。

另一反例验证两份显式创建的同ID实例在存读档后仍是两份。



检查测试时发现旧跨日辅助代码读取顶层choices，但真实选择位于payload.choices；

它会错误地直接消费选项。本专项使用严格选择处理器，遇到未知选择即失败。

全仓库旧测试辅助代码的同类普查尚未在本批完成。



### 未完成：初期地图的其他仪式



本批真实开场路径打印的first_day仪式ID为 `[5000001]`。

原作 `save_samples/auto_save.json` 包含家业、权力的游戏、浴场里的消息、书店营业，

是进一步差分的证据入口；两者尚未达到同状态地图一致。



已定位另一自制入口：ConfigDB.NORMAL_DEFAULT_CARDS仅四张，

原作InitNode.default_cards有168项，包含苏丹2000024和书店老板2000199。

`Datapool.InitPlayer` @InitNode+0x58 逐项AddCard；dump.cs确认该字段是default_cards。

书店5002006的s5必须在创建时吸附2000199，因此缺少此人物会导致生成失败。

“168项都是可见手牌”没有证据，不可直接把168张图摆在手牌区；下一批必须一起核对

原作Player.cards、IsHandCard/手牌展示过滤、装备初始化和事件生成的完整边界。



**本批仅消除自制开局仪式的重复来源，不宣称第一天/第二天完整还原。**



### 验证记录



日志置于 `C:/Users/User/Documents/GitHub/Faust-artifacts/Faust-cleanup-20260911/`。



- `startup-full.log`：全量62脚本/722测试，首次714通过、6失败、2无断言中断。

  失败/中断均定位为依赖自制开局仪式的旧夹具；未把这个结果写成全量全绿。

- 修正夹具后复跑 `startup-final-test_{data_db,hand_pages,integration,

  rite_input_contract,rite_view,save_system,sudan}.log`，115测试/1134断言全过。

- 新增真实开场/跨日/存读档反例 `startup-rites.log`，2测试/11断言全过。

- 最终上述专项日志无ERROR、SCRIPT ERROR、孤儿节点、资源泄漏。

  未受影响的套件采用首次全量结果，未再次全量运行。

- `startup-slot-input.log`：1920×1080真实viewport输入PASS，家业/浴场投放、

  拖出、无效落点、跨槽及运行锁均通过；该工具显式建立仪式夹具，不替代开场链验收。

- 本批未修改content；本会话逐字节配置核验3889文件/0违规。

  原作存档导入桥在全量测试中通过，开局差异与尚未恢复的初始卡牌域仍如上明确保留。

- `git diff --check`通过。未提交、未推送；保留前序未提交工作与用户存档。


</details>


<a id="e060"></a>

## 审计报告八：仪式结算管线余项（2026-08-15）

证据范围：`docs/replica/loop.md#e060`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 审计报告八：仪式结算管线余项（2026-08-15）



> 范围：结算执行体、槽位满足判定、骰子重掷、auto_result / auto_begin、

> 拖放路由、结算收尾顺序、StartRite 细节（为报告一 A1 修复提供依据）。

> 已被前七份报告立案的 DSL 键语义、事件时机、苏丹循环、N 天仪式不结算

> 本体（报告一 A1）不重复。

>

> 方法：反编译 `RiteExtensions.c` / `RitePanelController.c` /

> `RiteResultDiceCountPromptController.c` / `RiteResultPanelController.c` /

> `GameController.c` 指定函数 / `StartRite.c` / `OperationsExtensions.c` /

> dump.cs 字段布局，对照克隆 `sim/rite_resolver.gd`、`sim/round_loop.gd`、

> `sim/game_state.gd`、`ui/rite_view.gd`、`ui/game.gd`。



### A. 发现清单（按严重度）



### A1【High】槽位放置判定忽略已放置的其他卡



- **克隆证据**：`ui\rite_view.gd:718-728`——`_slot_accepts_card` 构造的 ctx 中 `"rite_state": {}`，永远为空。

- **原作证据**：`RiteExtensions.c @ GetSatisfiedSlotIndex (RVA 0x392ac0)` 行 2038-2040——`ConditionContext___ctor(ctx, rite, 0, 0, card, ...)` 携带 rite 当前 `cards`（已放入的卡参与槽位条件求值）。

- **正确行为**：槽位 condition 求值时应能看到本仪式其他槽已放置的卡（如 `s1.xxx` 引用类条件）。



### A2【High，为报告一 A1 修复依据】玩家 UI 确认仪式从不置 start / start_round / start_life，且无撤回



- **克隆证据**：`start_rite_instance`（`sim\game_state.gd:906-915`）仅被 `sim\round_loop.gd:225`（auto_begin 路径）调用；`ui\game.gd` 与 `ui\rite_view.gd` 全程无调用。

- **原作证据**：`RitePanelController.c` 行 1203-1239（OnConfirm 链）——先 `CheckConfirm`（槽位校验），再 `Rite__set_start(1)`、`set_start_round(player.round @player+0x2c)`、`set_start_life(rite.life @rite+0x2c)`，随后逐非吸附槽绑定 key-card；`OnStop (RVA 0x5906e0)` 行 1442-1462——`set_start(0)`、`set_life(start_life @+0x28)`、`new_born=false` 后重新 Show。

- **正确行为**：按下"开始"= 校验后置 start 并记录 start_round/start_life；开始后可停止撤回，life 回滚到 start_life（卡保留）。克隆 `start_rite_instance` 本身语义正确，但 UI 链从未调用，0 天仪式的实例元数据（start_round 等）始终缺失。



### A3【Medium】骰子重掷（重跑）路径完全缺失



- **克隆证据**：`ui\rite_view.gd` 仅有金骰（`_use_gold_dice_reactive`），无任何 reroll 接口。

- **原作证据**：`RiteResultDiceCountPromptController.c @ OnRedraw (0x59dc40)` 行 597-627（扣 `+0xd8` 重掷次数、置 confirm/cancel）与 `@ OnRedrawConfirm (0x59db60)` 行 647-680——`RSG_Promise__Reject(promise, RetryException)` 触发整场重掷；`RiteExtensions.c @ GetRerollCount (0x392990)`，且结算面板初始化时读入（`RiteResultPanelController.c:354`，存 `+0x160`）。

- **正确行为**：每个仪式按配置有重掷次数，确认后以 RetryException 拒绝 promise、重新掷骰（区别于金骰的"加成功"）。



### A4【Medium】`auto_result` 仪式在 UI 路径未跳过交互



- **克隆证据**：`ui\rite_view.gd` `_resolve/_do_resolve/_commit_resolution` 无 `auto_result` 检查。

- **原作证据**：`GameController.c @ Settlement (0x556ae0)` 行 4520-4526——玩家 `+0x130` HashSet 含该 rite uid（`PlayerExtensions.IsRiteAutoResult`，`RiteResultPanelController.c:442-446`）时传入 flag；`RiteResultPanelController.c` 行 640-644——`SetActive(gameObject, flag=='\0')`，即 auto_result 结算不显示面板/自动推进。

- **正确行为**：auto_result 仪式结算应跳过玩家确认（克隆 headless 路径已如此，注释见 `round_loop.gd:232-233`；UI 路径应一致）。



### A5【Low】拖放必须精确命中槽位；原作自动路由到首个满足槽



- **克隆证据**：`rite_view.gd:370-395` `can_drop_card_on_slot/drop_card_on_slot` 只校验被丢的槽。

- **原作证据**：`GetSatisfiedSlotIndex (0x392ac0)` 返回第一个"无卡且 CanPutCard 通过"的槽索引（跳过 `open_adsorb` 槽，行 2037/2034-2040）；`GameController.c @ DragCard (0x54ef50)` 行 4586 调 `ShowSatisfiedSlot` 高亮。

- **正确行为**：拖卡到仪式面板时自动匹配首个可放槽并高亮，不要求玩家点准槽位。



### A6【Low】headless 结算中 deferred 效果应用于返卡/移除之后



- **克隆证据**：`sim\round_loop.gd:262-265`——`finalize_rite_settlement`（返卡+移除实例）→ `DeferredEffects.apply` → `rite_end`。

- **原作证据**：全部 ops（含事件/prompt 入队）在 promise 链内先执行，`PlayerExtensions__RemoveRite` 在链尾闭包（`RiteResultPanelController.__c__DisplayClass56_0.c:880`，按 `rite.uid` 移除）。

- **正确行为**：结算产生的事件/prompt 应在仪式卡返还与实例移除之前入队/触发，保证事件条件看到的局面一致。（影响面小：immediate 效果在 resolve 阶段已先行。）



### A7【Low】auto_begin 启动额外要求 open_condition 仍成立



- **克隆证据**：`sim\round_loop.gd:223` `start_auto_begin_rites` 要求 `RiteOpen.is_rite_open`。

- **原作证据**：`GameController.c @ DoStartAutoBeginRite (0x54ebc0)` 行 5344-5349——仅检查 `start==false` 且 `data.auto_begin(+0x48)`，无 open_condition 复查。

- **正确行为**：auto_begin 对已生成实例无条件启动；开放条件在生成时（DSL 门）把控。



### A8【Info】金骰在检定已成功时也可投入



- **克隆证据**：`rite_view.gd:561-569` `_update_gold_button` 只看 `gold_dice>0 && pending`。

- **原作证据**：骰数提示由结算链内的失败检定 op 呼出（`RiteResultPanelController.c @ ShowDiceCountPrompt 0x5a5760` / `ShowDicePrompt 0x5a5910`）。成功时无提示入口（"仅失败时提示"这一点归 C-7 部分验证，故仅记 Info）。



### B. 已验证正确



1. **生命周期主干**：`round_loop.gd:235-266` 与 `GameController.c @ UpdateSingleRite (0x55ab10)` 行 5857-5883 一致——先 `life+1`；未 start 且 `waiting_round>=1 && life>=waiting_round` 走 Dead；未 start 且 `waiting_round<1` 永久跳过（原作行 5861 同语义）；已 start 且 `life>=round_number` 才 Settlement。

2. **超时链顺序**：`rite_clean` 事件 → `waiting_round_end_action` → 返卡 → 移除（`round_loop.gd:250-254`）与 `RiteExtensions.c @ Dead (0x501460)` 行 48-63（OnRiteClean 最先）一致。

3. **三分支互斥/叠加**：`sim\rite_resolver.gd:41-63` prior 首匹配即断、normal 首匹配即断、extre 全匹配且"全部 result 先执行、全部 action 后执行"——extre 两阶段与 `OperationsExtensions.c @ Start (0x500dc0)` 行 50-90 的两遍收集（先 `+0x30` 非空回调、后 `+0x38` 非空回调，再 DoSequence 顺序执行）结构一致。

4. **auto_begin 只 start 不结算**：`round_loop.gd:210-227` 与 `DoStartAutoBeginRite` 行 5349（仅 `Rite__set_start(1)`）一致；auto_result 仅表现层（`round_loop.gd:232-233` 注释与原作 `GameController.c:4520-4526` 事实相符，除 A4 的 UI 缺口）。

5. **金骰主流程**：加 N → 确认 = `Reject(GoldDiceException(N))`（`RiteResultDiceCountPromptController.c @ OnGoldConfirm 0x59d8b0` 行 539-567）→ 整场回滚重解，骰面缓存复用、金骰加在成功数上——克隆 `_resolve_baseline` 回滚 + `_resolve_dice_cache` + `condition.gd:256-280`（`successes + gold` 对 `x` 比较）核心等价；取消返还待定金骰（`OnGoldCancel 0x59d6f0` 行 483-487）与克隆关闭回滚一致。

6. **按检定类型作用域金骰**：`condition.gd:261-263` 的 `gold_dice_map[type_key]` 对应原作 `goldDiceCounts[type]`。

7. **RiteInstance 字段与初值**：start/start_round/start_life/life 默认 0（`sim\rite_instance.gd:14-17`）对应 `Rite` ctor 默认（dump.cs:392391-392412）。

8. **start_rite_instance 语义**（仅 auto_begin 使用，见 A2）：`game_state.gd:906-915` 的 `start_round=round_number / start_life=life` 精确复刻 `RitePanelController.c:1228-1239`。

9. **实例生成与吸附**：`game_state.gd:750-805` 复刻 `PlayerExtensions.c @ InitRite (0x38e140)` 行 753-786——uid 计数递增、`once_new`→new_born、先 AdsorbCards 失败则 RebackCards+uid 回退+中止创建、成功才入列表。

10. **收尾归属**：`finalize_rite_settlement`（`round_loop.gd:296-326`）——clean 指令消费（含苏丹卡）、非 clean 返还（苏丹卡回 sudan 区、其余回手牌）、按 uid 移除实例且同配置多实例独立——对应 `PlayerExtensions__RemoveRite(player, rite.uid)`（DisplayClass56_0.c:880）与 `RiteExtensions.c @ ReturnCards (0x5016d0)`。

11. **rite_start/rite_end 触发点**：打开面板触发 `rite_start`（`ui\game.gd:222`，对应 `StartRite.c @ Do` 行 128-135 `NoteRiteStart`）；提交后触发 `rite_end`（`ui\game.gd:496`，对应面板链内 OnRiteEnd）。

12. **StartRite.Do 失败路径**：配置缺失 LogError+失败、InitRite 失败 LogWarning+`SetLastOpState(0)`（`StartRite.c` 行 76-114）——不抛异常、链继续，克隆 `result.gd` 的 `rite` 键失败返回 0 同义（DSL 细节归报告一）。



### C. 无法验证与原因



1. **金骰扣费计数器 7100006**：`grep 7100006` 在 decompiled 全目录无命中；`PlayerExtensions__GetGoldDiceCount` 被调用（`RiteResultDiceCountPromptController.c:84`）但其扣费写点与计数器 id 需通读 PlayerExtensions.c/counter 表才能定位。预算内未做。

2. **OperationsExtensions.Start 中 `op+0x30`/`op+0x38` 的确切字段语义**：偏移与 `RiteNode.Settlement.result(+0x30)/action(+0x38)`（dump.cs:392606-392608）及 `OperationContext._preResult(+0x30)/_preExtraResult(+0x38)`（dump.cs:394482-394483）均吻合，但无法从局部反编译确定是哪一个（需遍历 Operations 子类字段表）。

3. **ThinkController.OnDrop → IThink 的后续运行时链**：`DoIThink (0x54e880)` 已确认是"程序化把选中卡丢到思考桌"（行 10225-10246 构造 PointerEventData 调 `ThinkController__OnDrop`），但 ThinkController.c 未读，克隆 `sim\methinks.gd` 的"直接 resolve think 仪式 s1"与原作服务端链的等价性未证。

4. **一槽多张卡（多卡槽）**：原作 `Rite.cards` 为按槽索引对齐的 `List<Card>`，`GetSatisfiedSlotIndex` 逐索引找空位——所见证据均为一槽一卡；克隆 `cards_in_slot(...)[0]`（`rite_view.gd:96-98`、`round_loop.gd:274-276`）与此一致，但"等价卡/卡组 any-of 匹配"在 CanPutCard(0x3918b0) 内部，未读（condition 语义归报告一/五，不重证）。

5. **面板闭包链中 OnRiteEnd 与 RemoveRite 的相对顺序**：`Settlement` 的 10 层 promise 闭包（a6f0..abc0）未逐一映射到 DisplayClass 方法名；克隆"record_ended→返卡→移除→deferred→rite_end"的顺序（A6）只能部分对证。

6. **GetRerollCount 数据来源**：仅读函数头 12 行（0x392990），重掷次数来自配置还是玩家计数器未确认——不影响 A3 的立案（重掷路径存在本身已由 OnRedraw/RetryException 双信号确认）。

7. **骰数提示"仅失败时呼出"**：`ShowDiceCountPrompt/ShowDicePrompt` 的调用者（结算链内 op）未定位，A8 保持 Info 级。



### 附：给报告一 A1 的直接依据（StartRite 六问答案）



`StartRite$$Do (0x51bcf0)` 是**创建仪式实例的 DSL 操作**，不是开始按钮——GetRiteData→InitRite（含吸附，失败则中止创建）→AddRite→`new_born` 时 NoteRiteStart；**不置 start、不校验槽满、不设 waiting_round/life（均保持 0）**。玩家的"开始"在 `RitePanelController` OnConfirm（CheckConfirm→set_start→start_round=player.round→start_life=life，行 1203-1239），且可通过 `OnStop (0x5906e0)` 撤回（start=false、life 回滚 start_life、卡留槽）。


</details>


<a id="e114"></a>

## 治理家业页面续修验收

证据范围：`docs/replica/loop.md#e114`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 治理家业页面续修验收



2026-09-08，承接任务 `01a07f29-9e79-7953-b111-e8b5628acbaa`。本记录区分已落地修改与仍未完成的视觉对拍。



### 已落地



- 建筑使用精灵原生尺寸，Position 只应用一次 bg_pos；slot_open 映射到模板卡槽；恢复建筑前景和原精灵网格，避免图集边缘显示。

- 右侧恢复标题、回合、tips_text、属性列及底部操作图片；仪式覆盖声望栏，手牌在仅打开仪式时仍可交互。

- 接手复查发现此前全绿日志仍有 7 次 `<null>.png` 加载错误。本次将 JSON null 与空字符串共同按背景回退处理，并在动态七槽测试中检查纹理实际加载。



### 证据入口



- `RitePanelShowController.c Show 0x596450`，尤其 L848–866 的 IsNullOrEmpty 双层回退；dump.cs 的 RitePanelShowController 类及 RitePanelShow/RitePanelTitle/CardSlot prefab。

- `RitePanelTitleController.Show 0x5992a0`、`CardSlotController.Init 0x53b940`；原配置映射 8001002 → 8000003。

- 用户提供的原作截图与[当前运行截图](../ui_layout/rite_page_corrected.png)直接对照。两者是不同回合、不同手牌状态，不作为同刻状态对拍。



### 验证与未决项



- 前会话完整 GUT 日志：469/469、3443 断言通过，但有上述 7 次资源错误，不能称为无错误验收。

- 本次先复跑仪式组 24/24、72 断言通过；加入纹理断言后的最终结果见 `rite-handoff-check.log`。

- 建筑主体及卡槽位置已接近参考图。正文的字体、大小及换行仍明显不同；顶部自动吸附标记、回合数字样式和底部额外按钮也仍需逐项核对。

- 未完成同状态原作对拍，不标记为完全复刻。本次未修改 content 或游戏状态逻辑。


</details>


<a id="e115"></a>

## RitePanelShow — 原作布局真值与克隆映射

证据范围：`docs/replica/loop.md#e115`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### RitePanelShow — 原作布局真值与克隆映射



### 证据



- 原作 prefab：`unity_export/ExportedProject/Assets/Resources/prefab/RitePanelShow.prefab`。

- 原作控制器：`engine_spec/decompiled/RitePanelShowController.c`，`Show`（RVA `0x596450`）创建 `CardSlot`，并写入模板背景、标题和每槽的 `localPosition`、`localScale`、`localRotation`。

- 结构签名：`dump.cs` `RitePanelShowController`（`ModelBG`、`SlotsContainer`、`slots`）及 `RiteTemplateNode` / `SlotPosition`。

- 内容真源：`content/rite_template_mappings.json` 与 `content/rite_template/*.json`；不建立克隆侧模板表。



### 固定 prefab 几何（3840×2160 CanvasScaler 设计空间）



| 原作节点 | 直接几何/规则 | 克隆节点 |

| --- | --- | --- |

| `RitePanelShow` | 3692×2132，中心锚点 | `RitePanelShow` 源画布 3840×2160 中的原作承载层 |

| `Position` | 中心 `(0, 210)`，Unity y-up | `SOURCE_POSITION_CENTER=(1920,870)` |

| `Position/bg` | 4096×2148，中心锚点 | `RiteTemplateBackground`，以模板 `bg_pos` 移动 |

| `SlotsContainer` | 3692×2132 | 只承载原作 `CardSlot` 坐标 |

| `CardSlot` | 272×496，pivot `(0.5,0.5)` | `OverlaySlot_Sn` |

| `RitePanelTitle/CommonContent` | 1148×1124，`common_operation_bg` | `RiteOverlayPanel` |



### 模板位置公式



对每个原作 `rite_template` 槽：控制器以 `SlotsContainer` 左下原点的 `pos`，减去容器半尺寸后写到实例的中心局部坐标。因此在 Godot 的 y-down 设计画布中：



`center = (1920, 870) + (pos.x - 1846, 1066 - pos.y)`



`scale` 与 `rotation_z` 同样直接读取该模板。禁止回退为按槽数生成的网格，也禁止为了避开手牌而二次挪动槽位。



### 验收



`tests/test_ui_layout.gd::test_rite_view_replays_source_canvas_geometry` 对原作开局仪式 `5000001 → mapping 8001002 → template 8000003` 验证背景、标题与 `s1` 的精确矩形；另验证实际打开路径进入 `SourceOverlayLayer`，不经过旧 1280×800 `OverlayLayer`。


</details>


<a id="e118"></a>

## 全仪式模板布局普查与修正

证据范围：`docs/replica/loop.md#e118`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 全仪式模板布局普查与修正



2026-09-08。范围是治理家业同类的 `RitePanelShow` 仪式投卡页面。所有修正进入 `ui/rite_view.gd` 共用路径，没有按治理家业 ID 分支。



### 覆盖范围



| 对象 | 数量 | 本次验证 |

| --- | ---: | --- |

| rite 配置 | 1495 | 逐个解析有效映射及实际卡槽，全部可解析 |

| 映射配置 | 453 | 作为统一模板解析入口 |

| 模板 | 251 | 全部检查；247 个有映射的模板构建页面并 GPU 渲染 |

| 未被映射引用的模板 | 4 | 8000010、8000060、8000067、8000232，仅检查资源，不虚构入口 |

| 背景 / 前景 | 65 / 43 | 全部导出原纹理和 Sprite 三角网格 |

| 卡槽图片 | 10 | 全部覆盖，按各自图片尺寸绘制 |



### 修正的共用规则



1. 之前只有 zz_01_fg，另外 42 种前景缺失；原来的网格导出工具也写死 zz_01 和 3348×1420。现在从全部模板引用集合导出，读取每张纹理实际尺寸和原 Sprite 顶点流，校验流布局、三角形索引和 UV 范围。118 张纹理与对应原资产 SHA256 相同。

2. 卡槽保留 272×496 原根尺寸，scale 作用于整棵卡槽节点，rotation 绕中心 (136,248)；之前只是缩小按钮矩形，子图形没有同步缩放，旋转还绕左上角。

3. 前景独立读取本身的尺寸。`fg_in_slot_index=0` 放在卡槽层之上；非零值插入卡槽兄弟列表，8000207 的值 2 已覆盖。

4. 模板 `title_bg_hide`、`title_help_btn_hide` 控制共用说明底板和帮助入口，特殊终局模板不再强加通用底板。卡槽背景空值回退和隐藏元数据集中保留。

5. 配置 5000332、5006745 的槽数超过各自 slot_open 长度。原作不是补写卡槽，而是重新取 mapping 0。现在背景、说明和卡槽共用 `_resolved_mapping`，不会出现一部分默认、一部分仍用原映射的混搭。



### 直接证据



- `RitePanelShowController.c Show (0x596450)` L380–438：缺失映射及映射长度不足，取 mapping 0；L688–719：BG/FG 加载及 SetNativeSize；L725–742：说明底板和帮助隐藏；L810–893：slot_open、居中位置、背景、scale、rotation；L930–966：前景父级与 sibling index。

- `dump.cs` RiteTemplateNode (393570 起)：fg_in_slot_index@0x38、title_bg_hide@0x58、title_help_btn_hide@0x59；SlotPosition (393454 起)：背景隐藏、位置、scale、rotation_z。

- 独立信号：未经修改的 `content/rite_template/*.json`、`rite_template_mappings.json`、CardSlot.prefab 根几何，以及原 Sprite.asset 顶点与 uvTransform。251 个模板中的 1900 个 slot 定义，含多种缩放与非零旋转。



### 验证



- 全量 GUT：471/471，3454 断言，262.670 秒；`rite-all-full.log` 无 ERROR / SCRIPT ERROR / orphan / 资源泄漏。

- UI 单组：76/76，889 断言。

- 新增全配置映射、全模板渲染分支两项遍历测试。注意 251 个模板检查包含 4 个无映射模板的资源检查，不表示它们拥有游戏入口。

- GPU：247 张 960×540 页面截图，日志 `rite-template-capture.log` 无引擎错误。7 张概览已逐张查看，覆盖旋转、多槽、前景及特殊终局模板。

- content parity：3881 文件，0 违规；未修改原作内容或本轮游戏状态逻辑。



### 截图入口



[1](../ui_layout/rite_templates/overview-1.jpg) · [2](../ui_layout/rite_templates/overview-2.jpg) · [3](../ui_layout/rite_templates/overview-3.jpg) · [4](../ui_layout/rite_templates/overview-4.jpg) · [5](../ui_layout/rite_templates/overview-5.jpg) · [6](../ui_layout/rite_templates/overview-6.jpg) · [7](../ui_layout/rite_templates/overview-7.jpg)



[模板与代表仪式清单](../ui_layout/rite_templates/manifest.json)。单页文件名为模板 ID，例如 [治理家业](../ui_layout/rite_templates/8000003.png)、[旋转卡槽](../ui_layout/rite_templates/8000031.png)、[非零前景层级](../ui_layout/rite_templates/8000207.png)、[隐藏底板的终局模板](../ui_layout/rite_templates/8000553.png)。



复验工具：`tools/export_rite_sprite_mesh.py`、`tests/test_rite_template_coverage.gd`、`tools/capture_rite_templates.gd`、`tools/build_rite_template_sheets.py`。截图使用直接挂载共用页面的独立测试场景，不修改存档或把未开放仪式塞进玩家地图。



### 尚不能据此宣称的内容



本次完成模板资源与布局分支的全量检查，不等于 1495 个仪式均已在真实剧情中逐局验收。截图采用空槽、代表配置，缺少原作同状态截图集；人物变量替换、字体/行距、吸附/手柄提示、各阶段说明与结算交互仍有既有缺口。事件选择浮层和其他菜单是不同控制器，不属于这次仪式模板普查。


</details>


<a id="e119"></a>

## 仪式槽与俺寻思交互修复（2026-09-11）

证据范围：`docs/replica/loop.md#e119`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### 仪式槽与俺寻思交互修复（2026-09-11）



### 已确认与修正



- `CardSlotController.Init 0x53b940 / ShowTips 0x53cce0`：Slot.text 进入

  TipsHolder literal 字段，不是第二种提示面板。使用共享 TipsView，去掉默认 tooltip。

- `CardSlot.prefab` Highlight 状态组件只在 Highlighted 激活；精灵 GUID

  `4b17a277b119abb4ab3c783885530d47` 对应 card_outline。矩形 256×512，槽内 (8,11)。

- `ThinkController.OnPointerEnter 0x5c3330 / OnPointerExit 0x5c3440` 与

  `IThink.controller`：拖入 Hover 对应 Open，离开 Close，Idle/Thinking 为原作精灵动画。

  本地播放器直接读取原始 .anim 的帧键/时间/循环，不再使用自制旋转缩放动画。

- 59 个原始动画、控制器、Sprite 描述和图片逐文件 SHA256 与语料一致。

- 后续根因批次删除同步兼容桥。SlotPop 提示 → ThinkOver 2 秒锁卡 → 共享

  RiteSettlement：全部 result → 卡归还 → 全部 action → 实例移除。创建阅读仪式

  的 action 在卡归还后执行，open_adsorb 因此能找到书牌。可暂停、保存并恢复。

- 提示框支持未挂树时的布局计算，避免批量模板测试空引用。



### 输入验证



`tools/verify_rite_think_input.gd` 启动完整桌面，通过 viewport 鼠标按下、移动、抬起：



1. Idle 在 0.2 秒后更换原始精灵帧。

2. 拖入 2000472：进入 Thinking，产生提示；处理提示后创建 5000113。

3. 书牌归属新仪式，不在手牌中重复出现；动画回到 Idle，可接受下一张牌。

4. 打开治理家业，悬停 s1：显示原配置提示与高亮；移开隐藏。



最终输入验证 PASS。截图：`think_idle.png`、`rite_slot_hover.png`。

专项 GUT：rite_view 36/36、source_tips 8/8、dsl_batch1 43/43、ui_layout 81/81，

合计 168 测试通过；最终专项日志无 SCRIPT ERROR/ERROR、孤儿或泄漏记录。

测试日志位于仓库外 `C:/Users/User/Documents/GitHub/Faust-artifacts/Faust-cleanup-20260911/`。



### 尚未完成



- `ProcessPop 0x5c38b0` 的 +0xB0 是 RiteNode.cards_slot；其闭包字段为

  SlotPop（dump.cs:327529），不是 settlement 或 settlement_prior。

  旧 Methinks 注释把它当作多条 settlement 的依据是错误的，不能继续引用为事实。

- ThinkOver 的 2 秒锁卡边界、WaitingProcessDone/Close/Idle 状态转换已接；

  effect/Folder 曲线、解锁卡牌的移动演出、音效仍未完整移植。

- ithink_card_uid 与 think_session 已进入克隆存读档；原作 ithink_card 的导入映射仍待补。

- 最新输入复验 `rite-think-input-final.log` 为 PASS，明确断言锁卡前不生成阅读仪式，

  完成后书牌只有一个仪式所有者。它验证 Godot 输入链，不能替代原作实机对拍。

- 仪式浮层打开时仍按现有模态边界阻止向底层俺寻思投卡，该边界未做原作实机对照。

- 精灵裁剪/pivot、TMP 文本、填槽时高亮与拖入闪烁，以及原作实机像素对拍尚未验收。

- 本轮中间版本全量 GUT 692：687 通过、4 失败、1 risky；其中新增动画状态对应旧

  断言已更新，其他三项为已知 card_flash / event_prompt / book_search 失败。

  中间版本提示框空引用已修复，专项日志重新扫描，不能将该全量结果称为全绿。


</details>
