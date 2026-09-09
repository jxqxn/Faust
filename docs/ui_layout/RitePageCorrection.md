# 治理家业页面续修验收

2026-09-08，承接任务 `01a07f29-9e79-7953-b111-e8b5628acbaa`。本记录区分已落地修改与仍未完成的视觉对拍。

## 已落地

- 建筑使用精灵原生尺寸，Position 只应用一次 bg_pos；slot_open 映射到模板卡槽；恢复建筑前景和原精灵网格，避免图集边缘显示。
- 右侧恢复标题、回合、tips_text、属性列及底部操作图片；仪式覆盖声望栏，手牌在仅打开仪式时仍可交互。
- 接手复查发现此前全绿日志仍有 7 次 `<null>.png` 加载错误。本次将 JSON null 与空字符串共同按背景回退处理，并在动态七槽测试中检查纹理实际加载。

## 证据入口

- `RitePanelShowController.c Show 0x596450`，尤其 L848–866 的 IsNullOrEmpty 双层回退；dump.cs 的 RitePanelShowController 类及 RitePanelShow/RitePanelTitle/CardSlot prefab。
- `RitePanelTitleController.Show 0x5992a0`、`CardSlotController.Init 0x53b940`；原配置映射 8001002 → 8000003。
- 用户提供的原作截图与[当前运行截图](rite_page_corrected.png)直接对照。两者是不同回合、不同手牌状态，不作为同刻状态对拍。

## 验证与未决项

- 前会话完整 GUT 日志：469/469、3443 断言通过，但有上述 7 次资源错误，不能称为无错误验收。
- 本次先复跑仪式组 24/24、72 断言通过；加入纹理断言后的最终结果见 `rite-handoff-check.log`。
- 建筑主体及卡槽位置已接近参考图。正文的字体、大小及换行仍明显不同；顶部自动吸附标记、回合数字样式和底部额外按钮也仍需逐项核对。
- 未完成同状态原作对拍，不标记为完全复刻。本次未修改 content 或游戏状态逻辑。
