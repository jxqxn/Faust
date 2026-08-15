# 报告六：事件系统（2026-08-15 第二批完成）

主文档：[`AUDIT_2026-08-15.md`](AUDIT_2026-08-15.md)。审计范围：克隆 `sim/event_runtime.gd`、`sim/game_state.gd` 事件段、`sim/deferred_effects.gd` 对照原作 `EventTrigger.c`、`EventTriggerExtensions.c`、`EventOn/EventOff.c`、`TimingRoundBase/TimingCardBase/TimingRiteBase.c`、`dump.cs`、`data/config/event/*.json`（1863 个，全量统计 + 12 个等距抽样）。

## A. 发现清单

### A1【严重】回合时机语义整体错误：原作是"周期冷却重臂"，克隆是"精确回合匹配"，且 timing_rounds 完全缺失
- **克隆证据**：`sim/event_runtime.gd:100-101` 把 `round_begin_ba/round_begin_fr/round_end` 的 on 值当回合数精确匹配（`_int_or_list_includes(trigger_value, ctx.round)`）。全工程无 `timing_rounds` 任何对应物。
- **原作证据**：`TimingRoundBase.c @ IsValid (0x465d30)`、`OnStart (0x4660d0)`、`OnEnd (0x466000)`、`NextRound (0x465f20)`；`dump.cs:391584` Player+0x128 = `Dictionary<int,int> timing_rounds`（序列化字段）；`Datapool.c:1568` `Timings.SetIdentify(event.on, event.id)`（键=事件id）。
- **正确行为**：事件启用（EventTrigger.Add→ITiming.OnStart）时写 `timing_rounds[事件id] = 当前回合 + 间隔`；触发时机到达时 IsValid 判 `当前回合 >= 下次回合` 才触发，并立即重臂 `下次回合 = 当前回合 + 间隔`（单值）或 `当前回合 + Random.Range(list[0], list[1])`（双元素列表，上界开区间）。EventOff/Remove 时 OnEnd 删除该条目。即 `"round_begin_ba": 5` = **每 5 回合复发**，`[1,2]` = **每 1~2 回合随机复发**，不是"仅第 5 回合/仅第 1、2 回合"。
- **量级**：配置 1381 个事件用 `round_begin_ba`（1217 单值+161 双值列表+3 单元素列表）；其中 **451 个 is_replay=1 的回合事件**在克隆下只触发一次，原作周期复发（例：5300009 `round_begin_ba:5`、5300011 `:7`）。克隆存档也不保存"下次触发回合"状态。
- 附：原作 IsValid 发现 timing_rounds 缺键会 LogError 并返回 false——启用路径漏 OnStart 会被原作当作错误暴露。

### A2【高】rite 时机缺"值 1 = 任意仪式"哨兵，10 个配置事件在克隆中永久死锁
- **克隆证据**：`sim/event_runtime.gd:103-104` rite 组直接 `_int_or_list_includes`，无 `_is_any` 检查（卡牌组 106-109 有）。
- **原作证据**：`TimingRiteBase.c @ IsValid (0x465be0)`：count==1 且 value==1 → 恒真；否则 HashSet.Contains(ctx.rite 的 id)。
- **量级**：配置 10 个事件用哨兵 1：`rite_end:1`×7（5300239/5310453/5310456/5310857/5320420/5320421 等）、`open_rite:1`（5300301）、`rite_can_start:1`（5310129）、`rite_can_fill:1`（5310139）、`rite_can_stop:1`（5310140）。仪式配置 id 均 ≥5000000，克隆中 `1 == ctx.rite` 永不成立。

### A3【高】game_end 被当作无值时机，结局过滤语义丢失
- **克隆证据**：`sim/event_runtime.gd:113` game_end 落入"注册即全部触发"默认分支。
- **原作证据**：`GameEnd.c @ IsValid (0x45efe0)`：取 player+0x7c 结局 id（int.MinValue→false），查结局配置的类型字段（+0x44），值集匹配；单值 **-1 = 任意结局**。
- **量级**：10 个 game_end 事件：6 个 `-1`（克隆碰巧等效）、`-3`（5360002）、`12`（5360026）、`0`（5360037）、`[4,11]`（5360052）、长列表（5360051）共 4 个会被克隆**过度触发**（任意结局都弹）。

### A4【中】back_to_* 不应做回合值匹配
- **克隆证据**：`sim/event_runtime.gd:100` 将 `back_to_round_begin/back_to_prev_round_end` 放入回合值组。
- **原作证据**：`dump.cs:426298/426318` `BackToPrevRoundEnd/BackToRoundBegin : TimingBase`（无值、无重臂，IsValid 恒真）。
- **量级**：配置仅 5321058（`back_to_prev_round_end:1`）受影响：克隆要求 round==1，原作每次回到该时机都触发。

