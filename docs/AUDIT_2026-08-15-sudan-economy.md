# 审计报告七：苏丹卡循环 / 难度 / 回退系统余项（2026-08-15）

> 范围：苏丹卡重抽主链与恢复、重抽失败路径、池标签回写、额外重抽计数器、
> 回退上一回合（Back to prev）完整链、game over 存档处理、advance_day 与
> OnNextRound 链顺序余项。前六份报告已覆盖的 DSL 键语义、事件系统触发时机、
> 卡牌模型不在本篇重复。
>
> 方法：反编译 `.c`（GameController / LoadController / DatapoolExtensions /
> PlayerExtensions / SudanPoolModifyTag / RedrawSudanCard 内联段 /
> RiteResultDiceCountPromptController / DoBackToPrevRoundEnd /
> DisplayClass142_0/141_0/143_0）+ `dump.cs` 字段布局 + `init/1.json` 键提取，
> 对照克隆 `sim/round_loop.gd`、`sim/game_state.gd`、`sim/result.gd`、
> `sim/rite_resolver.gd`、`sim/deferred_effects.gd`、`ui/game.gd`。

## A. 发现清单（按严重度）

### A1【高】回退上一回合（Back to prev）：克隆只有"半条链"，缺失全部执行机构

- **克隆证据**：`sim\result.gd:243-244`（`back_to_prev_round_end` 键 → `deferred.back_to_prev=true`）；`sim\rite_resolver.gd:82-83`、`sim\deferred_effects.gd:174-175`（仅合并标志）；**全仓库无任何消费者**（grep 确认 `deferred["back_to_prev"]` 零读取）；`sim\game_state.gd:64` `back_to_prev_left` 只在 setup_new_run 赋值、存读档往返，**无递减、无 UI**。另 `result.gd:40` 的键清单**缺 `back_to_round_begin`**（原作有对应 DSL op）。
- **原作证据链（修复所需的完整机制清单）**：
  1. 每日双快照：`GameController.c@OnNextRound 0x554540`（L1936）在链开始前 `SaveRoundEnd`；`GameController.__c__DisplayClass142_0.c@<OnNextRound>b__9 0x571000`（L490）在链末 `SaveRoundBegin`。二者都是 `Datapool__SavePlayer(整个 Player 对象, 按轮格式化的键)` + 同时写主键 `""`（`DatapoolExtensions.c@SaveRoundEnd 0x3f9120 / SaveRoundBegin 0x3f9050`）。Player 含手牌/仪式/计数器/苏丹池（`List<Card>` +0xb0）/事件状态/延迟操作/笔记等全部字段（dump.cs:391488-391625）——快照范围 = 全量玩家状态。
  2. 门控：`OnPrevRound 0x554f80`（L2149-2174）：`round(player+0x2c) > max(1, min_round(player+0x30))` 否则 LogWarning 返回；`GetBackToPrevCount < 1` 返回；`< 9999` 才置"消耗"旗标（9999=无限）；`IsValidRoundEnd(round-1)`（`DatapoolExtensions.c 0x3f8d50`）失败则弹错误提示；最后 ConfirmController 确认 → `<OnPrevRound>b__0 0x571320` 调 `PrevRoundInternal(gc, consume)`。
  3. 消耗时机：`PrevRoundInternal 0x555570`（L2246-2252）**确认后、回滚前**调 `UseBackToPrev`；`PlayerExtensions.c@UseBackToPrev 0x38f9b0` → `SetCounter(0x6c5667)`，而 `SetCounter 0x38f2d0`（L941-966）对 id 0x6c5667 **特判直写 Global 对象 +0x7c（clamp ≥0）**，不进玩家计数器——随后 L2261 `Datapool__SaveGlobal` 先存全局，因此**消耗在玩家快照回滚后依然保留**。
  4. 回滚执行：`global+0x80=2`（装载模式）→ `GameEventSender__RoundPrev` → `LoadController__LoadRound(round-1, 0)`（L2283）→ `LoadController.c@0x42f8a0` mode=(flag^1)+1=2 + 目标轮 → 场景重载 → `LoadController$$Start 0x42fc30`（L233-243）mode2 → `DatapoolExtensions__LoadRoundEnd(datapool, round-1)`（`0x3f8e70`：LoadPlayer(roundEndKey) 成功后提升为主存档 `""`）。即回退到"按下一日那一刻的 round-1 全量状态"。
  5. 事件时机与 DSL：`EventTriggerExtensions.c` 有 `OnBackToPrevRoundEnd 0x4f8e60` / `OnBackToRoundBegin 0x4f8f40`；`DoBackToPrevRoundEnd.c@Do 0x4f89a0` 证明 DSL op `back_to_prev_round_end` 就是调 `OnPrevRound`（同一套门控+确认，不是静默回滚）。
