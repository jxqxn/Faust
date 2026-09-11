# SourceTips 原作证据与修正（2026-09-11）

本页替代此前失真的真值表；旧版关于 1920 分母、偏移、永不启用 Left、未知 key
不显示的结论均已撤销。普通鼠标提示已接通，尚不宣称原作实机像素级对拍完成。

## 常量必须按 PE 节表取值

原作 `GameAssembly.dll` 只读。反编译的 `DAT_181…` 是 VA；先减 ImageBase
`0x180000000` 得 RVA，再通过节表换成文件偏移。旧探针直接把 RVA 当文件偏移，
读错位置，继而把可解析的常量误记为未知。

可复验工具：`tools/read_pe_floats.py <GameAssembly.dll> <RVA...>`。

| RVA | raw offset | float32 值 | 用途 |
| --- | --- | --- | --- |
| 0x1c9e564 | 0x1c9cd64 | 0.800000011920929 | 水平与上部判断阈值 |
| 0x1c9e7d0 | 0x1c9cfd0 | 3840 | 宽度基准 |
| 0x1c9e7cc | 0x1c9cfcc | 2160 | 高度基准 |
| 0x1c92b48 | 0x1c91348 | 0.20000000298023224 | 右下分带 |
| 0x1c92b4c | 0x1c9134c | 0.5 | 半高 |
| 0x1c9e5f8 | 0x1c9cdf8 | 50 | 水平夹取边距 |
| 0x1c9e5fc | 0x1c9cdfc | 150 | 纵向夹取余量 |
| 0x1c9e7b4 / 0x1c9e7d8 | 0x1c9cfb4 / 0x1c9cfd8 | +0.185185179 / -0.185185179 | OFFSET 世界单位 |
| 0x1c9e7dc / 0x1c9e7b8 | 0x1c9cfdc / 0x1c9cfb8 | -0.277777791 / +0.462962955 | RIGHT_BOTTOM |
| 0x1c9e7d4 / 0x1c9e7d8 | 0x1c9cfd4 / 0x1c9cfd8 | -0.092592590 / -0.185185179 | RIGHT_TOP |

背书：`SlotTipsController.c` set_Width **0x5aca50**、SetPositionInternal
**0x5ac340**、.cctor **0x5ac920**；`dump.cs:326121` 字段及签名。

## 布局与变换

`Tips.prefab` 根 900×164，Unity pivot(0.5,1) 是**上边中心**。Right 锚在根中心，
pivot(0,.5)，因此它的左边位于根 x=450，不是旧实现的 x=50。
Right 的 sizeDelta.y=0，ContentSizeFitter VerticalFit=2 决定实际高度；Left 的
序列化 164 不是固定高度。两边 padding 四向 60。文字 @TIPS_FORMAT，md=30，
xiquemuye，颜色 #DDD5C4。克隆使用 Godot 字体排版，TMP 行高差异仍待实机测量。

Border 的 **sprite** 是13×75，但 RectTransform sizeDelta=(13,0)，上下 stretch；
因此边框高度随面板变化。右边面的边框左上 x=-17（-4减13），不是旧值+9。
使用 NinePatchRect 保留 top23/bottom26 切片。

Left 初始隐藏，但 SetPositionInternal 会主动启用它。Left Y轴旋转180度，背景与
边框镜像；LeftText 再旋转180度，文字不倒置。克隆复用面板、镜像背景并换边框位置。

## 位置与宽度

`set_Width`: `sizeDelta.x = Screen.width * NeedWidth / 3840`。1920窗口、NeedWidth1000
得到500个面板局部单位；没有把它擅自改成“半屏”。NeedWidth=0保留800。

`SetPositionInternal` 先取指针屏幕比例，再夹取指针坐标，最后投影和加世界偏移。
水平右侧严格为 x/width>0.8；纵向使用 **Unity Y向上**。上部>0.8和下部<0.2仅在
右侧切换偏移。禁止把最终面板矩形再钳回窗口，那会改变原作顺序。

GameApplication.ScreenToDesktopPoint **0x43e7f0** 读取桌面相机作射线/平面求交。
当前平面UI投影按 GameScene 正交相机 size=5（屏高10世界单位）折叠；2160设计空间
对应偏移(40,40)、(-60,-100)、(-20,40)，Godot Y向下。克隆不另建可动3D桌面相机；
跨相机变换的等价性仍是限制，不能写成“所有场景无差异”。

