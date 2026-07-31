# UI 架构验收矩阵

本文是主游戏 UI 的状态、归属和层级契约。任何改变 `GameScreen`、
`ThoughtWorld`、菜单或卡牌轨道的提交，都必须先通过对应自动测试，再按本表
在 1280x720 和窄宽度窗口各进行一次截图核对。

## 长期节点归属

| 对象 | 唯一长期父节点 | 出现状态 | 禁止出现状态 |
| --- | --- | --- | --- |
| 地点印记、档案、桌面拖放思考按钮 | `SituationDesk` | 形势桌 | 现场探索、现场思考 |
| 仪式 pin、思考遮罩、思考连线、现场思考按钮 | `ThoughtWorld` | 现场思考 | 形势桌 |
| 手牌轨道、下一天、HUD | `GameScreen` | 所有游戏表面 | 无 |
| 仪式/事件/卡牌细节弹窗 | `GameScreen/OverlayLayer` | 局部模态 | 被全局菜单遮挡时不可输入 |
| 游戏菜单、手动存档页及其遮罩 | `Game` | 全局模态 | 无；必须压过所有游戏内容 |

不得为了临时显示把一个节点 reparent 到另一个表面。显示由状态决定，归属不变。

## 表面状态机

`GameScreen.PresentationState` 是中央表面的唯一状态源：`DESK`、`SCENE`、
`SCENE_THINKING`。只有 `GameScreen._set_presentation_state()` 可以切换形势桌与
现场的可见性；按钮只请求状态转换，不能直接改另一张表面的 `visible`。

| 起点 | 可见入口 | 终点 | 不变条件 |
| --- | --- | --- | --- |
| `DESK` | 当前现场档案 | `SCENE` | 手牌、HUD、进行中仪式数据不重建 |
| `SCENE` | 现场“思考” | `SCENE_THINKING` | `ThoughtWorld` 内的 mask、pin、连线一起呈现 |
| `SCENE_THINKING` | 思考返回/ESC | `SCENE` | pin 仍留在 `ThoughtWorld`，仅不可见 |
| `SCENE` 或 `SCENE_THINKING` | 返回形势桌 | `DESK` | 桌面恢复；现场思考先退出 |

## 状态与层级预算

| 层级 | z 区间 | 内容 |
| --- | --- | --- |
| 现场内容 | 0-99 | 背景、角色、思考特效、仪式 pin |
| 局部模态 | 100 | 仪式、队列、卡牌细节 |
| 常驻操作 | 200 | 手牌轨道、下一天 |
| 全局模态 | 1000 | 游戏菜单、手动存档页、全屏输入遮罩 |

全局模态的根节点和遮罩都必须使用 `MOUSE_FILTER_STOP`。局部模态可按设计让
手牌保持可见；全局模态不允许任何下层内容或输入穿透。

## 玩家路径截图

按顺序操作并截图；不得用隐藏节点的信号替代可见入口。

1. `desk-default`：形势桌是唯一中央表面；仪式 pin 不出现；桌面“思考”是拖放目标。
2. `scene-open`：点击可见的“当前现场档案”后，现场出现，桌面完全隐藏。
3. `scene-thinking`：点击可见的现场“思考”后，遮罩、思考姿态、仪式 pin 与角色到 pin 的连线同时出现。
4. `rite-local-modal`：点击可见 pin 后，仪式弹窗阻断现场；pin 不再可点。
5. `global-menu-over-local-modal`：在局部模态仍存在时打开菜单；菜单遮住角色、手牌、局部弹窗和所有场景内容。
6. `menu-input-blocked`：尝试点击菜单外侧、手牌和场景；仅菜单自身控件响应。

任一截图出现下层角色/手牌盖住菜单、桌面出现仪式 pin、或现场思考没有 pin/连线，
即为阻塞缺陷，不能以 GUT 全绿作为交付依据。

## 自动防线

`tests/test_ui_layout.gd::test_player_path_keeps_surface_ownership_and_modal_budget_intact`
覆盖同一条可达路径，断言节点父级、表面状态、可见性、遮罩、输入 blocker 和 z 层级。
它不替代截图检查，只负责防止已确认的结构性回归。
