# 原作—克隆方法映射表（METHOD_MAP）

## SourceTips 鼠标悬停提示修正（2026-09-11）

原有“1:1”记录有误，本批已用 `.c` + `dump.cs:326121` + prefab + PE映射常量重新核实。
`SlotTipsController.SetPositionInternal 0x5ac340 / set_Width 0x5aca50 / .cctor 0x5ac920`：
分母3840、阈值0.8、左右面板切换、先夹取指针再投影与世界偏移；动态高度/边框切片、
GetTipText→Translate未知key回传、Godot输入坐标与命中顺序已修正。8测试132断言通过，
两分辨率viewport输入覆盖整理/回退/处决日/背包/俺寻思。原作实机像素级对拍未完成；
其他holder、动态文本、手柄、卡槽提示仍开放。详 [真值表](ui_layout/SourceTips.md)
及 [修正报告](audit/SourceTipsCorrection.md)。

## A19 付款执行体定案：`CardSlotController.CardStack`（第三十六批）

"付款执行体仍缺（`ClearNeedCosts` 无反编译调用方）"**三个前提全错**：`ClearNeedCosts 0x385470` 只是 `ConditionContext` 字段重置（`+0x60`/`+0x64`/`+0x68`）且全语料零调用方——死方法本就不该有调用方；`CostCondition.PostProcess 0x3f6520` 是**配置加载期**一遍（`Datapool.LoadRitePostProcess 0x4163c0` → 逐卡 `TranslateTag` → 解析缓存 `Min`/`Max`），签名收 `List<ICondition>` 而非 context。真正执行体一直在产物里：**`CardSlotController.CardStack 0x53b0a0`**。规格：开头 `HasTag(card, "stackable")` 门（字面量 `0x2593720` = `stackable`，即 tag.json `可堆叠`）；`ConditionContext(rite+0x90,…, card, …, 1)` + `RiteExtensions.CanPutCard` 填 context；`is_cost@0x60 == 0` → 不是付款槽直接返回 0；`余量 = card.count@0x20 − ctx.cost_count@0x64`；**余量 < 1** → `PlayerExtensions.RemoveCard(player, card.id@0x18)` 整张离手，落槽的就是这张卡本身；**余量 ≥ 1** → `Card.set_count(余量)` 留在手牌 + `CardExtensions.Copy(card, keep_count=true)` 后 `set_count(ctx.cost_count)`，只把应付那份 `SetCard` 进槽。不可堆叠卡因开头那道门永远走整张路径。`cost_count` 即克隆的 `cost_count_for()`（源自 `IsSatisfied 0x3f6160` 尾段）。配置侧：**1863 个仪式里 653 个**槽条件带 `cost.`，**46 个不同键**（`cost.消耗品=` 333 / `cost.金币` 323 / `cost.金币=` 57 / `cost.可堆叠=` 27 / `cost.不满` 13 …），操作符是键的一部分，且可嵌在 `any`/`all`/`none` 内（如 `5000001` s4 = `{"type":"item","!金币":1,"any":{"cost.消耗品=":1,"is":2001303,"空屋":1}}`；`5000005` s2 = `{"type":"item","cost.金币":3}`）。克隆落地：`GameState.pay_cost_into_slot(card_uid, slot, needed, db, rite_uid)` 三分支执行体 + `slot_cost_needed()` / `slot_definition()`（DFS 穿透 any/all/none 找 `cost.*`，解析/比较/夹取复用 `ConditionEval.eval_cost`，不写第二份运算符解析）+ `_find_cost_key`/`_cost_key_value`；此前 `add_card_to_slot()` 一律整体移动，故 3 金币槽配 `count=10` 的卡会把 10 个全放进槽，现已按规格只付 3。`tests/test_cost_payment.gd` **13 测试**：三分支 count/zone/in_hand/slot_key、不可堆叠门、参数边界（slot 0/cost 0/负 cost/未知 uid）、切片继承运行时标签增量、切片记 `COPY` 行、真实配置查询（`5000005` s2 `cost.金币` 在 count 3 查得 3、count 1 查得 0；`5000001` s4 穿透 `any` 查到 `cost.消耗品=` 要 1；`5000001` s1 无 cost 键不发明）、独立重扫断言 **653** 防腐。**幽灵引用修正**：`cost_count_for` 文档里的 `PayCosts` 在 dump.cs 命中 **0** 次，是编造名，已改指 `CardSlotController.CardStack`。**仍未接**：`CanPutCard` 完整槽接受判定（type/is/tag + cost 合并复核）、付款入场缩放 `+0x180/+0x184`（0.01f）。详[付款执行体证据](audit/CostPaymentExecutionCorrection.md)。

## A21 续：三张音频映射表也是配置（第三十五批）

上批留的线索（"配音文件名→调用点很可能也有配置表"）**查实：三张表全在语料里**。①**`sfx_npc_role_dub.json`** = **卡片 id → 有序配音 clip 名数组**：584 条 / 579 非空 / 670 引用 / 去重 **123** clip，**123/123 语料零缺失**；键域由 `2000029 → ["item_coin"]`（金币卡唯一"台词"是金币音效）钉死为 `CardNode.id`，不是人物 id；数组顺序即变体取用顺序。审计的"~391 个配音无法逐条对拍"**既高估数量也误判载体**。②**`sfx_settle_card_new.json`** = 9 键，**`"0"` 是默认项**、8 个坏结果覆盖（`settle_card_new_bad`），三种值 `nomal`/`great`/`bad`（原作拼写 `nomal` 不改）；语义 = **具体优先、否则落 `"0"`**，不是未命中静音。③**`over_music_config.json`** = 150 项，表项形状与 `sfx_config.json` 循环表一致（`{clip,start,loop_start,loop_end}`）；149 个键是结局 id，**全部命中** `content/over.json` 的 159 个属性键（零缺失）；第 150 键是 **`-1` 兜底**（clip 同结局 1..7）。顺带澄清 `over.json` 是**顶层对象**（键=结局 id）、**节点无 `id` 字段**，`ui/game_over.gd` 亦按属性键查——曾误当数组解析，被测试打回。落地：三配置逐字节拷入（parity **3889/0**）+ `db.{npc_role_dub,settle_card_new,over_music}` + `GameAudio.{npc_dub_files,npc_dub_file,settle_card_cue,over_music_entry,over_music_clip}`（`_cue_file` 统一补 `.ogg`；索引**钳制**；`over_music_entry` 原先的 `over_id<=0` 门会挡掉 `-1`，已去）。资产：三表引用的 133 clip 中 **132 个从未进克隆**，全部 SHA-256 等值拷入（42 MB），音频目录 35→**167** ogg（167/167 相等），`CUE_CLIPS` 改为登记全部 167 项。`test_audio_cues.gd` 10→**18**：三表形状与键域、索引钳制、空/未知/`null` 三路径、**每个 clip 必须 `ResourceLoader.exists` 且必须在 `CUE_CLIPS`**、结局 id 双向覆盖（含 10 个无音乐结局 `0,15,40,204,273,274,289,290,291,999` 的确切集合与 `-1` 等价性）。**仍未接**：播放宿主（**表 ≠ 时机**，不编造触发点）、两张难度音乐表的消费方、`MusicFadeOutController` 淡出曲线；语料 207 ogg 中另 40 个（~21MB）未被任何已集成配置引用，未搬。详[映射表证据](audit/AudioMappingTablesCorrection.md)。

## A21 音频 clip 名来源定案：`sfx_config.json`（第三十四批）

A21 原留档"`LoopArmageddonController` 的 clip 名来自编辑器字段、语料无该字符串、无法推导"**是错的**——clip 名与循环点都在 `data/config/sfx_config.json`（顶层 5 张表：`main_game_loop` / `main_game_loop_difficulty` / `settle_loop` / `settle_loop_difficulty` / `armageddon_music_loop`），表项 = `{clip, start, loop_start, loop_end}` + 可选 `play_in_rite_create` / `play_instant`。查找链：`LoopArmageddonController.GetLoopData 0x4033f0` 与 `PlayArmageddon 0x403520` 都走 `Datapool+0x68→+0x60→+0xB0→+0x38`，以 `Animator.GetInteger` 得到的 controller `+0x48`（**配置 id**）为键；`PlayArmageddon` 的空名报错把 `+0x40`(clip 名) 与 `+0x48`(id) 一起 `String.Format` 进 LogError，两个偏移语义由此坐实；`GetClip 0x403240` 按名解析 AudioClip（先 `Datapool.LoadModAudioClip`，空则退内建数组）；`Update 0x404110` 用 `loop_start(+0x34)`/`lifeCount(+0x38)` 做 `time` 回卷。`armageddon_music_loop` 共 **22 个 rite id**（5003027…5010201）→ 10 个 clip（`secret_journey`/`dragon_slayer`/`final_battle_facing_sultan`/`the_last_sultan_card`/`seeds_of_history`/`battle_1..4`/`void_flight`），`loop_end:-1` = 放到尾。落地：`content/sfx_config.json` 逐字节拷入（parity **3886/0**）+ `db.sfx_config` 加载 + `GameAudio.ARMAGEDDON_TABLE_KEY`/`armageddon_rite_ids`/`armageddon_loop_for`/`armageddon_clip_for`（三种空查询路径对应原作"clip 名为空→LogError"）；`armageddon_music_loop` 的 10 个 clip 里 7 个从未进克隆，已 SHA-256 等值拷入并全部登记 `CUE_CLIPS`（13 名）。`test_audio_cues.gd` 4→10：表 22 项、两种表项形态、未知 rite/id 0/config null 三空、**每个 clip 必须 `ResourceLoader.exists` 且必须在 `CUE_CLIPS` 里**、`main_game_loop` 同查。**仍未接**：播放宿主（`is_armageddon`/`armageddon_rite_id` 全仓只有初始化 + 存档恢复两处写点，**无运行时赋值**，硬接即自制时机）、两张难度音乐表的消费方、`MusicFadeOutController` 淡出曲线。**新线索**：音乐族提示名来自配置表，故"~391 个配音文件名→调用点在未导出 .cs"这条留档很可能也有对应配置表。详[clip 来源证据](audit/AudioClipSourceCorrection.md)。

## A11 卡牌场景环境输入定案（第三十三批）

`CardShaderAudit.md` 把"SH 环境光 / 反射立方体 / RenderSettings 现场绑定值"挂在"待测"。本批**在导出场景数据里定案**，不需要抓帧——序列化值本身就决定了它们。①**环境光是 Flat 单色，不是 SH**：`GameScene.unity` RenderSettings `m_AmbientMode:3`(Flat) + `m_AmbientSkyColor {0.212,0.227,0.259}` @ `m_AmbientIntensity:1`；`m_AmbientEquatorColor`/`m_AmbientGroundColor` 在 Flat 下**不参与**；`LightmapSettings` 的 `m_EnableBakedLightmaps:0`/`Realtime:0`/`m_AO:0` 证明**无烘焙 GI** → shader 的 `ambient_diffuse = vec3(0.212,0.227,0.259)` 逐字正确。②**环境反射恰为零**：`m_SkyboxMaterial` 与 `m_CustomReflection` 均 `{fileID:0}`，Flat 不产 SH → 没有可绑立方图，`environment_specular = vec3(0.0)` 有源。③**只有一盏灯照卡**：场景仅两个 `!u!108`，都是 Directional/白/强度1；`&4869` mask `1073741824`(`1<<30`) 只含苏丹骰子层且有软阴影，`&4870` mask `2147483895`(`0x800000F7`) **bit5=1 → 含卡牌 layer5**、无阴影 → 克隆"单光源+白+强度1+无阴影"四条成立，且**禁止**用 4869 给卡牌造投影；`&4870` 宿主 Transform `&4011` 四元数 `(.13040192,.043246232,-.005693473,.9905012)`（欧拉 x:15 y:-5）与审计一致。④**颜色空间登记为未验证分歧**：源 `m_ActiveColorSpace:0`(Gamma)，克隆 `project.godot` 无任何 rendering/color_space 设置；**不断言亮度方向**（Unity Gamma ↔ Godot 线性/显示 sRGB 的对应未在本仓库验证）。⑤**仍未定案**：`light_direction` 的 z 符号——匀量 `(-0.08418598,0.25881905,0.96225019)` 正是源四元数的 forward，而 shader 把 `l` 当"指向光源"用；两种解释（全局取负 / 切线空间 z 朝向相反）都自洽，需**同帧卡面明暗对拍**才能判，故不改。落地 `tests/test_card_shader_scene_inputs.gd`（8测试/30断言）直读语料 `.unity` + `ProjectSettings.asset` 与 shader 匀量交叉断言。**渲染公式本身未碰**（TBN/粗糙度/能量分配、法线打包、手工亮度倍率、纵向渐变、detail 均值补偿仍开放）。详[环境输入证据](audit/CardShaderEnvironmentCorrection.md)。

## A13 事件派发挂载点真值表（第三十二批）

"A13 挂载点无源（缺 GameEventSender）+ b__2/b__8 未读"**两句都作废**。① `GameEventSender` 从不是事件系统——它是 **PostHog 埋点**（`Configs: Dictionary<GameEventSenderType, PostHogSenderConfig>` / `PostHogSender` / `OnApplicationQuit` 上报），方法名（`StartGame`/`NextDay`/`CardBorn`）像游戏事件是误判来源；真正的事件系统是 `EventTrigger.c`（`Add` 0x4fa9d0 / `Remove` 0x4fc3a0 / `On` 0x4fbc20 / `GetActiveEvents` 0x4fba90 / `DoSettlements` 0x4fb1c0）+ `EventTriggerExtensions.c`（**28 个 `On*`**）+ `EventNode.c`。② `b__N` 编号**每个闭包类各自从 0 起**，必须带前缀：`GameController.__c__DisplayClass142_0.<OnNextRound>b__2 0x570720 = OnRoundEnd`、`b__6 0x570b00 = UpdateSudanLife/HandCardAutoSort/AutoClassify/UpdateHandCards/UpdateHandCardPos×2/CardArrange`、`b__7 0x570e60 = TryGenSudanCard`、**`b__8 0x570f90` 是空体**、`b__10 0x570600 = DoGameOver + LogException`；`round_begin_ba` 挂在 `DisplayClass141_0.<Start>b__5 0x56f9c0`，**紧跟 `player+0x2c += 1` 之后**（与第二十一批一致）。③**派发真值表**（`decompiled/*.c` 全量调用点扫描，排除 `EventTriggerExtensions.c` 自身定义 × `data/config/event/*.json` 的 `on` 块，1863 文件）：配置侧 21 个时机=`round_begin_ba` 1381 / `rite_end` 357 / `card_clean` 68 / `counter` 16 / `game_end` 10 / `rite_start` 7 / `close_wizard` 5 / `card_born` 4 / `close_begin_guide` 3 / `rite_cancel`・`sudan_redraw_start` 2 / 其余 11 类各 1——**全部有源**。`card_dead`（`OnCardDead` 0x4f9200）与 `round_begin_fr`（0x4fa650）**有定义、无任何调用点、0 配置实例** → 克隆两处自发派发已删（`_update_card_lives` 的 `trigger_events("card_dead")` 与 `ROUND_TIMINGS` 里的 `round_begin_fr`）；原作的死亡面是卡自身 `vanish` 块 + `card_clean`。`OnCounterChanged` 0x4f9770 / `OnGlobalCounterChanged` 0x4f9a30 同样无调用点，但配置确实用 `counter`（16 例），克隆按配置键派发即正确。仍未接：`rite_begin`（有源 2 处调用、0 实例）、`rite_clean`、`EventTrigger.DoSettlements` 的结算块顺序、28 入口的 `controller+0x298` owner 未逐点对照。详见[派发真值表](audit/EventDispatchTruthTable.md)。

## A20 `rebirth.s<n>` 两分支与 冻结 门（第三十一批）

`RebirthSudanCard.Do 0x519d60` 只是"取 `<>c` 缓存委托 → `OperationFilter.Filter` 逐卡调用 → `GameController.UpdateSudanLife 0x55aeb0`"，**自己不动 life**；真正写点在 `<>c.<Do>b__4_0 0x51dec0`：`HasTag(card, "freeze")` 为假 → `Card.set_life(card, 0)`；为真 → 读 `CardNode.card_vanishing@0x60` 并 `Card.set_life(card, card_vanishing − player.sudan_card_init_life@0x64)`，即 **`GenSudanCard` 的同一头起步量，不是满额**。字面量此前记为"元数据无法反查"，实际 `il2cpp_dump/stringliteral.json` 的键 = **VA − `0x180000000`**：`DAT_1825ac9e8 → 0x25ac9e8 = "freeze"`（tag.json id 3019999 冻结 / code freeze / can_add 0）、`DAT_182596500 → "sudan"`。配置侧 8 处写点全落苏丹卡槽：5000158 s2（`type:sudan`）、5006558 s1×2（`type:sudan`，正文"就像是从女术士的宝匣里刚刚抽出来的时候一样"）、5000576 s1×5（`is:2001019`，`card_vanishing=15` → 冻结档 `life=10`、倒计时 5），`is_empty` 全 0。克隆旧实现无条件 `life=0` + `days_left=card_vanishing`，两处都错；**默认档 `sudan_life_time`=7 与 `2010001.card_vanishing`=7 退化同值**，所以旧测试一直"通过"——本批把 fixture 搬到困难档（头起步 5）才暴露。已改为 `_has_freeze_tag()`（经 `db.tag_code_to_name` 解析、读有效行）+ 按门分流 + `days_left = card_vanishing − life`；`test_dsl_batch1.gd` 拆成"无冻结/有冻结"两条并显式断言 `days_left != card_vanishing`。详[rebirth 分支证据](audit/RebirthBranchCorrection.md)。

## A12 CardOpContext 操作流 补记（第三十批，ADD_TAG/REMOVE_TAG 入流 + `can_visible` 门）

上一批留的"can_visible 门 + 两类记录缺失"本批收口。**`can_visible` 是显示旗标，不是写入门**：门在 `RiteResultPanelController.AddCardOp 0x5a0e60` 的 `List.Add`（0x3345）**之前**（0x3337：`*(char *)(*(long long *)(param_2 + 0x20) + 0x41) == 0 → return`），而 `CardExtensions.AddTag 0x37e6a0` / `RemoveTag 0x382e40` **从不读 `+0x41`**；全语料 `+0x41` 读点（`HandCardsController`/`HandBagController`/`CardInfoNewController`/`GalleryCardInfo`/`Datapanel`/`TagNode`/两个 ModifyTag 系列的 PreDo/结果面板/`PanelBase`/`MusicFadeOutController`）**全部是消费方**。所以 `can_visible=0` 的 262/442 个标签（影响力/污名/耐心/专属/各类存货与标记）**照常写入卡牌，只是不产生结果行**。

克隆落地：`ResultExec._mutate_tag()` 收口**全部 6 个标签写入源**（裸键 / `s<n>` 槽 / `table.` `g.` / `total.` / `sudan_pool.` / `GenCard` 的 operation-local TagModify），写入无条件、只有**记录**过门；`TagSystem.apply` 改为返回"值是否真变了"；`GameState.record_tag_op(uid, tag_name, op, amount, tags)` 落 `op` 6/7 + `tag`/`amount`/`value_after`，并补上此前只有注释没有值的常量 `CARD_OP_ADD_TAG=6`/`CARD_OP_REMOVE_TAG=7`（`+`/`=`→6、`-`→7）。**记录时机对齐原作 PreDo**（`DesktopModifyTag.__c__DisplayClass7_1.c` `<PreDo>b__2` 0x521f60 / `b__3` 0x521fb0 → `OperationContext.AddCardOp_AddTag` 0x39dfa0 / `_RemoveTag` 0x39e870），**早于** `Do()` 的 `can_add` 门，故 `self+已拥有`（卡上已有、实际零改动）**仍报一行**；曾加过"没变就不记"的过滤，属自制偏差已删。测试 `test_card_op_stream.gd` 9→13（含"不可见标签写入了但不入流""can_add 挡住仍报一行且卡没变"），`test_tag_model.gd` 13/13。全量 GUT 53 脚本 / 617 测试 / 614 通过 / 4544 断言（4542 过；两条既有 UI 失败、1 条既有 Risky，零 SCRIPT ERROR/orphan/泄漏），content parity 3885/0。详[操作流证据](audit/CardOpStreamCorrection.md)。A12 仍剩：逐张卡动画播放（`OpCardNewController.Init 0x572f40`）、`+0x182` 缓存态与 `MoveOpCardsToResults`、`+0x183` 门、POP/HAND_POP/THINK_POP/REBIRTH_SUDAN_CARD 四类记录（其中 `pop.`/带点 `hand_pop.`/`think_pop.` 在**全量 config 里 0 次出现**，故不可达，非可验证缺口）。

## A12 CardOpContext 操作流（第二十九批，操作流已落地、播放未接）

`CardOpType`（dump.cs 6304）13 值 NEW0/COPY1/DELETE2/EQUIP3/UNEQUIP4/UNEQUIP_RECOVERY5/ADD_TAG6/REMOVE_TAG7/UPRARE8/POP9/HAND_POP10/THINK_POP11/REBIRTH_SUDAN_CARD12；`CardOpContext`（6305）`OpType@0x10/card@0x18/tag@0x20/value@0x28/count@0x2c/pop@0x30`；`RiteResultPanelController.AddCardOp0x5a0e60` 对 ADD/REMOVE_TAG 先查 `tag+0x41`（can_visible）不入队，否则追加到 `+0x1d8`；`OpCardNewController`（4476）是播放侧。克隆 `_rebuild_result_lists` 原为空实现、且**无任何操作记录源**。第二十九批：`GameState` 加被动结果操作日志隔舱（NEW/COPY/DELETE/EQUIP/UNEQUIP/UNEQUIP_RECOVERY/UPRARE 在卡牌变更点记录），`ResultExec.execute` 与 `rite_view._apply_deferred_to_world` 两处开启收集（延迟效果也算同一条流），结果面板按真实流填充原作三图层。注意返回形状：`res.card_ops` 在**顶层**（返回的是 deferred 结构本身），不是 `res.deferred.card_ops`。9测试/20断言；顺带修掉 `_clear_result_lists` 用 queue_free 导致的同帧重建 orphan。全量 53 脚本/612 测试/4520 断言（两条既有 UI 失败无关），详[操作流证据](audit/CardOpStreamCorrection.md)。缺口：逐张卡动画播放（OpCardNewController.Init）、can_visible 门、`+0x182` 缓存态与 MoveOpCardsToResults、ADD_TAG/REMOVE_TAG/POP/HAND_POP/THINK_POP/REBIRTH_SUDAN_CARD 六类记录。

## A21/A22/A23 音频提示面、向导宿主、卡面可达性（第二十八批）

