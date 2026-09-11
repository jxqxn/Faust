# cost.* 是交易而不是被拖卡牌的属性（第二十二批，2026-09-10）

A19 原登记为"只核数量不够，还需付款对象与顺序"。本批回到 `CostCondition.IsSatisfied`，确认克隆把 cost 当成了"被拖动那张卡的标签"，并把它改成原作的**枚举式付款判定**。

## 原作事实

`CostCondition.IsSatisfied 0x3f6160`（`decompiled/CostCondition.c`）：

- **候选来源是 `player+0x88`（`Player.cards`）**，用 `List_Enumerator` 顺序遍历；不是 `GetHandCards`，也不是 `GetTotalCards`。
- 对每个候选先跑内层 `Compare`（构造函数 `0x3f6880` 把选择器解析成 int：`>= 2000000` 走卡牌 id 分支，否则走标签分支），再跑 `param_1+0x20` 的附加条件列表（`ListExtensions.AllSatisfied`）。
- 命中的卡 `FUN_1800032d0` 收进一个局部 `List<Card>`，并 `iVar10 += card.count@0x20`；`iVar10 >= min` 时停止遍历。
- 末尾 `ConditionContext.SetNeedCosts(count, cards)`，返回值 `min <= iVar10`。字段布局由 dump.cs 独立确认：`is_cost@0x60 / cost_count@0x64 / need_cost_cards@0x68 / self_card_index@0x70`（dump.cs:383873 附近）。
- 交付数量（`iVar9`）的取值规则：`max == int.MaxValue` 且 `total >= min` 时交付 `min`；否则 `total >= min && max < total` 时交付 `max`；其余交付累计值 `total`。
- `PostProcess 0x3f6520` 决定 `[min,max]`：值有两个元素时读 `[0]`/`[1]`；单元素且某标志位为 0（对应"卡牌 tag 分支"）时 min 与 max 都取该值；否则按标志位选择"至少/至多"形态。

**配置实测**（`_unpack/data/config` 全量扫描）：`cost.*` 键 **909 个**，标量 746 / 二元组 163；**39 个不同选择器**（38 个 tag + 1 个卡牌 id）。分布高度集中：`金币` 382、`消耗品` 370，两者占 83%。关键点：`2000029 金币` 本身就带 `消耗品` 标签，所以 `cost.消耗品` 常常由金币直接满足。

## 克隆偏差（已修）

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

## 修复

- `ConditionEval.eval_cost`：改为枚举 `GameState.cost_candidate_cards()`，按 `cost_selector()` 解出的选择器逐个判定，累加 `Card.count` 到下限即停，把选中卡写入 `ctx["need_cost_cards"]`、交付量写入 `ctx["cost_count"]`。
- 新增 `ConditionEval.cost_selector()`（剥掉 `op` 后缀）、`ConditionEval.cost_count_for()`（上述交付量规则）、`ConditionEval._cost_card_matches()`（数字选择器比 `card_id`，否则查有效标签行）。
- 新增 `GameState.cost_candidate_cards()`：按 uid 升序取 `hand / sudan / slot` 三个 zone 的卡，对应 `Player.cards` 的插入序，且**包含槽内卡**（原作是一个 list）。
- 标签判定走 `effective_card_tags`，因此包含运行时增量与 ×count，与第十九批的 tag 模型一致。

## 验证

- 新增 `tests/test_cost_condition.gd`（9 测试 / 21 断言）：无关 acting 卡不阻断可付的 cost、无匹配卡则失败、`Card.count` 累加、达到下限即停并选中**第一个**匹配卡、`[1,2]` 的 max 封顶、`>=` 后缀与数字选择器、有效标签行（配置行 + 增量 + ×count）、槽内卡仍计入、金币满足 `cost.消耗品`。
- 全量 GUT：47 脚本 / 576 测试 / 574 通过 / 4360 断言中 4358 通过（`a19-full.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败仍是既有的 `test_card_flash` 卡面几何与 `test_event_choice_controller` mask 高度，与本批无关。

## 未完成与新增审计线索

- **付款执行体仍未接**：`SetNeedCosts` 只把选择记进 `ConditionContext`；`ClearNeedCosts 0x385470` 在反编译子集里**没有任何调用方**，真正扣卡的那段代码不在子集内。克隆目前只在槽位预检里用 cost 做"能不能放"的门，没有实际扣除，也没有把 `need_cost_cards` 交给结算链。这是 A19 剩下的主体。
- **`cost_count` 为 0 的早期分支**：`IsSatisfied` 开头有一条 `param_2+0x20 == 0` 的路径（读 `+0x10` 的单卡），本批未展开其字段归属，克隆不建模这条分支。
- **标量的 min/max 语义**：`PostProcess` 对单元素值会按标志位决定 "至多" 或 "恰好"，本批按"标量即下限、max 视作无上限"处理并已在代码注释登记；163 个二元组键是确定按 `[min,max]` 读的。
- **`self_card_index@0x70`** 未使用；它在"槽内自卡"类 cost 里的作用未核。
