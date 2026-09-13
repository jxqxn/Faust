# 桌面与仪式性能排查（2026-09-12）

状态：🟡。已修复可复现的重复加载开销；未证明所有卡顿已消失，也未测原作 FPS。

## 量测与根因

Godot 4.7 / RTX 4070 Ti SUPER / Forward+ / 1280×720 独立窗口，导入只读语料 `save_samples/auto_save.json`，5 张可见手牌。使用隔离存档路径，不覆盖玩家存档。关闭 vsync 和 FPS 上限只用于量测，未更改项目设置。

| 路径 | 修复前观察 | 最终观察 | 解释 |
|---|---:|---:|---|
| 同页连续 `GameScreen.refresh()`，同步 CPU 部分 | 9.55–10.36 ms | 6.40–6.67 ms | 样式 JSON、图集重复解析/读取减少 |
| 后续三个仪式打开，同步 CPU 部分 | 221–251 ms（仅完成最初两项缓存时） | 84.5–88.5 ms | 模板映射缓存及原作贴图跨面板保留 |
| 仪式图片控件构建累计，已加载后的同一仪式 | 96.34 ms | 3.66 ms | 多个 TextureRect 不再重新读入已释放贴图 |
| 真实鼠标从空分页返回手牌，输入至绘制完成 | 连续两次 140.57 / 139.82 ms | 首次 107.11、再次 7.40 ms | 手牌贴图缓存减少反复切页停顿；缓存失效/首次加载仍慢 |
| 本进程首个仪式打开 | 328 ms | 287 ms | 仍有明显冷加载停顿，不能标记解决 |

前后记录是相同设备与夹具上的阶段性样本，不是原作对照或严格性能分布。切页修复前数值来自本次工具输出的阶段测量；后续同名最终日志已重跑。其他原始测量见 `desktop_profile_before.log`、`desktop_profile_after.log`、`desktop_profile_rites_before.log`、`desktop_profile_breakdown.log`、`desktop_profile_final.log`。

静态桌面没有复现持续低帧率。`Performance.TIME_PROCESS` 的更新周期不同于短时无上限采样，旧记录中的该字段不参与判断，最终工具已移除该字段。不能将上述同步调用耗时、render GPU 时间和用户屏幕实际 FPS 混为一谈。

## 实现范围与原作边界

- `source_text_style.gd`：缓存原始 `content/textstyle.json` 的解析结果；每个控件仍独立订阅字号偏好，重开页面和字号设置行为不变。直接核读 `TextTranslate.c` L144–151：`UpdateTextInternal 0x1566ad0` 通过 `Datapool.GetTextStyleNode` 取样式；`dump.cs:387756` 的 Config 持有 textstyle 表。
- `atlas.gd`：按路径保留最多 32 个图集及切片；图集第一次切片读取一次 CPU 图像，后续复用。未改变源矩形、缩放、PNG、过滤或返回纹理类型。新增测试逐帧比较 rites/countdown 两图集与原始 PNG 裁剪的像素。
- `rite_view.gd`：只缓存 UI 文案、仪式模板、模板映射，仍走 SourceJSON 无损解析；不缓存仪式运行实例或槽位状态。核读 `RitePanelShowController.c @ Show 0x596450` 的模板/Datapool 贴图调用，以及 `dump.cs:387766–387768` 的 rite_template / rite_template_mapping 字段。
- `source_texture_cache.gd`：卡牌及仪式共用原始 Texture2D 资源缓存。按最近使用淘汰，估算保留量上限 128 MiB，按宽×高×6 保守计入 mip 开销；这是宿主资源策略，不是原作视觉参数，也不是整个进程显存上限。超大单图不驻留。只保留纹理，不复用控件或可变 ShaderMaterial。
- 主场景退出及测试收尾释放缓存。未更改着色器、光照参数、卡面、动画、布局、点击语义或 `content/`。

## 验证链与发现的旧夹具问题

- 原作数据 → 导入状态 → 真实控件：性能夹具导入原作 auto_save，再构建完整 Game 主场景。
- 实际输入：分页使用 `InputEventMouseMotion/MouseButton`，4 次均核对 hovered 控件及最终分页；输入至 `frame_post_draw` 才结束计时。
- 实際拖放：复用 `tools/verify_rite_hand_input.gd`，临时副本仅增加隔离存档路径并改截图输出位置。鼠标从主角卡拖入槽位、确认开始、重新打开运行仪式、停止撤回均 PASS；日志 `performance_rite_mouse.log`，截图 `performance_rite_hand.png` / `performance_rite_running_1920.png`。
- UI/样式/图集/仪式回归：103 测试、1288 断言通过；5 份 `performance_test_*.log` 为最终结果。
- `test_rite_input_contract.gd` 的旧 make_view 未创建实际 RiteInstance，导致 nil 异常且 GUT 仍可能给退出码 0。修正夹具：先生成实例并显式传 UID，11/11、56 断言通过。不通过修改生产逻辑恢复“打开 UI 自动造仪式”的旧假设。
- 动画与持久化：`verify_next_day_restart.ps1` 在 6 个独立 GL 进程中完成夜幕/白昼中断、读档、连续 1→2→3 天，共 62 检查通过；日志 `performance_next_day_restart.log` 及 `next_day_runtime/process_restart/`。该测试验证调度恢复，不等于所有原作事件内容对拍。
- 最终日志扫描无 SCRIPT ERROR、ERROR、Risky、失败断言、孤儿或资源泄漏诊断。缓存单元测试只证明资源与生命周期边界，不能单独证明全游戏还原。

