# 全仪式模板布局普查与修正

2026-09-08。范围是治理家业同类的 `RitePanelShow` 仪式投卡页面。所有修正进入 `ui/rite_view.gd` 共用路径，没有按治理家业 ID 分支。

## 覆盖范围

| 对象 | 数量 | 本次验证 |
| --- | ---: | --- |
| rite 配置 | 1495 | 逐个解析有效映射及实际卡槽，全部可解析 |
| 映射配置 | 453 | 作为统一模板解析入口 |
| 模板 | 251 | 全部检查；247 个有映射的模板构建页面并 GPU 渲染 |
| 未被映射引用的模板 | 4 | 8000010、8000060、8000067、8000232，仅检查资源，不虚构入口 |
| 背景 / 前景 | 65 / 43 | 全部导出原纹理和 Sprite 三角网格 |
| 卡槽图片 | 10 | 全部覆盖，按各自图片尺寸绘制 |

## 修正的共用规则

1. 之前只有 zz_01_fg，另外 42 种前景缺失；原来的网格导出工具也写死 zz_01 和 3348×1420。现在从全部模板引用集合导出，读取每张纹理实际尺寸和原 Sprite 顶点流，校验流布局、三角形索引和 UV 范围。118 张纹理与对应原资产 SHA256 相同。
2. 卡槽保留 272×496 原根尺寸，scale 作用于整棵卡槽节点，rotation 绕中心 (136,248)；之前只是缩小按钮矩形，子图形没有同步缩放，旋转还绕左上角。
3. 前景独立读取本身的尺寸。`fg_in_slot_index=0` 放在卡槽层之上；非零值插入卡槽兄弟列表，8000207 的值 2 已覆盖。
4. 模板 `title_bg_hide`、`title_help_btn_hide` 控制共用说明底板和帮助入口，特殊终局模板不再强加通用底板。卡槽背景空值回退和隐藏元数据集中保留。
5. 配置 5000332、5006745 的槽数超过各自 slot_open 长度。原作不是补写卡槽，而是重新取 mapping 0。现在背景、说明和卡槽共用 `_resolved_mapping`，不会出现一部分默认、一部分仍用原映射的混搭。

## 直接证据

- `RitePanelShowController.c Show (0x596450)` L380–438：缺失映射及映射长度不足，取 mapping 0；L688–719：BG/FG 加载及 SetNativeSize；L725–742：说明底板和帮助隐藏；L810–893：slot_open、居中位置、背景、scale、rotation；L930–966：前景父级与 sibling index。
- `dump.cs` RiteTemplateNode (393570 起)：fg_in_slot_index@0x38、title_bg_hide@0x58、title_help_btn_hide@0x59；SlotPosition (393454 起)：背景隐藏、位置、scale、rotation_z。
- 独立信号：未经修改的 `content/rite_template/*.json`、`rite_template_mappings.json`、CardSlot.prefab 根几何，以及原 Sprite.asset 顶点与 uvTransform。251 个模板中的 1900 个 slot 定义，含多种缩放与非零旋转。

## 验证

- 全量 GUT：471/471，3454 断言，262.670 秒；`rite-all-full.log` 无 ERROR / SCRIPT ERROR / orphan / 资源泄漏。
- UI 单组：76/76，889 断言。
- 新增全配置映射、全模板渲染分支两项遍历测试。注意 251 个模板检查包含 4 个无映射模板的资源检查，不表示它们拥有游戏入口。
- GPU：247 张 960×540 页面截图，日志 `rite-template-capture.log` 无引擎错误。7 张概览已逐张查看，覆盖旋转、多槽、前景及特殊终局模板。
- content parity：3881 文件，0 违规；未修改原作内容或本轮游戏状态逻辑。

## 截图入口

[1](rite_templates/overview-1.jpg) · [2](rite_templates/overview-2.jpg) · [3](rite_templates/overview-3.jpg) · [4](rite_templates/overview-4.jpg) · [5](rite_templates/overview-5.jpg) · [6](rite_templates/overview-6.jpg) · [7](rite_templates/overview-7.jpg)

[模板与代表仪式清单](rite_templates/manifest.json)。单页文件名为模板 ID，例如 [治理家业](rite_templates/8000003.png)、[旋转卡槽](rite_templates/8000031.png)、[非零前景层级](rite_templates/8000207.png)、[隐藏底板的终局模板](rite_templates/8000553.png)。

复验工具：`tools/export_rite_sprite_mesh.py`、`tests/test_rite_template_coverage.gd`、`tools/capture_rite_templates.gd`、`tools/build_rite_template_sheets.py`。截图使用直接挂载共用页面的独立测试场景，不修改存档或把未开放仪式塞进玩家地图。

## 尚不能据此宣称的内容

本次完成模板资源与布局分支的全量检查，不等于 1495 个仪式均已在真实剧情中逐局验收。截图采用空槽、代表配置，缺少原作同状态截图集；人物变量替换、字体/行距、吸附/手柄提示、各阶段说明与结算交互仍有既有缺口。事件选择浮层和其他菜单是不同控制器，不属于这次仪式模板普查。
