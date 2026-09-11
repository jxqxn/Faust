# 通知抖动原生数学与点击链纠偏（2026-09-10，第十二批）

本批接续 ShakerSourceCorrection.md，替换 A06 的双 sin、线性衰减、归一化振幅及局部时间。只验收下列边界，不宣称原机逐帧像素一致。

## 原作证据

- `Shaker.c` OnEnable 0x435690 / Update 0x4357e0，`dump.cs:420570`：初始 currentFreq=2、velocity=0、seed=Random.value*10-5；SmoothDamp(current,0,velocity,delta,10,delta)。位置用 seed+1/+2/+3、时间先取余 float32(2π)，噪声乘强度后加捕获的世界位置。
- UnityPlayer 注册循环 0xfd7bf0/0xfd7c01：函数表 0x18d4ae0 与名称表 0x18db7a0 的共同索引 2144 对应 PerlinNoise，入口 0xf0490，内核 0x5949c0。置换表 0x199a690（512 int32，后半重复）；输入先 abs，五次插值及三层置换梯度，输出 `(noise+.69)/1.483`。不能替换成一般库的 `(noise+1)/2`。
- GameAssembly SmoothDamp 0x197a3e0；独立签名 `dump.cs:343100`。工具读取对应常量并直接调用原作纯计算函数。
- GameScene.unity MainUI GO111 / Canvas7581：ScreenSpaceCamera，Camera4416，planeDistance100；该相机正交 size5，即高度10世界单位。因此世界偏移乘逻辑视口高/10，翻转Y。用 global_position 避免父级缩放重复应用。
- GameController.c NoticeCachedEvent 0x5534d0（9445起）：枚举 cachedEvents@0x320，对每个 controller 调用 Shake。GameScene GO47 点击遮罩指向此方法；CachedEventController.Shake 0x527940 重启 Shaker。

## 修复

`source_shaker_math.gd` 按原作浮点32运算边界移植噪声和衰减。`cached_events_view.gd` 捕获世界位置、保留跨帧速度，共用父级时钟，重新触发不重置时间相位。当前 CachedEvent 的旋转强度为零。

实际鼠标测试还发现：遮罩虽有较高 z_index，Godot 输入仍先命中后添加的 AdvanceDayButton。`game_screen.gd` 将遮罩移到后续兄弟位置，并在模态暂停期间禁用其输入。缓存事件存在时点击该区域触发通知抖动，回合不推进；不清除缓存列表。

## 原生裁判与验证

`tools/probe_unity_shaker_math.py` 使用 LoadLibraryExW(DONT_RESOLVE_DLL_REFERENCES) 映射本机原作 DLL，仅调用已反汇编确认的两个纯标量函数，不初始化游戏、不联网。生成审计专用 `shaker_native_oracle.json`，不进入运行时内容。重新核对256个置换条目与原 DLL 一致。

- 1029 个噪声样本、30/60/144 Hz 共468个衰减步骤：GDScript 输出与原生返回值逐项 float32 精确相等。JSON 解码值先恢复 float32，不使用容差放宽。
- 首次差分发现 fade 的中间乘法缺少独立 float32 舍入；已修后全部相等。
- 数学及投影/重触发测试3项/9断言；完整 UI81项/1073断言，共84项/1082断言通过。日志无引擎错误、orphan或泄漏报告。
- `verify_cached_shaker_input.gd`：1280×720、1920×1080 实际鼠标点击均 PASS；两条通知均抖动，最终回到捕获原点附近，缓存数和回合不变。截图在 `docs/ui_layout/cached_shake_{1280,1920}.png`。

## 尚未验收

宿主共享时钟的起算时刻与原作 Time.time、Unity 随机数流未同步；当前运行截图是克隆输入验证，不能当作原机同帧对拍。原机整帧、暂停/时间缩放的完整生命周期仍需核实。A06保留开放状态。
