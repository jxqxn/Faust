# 仪式系统根因自审与重新验收

2026-09-11。用户要求完整复刻原作仪式：外观、交互、动画、规则、时序与存读档都在范围内。
旧的局部完成标记不构成整套仪式的验收。

## 根因

1. 用 prefab 布局覆盖率代替运行流程覆盖率；1495 个配置能打开，不等于每个仪式能完成。
2. 源码注释替代了字段核验：ProcessPop 的 +0xB0 被误当 settlement，实际是 cards_slot，
   闭包是 SlotPop。该错误造成独立的全匹配俺寻思结算器长期存在。
3. 三套执行入口分叉：RiteView 全存档预演/回滚，RoundLoop 无交互即时结束，Methinks 自制循环。
4. 测试锁定了错误契约，例如“投卡不应处于 thinking”；绿灯只能证明测试期望被满足。
5. 未完成项被追加到越来越长的日志，而没有阻止同一模块继续标记“1:1”。

## 本次直接核实的结构冲突

| 原作事实与双信号 | 当前冲突 | 整改入口 |
| --- | --- | --- |
| EnqueueSettlement 0x5a2d10；dump.cs:325472–325474 settlements/finalResults/finalOperations 三队列 | 选一项就执行 result/action，后续条件可被提前结果改变 | RiteResolver：分离选择与执行 |
| DisplayClass56_0 b__4 0x5b3a50 执行 finalResults，b__7 0x5b45c0 执行 finalOperations；二者之间有卡牌处理和 NoteRiteDone | normal.action 提前于 extra.result | 全部 result 队列在 action 队列前 |
| ThinkController.OnCardLocked 0x5c2d10 → GameController.Settlement；RiteNode 定义/5000002 配置 | Methinks 绕过 prior、extra、公共结算器 | 删除独立分支规则 |
| OperationsExtensions.Start 0x500a70 / Promise.Sequence；现有事件链已可保存 continuation | 仪式遇到选项仍提前执行后续结果/移除仪式 | 将仪式接入可暂停操作链 |

## 整体验收清单（尚未完成，不得缩减成外观工作）

- 创建、实例 UID、开放/吸附条件、地图定位与可见性。
- 准备：提示、高亮、合规卡筛选、拖入/替换/付款/回手、恢复投放、帮助。
- 开始/运行：必填与代价、开始日/寿命、停止、跨日、自动开始/到期。
- 结算：prior/normal/extra 与卡牌装备 extra、PreDo、骰子阶段、金骰/重投。
- 串行演出：文字等待、操作卡列表、卡牌变化、归还、action、结束与 final_pin。
- 俺寻思：SlotPop、原动画事件、共享结算、ithink_card、卡归属和再次投放。
- 同状态存读档/回退、提示中断、两个以上同时到期、多个同 ID 实例。
- 原作同存档状态/输入/截图对拍。专项测试和模板截图不能替代此项。

本文件是重新验收入口，具体修复及未通过项持续追加；没有原作背书的边界不得用直觉补全。

## 已落地的结构整改（2026-09-11，整体验收仍开放）

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

## 新核实的剩余差异（不可用旧完成标记覆盖）

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
[`OpCard`](../ui_layout/OpCard.md)（29 节点）、
[`OpCardShow`](../ui_layout/OpCardShow.md)（1 节点）、
[`RiteResultPanel`](../ui_layout/RiteResultPanel.md)（209 节点）。
OpCard 根 564×661，CardShow/Equip 各 256×512，NewGet 200×60 / fs30，
TagBg 200×100；它们目前只是证据，**未宣称对应渲染器或 PreDo 已实现**。
必须按这条独立演出链补全，不允许再恢复全状态预演回滚或用 DSL 文本行替代。

## 本次验证记录

日志均位于仓库外 `C:/Users/User/Documents/Faust-cleanup-20260911/`。

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