A21：克隆 cue 面 25/25 全部存在（23 个 SFX 在语料 `AudioClip/`、25 个在克隆 `assets/original/audio/`）；音频提示名**不来自内容配置**（全量 config 里 `sfx/sound/audio/bgm` 字符串仅 1 处），靠编辑器引用 + `SFxManager` 运行时查表。加 `CUE_CLIPS` 注册表 + `test_audio_cues.gd`（4/43）。未接：`LoopArmageddonController`（clip 名来自编辑器字段、语料无该字符串、不可推导）、~391 个角色配音/环境 clip（文件名→调用点在未导出 .cs）。A22：credits/after_story 非空实现，`credits_page` 的两个 `pass` 是不可达基类默认（子类全重写，控制器只在 has 为真时调用）；`magic_sudan` 宿主配置一直在语料（`wizard/wizard.json` id `WIZARD`、`wizard_sudan.json` id `WIZARD_SUDAN`），已按零转译逐字节拷入 `content/wizard/`（parity 3885/0）并新增 `ConfigDB.wizard_config` + `_load_dir_by_string_id`（原 `_load_dir` 会把两个字符串 id 压成 0 互相覆盖）；`magic_sudan` 仍为审计 no-op 但已有宿主数据。A23：1292 张卡全带 `resource`，其中 110 张在原作数据里就无立绘文件，走 `card_type_*` 兜底；6 张稀有边框全在，故 `_style_for_card()` 的纸面分支**对配置卡不可达**，留作防御守卫并用 `test_card_face_reachability.gd`（5/18）钉住。全量 52 脚本/603 测试/4500 断言（两条既有 UI 失败无关），详[证据](audit/AudioWizardAndCardFaceCorrection.md)。

## A16 结局地图特效槽 + A18 池序精确化（第二十七批）

`GameScene.unity`：`Eft_End_Map`(fileID 2574, layer 6) 是 `m_IsActive:0` 的**空 Transform**（scale 200³），粒子子物体运行时实例化；`MapController.ChangeBGToEnd0x567b70` 三步（`bg`→`bg_end`、逐 location 子 Image 查 `Datapool.GetEndMapSprite`、`EftEnd@0x78.SetActive(true)`），字段布局 dump.cs 独立确认。克隆已实现前两步、缺第三步：第二十七批补 `Eft_End_Map` 槽位节点（初始隐藏/零子节点/带 `source_active_at_start` 元数据）并在 `change_bg_to_end()` 末尾激活，不发明粒子。A18：`drawn_round` 全仓只有写点无读取方，报告文案改为"存档无承载字段、记为导入当刻 round、仅随存读档往返"；`sudan_deck 顺序` 近似条目**已过期删除**（第二十批后按 uid 的 `sudan_pool_objects` 为精确逐对象比对），并加断言禁止复活。A15 补两条已确证事实：位置按**位置名** `GameController.GetLocation(controller, rite+0x50)` 取 `RiteController.position@0x40`，同地点多仪式 = `RitePosition.GetPosition(count)=(count*100,0,0)` 与 `AddRite` 的 `SetParentNormalize(..., count*100-100, 0, 0)`，**与 type 无关**；各表基准坐标在导出数据中无承载，仍未对拍。14测试/149断言 + 桥 6/86，全量 589/591（两条既有 UI 失败无关），详[证据](audit/EndMapEffectAndPoolOrderCorrection.md)。

## A14/A15 骰子子场景与仪式类型分支（第二十六批，骰子实例已定位；A15 仍待核）

`GameScene.unity`：`SudanDiceCamera`(4416) + 子 `Dices`(349) 挂 `SudanDiceRollController`(11767)，Transform localPos(1.05,-1.69,39)/scale 0.01，`SudanDicePrefab`→`Resources/prefab/SudanDice.prefab`；`Roll0x503f30` 把骰子实例 parent 到该节点。真值：DiceBaseScale 40³、CellSize 100²、HeightRange(-170,-230)、TopTimeRange(0.5,0.6)、TotalTimeRange(0.8,0.9)、RollRotationSpeedRange(400,1000)、MaxScaleRange(1.05,1.1)、WaitingTime 0.2、NormalizeTime 0.4、FullSize(1100,900)、Row 9/Column 11、RandomPos 运行时填。落点=GetRandomFinalPosition（Fisher-Yates 洗牌后按网格取点，区域=FullSize×0.5 且 y 取负），逐颗错峰=总时长/count；每帧 `SudanDiceController.GetPosition0x501b00` 走抛物线（Parabola.ctor 用水平位移与高度算 quad/lin）。克隆的 `RedrawSudanButton` 是触发 UI 非骰子，停放矩形无原作对应物故保留，迁移需独立 3D 视口批次。A15：位置分支开关 = `RiteNode.type@0x30 = RiteType{NORMAL=0,END=1,ENEMY=2,TREASURE=3}`（dump.cs 9597），配置分布 1394/41/44/16，`RiteRender.Init0x59a9e0` 按 1/2/其它分三支；各支对应位置表与 `RitePosition.GetPosition(count)` 分槽算法未核，故 A15 保持待核。详[骰子子场景证据](audit/SudanDiceSubsceneCorrection.md)。

## A12 结算播速两档（第二十五批，速率边界已验）

`RiteResultPanelController.UpdateResultTextSpeed0x5a74a0` 取一个**布尔**参数：为 0 读 `Player.result_text_play_rate@0x68`，否则读 `Player.result_text_auto_play_rate@0x6C`，夹在 `[DAT_181c92b4c, DAT_181c9e4d0]`（PE 节 RVA 读 `GameAssembly.dll` = 0.5 / 100.0）后写入 `ScrollViewTextController+0x38`。`OnAutoPlay0x5a38d0` 先写 autoPlay@0x184、再 `SetRiteAutoResult`、然后调它，并在等待中的 Promise（+0x178）上 Resolve。字段身份 dump.cs:387291-387293 独立确认。配置实测 variable.json 只有两行：1 与 15。克隆原把速率在 1.0/2.0 间自造循环、另在 `_build_dice_surfaces` 重复读配置、且 `_update` 里把档位与 `_result_play_rate` **乘两次**。第二十五批：`ConfigDB.variable_config` 正式加载、`GameState.source_result_text_rate(auto_play)` 取键并夹界、`RiteView._refresh_play_rate` 成为唯一写入点、删掉重复读取与双重相乘。5测试/13断言 + rite_view 36/175，详[播速证据](audit/ResultPlayRateCorrection.md)。缺口：OpCard 奖励演出链（A12 主体）仍未接、`ScrollViewTextController+0x38` 的消费方式未核、OnAutoPlay 的 Promise 分支未接、15× 无专属贴图。

## A10 自动字号：sizeRange 上限 + 拟合收缩（第二十四批，字号边界已验）

`TextTranslate.UpdateFontSize0x1566920`：字号先用 `css_size@0x40` 按用户档位（`Datapool+0x218`）查表、失败退 `size@0x24`；随后 `set_enableAutoSizing(enableAutoSize@0x21)`、`set_fontSizeMin/Max(sizeRange@0x28)`、`set_characterSpacing@0x30`/`wordSpacing@0x34`/`lineSpacing@0x38+每实例增量`/`paragraphSpacing@0x3C+增量`。`UpdateTextInternal0x1566ad0` 只在"非自动且 css_size 非空"时挂 OnFontSizeChanged，故自动字号不跟用户偏好。字段布局 dump.cs:393716 独立确认。配置实测 80 样式中 13 个 enableAutoSize 且**只有 sizeRange**。克隆原只取上限、显式档位不建绑定、缺档位返回 0、尺寸不更新：第二十四批补 `fit_point_size` 二分拟合（真实 Font 度量）、`_ready` 连 `resized` 重拟合、绑定总是建立、查表失败退 size。7测试/32断言，全量 583/585（两条既有 UI 失败无关），详[自动字号证据](audit/AutoSizeTextCorrection.md)。缺口：拟合是等价近似非 TMP 复刻、spacing 字段未映射、`TMPTextMaxPreferredSize` 首选尺寸截断未接。

## A20 CopyCard 复制运行时增量/计数/装备（第二十三批，复制边界已验）

`CopyCard.__c__DisplayClass4_1.c @ <Do>b__1 0x508090` 调 `CardExtensions.Copy(card,false)` 并做 `AddExtraResult_CardBorn`/`NoteCardBeReward`/用 `player.round@0x2C` 构造 TimingContext 触发 `EventTrigger.On`；`DisplayClass4_0 @ b__0 0x507430` 只是 Where 谓词。`CardExtensions.Copy 0x37f4e0`：`PlayerExtensions.AddCard(source.id)` 建新对象 → 遍历 `source.equips@+0x40` 递归 `Copy(equip,keep_count=true)` 追加（SFx/`sfx@+0x80` 非空则回调）→ 遍历 `source.tag@+0x30` 逐项写入新卡（**运行时增量被复制**）→ `keep_count==false` 时 `Card.set_count(source.count@0x20)`；`life/custom_name/custom_text/rareup/bag/bagpos` 均不在 Copy 内。克隆侧 `is_supported_key` 早已承认 `copy.s<n>`，但 `_apply_key` 没有分支（静默空操作），且实现为"从配置新建"。第二十三批补分派 + `copy_card_instance`（复制增量、count、装备递归）。6测试/24断言，全量 580/582（两条既有 UI 失败无关），详[Copy 证据](audit/CopyCardCorrection.md)。缺口：`rebirth.s<n>` 未按源复核、copy 的 `card_born` 时机链未接、非 `s<n>` 选择器未展开。

## A19 cost.* 枚举式付款判定（第二十二批，判定与交付量边界已验）

`CostCondition.IsSatisfied0x3f6160` 不是"被拖动卡牌的属性"：它以 `List_Enumerator` 顺序遍历 `player+0x88`（`Player.cards`），对每张卡跑内层 `Compare`（构造函数 `0x3f6880` 按 `>= 2000000` 分流卡牌 id / 标签，`Compare.Update` 携带 op）与附加条件列表，命中的卡计入局部列表并 `iVar10 += card.count@0x20`，到 min 停止；末尾 `SetNeedCosts(count,cards)`，返回 `min <= iVar10`。字段布局 dump.cs 独立确认：`is_cost@0x60/cost_count@0x64/need_cost_cards@0x68`。`PostProcess0x3f6520` 决定 `[min,max]`；交付量规则为 max==int.MaxValue→min、max<total→max、否则 total。配置实测 909 个 `cost.*` 键（标量 746/二元组 163、39 个选择器，金币 382 + 消耗品 370 占 83%，且金币自带消耗品标签）。克隆原只查 acting card 的标签值、不累加 count、忽略 max：第二十二批改为枚举 `cost_candidate_cards()`（hand/sudan/slot 按 uid 序，对应 Player.cards 插入序）并写回 `need_cost_cards`/`cost_count`。9测试/21断言，全量 574/576（两条既有 UI 失败无关），详[cost 证据](audit/CostConditionCorrection.md)。缺口：付款执行体（`ClearNeedCosts` 无调用方）未接、`IsSatisfied` 开头单卡分支未展开、标量 min/max 语义按"标量即下限"处理、`self_card_index@0x70` 未用。

## A13 NextDay 闭包链顺序 + 每日吸附（第二十一批，链序与吸附边界已验）

`GameController.OnNextRound0x554540` 的 Promise 闭包链（`GameController.__c__DisplayClass142_0.c`）按 RVA 与书写顺序：b__3 0x570790（终局门 → `player.round@0x2C += 1` 无条件）→ b__5 0x570850（UI/音乐/地图）→ b__6 0x570b00（终局门 → **遍历 `player+0x90` List<Rite> 逐个 AdsorbCards** → UpdateSudanLife → 手牌排序/整理/定位）→ b__7 0x570e60（TryGenSudanCard）→ b__9 0x571000（恢复周期/红点）。字段身份由 dump.cs Player(6274) 独立确认。`RiteExtensions.AdsorbCards0x38fca0` 以外层索引遍历 `rite+0x30` 槽、只处理 `Slot.open_adsorb@+0x20`、按 `player+0x88` 顺序取**第一个** CanPutCard 命中，调用点为 InitRite 与每日 b__6。克隆原只在创建时吸附、且随机取候选：第二十一批补 `adsorb_open_slots_daily`（advance_day 内、day+1 之后、结算之前）并改为取首个命中。rite_view 36测试/175断言全绿，全量 565/567（两条既有 UI 失败无关），详[链序证据](audit/NextDayChainCorrection.md)。缺口：事件派发挂载点无源未改、b__2/b__8 职责未读、每日吸附的 Note(type 4) 未接。

## A17 苏丹池对象域：List<Card> 而非 id 多重集（第二十批，对象边界已验）

`Player.sudan_card_pool@0xB0` 是 `List<Card>`（dump.cs + Player.c 构造器双信号）。`GenSudanCard0x54f6f0` 洗牌后 `RemoveLast` 取出的就是那个 Card 对象本身并直接 AddCard/MarkCardGen/PutCardOnTable；`RedrawSudanCard0x5558b0` 末尾把弃牌对象 `Insert(Random.Range(0,count))` 放回池；`SudanPoolModifyTag0x51c2e0` 与 `SudanPoolHaveCardCount0x409760` 都遍历 `player+0xB0` 逐个对象。存档证据决定性：`sudan_pool_cards` 28 项配置 vs `sudan_card_pool` 27 个对象、其中 11 个 id 重复，每对象自带 uid/count/life/tag。克隆原用 `Array[int] + sudan_pool_tags[card_id]` 把同 id 对象合并，标签操作只改一条。第二十批改为池对象数组，shuffle 移到抽取时，重抽回插对象本身，旧存档按 id 升级。22+13+6 测试全绿，语料新增 `sudan_pool_objects` 逐对象对拍，详[池对象证据](audit/SudanPoolObjectModelCorrection.md)。缺口：`param_3` 定点抽取分支未接、`sudan_pool_pos` 语义未定、池对象 life 字段未读。

## A24 卡牌标签模型：配置基准 + 运行时增量（第十九批，有效行边界已验）

CardExtensions.GetTag0x3814a0 = `Card.data+0x58`（配置行，中文名）+ `Card+0x30`（运行时增量，英文code）+ 可继承装备整行（TagNode+0x42门控，raw=true跳过掩码），非正和按TagNode+0x43掩码，最后×`Card+0x20`count；GetTags0x381940为三段键并集；AddTag0x37e6a0只写`Card+0x30`，配置字典从不被写。独立信号：dump.cs Card.tag@0x30 / CardNode.tag@0x58两字典、tag.json 442条name↔code双向唯一、auto_save uid29 `{"social":1,"charm":1}`对cards.json 2000001（社交1魅力2）。克隆原把英文code增量当整行、无基准、无×count、装备逐标签判门。第十九批拆分配置行与增量、桥接双键域、补×count与掩码、6处写入点改"写增量读有效行"、存档加tags_are_delta标记并rebase旧存档，并修掉create_card_instance把配置整行当增量的根因。12测试/38断言，含从存档JSON+配置独立重算185张卡GetTag行零不一致；全量46脚本/566测试/4298断言（两条既有UI失败与本批无关，已基线对照），详[标签模型证据](audit/TagModelCorrection.md)。key域全局统一、苏丹池对象域(A17)、copy.*标签携带仍开放。

## A08 剧情名称/描述多目标与根对象域（第十八批，数字ID根成员边界已验）

ChangeCardName.DoTemplate0x4f2130：table=Player.cards@0x88，total=PlayerExtensions.GetTotalCards0x38de90；后者复制Player.cards再追加每个Rite.cards非空对象，不进入装备。OperationFilter.Filter(List)0x3a13c0遍历全部并调用回调，不是FilterFirst0x3a1060；数字ID门还检查IsLost0x382870（GetTag(lost)>0，原tag.json=遗世）。本批纠正text/name入口的首项return、table含槽、total含装备/removed及遗世ID漏门；其他selector不借此登记完成。24测试/212断言及原作存档新增两行根成员对拍通过，详[多目标证据](audit/CustomTextScopeCorrection.md)。标签code/名称与原存档增量合成已由第十九批落地，见上条。

## A08 剧情描述键（第十七批，默认描述键边界已验）

ChangeCardName.PreDo闭包0x5089e0对type=text写同一注册key到Card.custom_text；CardInfoNewController.Show0x537000（443起）非空custom_text直接Translate后ProcessPlaceholders，与名称不同：未知键不回退配置正文。沿用Datapool.BuildCustomText/默认语言注册链，将名称/描述共用原作同类索引；不得套用名称的未知键回退规则。已接入原28个描述键，共40处/38个名称描述键，104测试/1270断言及双分辨率生产详情验证通过，详[第十七批证据](audit/CustomDescriptionTranslationCorrection.md)。多目标选择和占位符/语言覆盖仍开放。

## A08 剧情改名键（第十六批，默认名称键边界已验）

ChangeCardName构造0x4f2a30拼接change_card_ + name + _ + 配置片段，注册Common.AddCustomCardText；PreDo闭包0x5089e0写Card.custom_name为该键。Datapool.MergeCustomTextToDefaultLanguage0x417dc0将注册值并入默认翻译；Translate0x422740未命中返回键；CardExtensions.GetName0x37ff50仅在译文不等于键时采用，否则回退。原配置12处/10个唯一名称键、零冲突。已在ConfigDB建立原作同类运行时索引，保留原content不变，修正剧情名称原始存档字段及显示回退。103测试/1264断言通过，详[默认译文证据](audit/CustomNameTranslationCorrection.md)。当前语言/Mod、custom_text、多目标筛选及通知消费者仍开放。

## A08 改名状态域（第十五批，读写边界已验）

ChangeName.Do0x4f30e0直接传value；PromptChangeNameController.Show0x585890以0分玩家名，其余按配置id；SetPlayerName0x585530写Player.name@0x20，SetSpecialCardName0x585600写player_card_name@0x170。dump.cs:391488及原存档name独立交叉确认。CardExtensions.GetName0x37ff50/0x3801b0先查配置id表，再走custom_name/配置名与player名；字符串0x25828f8=player，tag.json映射主角。已修实例存在门、配置id丢失、错写custom_name，并将Player.name纳入存读档与原存档对拍。102测试/1252断言及双分辨率真实输入通过，详[状态域证据](audit/RenameStateDomainCorrection.md)。禁词、通知消费者及custom_name翻译链仍开放。

## A08 改名校验与键盘确认（第十四批，输入边界已验）

直接复核PromptChangeNameController IsValidName0x584de0、OnNameChanged0x585450、OnNameSubmit0x585490、OnConfirm0x585000及dump.cs:323419；Input的0x260为TMP_InputField.m_AllowInput（dump.cs:361469类）。输入不硬截断，长度按UTF-16单元；空串禁用且清提示，非法长度禁用并显示原ILLEGAL_NAME；Enter只移选择到Confirm，编辑状态下确认不执行。禁词加载/判定、玩家名/配置id名与当前实例写入路径差异另行追踪，不能由局部输入校验推定整链一致。86测试/1115断言及双分辨率真实Enter/点击通过，详[第十四批及状态域缺口](audit/RenameValidationCorrection.md)。

## A08 改名输入表面（第十三批，输入表面边界已验）

PromptChangeName.prefab Image114477046003934300为Simple(m_Type=0)，不是九宫格；TextArea224722951815217645折算Rect(10,7,806,77)。Text114279359913592680使用@TITLE_H3，Placeholder114094320201520353使用独立PROMPT_CHANGE_NAME_INPUT_PLACEHOLDER（xiquemuye及css_size）。TextTranslate.UpdateTextInternal 0x1566ad0按key/style选择原配置并写字体；PromptChangeNameController.OnEnable 0x585220 / dump.cs:323419确认输入由独立TMP_InputField承载。本批删除30像素九宫边框和40/20内距，分离占位文字。验证/截断、禁词、输入提交选中Confirm而非立即确认等另登记开放，不混作已复刻。4测试/28断言及1280/1920实际输入通过，详[输入表面与新发现](audit/RenameInputSurfaceCorrection.md)。

## A06 原生噪声与衰减移植（2026-09-10，第十二批，数学与点击边界已验）

UnityPlayer注册循环0xfd7bf0/0xfd7c01按同一索引读取函数表0x18d4ae0和名称表0x18db7a0；索引2144对应Mathf.PerlinNoise→0xf0490→0x5949c0。已直接调用无初始化映射的原作纯计算函数生成1029噪声样本与468衰减步骤；标准置换表、abs输入、五次插值、(noise+.69)/1.483已由机器码确认。MainUI Canvas7581为ScreenSpaceCamera、Camera4416正交size5，世界偏移需乘逻辑视口高/10并翻转Y。原机整帧验收仍未完成。

已替换双sin/线性衰减并恢复世界投影；实际输入发现并修正NextDay遮罩兄弟顺序。84测试/1082断言、1497条原生计算样本及1280/1920点击验证通过。共享时钟起点和Unity随机数流仍未同步，详[第十二批证据](audit/ShakerNativeCorrection.md)。

## A06 Shaker证据纠错（2026-09-10，第十一批）

复核dump字段与.c实参发现前次审计把maxSpeed@0x64/time@0x68对反：实际currentFreq初始2、SmoothDamp限速参数10；seed=Random.value*10-5，时间先取余float32(2π)，各轴seed+1..6，世界坐标写入。已定位同版本UnityPlayer的Perlin注册字符串，算法本体仍待追踪。新增只读可复验提取工具与[完整纠错证据](audit/ShakerSourceCorrection.md)，不将当前双sin近似标为已修。

## A09 行内删除确认按钮（2026-09-10，第十批）

UserArchiveItem.prefab组件114012617856089587/114228214996573471分别是Confirm/Close按钮，ColorTint标准色、fade .1、Navigation None，TargetGraphic分别114321827775029018/114041320612064254。114703247130969877/114641204913154593是ActionBinder，不能错当按钮；Confirm UnityEvent调用UserArchiveItemController.OnDelete 0x5c9760，Close关闭DeleteConfirm并恢复两个手柄提示holder。本批修剩余按钮着色，手柄提示树继续留档。

已修行内Confirm/Close并删除共用工厂RGB1.15分支；3/19及双分辨率实际悬停/取消/删除流程通过。输入框/滚动条及手柄提示未迁部分仍开放。详[第十批证据](audit/ArchiveButtonTintCorrection.md)。

## A09 档案按钮状态色（2026-09-10，第九批）

直读UserArchive/Item/NameInput prefab的Selectable：Close、ModifyName、Load、Delete、Cancel均标准ColorTint，highlight=.9607843、pressed=.78431374、fade=.1；名称Confirm的disabled为RGB .39215687/alpha1（不是克隆alpha.4），navigation=4。UserArchiveNameInputController.c的Show/文本更新只写interactable，不写透明度。按各自TargetGraphic修正；输入框/滚动条、显式导航图和行内删除确认另待核验。

六类已核按钮状态色修复，archive_flow 3/19及双分辨率完整GPU流程通过，包括名称清空后的实际禁用颜色。行内删除确认、输入框/滚动条及显式导航仍待核实。详[按钮状态色证据](audit/ArchiveButtonTintCorrection.md)。

## A05 交互替换装备的返回分页（2026-09-10，第八批）

CardController.CardEquip 0x528020 与 CardInfoNewController.DropCard 0x533550 均对旧装备调用 BackToHandOrBag(old,host.bag,0,true)；后者0x4eef90（dump.cs:311018）明确写bagpos/bag。普通手牌分支 AddCard 0x54ad40 在bagpos=0时设为子节点数，随后 UpdateHandCardPos 0x559a70 编号1..N。克隆旧装备沿用原bag/位置，需将交互替换返回卡放到目标页末尾并更新当前页位置；非交互DSL回收不在此规则内。

