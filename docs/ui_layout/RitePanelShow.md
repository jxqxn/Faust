# RitePanelShow — 原作布局真值与克隆映射

## 证据

- 原作 prefab：`unity_export/ExportedProject/Assets/Resources/prefab/RitePanelShow.prefab`。
- 原作控制器：`engine_spec/decompiled/RitePanelShowController.c`，`Show`（RVA `0x596450`）创建 `CardSlot`，并写入模板背景、标题和每槽的 `localPosition`、`localScale`、`localRotation`。
- 结构签名：`dump.cs` `RitePanelShowController`（`ModelBG`、`SlotsContainer`、`slots`）及 `RiteTemplateNode` / `SlotPosition`。
- 内容真源：`content/rite_template_mappings.json` 与 `content/rite_template/*.json`；不建立克隆侧模板表。

## 固定 prefab 几何（3840×2160 CanvasScaler 设计空间）

| 原作节点 | 直接几何/规则 | 克隆节点 |
| --- | --- | --- |
| `RitePanelShow` | 3692×2132，中心锚点 | `RitePanelShow` 源画布 3840×2160 中的原作承载层 |
| `Position` | 中心 `(0, 210)`，Unity y-up | `SOURCE_POSITION_CENTER=(1920,870)` |
| `Position/bg` | 4096×2148，中心锚点 | `RiteTemplateBackground`，以模板 `bg_pos` 移动 |
| `SlotsContainer` | 3692×2132 | 只承载原作 `CardSlot` 坐标 |
| `CardSlot` | 272×496，pivot `(0.5,0.5)` | `OverlaySlot_Sn` |
| `RitePanelTitle/CommonContent` | 1148×1124，`common_operation_bg` | `RiteOverlayPanel` |

## 模板位置公式

对每个原作 `rite_template` 槽：控制器以 `SlotsContainer` 左下原点的 `pos`，减去容器半尺寸后写到实例的中心局部坐标。因此在 Godot 的 y-down 设计画布中：

`center = (1920, 870) + (pos.x - 1846, 1066 - pos.y)`

`scale` 与 `rotation_z` 同样直接读取该模板。禁止回退为按槽数生成的网格，也禁止为了避开手牌而二次挪动槽位。

## 验收

`tests/test_ui_layout.gd::test_rite_view_replays_source_canvas_geometry` 对原作开局仪式 `5000001 → mapping 8001002 → template 8000003` 验证背景、标题与 `s1` 的精确矩形；另验证实际打开路径进入 `SourceOverlayLayer`，不经过旧 1280×800 `OverlayLayer`。
