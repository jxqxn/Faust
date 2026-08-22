# BeginGuide 桌面布局真值表

原作来源：

- `unity_export/ExportedProject/Assets/Scenes/GameScene.unity`
  `MainUI/Prompt/BeginGuide/Default`
- `engine_spec/decompiled/BeginGuideController.c`
  `ShowBeginGuide` (RVA `0x526220`) / `GetBeginGuideItem` (`0x525630`)
- `engine_spec/decompiled/BeginGuideItemController.c`
  `Show` (`0x527450`) / `SetPos` (`0x526dd0`) / `CloseInternal` (`0x526710`)
- `il2cpp_dump/dump.cs` `BeginGuideController` / `BeginGuideItemController`
  （约 316733 行）

## `Default`（3840×2160 画布）

| 节点 | 原作 RectTransform | 克隆落点 |
| --- | --- | --- |
| `BeginGuide` | 全屏 stretch | `BeginGuideBar` 保留 3840×2160 父画布，再随 `GameScreen` 等比缩放 |
| `Default` | center，anchored `(747.3,-785)`，`1200×460` | 解析后左上 `(2067.3,65)`，直接写入 |
| `Default/Close` | right-bottom，`(-10.9,-10)`，`80×80` | `(1149.1,410)` / `80×80`，`close_1.png` |
| `Default/Image` | center，`(-756,0)`，`400×400` | `(-356,30)`；故意从左边溢出，不裁剪 |
| `Default/Text` | stretch，`sizeDelta=(-70,-70)` | `(35,35)` / `1130×390`，font size 75 |
| `Default/Ring` | center，`(-706,-337)`，`314×225` | `(-263,-219.5)` / `314×225`，`single_ring.png` |

## 已对齐与保留项

`ShowBeginGuide` 先取得 `BeginGuideItem`，再调用 `Show`；关闭路径为
`OnCloseBtnClick → CloseInternal → BeginGuideController.OnClose`，后者触发
`OnCloseBeginGuide`。克隆的 `begin_guide` 指令与关闭写点继续复用该状态边界。

本批只对拍桌面 `Default` 几何与关闭入口。`GetBeginGuideItem` 的目标卡/槽/按钮路由、
`SetPos` 的运行时 anchor 数组改写和点击目标转发仍未完整承载；它们不因默认面板已对齐而
视作完成。
