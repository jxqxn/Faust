# 2026-09-13 提示框复审（保持 🟡）

## 原作证据

Computer Use 在本机原作继续游戏，点击下一天，依次确认“权力的游戏”“治理家业”，白昼后出现事件5300098。2560×1440实机图见 [original_market_prompt.jpg](original_market_prompt.jpg)。短正文无滚动条，图片确认按钮可关闭提示。尚未取得原作长正文溢出的同态拖动证据，不能据本图声称长滚动条已一致。

## 本轮修正

- PromptNew.prefab：VerticalScrollbarVisibility=1（AutoHide），Viewport宽为ScrollView宽−30；独立轨道宽6、左边位于ScrollView右边+4。SlidingArea相对轨道为(-10,5)、27×(H−10)，Handle额外高度20。移除内置白条绘制及命中，滚动数值继续由RichTextLabel范围承载，外部控件显示源贴图并处理拖动。
- Sprite.border为左、下、右、上。轨道九宫格换算为L0/T212/R0/B171，滑块为L9/T58/R9/B77。Handle颜色normal=1、hover=245/255、pressed=200/255，渐变0.1秒。
- PromptControllerBase.ShowInternal 0x589890、PromptController.Show 0x58a020、dump.cs:364756及5300098.json：+10相对当前字号，不是绝对10。Title SDF的源字体为XiQueGuZiDianTiJFT.ttf；Godot嵌套b覆盖显式字体时，在b内恢复源字体。
- 原始PROMPT_RITE_START_RESULT使用125%字号与inline align=left。百分比随当前字号计算；left标签不输出Godot段落标签，避免把行首圆点挤到单独一段。事件/选项/卡详情/仪式正文与结算保留原始markup，修改字体偏好时重新计算。
- StartRite.Do 0x51bcf0 → OperationContext.AddExtraResult_RiteStart 0x39f810 → Prompt.Do 0x519340：新增仪式的提示文本进入可序列化操作序列，后续prompt取出并清空。门为Rite.new_born@0x20，不是is_show@0x21；模板和分隔符直接取content/ui.json及variable.json。
- NoPromptOperations.Do 0x5001f0及完成回调0x506390：进入前保存旧附加文本，内部操作完成后清理并恢复。dump.cs:312546–312560的context/current字段为独立信号。操作帧保存该恢复边界，暂停并JSON重建后仍有效；显式内部prompt并不被屏蔽。

## 验证

[clone_market_prompt.png](clone_market_prompt.png) 为1920×1080正式场景GPU截图。复现：`tools/dev_screenshot_runner.tscn -- --new-game --market-prompt --frames 20 --out <path>`。现在执行实际5300098事件（预置其7000060=5条件），因此包含“事件 做好准备 出现了”。这不等于重放了前四天：背景桌面状态与原作样本仍不同。

| 检查 | 最新结果 | 范围 |
|---|---|---|
| 最近完整回归（布局/事件/仪式/跨日改动前）763测试，762通过，1 GPU Pending，7416断言；本轮改动后的专项：UI布局81/81、提示8/8、事件12/12、仪式39/39、跨日2/2、独立进程6/6 | 72脚本；最新no_prompt边界添加前运行；无引擎错误、泄漏、孤儿诊断 |
| test_prompt_source_groups | 8/8，87断言 | 1920×1080及1280×720真实滚轮和滑块拖动，命中控件、最大值、按下色、释放、长转短、重建、字体偏好变更 |
| test_source_text_style | 7/7，39断言 | 最新百分比与行首圆点转换，以及原字体偏好存读档 |
| test_event_choice_controller | 12/12，100断言 | 原始事件生成提示→磁盘保存读档→重建GameScreen→真实鼠标确认→队列清空且不重复造仪式；no_prompt嵌套恢复和只消费一次 |
| test_rite_view | 39/39，196断言 | 相对文本接入后仪式准备、结果与交互回归 |
| test_next_day_mask（前轮独立GPU） | 1/1，18断言 | 最大相邻采样跳变0.003921598；证明连续性，不是原作逐帧一致 |
| verify_next_day_restart.ps1 | 6个独立GPU进程，62检查，零失败 | 第1→2→3日夜幕、白昼、稳定态恢复；隔离fixture禁用事件/仪式，仅验证过渡调度，不算真实内容前三日验收 |

完整测试输出位于系统临时目录faust-final-all.log、faust-final-all.stderr.log；本轮专项日志为faust-prompt-spacing.log、faust-event-final.log、faust-rite-final.log、faust-next-day-text-final.log、faust-ui-final.log。独立进程的正式日志及截图位于../next_day_runtime/process_restart/。

## 仍未闭合

1. 原作长提示的同场景逐帧拖动与惯性尚未取得；当前外部滑块已覆盖真实拖动，轨道点击按源ScrollRect分页一步。
2. 长提示原作同场景滚动过程仍待逐帧对拍。TMP lineSpacing=7、paragraphSpacing=69已按基础字号×0.01接入；PromptIconController.SetIcon 0x58a210的Sprite裁切/PPU已导出为AtlasTexture。position_shangye_1为1036.9398×701.89734，立绘不再按整张1148×744背景图显示。面板与原作完整运行时状态的逐帧位置仍保留差异记录。
3. OperationContext卡牌附加结果、option/confirm消费及跨事件上下文继承未全部迁移；本轮仅覆盖仪式→prompt及no_prompt保存恢复边界。
4. 仪式正文/结算相对markup已接入字体偏好更新，保存source_text并兼容旧版仅BBCode快照；仪式专项39/39、196断言通过。test_next_day_resume 2/2、146断言通过，包括原作样本两次连续跨日、提示及最终结果的磁盘保存/重建、原始markup与显示文本保留。
5. 完整前几日真实内容、每个覆盖层和中断阶段、逐帧声音对拍仍有缺口，不能将本批标成全项目像素级完成或全项目已满足推送门禁。