已修交互替换返回目标页及当前页编号；26测试/203断言、双分辨率真实GUI跨页换装通过。独立CardBagPanel及完整标签语义等仍待迁。详[返回分页证据](audit/EquipmentReturnPageCorrection.md)。

## A05 槽位装备来源审计（2026-09-10，第七批）

原作 CardExtensions.CanEquip 0x37ec10（dump.cs:388255）只对目标调用 IsHandCard，对来源检查装备标签/类别；CardController.CardEquip 0x528020（dump.cs:317123）与 CardDropManager.DropCard 0x4ef4f0 交叉确认同一拖动来源进入装备链。克隆 UI 和 attach_equipment(enforce_slot) 均额外要求 equipment.zone=hand。本批去除此来源域误限，保留原槽位可移动门和宿主结算锁，复用上批离槽后的面板同步。目标的 IsHandCard 标签语义、完整装备替换排序/返回分页及拖起离槽时序仍须另外审计，不能以本项覆盖。

同链新增已核偏差：CardEquip尾部调用GameController.ShowCardInfo 0x556c60；后者仅在wizardController@0x128启用时退出（dump.cs:319777），并不会因ritePanel@0x118打开而跳过详情。克隆装备成功后此前只刷新已开的详情，漏了首次自动打开。现按同一目标刷新/首次打开区分，避免将程序刷新当作点击切换而关闭面板。

本批115测试/1305断言通过，原作auto_save导入复验通过；双分辨率真实槽出装备、手牌装备自动开详情及详情内替换通过。详[槽位装备纠偏](audit/SlotEquipmentCorrection.md)。不代表IsHandCard标签、返回分页、配音或完整拖起生命周期已完成。

## 槽卡拖回手牌合堆（2026-09-10，近似审计第六批）

A05移除克隆额外的手牌来源限制；按实际实例检查槽位锁定，消费后重载原仪式面板槽位，防止来源重入手牌及重复回调重复计数。10/56合堆回归、5/24吸附、36/172仪式、6/82原作存档导入通过；1280/1920真实GUI拖动通过。原作拖起即离槽的生命周期及其他A05边界仍未完成。详[槽出合堆证据](audit/SlotHandStackCorrection.md)。

## 拖入吸附与抓取边界（2026-09-10，近似审计第五批）

A05按HandCardsController恢复原始顺序/半宽加半间距的插入判定、240×100 sticky及释放帧边界；修正虚拟占位卡、父子拖放坐标重复取样，补当前已迁移子树的Bounds抓取钳制。91测试/1145断言、双分辨率实际吸附/装备/抓取检查通过。原完整active提示子树、独立选择/手柄持牌及槽卡拖出合堆仍未完成。详[拖入吸附证据](audit/HandDragPreviewCorrection.md)。


## 卡牌根与手牌堆叠纠偏（2026-09-10，近似审计第四批）

A05已将视觉独立抬升换为原作真实扩高根，补候选命中缩放与flash进入门、归一化拖起坐标；均匀压缩改为HandCardsController原左/中/右钳制、兄弟排序与边缘Range滚动。100测试/1205断言及1280/1920根命中/双向滚动输入通过。🟡 原Bounds抓取钳制、独立选择/手柄持牌、sticky拖入判定仍未完成。详[卡牌根与手牌布局证据](audit/CardRootAndHandLayoutCorrection.md)。


## 事件布局纠偏（2026-09-10，近似审计第三批）

A07改为原Prefab反向排列和min/preferred/flexible分配：空图组仍参与、0–3立绘按native尺寸、行首选112/间距20、正文cap允许父布局压缩。A09纠正正文x352.5并恢复确认按钮ColorTint。88测试/1128断言及1280/1920实际输入通过；原机同帧与TMP/内建默认高亮图仍待验，不能登记全页完成。详[事件布局与确认按钮](audit/EventLayoutCorrection.md)。


## 首选尺寸布局纠偏（2026-09-10，近似审计第二批）

取自A08/A09，直接核对PromptChangeName/ConfirmNew prefab布局组、ConfirmController.Show 0x53fc30、TextTranslate.UpdateTextInternal 0x1566ad0及TextStyleNode/config。改名框由固定220改为正文首选高度+上下padding600；输入与错误提示归还Content父节点，关闭Godot文字父节点特有的裁剪，恢复取消原图与输入原色。无立绘共用确认框由max560与固定160正文改为正文高度+450、2000宽及原布局居中。详情/证据/测试见 [首选尺寸布局纠偏](audit/PreferredLayoutCorrection.md)。🟡 TMP字形度量、自动字号、placeholder独立字体、背景与多选项布局仍未全迁，不登记整页像素一致。


## 近似参数全域审计（2026-09-10，首批共用卡牌布局）

从下方 B/C/D 项展开 [逐项审计](audit/ApproximationAudit.md)，含24组人工条目及 ui/sim/core 逐文件自动候选；候选不等于缺陷，也不继承历史“全绿”。本批直读 CardController.CardMoveUp 0x528390 / CardResetMove 0x528480、GameController.AddCard 0x54ad40、HandCardsController.Update 0x563520、HandBagController.SetChild 0x55e360，并以 dump.cs:317111/317114/320498、CardShow prefab、原 DLL 常量交叉验证。

修正：删除不存在的 CardArea.c 背书；普通入手/重排/失败拖回不再附加 .30/.055/.16/.22 秒自制飞入、错峰、淡入、SINE 缓动；删右侧42和上下28/4起点。悬停由卡高20%改为原根增高100的居中卡面投影50（候选缩放同比，槽卡不抬起）。🟡 根命中区域增高未迁；独立 OpCard 奖励演出与原机连续输入未验，不宣称整套卡牌完成。Shaker的线性减时、双sin与归一化振幅已证实和原作不符，待噪声/世界坐标一并恢复，禁止再调目测参数。


## 卡牌原着色器算法落地（2026-09-10，环境捕获仍待完成）

已接入GUI SSU Flash118连续alpha/纹理尺度/混色公式，CardShow60/75 Gamma金属计算、法线z重建和分层Emission，移除拟合亮度/纵向渐变/detail均值补偿/无效normal_offset。原材质、绑定、场景静态适配和明确缺口见 [CardShaderImplementation.md](ui_layout/CardShaderImplementation.md)。Flash的12例和金属4例通过“执行原作汇编生成参考→实际GPU渲染”的独立对比，受控最大通道误差1/255；不是整帧像素误差。GUT90/90、1171断言，1280/1920装备拖放/候选/详情GPU通过，最终日志干净。

主清单「卡面外观/候选闪烁」仍🟡：真实SH/反射探针及HDR透明混合需要原作帧捕获。静态环境色、黑镜面环境输入及屏幕平面相机适配不能当作运行时现场值；当前没有实现探针采样链。未改content，未提交或推送。

## 卡牌光照与轮廓算法审计（2026-09-10，待实现）

主清单「卡面外观/候选闪烁」维持🟡，不能按时序/GUT通过登记像素完成。新证据见 [CardShaderAudit.md](ui_layout/CardShaderAudit.md)：离线从原作sharedassets0.assets提取并反汇编CardShow/Default及GUI SSU的9个目标程序，工具 `tools/audit_card_shaders.py`、绑定与hash `docs/ui_layout/shader_evidence/index.json`。

已核实：Flash118内轮廓=8方向连续alpha取min、width×100/纹理尺寸、原图与金色随fade混色；现有2.5px/step(.5)/纯金色算法不一致。CardShow60实际有打包法线重建、世界空间光照、金属粗糙度/Fresnel、SH/反射、自发光；现有固定half-vector、稀有度亮度倍率、detail均值补偿及纵向渐变均不能当原作算法。原代码写NormalOffset的事实不代表GPU消费：本包CardShow编译绑定未发现NormalOffset；克隆直接添加offset缺乏背书。后续从这几项替换，不再截图拟合。当前仅审计/证据工具和文档，无运行时改动；实际draw-call变体/现场环境输入仍待捕获。

## 卡面颜色采样与拖动遮挡纠偏（2026-09-10）

同批「仪式候选卡闪烁」已接：`CardSlotController.c` 两处调用 `HandCardSortByCondition(..., select_first=1)`；`GameController.HandCardSortByCondition 0x5515a0` 逐卡Reset后按validator置flash，仅首个匹配项进入SetSelectionGameObject。`CardFlashController.Update 0x52e330 / Reset 0x52e2d0` 加 `dump.cs:317254–317279` 与 CardNew.prefab 的speed3、曲线(0,0,切线2)→(1,1,切线0)构成独立背书。克隆“所有候选永久选中”已替换为单次闪烁（fade=2t−t²，约1/3秒到峰值再1/3秒归零），仅选首个候选。匹配卡的1.1倍放大来自`.c`的DAT_181c92b5c，并直接读取语料GameAssembly.dll RVA0x1c92b5c=cdcc8c3f验证；非匹配恢复1倍。`ResetHandCardScale 0x5561d0`恢复正常大小，退出仪式时接清理选中/缩放。shader轮廓宽度仍是近似，不登记为瞬态像素完成。

原作实机补证：进入治理家业→点击左人物槽，三个人物排到前面、放大，仅首张阿尔图保持选中顶部亮斑；等待后候选不再瞬态闪烁；点击取消回桌面，四卡恢复普通大小和非选中外观。此前直接把全部候选`set_selected(true)`的实现与此不符。克隆测试覆盖曲线四检查点、结束不循环、重触发重置、非匹配取消，以及多候选只选第一张、1.1倍放大及恢复。GPU工具捕获`card_reference_candidate_flash_{1280,1920}.png`并等待验证fade归零。

候选放大同步修正手牌排布：`HandCardsController.Update 0x563520` 用sizeDelta.x×localScale.x累计宽度；`HandBagController.SetChild 0x55e360` 将scaled half-height放在底锚点上。克隆间距现在计入1.1倍宽度，并补偿中心缩放的半宽/半高，底边不再被窗口裁掉。原CardNew中心pivot(.5,.5)未改，Godot保留既有稳定命中框的实现方式；放大后额外10%可见边缘的精确命中范围仍未作原作边界对拍。

投影审计发现：GameScene有两盏方向光，Light4869仅照layer30且soft shadow，Light4870包含卡牌layer5但shadow关闭；不能据“场景有阴影灯”直接给卡牌添加假投影。CardNew/控制器未找到独立shadow组件，后续需继续核实实际材质/Canvas产物，暂未新增自制阴影。

本批最终验收：UI81/81（1102断言）+候选闪烁3/3（55断言），合计84项/1157断言；1280×720、1920×1080 GPU候选动态/选中金币/装备拖动遮挡/装备详情均通过。四组材质GPU色块误差0。最终日志无ERROR/SCRIPT ERROR/orphan/泄漏；`git diff --check`通过（既有CRLF提示）。截图仅本批1280/1920为最新，2560旧图不代表本批结果。未改动content、未提交或推送，保留其他会话改动。

对应主清单「卡面外观」和「拖放」两项。已确认并修正：

- **RGB 重复采样及错误 gamma：** `card_metal.gdshader` 原来把 `sqrt(texture.rgb)` 再乘 fragment `COLOR`（已含默认纹理），导致色值约为原图的1.5次方。旧注释声称所有采样均已线性解码，无本机验证支持。新增 `tools/verify_card_material.gd` 在同一透明 SubViewport 比较原生 TextureRect 和关闭光照的卡面 shader：四个含调色/半透明的色块原误差0.061–0.108；修复为 vertex 调制 × 单次采样后四项误差均0。normal/metal/detail 同时取消错误平方根，法线和金属数据不再被人为 gamma 扭曲。原作材料参数入口仍是 `CardRender`/`CardRenderItem` 加 `.mat` 的 MainTex/BumpMap/MetallicGlossMap，未改配置内容。
- **拖动装备被人物盖住：** 原作 `CardController.OnBeginDrag 0x5294e0` 把卡 reparent 到 `GameController.drag@0xe0`（dump.cs:319768），`OnDrag 0x52a150` 用鼠标局部坐标减抓取偏移更新位置。独立信号 `GameScene.unity MainUI/Drag` 位于 HandBagPanel 后、Prompt 前。克隆原预览只有局部z20，低于手牌祖先z200，所以甲胄主体被阿尔图盖住、只露顶部；这不是“装备未接受”。共用 CardWidget 预览改为独立z300层（Godot层级适配数值），置于手牌/详情之上、阻断提示400之下，仍保留.6透明度和原抓取点。
- **验收增加真实遮挡检查：** `verify_card_reference_states.gd` 在同一次真实GUI拖放中切换预览显隐，比较人物中心400像素，要求超过100像素能看见装备覆盖。此前只检查 `gui_is_dragging` 和装备UID，无法抓出该问题。工具新增 `-- --interactive`，可直接用电脑鼠标复验相同原配置fixture。

本次 computer-use 已启动原作、进入继续存档并观察稳态；克隆使用真实电脑鼠标把家传铠甲拖到阿尔图，再点击详情，确认装备离手、甲胄位于详情人物后、体魄4/智慧3显示。原作当前存档是四张手牌，未含同件甲胄，因此本次实时操作属于原作外观观察+克隆功能走查；用户提供的三状态图仍是装备同状态参考，不能写成实时双方同存档逐帧对拍完成。

**仍未验收为像素级：** 旧材质光照系数仍是近似，本批没有添加新的亮度拟合；历史“整卡均值误差6%”在颜色管线修复后不再作为验收依据。原作光照、边缘投影、Flash触发链和完整TMP效果仍未补全。后续 Flash 背书已追到 `GameController.FlashAndSortCard 0x54eff0`：遍历当前手牌，将传入UID集合成员标为flash、逐卡Reset后置flag，不能擅自把悬停或装备成功绑定成闪烁触发。

## 卡缘常亮与重复透明度修复（2026-09-10）

用户继续指出整圈边缘不符。直接复核发现两项共用渲染错误，而非只缺少上一批的选中顶部亮斑：

- `CardFlash.mat _InnerOutlineFade=0`，`CardNew.prefab Flash.controller currentTime=0/flash=0/speed=3`；`CardFlashController.Reset 0x52e2d0` 写0，`Update 0x52e330` 按曲线写 `_InnerOutlineFade`（stringliteral 0x2581FA0）。克隆此前忽略 fade，始终画2.5单位宽的硬金圈。现恢复默认0，移除常驻伪描边；选中独立 Outline 不受影响。Flash被触发后的全调用链及瞬态外观仍未迁完，不能把初始不可见写成“永不闪烁”。
- Godot canvas fragment 的 COLOR 已包含默认纹理采样。旧 `texture.a * COLOR.a` 再乘一次贴图alpha，原图软边因此平方变硬。`card_metal.gdshader` 改从 vertex 传入调制alpha，只乘原图alpha一次；原作 card材质 `_Mode=2/_SrcBlend=5/_DstBlend=10` 为标准透明混合。RGB拟合模型本批未改。

GPU验证新增透明 SubViewport：alpha=.5纹理 × 拖动调制.6，读回须约.3（容差.015），旧链约.15。1280/1920三状态截图工具通过，UI81/81、1102断言通过，日志无 ERROR/SCRIPT ERROR/orphan/泄漏，diff检查通过。截图仍为 `card_reference_*`。材质光照、真实投影和完整瞬态闪烁仍待原作对拍，不能以本批修复宣称所有卡缘效果达到像素一致。

## 用户三状态截图纠偏（2026-09-10，视觉仍未全量验收）

用户参考：金币选中卡面、家传铠甲拖到阿尔图、装备后的详情。此前“prefab Outline 初始 inactive 所以永不绘制”和“卡名恒为 prefab fs30”的结论错误，本节覆盖这些历史结论。

| 表现链 | 原作直接背书 | 本批修正 |
| --- | --- | --- |
| 选中亮边/顶部亮斑 | CardController.OnSelect 0x52b710 / OnDeselect 0x529ef0 切换 Outline@0x140；CardNew.prefab Outline sprite=card_outline_new、256×525、pos(0,22) | 使用已存在原图，位于卡面下方 Rect(-31,-73.5,256,525)，随选中切换；初始 inactive 不等于运行时永不显示。图中顶部亮斑是该原图的一部分，不凭静态截图新增粒子动画 |
| 拖动透明 | OnBeginDrag 0x5294e0 将 dragAlpha@0x164 赋给 CardRender.targetAlpha@0x74；dump.cs CardController 字段、CardNew.prefab dragAlpha=0.6（覆写 ctor 0.5）；OnEndDrag 0x52a570 恢复1 | 预览 alpha=.6；Flash shader 同样尊重父级 alpha，避免拖动时亮边仍全不透明 |
| 详情遮挡 | CardInfoNew.prefab panel.children: Equips 224017892387517381 → MainIconMask 224709890794832471 → BottomDecorate；用户图3独立确认 | 恢复装备在后、人物在前、装饰最前，取消旧创建顺序造成的装备遮住人物 |
| 卡名运行时字号 | CardShowItem.prefab TextTranslate.key=@CARD_TITLE；textstyle.json 默认45、css_size md38等；TextTranslate.UpdateFontSize 0x1566920 | 接既有 SourceTextStyle，普通卡 @CARD_TITLE、苏丹卡 @CARD_SUDAN_TITLE，跟随设置变化，不再锁死30 |

新增 `tools/verify_card_reference_states.gd` 以原配置金币7、阿尔图、梅姬、法拉杰、家传铠甲2000368重现三状态；阿尔图智慧3是用户图3可见的对拍 fixture，非默认开局或配置改动。2560请求在本机窗口模式实际捕获2560×1421（标题栏约束），图存 `docs/ui_layout/card_reference_{gold_selected,armor_drag,armor_detail}_2560.png`。另有1920输入走查；UI81/81、1101断言通过。

**仍未通过像素级验收：** `card_metal.gdshader` 的光照仍是旧拟合模型，原作 `CardShow/Default` 导出文件为 DummyShaderTextExporter stub；没有依据把平均色接近等同于材质一致。本批未再用未经验证的亮度参数掩盖缺口。卡名的完整 TMP 材质效果、原作 dragAlpha 从1到.6的过渡曲线、逐帧材质高光也尚未完整重建。三处源链错误已修复不代表整个卡面还原完成。

## 卡牌优先批次：真实输入路由（2026-09-10）

本节更新下方 2026-09-09 拆分/堆叠批次的验收范围：直接调用 GameScreen 处理器只能验证数据，不能证明鼠标可用。原工具未发现同 ID 显示合并隐藏了拆分出的第二张卡。本批删除该显示合并，逐 UID 渲染、逐实例显示数量。

原作背书：`CardController.c OnPointerUp 0x52afe0` 在持有时间超过 `holdTime@0x15c` 时跳过详情/拆分；命中 `Stackable` 时调用 `CardSplit(1)`。独立信号 `il2cpp_dump/stringliteral.json` 的 `0x25A13E8="Stackable"`，`dump.cs CardController` 的方法/字段；2026-09-10 原作 2560×1440 实机在继续存档点击金币数量牌，8→7+1，两张卡同时可见，既有详情保留（悬起后的徽记位置与静止位置不同）。`CardDropManager.c DropCard 0x4ef4f0` 对占用槽调用 `CardSlotController.CardStack`，手牌才调用 `CardController.CardStack 0x5286b0`。

修复共用链：

- 数量牌点击拆出 1 张；Shift+点击仍为原 SplitCard 提示层未迁移前的半分适配。
- 长按松开不再误开详情；没有配对按下的松开不触发点击。
- 仪式槽中的卡面将堆叠交给槽控制器，保留条件和锁定检查，避免发射无人监听的手牌堆叠信号。
- 手牌重排动画保留稳定矩形命中，避免移动中的卡临时 IGNORE 导致堆叠被托盘当成插入；重播先取消旧 tween，防止旧完成回调覆盖新动画。此处为 Godot 输入承载修复，不宣称原 DOTween 逐帧一致。

`tools/verify_card_surface.gd` 已改成 `root.push_input` 点击数量牌、拖动拆出卡并命中另一卡、长按阿尔图再松开；不再直接调用拆分/合并处理函数。1280×720 和 1920×1080 GPU 输入流程通过，检查可见独立 UID、7+1、合并回8、真实拖拽状态、目标命中及长按不打开详情。全量回归结果见本节后续验收记录。

### 卡牌优先清单（不能按局部通过勾选全量完成）

| 范围 | 当前边界 / 下一项 |
| --- | --- |
| 卡面外观、稀有度、数量、寿命 | 原资产几何已接；方向光、高光分布及各类卡面同状态对拍仍 🟡 |
| 手牌点击、长按、拖放、拆分、堆叠 | 本批修复真实输入路由；原 SplitCard 提示层、跨页/边界完整对拍仍 🟡 |
| 仪式投放、取回、占用槽堆叠、锁定 | 卡面委托及锁定回归已接；候选条件/数量过滤尚未全覆盖 🟡 |
| 卡牌详情、改名、装备 | 本批补上手牌角色/详情接收装备、替换旧装备回手、详情即时刷新；主动卸装、提示及外部变更订阅仍 ⬜ |
| 卡牌动画 | 悬起、回位、重排与长按提示已有；原作逐帧时序、拆分专用效果仍 🟡 |
| 结算中的卡牌变化 | CardOpContext→OpCardShow→结果卡/入手牌播放链仍 ⬜，不能用 DSL 文本替代 |
| 实例功能与存读档 | 继续以 UID、原作样本和规则方法为裁判；全部内容链未完成 |

装备子批次背书：`CardDropManager.DropCard 0x4ef4f0` 明确按 CardStack→CardEquip 顺序尝试；`CardController.CardEquip 0x528020` 与 `CardInfoNewController.OnDrop 0x534410 / DropCard 0x533550` 共享 `CardExtensions.CanEquip 0x37ec10`，后者先找宿主第一种匹配槽，再以同类槽容量判断是否替换第一件装备。UI 接入既有 `GameState.attach_equipment(..., recover_replaced=true, enforce_slot=true)`，未另造装备内容或修改配置。手牌卡面与详情面板共用实时 UID 校验；仅详情本身可作为允许拖入装备的局部浮层，其余模态/已离开手牌的对象拒绝。

新增 `tools/verify_card_equipment_input.gd`：原配置 2001193 / 2000246 / 2000252，真实鼠标拖到角色装备匕首→点击角色打开详情→拖长剑到详情替换→检查匕首回手、长剑归属、详情 UID 和数值重建。在1280×720、1920×1080通过，截图 `card_equipment_1280.png` / `card_equipment_1920.png`。这是克隆实际输入与源链对应验证，装备子批次尚无原作同状态逐帧对拍；不能宣称整页像素完成。独立卸装的 RemoveCard 0x536a00 已定位，但输入回调及不可卸装门尚未完全核实，本批不猜测点击即卸装。RequestSavePlayer、RequestUpdateRite 的完整通知链仍待对齐。

验收记录：拆分/堆叠修复后全量518/518、3976断言；随后装备子批次专项：实例/门禁12/12、55断言，堆叠9/9、45断言。全量日志的3处临时 orphan 来自测试当帧查询被移出树且已 queue_free 的容器/帮助节点；对应测试补等2帧后，UI81/81、1096断言，仪式36/36、172断言，无 orphan/脚本错误/泄漏。最终相关组共138测试/1368断言，两个GPU输入工具均在1280/1920通过。`git diff --check`通过。未改动 `content/`，未提交或推送，保留其他会话改动。

