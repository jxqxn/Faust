# 审计报告八：仪式结算管线余项（2026-08-15）

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

## A. 发现清单（按严重度）

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

## B. 已验证正确

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

## C. 无法验证与原因

1. **金骰扣费计数器 7100006**：`grep 7100006` 在 decompiled 全目录无命中；`PlayerExtensions__GetGoldDiceCount` 被调用（`RiteResultDiceCountPromptController.c:84`）但其扣费写点与计数器 id 需通读 PlayerExtensions.c/counter 表才能定位。预算内未做。
2. **OperationsExtensions.Start 中 `op+0x30`/`op+0x38` 的确切字段语义**：偏移与 `RiteNode.Settlement.result(+0x30)/action(+0x38)`（dump.cs:392606-392608）及 `OperationContext._preResult(+0x30)/_preExtraResult(+0x38)`（dump.cs:394482-394483）均吻合，但无法从局部反编译确定是哪一个（需遍历 Operations 子类字段表）。
3. **ThinkController.OnDrop → IThink 的后续运行时链**：`DoIThink (0x54e880)` 已确认是"程序化把选中卡丢到思考桌"（行 10225-10246 构造 PointerEventData 调 `ThinkController__OnDrop`），但 ThinkController.c 未读，克隆 `sim\methinks.gd` 的"直接 resolve think 仪式 s1"与原作服务端链的等价性未证。
4. **一槽多张卡（多卡槽）**：原作 `Rite.cards` 为按槽索引对齐的 `List<Card>`，`GetSatisfiedSlotIndex` 逐索引找空位——所见证据均为一槽一卡；克隆 `cards_in_slot(...)[0]`（`rite_view.gd:96-98`、`round_loop.gd:274-276`）与此一致，但"等价卡/卡组 any-of 匹配"在 CanPutCard(0x3918b0) 内部，未读（condition 语义归报告一/五，不重证）。
5. **面板闭包链中 OnRiteEnd 与 RemoveRite 的相对顺序**：`Settlement` 的 10 层 promise 闭包（a6f0..abc0）未逐一映射到 DisplayClass 方法名；克隆"record_ended→返卡→移除→deferred→rite_end"的顺序（A6）只能部分对证。
6. **GetRerollCount 数据来源**：仅读函数头 12 行（0x392990），重掷次数来自配置还是玩家计数器未确认——不影响 A3 的立案（重掷路径存在本身已由 OnRedraw/RetryException 双信号确认）。
7. **骰数提示"仅失败时呼出"**：`ShowDiceCountPrompt/ShowDicePrompt` 的调用者（结算链内 op）未定位，A8 保持 Info 级。

## 附：给报告一 A1 的直接依据（StartRite 六问答案）

`StartRite$$Do (0x51bcf0)` 是**创建仪式实例的 DSL 操作**，不是开始按钮——GetRiteData→InitRite（含吸附，失败则中止创建）→AddRite→`new_born` 时 NoteRiteStart；**不置 start、不校验槽满、不设 waiting_round/life（均保持 0）**。玩家的"开始"在 `RitePanelController` OnConfirm（CheckConfirm→set_start→start_round=player.round→start_life=life，行 1203-1239），且可通过 `OnStop (0x5906e0)` 撤回（start=false、life 回滚 start_life、卡留槽）。
