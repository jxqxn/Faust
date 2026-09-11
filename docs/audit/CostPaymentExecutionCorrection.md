# A19 付款执行体：`CardSlotController.CardStack`（第三十六批）

> **2026-09-11 接手复核：本批只落地辅助函数，尚未接入游戏，不能标作 A19 已完成。**
> `ui/rite_view.gd::_place_card_in_slot` 仍直接调用 `add_card_to_slot`；下文“三分支”只覆盖 `CardStack` 的部分路径。
> 原方法 `current@0x148` 非空且同配置 ID、双方可堆叠时，先合并数量，再调用 `CanPutCard`，按 `is_cost/cost_count` 回滚或分配余量；本批未移植此分支。
> 第37批已移除 `slot_cost_needed` 的首键 DFS，改为完整条件求值，并纠正普通成本被错误枚举的问题，详 [CostContextCorrection.md](CostContextCorrection.md)；付款执行接线仍未完成。
> 此外 `CardStack` 对不可堆叠卡返回 false；整张落槽属于另外的 `DropCard(0x53b720)` 路径，不能归入 CardStack 已验证分支。
> 证据：直接重读 `CardSlotController.c @ CardStack 0x53b0a0 / DropCard 0x53b720`；`dump.cs:317918` 的 current/Slot/panel 字段与 `dump.cs:318014` 方法签名。
> 方法尾部存在 `SFxManager.SFxPlayCharacterDub` 调用，故“卡牌配音触发时机全在未导出控制器里”也不成立；完整音频选择算法仍需另查。

A19 的留档写着：

> **付款执行体仍缺**：`ClearNeedCosts 0x385470` 无反编译调用方，克隆未实际扣卡

**三个事实错误叠在一起**：

1. `ClearNeedCosts` 不是付款执行体，它只是 `ConditionContext` 的**字段重置**（`+0x60=0`、`+0x64=0`、`+0x68=null`），而且**全语料零调用方**——它没有调用方是正常的，因为它本来就是死方法。
2. `CostCondition.PostProcess 0x3f6520` 也不是付款，它是**配置加载期**的一遍：`Datapool.LoadRitePostProcess 0x4163c0` 遍历仪式节点，对每个卡的 tag 名跑 `TranslateTag`，然后调 `PostProcess(List<ICondition>)` 把 `Min`/`Max` 解析并缓存下来。它的签名收的是**条件列表**，不是 `ConditionContext`。
3. 真正的付款执行体在**别处**，而且是反编译产物里完整存在的：`CardSlotController.CardStack 0x53b0a0`。

## 原作事实

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

## 克隆缺口

克隆此前**没有付款执行体**：`add_card_to_slot()` 一律把**整张卡**移进槽，不区分"付出 cost_count"与"填充槽位"。于是：

- 3 金币的槽，玩家拿一张 `count=10` 的金币卡落槽 → 克隆把 10 个金币全放进槽（原作只付 3，余 7 留手牌）；
- 克隆也**没有**槽 cost 查询，落槽前不判断这张卡够不够付。

（第二十二批已把 `IsSatisfied` 的枚举判定做对了，缺的正是"判定→执行"这一步。）

## 修复

### 1. `GameState.pay_cost_into_slot(card_uid, slot, needed, db, rite_uid)` —— 付款执行体

按上表三分支实现：不可堆叠**或**余量 < 1 → 整张移入槽；否则手牌 `count -= needed`、复制一张 `count = needed` 入槽。复制失败时回滚手牌 count。落槽复用现有 `add_card_to_slot`，因此槽位登记、rail 清理、zone 归属都与既有路径一致。

### 2. `GameState.slot_cost_needed(slot, card_uid, db, rite_uid)` —— 槽 cost 查询

深度优先在 `any`/`all`/`none` 里找第一个 `cost.*` 键，取它的值，把解析/比较/夹取全部交给既有的 `ConditionEval.eval_cost`（避免第二份运算符解析），返回上下文里的 `cost_count`；不满足则返回 0。另加 `slot_definition(slot, rite_uid)` 作为槽定义查询。

### 3. 顺手修正一处**幽灵引用**

`condition.gd` 的 `cost_count_for` 文档写着"the count **PayCosts** would hand over"。`PayCosts` 这个名字在 `dump.cs` 里**命中 0 次**——它是编造的。已改为引用真实的 `CardSlotController.CardStack`，并写明这次回归的原因。

## 验证

新增 `tests/test_cost_payment.gd`（**13 测试**），全部对着真实内容与真实偏移：

- 三分支各自的 count/zone/in_hand/slot_key 断言（`count=5` 付 1 → 余 4 留手牌 + 复制 1 入槽；`count=3` 付 3 → 同一 uid 整体移动；`count=1` 付 4 → 整体移动且不改 count）；
- 不可堆叠卡任何 cost 下都整体移动（`HasTag("stackable")` 门的语义）；
- 参数边界（slot 0 / cost 0 / 负 cost / 未知 uid）一律返回 0 且不动手牌；
- 付款切片继承源卡运行时标签增量（`CardExtensions.Copy` 复制 `Card.tag@0x30`）；
- 切片在结算流里记一条 `COPY` 行；
- 槽 cost 查询对着真实配置：`5000005` s2 的 `cost.金币=3` 在 `count=3` 时查得 3、在 `count=1` 时查得 0（条件确实在把关）、`5000001` s4 的 `cost.消耗品=` 能穿过 `any` 找到且要 1、`5000001` s1 没有 cost 键时不发明；
- 分布哨兵：独立重扫 `db.rites` 断言 **653** 个仪式带槽 cost（防文档里的数字腐烂）。

## 仍开放

- **`CanPutCard` 的完整槽接受判定**（槽 type/is/tag 条件 + cost）未接：克隆目前只有 cost 查询，落槽前的完整复核仍走原有路径。本批只保证"该付多少"与"怎么付"两点正确，不宣称整条落槽校验已完成。
- 付款时的 `+0x180/+0x184`（`0.01f`）入场缩放属表现层，未接。
- `cost.<tag>` 无操作符时默认比较符（`Compare` 的 `>=`）由既有 `eval_cost` 决定，本批未改动。
