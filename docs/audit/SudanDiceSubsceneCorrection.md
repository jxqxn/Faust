# 苏丹骰子子场景与仪式类型分支（第二十六批，2026-09-10）

A14 原登记为"game_screen SudanDice 位置为停放值 / 待核候选：需要定位原实例/动画控制，不从空余位置推断"。本批定位到了原作实例与动画控制，结论是**它不在 2D 画布上**。顺带给出 A15 的一个已定事实（位置分支的开关是 `RiteNode.type`）。

## A14：苏丹骰子

### 原作事实

骰子是一套**独立的 3D 子场景**，由专用相机渲染，不在 UI 画布上：

- `GameScene.unity` 里有 GameObject `SudanDiceCamera`（fileID 4416，挂 Camera 组件 4008）与它的子对象 `Dices`（fileID 349，Transform 4012，layer 30）。
- `Dices` 上挂 `SudanDiceRollController`（MonoBehaviour fileID 11767，脚本 guid `5120d76301e969c0f8aa1b32aa0c43bb`）。其 Transform 为 `localPosition (1.05, -1.69, 39)`、`localScale 0.01`，父级为 `SudanDiceCamera`。`SudanDicePrefab` 指向 `Resources/prefab/SudanDice.prefab`。
- `Roll` 时把骰子实例 `Instantiate` 后 `set_parentInternal` 到控制器自身 transform（`SudanDiceRollController.c` 0x503f30 内），所以骰子的坐标空间是 `Dices` 的局部空间。

**序列化字段真值**（GameScene.unity，`SudanDiceRollController` 块）：

| 字段 | 值 | 含义 |
| --- | --- | --- |
| `DiceBaseScale` | (40, 40, 40) | 骰子基础缩放 |
| `CellSize` | (100, 100) | 骰子网格步长 |
| `HeightRange` | (-170, -230) | 抛物线高度区间 |
| `TopTimeRange` | (0.5, 0.6) | 到顶点的时间区间 |
| `TotalTimeRange` | (0.8, 0.9) | 总飞行时间区间 |
| `RollRotationSpeedRange` | (400, 1000) | 滚动角速度区间 |
| `MaxScaleRange` | (1.05, 1.1) | 中途最大缩放区间 |
| `WaitingTime` | 0.2 | 骰子之间的间隔 |
| `NormalizeTime` | 0.4 | 归位时间 |
| `FullSize` | (1100, 900) | 落点区域尺寸（代码里再乘 0.5） |
| `RandomPos` | `[]` | 运行时由 `GetRandomFinalPosition` 填 |
| `Row` / `Column` | 9 / 11 | 网格行列 |

**随机落点**：`Roll` 里取 `RandomPos = GetRandomFinalPosition(count, Vector2(FullSize.x * 0.5, -FullSize.y * 0.5))`；`GetRandomFinalPosition` 先用 `0..count-1` 初始化再 `Random.Range(i+1, count)` 洗牌，再按网格取点。每颗骰子的间隔 = `总时长 / count`，逐颗错峰（`fVar22` 累加，`PromiseTimer.WaitFor`）。

**每帧位置**（`SudanDiceController.GetPosition` 0x501b00）：以 `t = 归一化时间 × Parabola.Speed`，`localPosition = (base.x + t*vx, base.y + t*vy, base.z − (t²*quad + t*lin))`，其中抛物线系数由 `Parabola.ctor` 用 `总水平位移` 与 `高度` 算出（`quad = (2h)/d²`、`lin = -2h/d`）。`base`/`v` 来自 `Roll` 的起终点参数。

### 克隆偏差与处置

克隆没有一个 3D 骰子子场景，只有 `game_screen.gd` 里一个名为 `RedrawSudanButton` 的 **2D 按钮**——它是重抽的**触发 UI**，不是骰子模型；其位置原本是一条"未定位，先停在怀表列左侧"的停放值。

本批的处置是**把注释改成已核事实并登记结构性缺口**：明确该控件是触发按钮、骰子属于相机子场景、并列出上述真值表与 RRC 指针。**停放矩形保持原样**——它没有原作 2D 对应物，任何新坐标都会是自造数。迁移骰子子场景需要一套 3D 视口 + Parabola + PromiseTimer 错峰播放，属于独立批次。

## A15：仪式的类型分支（部分事实已定，仍待完整核）

### 已确认

- `RiteNode.type` 是 `enum RiteType { NORMAL=0, END=1, ENEMY=2, TREASURE=3 }`（dump.cs，TypeDefIndex 9597），字段在 `RiteNode + 0x30`。
- `RiteRender.Init 0x59a9e0` 读 `param_1[5] + 0x30` 得到该值，然后按 `1` / `2` / 其它分成不同放置分支：END 用 `Datapool.GetRiteOutlineSprite` 与第 1 个位置表，ENEMY 走 `RiteTransform.RectTransform` + `SetActive` + 第 2 个位置表，其余走按名字查表。
- **配置实测**：1495 个仪式里 1394 个未写 `type`（= `NORMAL`/0）、`TREASURE` 16 个、`END` 41 个、`ENEMY` 44 个。
- 克隆已经有「奇珍 / 大敌」两套位置表（`ui/map_controller.gd` 的 `rite_positions`），与 END/ENEMY 两个分支的**存在**吻合。

### 仍未完成（A15 保持待核）

- `RiteRender.Init` 三个分支分别对应哪张位置表、以及 `RiteTransform` 的哪个字段，只读到调用形状，**没有逐字段核对 `RiteController.position@0x40`、`bound@0x48` 与 `RitePosition.GetPosition(count)` 的多仪式分槽算法**。
- 克隆是否按 `type` 选择位置表、或是按节点名硬编码，未核。
- 因此本批**不宣称 A15 已修**，只把"开关是 `RiteNode.type` 且取值分布已知"这条事实登记进去，下一步从 `RiteRender.Init` 的三个分支与 `RitePosition.GetPosition` 继续。

## 验证

- 本批只改注释与文档，未改行为。全量 GUT 49 脚本 / 590 测试 / 4408 断言通过（`r3-full.log`），无 SCRIPT ERROR、无 orphan/泄漏；两条失败是既有的 `test_card_flash` 与 `test_event_choice_controller`。