Godot鼠标事件按canvas逆变换转换为本控件坐标；面板只缩放一次，不再把指针
除以窗口比例后又放到屏幕坐标。`_process` 跟随最近输入，避免注入事件后读取旧OS指针。
窗口大小与逻辑viewport大小分开传入。

## 文字与生命周期

`TipsHolder.GetTipText 0x5c4400`：委托优先，其次非空TipsId翻译，否则字面量。
`Datapool.Translate 0x422740` 两表都未命中时直接返回key，GetTipText直接返回该结果，
不存在“同一个key在GetTipText变成null”的隐藏规则。只有最终空文字才早退。
默认简体来自 `content/ui.json`，不混用 zhTW 译文。

attach绑定具体目标；重复attach不重复连接；离开/隐藏/移除目标都会关闭提示。
真实viewport输入回归覆盖整理、回退、处决日、背包、俺寻思，1280×720和1920×1080。
已修复Godot手牌大矩形挡住背包/俺寻思命中的问题。处决日浮层按可见绘制顺序参与命中。
截图工具通过 `push_input(event, true)` 触发hover，不再调用show_for伪装鼠标成功。

## 6. `GameScene.unity` 里的 TipsHolder 清单（30 处 / 16 个 id）

| TipsId | GameObject 路径 | NeedWidth | 克隆状态 |
| --- | --- | --- | --- |
| `BACK_TO_LAST_ROUND_BEGIN_TIPS` | `MainUI/Next Round/PrevRound` | 1000 | ✅ 已接 |
| `BACK_TO_ROUND_BEGIN_TIPS` | `MainUI/Next Round/BeginRound` | 1000 | ⬜ `BeginRound` 按钮本身未建 |
| `SORT_HAND_CARD_TIPS` | `MainUI/Next Round/Sort` | 1000 | ✅ 已接（按钮同批补建） |
| `EXECUTION_DAY_TIPS` | `MainUI/RoundNumber BG` | 0 | ✅ 已接 |
| `ITHINK_TIPS` | `MainUI/IThink` | 0 | ✅ 已接（`ThinkDropZone`） |
| `BAG_POS_1..4_TIPS` | `MainUI/BagBtnGroup/BagGroup/{0..3}` | 0 | ✅ 已接 |
| `BAG_EXPANSION_TIPS` | `MainUI/BagBtnGroup/BagShow` | 0 | ⬜ 背包展开按钮未建 |
| `BAG_AUTO_CLASSIFY_TIPS` | `MainUI/HandBagPanel/AutoClassify` | 0 | ⬜ 自动分类控件未建 |
| `RITE_STOP_TIPS` | `MainUI/UI/RitePanel{,Show}/…/Stop` | 0 | ⬜ 仪式停止按钮的 holder 未接 |
| `RITE_AUTO_FILL_TIPS` | `…/Last State` | 0 | ⬜ |
| `RITE_AUTO_SETTLEMENT_TIPS` | `…/Toggle` | 0 | ⬜ |
| `RITE_FIGHT_EVENT_TIPS` | `…/Header/FightEvent` | 0 | ⬜ |
| `RITE_AUTO_RESULT_TIPS` | `MainUI/UI/RiteResultPanel/Op BG/AutoPlay` | 0 | ⬜ |
| （动态，`UpdateTips` 委托） | `MainUI/Prestige/7100001..6` | 0 | ⬜ 文本由运行期委托产生，需先定位委托绑定 |
| （动态） | `MainUI/SudanBox` | **1800** | ⬜ 同上 |
| （动态） | `MainUI/UI/RiteResultPanel/Dice Prompt/Type` 等 4 处 | 0 | ⬜ 同上 |

`SelectionTipsOffset` 与 `SelectionTipsElapseTime`（手柄选中 3 秒后弹提示）是**手柄**路径，
本批次只做鼠标悬停；`OnSelect`/`OnDeselect` 分支未接，一并留档。


## 验收边界

普通提示本批修正；静态仪式holder、动态文本委托、手柄延时和手机版仍按上表留档。
后续复核纠正：CardSlotController.Init/ShowTips 使用同一个 TipsHolder，传入 Slot.text；
并非另一种提示表面。本次已接入鼠标槽位提示。实机原作截图对拍、TMP逐字像素
一致性没有在本轮完成；自动截图只证明克隆真实渲染与输入链可用。