## 按住提示：卡牌满足的仪式高亮（2026-09-09）

接手 DeepSeek 记录后复核：`CardController.Update 0x52c890` 比较是严格 **>0.2s**；`GameController.ShowSatisfiedRite` 正确 RVA 为 **0x5576b0**（dump.cs:320091），`CardHandler.GetCardSatisfiedRite` 为 **0x52e770**（dump.cs:317401），`RiteRender.ShowEffect` 为 **0x59cc70**（dump.cs:324645）。先前记录的 0x59be70 实为 OnUpdateBound，不是 ShowEffect。原作跳过 start 仪式、逐槽调用 GetSatisfiedSlotIndex 0x392ac0；ShowSatisfiedRite 对空列表不操作，不负责松开后取消动画。

原动画实际完整存在：`Resources/anims/rite/card_satisfied.anim`（stringliteral 0x25949A8）。IconOutline 白色 alpha 在 0/.25/.75/1 秒为 0/1/1/0、零切线，非循环，1秒 PostEffect。现删除整块标牌无限变色，重放该轮廓曲线；重复触发重置到起点，松开不提前取消。普通仪式使用 RiteNew.prefab 的 rite 精灵（rite_outlines 图集195x273）、152x208矩形、pos(0,-23.6)、pivot(.5,0)，放在标题之后图标之前。CardWidget 暂停及开始拖拽清除待触发计时，GameScreen 阻断时不触发背景提示。6项专项测试覆盖阈值、取消、自动结束、重播与曲线采样；GPU工具改为 root.push_input 真实鼠标命中，检查按住触发与自动结束。

保留差异：动画 TitleBG/Title/TitleOutline 路径与此份 RiteNew.prefab 的 TitleBG/TitleOutline 不同，标题轮廓是否实际绑定需原作运行时验证，未猜测启用；type1/2 专用图标尺寸与偏移仍未完整映射。GetSatisfiedSlotIndex 的 CanPutCard/adsorb_spec 与部分数量匹配上下文尚未完整迁移，因此不能把候选集合称为全条件一致。其他按住分支、拆分输入层和装备交互仍待补齐。

接手验收：原记录最后的后台回归已结束，原基线504/504、3838断言。修正后完整GUT506/506、3850断言，零引擎错误/泄漏；最后锚点修正后专项6/6、26断言，1280x720 GPU日志无警告。1920x1080与1280x720真实鼠标按住均命中阿尔图并显示事件轮廓，截图 `card_hold_1920.png` / `card_hold_1280.png`。这些是克隆输入与曲线回放证据，不是原作同状态逐帧对拍。尚未完成的全卡面/全交互目标继续保留，不能按此前整卡颜色均值差小于6%宣称像素级完成。

## 卡牌堆叠/拆分交互（2026-09-09，源语义落地）

`CardController.CardSplit 0x528580`：要求 `count > n`，源卡 `count -= n`，副本走 `CardExtensions.Copy`（bag/bagpos 一并继承）后由 `CardDropManager.BackToHandOrBag` 放回手牌；`OnPointerUp 0x52afe0` 在"可堆叠且 count>1 + SplitCard 提示（A+B）被按住"时调用 `CardSplit(count/2)`。`CardController.CardStack 0x5286b0`：同卡 id 且双方带 `可堆叠` 时 `目标.count += 源.count`，源卡 `PlayerExtensions.RemoveCard` 移除、目标回到自己的 bag/bagpos；`CardDropManager.DropCard` 对**手牌目标**调 CardStack、对**已占用的仪式槽**调 `CardSlotController.CardStack`。`CardController.Update` 另有 0.2s（0x3e4ccccd）按住阈值 → `GameController.ShowSatisfiedRite` 提示（宿主未接，见下）。

落地：`GameState.split_card_stack(uid, amount=-1)`（默认 count/2）与 `GameState.stack_cards(target_uid, source_uid)`（同 id + 双可堆叠 + 移除源卡）；`CardWidget` 增加 `stack_dropped`（拖到同 id 可堆叠手牌上合并，`CardDropManager` 手牌分支）与 `split_requested`；`rite_view.drop_card_on_slot` 对已占用且同 id 可堆叠的槽改为合并（`CardSlotController.CardStack`）。新增 `tests/test_card_stacking.gd`（7 测试 / 33 断言）覆盖拆分计数与 bag/bagpos 继承、`count>n` 门槛、合并移除源卡、非同 id/非可堆叠拒绝、拖放门禁；`tools/verify_card_surface.gd` 追加端到端：经生产 GameScreen 的处理器拆分 8→4+4（对象数 2、总数不变）再合并回 1 个 8。

🟡 宿主适配：原作拆分手势是手柄/键盘的 SplitCard 提示（A+B）按住后点击；宿主还没有输入提示层，暂时绑成 **Shift+左键**点击，已在 CardWidget 与测试里注明。⬜ `CardController.Update` 的 0.2s 按住 → `ShowSatisfiedRite` 提示未接。

## 手牌卡面 1:1 第四批（2026-09-09，材质光照分布 + 详情面板装备缩略图）

**材质光照分布**：用立绘 alpha 把一张卡（梅姬）切成 8 条竖带，只统计"立绘透明、纯底板"的像素，在克隆渲染与原作 `desktop.jpg` 同坐标下逐带求均值。原作底板是**自上而下变暗**的（带均值 R 0.454→0.564→0.445→0.365→0.378→0.322→0.224→0.169），而克隆此前是均匀灯光，导致卡顶偏暗、卡底偏亮。按带比值线性拟合出三项并写进 `ui/card_metal.gdshader`：`vertical_light_falloff` 0.2065（顶 1.21×→底 0.79×）、`metallic_diffuse_loss` 0.3（metal.r=1 时削去 30% 漫反射，对应原作金属件的暗化）、`specular_strength` 0.3（保留高光但不再过亮）。逐带误差从约 21% 降到约 15%，六张卡整卡均值仍在 ±6% 内（梅姬 94/97/66 vs 96/100/66、阿尔图 88/90/95 vs 90/95/101、金币 140/119/57 vs 142/132/60、铁头 96/90/62 vs 97/92/62、快脚 101/86/78 vs 106/90/78、小圆 111/93/77 vs 116/98/76）。

**详情面板装备缩略图**：`CardInfoNew/Equips` 的缩略图本来就是同一条 CardWidget 链（`ui/card_info_view.gd` `_build_equips`，源几何 RefreshAllEquips 0x534c40 / .cctor 0x537e30 双列旋转），因此自动继承前三批的壳层修复。新增 `tools/verify_card_detail.gd`：给阿尔图装两件饰品 → 打开生产 CardInfoView → 校验每张装备缩略图都有 RarityFrame+材质、CardArt、CardNew/Flash，且尺寸为 194×422，并输出 `card_detail_2560.png`。原作参考 `original_runtime/card_info_artu.jpg` 那一帧没有装备，故装备缩略图只做结构+源几何验证，不与原作逐像素对拍。

保留差异：逐带亮度分布仍是拟合近似（无方向光模型，卡顶/卡底两端仍各有约 15% 偏差）；装备缩略图缺原作同状态截图。

## 手牌卡面 1:1 第三批（2026-09-09，寿命牌 DotText）

`CardShowChar/Item/Sudan` 的 `LifeBg/Image/DotText` 是 TMP 文本 `'<sprite=21>'`，其 `m_spriteAsset` 指向 **`Resources/sprite assets/rite_settlement_icon`**（不是 number_6）：该 sprite asset 的 character table 第 21 项是 `dot_0.png`（图集帧 471,107,50,30），fs28，`m_fontColor` 白——即原作寿命牌左侧时钟下方那枚 50×30 的黑色小药丸。落地：复制 `Resources/image/rite_settlement_icon.png/.json`（SHA256 与语料一致），在 LifeBg 内加 `DotText` TextureRect（LifeBg 局部 (-7.2,23.1)、50×30），位置由 Unity 锚点 (0,0)+pos(36.8,5.4)+pivot 中心折算。

验收：`tools/verify_card_surface.gd` 给小圆临时加 7 天寿命（改的是 game screen 自己的 ConfigDB 实例，不是工具的），校验 LifeBg 98×45@(57.5,-45)、Life 数字为 6、DotText 位置/尺寸；截图 `card_surface_1920.png` 与原作 desktop.jpg 第六张卡的寿命牌逐元素对照（时钟 + 绿色条 + 数字 + 小药丸齐备）。卡牌 UI 专项 80/80、1011 断言。

保留差异：材质高光/法线的空间分布仍是均匀近似（卡顶条带比原作暗约 20%、卡缘略亮）——要逐区一致需要方向光模型；卡牌详情面板的装备缩略图复用同一条 CardWidget 链，但尚未按 `original_runtime/card_info_artu.jpg` 单独对拍。

## 手牌卡面 1:1 第二批（2026-09-09，细节贴图/数字精灵/手牌基线）

第一批之后的三项收口：

1. **手牌垂直基线**：GameScene `MainUI/Hand` 锚 (0,0)-(1,0)、pos (-63.97,4)、sizeDelta (-1116.74,430)、pivot (0.52,0)——内容矩形底边距画布底 4 单位，卡牌贴其**底边**而非居中。克隆原来居中，1920 下比原作高 2px；改 `_card_items.size.y - card_size.y` 后卡顶 865→867px，与原作 867-868 对齐。
2. **`_DetailAlbedoMap`（`_DETAIL_MULX2`）**：12 个卡材质的 detail 贴图逐档取真值——char copper/gold=card_d_1、char silver=card_e_0；item copper/gold=card_d_6、item silver=card_d_2；sudan copper/gold=card_d、sudan silver=card_d_3；stone 档无该贴图也无该 keyword。已复制 6 张纹理（SHA256 与语料一致）并在 shader 里按 `_UVSec: 0` 同 UV 做 `albedo × detail × 2`；灯光按 detail 均值除回，保持场景光常量。
3. **数量底章按卡类分派**：`CardShowChar`/`CardShowSudan/Stackable` 是 number_bg 80×80@(57,332)，**`CardShowItem/Stackable` 是 checkbox_bg 75×78@(59.5,332)**——第一批统一用 number_bg 是错的（金币卡就是 item）。数量与寿命数字改用 `ui/source_number.gd` 的 TMP 数字精灵（spriteAsset 737d2853=number_6，fs48/fs52，`Utils.NumberToSprites 0x3ac420`），字号换算按原作截图校准到 glyph_height 58/63（克隆原来 48/52，数字明显偏小）。

验收：`tools/verify_card_surface.gd` 六张卡（梅姬/阿尔图/金币 count=8/铁头/快脚/小圆）同坐标整卡均值 vs 原作 desktop.jpg：梅姬 99/103/70 vs 96/100/66、阿尔图 94/98/104 vs 90/95/101、金币 143/121/57 vs 142/132/60、铁头 100/95/65 vs 97/92/62、快脚 106/89/81 vs 106/90/78、小圆 116/97/80 vs 116/98/76——全部在 ±6% 内。截图 `card_surface_1920.png`、对比图 `card_surface_compare.png`。

保留差异：材质高光/法线的空间分布仍是近似（顶部条带比原作暗约 20%，卡缘条带略亮）；`LifeBg/Image/DotText`（`<sprite=21>`）未接；装备槽、详情面板的卡面复用同一条 CardWidget 链但未逐屏对拍。

## 手牌卡面 1:1 第一批（2026-09-09，卡面壳层已验收）

CardNew.prefab（docs/ui_layout/CardNew.md）根 194×422，两个旧实现漏掉的壳层：**Outline** 256×525 pos(0,22) 的 `m_IsActive: 0`——原作从不绘制；**Flash** 256×512 pos(0,0) 且 `m_IsActive: 1`，sprite=Sprite/card_outline.asset（Texture2D/card_outline.png，256×512）+ Resources/materials/CardFlash.mat（keywords `_ENABLEINNEROUTLINE_ON`/`_INNEROUTLINEOUTLINEONLYTOGGLE_ON`，`_InnerOutlineColor` 0.882/0.728/0.337，`_InnerOutlineWidth` 0.08）——原作卡面边缘那圈金色内描边就是它，不是 Outline。CardShowChar/Item/Sudan 的 **Stackable 是 80×80 的 Sprite/number_bg.asset**（68×68 纹理）底部锚 +50 → 左上 (57,332)，旧实现的 checkbox_bg 75×78 是错的底图。12 个 `materials/card/{char,item,sudan}/{stone,copper,silver,gold}.mat` 的 `_MainTex`/`_BumpMap`/`_MetallicGlossMap`/`_BumpScale`/`_GlossMapScale` 已逐档取真值（stone 0.9027777/0.3020833、copper 0.3819444/0.7847222、silver 0.2847222/0.8090278、gold 0.3680556/0.75），材质对**所有稀有度**生效——旧实现 `rare<2` 直接 return 是自制捷径。

色彩空间坑（本轮最大发现）：canvas_item 自定义 shader 里 `texture()`/sampler 采样已被解码到线性空间，而默认 2D 管线在 sRGB 空间，同一张底板挂 shader 会暗到约 0.4 倍；`ui/card_metal.gdshader` 用 `to_display()`（pow 0.5）还原后与不挂 shader 的同一纹理逐像素一致（探针实测 flat 0.5 → 0.2471 → 0.498）。`_DETAIL_MULX2`/`_EMISSION`/Standard 光照无导出函数体（DummyShaderTextExporter），故灯光项按原作截图逐档校准 `material_light`。

验收：`tools/verify_card_surface.gd` 在 1920×1080 用与原作 `original_runtime/desktop.jpg` 相同的手牌（梅姬/阿尔图/金币 count=8/铁头/快脚/小圆）渲染并截图 `docs/ui_layout/card_surface_1920.png`；同坐标整卡均值实测 克隆 vs 原作：梅姬 93/98/76 vs 96/100/66、阿尔图 92/95/105 vs 89/94/100、快脚 112/95/86 vs 118/98/77、金币 94/90/70 vs 98/92/62；立绘区域逐像素一致（82/70/58 vs 81/68/55），说明差异只在底板材质。卡牌 UI 专项 80/80、1006 断言。

保留差异：手牌整体比原作高约 2–3 px（1920 下，`HAND_MASK_HEIGHT` 470 与内容偏移 36 待按原作复核）；`_DetailAlbedoMap`（card_d_*/card_e_0，`_DETAIL_MULX2`）尚未接入；TMP 数字精灵（`<sprite=9>`）仍以文字替代；材质各向异性/环境反射与逐帧对拍未完成。

## 地图投影与事件标牌（2026-09-09，局部链已验收）

GameScene Desktop Camera Transform3970/Camera4419：位置(97,-106)、正交半高1732；Map7621缩放1.25、位置(0,-178)。建筑按Image子节点尺寸及偏移绘制，不使用Location容器尺寸。RiteRender.OnUpdateBound 0x59be70（dump.cs:324578）将bound宽设为TitleBG宽+Icon宽/2，中心X=(bound宽-Icon宽)/2，再调用MapController.SetRitesPosition 0x56a200 / SetPos 0x569cd0；GameAssembly RVA0x1c92b4c浮点常量实读0.5。原先123×133仅为初始bound，不能代表标题展开后的碰撞范围。RiteNew根子序TitleBG→IconOutline→Icon；RiteShows/TextTranslate按@RITE_TITLE读取字号。rites图集JSON标注2048×4096，实际PNG为1024×2048，裁切坐标必须同比换算；本地全部PNG/JSON配对检查仅此图集尺寸不符。

验收（2026-09-09 续批，接手被中断的会话后完成）：tools/verify_situation_desk.gd 在 1920x1080、1280x720、1600x1000（16:10）三种窗口下做真实鼠标回放——SituationDesk 始终填满 3840x2160 画布（canvas_items expand，窗口只做整体缩放）；自宅同点 4 个仪式（5000003，范围 [2,12]）展开后的 bound 两两不相交；每张 RiteNew 的图标面与标题条分别点击都打开正确实例，关闭后 overlay 确实消失。截图 desktop_map_{1920,1280,1600}.png 与原作 original_runtime/desktop.jpg 同比例裁切比对：建筑位置与尺寸吻合，事件标牌高度差在 5% 内（原作 2560 宽截图标牌实测约 33 原生px → 49.5 画布px，克隆 52 画布px）。另独立复核 assets/original/ui 下 12 组 PNG/JSON 配对，仅 rites 一组尺寸不符，故共享裁图换算只影响该图集。全量 GUT 492/492、3667 断言，零引擎错误/泄漏/orphan 门禁通过（含 test_hand_pages 把旧自制 42px 与 3840÷4200 缩放常量改为 @RITE_TITLE md=40 与 2160×1.25÷3464 的世界投影）。

保留差异：图标徽记在图集帧内的留白、TMP 基线、材质发光以及图标与标题条的重叠像素级对位未逐帧对拍；不同存档的事件名与数量不同，只比对结构不比对状态数值。此条不升级为"地图整页 1:1"。

## 桌面顶部三项修正（2026-09-09，局部链已验收）

菜单/帮助锚节点的鼠标排序按引导修复同理置于SituationDesk之后、模态层之前；MenuButton关闭flat模式，恢复checkbox_bg底图。声望以PrestigeItemController.Init 0x582f50 / OnCounterChanged 0x583460的NumberToSprites和SetNativeSize为背书，GameScene Image底托52.5x54.6、Count40x50；TMP精灵GUID737d2853对应number_6，7100006源图160x236且旧宿主缺图。新增7100006、number_6及number_6_red的PNG/JSON共五份文件均与语料SHA256一致。

处刑日以GameController.UpdateSudanLife 0x55aeb0为背书：遍历手牌和仪式，选择sudan标签且life最大者，显示card_vanishing-life / Player.sudan_card_init_life（dump.cs Card+0x24、Player+0x64）。宿主沿现有sudan类型匹配器筛选hand、active_sudan_cards、仪式槽，替换旧life+1。标题取ui.GAME_MAIN_HEAD_TITLE与textstyle.@EXECUTION_DAY_TITLE；路径按variable MAIN_UI_TITLE_NUMBER_*和countdown_pics精灵表，数字剩余不足三天切number_6_red。固定204高度、LeftSpace150/RightSpace180、NumberSprite最小1115、上边距37、九宫格源边界227/245/52/71；GameScene GO87/101/225的标题装饰为inactive，保持不显示。最后一天标题和数字使用RedText.anim的0/0.25/0.5/0.75/1秒缩放曲线1/0.95/1/1.05/1，中点切线0.2。顶部更新仅重排自身，避免触发SituationDesk重建。

验收：完整GUT490/490、3605断言，零引擎错误/泄漏（header-full-check.log）。tools/verify_desktop_header.gd在1280x720与1920x1080从main.tscn真实点击菜单、返回和帮助，并验证7/6/3/2/1天图集、最后一天动画、仪式槽内较老卡、不同分母、隐藏及无卡状态。截图desktop_header_{1280,1920}_day*.png与原作original_runtime/desktop.jpg作结构参考，不同存档不比较状态数值。parity3882文件/0违规。

保留差异：TMP字体/精灵的精确基线、数字零的对齐、材质发光、整条进度的过渡动画及原作同状态逐帧对拍未完成；sudan筛选沿宿主现有类型边界，未宣称完整HasTag复合语义。此批不能升级为桌面整页1:1或所有交互问题均已解决。

## 引导关闭命中修正（2026-09-09）

BeginGuideController.OnCloseBtnClick 0x525fa0 / dump.cs:316765 是已有关闭入口，本批不改关闭语义。GPU鼠标回放证实宿主的 Default/Close 虽然显示在上层，命中却落在后创建的 SituationDesk；仅设置 z_index 未改变 Control 输入顺序。将引导节点移到桌面之后、两个模态层之前，保留视觉坐标和模态遮挡。验收脚本 tools/verify_guide_close.gd 覆盖中心、伸出面板的按钮边缘和刷新后保持关闭。

验证：1280x720、1920x1080 GPU输入回放通过，事件提示遮挡时不会点击穿透，提示关闭后恢复叉号命中；guide_close_before/after截图留档。UI回归79/79、923断言，stderr空、无引擎错误或泄漏。仅修宿主输入层级，不据此声明完整教学时机链已还原。

## ConfirmNew按钮行（2026-09-09，已接局部链，整页未完成）

ConfirmController.Show 0x53fc30调用AssignTranslateText分别设置确认/取消文字；Done 0x53fb70清Promise后Resolve(bool)，dump.cs:318365。ConfirmNew.prefab Operations锚(0,0)-(1,0)、pos(801,-6)、sizeDelta(983.4226,144.2)、pivot(.5,0)；横排间距60、右padding120、MiddleCenter，Cancel168x158在前、Confirm325x158在后。计算源2705宽时Cancel左1817、Confirm左2045、顶H-145.1。两标签24号、源颜色alpha0；手柄InputDisplay仍未移植。宿主已补正文居中与独立确认分支；精确PreferredSize、遮罩与短面板最终高度仍待实机校准。专项10/10、80断言通过。

## 提示人物与卡组参数（2026-09-09，进行中）

PromptControllerBase.ShowInternal 0x589890按三个位置处理外层数组，标量字符串只放中位；full前缀由TrySetupFull 0x589d60处理（stringliteral 0x25ACD30）。PromptIconController.SetIcon 0x58a210处理单位置：字符串pic/前缀（stringliteral 0x25821F8）先FindCard再配置GetPic，数字数组生成配置卡而非运行时卡，最多三张、零值跳过但保留索引。静态PosYRotZ由.cctor 0x58ab00给出(280,18)/(430,10)/(580,2)，一张取中、两张取中和末，scale=1.8、后生成移到首子节点。dump.cs:323572 Holder/Icon/PosYRotZ；content/event/5300000及5300177给出外层图像数组实例。当前先补参数解释和既有素材展示；外层IconGroup与正文的完整原布局分配仍未移植。

FindCard 0x38c740补查：Player.cards@0x88优先，其后依Player.rites@0x90枚举Rite.cards@0x30（dump.cs Player/Rite字段独立核对）。不能使用宿主全实例注册表按UID查询；消费后残留条目不应覆盖配置立绘。

## 事件正文高度与富文本（2026-09-09，已接局部链，整页未完成）

取 ScrollViewContentHightWatcher.LateUpdate 0x4342c0（dump.cs:420520，LastHeight+0x20 / MaxHeight+0x24 / layoutElement+0x30）：正文内容高度写回 preferredHeight，上限来自 PromptNew.prefab:1790 的1300。PromptController.Show 0x58a020重建布局；正文@PROMPT_TEXT、选项@OPTION_ITEM_TEXT由两个prefab的TextTranslate键确认。先替换固定正文高度和失效的滚动输入，选项随正文下移、底部装饰随面板下缘移动。外围水平位置、选项行高及根布局分配仍沿现有近似，不宣称完整LayoutGroup复刻。保留选择后确认及队列等待语义。

