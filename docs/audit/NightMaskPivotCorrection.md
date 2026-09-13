# 夜幕黑条：粒子 pivot 符号错误（2026-09-12）

## 结论

黑条来自 `ui/next_day_transition.gd` 将 ParticleSystemRenderer 的顶点偏移当成 RectTransform 原点相减。`pivot.x=-0.05` 在尺寸 60 的粒子上应为 -3，旧代码使用 +3，导致两组镜像粒子重叠 12 个局部单位。重叠区由两层变成四层，随夜幕移动形成宽大的深色斜条。已将四边形左上角 `(-27,-30)` 修正为 `(-33,-30)`。

本次没有修改透明度、纹理、动画轨迹，也没有添加模糊或替代渐变。修复范围为这条硬边黑带，不代表罗盘所有特效、声音或全过场像素差异已经验收。

## 原作证据与交叉核对

- `GameScene.unity`：GO2637/944（夜幕）、GO2565/1805（白昼）的 ParticleSystem 初始 size=60、rotation=-π/2；每组 burst=2。Renderer pivot=(-0.05,0,0)、Local alignment=2。子发射器 anchoredPosition.y=54、scale.y=-1。
- 位置独立约束：`54 = 2 × 60 × (0.5 - 0.05)`。按负偏移得到顶点 x∈[-33,27]；转 -90° 后，父片接合边在 y=-27，子片接合边同样在 -54+27=-27，两片恰好接合。旧顶点 x∈[-27,33] 使父边 y=-33、子边 y=-21，出现 12 单位重叠。
- 原作过程截图 `next_day_runtime/original-night-moving.jpg` 没有硬边深色斜带。修正后 GPU 画面与该特征一致；未以截图反推出任意新参数。
- 原作运行文件 `sharedassets3.assets` path_id 258 的 ND_text_mask04 RGBA 与本地 PNG 完全相等，线性/Clamp 采样器一致。材质 `ND_mask01.mat` 和 DXBC blob30 支持现有 alpha×alpha 与混合设置；无需改 shader 通道。

## GPU 因果隔离

工具 `tools/audit_next_day_mask.gd` 在 1920×1080 白底上渲染真实生产 overlay，固定夜幕 t=4，分别显示两组、仅父组、仅子组，暂隐藏罗盘。输出位于 `next_day_runtime/mask_isolation/`。

| GPU 量测 | 修复前 | 修复后 |
|---|---|---|
| 两组叠加，y=540 扫描线的硬边 | x=1121，红通道 0.141→0.369，单像素跳变 22.7% | 无大于 5% 的跳变 |
| 仅子组 | x=1121，0.380→1.000 | x=534，0.384→1.000 |
| 仅父组 | 该扫描线无硬边 | x=534，1.000→0.384 |

修正后两片硬裁剪边恰好在同一像素交接，合成后消失。`before-both.png` / `both.png` 和 `before-measurements.json` / `measurements.json` 保留修复前后证据。

## 回归

`tests/test_next_day_mask.gd` 使用实际 GL 渲染，夜幕与白昼各取 0—4 秒的 9 个时刻、每帧扫描 5 条横线。18/18 断言通过，最大相邻像素红通道变化为 1/255≈0.392%；阈值 5% 是用于捕捉硬边的测试容差，不是新增游戏效果参数。日志 `next_day_mask_regression.log` 无引擎错误或资源泄漏。白底是隔离诊断，不代替完整场景回放。

修正后的完整场景回放：`tests/test_next_day_resume.gd` 在 GL 渲染下重新通过 **2/2 测试、135 断言、92.29 秒**，涵盖原作 auto_save 导入后的连续两天、真实鼠标命中、仪式结果/嵌套提示、保存及整场景重建。与遮罩专项合计 3 测试/153 断言；两份最终日志无引擎错误、孤儿或资源泄漏。已查看新的 `next_day_runtime/clone-day-2-enter.png`，游戏桌面中的硬边深色带消失。修前完整场景截图保存在 `mask_isolation/before-game-day-enter.png`。不在这一参数修正后重复此前的六进程调度回归；该修正不改变状态保存字段或跨日调度。