### A5【中】克隆生产代码只发射 7 种时机，52 个事件的触发时机永远不会到来
- **克隆证据**（全部 trigger_events 调用点）：`sim/result.gd:763` card_clean；`ui/game.gd:222` rite_start、`:496` rite_end；`sim/round_loop.gd:34` round_end、`:155/:317` card_clean、`:195` round_begin_ba、`:250` rite_clean、`:265` rite_end。
- **原作证据**：28 个 On* 入口及调用方（EventTriggerExtensions.c 全 28 方法 RVA 0x4f8e60–0x4fa8f0；调用方：GameController.c:2868 game_end、:9052/:9116 counter/global_counter 内联、GameController.__c__DisplayClass141_0:138 round_begin_ba、142_0:68 round_end、141_2:32/53 back_to_*、193_0:21 rite_begin；GenCard.c:298/GenCoin.c:125/GenLoot.__c__16_0:16 card_born；CardExtensions.c:54 card_dead；DesktopCleanCard.4_1:28/RiteResultPanelController.56_4:16/CleanSlot.4_1:45 card_clean；GameController.c:4714 open_card_info；CardInfoNewController.c:601 open_card_info_end；RitePanelController.c:493 open_rite、34_0:16 rite_start/:42 rite_begin；RitePanelShowController.c:993 open_rite、:1010/:1272 rite_can_start、:2039 rite_cancel、24_0:65 open_rite_end；RitePanelTitleController.24_0:40 rite_can_fill/:82 rite_can_stop；RiteExtensions.c:49/CleanRite.3_1/:3_3 rite_clean；RiteResultPanelController.c:1289 rite_end；BeginGuideController.c:132 close_begin_guide；PromptController.c:133 close_prompt；WizardController.c:1285 close_wizard、:2279 show_wizard_option、:2315 sudan_redraw_start）。
- **量级**（配置中有事件声明、克隆永不触发的时机）：counter 16、game_end 10、close_wizard 5、card_born 4、close_begin_guide 3、sudan_redraw_start 2、rite_cancel 2，open_rite/close_prompt/open_card_info/show_wizard_option/open_rite_end/rite_can_start/open_card_info_end/rite_can_fill/rite_can_stop/back_to_prev_round_end 各 1 —— **合计 52 个事件**。（`round_begin_fr/card_dead/rite_begin/rite_settlement/back_to_round_begin/global_counter` 配置 0 使用，暂无内容影响。）

### A6【中】EventOff 小值（<10）的"按谓词批量关闭"路径缺失
- **克隆证据**：`sim/game_state.gd:1112-1117` disable_event 只支持显式 id。
- **原作证据**：`EventOff.c @ Do (0x50ef60)`：单值 <10 时不按 id 关，而是遍历 `GetActiveEvents()`（0x4fba90）按谓词批量 SetEventStatus(0)+Remove；谓词之一为 `NoAchievementEventValid (0x50f410)`（事件 id 不在成就区间 5350528..5372047）。显式 id/列表路径（≥10）与克隆一致。
- **量级**：配置中 `event_off` 小值仅 **1 处**（`event_off:1`）；其精确谓词语义见 C2。

### A7【低】触发顺序偏差：克隆按事件 id 排序
- **克隆证据**：`sim/event_runtime.gd:84` `out.sort()`。
- **原作证据**：`EventTrigger.c @ On (0x4fbc20)`/`DoSettlements (0x4fb1c0)` 均为 `ToList(HashSet)` 直接枚举，**无优先级字段**，顺序=HashSet 枚举序（近似插入序，删除后不保证）。克隆排序是为确定性的有意偏差，非复刻原作顺序。

### A8【低】克隆不读取的事件字段（量级为全 1863 文件统计）
- `text` 1863/1863（事件名，纯 UI）；`settlement[].tips_resource` 1809/1865、`settlement[].tips_text` 1809/1865（结算提示资源/文案，UI 通道，克隆事件弹窗无此文案）；`auto_start` 1517/1863（**数据中恒为 false**，当前无行为影响，但 EventNode 无此字段，属数据冗余）。克隆读取：id/on/condition/settlement[].action/is_replay/start_trigger/auto_start_init（`game_state.gd:1093-1148`、`deferred_effects.gd:101-143`、`event_runtime.gd:47-59`）。

### A9【低/信息】close_begin_guide 值为字符串引导类型，克隆按"全部触发"处理
- 原作：`SingleOrSetValues<string>`，`OnCloseBeginGuide (0x4f94d0)` 把参数写入 TimingContext.guide_type（第 7 字段，dump.cs:395163 区域）做匹配；配置 3 事件值为 `"RIGHT_CLICK_SLOT"/"CHANGE_SUDAN_CARD"/"TIME_OUT"`。克隆落入默认真分支且该时机从未发射（A5），暂无实际影响。