- **一句话正确行为**：回退 = 确认后消耗一次全局侧次数（9999 不消耗、0 禁用、`round>max(1,min_round)` 门控），用每日开始时保存的 roundEnd 全量玩家快照整体重装载。
- **修复提示**：克隆已有 `SaveSystem.serialize/deserialize` 全量状态能力（rite_view 金骰基线在用），需要补：每日 advance 双快照存储、`min_round` 字段、确认流程、`LoadRoundEnd(round-1)` 恢复、`back_to_round_begin` 键解析。

### A2【中】重抽中逢单卡生成失败路径与原作分叉

- **克隆证据**：`sim\round_loop.gd:113-137`——循环内 `SudanCards.draw` 返回 -1 时 `break`，之后**仍回插弃卡、仍消耗 redraws_left**。
- **原作证据**：`GameController.c@RedrawSudanCard 0x5558b0` L3823-3834——`GenSudanCard` 返回 0 即 `goto` 错误路径，**不回插弃卡、不消耗次数**（部分生成的新卡留在桌上）。
- 预门控（池数 < sudan_redraw_count 拒绝，L3810-3814）使此路径罕见，但语义相反。

### A3【中】重抽弃卡的运行时标签未写回池

- **克隆证据**：`sim\round_loop.gd:130-134` 弃卡仅按 **id** 回插 `sudan_deck`；在玩期间对该卡实例的标签修改不会写回 `sudan_pool_tags`。另 `sim\result.gd:828-837` 按 id 去重——池中同 id 多张卡共享一条标签记录。
- **原作证据**：`RedrawSudanCard` L3840-3842 把**弃卡 Card 对象本身**（连同标签修改）`List.Insert(Random.Range(0,count))` 回插 `player+0xb0` 池；`SudanPoolModifyTag.c@DoTemplate 0x51c2e0` L194-198 直接对池内 Card 对象过滤改标签，抽卡（GenSudanCard RemoveLast）天然携带。

### A4【中】缺"额外重抽"计数器 7100008（0x6c5668）

- **克隆证据**：`sim\game_state.gd:63-67` 只有 `redraws_left`（= per_round 用量模型）。
- **原作证据**：`PlayerExtensions.c@GetSudanRedrawCount 0x38dda0` L2470-2489：可用数 = `player+0x6c`(per_round) + 计数器 7100008；`RedrawSudanCard` L3845-3862：`used(+0x70) < per_round(+0x6c)` 则 `used+1`，**否则** `UseSudanExtraRedraw 0x38fb60`（7100008 减一）。来源 = 通用 ModifyCounter DSL 可加此 id（当前配置数据 grep 7100008/7100006 零命中，今日无内容差异，但克隆的 counter.add 写这个 id 会成为死数据）。
- 附带：克隆 `_redraws_per_round` 恢复缺 `recovery<2 恒重置` 保护（原作 b__9 L465-473；`round % 0` 在 Godot 报错；配置恒 7，当前无害）。

### A5【低】advance_day 与 OnNextRound 链的顺序差异（部分可证、部分存疑）