## 尚未完成

首次打开约 287 ms、仪式之后首次返回手牌约 107 ms 仍偏高；热打开也有约 85 ms。卡牌控件全量重建、首次资源加载/上传、槽位视觉构建仍需进一步拆分量测。大量手牌、长时间游玩、用户当时的实际帧率和原作同场景性能尚未测量，不把小手牌静态样本外推为全场景性能结论。

## 原作资源生命周期复查（用户补充：学习优点，不照搬优化缺点）

判定原则：玩家可观察的外观、规则、输入、时序与存档仍按原作验收；缓存、加载策略和控件复用属于宿主实现，可以不同，须用耗时与内存量测决定。原作中的某个模式不自动等于最佳实践。

### 已核实、值得学习

1. **卡牌有自己的显示对象，不是每次刷新重新造。** `GameController.c @ AddCard 0x54ad40` L2980–3050：先检查 `Card+0x70`；存在时取 CardController、必要时换父级并复位姿态，仅不存在时 Instantiate 并 Init。独立符号 `dump.cs:389615` 将该字段确认为 `_gameObject`。`UpdateHandCards 0x559d90` 先收集现有手牌控件，再为当前页调用 AddCard；不属于当前页的控件经 `SetParentNormalize` 移到 `GameController+0xF0`，而非在本方法中 Destroy。`ChangeCurrentBag 0x54cb60` 调用该更新链。相比克隆 `refresh()` 的整批 queue_free，这提供了后续按 UID 复用控件的直接背书；本批只完成资源复用，没有虚报节点复用已完成。
2. **常用小图按名称查表。** `Datapool.c @ LoadRiteSprite 0x416930` L2195–2223：Resources.LoadAll 后按去扩展名的 sprite 名写入 `Datapool+0xA8`。`dump.cs:423213` 附近确认它是 `Dictionary<string, Sprite> rite_sprites`；相邻方法/字段管理 tag、head、outline、guide 图。本批共享图集与切片遵循这种“解析/取图和绘制分离”的思想。
3. **文字样式查内存表。** `GetTextStyleNode 0x412e70` L6233–6238 查 `Datapool+0x280`，不读取 JSON；`dump.cs:423300` 为 `current_language_textstyle`。本批样式解析缓存直接消除了克隆引入的重复工作。

### 不盲目照搬；只登记潜在代价

- `Datapool.LoadSprite 0x416e50` 的普通路径仍调用 `Resources.Load`；`+0x178` 的字典是 **mod_sprite_loaders**（dump.cs 字段核对），不是通用图片缓存。不能据此宣称“原作所有图片都有自建缓存”或“原作全部异步加载”。Unity 实际磁盘/GPU 开销仍需实机量测。
- `RitePanelShowController.Show 0x596450` L648、808 有槽位 Instantiate；其关闭处理 L1496 仍销毁槽位对象。原作并非所有 UI 都做对象池；克隆未来是否复用槽位应靠实测与状态清理验证决定。
- `UpdateHandCards` 仍使用 GetComponentsInChildren、临时集合与排序。这些可带来分配/遍历代价，但只有源码不足以证明它们是原作性能瓶颈，不照抄也不空口批判。
- 全局加载所有图集有首次加载与常驻内存成本。克隆采用有上限的按需缓存；上限只是初始宿主策略，尚未经过大手牌/低内存设备调优。

下一项结构性目标应是按卡牌 UID 维护控件，区分“移到别页、移到仪式、数据变化、真正销毁”，保留有效节点。实施前须覆盖拖拽中的所有权、叠堆/拆分/装备后刷新、候选高亮与顺序、跨页返回、跨日删除、重建读档，不能用新增对象池掩盖旧状态泄漏。首次资源加载应另外量测，避免把工作简单挪到主菜单而宣称消除卡顿。

后台 threaded prewarm 曾做过一次隔离实测：它与渲染线程争用，最终静止 frame mean 由约 0.39 ms 升到约 0.59 ms，首次切页仍约 123 ms；因此已撤销调用和实现，不计入修复收益。

## 右下角重抽入口清理（2026-09-12）

原作 `GameScene.unity` 的 `RedrawButton/RedrawCount` 位于 `RiteResultPanel/DiceCountPromptNew`（`docs/ui_layout/GameScene.md` 1403–1405；`dump.cs` 324681–324736），由 `RiteResultPanelController.OnRedraw` 驱动。原作桌面 `Next Round` 常驻区没有该按钮。克隆此前把 `redraw_active.png` 放进 `RightActions`，并承认其矩形是 clone-only parked rect；这会造成错误图标、错误位置和错误功能入口。现已删除桌面按钮、位置和输入链，保留结果面板重抽入口与 `GameController.OnRedrawSudan 0x555460 → RedrawSudanCard 0x5558b0` 规则链。UI 81/81、1069 断言及重抽规则 22/22、590 断言通过。
