# 仪式槽与俺寻思交互修复（2026-09-11）

## 已确认与修正

- `CardSlotController.Init 0x53b940 / ShowTips 0x53cce0`：Slot.text 进入
  TipsHolder literal 字段，不是第二种提示面板。使用共享 TipsView，去掉默认 tooltip。
- `CardSlot.prefab` Highlight 状态组件只在 Highlighted 激活；精灵 GUID
  `4b17a277b119abb4ab3c783885530d47` 对应 card_outline。矩形 256×512，槽内 (8,11)。
- `ThinkController.OnPointerEnter 0x5c3330 / OnPointerExit 0x5c3440` 与
  `IThink.controller`：拖入 Hover 对应 Open，离开 Close，Idle/Thinking 为原作精灵动画。
  本地播放器直接读取原始 .anim 的帧键/时间/循环，不再使用自制旋转缩放动画。
- 59 个原始动画、控制器、Sprite 描述和图片逐文件 SHA256 与语料一致。
- 后续根因批次删除同步兼容桥。SlotPop 提示 → ThinkOver 2 秒锁卡 → 共享
  RiteSettlement：全部 result → 卡归还 → 全部 action → 实例移除。创建阅读仪式
  的 action 在卡归还后执行，open_adsorb 因此能找到书牌。可暂停、保存并恢复。
- 提示框支持未挂树时的布局计算，避免批量模板测试空引用。

## 输入验证

`tools/verify_rite_think_input.gd` 启动完整桌面，通过 viewport 鼠标按下、移动、抬起：

1. Idle 在 0.2 秒后更换原始精灵帧。
2. 拖入 2000472：进入 Thinking，产生提示；处理提示后创建 5000113。
3. 书牌归属新仪式，不在手牌中重复出现；动画回到 Idle，可接受下一张牌。
4. 打开治理家业，悬停 s1：显示原配置提示与高亮；移开隐藏。

最终输入验证 PASS。截图：`think_idle.png`、`rite_slot_hover.png`。
专项 GUT：rite_view 36/36、source_tips 8/8、dsl_batch1 43/43、ui_layout 81/81，
合计 168 测试通过；最终专项日志无 SCRIPT ERROR/ERROR、孤儿或泄漏记录。
测试日志位于仓库外 `C:/Users/User/Documents/Faust-cleanup-20260911/`。

## 尚未完成

- `ProcessPop 0x5c38b0` 的 +0xB0 是 RiteNode.cards_slot；其闭包字段为
  SlotPop（dump.cs:327529），不是 settlement 或 settlement_prior。
  旧 Methinks 注释把它当作多条 settlement 的依据是错误的，不能继续引用为事实。
- ThinkOver 的 2 秒锁卡边界、WaitingProcessDone/Close/Idle 状态转换已接；
  effect/Folder 曲线、解锁卡牌的移动演出、音效仍未完整移植。
- ithink_card_uid 与 think_session 已进入克隆存读档；原作 ithink_card 的导入映射仍待补。
- 最新输入复验 `rite-think-input-final.log` 为 PASS，明确断言锁卡前不生成阅读仪式，
  完成后书牌只有一个仪式所有者。它验证 Godot 输入链，不能替代原作实机对拍。
- 仪式浮层打开时仍按现有模态边界阻止向底层俺寻思投卡，该边界未做原作实机对照。
- 精灵裁剪/pivot、TMP 文本、填槽时高亮与拖入闪烁，以及原作实机像素对拍尚未验收。
- 本轮中间版本全量 GUT 692：687 通过、4 失败、1 risky；其中新增动画状态对应旧
  断言已更新，其他三项为已知 card_flash / event_prompt / book_search 失败。
  中间版本提示框空引用已修复，专项日志重新扫描，不能将该全量结果称为全绿。