- 可证差异 a：原作每天在链首/链尾各存一次快照（见 A1），克隆无。
- 可证差异 b：原作苏丹处刑检查位于 b__6（round+1 与 round-begin 类步骤**之后**、TryGenSudanCard 之前）；克隆在 round_begin_ba/auto-begin **之前**（`round_loop.gd:44-60`）。净效果（处刑先于抽新卡）一致。
- 可证差异 c：原作重抽恢复在抽卡后（b__9），克隆在抽卡前（`round_loop.gd:187-189`）——无观察差异（抽卡不读重抽状态）。
- **存疑**：原作链在 OnRoundEnd（b__2）**之前**有 3 个绑定 GameController 的 Do\* 槽位（形状与 `DoRiteUpdate 0x54ea40` / `DoCardUpdate 0x54d4c0` / `DoDelayOpertions 0x54da50` / `DoStartAutoBeginRite 0x54ebc0` / `DoIThink 0x54e880` 完全吻合：3 Func + 1 Action 在前、2 Func 在后），但 DAT_ 元数据指针无法映射到具体函数名（见 C1）。若 DoRiteUpdate 在前置槽位，则**原作仪式推进先于 round_end 触发，克隆相反**（`round_loop.gd:34-36`）。克隆 SRC 注释声称"round_end 先观察旧回合"与 b__2 先于 round+1 一致，但"先于 Do\*"不可证。

### A6【低】game over 后存档处理不同；round 值净一致

- **克隆证据**：`ui\game.gd:539-546` `_show_game_over` 调 `SaveSystem.delete_save()`（无继续）；round 不加（`round_loop.gd:59` game_over 时跳过 `_begin_round`）。
- **原作证据**：`DisplayClass142_0@b__10 0x570600` L579-597：捕获 GameOverException 后**若 round 已被 b__3 加过则 round-1（clamp 0）**再 `DoGameOver 0x54dbd0`（读 over_reason 显示，不删存档；主存档停在 SaveRoundEnd 时刻 = 致命推进前的状态，可 continue 重打该回合）。
- 结论：两侧 game over 后 round 都 = N（原作 N+1 后回退；克隆不加），round 值一致；差异仅在"是否保留继续存档"。

## B. 已验证正确列表

1. **重抽主链模型**（extra=0 退化情形）：可用 = per_round−used ↔ 克隆 `redraws_left`；"成功一次减一"路径证实（`RedrawSudanCard` L3845-3854：`used(+0x70)+1`）；恢复时点一致——原作 b__9 在 round+1 后判 `round % recovery(=7, player+0x74) == 0`，克隆 `_begin_round` 在 round+1 后同式（`round_loop.gd:187-189`）；池预门控一致（`pool.count < sudan_redraw_count`，克隆 `round_loop.gd:98-101`）。
2. **per_round 来源**：原作 `SetDifficulty 0x38f530` L2295 写 `player+0x6c = 难度节点+0x38`（init 1.json：3/1/1），克隆 `game_state.gd:505/546-549` 同源；`sudan_redraw_count` 恒为 init 顶层 1，难度不覆盖，克隆一致。
3. **回退计数存储语义**：原作 Global+0x7c（SetCounter 特判路由、clamp≥0、SetDifficulty 按 `Global.0x7c - 9999 + 难度值` 调整），克隆用 `back_to_prev_left` 存档字段——回滚后保留这一关键性质等价（字段在玩家快照外/克隆全量存档内均不回滚）。
4. **sudan_pool_tags 抽卡带入**：两条抽卡路径（`draw_weekly_sudan`、`use_redraw` 新卡）都过 `_create_sudan_instance`（`round_loop.gd:174-181`）合并池标签；原作语义（池内 Card 对象改标签→抽走即携带）在"池内修改→抽出"主路径上等价。
5. **金骰 UI 键型一致**：原作 `goldDiceCounts` 为 `Dictionary<string,int>`（dump.cs:383865），键 = FuncCompare.type 字符串（dump.cs:416915），配置实测键域 `f`/`r1`/`r2`（rite 目录 512/1534/367 处）；克隆 `_gold_type_for_reactive_spend` 返回 `dice_types_seen[0]`（condition.gd:226/276-279 记录的正是该前缀字符串），空回退 `"r1"` 仅 UI 边缘。金骰花费用计数器 7100006 持久、`goldDiceCounts` 每结算上下文 fresh——克隆 `state.gold_dice` 持久 + `_gold_dice_map` 每次结算清空（rite_view.gd:410/454/525）一致，重抽基线回滚（`_resolve_baseline`）对应 OnGoldCancel/关闭路径。
6. **advance_day 骨架顺序可证部分**：round_end 触发在 round+1 前（克隆 ✓ 对应 b__2→b__3）；round+1 后才 auto-begin 仪式、抽苏丹卡（b__7 的 `player+0x161` disable 旗标门控 ↔ 克隆 `auto_gen_sudan_card`）；TryGenSudanCard 在处刑检查后。
7. **game over 的 round 净值**（见 A6）：两侧一致。
8. **事件时机名**：`back_to_prev_round_end`/`back_to_round_begin`/`round_begin_ba`/`round_begin_fr`/`round_end` 五个时机克隆 event_runtime.gd:100 全部识别；原作配置只用 `round_begin_ba`（1381 处）与 `back_to_prev_round_end`（1 处），克隆从未触发 round_begin_fr 今日无内容影响。

