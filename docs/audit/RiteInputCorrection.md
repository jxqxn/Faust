# 仪式手牌输入与槽位高亮复核（2026-09-11）

这是仪式整体整改中的输入批次，不是整套仪式完成声明。

## 根因与修正

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

## 验证

仓库外日志：`C:/Users/User/Documents/Faust-cleanup-20260911/`。

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

## 尚未验收

1. 本批没有重新做原作同存档、同帧截图差分，不能声称像素已完全一致。
2. CheckSlotPops 投放后的角色对话，以及 Prompt 材质参数动画尚未完整迁移。
3. 前批记录的逐项 PreDo/骰子/卡牌演出、附加事件结算、OnClose 时机、读档恢复仍开放。
4. 模态/输入顺序已通过这里列出的流程，未冒称所有仪式、所有模态组合遍历完成。

## 二次复核：共同根因而非仪式特例

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

## 2026-09-11 槽卡拖出：归属切换时点

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

验证（日志在仓库外 `C:/Users/User/Documents/Faust-cleanup-20260911/`）：

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
