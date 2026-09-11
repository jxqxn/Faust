# 自动字号：按 sizeRange 收缩（第二十四批，2026-09-10）

A10 原登记为"source_text_style 自动字号只取 sizeRange 上限 / 已发现实现缺口，待源算法核验：所有长卡名、事件/仪式描述共用；不能页面各自缩小字号补救"。本批把 `TextTranslate.UpdateFontSize` 的方法体与 `TextStyleNode` 字段布局对齐，确认上限来自 `sizeRange.y`，而**收缩**是 TMP 渲染器内部的 enableAutoSizing 行为。

## 原作事实

`TextTranslate.UpdateFontSize 0x1566920`（`decompiled/TextTranslate.c`）按顺序设置：

1. 字号：先用 `style_48+0x40`（`css_size` 字典）以当前字号档位（`param_2`，来自 `Datapool+0x218`，即用户字号偏好）查表；查不到则用 `style_48+0x24`（`size`）。
2. `TMP_Text.set_enableAutoSizing(style_48+0x21)` —— 字段 `enableAutoSize`。
3. `TMP_Text.set_fontSizeMin(...)` / `set_fontSizeMax(...)` —— 字段 `style_48+0x28`，即 `sizeRange`。
4. `set_characterSpacing(0x30)` / `set_wordSpacing(0x34)`；
   `set_lineSpacing(0x38 + param_1+0x40)` / `set_paragraphSpacing(0x3C + param_1+0x44)`（后者是每实例增量）。

`TextStyleNode` 字段布局由 dump.cs:393716 独立确认：`font@0x10 / material@0x18 / isRightToLeftText@0x20 / enableAutoSize@0x21 / size@0x24 / sizeRange@0x28 / characterSpacing@0x30 / wordSpacing@0x34 / lineSpacing@0x38 / paragraphSpacing@0x3C / css_size@0x40`。

`TextTranslate.UpdateTextInternal 0x1566ad0`：只有当 `enableAutoSize@0x21` **为假**且 `css_size@0x40` 非空时才挂 `OnFontSizeChanged` —— 也就是说**自动字号样式不跟随用户字号偏好**，因为它的字号由 sizeRange 与拟合决定。

`TMPTextMaxPreferredSize`（0x464d00/0x464d10/0x464dd0/0x464fa0）是另一件事：把布局首选尺寸按每实例 `maxWidth@0x30`/`maxHeight@0x34` 截断（`0 < cap <= preferred` 时取 cap），并连做三次 `LayoutRebuilder.ForceRebuildLayoutImmediate`。它与 enableAutoSizing 无关。

**配置实测**（`content/textstyle.json`）：80 个样式里 **13 个 `enableAutoSize: true`**，且这 13 个**只有 `sizeRange`**（无 `size`、无 `css_size`），例如
`@CARD_INFO_TAG_TEXT [26,30]`、`@CARD_INFO_NAME [40,60]`、`@BIG_BUTTON_AUTO_SIZE [30,60]`、`@MAIN_BODY_AUTO_SIZE [20,60]`、`@TITLE_H3_AUTO_SIZE [40,50]`、`@BUTTON_AUTO_SIZE [30,40]`。
非自动样式的 `css_size` 有 6 档（`xs..xxl`），另有 `size` 兜底（如 `@CARD_TITLE size=45`）。

## 克隆偏差（已修）

1. **只取上限、不收缩**：`_point_size` 对自动样式直接返回 `sizeRange[1]`，长文本永不缩小。原注释自己也承认这一点。
2. **绑定丢失**：`apply()` 只在 `size_class` 为空时才创建 `SourceTextStyle` 子节点，显式传档位（多处 UI 传 `"md"` 等）时**根本不建绑定**，于是既没有偏好订阅，也没有任何尺寸维护点。
3. **`css_size` 缺该档位时返回 0**：`int(style.get("css_size", {}).get(code, style.get("size", 0)))` 在字典存在但**没有该 key** 时给出 `get` 的默认值 0，而不是 `style.size` —— 会把文字尺寸设成 0。源里是"查表失败退 `size@0x24`"。
4. **尺寸恒不更新**：没有任何随控件尺寸变化的重新拟合。

## 修复

- `fit_point_size(font, text, box, floor, ceiling)`：在 `[floor, ceiling]` 上二分，取"换行后仍能放进 box"的最大字号；用真实 `Font` 量（`get_height` + 以「汉」为样本的 `get_string_size`），与控件解耦以便测试。
- `_apply_auto_size()`：自动样式下按 `sizeRange` 拟合并写回字号，同时在控件上留 `source_text_size_range` / `source_text_fitted_size` 元数据。
- `_ready()`：自动样式时连 `Control.resized`，尺寸变化即重新拟合（TMP 是渲染器内部重排，Godot 没有单一等效钩子）。
- `apply()`：**总是**建立绑定；偏好订阅仍只对"非自动 + 有 css_size"的样式开放，与 `UpdateTextInternal` 一致。
- `_point_size()`：查表失败时退 `style.size`，不再返回 0。

## 验证

- `tests/test_source_text_style.gd`（7 测试 / 31 断言）：新增"宽松盒保持上限 / 紧凑盒收缩且不越界 / 不可能盒落到下限 / 无字体、空文本、零宽盒、坍缩区间、零下限的退化处理 / 固定样式查表失败退 `size`"。
- 全量 GUT 见收尾记录。

## 未完成与新增审计线索

- **拟合算法是等价近似，不是 TMP 复刻**：TMP 的 enableAutoSizing 在真实字形度量与断行规则下搜索；克隆用"字符数 / 每行可容纳字数"估算行数，对等宽 CJK 接近，对拉丁混排与换行规则（禁则、连字符）会偏。已在该函数注释与本节登记，不宣称像素一致。
- **spacing 字段未接**：`characterSpacing@0x30` / `wordSpacing@0x34` / `lineSpacing@0x38` / `paragraphSpacing@0x3C` 本批仍未映射到 Godot 的主题常量（`RichTextLabel` 无逐字间距覆盖，需要 BBCode 或 shader），保留为缺口。
- **每实例 spacing 增量**（`param_1+0x40` / `+0x44`）未核其写入方。
- **`TMPTextMaxPreferredSize`** 的首选尺寸截断未接；它影响的是容器布局而非字号，登记为独立候选（邻近 A09/A10）。