## C. 无法验证与原因

1. **OnNextRound 链槽位 3/4/5/9/10/11 的具体函数身份**：这些步骤经 `System_Action/Func .ctor(obj, DAT_指针)` 绑定，DAT_ 是 il2cpp 元数据段地址；`_symbols.tsv`/`_game_funcs.tsv` 只映射代码 RVA→名，无法反查。因此"仪式更新（DoRiteUpdate）在 round_end 触发之前还是之后"（A5 存疑点）与"auto-begin 是否先于 OnRoundEnd"不可定论，需实机日志或 Ghidra 元数据表交叉。
2. **链槽位 8/13（绑定 gc+0x298 EventTrigger 实例的委托）是否精确为 OnRoundBeginBa/Fr 求值+DoSettlements**：OnRoundEnd 在 b__2 内联直调（证实），但 Ba/Fr 在 OnNextRound 流程中的发射点未以直调形式出现（仅 startup 链 `<Start>b__5` L138 直调 OnRoundBeginBa）；架构上高度吻合"8/13=Ba/Fr 判定"，指针身份不可证。
3. **SaveRoundBegin/End 快照键的字符串字面值**：DAT_ 格式串不可读；"按轮参数化命名"由 `IsValidRoundEnd(round)`/`LoadRoundEnd(round)` 的传参结构证明，具体键名（如 `round_end_{0}`）无法还原。
4. **OnGoldConfirm 上层捕获方写入 goldDiceCounts[type] 的确切代码行**：GoldDiceException 构造与 Promise.Reject 已证（RiteResultDiceCountPromptController.c@0x59d8b0 L562-566），捕获重跑方未读；键型证据链（dump.cs 字段 + FuncCompare.type + DICE_SYSTEM.md §6.5 IsSatisfied 读取）已足够支撑键型结论。
5. **原作 game over 后主存档是否被再次覆盖**：DoGameOver 之后续 UI 流未追踪；不影响 A6 的 round 值结论。

---

预算说明：本域审计仅读取点名文件及直接关联（GameController.c 指定函数段、LoadController.c、DatapoolExtensions.c、PlayerExtensions.c 指定函数、SudanPoolModifyTag.c、RedrawSudanCard/RiteResultDiceCountPromptController/DoBackToPrevRoundEnd/BackTo\* 全文、DisplayClass142_0/141_0/143_0 全文、dump.cs 三处类定义、init/1.json 键提取、克隆四个点名文件 + result.gd/condition.gd 相关段），未修改任何文件。
