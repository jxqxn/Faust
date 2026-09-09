# 卡面与手牌区域纠偏 — 2026-09-07

用户图一复现于1920×1080 Forward+；Compatibility得到同样结果。不是通过改渲染器修复。

## 2026-09-09 续批：卡面壳层与材质亮度

| 旧偏差 | 原作依据 | 修正 |
| --- | --- | --- |
| 卡面没有任何外圈描边 | CardNew.prefab：Outline `m_IsActive: 0`（原作不画），Flash `m_IsActive: 1` 256×512 + CardFlash.mat（`_INNEROUTLINEOUTLINEONLYTOGGLE_ON`、`_InnerOutlineColor` 0.882/0.728/0.337） | 新增 `ui/card_flash.gdshader`：用 card_outline.png 自身 alpha 轮廓做 2.5px 金色内描边，挂在 CardArt 之上的 `Flash` 节点 |
| 数量底章用 checkbox_bg 75×78 | CardShow*/Stackable = 80×80 `Sprite/number_bg.asset`，底部锚 +50 → 左上 (57,332) | 复制 `Texture2D/number_bg.png`（SHA256 一致）并改位置/尺寸/底图 |
| 只有 rare≥2 挂材质 | 12 个 `materials/card/{char,item,sudan}/{tier}.mat` 每档都有 _MainTex/_BumpMap/_MetallicGlossMap | `_apply_metal_surface` 对全部稀有度生效，并按档写入真值 `_BumpScale`/`_GlossMapScale` |
| 卡面比原作暗约 2 倍 | canvas_item 自定义 shader 采样在线性空间、默认管线在 sRGB；Unity Standard 光照无导出函数体 | 采样统一 `to_display()` 还原；灯光按原作截图逐档校准 `material_light` |

验收与保留差异见 METHOD_MAP 顶部「手牌卡面 1:1 第一批」；截图 `card_surface_1920.png`，对拍脚本 `tools/verify_card_surface.gd`。

## 2026-09-09 第二批：手牌基线、细节贴图、数字精灵

| 旧偏差 | 原作依据 | 修正 |
| --- | --- | --- |
| 手牌卡比原作高 2px | GameScene MainUI/Hand 内容矩形底边距画布底 4 单位，卡牌贴底边 | `_layout_hand_cards` 的 Y 由居中改为 `size.y - card_size.y` |
| 缺 `_DETAIL_MULX2` 细节层 | 12 个卡材质逐档的 `_DetailAlbedoMap`（stone 档没有） | 复制 6 张 detail 纹理，shader 里同 UV 做 `albedo × detail × 2`，灯光按 detail 均值除回 |
| 数量底章统一用 number_bg | CardShowItem/Stackable 是 checkbox_bg 75×78@(59.5,332) | 按卡类分派：char/sudan 用 number_bg 80×80@(57,332)，item 用 checkbox_bg |
| 数量/寿命数字是普通字体 | 两个 TMP 组件都用 spriteAsset number_6（fs48/fs52） | 改用 `ui/source_number.gd` 数字精灵，glyph_height 58/63 |

六张卡整卡均值与原作差 ≤6%（见 METHOD_MAP）；对比图 `card_surface_compare.png`。

## 2026-09-09 第三批：寿命牌 DotText

`LifeBg/Image/DotText` 的 `'<sprite=21>'` 用的是 `rite_settlement_icon` sprite asset（索引 21 = `dot_0.png`，图集帧 50×30），不是 number_6。已复制该图集并在 LifeBg 内按 Unity 锚点折算加上 `DotText`（(-7.2,23.1)、50×30）。对拍脚本临时给小圆加 7 天寿命来覆盖这条链。

## 2026-09-09 第四批：底板光照分布与详情面板

- 光照：按"立绘透明像素"逐带对比克隆与原作，得到自上而下 1.21×→0.79× 的衰减、金属件 30% 漫反射损失、0.3 高光强度，写入 `ui/card_metal.gdshader` 三个 uniform；逐带误差 21%→15%，整卡均值仍 ≤6%。
- 详情面板：`CardInfoNew/Equips` 缩略图复用 CardWidget 链，新增 `tools/verify_card_detail.gd` 校验装备缩略图的 RarityFrame/材质/CardArt/Flash/194×422 并输出 `card_detail_2560.png`；原作参考帧无装备，故只做结构与源几何验证。


