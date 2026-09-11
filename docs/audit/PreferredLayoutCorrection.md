# 首选尺寸布局纠偏（2026-09-10）

对应 ApproximationAudit A08/A09，以及 A10 的样式订阅边界。**本批不是所有弹窗或 TMP 自动字号完成。** 不再用截图高度替代已能从 Prefab 读出的布局计算。

## 原作证据与计算

原文件均在只读 `Faust-local-source/_unpack`。

| 边界 | 直接证据 | 本批结果 |
| --- | --- | --- |
| 改名面板高度 | PromptChangeName.prefab:882起：PromptBG LayoutGroup padding L270/R300/T200/B400、spacing0、control width/height；ContentSizeFitter VerticalFit2。Full/Icon/Border/Confirm/Cancel均ignoreLayout | 高度=600+正文首选高度；取消220固定值，画布居中 |
| 改名内容层级 | 同Prefab Content的children包含InputField、Content Invalid Prompt；Input锚(.5,0)、pos(0,-36)、826×90、pivot(.5,1)；错误行锚(.5,.5)、pos(0,-227)、324×48 | 两个节点移回Content内部；Input顶部=正文底+36，错误行不参与根布局高度 |
| 动态文字 | TextTranslate.UpdateTextInternal 0x1566ad0 / UpdateFontSize 0x1566920；dump.cs TextStyleNode:393716起；Prefab TextTranslate key=PROMPT_CHANGE_NAME_TITLE；textstyle.json同键css_size=40/45/50/55/65/75 | 改名标题接源字体/字号类并随偏好重排，删除固定fs40。原输入Text另用@TITLE_H3 |
| 文字与取消图 | 同Prefab Content m_fontColor=(.8627451,.8117647,.6039216,1)，Input Text=(1,.9764706,.6862745,1)，Placeholder灰.8113208/alpha.5；Cancel Image启用、guid c2d4c863f62df2d40985630eed19eb33→Sprite/rite_op_cancel.asset.meta；CancelText alpha0 | 恢复正确文字颜色、漏掉的取消图；不再靠暗色自制取消文字充当按钮图 |
| 无立绘共用确认框 | ConfirmController.Show 0x53fc30（ConfirmController.c:42–53）调用ShowInternal、AssignTranslateText、ForceRebuildLayoutImmediate；dump.cs:318365起。ConfirmNew.prefab OptionBG padding L200/R100/T150/B200、spacing100；ContentGroup preferredWidth2000，正文前后各一个active零高flexible spacer，spacing50；空IconGroup自身active、三Pos inactive | 高度=正文首选高度+450；正文宽2000，位置(352.5,200)。删除max560、正文2205×160与目测x250。当前共用确认框只承载无立绘路径 |
| 字号订阅门 | TextTranslate.UpdateTextInternal:198起，仅!enableAutoSize且css_size非空才订阅；dump TextStyleNode offsets .21/.40 | 共享SourceTextStyle加入相同条件。当前配置没有auto+css同时出现的条目，因此不夸大为已改变现有自动字号行为 |

确认框横坐标推导：可用宽=2705−200−100=2405；空IconGroup宽0+spacing100+ContentGroup宽2000=2100；MiddleCenter留白(2405−2100)/2=152.5；m_ReverseArrangement=1使正文先于空IconGroup排列，正文x=200+152.5=352.5。高度来自350上下padding+两个50间距，不把零高spacer删除后再凭目测补偿。

## Godot适配与新发现

Unity TMP文字节点可以拥有超出文字矩形的输入子节点。改回真实层级后，GPU输入测试发现Godot RichTextLabel默认裁剪使输入框不可见、点不到；本批显式关闭该节点clip_contents，保持原父子坐标并恢复真实输入。不能只看节点坐标测试全绿。

正文的首选行高由Godot字体排版给出，布局计算遵循上述源字段。保留独立renderer差异：TMP行距/段距与SDF材质、自动字号搜索及压字算法、改名输入的独立placeholder字体与TextArea边距尚未完整迁移；改名背景目前仍有原贴图拉伸/Full层缺口。**未把这些实现说成像素级等价。** EventPromptView的多立绘、多选项、根Top/Bottom布局后续已在[第三批](EventLayoutCorrection.md)修正；渲染剩余差异见该文。

## 验证

- GUT：UI布局81/1075，首选布局新增3/17，源文字样式4/19，档案流3/19；合计91测试、1130断言。
- 首选布局测试：正文变长增高、变短回缩；改名字号变化重排；输入相对正文定位；错误提示不污染父布局；确认只提交一次。
- `tools/verify_prompt_preferred_layout.gd`：1280×720、1920×1080 GPU及真正输入事件，点击LineEdit→输入A→确认→取消；共用确认按钮实际可点。纯隔离页面，不写玩家存档。截图 `docs/ui_layout/{changename,confirm}_preferred_{1280,1920}.png`，已检查渲染。
- `tools/verify_archive_flow.gd` 1280×720：覆盖/载入确认的实际点击链通过；工具使用其独立测试存档目录。
- 最终相关日志无SCRIPT ERROR/ERROR、失败、orphan或泄漏报告，diff检查通过。最初输入验证失败已修正后重跑，不能引用首次菜单误截图作为改名验收。
- 本批没有新启动原作同状态对拍；证据为原方法+Prefab+配置，GPU与输入验证证明宿主实施，没有替代原机最终验收。