增量普查发现OptionNew.prefab:1780的MaxHeight是1100，并非PromptNew的1300；Options节点GO1313026266067498 / LayoutGroup114855482821919830间距20。OptionController.Show 0x576b50将OptionNewItem挂到options根（+0x90，dump.cs:321643），不能沿用ContentGroup的50间距。ConfirmNew没有这个ScrollView高度观察器，继续作为独立表面缺口，不用普通提示的参数声称已映射。

上限分流与20间距已接。最终UI79/79、923断言；此前完整回归487/487、3574断言；两分辨率GPU长正文及原配置5300102的实际选择/改选/确认/提示后event_on均通过，stderr空。测试只证明所述宿主路径，外围几何与人物图组未达原作一致。

## 卡牌详情标签与数值差异（2026-09-09，已接局部链，整页未完成）

本批取 CardInfoNewController.RefreshAllTags 0x535270：TagNode+0x40/41/43 控制显示，Variable.card_state_icon 优先分到状态栏，type=attribute 分到纯名称行，其余分到徽记网格；排序比较器 0x393940 返回 b.tag_rank-a.tag_rank（dump.cs:386926）。GetTagWithDiff 0x3811e0 的差值是当前 GetTag 减 Card.data 的配置值（Card.data+0x68，dump.cs:389593），不是只统计装备。CardTagNewController.FormatValue 0x53ec20 按差值正/负/零使用原 variable 文本颜色。Show 0x537000 的 Title 仅取 CardNode.title。状态图由 CardStateTagController.SetState 0x53dbb0 读取 variable.card_state_icon；原配置 sacrifices 指向拼错的 staet_sacrifices，语料只有 state_sacrifices，保留为源资源缺口，不擅自改配置。

已接上述分组、排序、差值色及静态箭头，状态按正值重复；16张槽位/状态/箭头纹理与语料hash一致。装备区依 RefreshAllEquips 0x534c40/.cctor 0x537e30 摆放真实CardWidget；槽位依GetEquipStats 0x37fa50逐装备一次匹配、CardEquipSlot.SetType 0x52dc70/set_Equiped 0x52e090切换原图。RareIcon经CardShows_FaceUnlit.asset:123和dump.cs:541824确认石/铜/银/金数组；RareText原色黑。装备拖放、取回、提示和动态数值变化监听仍未完整接到此视图。

帮助页原作实机证据original_runtime/card_info_help.jpg：原来的1920再翻倍假设错误，Help嵌套Canvas是WorldSpace/overrideSorting而非独立1920画布。按3840根空间的anchors/pivot重放四段、50%黑遮罩、card_info圈线、@HELP_TEXT与content/ui.json全文；RichTextLabel补TMP Overflow绘制边界，实际打开/遮罩关闭/详情关闭已通过。共享富文本转换仅转换完整已识别样式token，保留普通比较符和不支持的sprite/相对字号token，不宣称完整TMP解析器。UI78/78、912断言（card-complete-ui.log），全量回归进行中。

## 仪式滚动正文（2026-09-09，已接块布局，TMP差异未完成）

取 RitePanelTitleController.Show 0x5992a0（dump.cs:324417），拼接variable.RITE_PANEL_TIPS_TEXT_HEADER/ICON/CONTENT/FOOT；RitePanelTitle.prefab正文@MAIN_BODY、paragraphSpacing80、viewport宽比ScrollView少17。TextTranslate.Start 0x15667e0缓存TMP初始段落间距，再在UpdateTextInternal加TextStyleNode段距。提示CONTENT indent120，ICON size100，颜色#FCE29A；sprite索引3=分隔线、12=rite_tips。原作截图rite_household_font_reference.jpg交叉核对。宿主将这些块放进同一滚动树；TMP sprite基线与逐字行高仍需单独校准。

宿主实测lg正文两行的contentHeight=214，含末段80；因此VBox不能再加80。取消重复间距，分隔图后用Margin保留80；此修正只消除宿主双计数，未宣称TMP按字体face比例的段距算法已完整移植。

## 卡牌详情属性结构纠正（2026-09-08 实机）

原作右击阿尔图截图 original_runtime/card_info_artu.jpg 显示带徽记的四列属性与底部名称标签。此前把 CardAttribute 无图结构推广到数值属性区的结论错误：CardInfoNew.prefab:1311 TagPrefab GUID06679e1929ab016419ec8700bfc39f3f 指向 CardTag.prefab，AttributePrefab GUID7b2c7f38735de4144bc235b272548f0e 才指向 CardAttribute。RefreshAllTags 0x535270（dump.cs:317550类字段）为前者调用 CardTagNewController.Show 0x53f040，后者用于纯名称标签。

已恢复 TagContainer 的1700x419.49容器、400x120网格/水平间隔20/MiddleLeft、四列徽记+名称+值，标签按 Attributes authored底部矩形摆放。图标从 TagNode.resource 读取tags图集（含支持，旧CardWidget属性helper未包含支持）。导出CardTag.md作为几何证据。当前仍只展示原有六属性集合，完整can_visible/can_add/can_nagative_and_zero分组、tag_rank排序、状态栏、装备diff箭头/颜色/点击提示未迁，不标整详情完成。原作样本有装备加成，克隆开局样本不同，截图仅验证结构。

CardInfoNewController.Show 0x537000 L556-575 读取 Variable.ui_size@0x58（dump.cs:387285）按 Datapool.fontSize@0x218 设置整面板scale；原配置md=1/lg=1.1/xl=1.2/xxl=1.3。已接打开时以中心为轴整体缩放，不能把原作lg截图和克隆md截图的大小差异当成静态prefab错误。

共享SourceText发现自动字号样式可能只有enableAutoSize/sizeRange而没有size：原0回退会使文字近乎不可见，现从上限起始；完整TMP缩小拟合算法仍缺失。最新卡牌截图card_info_grid_1280.png；专项记录见card-info-grid-tests.log。

## 应用字号联动（2026-09-08）

GameApplicationConfig..cctor 0x300380 写 GAME_FONT_SIZE@0x78，stringliteral 0x25C2418 为 md；dump.cs:542495/542496 定义字段与 GameFontSize 偏好键。SettingDropDownController.InitFontSizeDropDown 0x5a96a0 枚举 variable.support_font_size，显示“小”对应 md，“普通”对应 lg，不能按界面名称推断代码。GameApplication.SetFontSize 0x43ee10 经 Datapool.OnFontSizeChanged 更新文本后写 PlayerPrefs；TextTranslate.UpdateFontSize 0x1566920 按 css_size 查找并回退 size。

已接应用偏好持久化、源配置五档下拉、已打开仪式/设置页的动态字号、关闭页面时订阅释放；固定标题不随档位变化。KeyItem 样式纠正为 @MAIN_BODY。SourceText.apply 显式指定档位仍用于独立样式测量，运行时省略档位即订阅偏好。其他未使用 SourceText 的页面尚未逐节点迁移。下拉背景导入 dropdown_bg，hash A7556C6DD1AF99EF28CB73AC08294DA5EF4B94FF5433AC16629E2E1DFD116864 与原图一致；PopupMenu 选项位置/滚动模板尚未达到源 TMP 布局。

专项2/2、15断言；全量482/482、3537断言（34脚本，2条既有警告，无引擎错误或泄漏）。GPU 测试隔离偏好文件，鼠标打开菜单后经输入分发器选择普通，确认 lg 生效；直接向弹窗 viewport 注入按键不经过原生窗口分发，已修正测试输入方式。

## 设置页新版结构（2026-09-08 实机续批，部分已接）

实机 1.0.2feaceb3 使用 SettingsPanelNew，旧宿主依据 SettingsPanel 的单面板结构不匹配。依据 SettingsController.ShowSettings 0x5ab420 / OnEnable 0x5ab270（dump.cs:325897），SettingsPanelNew.prefab 的分页 ToggleGroup→SetActive 序列，SettingToggleGroupsController.Start 0x5aadc0，以及 KeyMapController.OnEnable 0x565aa0 / KeyItemController.SetKey 0x5656e0 + Resources/InputActions.asset，迁移三分页、原图背景、源字号与键位列表。实机截图见 docs/ui_layout/original_runtime/settings_*.jpg；新版几何见 SettingsPanelNew.md / KeyItem.md。原作存档与注册表在启动前已备份于 C:/Users/User/Documents/Faust-backups/original-ui-20260908-212447。UI76/76、显示设置6/6；两种GPU分辨率实际切页/滚动/关闭通过。功能与视觉缺口详见 PageFidelity，整页尚未完成。

RitePanelTitleController.Show 0x5992a0（dump.cs:324417）：text@0x48绑定ScrollViewTextController，源实际样式@MAIN_BODY；@RITE_TEXT在OpenTips，已修正旧正文误用。Stop@0x70仅start且start_round等于Player.round才显示；LastState@0x60按!start显示且有缓存才可操作。已接两个显隐门及停止处理函数边界，仍保留完整富文本/字号档/预览提交链缺口。

## 事件提示运行时背景（2026-09-08 续批）

`PromptControllerBase.Awake 0x589430` / `UIImageExtensions.LoadSprite 0x40c210` + stringliteral 0x25ACDA8=`full/item_bg`：FullImage 父容器首位动态加载背景，LoadSprite 的 native-size 后才设置 stretch anchors。PromptNew Full 的 Mask m_ShowMaskGraphic=0，Sprite prompt_bg_mask_2 border=(284,234,248,255)，矩形按锚点换算为(38,52)/2629x828；旧克隆误把 mask 画成黑块且 y/高度符号反了。已导入源 item_bg.png（SHA256 7E4B1EBC32F2D695EECEEA3221EBFA5ADECA66077A4644D0C80F9DCD3B67C024），恢复仅裁切子项与底图。Prompt.Do 0x519340 的 icon@0x20 保留到显示层，当前标量图已接；数组/嵌套图及 full CG 仍缺。事件专项10/10、72断言；原配置事件5300102的鼠标选择/确认/后继提示/事件启用两种分辨率通过，截图与限制见 PageFidelity。

## 仪式成熟门与前置分支（2026-09-08 续批）

- `GameController.UpdateSingleRite 0x55ab10`：started 且 life < round_number 时不结算；独立字段 `dump.cs:392403` life@0x2c / `393174` round_number@0x44。RiteView 重开入口与确认按钮共用该门，0/1天拒绝、2天允许的专项通过；修复“重开正在运行的仪式便能提前领结果”。
- `DisplayClass77_0.<DoPriorSettlement>b__7 0x5b6120` 成功返回 true；`DisplayClass56_0.<Settlement>b__1 0x5b34e0` 仅在 false 时进入普通结算并 Then DoExtraSettlement。script.json 的 MethodAddress 5907056 / Address 39473456 对应 DoExtraSettlement / DAT_1825a5130；克隆命中前置后跳过普通与仪式额外结算，卡牌自带额外结算是另一链，不据此跳过。
- 串行链调查纠正：DoExtraSettlement 0x5a2270 的逐条 DoSequence 是 **PreStart/展示/EnqueueSettlement**。EnqueueSettlement 0x5a2d10 将 Settlement.result@0x30 与 action@0x38 分别排入 controller+0x110/+0x118，之后 DisplayClass56_3 b__13 0x5b4f20 / DisplayClass56_5 b__15 0x5b5070 才 Start。不能将其解释成逐条实际 result+action。现有同步 resolver 缺独立预演及提交阶段，完整迁移需同时处理预演语义、骰子、上下文、队列与存档；本批未把这部分标成完成。

## 仪式结果等待边界（2026-09-08，部分接通）

`RiteResultPanelController.Settlement 0x5a4800` / `RiteResultPanelController.__c__DisplayClass56_0.<Settlement>b__8 0x5b4850` 在尾段 RemoveRite。宿主 rite_view 已在 pending_operations 非空时锁确认、取消、金骰、重掷；零日 auto_result 延后关闭，结果产生后刷新提示。GameScreen 阻塞提示固定前景并吸收背景点击，解决仪式升层后的视觉遮挡。仪式专项28/28、110断言；两种分辨率的实际鼠标路径和截图见 [页面验收](ui_layout/PageFidelity.md)。仍缺 RiteResolver 串行执行、post_rite 清理等待、NextDay、结果预览读档与重新打开时成熟门；不登记整链完成。

## 仪式空槽与运行中编辑（2026-09-08，部分接通）

后续排序批次：`HandCardSortByCondition` 比较器在 dump.cs:319328 指向 0x56f1c0，与反编译 `GameController.__c.c` 的 FlashAndSortCard 比较器共享函数体；合格卡优先，再经 `CardExtensions.CompareBagPos 0x37eff0` 比较正 bagpos（非正视为 int.MaxValue）、id、uid。当前页排序后写 bagpos=1..N；宿主 `GameState.sort_current_hand_by_condition` 同步 rail_order/hand，其他页保持。分页专项6/6、44断言；仪式26/26、92断言；原作 auto_save 导入桥50/50、stderr空。该桥只验证同刻导入，不证明排序后原作运行对拍；候选动画、真实输入与结算串行链仍未验收。

`CardSlotController.OnPointerClick 0x53c050` -> `GameController.HandCardSortByCondition 0x5515a0`，独立字段 `dump.cs:319849` qualified_bags_has_cards/index：空槽查找合格背包，首次保留当前合格页，重复点击轮换升序合格页，无匹配不改页。宿主 rite_view 与 game_screen 已接页切换及候选焦点；原作 bagpos 重排、CardFlash/背包/槽动画、精确高亮及设备输入切换仍未接，不标整链完成。

运行中编辑门：`RitePanelShowController.Show 0x596450` L649-658/L892-900 的 `!open_adsorb && !start` -> `CardSlotController.can_move`（dump.cs:317927 附近）。宿主共用 rite_slot_access 拦截点击、拖出、跨槽及桌面返卡，停止后恢复。当前专项 26/26、92 断言，无引擎错误或泄漏；最新空槽修改尚无可见输入与原作同状态截图对拍。前一轮完整回归 473/473、3469 断言，不作为最新变更全量回归。

## 全页面验收标准（2026-09-08）

用户要求全部页面按同一严格标准还原。见 [页面清单与验收门](ui_layout/PageFidelity.md)：逐节点字体/字号、布局、可见输入和状态证据分别验收。当前仪式统一 HY 字体不符合原作 textstyle 的多字体配置，上一轮字体完成结论撤回；先验证 TextTranslate/TMPTextExtensions 共用样式链，再续仪式选卡与锁槽，随后逐页推进。既有测试全绿不等于该清单已验收。

## 2026-09-08 全仪式模板普查

`RitePanelShowController.Show 0x596450` → 共用 `ui/rite_view.gd`：补齐全部 65 背景/43 前景/10 卡槽资产与原 Sprite 网格；保留原槽根尺寸并按中心变换整个子树；fg_in_slot_index、title_bg_hide/title_help_btn_hide 接线；映射长度不足按原作退回 mapping 0。1495 个仪式映射检查、251 模板检查（247 个有映射模板 GPU 截图），GUT 471/471、3454 断言，无引擎错误；content parity 3881/0。🟡：模板分支全覆盖不等于全部剧情状态/字体/结算表现 1:1。证据与图集见 [全仪式模板验收](ui_layout/RiteTemplateCoverage.md)。

## 2026-09-08 治理家业页面续修

来源：`RitePanelShowController.Show` 0x596450（原生精灵尺寸、Position=bg_pos、slot_open 映射、fg）；`RitePanelTitleController.Show` 0x5992a0（tips_text、标题、回合）；`CardSlotController.Init` 0x53b940（类型图标）。独立信号为 dump.cs 对应类字段、RitePanelShow/RitePanelTitle/CardSlot prefab、8001002→8000003 原配置和用户原版截图。修正既有批次 X 的固定背景拉伸、bg_pos 重复偏移、未应用 slot_open 和漏前景；验收记录见 `docs/ui_layout/RitePageCorrection.md`。

## 2026-09-08 桌面续修

