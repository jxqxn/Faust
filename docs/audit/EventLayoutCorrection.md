# 事件布局与确认按钮纠偏（2026-09-10）

对应 A07/A09。已消除本批列出的目测布局参数；不是整页像素一致验收。

## 证据与已改边界

只读原文件位于 `Faust-local-source/_unpack`。

- `PromptController.c Show 0x58a020`、`OptionController.c Show 0x576b50`、`ConfirmController.c Show 0x53fc30` 在赋文案后调用 ForceRebuildLayoutImmediate。`PromptControllerBase.c ShowInternal 0x589890` 分配立绘；`PromptIconController.c SetIcon 0x58a210` 对 null 禁用 Pos，字符串图调用 `UIImageExtensions.LoadSprite 0x40c210` 的 native-size 分支。
- `PromptNew.prefab` / `OptionNew.prefab`：根 Top minHeight100/flexible3500、Bottom minHeight400/flexible2000。2705宽 OptionBG 横排反向、padding L200/R100、spacing100。ContentGroup preferredWidth2000。空 IconGroup 本身仍 active，不能将其间距删掉。
- IconGroup spacing=-200，Pos 宽400；0/1/2/3张立绘时内容宽依次2000/1905/1705/1505。图按原 native texture size，移除400×500挤压。
- Prompt 内容前后 active 零高 flexible spacer，各50间距；Option 使用正文+Options间距50，Options 内间距20。`OptionNewItem.prefab` 根 Image 的 `option_item_bg.asset` 是1424×112、PPU100，首选行高112；文字全幅，无自制24边距。
- `ScrollViewContentHightWatcher.c LateUpdate 0x4342c0` 给 LayoutElement 写 preferredHeight 上限1300/1100；这不是最终 viewport 高度。父布局拥挤时仍可收缩。ConfirmNew 非滚动正文路径不套这两个 cap。
- 新 `source_layout_axis.gd` 承载 min/preferred/flexible 分配、反向排列和父约束；`dump.cs:430763/430766` 提供原布局接口签名。**原引擎该方法体未独立反编译，适配器不能登记为逐行源码翻译。** Godot文字首选高度仍与TMP存在度量差异。
- 上一批共用确认框漏读 `m_ReverseArrangement:1`：正文x从452.5纠正为352.5（200+居中留白152.5；空图组排在正文之后）。已同步修正上一批文档和测试。
- ConfirmNew Confirm/Cancel 的 ColorTint：normal白，highlight/selected .9607843，pressed .78431374，disabled RGB .78431374/alpha .5019608，fade .1，导航None。新增限定确认按钮的适配器，用原颜色与非缩放时间渐变取代1.15悬停增亮。档案页借用的按钮尚未核对各自prefab，未把确认框字段强加给它们。

## 验证

- UI布局81测试/1073断言、布局分配及多图长文/无滚动确认4/38、共用首选布局3/17，全部通过，无测试失败、引擎错误或泄漏报告。
- `verify_event_prompt_layout.gd`：1280×720、1920×1080 GPU实际输入。覆盖0–3立绘、未选禁确认、选项切换、确认恰好一次、长正文滚轮、两档字体变化后正文不遮选项。两档均 PASS。
- `verify_prompt_preferred_layout.gd`：两档GPU实际改名输入/确认/取消、共用确认点击、禁用/悬停/按下颜色终值，均 PASS。截图已刷新。
- 截图：`docs/ui_layout/event_icons_{0..3}_preferred_{1280,1920}.png`、`event_long_preferred_{1280,1920}.png`。人工查看三立绘1280、长文1920及确认1920图；自动截图不替代原机同状态对拍。

## 保留缺口

OptionNewItem 默认 Hightlight 是Unity内建九宫图，不是目前使用的黑色根背景；Toggle/Button的完整状态组合尚未迁。Full贴图PPU及变换、TMP行距/SDF/自动字号、卡牌扇形立绘材质与姿态仍有缺口。根布局已改不代表这些差异消失。本批未启动原作同帧对拍，不宣称A07整项完成。
