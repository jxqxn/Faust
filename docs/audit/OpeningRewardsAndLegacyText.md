# 开场奖励、抽卡顺序与遗留提示修正（2026-09-11）

## 用户反馈与根因

1. 对话确认贴图已有勾号，`EventPromptView._build_confirm` 又向同一 Button 写入“确认/继续”，造成叠绘。原作 `PromptNew.prefab` 的 Confirm（325×158）为图片加独立 InputDisplay，不包含这行居中文字。
2. 卡牌上方的棕色“某卡 放入 S1”来自 `RiteView` 自制 `RiteOverlayToast`，不是卡牌材质、原作槽位提示或原作文字动画。移除节点与内部写点，保留对外 set_log 空接收兼容宿主；原有槽位提示/高亮/合法性判定仍走各自控制器。
3. `ResultExec._apply_table_tag` 遍历 `surface_card_entries`，实际只含槽位卡和独立苏丹卡，遗漏 Player.cards 中的所有普通初始卡。又额外用 context.card_uid/rite_uid 缩小作用域。这使妻子获得追随者、家传铠甲获得已拥有、法拉杰获得追随者等原始开局配置不生效。
4. `Game._start_new_run` 发起开场事件后立即抽苏丹卡，忽略事件 Promise 等待选择的边界。

## 原作证据

- `decompiled/DesktopModifyTag.c` DoTemplate RVA 0x50e400：直接取 Player+0x88，交给 `OperationFilter.Filter(List<Card>)`；不读取 context 的卡/仪式归属。
- `il2cpp_dump/dump.cs:314110–314147`：table/g 注册至 DesktopModifyTag；`OperationFilter.c` Filter RVA 0x3a13c0 为列表谓词入口。
- `data/config/event/5310000.json` op3 给主角专属2增加已拥有并去除专属标记；5310002 op2 给主角专属1增加追随者；5310003 所有分支给妻子增加追随者。未改写或复制任何配置。
- `GameController.__c__DisplayClass141_0.c` b__5 RVA 0x56f9c0：OnRoundBeginBa 后 Promise 链绑定元数据 0x25ac328 / 0x25ac3a0 / 0x25ac058；对应 b__8 检查终局、b__9 HandCardArrange、b__10 TryGenSudanCard（检查 Player.disable_auto_gen_sudan_card）。
- `save_samples/auto_save.json` 首日 notes 的 10002/10001 独立记录家传铠甲2000368、法拉杰2000372、妻子2000006。不是所有开局分支的统一奖励表。

## 实现与验证边界

- table/g 标签操作使用既有匹配器，在普通未入槽卡和已抽出苏丹卡中匹配；不含仪式槽、装备与未抽卡池。
- 开场复用已可存档的 `round_transition`，增加 opening_events → opening_draw → opening_complete；待原始操作队列结清再排列手牌和抽卡，期间不会推进到第2天。
- `tests/test_opening_ui.gd` 走真实主场景 `_start_new_run` 和 OptionGroup/Confirm 按钮信号。按原作存档对应分支选军事贵族、言辞、法拉杰、智慧妻子；逐步骤验证奖励可见，全部开场等待期间无苏丹任务卡，结束后一张。普通手牌 ID 与原作 notes 推导的四张一致。
- `tests/test_startup_rites.gd` 验证等待中存读档、重复 resume 不重复抽卡，以及 context 不得把桌面标签操作窄化到仪式槽。
- 旧 card_instance 测试把人物苏丹2000024伪装为独立倒计时卡，初始人口完整后因此多造一张。改用原有初始人物；保险事件按原 `table_have.2000024` 前提放在桌面，不伪造无归属仪式槽。
- UI 布局测试的跳过开场辅助函数现在明确清除整条开场过渡；它是几何测试夹具，不能当开局验收。真实开局另由上述 UI 测试负责。

截图：`docs/ui_layout/opening_wife_confirm.png`、`opening_reward_hand.png`、`rite_drop_no_toast.png`。截图来自克隆实际 Vulkan 窗口；本批未重启原作进行新的双窗像素差分。当前验证不代表所有开场地图/动画、所有 DSL 方法已完整还原。

旧存档已消费的错误开场选择不会被静默重放或补发奖励；需新游戏验证完整开场。本批未提交或推送，保留此前会话的工作区改动。

## 本批最终检查

- 七组定向 GUT：140/140 测试，1901 断言通过（startup_rites、opening_ui、event_choice_controller、card_instance、sudan、rite_input_contract、ui_layout）。未重跑全库。
- `opening_ui` 在实际 1920×1080 Vulkan 窗口复验，并检查最终截图；屏幕测试画布取真实逻辑视口尺寸，避免测试夹具缩成半幅。
- `tools/verify_rite_slot_input.gd` 实际鼠标输入走查 PASS；拖入后断言不存在 RiteOverlayToast，截图无旧文字。
- 上述最终日志无 SCRIPT ERROR、ERROR、orphan 或泄漏诊断；`git diff --check` 通过。
- 原作配置未改动。日志在 `C:/Users/User/Documents/Faust-cleanup-20260911/opening-*.log`。