- 四页入口：GameController.ChangeCurrentBag 0x54cb60 → PlayerExtensions.SetCurrentBagIndex 0x38f500（合法索引 0..3）→ UpdateHandCards；CardExtensions.IsCurrentHandCard 0x3826a0 比较 Card.bag 与 Player.BagIndex。独立信号：dump.cs:391594、GameScene BagBtnGroup 四个 Toggle。接入实例分页与存档，保留全部卡的状态域。
- 仪式标牌：RiteRender.Init 0x59a9e0 / OnLanguageChanged 0x59bab0，dump.cs:324578 与 RiteNew.prefab TitleBG/Title/RightImage；标题条独立于 123×133 bound，字体 42、背景高 77，宽度由文本 PreferredSize 决定。
- 金属反光：CardRender.Update 0x53a8e0 → GameController.GetScreenOffset 0x5508a0，dump.cs:317732/319746 与 cardshow.shader 材质属性、char/*.mat。原 fragment 已丢失；Godot 光照响应只能登记为近似，不把周期扫光当作原作。

以上三项已接入。四页选择进入存档和原作导入桥，拖放索引在当前页与全局顺序间换算；苏丹新卡遵循当前页。金属贴图使用原类型对应的法线/金属图，位置偏移范围取 GameScene (0,.05)/(.2,.4)，无自动周期扫光。仪式标题改为独立可点击背景条，随地图同比缩放、读取改名覆盖。仍为 🟡：完整 HandBagPanel 整理/跨页搬运、分页计数/首见提示；反射算法与 Unity 光环境；仪式特殊类型原生尺寸/专用位移及状态装饰。详细验收见 `docs/ui_layout/DesktopContinuation.md`。

> 2026-08-17 建立（复刻工作法，见 AGENTS.md 同名节）。**本表是复刻工作的主 TODO**：
> 新工作从这里取项，不从零散错误报告取。实现行为前先在此登记原作方法背书
> （`.c` 反编译 + `dump.cs`/配置，双信号）；批次收尾时更新对应行。

## 状态图例

**已落地首批，整体仍🟡，2026-09-07 卡面与窗口启动纠偏**：从 CardNew 自制卡面项继续。CardController.Init 0x528f40 调用 GetCardShowPrefab / CardRender.Init；CardRenderChar.Init 0x538030、CardRenderItem.Init、dump.cs:317717 的 bg/image/text/stackable/life 字段与 CardShowChar/Item/Sudan.prefab、materials/card/{char,item,sudan} 独立确认真正卡面。旧 card_bg_* 是错误素材，不能充当前景边框。恢复原材质 MainTex 底板与 char *_f 前景、全幅 Icon、Title，删除 VBox 属性行。原 Shader 导出是 DummyShaderTextExporter，动态金属光照暂不宣称一致。窗口默认按用户明确要求改 Windowed/1920x1080，并尊重 --windowed；原常量 ExclusiveFullScreen 不足以证明用户请求窗口模式时应切换物理屏幕。

**显示设置输入遮挡修正（2026-09-06）**：实测设置页KeyMap覆盖显示模式行；直读SettingsPanel.prefab:24843-24867，KeyMap底部锚(0,0)、pos(487,284)、size(405,174)、pivot(.5,.5)，父高1200，Godot左上应为(284.5,829)。旧y229错误，随显示设置接线修正，以保证下拉框实际可点击。

**已接通：显示设置完整接线（2026-09-06）**。从显示启动未迁项继续：`SettingDropDownController.InitResolutionDropDown`0x5aa0b0→Screen.resolutions，闭包0x5b2af0/0x5b2b60按宽/高降序并转WxH后Distinct；模式来自原 `content/variable.json.support_fullScreen`。OnChangeScreenModeClicked0x5aab30/OnChangeResolutionClicked0x5aaab0分别调用GameApplication.SetFullScreen0x43eea0/SetResolution0x43f700并写PlayerPrefs。启动MoveNext0x4520e0读取同键，dump.cs:542497-542500确认默认与键名。Godot缺少物理显示模式设置接口，新增Windows平台适配（EnumDisplaySettingsEx/ChangeDisplaySettingsEx）承载Unity Screen接口；不另造分辨率内容表。宿主守护进程恢复游戏退出时的桌面模式，用户偏好保存在现有应用设置中。实际1920×1080物理模式/1280×720窗口切换、独立进程启动恢复及异常退出恢复桌面均已验；专项5/5+UI75/75。详见 [DISPLAY_SETTINGS.md](DISPLAY_SETTINGS.md)。

**历史记录：显示启动推断（2026-09-06，强制独占默认已由2026-09-07用户要求纠正）**：原 `GameApplication.<DoInit>d__43.MoveNext` 0x4520e0 在L883起读取 `GameResolution`，再读取 `GameFullScreen` 并调用 Screen.SetResolution；独立常量 `dump.cs:542497-542500` 为 ExclusiveFullScreen / 1920x1080。Unity ProjectSettings 的初始1920×1080/windowed（mode3）随后被此应用初始化覆盖，不能只抄工程窗口模式。克隆撤销临时1280×720窗口，项目初始请求改1920×1080/Godot exclusive fullscreen；3840×2160仍仅为UI画布。此为上一批临时落点；本批已由Windows平台适配补齐物理分辨率切换、枚举与偏好恢复，当前实现与验收以DISPLAY_SETTINGS.md为准。

**事件路径已接、整体仍🟡：串行操作链（2026-09-06）**。`OperationsExtensions.Start(IList<IOperation>,ctx)` 0x500a70 → `ListExtensions.DoSequence` 0x38b120 → `Promise.Sequence`，独立符号 `dump.cs:311993-312024`；`AllOperations.Do` 0x4ee520 使用同一入口。`Confirm` 回调0x5061a0 → `OperationContext.SetLastOpState` 0x3a0230（true→0、false→1）；`Option` 回调0x51f250 写 index+3/tag；`SuccessOperations`0x3a7930/`FailedOperations`0x39d5a0/`CaseOperations`0x399570 只在匹配执行后清状态，未匹配保持。已用 `sim/operations_extensions.gd` 承载原方法的串行等待：事件在 prompt/option/confirm/sleep/改名边界暂停，继续时恢复同级与嵌套操作，原配置 JSON（保序）+游标保留在现有运行队列中，不新增 content 转换表。已接 EventTrigger/DeferredEffects.execute_event，移除多余事件摘要；仪式结果收尾与NextDay整条Promise链继续单独登记，不能宣称本批全覆盖。

**确认框边界（2026-09-06）**：`ConfirmController.OnConfirm` 0x53fc20 / `OnClose` 0x53fc10 分别 `Done(true/false)`，`Done` 0x53fb70 直接隐藏并 Resolve；`dump.cs:318365` 的独立 ConfirmController 与 Promise<bool> 定义、`Confirm.Do` 0x4f4e30 → ShowConfirm 为第二信号。不能把 OptionController 的“选择后再确认”套到确认/取消两按钮。共享浮层按已有 payload.kind=confirm 保留直接提交，完整 Confirm prefab 视觉仍未迁。

**2026-09-05 核心准确性优先**：当前主线返回卡牌 → 仪式投放/结算 → 事件交互 → 桌面反馈的完整游玩链。详见 [核心复刻验收与当前证据](CORE_FIDELITY.md)。本表 ✅ 仅表示该行已有的方法证据，不代表所属系统已通过连续游玩或像素对拍；旁支完成数量不作为核心准确性的替代指标。

**2026-09-05—09-06 已修，事件选择提交链（取自下方 PromptNew 近似项）**：`OptionController.Show` 0x576b50 初始化 CurrentOptionIndex=-1、CurrentOption/CurrentToggle=null 并禁用 Confirm；`OptionController.<>c__DisplayClass11_1.<Show>b__0` 0x588f00 只设置选择并启用 Confirm；`OptionController.OnConfirm` 0x576900 才隐藏并 Resolve。独立信号 `dump.cs:321643-321673` 的 Confirm/OptionsGroup/CurrentOption/CurrentToggle/Promise 字段；键盘链 `OptionItemController.OnSubmit` 0x577490 → 闭包 0x588ec0 把焦点移到 Confirm。已删除“点击即执行”，改为单选/改选/确认一次；普通 prompt 才发 close_prompt。另从正式主场景 GPU 渲染确认并修正 GameScreen/事件浮层零尺寸根、无效 RichTextLabel 字号键及自制配置ID标题。首批新增7测试/54断言，第二批扩至9测试/64断言。**整体仍🟡**：完整立绘传递、动态布局、仪式/NextDay Promise链及原作同帧对拍未完成；旧行的“已完成核心”不能作为系统完成结论。证据与后续唯一优先项见 CORE_FIDELITY.md。

- ✅ **已对齐**：克隆实现有原作方法级 SRC 背书（双信号），语义经反编译验证。
- 🟡 **近似**：行为大体一致，但缺方法级背书、宿主结构自制、或只覆盖原作的一部分。
- ❌ **自制**：克隆存在、原作无对应——待消灭、降级为兼容层、或证明为等价承载。
- ⬜ **缺失**：原作存在、克隆没有——按玩家影响排期补齐。

## A. 已有方法级对齐证据（不代表系统整体完成）

| 原作证据（双信号） | 克隆落点 | 说明 |
| --- | --- | --- |
| `GameController` OnNextRound 链 b__3（round 每天无条件 +1，`player+0x2c`） | `sim/round_loop.gd` `advance_day` | 与是否持苏丹卡无关 |
| `TryGenSudanCard` 0x559730（`HasSudanCard` 门控抽新卡） | `sim/round_loop.gd` | 只有抽卡受门控 |
| `UpdateSingleRite` 0x55ab10（已 start 且 `life >= round_number` 才 Settlement；0 日仪式当日结算） | `sim/round_loop.gd` `_update_rite_instances` | 结算时机唯一入口 |
| `RitePanelController.c` OnConfirm 行 1203-1239（set_start / start_round / start_life）+ OnStop 0x5906e0 撤回 | `ui/rite_view.gd` + `GameState.start_rite_instance` | 创建与开始是两个动作 |
| `StartRite.c` Do 0x51bcf0（DSL `rite` 键只创建实例，不置 start） | `sim/result.gd` `rite` 分支 | 含吸附失败中止 |
| `DoCardUpdate` 0x54d4c0 行 5139-5231（通用卡寿命；庇护 = 身处任一仪式槽） | `sim/round_loop.gd` card_vanishing 链 | 庇护不看 start/round_number |
| `TimingRoundBase.c`（周期事件重臂，`player+0x128`） | `sim/round_loop.gd` timing_rounds | `round_begin_ba:N` = 周期 |
| `OperationFilter.c` Filter 0x3a15c0（s<n>/self/parent/all/enemy/friend/卡牌id 选择器族） | `sim/result.gd` `_slot_target_uids`、`sim/condition.gd` `_selector_condition_cards` | 通用于槽操作/装备/clean/条件 |
| `HasTagTips.c` IsSatisfied 0x3fe3c0（读卡实例 tag_tips 列表） | `sim/condition.gd` `tag_tips.<tag>` + `GameState.record_tag_tip` | 属性检定时记录，运行时不进存档 |
| `RiteResultPanelController.c:1268` → `CardExtensions.DoPostRite`（参战卡+装备逐张结算） | `sim/round_loop.gd` `_run_post_rites` | 卡牌定义 post_rite 执行链 |
| `RebirthSudanCard` 0x519d60 + b__4_0 set_life(0) | `sim/result.gd` `rebirth.s<n>` | 槽卡倒计时重置 |
| FuncCompare 运算符键尾最长匹配 | `sim/condition.gd` dispatch | 审计报告一 |
| `operations.json` / `conditions.json` 全键域 + `case:opN` 子树 + cards.json `post_rite`/`vanish` | `sim/dsl_audit.gd` + `tools/export_dsl_audit.gd` | 三类全支持归零（2134/4001/2522）；新键必须入审计 |
| `over.json` 159 结局表（处刑 vanish.over / 事件 over 值驱动） | `ui` 结局屏 | 名/副题/文本/后日谈标记 |
| `init/*.json` 难度配置 | `sim/result.gd` `_difficulty_choices` | 难度选择发生在游戏内（SetDifficulty 语义） |
| 文本占位符 `[sudan_life_time]` / `[sudan_redraw_total_left_times]` | `sim/game_state.gd` `substitute_text` | 显示前替换运行值 |
| `GameController.AddRite/AddRitePin` + `RiteController.Init` + `RitePosition.AddRite` + `Player.pins` + `RiteResultPanelController <Settlement>b__8` + `GameScene.unity` + `{RiteNew,RitePin}.prefab` | `ui/map_controller.gd` + `GameState.rite_pins` + v8 存读档/导入桥 | 2026-08-20 批次 U：地点节点、全部 `RitePosition` 子坐标、`area:N` / `area:[N,M]` 最少占用选择（并列低号）、同子点 +100 横向叠放；live Rite = runtime-UID、可点击 `RiteNew` `(0,-18)/123×133` bound；`Player.pins` = config-ID、有序去重、非交互 `RitePin` `(0,-17.6)/123×133` Icon；结算顺序为先删 live Rite 再写 `final_pin` endpoint。见 `docs/ui_layout/MapController.md` |
| `StartScene.unity` / `GameScene.unity` 场景树（GameObject/RectTransform/Sprite GUID） | `ui/main_menu.gd` 等第七波接线 | UI 原作化的证据法 |
| `StartScene.unity` Setting 按钮 `m_OnClick → SettingsController.OnShow`（124454–124470）+ `SettingsController`（dump.cs:325897–325909；ShowSettings 0x5ab420） | `ui/game.gd` 标题菜单 `settings_pressed → _show_settings → SettingsPanel` | 2026-08-24 批次 AN：标题页设置不再只是未接信号；保留主菜单于下层，关闭后回到同一标题页。回归测试覆盖点击→打开→关闭。 |
| `CardInfoNew.prefab`（2510×1077 居中面板全真值表）+ `CardInfoNewController.c` Show 0x537000（Name=GetName、Title=CardNode.title@0x20、Content=Card.custom_text@0x58‖CardNode.text@0x28 + Utils.ProcessPlaceholders、RareText=CARD_RARE_{1..4}、TypeIcon=card_type_*、MainIcon=GetPic/GetSudanFullIcon）+ `CardNode`/`Card` 字段 + textstyle.json（CARD_INFO_NAME 40..60 / DESC 18..40 / TYPE 30 / RARE_TEXT 60 / TAG_TITLE 40）+ ui.json（CARD_RARE_1..4、CARD_INFO_STATE_TITLE/ATTRIBUTE_TITLE、CARD_INFO_HELP_*） | `ui/card_info_view.gd`（批次 AF 2026-08-22；GameScreen `_source_overlay_layer` 内源画布，_unity_rect 把 anchors/pos/sizeDelta/pivot 精确换算为 Godot Rect2） | 旧自制 690×340 暗盒已删除（自制详情面板也随之删除）；🟡 登记：TagNode 属性/标签分组旗标（can_visible/can_nagative_and_zero 组合）未精确验证，克隆沿用现有属性/标签数据视图；RareIcon 稀有图标列表（Common+0x48+0xe0 序）未定位；Equips 区内容（已装配列表 vs 可装列表）未知；帮助气泡文案为 zhTW 转简体。**2026-08-22 批次 AK 后澄清**：`CardAttribute.prefab` = 纯文本行（60×40、fs30、全幅 Outline、**无徽记图**）——批次 AJ 留档的"属性徽记图标"系误解（`Resources/image/tags.png` 图集属其他列表，tag_N 帧所在待定位）；`TagInfo/StateBar` = "状态" 标题（fs40 100×50）+ `CardStateTag.prefab`（43×43 可点图标按钮：root Image 43² + Icon 43² + Outline 全幅+10、LayoutElement 43²、Selectable）行 + Left 分隔线（rite_log_sperator），状态语义（哪些状态、点击行为）无控制器背书 ⬜ |
| PromptNew 通用事件提示浮层（GameScene MainUI/Prompt；旧 1280 暗盒已迁） | **已落地（2026-08-23 批次 AL）**：`ui/event_prompt_view.gd` EventPromptView（3840×2160 源画布 + OptionBG 2705×960 prompt_bg 居中 + Full prompt_bg_mask_2 + Title/EventPromptBody fs40 + OptionNewItem 行 2200×100/步进 150/fs40/option_item_bg+highlight + Border decorate + Confirm rite_op_confirm 325×158@(2059.5,808)）+ GameScreen 迁移（`_event_overlay` = EventPromptView；choice/continue 信号回 `_consume_event_display`，队列语义原样）+ 测试 3 条（几何/选项行/继续模式）+ UI 组 66/66 | **🟡（运行时布局，单点替换）**：OptionBG 高度 960（用户截图归一化量测；`PromptController.Show 0x58a020` ForceRebuildLayoutImmediate 为真源）、文本/选项行/立绘截图推导矩形、标题条占位；渲染行为经 GUT 验证（66/66），截图走查留档（dev_screenshot_runner `--event-prompt` 旗标已加，实机 bootstrap 下浮层显隐待复验） | 中·高 → 已完成核心 |
| `Tips.prefab` + `SlotTipsController.c` 0x5ac340 / 0x5aca50 / 0x5ac920 + `TipsHolder.c` 0x5c4400 / 0x5c53a0 + `dump.cs:326121` | `source_tips.gd` / `tips_view.gd`；普通鼠标hover、原作宽度/分带/夹取与文字回传，8测试132断言，两分辨率输入 | **🟡**：原作实机对拍/TMP；其他静态holder、动态委托、手柄/手机、卡槽第二提示未完成。详 `docs/ui_layout/SourceTips.md` | 中 |
| `GameController.GenCard` 0x54f650 → `PlayerExtensions.AddCard` 0x38b620 + `GenCoin.c Do` 0x510b40（金币 = 手牌金币卡 2000029 **多对象** count 之和；每 op 新建对象、count=操作值可为负、bagpos=1 前置、OnCardBorn） | `sim/game_state.gd` coin_count 计算属性 + `_grant_gold`/`_remove_gold`、`sim/result.gd` coin 键、v5→v6 存档迁移 | 2026-08-17 修复；多对象扣除顺序未验证（cost 支付链未审计，现最大面额优先） |
| `CostCondition.IsSatisfied` 0x3f6160（花费判定读卡对象 count，card+0x20；判定时按 player.cards 枚举序选定付款卡清单记入 `ConditionContext.need_cost_cards`） | `sim/condition.gd` 金币/coin 条件（经 coin_count 求和属性）、`game_state._remove_gold`（uid 升序=枚举序，末对象部分扣减等价于移除找零；付款执行体未反编译留档） | 读模型与支付顺序一致 |
| `PlayerExtensions.GetCounter` 0x38ce70 特殊分支（7000105 金币/7000104 门客 = 从 cards+rites 派生求和；7100007 回退配额读 Global） | `game_state.gold_total()`（hand+slot 求和）、`game_state.get_counter` 7100007 分支读 `global_state` | 金币总额含仪式槽；配额读全局域 |
| dump.cs:542529 常量表 + `PlayerExtensions` Add/SubCounter（**金骰 = COUNTER_GOLD_DICE 7100006**；额外重抽 = 7100008；回退 = 7100007 存 global，9999=无限） | `game_state.gold_dice` 计算属性（counter 存储 + 7100006 非负门 + v6 去标量）；`round_loop.use_redraw` 的普通配额耗尽后消费 7100008 | 金骰、7100007、7100008 均已落地 |
| `Global`（global.json 跨局域）+ `PlayerExtensions` SetCounter 0x38f2d0 7100007 分支（无条件非负 clamp 写 `Global.backToPrevRound`）+ `Datapool.c` StartGame L4497 新局重置 9999 + CorrectPlayerData L4130-4134 档案恢复 | `sim/global_state.gd` GlobalState（user://global.json；backToPrevRound/roundRollback 先行）+ `game_state.set_counter` 7100007 分支 + `setup_new_run` 重置 9999（`apply_resources=false` 供菜单新局延迟到叙事者选择）+ `SaveSystem.load_user_archive` 档案索引恢复 | 2026-08-18 修复；其余 global.json 字段见 ⬜ |
| `GameController` OnPrevRound 0x554f80（min_round 门 + GetBackToPrevCount 配额门 + 9999 不消耗 + IsValidRoundEnd + 确认框）→ PrevRoundInternal 0x555570（UseBackToPrev 先消耗 → `Global.roundRollback = 2` → SaveGlobal → LoadRound(round-1)）；OnBeginRound 0x5537b0 置 rollback=1 | `sim/round_loop.gd` `back_to_prev_round_end`（门控 → 消耗 → 标记 → 全局保存 → 快照恢复；配额在全局域故快照恢复不回滚消耗）+ `advance_day` 置 ROLLBACK_TO_BEGIN | 消耗先于恢复，与原作顺序一致 |
| `DatapoolExtensions` SaveRoundBegin 0x3f9050 / SaveRoundEnd 0x3f9120（先 SavePlayer(auto_save)，再写 `round_{N}.json` / `round_{N}_end.json`）+ LoadRound 0x3f8fa0 / LoadRoundEnd 0x3f8e70 / IsValidRoundEnd 0x3f8d50；LoadUserArchive 0x417350 删除 `round_*.json` | `SaveSystem.save/load_round[_end]` + `RoundLoop` 磁盘回退兜底 + 档案加载清理轮次文件；内存快照仅作同进程缓存 | 2026-08-18 批次 F；重启后仍可回退，文件名和双写顺序对齐 |
| `PlayerExtensions.SetDifficulty` 0x38f530（金骰 = 当前 + 新难度 gold_dice_count **加法**；回退配额 = 当前 − 9999 + 新难度 back_to_prev_round_count；重抽只改 `times_per_round` 与 `card_init_life`） | `game_state._apply_difficulty_resources()`（新局与中途切换共用；`apply_difficulty`） | 离开无限档=重置为新配额；有限切有限=clamp 归零；切回无限档=保留余量（防刷）；本周期已用次数与恢复周期不改 |
| `TimingRoundBase` 键 = 实例 +0x20 **int**（player+0x128 字典键；样本全部 = 事件 id×100，TimingRoundBase.c IsValid 0x465d30/OnStart 0x4660d0） | `event_runtime._timing_key` = event_id*100（2026-08-18 由导入桥发现偏差后修正；1381 个回合时机事件全单桶序号 0；旧字符串键 deserialize 迁移） | 多桶事件的序号分配未验证（当前无此配置） |
| 原作存档 Player 60 字段（dump.cs:391488 × save_samples 双信号） | `sim/original_save_importer.gd` 导入桥（difficulty 1 基 -1；cards[i]↔s{i+1}；装备嵌套→扁平 equipped 链；min_round、苏丹重抽 profile、终局结果、cached_event、HUD 标志族、`pins` 与 end/armageddon 三字段显式持久化） | 同刻对拍 49/49；仅 drawn_round 与洗牌后牌堆顺序作显式近似登记 |
| `GameController.GenSudanCard` 0x54f6f0 L3656-3662（出生 `set_life(模板 card_vanishing − player.sudan_card_init_life)` 抢跑）+ `UpdateSingleCard` b__1 0x572420（每日 life+1，`life>=card_vanishing` 且无槽位庇护即 DoVanish 处刑）+ `UpdateSudanLife` 0x55aeb0（倒计时显示 = vanish − life，可负） | `round_loop.draw_weekly_sudan`（头起步）+ `_update_card_lives`（苏丹并入通用死亡，days_left 为 vanish−life 镜像）+ rebirth 按模板 | 2026-08-18 批次 D；困难档 7−5=2 抢跑=5 天；b__1 老化豁免标签字面量未反查（无配置命中） |
| `RedrawSudanCard` 0x5558b0 L3823-3842（循环 player+0x68 次 GenSudanCard；新卡 `set_life(弃卡 life)` 继承剩余期限；弃卡 life 归 0 后 `Insert(Random.Range(0,count))` 回池）+ `GenSudanCard` 抽取 = sudan_card_pool **先 Shuffle（sudan_shuffle）再 RemoveLast** | `round_loop.use_redraw`（carried_life = 弃卡实例 life）+ `SudanCards.draw` pop_back 尾抽 | 2026-08-18 批次 D；牌序因每次 Shuffle 无意义，多重集对拍为正确粒度 |
| 手牌位系统：Card `bag`@0x48（包页 id）/`bagpos`@0x4c（页内 1 基位置，0=未摆放）+ `Player.BagIndex`@0x150（当前查看页）+ `IsCurrentHandCard` 0x3826a0（bag==BagIndex 且三标签）+ `UpdateHandCardPos` 0x559a70 L1060-1097（b__6 链内、回合开始事件后：收集当前页手牌→排序→`set_bagpos(i+1)` 压缩 1..N）+ GenCoin `set_bagpos(1)` 金币前置 + GenSudanCard `set_bag(BagIndex)` | `CardInstance.bag/bag_pos`（v7 起持久化）+ `round_loop.update_hand_card_pos`（日终压缩，克隆单页 bag=0）+ `_grant_gold` 前置 + 抽卡 set_bag | 2026-08-18 批次 E；三标签名无法从元数据反查（字面量间接寻址），留档 |

## B. 近似 🟡（行为近似承载，缺背书或部分覆盖）

| 克隆落点 | 缺口 |
| --- | --- |
| `sim/game_state.gd` v8 存档（serialize） | 原作存档 schema 已全解码（60 字段，`docs/ORIGINAL_SAVE_SCHEMA.md` + `sim/original_save_schema.gd`）；**阶段二导入桥已落地**（`sim/original_save_importer.gd` + `tools/export_save_diff.gd --bridge`，语料 auto_save 49/49 同刻对拍全过，含 Player.pins 与 end/armageddon 三字段）；续局行为对拍待实机样本 |
| `GameState.pending_operations` / `delayed_operations` | 原作 Promise/Pop 队列的宿主承载；2026-09-06 事件进入 OperationsSequence，支持 UI 等待、分支响应与存读档保序。仪式收尾/NextDay/延迟操作及旧 ResultExec 调用仍未整体串行化，保持🟡 |
| `sim/condition.gd` AttrExprParser | 文法已对齐（四则/e() 敌方/sN.tag/counter.N）；解析器宿主为自制递归下降，非原作方法映射 |
| `ui/game_audio.gd` GameAudio | 仅 main/tutorial BGM + 部分音效；拖放音、弹窗出现音、BGM 分层（level2/3）、结局 BGM、`sfx_*.json` 全量缺 |
| `ui/begin_guide_bar.gd` 引导条 | 文案/键族/存档对齐；`WizardController` 完整演示宿主与 magic_sudan 演出缺，5310004 后序列未实机校对 |
| `MapController.SetRitesPosition/SetPos` + `RefreshRitePinLines` | 批次 U 已拆出 live `RiteNew/RiteController` 卡层与 `Player.pins` endpoint；批次 V 已补 RiteNew 123×133 bound 的跨点碰撞与 bg 外整位回退（只测 bound 中心、不钳边）；批次 W 已接 8 个原作 `RiteNode.from_pins`：仅已完成 pin 可作起点、终点可为 pin 或 live RiteNew、键为 `(target rite-id, source pin-id)`、原始二次 Bézier/保留区/虚线/箭头参数直读配置。不得把 SetPos 或 from_pins 起点误套到 RitePin 之外的运行时卡 |
| `ui/map_controller.gd` `MapController.SetRitesPosition` / `SetPos` / `RefreshRitePinLines` | `LocationController.RitePosition` 子点、范围选位与同点叠放已精确；批次 V：NORMAL/`[` 组按屏幕中心排序后两两推开，固定特殊仪式只避开该组；候选出 bg 则恢复旧位。批次 W：重建线层等价 `CleanUnexistsPinLines`，且不因 live source 或无关 pin 合成边；已覆盖的 8 条配置同为 50 段、20 像素、起始保留 .08、100/40 箭头、RGBA(207,187,161,255)、虚线。|
| 苏丹卡视觉（稀有边框、倒计时红光） | 部分接入；细节原作化未完成 |
| `ui/*.gd` 旧屏坐标（game_screen / rite_view / card_widget / begin_guide_bar / game_over / ESC·档案 overlay） | **2026-08-18 批次 P 起列入 UI 布局对拍**：视口已切原作 3840×2160 设计空间（旧 `window/size/viewport=Vector2i(...)` 键无效、从未生效，游戏一直跑在引擎默认 1152×648）。**批次 Q 已将 `game_screen` 的桌面 chrome 与手牌带移出 LegacyLayer**；**批次 R 已把桌面地图换为 `ui/map_controller.gd`**；**批次 X 已将 `rite_view` 迁至 `GameScreen.SourceOverlayLayer`**：`RitePanelShow` 固定 3840×2160 源画布，`Position/bg` 4096×2148、`RitePanelTitle` 1148×1124、`CardSlot` 272×496 都直接回放 prefab；`rite_template` 的 `bg_pos/title_pos/slots.{pos,scale,rotation_z}` 按 `RitePanelShowController` 的实际坐标链写入，旧“网格 + 手牌安全区”已删。**批次 Y 已将 `card_widget` 与 `GameScene/MainUI/Hand` 改为源码直连**：CardNew `194×422`、SudanCard `185×330` 分型；Hand 的解析矩形 `516.7349,1726 / 2723.264×430` 和 `HandCardsController` 的 Space=10 / minVisibleWidth=20 直接落地，移除全局 3× mockup 缩放。**批次 Z 已删除无原作桌面对应、且无实际发射点的 `rite_selector` 自制分支**；桌面仪式入口仅保留 `MapController` 的 `RiteNew/RiteController -> RitePanelShow` 直接链。**批次 AA 已将 BeginGuide `Default` 迁至源 3840×2160 坐标，回放 1200×460 面板、400×400 溢出图标、75px 文本和 80px Close**；**批次 AB 已将结局从 LegacyLayer 的自制单页迁到 `OverNewController` 结构：Step1 标题 → 配置 CG → Step3 主菜单；`DoNext` 的 Story/AfterStory 枚举与分支保留，但 after_story 播放宿主仍缺。**批次 AC 已将 ESC 从 LegacyLayer 自制菜单迁至 `ESCGameController` 结构：源 `ESCPanel` 2×根、Mask、1021px ButtonGroup、四个激活项与 `Return/EndGame/MainMenu` 调用链；`NewGame` 保持 prefab 禁用。**批次 AD 已接 `ESCGameController.OnSettings -> SettingsController.ShowSettings(false)`：`SettingsPanel` 2×根、1788×1200 `PanelBG`、四个源 dropdown、音乐/音效 0–100 slider+独立 ON/OFF、数据收集/主播配置和 KeyMap 入口均按 Prefab 真值表重建；音量/开关经 `GameApplication` 等价应用偏好持久化，不进入 Player 存档。平台显示/语言/分辨率/字体和 KeyMap 的 Godot 宿主尚缺，仍显式禁用。**批次 AE 已将手工档案从 LegacyLayer 迁到 `UserArchiveController` 结构**：全屏 3840×2160 `UserArchive`、左侧 28% 信息栏、右侧滚动档位、固定 50 个 2760×240 的 `UserArchiveItem`（空位也显示）、覆盖确认 → 1–20 字 `UserArchiveNameInput`、改名只走 `Datapool.UpdateUserArchive` 等价索引更新而不重写玩家档。`bg_1`/按钮/卷轴原始贴图未从语料导出，保留源几何与逻辑载体，不自制替图。**批次 AJ 按原作运行时截图对拍修正卡牌详情内容行**：属性行顺序改为 体魄/魅力/智慧/**战斗**/社交/支持（原文 cfg 2000001 与截图一致：战斗在社交前；旧实现是社交在前）；标签行改为**纯名称**无数值（截图：男性 贵族 主角 已拥有；旧实现显示"名 值"）。🟡：属性徽记图标（tag_N 精灵资源未独立导出为纹理，仅 Resource/image/*.asset 存在）留待资源提取。**批次 AI 修正声望条槽位几何**：`_build_prestige_strip` 六个槽按 GameScene 真值表 `MainUI/Prestige/710000N` 行的 anchor/pivot 混合（7100001 为 (0,1)+(−6.5)，其余 (0,0)+各 y；pivot 恒 (0.52,0.94)）用 pivot 折叠后的左上角矩形摆放（−80.12/−8.62 … 751.88/43.88）。旧实现把 authored `pos` 当左上角，六槽位置全错（批次 P 时代的未对拍偏差）。补 710000N 勋章贴图与计数标签（宿主视图 🟡，原作计数走 Image/Count 精灵）。**批次 AH 已把改名提示迁至 `ChangeNameView`（`ui/change_name_view.gd`，`GameScreen._source_overlay_layer`）**：`PromptChangeName` 源几何——PromptBG 2534.4×220 居中（prompt_bg）、"修改名称"标题 fs40、InputField 826×90（input_bg，占位符"请输入名称" fs50，`PromptChangeNameController.IsValidName 0x584de0` 的 **1–20 字符**上限——旧克隆 max_length=32 是偏差，一并修正）、Content Invalid Prompt 324×48 校验错误行、Icon 471×1028 卡立绘（(1,0)(−274,66)）、Border decorate 236×324、Confirm rite_op_confirm 325×158、Cancel rite_op_cancel 168×158+"取消" fs24；控制器无显式尺寸写（高度为 ContentSizeFitter PreferredSize，语料无法静态解出）→ **🟡 登记：PromptBG 高度用 220 宿主常量**，子几何全部走 authored 锚点数学，后续实机样本可只替换该常量；i18n `PROMPT_CHANGE_NAME_TITLE/_INPUT_PLACEHOLDER`（zhTW→简体）。**批次 AG 已接桌面帮助**：`GameScreen` 新增 `MainHelpTrigger`（help_button 88×91，top-right pivot (0.5,1) pos (−70,−143.5)，z=50 位于局部模态之下、随 `Player.helpbtn_unshow` 显隐）+ `ui/main_help.gd`（`MainUI/MainHelp` 源浮层：Mask + 指针图 `main.asset` + 11 条 602×200 fs50 气泡，锚点/位置直读 GameScene 真值表；文案 = i18n `MAIN_HELP_*`（zhTW→简体，Unity `<b><color=white><size=86>` 标记转 Godot BBCode））。已知渲染差异：Godot RichTextLabel 的 86px 行内强调字形基线偏移（原作 TMP 无此表现）；InputDisplay 手柄提示未做。**批次 AF 已将卡牌详情迁至 `CardInfoView`（`ui/card_info_view.gd`，`GameScreen` 的 `_source_overlay_layer`）**：源 `CardInfoNew` 面板 2510×1077 居中（3840×2160 设计空间）、`bg_7` 全板、Name（(1911,-89)/435.55×71.58 + 卡名与 TypeIcon fs30 标题）、Content（(270,80)/1550×185 fs34，custom_text‖config.text+占位符）、RareBG（rare_stone 147×249 + CARD_RARE_1..4 石/铜/银/金 fs60）、TagInfo 左列（1336.7×647.76，属性/标签两栏）、MainIconMask（1000×1100 + 471×1028 立绘）、Equips（402.65×500.57 + EquipState 顶部）、Close（checkbox_bg 80×82 + close_2）、BottomDecorate、HelpButton → Help 浮层（card_info 四条 CARD_INFO_HELP_* 气泡）；全部直读 prefab 真值表。详见 `docs/ui_layout/RitePanelShow.md`、`docs/ui_layout/HandCards.md`、`docs/ui_layout/MapController.md`、`docs/ui_layout/BeginGuide.md`、`docs/ui_layout/Over.md`、`docs/ui_layout/ESCPanel.md`、`docs/ui_layout/SettingsPanel.md`、`docs/ui_layout/UserArchive.md`、`docs/ui_layout/CardInfoNew.md`。 |

## C. 自制 ❌（原作无对应，待消灭/降级）

| 克隆物 | 处置 |
| --- | --- |
| `set_world_scene_blocker`、`world_spawn_id`、`world_position_ratio` 存档字段 | 横版世界探针遗留；清理需评估 v5 存档兼容（GAP 留档） |
| ~~`GameState.coin_count` 标量金币~~ | 已消灭（2026-08-17）：金币卡多对象模型落地，coin_count 变为求和计算属性，v6 存档不再持久化标量 |
| ~~`GameState.gold_dice` 标量骰子~~ | 已消灭（2026-08-17）：金骰 = counter 7100006（dump.cs:542529 + Add/SubCounter + 存档样本三重信号），计算属性落地 |
| ~~`GameState.back_to_prev_left` 局内回退配额标量~~ | 已消灭（2026-08-18）：配额 = counter 7100007 存全局域 GlobalState（原作 Global.backToPrevRound），v7 局内存档不再携带；快照恢复后"补回预算"hack 一并删除（配额天然在恢复范围外） |
| ~~`event_runtime._timing_key` 字符串键 `"timing:event_id"`~~ | 已消灭（2026-08-18，导入桥发现）：改为原作 int 键 event_id×100（TimingRoundBase+0x20 int 直址 player+0x128），旧键加载时迁移 |
| `GameState.hand`/`rail_order` 独立手牌数组 | 部分收敛（2026-08-18 批次 E）：CardInstance 已承载 bag/bag_pos 并由日终压缩维护（bag_pos = 手牌序+1 不变式）；数组彻底退役仍阻塞于 IsHandCard 三标签名未反查（成员资格判据）与包页 UI 缺失 |
| `MethinksEngine` / `drop_card_on_methinks` 命名族 | 复刻期兼容接口；玩家可见概念统一为"思考"，方向定后重命名 |
| ~~弹簧积分器、透视/阴影 shader、SubViewport 双通道、ui_motion.gd~~ | 已于 2026-08-17 去 Balatro 批次删除（git 历史可恢复） |

## D. 缺失 ⬜（原作有、克隆无）

| 原作系统 | 证据入口 | 规模评估 |
| --- | --- | --- |
| after_story 后日谈播放 | **2026-08-28 批次 AP 已迁主链**：66 个 `data/config/after_story/*.json` 零转译进入 `content/after_story/`，`ConfigDB.after_stories` 对应 `Datapool.after_story@+0x70`；`ui/over_new_step2_story.gd` / `ui/over_new_after_story_item.gd` 分别 1:1 映射 `OverNewStep2StoryController` / `OverNewAfterStoryItemController`。历史 `player_data==null` 分支按 `AfterStoryData{card_id,pic,prior,extra}` 精确回放原 settlement key；有 Player/实时分支按节点绑定匹配的运行时角色卡 `ConditionContext`，再计算 close/prior/extra；页面严格按 `Settlement.sort → card_id` 排序，1000×1900 横向分页、前后页门、选页回顶已接。**批次 AQ 补齐实时写点边界**：`ConfigDB.over_ids` 1:1 承载 `Datapool.over_ids@0x2A0 HashSet<string>`，与跨局 `Global.overID HashSet<int>` 严格分离；实时 Init 先 Clear、每个命中 settlement 在原 `result/action` 调用位置后 `SetOverId(key)`，`ConditionEval over_id/!over_id` 对应 `HasOverId 0x3fdc90`；历史 `Show(AfterStoryData)` 保持只读。当前原作 66 文件共 7750 个 settlement，实测 `result/action` 字段均为 0，因此不虚构 operation；若未来接 Mod 配置，此通用 dispatch 仍为 🟡。**批次 AR 已迁放大链**：`DoZoom 0x57a970` 的 0.1 秒过渡与 `OverNewStep2StoryZoomController.UpdateSize 0x57c190` 的四组宽度范围（BG 1707→4800、Story 1050→3540、Blocker/AfterStory 1000→3740）直接落地；Range 跨过 0.2 时，条目由纵向“立绘上/文字下”切为反向横排“文字左/立绘右”，当前页偏移和每项宽度始终跟随 `AfterStoryViewWidth`。旧实现把整个 3840×2160 根节点移到 x=-1707，原控制器没有这条行为，现已删除。**批次 AS 已迁故事播放链并修正同屏几何**：`OverNewController.StartStory 0x57a4a0 → OverNewStep2StoryController.Update/StopStory/OnJump 0x57bf40/0x57bd70/0x57b810` 直接映射；`PlaySpeed=20`，浮点累加后截断为可见字符，按已渲染前缀增长高度并自动跟随底部。第一次 Jump/点击只显示全文、滚回顶部并激活 Jump，第二次 Jump 才回调父控制器；旧克隆第一次点击直接跳过故事的偏差已删除。同时按 RectTransform 真值修正 Jump `(3136,1990)/44×51`、Zoom `(3547,60)/93²`、AfterStory viewport、Op Contents 与 Prev/Next/Confirm，消除先前未做 y 翻转/错误 pivot 的位置偏差。**批次 AT 已把 CG 层拆为 `ui/over_new_step2.gd = OverNewStep2ControllerView`**：`Init 0x587ee0` 的 `Name <- OverNode.name`、`FullCG <- bg`、`CGMask <- bg+"_mask"` 直接绑定，删除旧克隆在底部重复显示 `OverNode.text` 的自制 Label；保留 prefab 的 Over Title/Name/NpcHeadContainer 结构。`show_story.anim` 保持 Step2 常驻，逐帧回放 Mask Image alpha 和 Step2-Story CanvasGroup alpha；time=0.25 调 `UpdateMaskCanvasGroup 0x57a820` 启动独立五秒线性遮罩组淡入，time=1 调 `StartStory`。**批次 AU 已补齐 `NpcHeadPrefab` 链**：历史 `player_data==null` 按 `OverData.char_cards` 原序无筛选回放；实时 Player 分支按 `<Init>b__5_0 0x588d80` 精确筛 `type==char && adherent && !lost`。`OverNpcHead.prefab` 的 100×100 LayoutElement、92×92 Image `(4,-16)` 已落地；`OverNewNpcHeadController.Show 0x57a610 → Datapool.GetHeadSprite 0x411ea0` 按 `pic` tag 直读原作 `heads` atlas，依次尝试 `id_pic/id_0pic/id/default`。**批次 AV 已补齐原作输入表面**：`InputActions.asset` 的 `UI/Submit` 仅 Space/Enter/buttonSouth，按当前选中对象驱动 Over→StopStory→Confirm→AfterStoryConfirm→MainMenuButton；`EnableAfterStoryControl 0x57aaf0` 仅在后日谈阶段绑定 gamepad d-pad/left-stick 左右到 `OnPrevPerformed/OnNextPerformed`，摇杆采用越阈值单次 performed，不把键盘方向键误当专用翻页动作。完整 prefab/动态真值见 `docs/ui_layout/{Over,AfterStoryItem}.md`；视觉走查见 `docs/ui_layout/{afterstory_screenshot,afterstory_zoom_screenshot,story_typewriter_screenshot}.png`。验收：GUT 422/422、3070 断言，零引擎错误/orphan/泄漏；配置对拍 3878/0。🟡：仅未来 Mod settlement operations 待实例证据。 | 低（原作数据无实例的 Mod 写点） |
| ~~笔记系统（普查+结构承载）~~ | 已落地（2026-08-18 批次 O）：`Player.notes` List<List<Note>>@0x138 按回合分页（页=round−1），Note={type,id,uid,count}；type 1=仪式创建/2=消亡/3=结算/4=吸附卡(count 存卡 id)/10001=成为随从/10002=获得奖励卡。克隆 `GameState.notes`+`add_note` 进 v7 存读档与导入桥（对拍行过）；运行时写点 1/2/3 已接（StartRite.c L133 / GameController.c L5867 / RiteResultPanelController 链），4/10001 调用方不在反编译子集、10002 的手牌标签门未解——三写点留档 | 中（笔记 UI 未做） |
| 图鉴/画廊 | `gallery_cards.json` / `gallery_cg.json` + Gallery*Controller 族 | 🟡 标题入口 → `GalleryPanelController`；`GalleryCardPanel.GetCards/ShowCards` 的 `is_show/type/definition/sort` 筛选、六张 `GalleryCardGroup`、可视行 CardNew 实例化已对拍。网格点击按真实链 `GalleryCardItemController.OnPointerClick` 0x547970 → `GalleryCardPanel.ShowCardInfo` 0x549520 → **专用 `ui/gallery_card_info.gd` = `GalleryCardInfo.Show` 0x5465f0**；已落地 3840×2160 真值布局主块、CardNode 名称/标题/正文、PlotItem → PlotContent、前后项边界、关闭销毁。剧情遮罩与写点按 `Show` + `AddShowedGalleryCard` 0x543c80 接到 `Global.showedGalleryCards` 并保存。资源切换按 `Show` 的 `GetPic/GetRare` 头项 + `GalleryData.resources` AddRange 原序构建，`ChangeIcon` 0x544210 同索引切图与稀有边框；配置实际引用而仓库缺失的 27 张变体图已从语料逐文件 SHA-256 等值导入。`GalleryCardHead` 110²、`PlotItem` 850×100/fs50/dot/highlight、`PlotContentItem` 930 宽/fs70+50 均有独立 prefab 真值表。`SearchCard` 0x549240 + 闭包 0x55c7f0 = `CardExtensions.GetName(card).Contains`。**2026-08-27 标签批次**：`RefreshAllTags` 0x5459c0 的 `can_visible/can_add/can_nagative_and_zero` 三门、`type==attribute` 分流与 `tag_rank` 降序已直连 `content/tag.json`；非 attribute 走 `CardTagNew.Show` 0x53f040 + `CardTag.prefab`（3 列 365×120 网格、tag_N 原图集、名称+数值），attribute 走 `CardAttribute.Show` 0x527c10 + `CardAttribute.prefab`（60×40/fs30、纯名称、Real Attribute Contents 1.5×）。**CG 批次**：导航恢复为结局下的二级 `GALLERY_OVER_BTN_CG`；`GalleryCGIconController.IsLock/ShowIcon` 0x5430a0/0x5433a0 按 `GalleryCGNode.over_id` 对 `Global.overID` 任一命中解锁（纠正与 `showedGalleryCards` 混淆），15 个 CGItem authored RectTransform、锁层、锁定提示及 `ShowBigCG` 0x5436b0 的 title/big_resource/2160 方形等比展示已落地；配置引用 60 张图均从语料 SHA-256 等值导入。仍待：结局记录表面；CG 大图标题字体与原 TMP 的渲染细差 🟡。 |
| 向导演示宿主 | `wizard/` 配置 + WizardController（未审） | 中 |
| 音频全量 | `sfx_config.json`、`sfx_settle_card_new.json`、`sfx_npc_role_dub.json`、`over_music_config.json` | 小-中（配置在语料库未接） |
| 未接配置域 | `textstyle.json`、`imagestyle.json`、`dt`、`mobile_help.json` | 逐域判断用途后接入或说明（`variable.json` / `ui.json` 已由图鉴直接读取，`quest.json` 已由任务链直接读取，`upgrade.json` 已由命运商店与新局升级链直接读取，`credits.json` 已由制作人员名单直接读取，均非转换层） |
| 制作人员名单（Credits） | **2026-09-03 Credits 批次已迁**：`content/credits.json` 与语料逐字节一致，`ConfigDB.credits` 原样直载 19 名开发者、3 个 contributor 记录、12 个 thanks 记录及 11,006 个名字；代码按 `CreditsController`、`CreditsPage`、`CreditsPageDeveloper`、`CreditsPageContributor`、`CreditsPageThanks`、`CreditsGroup`、`CreditsMember` 原类边界拆分。`CreditsController.OnEnable/DoPrev/DoNext`（0x3f6f60/0x3f6ce0/0x3f6aa0）回放 developer → contributor → thanks 外层顺序、页面实例复用、内部页优先翻动与位置保存；`CreditsPageContributor` 每页两个 group；`CreditsPageThanks.GetNames 0x3f8070` 保留 column/cell_size/page_size 限幅、.NET UTF-16 长度、跨行补齐及分页边界（原配置“测试玩家”3 页、首个大型众筹名单 39 页已锁入对拍测试）。`Credits.prefab` 与三个子 prefab 的 3840×2160 根、关闭/翻页按钮、标题、logo、19 张开发者卡 authored transform 及静态字体/装饰几何均直接回放；图片逐文件从语料拷入并由内容哈希核验。**同日排版补证**：`CreditsHelperGroup.prefab` 的旧 `Title/seperator/spacer/Names` 均为 inactive，`CreditsGroup.Show 0x3f7590` 只向 active `NamesContainer` 实例化 `CreditsNameWithJob`；职位/姓名已按 prefab 恢复为左列左对齐、右列右对齐及源金色。thanks 的 Talk/Text 起点、四行占位推导行高、`<indent=N%>` 绝对列位和配置实际使用的 `<size>`/`<font>` TMP 标记均已按源语义承载。截图：`docs/ui_layout/credits_screenshot.png`、`credits_contributor_screenshot.png`、`credits_thanks_screenshot.png`。 | 🟡 尚无原作同帧运行截图，不能宣称像素级视觉对拍；剩余差异限于源 TMP 字体与 PreferredSize/自动字号度量、contributor 动态行高、`CreditsMember` 淡入淡出时长及 InputDisplay/手柄选择链。thanks 百分比 indent 已不再是缺口。 |
| 任务完成通知（Global / Quest / StoryNotify） | **2026-08-29 任务链批次已迁**：`content/quest.json` 与语料逐字节一致，`ConfigDB.quests` 直接承载 `Datapool.quest`；`sim/global_extensions.gd` 1:1 映射 `GlobalExtensions.RefreshQuest 0x4fcee0`，`Global.counter/quest` 与 `totalPoint/usedPoint/questState/hasEnterQuest` 使用原键持久化；`ModifyGlobalCounter.Do 0x5176a0 → RefreshQuest(true,false) → Global.OnQuestCompleted → StoryNotifyController.Show 0x5b9c00` 已直连。`ui/story_notify_controller.gd` 回放 StoryNotify.prefab 630×444 顶中几何、原 prompt/point_0 纹理、0.333s 入场+5s 停留+0.333s 退场与 FIFO；点击发出原作形状的 Story target 请求。原 `save_samples/global.json` 未包含非默认 quest/counter，故目前以反编译+配置/Prefab 双信号验证，**不宣称真实非默认存档逐字段对拍**。真值表见 `docs/ui_layout/StoryNotify.md`。**2026-09-02 任务面板与领奖链已迁**：`GameController.ShowStory 0x557ab0` 直接实例化 `ui/story_controller.gd = StoryController`；`StoryController.OnEnable/OnItemClicked/OnRewardClicked/OnRewardAllClicked/Sort/UpdateQuestRewardIcon`（0x5b0f70/0x5b1370/0x5b20b0/0x5b1d20/0x5b2370/0x5b2680）、`StoryItemController.Init/UpdateState/OnRewardClick`（0x5b9450/0x5b96a0/0x5b9520）和 `StoryTargetItemController.Init 0x5b9e80` 均拆成同名控制器边界。领取落在 `GlobalExtensions.GetQuestRewqrd 0x4fc860`：完成门/重复领取门、`Global.quest[id]=2`、`totalPoint += upgrade_point`、保存和 `HasQuestReward` 重算已回放。任务、目标与格式均直接读取原作 `quest.json`/`variable.json`；StoryPanel/StoryItem/StoryTargetItem 三份 Prefab 真值表与 15 张原图已落地，其中目标完成图 `Finish` 由 Prefab GUID 校正，不再误用 point。**2026-09-03 命运商店批次已迁**：原样 `content/upgrade.json` 50 个 `UpgradeNode` 由 `ConfigDB.upgrades` 直载；`Global.upgrade Dictionary<int,int>` 按原字段存读（key=已购买，value 0/1=停用/激活），`PointShopController.OnBuy/OnActivate/OnDeactivate`（0x5802d0/0x580090/0x5805e0）精确回放购买自动激活、`totalPoint -= cost`、`usedPoint += cost`、停用不退款。`HasUnlockUpgrade 0x3feb40` 按购买成员资格而非激活值，`HasAvailableUpgrade 0x4fcd00` 按未购买且可负担、刻意不看可见条件。新局 `Datapool.InitPlayer 0x413700 → DoUpgrade 0x410dc0` 以升级 id 升序执行 active 节点的原始 effect；新增的 `g.card`、`g.change`、`sudan_card` 回放本配置实际使用路径，尤其苏丹卡追加在已洗牌池尾。UI 拆为同名 `ui/point_shop_controller.gd` / `ui/point_shop_item_controller.gd`，按 Shop/ShopItem prefab 3840×2160 真值重放主块、行、按钮与链接卡预览；截图 `docs/ui_layout/pointshop_screenshot.png`。原 `save_samples/global.json` 已逐字段对拍 totalPoint/usedPoint/upgradeState/upgrade 的默认值；因样本没有已购买升级，**不宣称非默认升级存档已有真实样本对拍**。 | 🟡 原作 `Player.sudan_cards` 同时保存隐藏 Card 对象，而宿主仍以 id 队列+抽取时实例化承载；本配置 `g.change` 的开局手牌目标已覆盖，但该 Operation 对其他 Player.cards 区域的通用替换尚未迁。商店手柄 InputDisplay、LoopScrollRect 的选择保持/滚动插值、原 TMP 字体渲染细差及原作运行时截图逐帧对拍仍待完成；任务面板 TMP 字体细差同理 |
| Live2D | 语料库 `live2d/` 已提取 | 大（既定策略：第一版静态图） |
| ~~背包/手牌位系统（bag/bagpos/BagIndex）~~ | 已落地（2026-08-18 批次 E）：CardInstance.bag/bag_pos 持久化 + 日终压缩 + 导入桥透传与对拍（24 项）；三标签资格判据与多页包 UI 未做（三标签名留档） | — |
| end/armageddon 表现状态（`end_open/is_armageddon/armageddon_rite_id`） | **2026-09-03 状态边界已迁**：三字段按 Player@0x178/@0x179/@0x17C 原键进入 GameState、v8 存读档、原作导入桥与 49 项同刻对拍。**同日终局地图批次**：`RiteResultPanelController.<OnClose>b__0 0x5b51c0` 已在已提交的 5010009 结果关闭时精确写 `end_open`，不把其他 `final_pin` 仪式误判为终局；`ui/map_controller.gd.change_bg_to_end` 直接映射 `MapController.ChangeBGToEnd 0x567b70`，加载与语料 SHA-256 等值的 `table_map_end` 2048×1076 原图和 `Resources/image/end_map` 10 帧原图集，并按当前地点图名替换存在的同名帧；`MapController.Start 0x56a890` 的读档恢复由 `_ready` 回放，次日链通过桌面 refresh 幂等消费同一状态。实机渲染走查见 `docs/ui_layout/end_map_screenshot.png`。`is_armageddon/armageddon_rite_id` 实为 `sfx_config.armageddon_music_loop` 的仪式循环音乐恢复状态：`StartRite.Do 0x51bcf0` 处理 `play_in_rite_create=true`，结果关闭链处理 false，`GameController.Start`/次日 b__5 还原 Animator 参数。 | 🟡 终局主地图与地点帧已接；`Eft_End_Map` 是 GameScene 中含多层 ParticleSystem 的独立层级，尚未迁且未用自制效果替代。原始 `sfx_config.json` 尚未接入 `ConfigDB`，`LoopArmageddonController` 音频播放与两处写点仍待下一批；不得把此字段族扩写成自制“决战玩法模式” |
| RNG 续航（random_cache） | 存档字段双信号 | 小-中 |
| ~~激活苏丹卡的期限存档承载~~ | 已解（2026-08-18 批次 D）：期限 = 卡寿命模型（出生抢跑 + 每日 life+1 + 模板 card_vanishing 死亡），存档承载即 Card.life 本身；导入桥 days_left = vanish−life 精确恢复，仅 drawn_round 仍近似（难度中途切换后不可反推） | — |
| ~~原作苏丹抽牌序（sudan_pool_cards 顺序语义）~~ | 已解（2026-08-18 批次 D）：sudan_shuffle 开启时每次抽取先 Shuffle 再 RemoveLast，顺序无意义；克隆 pop_back 尾抽对齐 | — |
| ~~唯一性登记（only_cards/only_rites）~~ | 已落地（2026-08-18 批次 I）：`only_cards` = 已到桌的 `CardNode.is_only` 配置 id；`only_rites` = 成功 InitRite 的全部仪式 id；type-3 loot 每次抽取前按对应登记集过滤，删卡/删仪式不回退。导入桥对拍两项 | — |
| ~~生成计数（gen_cards/gen_tags）~~ | 已落地（2026-08-18 批次 J）：`gen_cards[id]` 在新建玩家卡时 +1；`gen_tags[code]` 对新卡 `GetTags` 的 HashSet 每个稳定 tag code +1，另承接 `Common.MarkTagGen` 回调语义。苏丹抽卡在池标签复制后显式登记；存档/导入桥双向对拍 | — |
| ~~改名持久化（custom_rite_name/player_card_name）~~ | 已落地（2026-08-18 批次 H）：玩家级配置 ID 覆盖表独立于 Card.custom_name/RiteInstance.custom_name；卡名覆盖优先于实例名，仪式名覆盖优先于配置名。证据：CardExtensions.c 0x37ff50 + Player.c 0x3a4520 / PlayerExtensions.c 0x38dcb0 + dump.cs Player@0x168/@0x170 | — |
| ~~UI 引导标志族（sudan_box_show/story/prestige/deadline/helpbtn、once_new_rites_is_show）~~（结构承载） | 已落地（2026-08-18 批次 N）：五个 Player HUD 标志 + 每仪式首见表进入 v7 存读档/导入桥；`close_*` 操作按原作 0=显示、非零=隐藏写对应字段。原作桌面 HUD 与仪式首见提示 UI 未接，故保持 semantic | 小 |
| ~~苏丹重抽恢复模型（times_per_round/times/recovery_round、sudan_card_init_life）~~ | 已落地（2026-08-18 批次 K）：Player 四字段进入 v7 存读档与导入桥；`RedrawSudanCard` 先用普通配额、再扣 7100008；`SetDifficulty` 只换额度和未来苏丹头起步，保留本周期已用数与 Init 恢复周期；日初按 recovery 周期清已用数 | — |
| ~~结局状态（success/over_reason）~~；~~cached_event（结构承载 + 桌面托盘 UI）~~ | 前者已落地（2026-08-18 批次 L）。后者批次 M 结构承载 + **2026-08-22 批次 AK 桌面托盘 1:1**：载入侧 = `OnCachedListChanged 0x553b70`（cachedEvents@GameController+0x320 字典差量重建：枚举 `Player.cached_event`@0x148 → `CachedEventPrefab`@0xA0 实例化到 `cachedEventContainer`@0x108 → `cachedEvents[id]=controller`；结尾 `SetActive(+0x220, 0<Count)` = **"Next Round Mask For Cached Event"**（GO 47/rect 7639，596×634，Image a=1/255 透明点击吸收器，场景 UnityEvent OnClick→`NoticeCachedEvent 0x5534d0` 摇动托盘））。**条目摆放谜底**：容器 Mono 11735 = HorizontalLayoutGroup 同构字段（m_Padding L0/R100/T0/B0、m_ChildAlignment 5=MiddleRight、m_Spacing 50、m_ReverseArrangement 1、control/expand/scale 全 0）——运行时布局组流式摆放，故 `CachedEventController.Init 0x527900` 无定位代码；条目 rect = 右→左（index 0 最右，right edge=3840−100，步进 112.5+50）。**条目**（`Resources/prefab/CachedEvent.prefab`）：checkbox_bg 112.5×117 + dialog 图标 192²@scale 0.5（视觉 96²居中）+ new 红点 85.5²@锚(1,1) pos(−7.9,−12.7)（顶右探出）+ **禁用** Shaker（positionIntension(0.2,−0.2)、freq 40、time 10、maxSpeed 2、perlin，`CachedEventController.Shake 0x527940` set_enabled(false/true) 重启；`Shaker.c` 已阅）。**点击链** `OnCachedEventClicked 0x5538e0`：`Datapool.can_cached_event_settlements` TryGetValue 命中→OperationMask@0x1C0 + `OperationsExtensions.Start` + b__0 0x5728d0 收尾隐藏+`RemoveCacheEvent`；未命中→直接 `RemoveCacheEvent`。克隆落地：`ui/cached_events_view.gd`（托盘 3840×128 + 右→左条目 + notice 抖动）+ GameScreen 集成（`refresh()` 按 `cached_event` 重建、点击=未命中分支移除、mask 显隐）+ 测试 2 条 + 截图 `docs/ui_layout/cachedevents_screenshot.png` + 新纹理 dialog.png/new.png。🟡/⬜：cached_settlement 结算分支（语料零实例，🟡 未接）；Shaker perlin 曲线/SmoothDamp 轮廓（🟡 视觉近似）；红点在点击后是否隐藏无证据（🟡）；StoryNotifyController 文字通知已迁至独立任务链行 | 小 |
| global.json 其余字段（gameStatistics/doneEvent/doneRite/showedPrompt/choosedOption/showedGalleryCards/图鉴/升级/任务/overRecord/meta counter） | `save_samples/global.json` 29 字段；承载容器 GlobalState 已落地（backToPrevRound/roundRollback + `overID`/`showedGalleryCards` HashSet）。**结局记录批次 AN 已迁原作分文件链**：`OverRecordStore` 1:1 对应 Datapool `Init/Load/Add/Delete/CheckOverRecordExcess`，读取 `over_record_excerpt.json` → `OVERRECORDDATA/over_record_No.{n}.json`，旧 `Global.overRecord` 仅作缺 excerpt 时迁移源；`OverRecordView` / `OverNodeView` 分别对应两个原控制器，列表顺序、坏档剔除、200 上限、动态计数、删除及 2301×360 行几何已接。**回忆详情批次 AO**：`OnMemoryClick 0x57cfc0 -> ShowOverInfo 0x57e1e0 -> LoadPlayerOverData 0x415e40 / LoadDefaultPlayerOverData 0x414c70 -> SetRecord/Init/Hide` 已直连；非空 `player_data` 复用原作存档导入及逐字段 diff，`text_extra.Length` 修正为真实 Story 门，record 最终返回画廊而不进入 Step3。原作样本只覆盖空记录；非空回忆用 `save_samples/auto_save.json` 作为 Player 产物裁判。截图 `docs/ui_layout/galleryover_screenshot.png`。🟡：完整 `AfterStoryItem` 翻页/放大控制、Story 打字机与动态人物头像尚未迁。 | 中（结局生成、升级/任务与其余 Global 域） |
| `[back_to_prev_count]` 文本占位符（Datapool.__c b__389_6 走 GetBackToPrevCount） | 原作配置中未发现该 token 的使用实例，token 拼写无法从语料确认 | 暂缓（不猜测命名） |
| ~~回退快照持久化（Datapool 轮次文件 + IsValidRoundEnd + LoadController.LoadRound）~~ | 已落地（2026-08-18 批次 F）：`round_{N}.json` / `round_{N}_end.json` 双边界持久化、有效性门、磁盘加载刷新 continue、档案恢复清理旧时间线；内存 round_snapshots 降为同进程缓存 | — |
| ~~仪式面板“恢复上次投放”（Player.last_round_rite_data）~~ | 已落地（2026-08-18 批次 G）：`OnConfirm` 按 Rite.id 记录手动槽 guid 的 `{id,count}`，`OnLastState` 按卡牌可用量与当前槽条件逐槽恢复；存读档与原作导入桥均承载。证据：RitePanelController.c 0x58f1c0 / 0x58fdf0 + dump.cs Player@0x158、LastCardData@0x10/@0x14、RiteNode.Slot.open_adsorb@0x20 | — |
| RoundRollbackType.BACK_TO_PREV_BEGIN(3) 的写点 | dump.cs:6186 枚举存在，写点未定位（LoadRoundBegin 疑似） | 小（待双信号） |
| 成就面板 | steam_achievement 空实现 | 可选 |
| 主菜单 ButtonsGroup 三键行（图鉴/商店/剧情，405×174 间距 240）+ Contacts 行 + Version 文本 | `docs/ui_layout/StartScene.md` 真值已备；图鉴/商店/剧情面板本体未复刻（D 表各行），社交链接对克隆无意义 | 随各面板批次接入 |

## 普查程序（如何扩展本表）

1. 从 `engine_spec/dump.cs` 提取运行时类清单（Controller / Manager / Panel 优先，JsonHandler 指路数据域）。
2. 每个类归入四状态之一，登记证据指针（文件 + RVA/行号）；查无克隆对应物即入 ⬜。
3. 每个复刻批次收尾时更新所 touched 的行；每个大阶段做一次 dump.cs 增量普查。
4. 表中新增 ✅ 必须附双信号；只有单信号时写 🟡 并注明缺口。

## 对拍台（验收裁判）

- **资产**：语料库 `save_samples/`（`auto_save.json`、`save_slot_000.json`、`global.json`、`user_archive.json`）= 原作真实存档，明文 JSON。
- **阶段 1 ✅（2026-08-17）**：schema 全解码——Player 60 字段与 dump.cs 双信号吻合，零未知零类型不符；映射表与工具落地（`sim/original_save_schema.gd` + `tools/export_save_diff.gd` + `tests/test_save_diff_harness.gd`，mapped 11 / semantic 11 / missing 38）；快照文档 `docs/ORIGINAL_SAVE_SCHEMA.md`。结构发现：金币=卡 2000029 堆叠（双信号）、骰子疑 counter、手牌=bag/bagpos、仪式槽位内嵌嵌套、UI 队列不持久化、回退双轨、random_cache。
- **阶段 2 ✅（2026-09-03 状态行增量）**：导入桥——原作存档 → 克隆 GameState → v8 payload → 同刻值对拍；语料 auto_save **49/49** 全过（含 only_cards / only_rites / gen_cards / gen_tags / 苏丹重抽 profile / 终局结果 / cached_event / HUD 标志族 / Player.pins / end_open / is_armageddon / armageddon_rite_id），差异按 converted / approximated / dropped 防静默登记。此后涉及状态的批次验收 = GUT 全绿 + 对拍零差异（或差异均有原作语义解释）。
- **远期**：固定种子 trace 对拍（同一操作脚本下原作 vs 克隆的事件/结算日志序列）。
- **UI 布局对拍 ✅（2026-08-18 批次 P）**：`tools/export_ui_layout.gd` 解析语料 AssetRipper 场景/prefab YAML，产出 RectTransform 真值表（锚点/位置/尺寸/pivot/缩放 + CanvasScaler + LayoutGroup 参数 + sprite guid→语料路径）至 `docs/ui_layout/`；主画布设计空间 = **3840×2160**。表现层批次的验收 = 每个摆位数字能回指真值表行；视觉证据用 `tools/dev_screenshot_runner.tscn` 截图。

## 仪式实机复核纠偏（2026-09-10，进行中）

原作实机 `original_runtime/rite_result_power_20260910.jpg` 与 `.prefab` 双信号确认此前结果表面存在坐标换算错误；以下修正优先于旧批次中的几何完成声明。

- `RiteResultPanel.prefab`：Result top-right anchor/pivot 折算为 `(1786.367,191.797)`；Op BG bottom-right 折算为 `(1804,1403)`；Next 相对 Op BG `(185,16)`，AutoPlay `(864,42)`；PlayRate `(3067,1441)`。标题 y=55。骰子两层 y=297/427。
- `RitePanelTitle.prefab`：Help 依附 CommonContent 中心，偏移 `(0,210)`，4096×2160；Prompt 自身偏移 `(-949,-233)`；Mask alpha=128/255。帮助文字必须保留父级几何，不能当全屏固定坐标。
- `RiteResultPanelController.c AddCardOp 0x5a0e60 / MoveOpCardsToResults 0x5a36f0 / AddCardToResults 0x5a0ff0` + dump.cs:325461–325462、321454–321455：Op Results/Op Hand Results 是按 OpCardShow.IsHandCard 分流的操作卡牌，不是 result/action DSL 键列表。删除无背书的 DSL 文字与槽卡快照伪结果，完整 CardOpContext 表现链仍缺失。
- 结算文案入口：`DisplayClass77_0.<DoPriorSettlement>b__3 0x5b5b70`、`DisplayClass79_0`、`AppendResultText 0x5a13e0` + content/variable.json 的 RITE_SETTLEMENT_RESULT_*。先恢复 prior/normal/extre 真实文本，去掉自制金币余额、检定键与“已执行N条”；TMP sprite/标题模板和串行承诺链单独列为未完成。

### 本批实现与验证补记

- 金骰/重投：`RiteResultDiceCountPromptController.c Show 0x59de70 / OnGoldAdd 0x59d360 / OnGoldCancel 0x59d6f0 / OnGoldConfirm 0x59d8b0 / OnRedraw 0x59dc40 / OnRedrawCancel 0x59da10`；dump.cs:324673–324752 的 GoldAddCount@0xD4/RedrawUsed@0xDC 与确认按钮字段为第二信号。源 prefab 左右壳层与四个确认/取消入口已落地，暂选不写玩家资源，确认才重结算。bg_5/gold_bg/gold_active 为有界源资产导入。
- `with_player_actor_context` 会 deep-copy ctx；UI 重算后必须重新绑定其持有的 live dice_cache，否则 FuncCompare.dices@0x40 缓存没有写回。修复于 RiteView._do_resolve；测试覆盖真实挂树的UI、选择2枚/取消/互斥/重复确认/原骰面保留。原依据 FuncCompare.IsSatisfied 0x3fc060 + DisplayClass88_0 b__5 0x5b7fe0。
- 结果文案开场来源 `Settlement 0x5a4800` RiteNode.text@0x20→ShowTextWithSeperator，回调 DisplayClass56_0 b__0 0x5b3300。结果正文 prefab TextTranslate 114117307842306080 实为 @MAIN_BODY、TMP paragraphSpacing=80；纠正旧错误样式。速度从 variable.json result_text_play_rate/result_text_auto_play_rate读取（dump.cs:387291–387293 + UpdateResultTextSpeed0x5a74a0），完整自动推进仍缺。
- Help TimePrompt 的 TMP verticalAlignment=1024（Bottom）已应用；原作实机 rite_help_20260910.jpg 与两尺寸宿主截图留档。DicesBG 原Sprite1744×1608，GameScene正交相机8.91、DiceShow1800高，投影尺寸按1800/1782计算；精确光照仍未回放。
- 真实输入：1280/1920准备拖放→开始→重开运行→锁槽→停止；结果金骰/重投/播放开关/继续；帮助两尺寸打开与关闭；事件等待1280。删除verify脚本直接调用处理函数的成功兜底。
- 回归：36/36仪式、172断言；81/81 UI、1096断言。516项全量初跑唯一失败为半像素位置取整，两层已保留源半单位坐标并通过相关组复跑。content parity3883/0。未改原作语料，未提交/推送。

**保留缺口**：CardOpContext→OpCardNew→OpCardShow→结果列表链；逐骰/成功环动画、数字精灵、金骰逐检定阶段；标题TMP模板；AutoPlay串行自动推进；整页同存档逐帧对拍。详见 `docs/ui_layout/PageFidelity.md` 最新节。此前“PlayRate y=275”“结果可用通用确认框”等记录作废。

### 2026-09-11 接手验收修订

本轮 A19 先修共享成本上下文：`CostCondition.IsSatisfied 0x3f6160` 按 `ConditionContext.is_adsorb@0x20` 分单卡/枚举，`is_first_drop@0x22` 决定取 Min；`PostProcess 0x3f6520` 按 Compare modifier 建立 Min/Max，不能丢比较符。独立证据 `dump.cs:383846` 上下文布局、`384167` ConditionModifier 枚举及 `Compare.c 0x3852a0/0x384eb0`。当前所有成本走枚举且忽略操作符的实现与源冲突，生产落槽接线必须在此边界修正后进行。

DeepSeek 第十九至三十六批已在工作区，接手记录见 [DeepSeekHandoffReview](audit/DeepSeekHandoffReview.md)。A19 付款辅助函数未接游戏拖卡，原 CardStack 已占槽合堆分支及完整条件上下文仍缺，不能按第36批文档标题认定完成；A21 原 CardSlotController.CardStack/DropCard 已有配音调用点，需继续追 SFxManager 选择与播放链。详细更正见 [CostPaymentExecutionCorrection](audit/CostPaymentExecutionCorrection.md)。

第38批 A19 生产接线：按 CardSlotController.CardStack 0x53b0a0 的 is_cost（而非 CanPutCard 布尔）门实现部分入金；已占槽同类卡用合并后的 current 身份、非首放上下文重新算 cost_count 后回退余量。CardDropManager.DropCard 0x4ef4f0 先尝试 CardStack 再 TryUpdateCard/DropCard。dump.cs current@0x148 与 ConditionContext.is_first_drop@0x22 为独立结构证据。

第38批验收见 [SlotCostInteractionCorrection](audit/SlotCostInteractionCorrection.md)：正成本入槽已接生产拖卡，原配置5000005的部分放入/补齐/超额保留与1280/1920实际GUI输入通过。A19仍有零成本、TryUpdateCard完整替换链及表现演出缺口，不标全完成。

第39批 A19：TryUpdateCard 0x598140 + dump.cs:324304 原型，CardSlotController.RecoveryCard 0x53c660 的 AddCard旧卡回手链。修复指定槽替换被自制自动路由截走，槽验证使用去掉目标槽的快照，拒绝时恢复引用。

第39批验证：指定槽替换与拒绝不改投已接，56测试/278断言及1280/1920实际GUI输入通过，见 [SlotReplacementCorrection](audit/SlotReplacementCorrection.md)。零成本等剩余边界继续开放。

第40批 A19数量边界：CardSlotController.CardStack 0x53b0a0 在cost_count=0时Copy后set_count(0)；Card.set_count 0x383e80直接写字段并通知，无最小1钳制。Card.count@0x20、CostCondition.PostProcess 0x3f6520的Min=0分支为独立信号。普查当前槽配置零个零成本入口，故为底层边界修复，不宣称当前内容运行可达。移除存档/导入/池对象的最小1转写，并允许0成本切片。

第40批收尾见 [ZeroCountBoundaryCorrection](audit/ZeroCountBoundaryCorrection.md)：54测试/389断言通过；零数量不再在导入/读档中变成1，HasTag堆叠门按有效值判断。当前配置零成本入口0处，清单保留其余未完成项。

第41批 A19 聚合条件：SlotHasTag.IsSatisfied 0x408cf0 + 闭包0x40bfb0对选中卡GetTag求和后比较；dump.cs:417790注册all/enemy/friend语法。OperationFilter.Filter 0x3a15c0的friend/enemy均走GetEnemyCardsWithIndex；其闭包0x3937b0实际保留Slot.is_enemy@0x29为false的卡（dump.cs:392754），不能按函数名反推。TryUpdateCard 0x598140临时清除目标槽，故聚合读取也必须使用排除目标的快照。此批不改FuncCompare的friends/enemys独立上下文规则；self/parent全链仍开放。

第41批验证见 [SlotAggregationCorrection](audit/SlotAggregationCorrection.md)：118测试/528断言通过，包含生产替换路径、模拟和原存档导入桥，最终日志无引擎错误或泄漏。CanPutCard额外adsorb_spec门已定位但未接，为A19下一项。

第42批 A19：CanPutCard 0x3918b0在条件通过后拒绝main.GetTag(adsorb_spec)>0且is_adsorb_spec为false的卡。HasTag.IsSatisfied 0x3fe5a0在main分支发现TagNode.attributes包含该键时，先调用SetAdsorbSpec 0x385520，再执行Compare。独立证据dump.cs TagNode.attributes@0x58、ConditionContext.is_adsorb_spec@0x21与stringliteral.json:10791。按执行顺序设置上下文标志，禁止预扫描未执行的条件来授权；CardStack仍按原is_cost独立门执行。ValidateTagAttributes 0x3831c0的附属属性写入链另有缺口，不能用本批代替。

第42批验证见 [AdsorbSpecGateCorrection](audit/AdsorbSpecGateCorrection.md)：87测试/459断言通过；真实auto_save uid120哲瓦德的标记验证了通用拒绝/指定允许和生产拖卡路径。无引擎错误或泄漏；下一批补标签附属属性写入生命周期，A19尚未全部完成。

第43批 A19属性生命周期：PlayerExtensions.AddCard 0x38b620遍历CardNode.tag的键（不按值过滤）并AddTag每个TagNode.attributes；ValidateTagAttributes 0x3831c0根据源tag.GetTag>0添加或移除attributes，Copy0x37f4e0在写入每个运行态增量后校验，最后赋count。Datapool.BuildInTags0x40d9b0/AddBuildInTag0x40c610将adsorb_spec注册为不可叠加、不可见内建tag；stringliteral0x25B3468=吸附指定，当前tag.json所有非空attributes均只含此键。普通标签基础AddTag/RemoveTag/ConvertToAddOrSub仍需另批全面修正，不把增量减法近似当作已完成。