## 原因与对应实现

| 旧偏差 | 原作依据 | 修正 |
| --- | --- | --- |
| 只读CardNew外壳，VBox自制标题、缩略图、属性行 | CardController.Init 0x528f40实例化GetCardShowPrefab，再CardRender.Init；dump.cs:317717 的bg/image/text/stackable/life | 按新导出的CardShowChar/Item/Sudan真值表分层，Icon全幅194×422，Title矩形(9.5,15,175,40)、字号30 |
| card_bg_*当成前景边框盖住立绘，纹理本身形状也不对 | CardRenderChar.Init 0x538030 / UpdateRareMaterial 0x538480；Resources/materials/card/{char,item,sudan}各品级_MainTex与_Color | 使用card、card_0..4原底板，人物叠加stone_f/copper_f/silver_f/gold_f前景。移除card_bg_*这条错误渲染路径 |
| 用配置id猜立绘文件，忽略resource | CardRender.InitImage 0x5390f0→CardExtensions.GetPic 0x3803b0；cards.json resource为单值或列表 | 读取resource及pic索引，选择对应原图；保留有效运行时名字、稀有度 |
| 手里苏丹卡用了池中的小图标尺寸、名字拼上稀有度 | GameController.AddCard 0x54ad40统一cardPrefab@0x268→CardController.Init；GenSudanCard 0x54f6f0添加普通Card；dump.cs:327241 SudanCardPrefab属于SudanPoolController | 手牌统一194×422，名称来自配置/运行时名字，稀有度由底板表达 |
| ×N标签另贴在卡外，倒计时只有18px | CardRender.UpdateShowInternal 0x53a4a0，count>1且stackable；life=config.card_vanishing−Card.life；CardShow*/Stackable、LifeBg | 合并显示数量传给卡面，数量底章及寿命绿签在原位置；实例life只投影到card_data_for，不改变状态推进 |
| HandBG只有字段和布局代码，没有实例 | GameScene MainUI/Hand BG，底部拉伸、高356 | 创建原hand_bg底板并置于手牌后 |
| 左下是146×58的IThink_01缩略条 | GameScene MainUI/IThink BG=388×704、Folder=400×700，左下锚 | 使用bg_0/open_03原图；保留现有拖卡到仪式的入口，无新增假按钮 |
| 怀表旁黑色长条撑破按钮 | 回退原图158×137；旧按钮套516px文字底板且内容左右margin各158 | 两个图标按钮使用空样式和全幅图像，不让文字按钮最小尺寸撑大 |

## 验证与边界

- 实际GPU截图：[card_hand_corrected.png](card_hand_corrected.png)，是克隆运行输出，并非原作截图。
- source prefab真值表：CardShowChar.md / CardShowItem.md / CardShowSudan.md，由原YAML直接导出。
- 导入14张原纹理：card/card_0..4、四张人物前景、bg_0、open_03、bg_green、rite_round；不改content。文件直接来自原素材，未绘制替代卡面。
- UI专项76测试通过，包括立绘不被底板遮挡、资源变体、数量和寿命显示、既有拖动交互。原作存档同刻导入对拍49/49；这不表示连续游玩全一致。
- 显示专项6/6。全量464项首次462通过，另2项指出IThink高于模态层：已将HandBG/IThink放回7/8层，随后完整UI76项复验通过。卡面替换测试增加帧等待以完成queue_free；最终专项无SCRIPT ERROR/ERROR/Orphan。未把局部复验说成另一次全量运行。

**仍未还原**：原材质的动态金属光照/法线/反射（导出的.shader是DummyShaderTextExporter，不能当作原片元算法）；数字仍是文字而非原TMP数字精灵；IThink开合动画与闭合姿态；四个手牌分页入口；桌面仪式标牌仍明显偏小。人物卡前景与底板使用原材质颜色，但与Unity世界空间光照尚无同帧对拍，不宣称像素相同。

这些是本条核心桌面链的后续缺口，不以外围面板数量代替修复。