### A10【低/信息】原作 On 有全局闸门
- `EventTrigger.c @ On (0x4fbc20)` 开头检查 GameApplication 静态单例 +0x2c8 布尔，为真直接返回；DoSettlements 循环中途同样检查并中止。疑似加载/退出保护。克隆同步执行无对应物，非缺陷，记录差异（字段名不可解析，见 C3）。

## B. 已验证正确

1. **时机字符串全集一致**：克隆 `event_runtime.gd:100-113` 列出的全部 timing 与原作 29 个 `[Timing("...")]` 属性（dump.cs:426298-426930）一一对应，无多列、无漏列（差异仅在匹配器语义，见 A2/A3/A4）。
2. **注册模型**：定义不注册，EventOn/auto_start_init 启用后才进桶 —— 克隆 `enable_event` 对应 `EventOn.<>c__DisplayClass2_0 <Do>b__0 (0x51f1a0)`：SetEventStatus(id,1)→Add(id,**flag=1**)。
3. **start_trigger 立即结算**：`EventTrigger.c @ Add (0x4fa9d0)`：`event.start_trigger(0x30) & flag` 才走立即路径，用当前回合构造 TimingContext 评估 condition（@0x38）后立即启动 settlement；克隆 `game_state.gd:1102-1105` 同构（同步 vs 队列差异属已审事项）。
4. **一次性/重放完成语义**：`EventTrigger.__c__DisplayClass4_0 <Add>b__0 (0x507360)`：AddDoneEvent(global,id) 无条件写；is_replay=true 保留；否则 Remove+SetEventStatus(0)。克隆 `complete_event`（game_state.gd:1124-1129）逐行对应；`DoSettlements (0x4fb1c0)` 与 DisplayClass6_0 同语义。
5. **EventOff 显式 id 路径**：SetEventStatus(id,0)+Remove(id)；克隆 `disable_event` ✓（timing_rounds 清理无对应物归 A1）。
6. **卡牌时机匹配**：`TimingCardBase.c @ IsValid (0x465a90)`：ctx.card 空→false；count==1&&value==1→任意；否则 Contains(card.id)。克隆卡牌组 + `_is_any` ✓。
7. **条件双重求值**：原作 On 触发时与 DoSettlements 执行前都评估顶层 condition；克隆 `fire()→_condition_holds` + `execute_event` 再评估 ✓。
8. **auto_start_init 初始注册**：配置 `[1]`×336（正常开局）、`[0]`×9（全部为"苏丹引导"新手引导事件）；克隆 profile=1 注册 336 个并正确排除引导事件。
9. **settlement 复用 result DSL**：配置 `settlement[].action` 键（rite 711、prompt 622、success 431、event_off 232、option/case:opN、event_on 150、card 183、loot 55、clean.rite 44、over 91……）走克隆 `ResultExec.execute` 同一引擎；剩余未覆盖键归 DSL 审计管辖，不在本审计范围。
10. **触发点→上下文轴**：round/card/rite/counter 四轴 TimingContext 字段（dump.cs TimingContext:timing/round/card/rite/counter_id/guide_type）与克隆 ctx 键一致。

## C. 无法验证与原因

1. **timing 字面量字符串**：反编译中为 il2cpp 元数据指针（DAT_*），不可直读；以 dump.cs `[Timing]` 属性 + 配置 JSON 键双信号替代，两源 29 项完全一致，可信度高但非反汇编直读。
2. **EventOff 小值谓词的精确含义**（值 1 与其他 <10 分别关闭哪个集合）：谓词为 display-class 委托指针（DAT_182591e50/DAT_182591de0），反编译不可解析；仅确认结构="遍历活跃事件按谓词批量关闭"+NoAchievementEventValid 的成就区间 5350528..5372047。配置影响面仅 1 处。
3. **On 全局闸门字段名**（DAT_1825942c0 单例 +0x2c8）：推断为 GameApplication 的加载/退出标志，无法从 .c 确认字段名。
4. **OnRoundBeginFr (0x4fa650) 与 rite_settlement 的运行时调用方**：全语料库未找到调用点（可能经委托/反射）；配置中 0 个事件使用，无内容影响。
5. **"timing_rounds 235 条样本"**：该数字无法验证——配置统计给出的是 1381 个声明回合时机的事件（451 个可复发），运行时 timing_rounds 条目数取决于启用集合，静态语料无法给出 235。

**核心结论（30 秒版）**：事件系统骨架（注册/启停/一次性移除/条件双检/settlement 引擎）克隆正确；最大的规则性缺口是 **A1 回合冷却重臂机制（timing_rounds）整体缺失**，影响 451 个可复发事件；其次是 **A2 rite 哨兵 1（10 个事件死锁）**、**A3 game_end 结局过滤（4 个事件过度触发）**、**A5 52 个事件的时机克隆从未发射**。
