# A19 第三十七批：成本上下文与比较符

第二十二批只移植了 CostCondition 的枚举分支，却把普通落槽也改成枚举；第三十六批又从完整条件中抽出首个 cost 键。本批纠正这两个根因，不宣称完整付款已接入游戏。

## 原作证据

- `CostCondition.c @ IsSatisfied 0x3f6160`：`is_adsorb@0x20=false` 检查 main@0x10 的选择器和附加条件，然后读取 main.count；数量不足仍 SetNeedCosts(count,null) 后返回 false；选择器未匹配不写成本字段。成功时夹到 Max，is_first_drop@0x22 为 true 时取 Min。
- adsorb 分支枚举 Player.cards@0x88，有限 Max 时累加至 Max，无限时至 Min。Rite.cards 不在该根列表中。
- `ConditionContext.c @ SetNeedCosts 0x385540` 同时写 is_cost=true、cost_count 和 need_cost_cards。独立 `dump.cs:383846` 确认全部字段布局。
- `CostCondition.c @ PostProcess 0x3f6520`：数组指定 Min/Max；标量按 modifier 建界。`Compare.c @ ctor 0x3852a0` 初值 modifier=0，成本无比较后缀时不调用 Update，因此裸键为 Min=Max。
- `Compare.c @ Update 0x384eb0` 与独立 `dump.cs:384167` 枚举 EQUAL=2、LESS=4、GREATER=8：`>`=[N+1,INT_MAX]，`>=`=[N,INT_MAX]，`<`=[0,N-1]，`<=`=[0,N]，等号/无后缀=[N,N]。
- `CostCondition.__c__DisplayClass12_1.c @ 0x40bf70` 数字 id 选择器还排除 IsLost；标签选择器闭包 `DisplayClass12_0 @ 0x40bf50` 调 HasTag。
- `RiteExtensions.CanPutCard 0x3918b0` 运行完整槽条件列表，不能单独执行 DFS 提取的成本叶子。

## 改动与真实配置边界

ConditionEval 按显式 is_adsorb 分流，恢复首放最小量、比较上下界、枚举停止阈值和成本状态字段。slot_cost_needed 删除首键 DFS，运行完整条件；RiteView 预检携带实际 UID 与首放标志。数字 id 成本排除遗世卡，枚举候选排除仪式内卡。

原配置 5000001 s4 同时有 !金币 和 any 内 cost.消耗品=1；旧测试错误地允许金币通过，现在拒绝。5000005 s2 的裸 cost.金币:3 仍要求3枚。新增测试分别覆盖首放、非首放、吸附、数量不足但记录成本、别的手牌不能代付以及枚举至有限上限。

## 未完成

尚未接付款辅助函数到 UI；CardStack 已占槽同类分支、吸附 PostProcess 附加条件、根列表精确顺序及 CanPutCard 特殊标签门仍未统一。未做原作实机同帧对拍，不把此边界的测试通过当作 A19 完成。未修改 content。

## 验证

成本14/40、付款辅助13/40、仪式UI36/175、存档桥6/87通过（测试数/断言数）。模拟组首次出现一条旧测试没有构造运行时当前卡 UID；已修正测试夹具，复跑结果收尾追加。日志 cost-context-*.log。

最终：模拟59/181通过；合计128测试/523断言通过，最终五份日志无失败、SCRIPT ERROR、ERROR、orphan或泄漏报告。git diff --check通过。本批为针对性回归，未重新跑全量；此前两项UI失败和一项无断言风险仍未在本批处理。
