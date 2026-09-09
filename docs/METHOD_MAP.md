# 原作—克隆方法映射表（METHOD_MAP）

## 手牌卡面 1:1 第三批（2026-09-09，寿命牌 DotText）

`CardShowChar/Item/Sudan` 的 `LifeBg/Image/DotText` 是 TMP 文本 `'<sprite=21>'`，其 `m_spriteAsset` 指向 **`Resources/sprite assets/rite_settlement_icon`**（不是 number_6）：该 sprite asset 的 character table 第 21 项是 `dot_0.png`（图集帧 471,107,50,30），fs28，`m_fontColor` 白——即原作寿命牌左侧时钟下方那枚 50×30 的黑色小药丸。落地：复制 `Resources/image/rite_settlement_icon.png/.json`（SHA256 与语料一致），在 LifeBg 内加 `DotText` TextureRect（LifeBg 局部 (-7.2,23.1)、50×30），位置由 Unity 锚点 (0,0)+pos(36.8,5.4)+pivot 中心折算。

验收：`tools/verify_card_surface.gd` 给小圆临时加 7 天寿命（改的是 game screen 自己的 ConfigDB 实例，不是工具的），校验 LifeBg 98×45@(57.5,-45)、Life 数字为 6、DotText 位置/尺寸；截图 `card_surface_1920.png` 与原作 desktop.jpg 第六张卡的寿命牌逐元素对照（时钟 + 绿色条 + 数字 + 小药丸齐备）。卡牌 UI 专项 80/80、1011 断言。

保留差异：材质高光/法线的空间分布仍是均匀近似（卡顶条带比原作暗约 20%、卡缘略亮）——要逐区一致需要方向光模型；卡牌详情面板的装备缩略图复用同一条 CardWidget 链，但尚未按 `original_runtime/card_info_artu.jpg` 单独对拍。

## 手牌卡面 1:1 第二批（2026-09-09，细节贴图/数字精灵/手牌基线）

第一批之后的三项收口：

1. **手牌垂直基线**：GameScene `MainUI/Hand` 锚 (0,0)-(1,0)、pos (-63.97,4)、sizeDelta (-1116.74,430)、pivot (0.52,0)——内容矩形底边距画布底 4 单位，卡牌贴其**底边**而非居中。克隆原来居中，1920 下比原作高 2px；改 `_card_items.size.y - card_size.y` 后卡顶 865→867px，与原作 867-868 对齐。
2. **`_DetailAlbedoMap`（`_DETAIL_MULX2`）**：12 个卡材质的 detail 贴图逐档取真值——char copper/gold=card_d_1、char silver=card_e_0；item copper/gold=card_d_6、item silver=card_d_2；sudan copper/gold=card_d、sudan silver=card_d_3；stone 档无该贴图也无该 keyword。已复制 6 张纹理（SHA256 与语料一致）并在 shader 里按 `_UVSec: 0` 同 UV 做 `albedo × detail × 2`；灯光按 detail 均值除回，保持场景光常量。
3. **数量底章按卡类分派**：`CardShowChar`/`CardShowSudan/Stackable` 是 number_bg 80×80@(57,332)，**`CardShowItem/Stackable` 是 checkbox_bg 75×78@(59.5,332)**——第一批统一用 number_bg 是错的（金币卡就是 item）。数量与寿命数字改用 `ui/source_number.gd` 的 TMP 数字精灵（spriteAsset 737d2853=number_6，fs48/fs52，`Utils.NumberToSprites 0x3ac420`），字号换算按原作截图校准到 glyph_height 58/63（克隆原来 48/52，数字明显偏小）。

验收：`tools/verify_card_surface.gd` 六张卡（梅姬/阿尔图/金币 count=8/铁头/快脚/小圆）同坐标整卡均值 vs 原作 desktop.jpg：梅姬 99/103/70 vs 96/100/66、阿尔图 94/98/104 vs 90/95/101、金币 143/121/57 vs 142/122/60、铁头 100/95/65 vs 97/92/62、快脚 106/89/81 vs 106/90/78、小圆 116/97/80 vs 116/98/76——全部在 ±6% 内。截图 `card_surface_1920.png`、对比图 `card_surface_compare.png`。

保留差异：材质高光/法线的空间分布仍是近似（顶部条带比原作暗约 20%，卡缘条带略亮）；`LifeBg/Image/DotText`（`<sprite=21>`）未接；装备槽、详情面板的卡面复用同一条 CardWidget 链但未逐屏对拍。

## 手牌卡面 1:1 第一批（2026-09-09，卡面壳层已验收）

CardNew.prefab（docs/ui_layout/CardNew.md）根 194×422，两个旧实现漏掉的壳层：**Outline** 256×525 pos(0,22) 的 `m_IsActive: 0`——原作从不绘制；**Flash** 256×512 pos(0,0) 且 `m_IsActive: 1`，sprite=Sprite/card_outline.asset（Texture2D/card_outline.png，256×512）+ Resources/materials/CardFlash.mat（keywords `_ENABLEINNEROUTLINE_ON`/`_INNEROUTLINEOUTLINEONLYTOGGLE_ON`，`_InnerOutlineColor` 0.882/0.728/0.337，`_InnerOutlineWidth` 0.08）——原作卡面边缘那圈金色内描边就是它，不是 Outline。CardShowChar/Item/Sudan 的 **Stackable 是 80×80 的 Sprite/number_bg.asset**（68×68 纹理）底部锚 +50 → 左上 (57,332)，旧实现的 checkbox_bg 75×78 是错的底图。12 个 `materials/card/{char,item,sudan}/{stone,copper,silver,gold}.mat` 的 `_MainTex`/`_BumpMap`/`_MetallicGlossMap`/`_BumpScale`/`_GlossMapScale` 已逐档取真值（stone 0.9027777/0.3020833、copper 0.3819444/0.7847222、silver 0.2847222/0.8090278、gold 0.3680556/0.75），材质对**所有稀有度**生效——旧实现 `rare<2` 直接 return 是自制捷径。

色彩空间坑（本轮最大发现）：canvas_item 自定义 shader 里 `texture()`/sampler 采样已被解码到线性空间，而默认 2D 管线在 sRGB 空间，同一张底板挂 shader 会暗到约 0.4 倍；`ui/card_metal.gdshader` 用 `to_display()`（pow 0.5）还原后与不挂 shader 的同一纹理逐像素一致（探针实测 flat 0.5 → 0.2471 → 0.498）。`_DETAIL_MULX2`/`_EMISSION`/Standard 光照无导出函数体（DummyShaderTextExporter），故灯光项按原作截图逐档校准 `material_light`。

验收：`tools/verify_card_surface.gd` 在 1920×1080 用与原作 `original_runtime/desktop.jpg` 相同的手牌（梅姬/阿尔图/金币 count=8/铁头/快脚/小圆）渲染并截图 `docs/ui_layout/card_surface_1920.png`；同坐标整卡均值实测 克隆 vs 原作：梅姬 93/98/76 vs 96/100/66、阿尔图 92/95/105 vs 89/94/100、快脚 112/95/86 vs 118/98/77、金币 94/90/70 vs 98/92/62；立绘区域逐像素一致（82/70/58 vs 81/68/55），说明差异只在底板材质。卡牌 UI 专项 80/80、1006 断言。

保留差异：手牌整体比原作高约 2–3 px（1920 下，`HAND_MASK_HEIGHT` 470 与内容偏移 36 待按原作复核）；`_DetailAlbedoMap`（card_d_*/card_e_0，`_DETAIL_MULX2`）尚未接入；TMP 数字精灵（`<sprite=9>`）仍以文字替代；材质各向异性/环境反射与逐帧对拍未完成。

## 地图投影与事件标牌（2026-09-09，局部链已验收）

GameScene Desktop Camera Transform3970/Camera4419：位置(97,-106)、正交半高1732；Map7621缩放1.25、位置(0,-178)。建筑按Image子节点尺寸及偏移绘制，不使用Location容器尺寸。RiteRender.OnUpdateBound 0x59be70（dump.cs:324578）将bound宽设为TitleBG宽+Icon宽/2，中心X=(bound宽-Icon宽)/2，再调用MapController.SetRitesPosition 0x56a200 / SetPos 0x569cd0；GameAssembly RVA0x1c92b4c浮点常量实读0.5。原先123×133仅为初始bound，不能代表标题展开后的碰撞范围。RiteNew根子序TitleBG→IconOutline→Icon；RiteShows/TextTranslate按@RITE_TITLE读取字号。rites图集JSON标注2048×4096，实际PNG为1024×2048，裁切坐标必须同比换算；本地全部PNG/JSON配对检查仅此图集尺寸不符。

验收（2026-09-09 续批，接手被中断的会话后完成）：tools/verify_situation_desk.gd 在 1920x1080、1280x720、1600x1000（16:10）三种窗口下做真实鼠标回放——SituationDesk 始终填满 3840x2160 画布（canvas_items expand，窗口只做整体缩放）；自宅同点 4 个仪式（5000003，范围 [2,12]）展开后的 bound 两两不相交；每张 RiteNew 的图标面与标题条分别点击都打开正确实例，关闭后 overlay 确实消失。截图 desktop_map_{1920,1280,1600}.png 与原作 original_runtime/desktop.jpg 同比例裁切比对：建筑位置与尺寸吻合，事件标牌高度差在 5% 内（原作 2560 宽截图标牌实测约 33 原生px → 49.5 画布px，克隆 52 画布px）。另独立复核 assets/original/ui 下 12 组 PNG/JSON 配对，仅 rites 一组尺寸不符，故共享裁图换算只影响该图集。全量 GUT 492/492、3667 断言，零引擎错误/泄漏/orphan 门禁通过（含 test_hand_pages 把旧自制 42px 与 3840÷4200 缩放常量改为 @RITE_TITLE md=40 与 2160×1.25÷3464 的世界投影）。

保留差异：图标徽记在图集帧内的留白、TMP 基线、材质发光以及图标与标题条的重叠像素级对位未逐帧对拍；不同存档的事件名与数量不同，只比对结构不比对状态数值。此条不升级为"地图整页 1:1"。

## 桌面顶部三项修正（2026-09-09，局部链已验收）

菜单/帮助锚节点的鼠标排序按引导修复同理置于SituationDesk之后、模态层之前；MenuButton关闭flat模式，恢复checkbox_bg底图。声望以PrestigeItemController.Init 0x582f50 / OnCounterChanged 0x583460的NumberToSprites和SetNativeSize为背书，GameScene Image底托52.5x54.6、Count40x50；TMP精灵GUID737d2853对应number_6，7100006源图160x236且旧宿主缺图。新增7100006、number_6及number_6_red的PNG/JSON共五份文件均与语料SHA256一致。

处刑日以GameController.UpdateSudanLife 0x55aeb0为背书：遍历手牌和仪式，选择sudan标签且life最大者，显示card_vanishing-life / Player.sudan_card_init_life（dump.cs Card+0x24、Player+0x64）。宿主沿现有sudan类型匹配器筛选hand、active_sudan_cards、仪式槽，替换旧life+1。标题取ui.GAME_MAIN_HEAD_TITLE与textstyle.@EXECUTION_DAY_TITLE；路径按variable MAIN_UI_TITLE_NUMBER_*和countdown_pics精灵表，数字剩余不足三天切number_6_red。固定204高度、LeftSpace150/RightSpace180、NumberSprite最小1115、上边距37、九宫格源边界227/245/52/71；GameScene GO87/101/225的标题装饰为inactive，保持不显示。最后一天标题和数字使用RedText.anim的0/0.25/0.5/0.75/1秒缩放曲线1/0.95/1/1.05/1，中点切线0.2。顶部更新仅重排自身，避免触发SituationDesk重建。

验收：完整GUT490/490、3605断言，零引擎错误/泄漏（header-full-check.log）。tools/verify_desktop_header.gd在1280x720与1920x1080从main.tscn真实点击菜单、返回和帮助，并验证7/6/3/2/1天图集、最后一天动画、仪式槽内较老卡、不同分母、隐藏及无卡状态。截图desktop_header_{1280,1920}_day*.png与原作original_runtime/desktop.jpg作结构参考，不同存档不比较状态数值。parity3882文件/0违规。

保留差异：TMP字体/精灵的精确基线、数字零的对齐、材质发光、整条进度的过渡动画及原作同状态逐帧对拍未完成；sudan筛选沿宿主现有类型边界，未宣称完整HasTag复合语义。此批不能升级为桌面整页1:1或所有交互问题均已解决。

## 引导关闭命中修正（2026-09-09）

BeginGuideController.OnCloseBtnClick 0x525fa0 / dump.cs:316765 是已有关闭入口，本批不改关闭语义。GPU鼠标回放证实宿主的 Default/Close 虽然显示在上层，命中却落在后创建的 SituationDesk；仅设置 z_index 未改变 Control 输入顺序。将引导节点移到桌面之后、两个模态层之前，保留视觉坐标和模态遮挡。验收脚本 tools/verify_guide_close.gd 覆盖中心、伸出面板的按钮边缘和刷新后保持关闭。

验证：1280x720、1920x1080 GPU输入回放通过，事件提示遮挡时不会点击穿透，提示关闭后恢复叉号命中；guide_close_before/after截图留档。UI回归79/79、923断言，stderr空、无引擎错误或泄漏。仅修宿主输入层级，不据此声明完整教学时机链已还原。

## ConfirmNew按钮行（2026-09-09，已接局部链，整页未完成）

ConfirmController.Show 0x53fc30调用AssignTranslateText分别设置确认/取消文字；Done 0x53fb70清Promise后Resolve(bool)，dump.cs:318365。ConfirmNew.prefab Operations锚(0,0)-(1,0)、pos(801,-6)、sizeDelta(983.4226,144.2)、pivot(.5,0)；横排间距60、右padding120、MiddleCenter，Cancel168x158在前、Confirm325x158在后。计算源2705宽时Cancel左1817、Confirm左2045、顶H-145.1。两标签24号、源颜色alpha0；手柄InputDisplay仍未移植。宿主已补正文居中与独立确认分支；精确PreferredSize、遮罩与短面板最终高度仍待实机校准。专项10/10、80断言通过。

## 提示人物与卡组参数（2026-09-09，进行中）

PromptControllerBase.ShowInternal 0x589890按三个位置处理外层数组，标量字符串只放中位；full前缀由TrySetupFull 0x589d60处理（stringliteral 0x25ACD30）。PromptIconController.SetIcon 0x58a210处理单位置：字符串pic/前缀（stringliteral 0x25821F8）先FindCard再配置GetPic，数字数组生成配置卡而非运行时卡，最多三张、零值跳过但保留索引。静态PosYRotZ由.cctor 0x58ab00给出(280,18)/(430,10)/(580,2)，一张取中、两张取中和末，scale=1.8、后生成移到首子节点。dump.cs:323572 Holder/Icon/PosYRotZ；content/event/5300000及5300177给出外层图像数组实例。当前先补参数解释和既有素材展示；外层IconGroup与正文的完整原布局分配仍未移植。

FindCard 0x38c740补查：Player.cards@0x88优先，其后依Player.rites@0x90枚举Rite.cards@0x30（dump.cs Player/Rite字段独立核对）。不能使用宿主全实例注册表按UID查询；消费后残留条目不应覆盖配置立绘。

## 事件正文高度与富文本（2026-09-09，已接局部链，整页未完成）

取 ScrollViewContentHightWatcher.LateUpdate 0x4342c0（dump.cs:420520，LastHeight+0x20 / MaxHeight+0x24 / layoutElement+0x30）：正文内容高度写回 preferredHeight，上限来自 PromptNew.prefab:1790 的1300。PromptController.Show 0x58a020重建布局；正文@PROMPT_TEXT、选项@OPTION_ITEM_TEXT由两个prefab的TextTranslate键确认。先替换固定正文高度和失效的滚动输入，选项随正文下移、底部装饰随面板下缘移动。外围水平位置、选项行高及根布局分配仍沿现有近似，不宣称完整LayoutGroup复刻。保留选择后确认及队列等待语义。

增量普查发现OptionNew.prefab:1780的MaxHeight是1100，并非PromptNew的1300；Options节点GO1313026266067498 / LayoutGroup114855482821919830间距20。OptionController.Show 0x576b50将OptionNewItem挂到options根（+0x90，dump.cs:321643），不能沿用ContentGroup的50间距。ConfirmNew没有这个ScrollView高度观察器，继续作为独立表面缺口，不用普通提示的参数声称已映射。

上限分流与20间距已接。最终UI79/79、923断言；此前完整回归487/487、3574断言；两分辨率GPU长正文及原配置5300102的实际选择/改选/确认/提示后event_on均通过，stderr空。测试只证明所述宿主路径，外围几何与人物图组未达原作一致。

## 卡牌详情标签与数值差异（2026-09-09，已接局部链，整页未完成）

本批取 CardInfoNewController.RefreshAllTags 0x535270：TagNode+0x40/41/43 控制显示，Variable.card_state_icon 优先分到状态栏，type=attribute 分到纯名称行，其余分到徽记网格；排序比较器 0x393940 返回 b.tag_rank-a.tag_rank（dump.cs:386926）。GetTagWithDiff 0x3811e0 的差值是当前 GetTag 减 Card.data 的配置值（Card.data+0x68，dump.cs:389593），不是只统计装备。CardTagNewController.FormatValue 0x53ec20 按差值正/负/零使用原 variable 文本颜色。Show 0x537000 的 Title 仅取 CardNode.title。状态图由 CardStateTagController.SetState 0x53dbb0 读取 variable.card_state_icon；原配置 sacrifices 指向拼错的 staet_sacrifices，语料只有 state_sacrifices，保留为源资源缺口，不擅自改配置。

已接上述分组、排序、差值色及静态箭头，状态按正值重复；16张槽位/状态/箭头纹理与语料hash一致。装备区依 RefreshAllEquips 0x534c40/.cctor 0x537e30 摆放真实CardWidget；槽位依GetEquipStats 0x37fa50逐装备一次匹配、CardEquipSlot.SetType 0x52dc70/set_Equiped 0x52e090切换原图。RareIcon经CardShows_FaceUnlit.asset:123和dump.cs:541824确认石/铜/银/金数组；RareText原色黑。装备拖放、取回、提示和动态数值变化监听仍未完整接到此视图。

帮助页原作实机证据original_runtime/card_info_help.jpg：原来的1920再翻倍假设错误，Help嵌套Canvas是WorldSpace/overrideSorting而非独立1920画布。按3840根空间的anchors/pivot重放四段、50%黑遮罩、card_info圈线、@HELP_TEXT与content/ui.json全文；RichTextLabel补TMP Overflow绘制边界，实际打开/遮罩关闭/详情关闭已通过。共享富文本转换仅转换完整已识别样式token，保留普通比较符和不支持的sprite/相对字号token，不宣称完整TMP解析器。UI78/78、912断言（card-complete-ui.log），全量回归进行中。

## 仪式滚动正文（2026-09-09，已接块布局，TMP差异未完成）

取 RitePanelTitleController.Show 0x5992a0（dump.cs:324417），拼接variable.RITE_PANEL_TIPS_TEXT_HEADER/ICON/CONTENT/FOOT；RitePanelTitle.prefab正文@MAIN_BODY、paragraphSpacing80、viewport宽比ScrollView少17。TextTranslate.Start 0x15667e0缓存TMP初始段落间距，再在UpdateTextInternal加TextStyleNode段距。提示CONTENT indent120，ICON size100，颜色#FCE29A；sprite索引3=分隔线、12=rite_tips。原作截图rite_household_font_reference.jpg交叉核对。宿主将这些块放进同一滚动树；TMP sprite基线与逐字行高仍需单独校准。

宿主实测lg正文两行的contentHeight=214，含末段80；因此VBox不能再加80。取消重复间距，分隔图后用Margin保留80；此修正只消除宿主双计数，未宣称TMP按字体face比例的段距算法已完整移植。

## 卡牌详情属性结构纠正（2026-09-08 实机）

原作右击阿尔图截图 original_runtime/card_info_artu.jpg 显示带徽记的四列属性与底部名称标签。此前把 CardAttribute 无图结构推广到数值属性区的结论错误：CardInfoNew.prefab:1311 TagPrefab GUID06679e1929ab016419ec8700bfc39f3f 指向 CardTag.prefab，AttributePrefab GUID7b2c7f38735de4144bc235b272548f0e 才指向 CardAttribute。RefreshAllTags 0x535270（dump.cs:317550类字段）为前者调用 CardTagNewController.Show 0x53f040，后者用于纯名称标签。

已恢复 TagContainer 的1700x419.49容器、400x120网格/水平间隔20/MiddleLeft、四列徽记+名称+值，标签按 Attributes authored底部矩形摆放。图标从 TagNode.resource 读取tags图集（含支持，旧CardWidget属性helper未包含支持）。导出CardTag.md作为几何证据。当前仍只展示原有六属性集合，完整can_visible/can_add/can_nagative_and_zero分组、tag_rank排序、状态栏、装备diff箭头/颜色/点击提示未迁，不标整详情完成。原作样本有装备加成，克隆开局样本不同，截图仅验证结构。

CardInfoNewController.Show 0x537000 L556-575 读取 Variable.ui_size@0x58（dump.cs:387285）按 Datapool.fontSize@0x218 设置整面板scale；原配置md=1/lg=1.1/xl=1.2/xxl=1.3。已接打开时以中心为轴整体缩放，不能把原作lg截图和克隆md截图的大小差异当成静态prefab错误。

共享SourceText发现自动字号样式可能只有enableAutoSize/sizeRange而没有size：原0回退会使文字近乎不可见，现从上限起始；完整TMP缩小拟合算法仍缺失。最新卡牌截图card_info_grid_1280.png；专项记录见card-info-grid-tests.log。

## 应用字号联动（2026-09-08）

GameApplicationConfig..cctor 0x300380 写 GAME_FONT_SIZE@0x78，stringliteral 0x25C2418 为 md；dump.cs:542495/542496 定义字段与 GameFontSize 偏好键。SettingDropDownController.InitFontSizeDropDown 0x5a96a0 枚举 variable.support_font_size，显示“小”对应 md，“普通”对应 lg，不能按界面名称推断代码。GameApplication.SetFontSize 0x43ee10 经 Datapool.OnFontSizeChanged 更新文本后写 PlayerPrefs；TextTranslate.UpdateFontSize 0x1566920 按 css_size 查找并回退 size。

已接应用偏好持久化、源配置五档下拉、已打开仪式/设置页的动态字号、关闭页面时订阅释放；固定标题不随档位变化。KeyItem 样式纠正为 @MAIN_BODY。SourceText.apply 显式指定档位仍用于独立样式测量，运行时省略档位即订阅偏好。其他未使用 SourceText 的页面尚未逐节点迁移。下拉背景导入 dropdown_bg，hash A7556C6DD1AF99EF28CB73AC08294DA5EF4B94FF5433AC16629E2E1DFD116864 与原图一致；PopupMenu 选项位置/滚动模板尚未达到源 TMP 布局。

专项2/2、15断言；全量482/482、3537断言（34脚本，2条既有警告，无引擎错误或泄漏）。GPU 测试隔离偏好文件，鼠标打开菜单后经输入分发器选择普通，确认 lg 生效；直接向弹窗 viewport 注入按键不经过原生窗口分发，已修正测试输入方式。

## 设置页新版结构（2026-09-08 实机续批，部分已接）

实机 1.0.2feaceb3 使用 SettingsPanelNew，旧宿主依据 SettingsPanel 的单面板结构不匹配。依据 SettingsController.ShowSettings 0x5ab420 / OnEnable 0x5ab270（dump.cs:325897），SettingsPanelNew.prefab 的分页 ToggleGroup→SetActive 序列，SettingToggleGroupsController.Start 0x5aadc0，以及 KeyMapController.OnEnable 0x565aa0 / KeyItemController.SetKey 0x5656e0 + Resources/InputActions.asset，迁移三分页、原图背景、源字号与键位列表。实机截图见 docs/ui_layout/original_runtime/settings_*.jpg；新版几何见 SettingsPanelNew.md / KeyItem.md。原作存档与注册表在启动前已备份于 C:/Users/User/Documents/Faust-backups/original-ui-20260908-212447。UI76/76、显示设置6/6；两种GPU分辨率实际切页/滚动/关闭通过。功能与视觉缺口详见 PageFidelity，整页尚未完成。

RitePanelTitleController.Show 0x5992a0（dump.cs:324417）：text@0x48绑定ScrollViewTextController，源实际样式@MAIN_BODY；@RITE_TEXT在OpenTips，已修正旧正文误用。Stop@0x70仅start且start_round等于Player.round才显示；LastState@0x60按!start显示且有缓存才可操作。已接两个显隐门及停止处理函数边界，仍保留完整富文本/字号档/预览提交链缺口。

## 事件提示运行时背景（2026-09-08 续批）

`PromptControllerBase.Awake 0x589430` / `UIImageExtensions.LoadSprite 0x40c210` + stringliteral 0x25ACDA8=`full/item_bg`：FullImage 父容器首位动态加载背景，LoadSprite 的 native-size 后才设置 stretch anchors。PromptNew Full 的 Mask m_ShowMaskGraphic=0，Sprite prompt_bg_mask_2 border=(284,234,248,255)，矩形按锚点换算为(38,52)/2629x828；旧克隆误把 mask 画成黑块且 y/高度符号反了。已导入源 item_bg.png（SHA256 7E4B1EBC32F2D695EECEEA3221EBFA5ADECA66077A4644D0C80F9DCD3B67C024），恢复仅裁切子项与底图。Prompt.Do 0x519340 的 icon@0x20 保留到显示层，当前标量图已接；数组/嵌套图及 full CG 仍缺。事件专项10/10、72断言；原配置事件5300102的鼠标选择/确认/后继提示/事件启用两种分辨率通过，截图与限制见 PageFidelity。

## 仪式成熟门与前置分支（2026-09-08 续批）

- `GameController.UpdateSingleRite 0x55ab10`：started 且 life < round_number 时不结算；独立字段 `dump.cs:392403` life@0x2c / `393174` round_number@0x44。RiteView 重开入口与确认按钮共用该门，0/1天拒绝、2天允许的专项通过；修复“重开正在运行的仪式便能提前领结果”。
- `DisplayClass77_0.<DoPriorSettlement>b__7 0x5b6120` 成功返回 true；`DisplayClass56_0.<Settlement>b__1 0x5b34e0` 仅在 false 时进入普通结算并 Then DoExtraSettlement。script.json 的 MethodAddress 5907056 / Address 39473456 对应 DoExtraSettlement / DAT_1825a5130；克隆命中前置后跳过普通与仪式额外结算，卡牌自带额外结算是另一链，不据此跳过。
- 串行链调查纠正：DoExtraSettlement 0x5a2270 的逐条 DoSequence 是 **PreStart/展示/EnqueueSettlement**。EnqueueSettlement 0x5a2d10 将 Settlement.result@0x30 与 action@0x38 分别排入 controller+0x110/+0x118，之后 DisplayClass56_3 b__13 0x5b4f20 / DisplayClass56_5 b__15 0x5b5070 才 Start。不能将其解释成逐条实际 result+action。现有同步 resolver 缺独立预演及提交阶段，完整迁移需同时处理预演语义、骰子、上下文、队列与存档；本批未把这部分标成完成。

## 仪式结果等待边界（2026-09-08，部分接通）

`RiteResultPanelController.Settlement 0x5a4800` / `RiteResultPanelController.__c__DisplayClass56_0.<Settlement>b__8 0x5b4850` 在尾段 RemoveRite。宿主 rite_view 已在 pending_operations 非空时锁确认、取消、金骰、重掷；零日 auto_result 延后关闭，结果产生后刷新提示。GameScreen 阻塞提示固定前景并吸收背景点击，解决仪式升层后的视觉遮挡。仪式专项28/28、110断言；两种分辨率的实际鼠标路径和截图见 [页面验收](ui_layout/PageFidelity.md)。仍缺 RiteResolver 串行执行、post_rite 清理等待、NextDay、结果预览读档与重新打开时成熟门；不登记整链完成。

## 仪式空槽与运行中编辑（2026-09-08，部分接通）

后续排序批次：`HandCardSortByCondition` 比较器在 dump.cs:319328 指向 0x56f1c0，与反编译 `GameController.__c.c` 的 FlashAndSortCard 比较器共享函数体；合格卡优先，再经 `CardExtensions.CompareBagPos 0x37eff0` 比较正 bagpos（非正视为 int.MaxValue）、id、uid。当前页排序后写 bagpos=1..N；宿主 `GameState.sort_current_hand_by_condition` 同步 rail_order/hand，其他页保持。分页专项6/6、44断言；仪式26/26、92断言；原作 auto_save 导入桥50/50、stderr空。该桥只验证同刻导入，不证明排序后原作运行对拍；候选动画、真实输入与结算串行链仍未验收。

`CardSlotController.OnPointerClick 0x53c050` -> `GameController.HandCardSortByCondition 0x5515a0`，独立字段 `dump.cs:319849` qualified_bags_has_cards/index：空槽查找合格背包，首次保留当前合格页，重复点击轮换升序合格页，无匹配不改页。宿主 rite_view 与 game_screen 已接页切换及候选焦点；原作 bagpos 重排、CardFlash/背包/槽动画、精确高亮及设备输入切换仍未接，不标整链完成。

运行中编辑门：`RitePanelShowController.Show 0x596450` L649-658/L892-900 的 `!open_adsorb && !start` -> `CardSlotController.can_move`（dump.cs:317927 附近）。宿主共用 rite_slot_access 拦截点击、拖出、跨槽及桌面返卡，停止后恢复。当前专项 26/26、92 断言，无引擎错误或泄漏；最新空槽修改尚无可见输入与原作同状态截图对拍。前一轮完整回归 473/473、3469 断言，不作为最新变更全量回归。

## 全页面验收标准（2026-09-08）

用户要求全部页面按同一严格标准还原。见 [页面清单与验收门](ui_layout/PageFidelity.md)：逐节点字体/字号、布局、可见输入和状态证据分别验收。当前仪式统一 HY 字体不符合原作 textstyle 的多字体配置，上一轮字体完成结论撤回；先验证 TextTranslate/TMPTextExtensions 共用样式链，再续仪式选卡与锁槽，随后逐页推进。既有测试全绿不等于该清单已验收。

## 2026-09-08 全仪式模板普查

`RitePanelShowController.Show 0x596450` → 共用 `ui/rite_view.gd`：补齐全部 65 背景/43 前景/10 卡槽资产与原 Sprite 网格；保留原槽根尺寸并按中心变换整个子树；fg_in_slot_index、title_bg_hide/title_help_btn_hide 接线；映射长度不足按原作退回 mapping 0。1495 个仪式映射检查、251 模板检查（247 个有映射模板 GPU 截图），GUT 471/471、3454 断言，无引擎错误；content parity 3881/0。🟡：模板分支全覆盖不等于全部剧情状态/字体/结算表现 1:1。证据与图集见 [全仪式模板验收](ui_layout/RiteTemplateCoverage.md)。

## 2026-09-08 治理家业页面续修

来源：`RitePanelShowController.Show` 0x596450（原生精灵尺寸、Position=bg_pos、slot_open 映射、fg）；`RitePanelTitleController.Show` 0x5992a0（tips_text、标题、回合）；`CardSlotController.Init` 0x53b940（类型图标）。独立信号为 dump.cs 对应类字段、RitePanelShow/RitePanelTitle/CardSlot prefab、8001002→8000003 原配置和用户原版截图。修正既有批次 X 的固定背景拉伸、bg_pos 重复偏移、未应用 slot_open 和漏前景；验收记录见 `docs/ui_layout/RitePageCorrection.md`。

## 2026-09-08 桌面续修

- 四页入口：GameController.ChangeCurrentBag 0x54cb60 → PlayerExtensions.SetCurrentBagIndex 0x38f500（合法索引 0..3）→ UpdateHandCards；CardExtensions.IsCurrentHandCard 0x3826a0 比较 Card.bag 与 Player.BagIndex。独立信号：dump.cs:391594、GameScene BagBtnGroup 四个 Toggle。接入实例分页与存档，保留全部卡的状态域。
- 仪式标牌：RiteRender.Init 0x59a9e0 / OnLanguageChanged 0x59bab0，dump.cs:324578 与 RiteNew.prefab TitleBG/Title/RightImage；标题条独立于 123×133 bound，字体 42、背景高 77，宽度由文本 PreferredSize 决定。
- 金属反光：CardRender.Update 0x53a8e0 → GameController.GetScreenOffset 0x5508a0，dump.cs:317732/319746 与 cardshow.shader 材质属性、char/*.mat。原 fragment 已丢失；Godot 光照响应只能登记为近似，不把周期扫光当作原作。

以上三项已接入。四页选择进入存档和原作导入桥，拖放索引在当前页与全局顺序间换算；苏丹新卡遵循当前页。金属贴图使用原类型对应的法线/金属图，位置偏移范围取 GameScene (0,.05)/(.2,.4)，无自动周期扫光。仪式标题改为独立可点击背景条，随地图同比缩放、读取改名覆盖。仍为 🟡：完整 HandBagPanel 整理/跨页搬运、分页计数/首见提示；反射算法与 Unity 光环境；仪式特殊类型原生尺寸/专用位移及状态装饰。详细验收见 `docs/ui_layout/DesktopContinuation.md`。

> 2026-08-17 建立（复刻工作法，见 AGENTS.md 同名节）。**本表是复刻工作的主 TODO**：
> 新工作从这里取项，不从零散错误报告取。实现行为前先在此登记原作方法背书
> （`.c` 反编译 + `dump.cs`/配置，双信号）；批次收尾时更新对应行。

## 状态图例

**已落地首批，整体仍🟡，2026-09-07 卡面与窗口启动纠偏**：从 CardNew 自制卡面项继续。CardController.Init 0x528f40 调用 GetCardShowPrefab / CardRender.Init；CardRenderChar.Init 0x538030、CardRenderItem.Init、dump.cs:317717 的 bg/image/text/stackable/life 字段与 CardShowChar/Item/Sudan.prefab、materials/card/{char,item,sudan} 独立确认真正卡面。旧 card_bg_* 是错误素材，不能充当前景边框。恢复原材质 MainTex 底板与 char *_f 前景、全幅 Icon、Title，删除 VBox 属性行。原 Shader 导出是 DummyShaderTextExporter，动态金属光照暂不宣称一致。窗口默认按用户明确要求改 Windowed/1920x1080，并尊重 --windowed；原常量 ExclusiveFullScreen 不足以证明用户请求窗口模式时应切换物理屏幕。

**显示设置输入遮挡修正（2026-09-06）**：实测设置页KeyMap覆盖显示模式行；直读SettingsPanel.prefab:24843-24867，KeyMap底部锚(0,0)、pos(487,284)、size(405,174)、pivot(.5,.5)，父高1200，Godot左上应为(284.5,829)。旧y229错误，随显示设置接线修正，以保证下拉框实际可点击。

**已接通：显示设置完整接线（2026-09-06）**。从显示启动未迁项继续：`SettingDropDownController.InitResolutionDropDown`0x5aa0b0→Screen.resolutions，闭包0x5b2af0/0x5b2b60按宽/高降序并转WxH后Distinct；模式来自原 `content/variable.json.support_fullScreen`。OnChangeScreenModeClicked0x5aab30/OnChangeResolutionClicked0x5aaab0分别调用GameApplication.SetFullScreen0x43eea0/SetResolution0x43f700并写PlayerPrefs。启动MoveNext0x4520e0读取同键，dump.cs:542497-542500确认默认与键名。Godot缺少物理显示模式设置接口，新增Windows平台适配（EnumDisplaySettingsEx/ChangeDisplaySettingsEx）承载Unity Screen接口；不另造分辨率内容表。宿主守护进程恢复游戏退出时的桌面模式，用户偏好保存在现有应用设置中。实际1920×1080物理模式/1280×720窗口切换、独立进程启动恢复及异常退出恢复桌面均已验；专项5/5+UI75/75。详见 [DISPLAY_SETTINGS.md](DISPLAY_SETTINGS.md)。

**历史记录：显示启动推断（2026-09-06，强制独占默认已由2026-09-07用户要求纠正）**：原 `GameApplication.<DoInit>d__43.MoveNext` 0x4520e0 在L883起读取 `GameResolution`，再读取 `GameFullScreen` 并调用 Screen.SetResolution；独立常量 `dump.cs:542497-542500` 为 ExclusiveFullScreen / 1920x1080。Unity ProjectSettings 的初始1920×1080/windowed（mode3）随后被此应用初始化覆盖，不能只抄工程窗口模式。克隆撤销临时1280×720窗口，项目初始请求改1920×1080/Godot exclusive fullscreen；3840×2160仍仅为UI画布。此为上一批临时落点；本批已由Windows平台适配补齐物理分辨率切换、枚举与偏好恢复，当前实现与验收以DISPLAY_SETTINGS.md为准。

**事件路径已接、整体仍🟡：串行操作链（2026-09-06）**。`OperationsExtensions.Start(IList<IOperation>,ctx)` 0x500a70 → `ListExtensions.DoSequence` 0x38b120 → `Promise.Sequence`，独立符号 `dump.cs:311993-312024`；`AllOperations.Do` 0x4ee520 使用同一入口。`Confirm` 回调0x5061a0 → `OperationContext.SetLastOpState` 0x3a0230（true→0、false→1）；`Option` 回调0x51f250 写 index+3/tag；`SuccessOperations`0x3a7930/`FailedOperations`0x39d5a0/`CaseOperations`0x399570 只在匹配执行后清状态，未匹配保持。已用 `sim/operations_extensions.gd` 承载原方法的串行等待：事件在 prompt/option/confirm/sleep/改名边界暂停，继续时恢复同级与嵌套操作，原配置 JSON（保序）+游标保留在现有运行队列中，不新增 content 转换表。已接 EventTrigger/DeferredEffects.execute_event，移除多余事件摘要；仪式结果收尾与NextDay整条Promise链继续单独登记，不能宣称本批全覆盖。

**确认框边界（2026-09-06）**：`ConfirmController.OnConfirm` 0x53fc20 / `OnClose` 0x53fc10 分别 `Done(true/false)`，`Done` 0x53fb70 直接隐藏并 Resolve；`dump.cs:318365` 的独立 ConfirmController 与 Promise<bool> 定义、`Confirm.Do` 0x4f4e30 → ShowConfirm 为第二信号。不能把 OptionController 的“选择后再确认”套到确认/取消两按钮。共享浮层按已有 payload.kind=confirm 保留直接提交，完整 Confirm prefab 视觉仍未迁。

**2026-09-05 核心准确性优先**：当前主线返回卡牌 → 仪式投放/结算 → 事件交互 → 桌面反馈的完整游玩链。详见 [核心复刻验收与当前证据](CORE_FIDELITY.md)。本表 ✅ 仅表示该行已有的方法证据，不代表所属系统已通过连续游玩或像素对拍；旁支完成数量不作为核心准确性的替代指标。

**2026-09-05—09-06 已修，事件选择提交链（取自下方 PromptNew 近似项）**：`OptionController.Show` 0x576b50 初始化 CurrentOptionIndex=-1、CurrentOption/CurrentToggle=null 并禁用 Confirm；`OptionController.<>c__DisplayClass11_1.<Show>b__0` 0x588f00 只设置选择并启用 Confirm；`OptionController.OnConfirm` 0x576900 才隐藏并 Resolve。独立信号 `dump.cs:321643-321673` 的 Confirm/OptionsGroup/CurrentOption/CurrentToggle/Promise 字段；键盘链 `OptionItemController.OnSubmit` 0x577490 → 闭包 0x588ec0 把焦点移到 Confirm。已删除“点击即执行”，改为单选/改选/确认一次；普通 prompt 才发 close_prompt。另从正式主场景 GPU 渲染确认并修正 GameScreen/事件浮层零尺寸根、无效 RichTextLabel 字号键及自制配置ID标题。首批新增7测试/54断言，第二批扩至9测试/64断言。**整体仍🟡**：完整立绘传递、动态布局、仪式/NextDay Promise链及原作同帧对拍未完成；旧行的“已完成核心”不能作为系统完成结论。证据与后续唯一优先项见 CORE_FIDELITY.md。

- ✅ **已对齐**：克隆实现有原作方法级 SRC 背书（双信号），语义经反编译验证。
- 🟡 **近似**：行为大体一致，但缺方法级背书、宿主结构自制、或只覆盖原作的一部分。
- ❌ **自制**：克隆存在、原作无对应——待消灭、降级为兼容层、或证明为等价承载。
- ⬜ **缺失**：原作存在、克隆没有——按玩家影响排期补齐。

## A. 已有方法级对齐证据（不代表系统整体完成）

| 原作证据（双信号） | 克隆落点 | 说明 |
| --- | --- | --- |
| `GameController` OnNextRound 链 b__3（round 每天无条件 +1，`player+0x2c`） | `sim/round_loop.gd` `advance_day` | 与是否持苏丹卡无关 |
| `TryGenSudanCard` 0x559730（`HasSudanCard` 门控抽新卡） | `sim/round_loop.gd` | 只有抽卡受门控 |
| `UpdateSingleRite` 0x55ab10（已 start 且 `life >= round_number` 才 Settlement；0 日仪式当日结算） | `sim/round_loop.gd` `_update_rite_instances` | 结算时机唯一入口 |
| `RitePanelController.c` OnConfirm 行 1203-1239（set_start / start_round / start_life）+ OnStop 0x5906e0 撤回 | `ui/rite_view.gd` + `GameState.start_rite_instance` | 创建与开始是两个动作 |
| `StartRite.c` Do 0x51bcf0（DSL `rite` 键只创建实例，不置 start） | `sim/result.gd` `rite` 分支 | 含吸附失败中止 |
| `DoCardUpdate` 0x54d4c0 行 5139-5231（通用卡寿命；庇护 = 身处任一仪式槽） | `sim/round_loop.gd` card_vanishing 链 | 庇护不看 start/round_number |
| `TimingRoundBase.c`（周期事件重臂，`player+0x128`） | `sim/round_loop.gd` timing_rounds | `round_begin_ba:N` = 周期 |
| `OperationFilter.c` Filter 0x3a15c0（s<n>/self/parent/all/enemy/friend/卡牌id 选择器族） | `sim/result.gd` `_slot_target_uids`、`sim/condition.gd` `_selector_condition_cards` | 通用于槽操作/装备/clean/条件 |
| `HasTagTips.c` IsSatisfied 0x3fe3c0（读卡实例 tag_tips 列表） | `sim/condition.gd` `tag_tips.<tag>` + `GameState.record_tag_tip` | 属性检定时记录，运行时不进存档 |
| `RiteResultPanelController.c:1268` → `CardExtensions.DoPostRite`（参战卡+装备逐张结算） | `sim/round_loop.gd` `_run_post_rites` | 卡牌定义 post_rite 执行链 |
| `RebirthSudanCard` 0x519d60 + b__4_0 set_life(0) | `sim/result.gd` `rebirth.s<n>` | 槽卡倒计时重置 |
| FuncCompare 运算符键尾最长匹配 | `sim/condition.gd` dispatch | 审计报告一 |
| `operations.json` / `conditions.json` 全键域 + `case:opN` 子树 + cards.json `post_rite`/`vanish` | `sim/dsl_audit.gd` + `tools/export_dsl_audit.gd` | 三类全支持归零（2134/4001/2522）；新键必须入审计 |
| `over.json` 159 结局表（处刑 vanish.over / 事件 over 值驱动） | `ui` 结局屏 | 名/副题/文本/后日谈标记 |
| `init/*.json` 难度配置 | `sim/result.gd` `_difficulty_choices` | 难度选择发生在游戏内（SetDifficulty 语义） |
| 文本占位符 `[sudan_life_time]` / `[sudan_redraw_total_left_times]` | `sim/game_state.gd` `substitute_text` | 显示前替换运行值 |
| `GameController.AddRite/AddRitePin` + `RiteController.Init` + `RitePosition.AddRite` + `Player.pins` + `RiteResultPanelController <Settlement>b__8` + `GameScene.unity` + `{RiteNew,RitePin}.prefab` | `ui/map_controller.gd` + `GameState.rite_pins` + v8 存读档/导入桥 | 2026-08-20 批次 U：地点节点、全部 `RitePosition` 子坐标、`area:N` / `area:[N,M]` 最少占用选择（并列低号）、同子点 +100 横向叠放；live Rite = runtime-UID、可点击 `RiteNew` `(0,-18)/123×133` bound；`Player.pins` = config-ID、有序去重、非交互 `RitePin` `(0,-17.6)/123×133` Icon；结算顺序为先删 live Rite 再写 `final_pin` endpoint。见 `docs/ui_layout/MapController.md` |
| `StartScene.unity` / `GameScene.unity` 场景树（GameObject/RectTransform/Sprite GUID） | `ui/main_menu.gd` 等第七波接线 | UI 原作化的证据法 |
| `StartScene.unity` Setting 按钮 `m_OnClick → SettingsController.OnShow`（124454–124470）+ `SettingsController`（dump.cs:325897–325909；ShowSettings 0x5ab420） | `ui/game.gd` 标题菜单 `settings_pressed → _show_settings → SettingsPanel` | 2026-08-24 批次 AN：标题页设置不再只是未接信号；保留主菜单于下层，关闭后回到同一标题页。回归测试覆盖点击→打开→关闭。 |
| `CardInfoNew.prefab`（2510×1077 居中面板全真值表）+ `CardInfoNewController.c` Show 0x537000（Name=GetName、Title=CardNode.title@0x20、Content=Card.custom_text@0x58‖CardNode.text@0x28 + Utils.ProcessPlaceholders、RareText=CARD_RARE_{1..4}、TypeIcon=card_type_*、MainIcon=GetPic/GetSudanFullIcon）+ `CardNode`/`Card` 字段 + textstyle.json（CARD_INFO_NAME 40..60 / DESC 18..40 / TYPE 30 / RARE_TEXT 60 / TAG_TITLE 40）+ ui.json（CARD_RARE_1..4、CARD_INFO_STATE_TITLE/ATTRIBUTE_TITLE、CARD_INFO_HELP_*） | `ui/card_info_view.gd`（批次 AF 2026-08-22；GameScreen `_source_overlay_layer` 内源画布，_unity_rect 把 anchors/pos/sizeDelta/pivot 精确换算为 Godot Rect2） | 旧自制 690×340 暗盒已删除（自制详情面板也随之删除）；🟡 登记：TagNode 属性/标签分组旗标（can_visible/can_nagative_and_zero 组合）未精确验证，克隆沿用现有属性/标签数据视图；RareIcon 稀有图标列表（Common+0x48+0xe0 序）未定位；Equips 区内容（已装配列表 vs 可装列表）未知；帮助气泡文案为 zhTW 转简体。**2026-08-22 批次 AK 后澄清**：`CardAttribute.prefab` = 纯文本行（60×40、fs30、全幅 Outline、**无徽记图**）——批次 AJ 留档的"属性徽记图标"系误解（`Resources/image/tags.png` 图集属其他列表，tag_N 帧所在待定位）；`TagInfo/StateBar` = "状态" 标题（fs40 100×50）+ `CardStateTag.prefab`（43×43 可点图标按钮：root Image 43² + Icon 43² + Outline 全幅+10、LayoutElement 43²、Selectable）行 + Left 分隔线（rite_log_sperator），状态语义（哪些状态、点击行为）无控制器背书 ⬜ |
| PromptNew 通用事件提示浮层（GameScene MainUI/Prompt；旧 1280 暗盒已迁） | **已落地（2026-08-23 批次 AL）**：`ui/event_prompt_view.gd` EventPromptView（3840×2160 源画布 + OptionBG 2705×960 prompt_bg 居中 + Full prompt_bg_mask_2 + Title/EventPromptBody fs40 + OptionNewItem 行 2200×100/步进 150/fs40/option_item_bg+highlight + Border decorate + Confirm rite_op_confirm 325×158@(2059.5,808)）+ GameScreen 迁移（`_event_overlay` = EventPromptView；choice/continue 信号回 `_consume_event_display`，队列语义原样）+ 测试 3 条（几何/选项行/继续模式）+ UI 组 66/66 | **🟡（运行时布局，单点替换）**：OptionBG 高度 960（用户截图归一化量测；`PromptController.Show 0x58a020` ForceRebuildLayoutImmediate 为真源）、文本/选项行/立绘截图推导矩形、标题条占位；渲染行为经 GUT 验证（66/66），截图走查留档（dev_screenshot_runner `--event-prompt` 旗标已加，实机 bootstrap 下浮层显隐待复验） | 中·高 → 已完成核心 |
| `GameController.GenCard` 0x54f650 → `PlayerExtensions.AddCard` 0x38b620 + `GenCoin.c Do` 0x510b40（金币 = 手牌金币卡 2000029 **多对象** count 之和；每 op 新建对象、count=操作值可为负、bagpos=1 前置、OnCardBorn） | `sim/game_state.gd` coin_count 计算属性 + `_grant_gold`/`_remove_gold`、`sim/result.gd` coin 键、v5→v6 存档迁移 | 2026-08-17 修复；多对象扣除顺序未验证（cost 支付链未审计，现最大面额优先） |
| `CostCondition.IsSatisfied` 0x3f6160（花费判定读卡对象 count，card+0x20；判定时按 player.cards 枚举序选定付款卡清单记入 `ConditionContext.need_cost_cards`） | `sim/condition.gd` 金币/coin 条件（经 coin_count 求和属性）、`game_state._remove_gold`（uid 升序=枚举序，末对象部分扣减等价于移除找零；付款执行体未反编译留档） | 读模型与支付顺序一致 |
| `PlayerExtensions.GetCounter` 0x38ce70 特殊分支（7000105 金币/7000104 门客 = 从 cards+rites 派生求和；7100007 回退配额读 Global） | `game_state.gold_total()`（hand+slot 求和）、`game_state.get_counter` 7100007 分支读 `global_state` | 金币总额含仪式槽；配额读全局域 |
| dump.cs:542529 常量表 + `PlayerExtensions` Add/SubCounter（**金骰 = COUNTER_GOLD_DICE 7100006**；额外重抽 = 7100008；回退 = 7100007 存 global，9999=无限） | `game_state.gold_dice` 计算属性（counter 存储 + 7100006 非负门 + v6 去标量）；`round_loop.use_redraw` 的普通配额耗尽后消费 7100008 | 金骰、7100007、7100008 均已落地 |
| `Global`（global.json 跨局域）+ `PlayerExtensions` SetCounter 0x38f2d0 7100007 分支（无条件非负 clamp 写 `Global.backToPrevRound`）+ `Datapool.c` StartGame L4497 新局重置 9999 + CorrectPlayerData L4130-4134 档案恢复 | `sim/global_state.gd` GlobalState（user://global.json；backToPrevRound/roundRollback 先行）+ `game_state.set_counter` 7100007 分支 + `setup_new_run` 重置 9999（`apply_resources=false` 供菜单新局延迟到叙事者选择）+ `SaveSystem.load_user_archive` 档案索引恢复 | 2026-08-18 修复；其余 global.json 字段见 ⬜ |
| `GameController` OnPrevRound 0x554f80（min_round 门 + GetBackToPrevCount 配额门 + 9999 不消耗 + IsValidRoundEnd + 确认框）→ PrevRoundInternal 0x555570（UseBackToPrev 先消耗 → `Global.roundRollback = 2` → SaveGlobal → LoadRound(round-1)）；OnBeginRound 0x5537b0 置 rollback=1 | `sim/round_loop.gd` `back_to_prev_round_end`（门控 → 消耗 → 标记 → 全局保存 → 快照恢复；配额在全局域故快照恢复不回滚消耗）+ `advance_day` 置 ROLLBACK_TO_BEGIN | 消耗先于恢复，与原作顺序一致 |
| `DatapoolExtensions` SaveRoundBegin 0x3f9050 / SaveRoundEnd 0x3f9120（先 SavePlayer(auto_save)，再写 `round_{N}.json` / `round_{N}_end.json`）+ LoadRound 0x3f8fa0 / LoadRoundEnd 0x3f8e70 / IsValidRoundEnd 0x3f8d50；LoadUserArchive 0x417350 删除 `round_*.json` | `SaveSystem.save/load_round[_end]` + `RoundLoop` 磁盘回退兜底 + 档案加载清理轮次文件；内存快照仅作同进程缓存 | 2026-08-18 批次 F；重启后仍可回退，文件名和双写顺序对齐 |
| `PlayerExtensions.SetDifficulty` 0x38f530（金骰 = 当前 + 新难度 gold_dice_count **加法**；回退配额 = 当前 − 9999 + 新难度 back_to_prev_round_count；重抽只改 `times_per_round` 与 `card_init_life`） | `game_state._apply_difficulty_resources()`（新局与中途切换共用；`apply_difficulty`） | 离开无限档=重置为新配额；有限切有限=clamp 归零；切回无限档=保留余量（防刷）；本周期已用次数与恢复周期不改 |
| `TimingRoundBase` 键 = 实例 +0x20 **int**（player+0x128 字典键；样本全部 = 事件 id×100，TimingRoundBase.c IsValid 0x465d30/OnStart 0x4660d0） | `event_runtime._timing_key` = event_id*100（2026-08-18 由导入桥发现偏差后修正；1381 个回合时机事件全单桶序号 0；旧字符串键 deserialize 迁移） | 多桶事件的序号分配未验证（当前无此配置） |
| 原作存档 Player 60 字段（dump.cs:391488 × save_samples 双信号） | `sim/original_save_importer.gd` 导入桥（difficulty 1 基 -1；cards[i]↔s{i+1}；装备嵌套→扁平 equipped 链；min_round、苏丹重抽 profile、终局结果、cached_event、HUD 标志族、`pins` 与 end/armageddon 三字段显式持久化） | 同刻对拍 49/49；仅 drawn_round 与洗牌后牌堆顺序作显式近似登记 |
| `GameController.GenSudanCard` 0x54f6f0 L3656-3662（出生 `set_life(模板 card_vanishing − player.sudan_card_init_life)` 抢跑）+ `UpdateSingleCard` b__1 0x572420（每日 life+1，`life>=card_vanishing` 且无槽位庇护即 DoVanish 处刑）+ `UpdateSudanLife` 0x55aeb0（倒计时显示 = vanish − life，可负） | `round_loop.draw_weekly_sudan`（头起步）+ `_update_card_lives`（苏丹并入通用死亡，days_left 为 vanish−life 镜像）+ rebirth 按模板 | 2026-08-18 批次 D；困难档 7−5=2 抢跑=5 天；b__1 老化豁免标签字面量未反查（无配置命中） |
| `RedrawSudanCard` 0x5558b0 L3823-3842（循环 player+0x68 次 GenSudanCard；新卡 `set_life(弃卡 life)` 继承剩余期限；弃卡 life 归 0 后 `Insert(Random.Range(0,count))` 回池）+ `GenSudanCard` 抽取 = sudan_card_pool **先 Shuffle（sudan_shuffle）再 RemoveLast** | `round_loop.use_redraw`（carried_life = 弃卡实例 life）+ `SudanCards.draw` pop_back 尾抽 | 2026-08-18 批次 D；牌序因每次 Shuffle 无意义，多重集对拍为正确粒度 |
| 手牌位系统：Card `bag`@0x48（包页 id）/`bagpos`@0x4c（页内 1 基位置，0=未摆放）+ `Player.BagIndex`@0x150（当前查看页）+ `IsCurrentHandCard` 0x3826a0（bag==BagIndex 且三标签）+ `UpdateHandCardPos` 0x559a70 L1060-1097（b__6 链内、回合开始事件后：收集当前页手牌→排序→`set_bagpos(i+1)` 压缩 1..N）+ GenCoin `set_bagpos(1)` 金币前置 + GenSudanCard `set_bag(BagIndex)` | `CardInstance.bag/bag_pos`（v7 起持久化）+ `round_loop.update_hand_card_pos`（日终压缩，克隆单页 bag=0）+ `_grant_gold` 前置 + 抽卡 set_bag | 2026-08-18 批次 E；三标签名无法从元数据反查（字面量间接寻址），留档 |

## B. 近似 🟡（行为近似承载，缺背书或部分覆盖）

| 克隆落点 | 缺口 |
| --- | --- |
| `sim/game_state.gd` v8 存档（serialize） | 原作存档 schema 已全解码（60 字段，`docs/ORIGINAL_SAVE_SCHEMA.md` + `sim/original_save_schema.gd`）；**阶段二导入桥已落地**（`sim/original_save_importer.gd` + `tools/export_save_diff.gd --bridge`，语料 auto_save 49/49 同刻对拍全过，含 Player.pins 与 end/armageddon 三字段）；续局行为对拍待实机样本 |
| `GameState.pending_operations` / `delayed_operations` | 原作 Promise/Pop 队列的宿主承载；2026-09-06 事件进入 OperationsSequence，支持 UI 等待、分支响应与存读档保序。仪式收尾/NextDay/延迟操作及旧 ResultExec 调用仍未整体串行化，保持🟡 |
| `sim/condition.gd` AttrExprParser | 文法已对齐（四则/e() 敌方/sN.tag/counter.N）；解析器宿主为自制递归下降，非原作方法映射 |
| `ui/game_audio.gd` GameAudio | 仅 main/tutorial BGM + 部分音效；拖放音、弹窗出现音、BGM 分层（level2/3）、结局 BGM、`sfx_*.json` 全量缺 |
| `ui/begin_guide_bar.gd` 引导条 | 文案/键族/存档对齐；`WizardController` 完整演示宿主与 magic_sudan 演出缺，5310004 后序列未实机校对 |
| `MapController.SetRitesPosition/SetPos` + `RefreshRitePinLines` | 批次 U 已拆出 live `RiteNew/RiteController` 卡层与 `Player.pins` endpoint；批次 V 已补 RiteNew 123×133 bound 的跨点碰撞与 bg 外整位回退（只测 bound 中心、不钳边）；批次 W 已接 8 个原作 `RiteNode.from_pins`：仅已完成 pin 可作起点、终点可为 pin 或 live RiteNew、键为 `(target rite-id, source pin-id)`、原始二次 Bézier/保留区/虚线/箭头参数直读配置。不得把 SetPos 或 from_pins 起点误套到 RitePin 之外的运行时卡 |
| `ui/map_controller.gd` `MapController.SetRitesPosition` / `SetPos` / `RefreshRitePinLines` | `LocationController.RitePosition` 子点、范围选位与同点叠放已精确；批次 V：NORMAL/`[` 组按屏幕中心排序后两两推开，固定特殊仪式只避开该组；候选出 bg 则恢复旧位。批次 W：重建线层等价 `CleanUnexistsPinLines`，且不因 live source 或无关 pin 合成边；已覆盖的 8 条配置同为 50 段、20 像素、起始保留 .08、100/40 箭头、RGBA(207,187,161,255)、虚线。|
| 苏丹卡视觉（稀有边框、倒计时红光） | 部分接入；细节原作化未完成 |
| `ui/*.gd` 旧屏坐标（game_screen / rite_view / card_widget / begin_guide_bar / game_over / ESC·档案 overlay） | **2026-08-18 批次 P 起列入 UI 布局对拍**：视口已切原作 3840×2160 设计空间（旧 `window/size/viewport=Vector2i(...)` 键无效、从未生效，游戏一直跑在引擎默认 1152×648）。**批次 Q 已将 `game_screen` 的桌面 chrome 与手牌带移出 LegacyLayer**；**批次 R 已把桌面地图换为 `ui/map_controller.gd`**；**批次 X 已将 `rite_view` 迁至 `GameScreen.SourceOverlayLayer`**：`RitePanelShow` 固定 3840×2160 源画布，`Position/bg` 4096×2148、`RitePanelTitle` 1148×1124、`CardSlot` 272×496 都直接回放 prefab；`rite_template` 的 `bg_pos/title_pos/slots.{pos,scale,rotation_z}` 按 `RitePanelShowController` 的实际坐标链写入，旧“网格 + 手牌安全区”已删。**批次 Y 已将 `card_widget` 与 `GameScene/MainUI/Hand` 改为源码直连**：CardNew `194×422`、SudanCard `185×330` 分型；Hand 的解析矩形 `516.7349,1726 / 2723.264×430` 和 `HandCardsController` 的 Space=10 / minVisibleWidth=20 直接落地，移除全局 3× mockup 缩放。**批次 Z 已删除无原作桌面对应、且无实际发射点的 `rite_selector` 自制分支**；桌面仪式入口仅保留 `MapController` 的 `RiteNew/RiteController -> RitePanelShow` 直接链。**批次 AA 已将 BeginGuide `Default` 迁至源 3840×2160 坐标，回放 1200×460 面板、400×400 溢出图标、75px 文本和 80px Close**；**批次 AB 已将结局从 LegacyLayer 的自制单页迁到 `OverNewController` 结构：Step1 标题 → 配置 CG → Step3 主菜单；`DoNext` 的 Story/AfterStory 枚举与分支保留，但 after_story 播放宿主仍缺。**批次 AC 已将 ESC 从 LegacyLayer 自制菜单迁至 `ESCGameController` 结构：源 `ESCPanel` 2×根、Mask、1021px ButtonGroup、四个激活项与 `Return/EndGame/MainMenu` 调用链；`NewGame` 保持 prefab 禁用。**批次 AD 已接 `ESCGameController.OnSettings -> SettingsController.ShowSettings(false)`：`SettingsPanel` 2×根、1788×1200 `PanelBG`、四个源 dropdown、音乐/音效 0–100 slider+独立 ON/OFF、数据收集/主播配置和 KeyMap 入口均按 Prefab 真值表重建；音量/开关经 `GameApplication` 等价应用偏好持久化，不进入 Player 存档。平台显示/语言/分辨率/字体和 KeyMap 的 Godot 宿主尚缺，仍显式禁用。**批次 AE 已将手工档案从 LegacyLayer 迁到 `UserArchiveController` 结构**：全屏 3840×2160 `UserArchive`、左侧 28% 信息栏、右侧滚动档位、固定 50 个 2760×240 的 `UserArchiveItem`（空位也显示）、覆盖确认 → 1–20 字 `UserArchiveNameInput`、改名只走 `Datapool.UpdateUserArchive` 等价索引更新而不重写玩家档。`bg_1`/按钮/卷轴原始贴图未从语料导出，保留源几何与逻辑载体，不自制替图。**批次 AJ 按原作运行时截图对拍修正卡牌详情内容行**：属性行顺序改为 体魄/魅力/智慧/**战斗**/社交/支持（原文 cfg 2000001 与截图一致：战斗在社交前；旧实现是社交在前）；标签行改为**纯名称**无数值（截图：男性 贵族 主角 已拥有；旧实现显示"名 值"）。🟡：属性徽记图标（tag_N 精灵资源未独立导出为纹理，仅 Resource/image/*.asset 存在）留待资源提取。**批次 AI 修正声望条槽位几何**：`_build_prestige_strip` 六个槽按 GameScene 真值表 `MainUI/Prestige/710000N` 行的 anchor/pivot 混合（7100001 为 (0,1)+(−6.5)，其余 (0,0)+各 y；pivot 恒 (0.52,0.94)）用 pivot 折叠后的左上角矩形摆放（−80.12/−8.62 … 751.88/43.88）。旧实现把 authored `pos` 当左上角，六槽位置全错（批次 P 时代的未对拍偏差）。补 710000N 勋章贴图与计数标签（宿主视图 🟡，原作计数走 Image/Count 精灵）。**批次 AH 已把改名提示迁至 `ChangeNameView`（`ui/change_name_view.gd`，`GameScreen._source_overlay_layer`）**：`PromptChangeName` 源几何——PromptBG 2534.4×220 居中（prompt_bg）、"修改名称"标题 fs40、InputField 826×90（input_bg，占位符"请输入名称" fs50，`PromptChangeNameController.IsValidName 0x584de0` 的 **1–20 字符**上限——旧克隆 max_length=32 是偏差，一并修正）、Content Invalid Prompt 324×48 校验错误行、Icon 471×1028 卡立绘（(1,0)(−274,66)）、Border decorate 236×324、Confirm rite_op_confirm 325×158、Cancel rite_op_cancel 168×158+"取消" fs24；控制器无显式尺寸写（高度为 ContentSizeFitter PreferredSize，语料无法静态解出）→ **🟡 登记：PromptBG 高度用 220 宿主常量**，子几何全部走 authored 锚点数学，后续实机样本可只替换该常量；i18n `PROMPT_CHANGE_NAME_TITLE/_INPUT_PLACEHOLDER`（zhTW→简体）。**批次 AG 已接桌面帮助**：`GameScreen` 新增 `MainHelpTrigger`（help_button 88×91，top-right pivot (0.5,1) pos (−70,−143.5)，z=50 位于局部模态之下、随 `Player.helpbtn_unshow` 显隐）+ `ui/main_help.gd`（`MainUI/MainHelp` 源浮层：Mask + 指针图 `main.asset` + 11 条 602×200 fs50 气泡，锚点/位置直读 GameScene 真值表；文案 = i18n `MAIN_HELP_*`（zhTW→简体，Unity `<b><color=white><size=86>` 标记转 Godot BBCode））。已知渲染差异：Godot RichTextLabel 的 86px 行内强调字形基线偏移（原作 TMP 无此表现）；InputDisplay 手柄提示未做。**批次 AF 已将卡牌详情迁至 `CardInfoView`（`ui/card_info_view.gd`，`GameScreen` 的 `_source_overlay_layer`）**：源 `CardInfoNew` 面板 2510×1077 居中（3840×2160 设计空间）、`bg_7` 全板、Name（(1911,-89)/435.55×71.58 + 卡名与 TypeIcon fs30 标题）、Content（(270,80)/1550×185 fs34，custom_text‖config.text+占位符）、RareBG（rare_stone 147×249 + CARD_RARE_1..4 石/铜/银/金 fs60）、TagInfo 左列（1336.7×647.76，属性/标签两栏）、MainIconMask（1000×1100 + 471×1028 立绘）、Equips（402.65×500.57 + EquipState 顶部）、Close（checkbox_bg 80×82 + close_2）、BottomDecorate、HelpButton → Help 浮层（card_info 四条 CARD_INFO_HELP_* 气泡）；全部直读 prefab 真值表。详见 `docs/ui_layout/RitePanelShow.md`、`docs/ui_layout/HandCards.md`、`docs/ui_layout/MapController.md`、`docs/ui_layout/BeginGuide.md`、`docs/ui_layout/Over.md`、`docs/ui_layout/ESCPanel.md`、`docs/ui_layout/SettingsPanel.md`、`docs/ui_layout/UserArchive.md`、`docs/ui_layout/CardInfoNew.md`。 |

## C. 自制 ❌（原作无对应，待消灭/降级）

| 克隆物 | 处置 |
| --- | --- |
| `set_world_scene_blocker`、`world_spawn_id`、`world_position_ratio` 存档字段 | 横版世界探针遗留；清理需评估 v5 存档兼容（GAP 留档） |
| ~~`GameState.coin_count` 标量金币~~ | 已消灭（2026-08-17）：金币卡多对象模型落地，coin_count 变为求和计算属性，v6 存档不再持久化标量 |
| ~~`GameState.gold_dice` 标量骰子~~ | 已消灭（2026-08-17）：金骰 = counter 7100006（dump.cs:542529 + Add/SubCounter + 存档样本三重信号），计算属性落地 |
| ~~`GameState.back_to_prev_left` 局内回退配额标量~~ | 已消灭（2026-08-18）：配额 = counter 7100007 存全局域 GlobalState（原作 Global.backToPrevRound），v7 局内存档不再携带；快照恢复后"补回预算"hack 一并删除（配额天然在恢复范围外） |
| ~~`event_runtime._timing_key` 字符串键 `"timing:event_id"`~~ | 已消灭（2026-08-18，导入桥发现）：改为原作 int 键 event_id×100（TimingRoundBase+0x20 int 直址 player+0x128），旧键加载时迁移 |
| `GameState.hand`/`rail_order` 独立手牌数组 | 部分收敛（2026-08-18 批次 E）：CardInstance 已承载 bag/bag_pos 并由日终压缩维护（bag_pos = 手牌序+1 不变式）；数组彻底退役仍阻塞于 IsHandCard 三标签名未反查（成员资格判据）与包页 UI 缺失 |
| `MethinksEngine` / `drop_card_on_methinks` 命名族 | 复刻期兼容接口；玩家可见概念统一为"思考"，方向定后重命名 |
| ~~弹簧积分器、透视/阴影 shader、SubViewport 双通道、ui_motion.gd~~ | 已于 2026-08-17 去 Balatro 批次删除（git 历史可恢复） |

## D. 缺失 ⬜（原作有、克隆无）

| 原作系统 | 证据入口 | 规模评估 |
| --- | --- | --- |
| after_story 后日谈播放 | **2026-08-28 批次 AP 已迁主链**：66 个 `data/config/after_story/*.json` 零转译进入 `content/after_story/`，`ConfigDB.after_stories` 对应 `Datapool.after_story@+0x70`；`ui/over_new_step2_story.gd` / `ui/over_new_after_story_item.gd` 分别 1:1 映射 `OverNewStep2StoryController` / `OverNewAfterStoryItemController`。历史 `player_data==null` 分支按 `AfterStoryData{card_id,pic,prior,extra}` 精确回放原 settlement key；有 Player/实时分支按节点绑定匹配的运行时角色卡 `ConditionContext`，再计算 close/prior/extra；页面严格按 `Settlement.sort → card_id` 排序，1000×1900 横向分页、前后页门、选页回顶已接。**批次 AQ 补齐实时写点边界**：`ConfigDB.over_ids` 1:1 承载 `Datapool.over_ids@0x2A0 HashSet<string>`，与跨局 `Global.overID HashSet<int>` 严格分离；实时 Init 先 Clear、每个命中 settlement 在原 `result/action` 调用位置后 `SetOverId(key)`，`ConditionEval over_id/!over_id` 对应 `HasOverId 0x3fdc90`；历史 `Show(AfterStoryData)` 保持只读。当前原作 66 文件共 7750 个 settlement，实测 `result/action` 字段均为 0，因此不虚构 operation；若未来接 Mod 配置，此通用 dispatch 仍为 🟡。**批次 AR 已迁放大链**：`DoZoom 0x57a970` 的 0.1 秒过渡与 `OverNewStep2StoryZoomController.UpdateSize 0x57c190` 的四组宽度范围（BG 1707→4800、Story 1050→3540、Blocker/AfterStory 1000→3740）直接落地；Range 跨过 0.2 时，条目由纵向“立绘上/文字下”切为反向横排“文字左/立绘右”，当前页偏移和每项宽度始终跟随 `AfterStoryViewWidth`。旧实现把整个 3840×2160 根节点移到 x=-1707，原控制器没有这条行为，现已删除。**批次 AS 已迁故事播放链并修正同屏几何**：`OverNewController.StartStory 0x57a4a0 → OverNewStep2StoryController.Update/StopStory/OnJump 0x57bf40/0x57bd70/0x57b810` 直接映射；`PlaySpeed=20`，浮点累加后截断为可见字符，按已渲染前缀增长高度并自动跟随底部。第一次 Jump/点击只显示全文、滚回顶部并激活 Jump，第二次 Jump 才回调父控制器；旧克隆第一次点击直接跳过故事的偏差已删除。同时按 RectTransform 真值修正 Jump `(3136,1990)/44×51`、Zoom `(3547,60)/93²`、AfterStory viewport、Op Contents 与 Prev/Next/Confirm，消除先前未做 y 翻转/错误 pivot 的位置偏差。**批次 AT 已把 CG 层拆为 `ui/over_new_step2.gd = OverNewStep2ControllerView`**：`Init 0x587ee0` 的 `Name <- OverNode.name`、`FullCG <- bg`、`CGMask <- bg+"_mask"` 直接绑定，删除旧克隆在底部重复显示 `OverNode.text` 的自制 Label；保留 prefab 的 Over Title/Name/NpcHeadContainer 结构。`show_story.anim` 保持 Step2 常驻，逐帧回放 Mask Image alpha 和 Step2-Story CanvasGroup alpha；time=0.25 调 `UpdateMaskCanvasGroup 0x57a820` 启动独立五秒线性遮罩组淡入，time=1 调 `StartStory`。**批次 AU 已补齐 `NpcHeadPrefab` 链**：历史 `player_data==null` 按 `OverData.char_cards` 原序无筛选回放；实时 Player 分支按 `<Init>b__5_0 0x588d80` 精确筛 `type==char && adherent && !lost`。`OverNpcHead.prefab` 的 100×100 LayoutElement、92×92 Image `(4,-16)` 已落地；`OverNewNpcHeadController.Show 0x57a610 → Datapool.GetHeadSprite 0x411ea0` 按 `pic` tag 直读原作 `heads` atlas，依次尝试 `id_pic/id_0pic/id/default`。**批次 AV 已补齐原作输入表面**：`InputActions.asset` 的 `UI/Submit` 仅 Space/Enter/buttonSouth，按当前选中对象驱动 Over→StopStory→Confirm→AfterStoryConfirm→MainMenuButton；`EnableAfterStoryControl 0x57aaf0` 仅在后日谈阶段绑定 gamepad d-pad/left-stick 左右到 `OnPrevPerformed/OnNextPerformed`，摇杆采用越阈值单次 performed，不把键盘方向键误当专用翻页动作。完整 prefab/动态真值见 `docs/ui_layout/{Over,AfterStoryItem}.md`；视觉走查见 `docs/ui_layout/{afterstory_screenshot,afterstory_zoom_screenshot,story_typewriter_screenshot}.png`。验收：GUT 422/422、3070 断言，零引擎错误/orphan/泄漏；配置对拍 3878/0。🟡：仅未来 Mod settlement operations 待实例证据。 | 低（原作数据无实例的 Mod 写点） |
| ~~笔记系统（普查+结构承载）~~ | 已落地（2026-08-18 批次 O）：`Player.notes` List<List<Note>>@0x138 按回合分页（页=round−1），Note={type,id,uid,count}；type 1=仪式创建/2=消亡/3=结算/4=吸附卡(count 存卡 id)/10001=成为随从/10002=获得奖励卡。克隆 `GameState.notes`+`add_note` 进 v7 存读档与导入桥（对拍行过）；运行时写点 1/2/3 已接（StartRite.c L133 / GameController.c L5867 / RiteResultPanelController 链），4/10001 调用方不在反编译子集、10002 的手牌标签门未解——三写点留档 | 中（笔记 UI 未做） |
| 图鉴/画廊 | `gallery_cards.json` / `gallery_cg.json` + Gallery*Controller 族 | 🟡 标题入口 → `GalleryPanelController`；`GalleryCardPanel.GetCards/ShowCards` 的 `is_show/type/definition/sort` 筛选、六张 `GalleryCardGroup`、可视行 CardNew 实例化已对拍。网格点击按真实链 `GalleryCardItemController.OnPointerClick` 0x547970 → `GalleryCardPanel.ShowCardInfo` 0x549520 → **专用 `ui/gallery_card_info.gd` = `GalleryCardInfo.Show` 0x5465f0**；已落地 3840×2160 真值布局主块、CardNode 名称/标题/正文、PlotItem → PlotContent、前后项边界、关闭销毁。剧情遮罩与写点按 `Show` + `AddShowedGalleryCard` 0x543c80 接到 `Global.showedGalleryCards` 并保存。资源切换按 `Show` 的 `GetPic/GetRare` 头项 + `GalleryData.resources` AddRange 原序构建，`ChangeIcon` 0x544210 同索引切图与稀有边框；配置实际引用而仓库缺失的 27 张变体图已从语料逐文件 SHA-256 等值导入。`GalleryCardHead` 110²、`PlotItem` 850×100/fs50/dot/highlight、`PlotContentItem` 930 宽/fs70+50 均有独立 prefab 真值表。`SearchCard` 0x549240 + 闭包 0x55c7f0 = `CardExtensions.GetName(card).Contains`。**2026-08-27 标签批次**：`RefreshAllTags` 0x5459c0 的 `can_visible/can_add/can_nagative_and_zero` 三门、`type==attribute` 分流与 `tag_rank` 降序已直连 `content/tag.json`；非 attribute 走 `CardTagNew.Show` 0x53f040 + `CardTag.prefab`（3 列 365×120 网格、tag_N 原图集、名称+数值），attribute 走 `CardAttribute.Show` 0x527c10 + `CardAttribute.prefab`（60×40/fs30、纯名称、Real Attribute Contents 1.5×）。**CG 批次**：导航恢复为结局下的二级 `GALLERY_OVER_BTN_CG`；`GalleryCGIconController.IsLock/ShowIcon` 0x5430a0/0x5433a0 按 `GalleryCGNode.over_id` 对 `Global.overID` 任一命中解锁（纠正与 `showedGalleryCards` 混淆），15 个 CGItem authored RectTransform、锁层、锁定提示及 `ShowBigCG` 0x5436b0 的 title/big_resource/2160 方形等比展示已落地；配置引用 60 张图均从语料 SHA-256 等值导入。仍待：结局记录表面；CG 大图标题字体与原 TMP 的渲染细差 🟡。 |
| 向导演示宿主 | `wizard/` 配置 + WizardController（未审） | 中 |
| 音频全量 | `sfx_config.json`、`sfx_settle_card_new.json`、`sfx_npc_role_dub.json`、`over_music_config.json` | 小-中（配置在语料库未接） |
| 未接配置域 | `textstyle.json`、`imagestyle.json`、`dt`、`mobile_help.json` | 逐域判断用途后接入或说明（`variable.json` / `ui.json` 已由图鉴直接读取，`quest.json` 已由任务链直接读取，`upgrade.json` 已由命运商店与新局升级链直接读取，`credits.json` 已由制作人员名单直接读取，均非转换层） |
| 制作人员名单（Credits） | **2026-09-03 Credits 批次已迁**：`content/credits.json` 与语料逐字节一致，`ConfigDB.credits` 原样直载 19 名开发者、3 个 contributor 记录、12 个 thanks 记录及 11,006 个名字；代码按 `CreditsController`、`CreditsPage`、`CreditsPageDeveloper`、`CreditsPageContributor`、`CreditsPageThanks`、`CreditsGroup`、`CreditsMember` 原类边界拆分。`CreditsController.OnEnable/DoPrev/DoNext`（0x3f6f60/0x3f6ce0/0x3f6aa0）回放 developer → contributor → thanks 外层顺序、页面实例复用、内部页优先翻动与位置保存；`CreditsPageContributor` 每页两个 group；`CreditsPageThanks.GetNames 0x3f8070` 保留 column/cell_size/page_size 限幅、.NET UTF-16 长度、跨行补齐及分页边界（原配置“测试玩家”3 页、首个大型众筹名单 39 页已锁入对拍测试）。`Credits.prefab` 与三个子 prefab 的 3840×2160 根、关闭/翻页按钮、标题、logo、19 张开发者卡 authored transform 及静态字体/装饰几何均直接回放；图片逐文件从语料拷入并由内容哈希核验。**同日排版补证**：`CreditsHelperGroup.prefab` 的旧 `Title/seperator/spacer/Names` 均为 inactive，`CreditsGroup.Show 0x3f7590` 只向 active `NamesContainer` 实例化 `CreditsNameWithJob`；职位/姓名已按 prefab 恢复为左列左对齐、右列右对齐及源金色。thanks 的 Talk/Text 起点、四行占位推导行高、`<indent=N%>` 绝对列位和配置实际使用的 `<size>`/`<font>` TMP 标记均已按源语义承载。截图：`docs/ui_layout/credits_screenshot.png`、`credits_contributor_screenshot.png`、`credits_thanks_screenshot.png`。 | 🟡 尚无原作同帧运行截图，不能宣称像素级视觉对拍；剩余差异限于源 TMP 字体与 PreferredSize/自动字号度量、contributor 动态行高、`CreditsMember` 淡入淡出时长及 InputDisplay/手柄选择链。thanks 百分比 indent 已不再是缺口。 |
| 任务完成通知（Global / Quest / StoryNotify） | **2026-08-29 任务链批次已迁**：`content/quest.json` 与语料逐字节一致，`ConfigDB.quests` 直接承载 `Datapool.quest`；`sim/global_extensions.gd` 1:1 映射 `GlobalExtensions.RefreshQuest 0x4fcee0`，`Global.counter/quest` 与 `totalPoint/usedPoint/questState/hasEnterQuest` 使用原键持久化；`ModifyGlobalCounter.Do 0x5176a0 → RefreshQuest(true,false) → Global.OnQuestCompleted → StoryNotifyController.Show 0x5b9c00` 已直连。`ui/story_notify_controller.gd` 回放 StoryNotify.prefab 630×444 顶中几何、原 prompt/point_0 纹理、0.333s 入场+5s 停留+0.333s 退场与 FIFO；点击发出原作形状的 Story target 请求。原 `save_samples/global.json` 未包含非默认 quest/counter，故目前以反编译+配置/Prefab 双信号验证，**不宣称真实非默认存档逐字段对拍**。真值表见 `docs/ui_layout/StoryNotify.md`。**2026-09-02 任务面板与领奖链已迁**：`GameController.ShowStory 0x557ab0` 直接实例化 `ui/story_controller.gd = StoryController`；`StoryController.OnEnable/OnItemClicked/OnRewardClicked/OnRewardAllClicked/Sort/UpdateQuestRewardIcon`（0x5b0f70/0x5b1370/0x5b20b0/0x5b1d20/0x5b2370/0x5b2680）、`StoryItemController.Init/UpdateState/OnRewardClick`（0x5b9450/0x5b96a0/0x5b9520）和 `StoryTargetItemController.Init 0x5b9e80` 均拆成同名控制器边界。领取落在 `GlobalExtensions.GetQuestRewqrd 0x4fc860`：完成门/重复领取门、`Global.quest[id]=2`、`totalPoint += upgrade_point`、保存和 `HasQuestReward` 重算已回放。任务、目标与格式均直接读取原作 `quest.json`/`variable.json`；StoryPanel/StoryItem/StoryTargetItem 三份 Prefab 真值表与 15 张原图已落地，其中目标完成图 `Finish` 由 Prefab GUID 校正，不再误用 point。**2026-09-03 命运商店批次已迁**：原样 `content/upgrade.json` 50 个 `UpgradeNode` 由 `ConfigDB.upgrades` 直载；`Global.upgrade Dictionary<int,int>` 按原字段存读（key=已购买，value 0/1=停用/激活），`PointShopController.OnBuy/OnActivate/OnDeactivate`（0x5802d0/0x580090/0x5805e0）精确回放购买自动激活、`totalPoint -= cost`、`usedPoint += cost`、停用不退款。`HasUnlockUpgrade 0x3feb40` 按购买成员资格而非激活值，`HasAvailableUpgrade 0x4fcd00` 按未购买且可负担、刻意不看可见条件。新局 `Datapool.InitPlayer 0x413700 → DoUpgrade 0x410dc0` 以升级 id 升序执行 active 节点的原始 effect；新增的 `g.card`、`g.change`、`sudan_card` 回放本配置实际使用路径，尤其苏丹卡追加在已洗牌池尾。UI 拆为同名 `ui/point_shop_controller.gd` / `ui/point_shop_item_controller.gd`，按 Shop/ShopItem prefab 3840×2160 真值重放主块、行、按钮与链接卡预览；截图 `docs/ui_layout/pointshop_screenshot.png`。原 `save_samples/global.json` 已逐字段对拍 totalPoint/usedPoint/upgradeState/upgrade 的默认值；因样本没有已购买升级，**不宣称非默认升级存档已有真实样本对拍**。 | 🟡 原作 `Player.sudan_cards` 同时保存隐藏 Card 对象，而宿主仍以 id 队列+抽取时实例化承载；本配置 `g.change` 的开局手牌目标已覆盖，但该 Operation 对其他 Player.cards 区域的通用替换尚未迁。商店手柄 InputDisplay、LoopScrollRect 的选择保持/滚动插值、原 TMP 字体渲染细差及原作运行时截图逐帧对拍仍待完成；任务面板 TMP 字体细差同理 |
| Live2D | 语料库 `live2d/` 已提取 | 大（既定策略：第一版静态图） |
| ~~背包/手牌位系统（bag/bagpos/BagIndex）~~ | 已落地（2026-08-18 批次 E）：CardInstance.bag/bag_pos 持久化 + 日终压缩 + 导入桥透传与对拍（24 项）；三标签资格判据与多页包 UI 未做（三标签名留档） | — |
| end/armageddon 表现状态（`end_open/is_armageddon/armageddon_rite_id`） | **2026-09-03 状态边界已迁**：三字段按 Player@0x178/@0x179/@0x17C 原键进入 GameState、v8 存读档、原作导入桥与 49 项同刻对拍。**同日终局地图批次**：`RiteResultPanelController.<OnClose>b__0 0x5b51c0` 已在已提交的 5010009 结果关闭时精确写 `end_open`，不把其他 `final_pin` 仪式误判为终局；`ui/map_controller.gd.change_bg_to_end` 直接映射 `MapController.ChangeBGToEnd 0x567b70`，加载与语料 SHA-256 等值的 `table_map_end` 2048×1076 原图和 `Resources/image/end_map` 10 帧原图集，并按当前地点图名替换存在的同名帧；`MapController.Start 0x56a890` 的读档恢复由 `_ready` 回放，次日链通过桌面 refresh 幂等消费同一状态。实机渲染走查见 `docs/ui_layout/end_map_screenshot.png`。`is_armageddon/armageddon_rite_id` 实为 `sfx_config.armageddon_music_loop` 的仪式循环音乐恢复状态：`StartRite.Do 0x51bcf0` 处理 `play_in_rite_create=true`，结果关闭链处理 false，`GameController.Start`/次日 b__5 还原 Animator 参数。 | 🟡 终局主地图与地点帧已接；`Eft_End_Map` 是 GameScene 中含多层 ParticleSystem 的独立层级，尚未迁且未用自制效果替代。原始 `sfx_config.json` 尚未接入 `ConfigDB`，`LoopArmageddonController` 音频播放与两处写点仍待下一批；不得把此字段族扩写成自制“决战玩法模式” |
| RNG 续航（random_cache） | 存档字段双信号 | 小-中 |
| ~~激活苏丹卡的期限存档承载~~ | 已解（2026-08-18 批次 D）：期限 = 卡寿命模型（出生抢跑 + 每日 life+1 + 模板 card_vanishing 死亡），存档承载即 Card.life 本身；导入桥 days_left = vanish−life 精确恢复，仅 drawn_round 仍近似（难度中途切换后不可反推） | — |
| ~~原作苏丹抽牌序（sudan_pool_cards 顺序语义）~~ | 已解（2026-08-18 批次 D）：sudan_shuffle 开启时每次抽取先 Shuffle 再 RemoveLast，顺序无意义；克隆 pop_back 尾抽对齐 | — |
| ~~唯一性登记（only_cards/only_rites）~~ | 已落地（2026-08-18 批次 I）：`only_cards` = 已到桌的 `CardNode.is_only` 配置 id；`only_rites` = 成功 InitRite 的全部仪式 id；type-3 loot 每次抽取前按对应登记集过滤，删卡/删仪式不回退。导入桥对拍两项 | — |
| ~~生成计数（gen_cards/gen_tags）~~ | 已落地（2026-08-18 批次 J）：`gen_cards[id]` 在新建玩家卡时 +1；`gen_tags[code]` 对新卡 `GetTags` 的 HashSet 每个稳定 tag code +1，另承接 `Common.MarkTagGen` 回调语义。苏丹抽卡在池标签复制后显式登记；存档/导入桥双向对拍 | — |
| ~~改名持久化（custom_rite_name/player_card_name）~~ | 已落地（2026-08-18 批次 H）：玩家级配置 ID 覆盖表独立于 Card.custom_name/RiteInstance.custom_name；卡名覆盖优先于实例名，仪式名覆盖优先于配置名。证据：CardExtensions.c 0x37ff50 + Player.c 0x3a4520 / PlayerExtensions.c 0x38dcb0 + dump.cs Player@0x168/@0x170 | — |
| ~~UI 引导标志族（sudan_box_show/story/prestige/deadline/helpbtn、once_new_rites_is_show）~~（结构承载） | 已落地（2026-08-18 批次 N）：五个 Player HUD 标志 + 每仪式首见表进入 v7 存读档/导入桥；`close_*` 操作按原作 0=显示、非零=隐藏写对应字段。原作桌面 HUD 与仪式首见提示 UI 未接，故保持 semantic | 小 |
| ~~苏丹重抽恢复模型（times_per_round/times/recovery_round、sudan_card_init_life）~~ | 已落地（2026-08-18 批次 K）：Player 四字段进入 v7 存读档与导入桥；`RedrawSudanCard` 先用普通配额、再扣 7100008；`SetDifficulty` 只换额度和未来苏丹头起步，保留本周期已用数与 Init 恢复周期；日初按 recovery 周期清已用数 | — |
| ~~结局状态（success/over_reason）~~；~~cached_event（结构承载 + 桌面托盘 UI）~~ | 前者已落地（2026-08-18 批次 L）。后者批次 M 结构承载 + **2026-08-22 批次 AK 桌面托盘 1:1**：载入侧 = `OnCachedListChanged 0x553b70`（cachedEvents@GameController+0x320 字典差量重建：枚举 `Player.cached_event`@0x148 → `CachedEventPrefab`@0xA0 实例化到 `cachedEventContainer`@0x108 → `cachedEvents[id]=controller`；结尾 `SetActive(+0x220, 0<Count)` = **"Next Round Mask For Cached Event"**（GO 47/rect 7639，596×634，Image a=1/255 透明点击吸收器，场景 UnityEvent OnClick→`NoticeCachedEvent 0x5534d0` 摇动托盘））。**条目摆放谜底**：容器 Mono 11735 = HorizontalLayoutGroup 同构字段（m_Padding L0/R100/T0/B0、m_ChildAlignment 5=MiddleRight、m_Spacing 50、m_ReverseArrangement 1、control/expand/scale 全 0）——运行时布局组流式摆放，故 `CachedEventController.Init 0x527900` 无定位代码；条目 rect = 右→左（index 0 最右，right edge=3840−100，步进 112.5+50）。**条目**（`Resources/prefab/CachedEvent.prefab`）：checkbox_bg 112.5×117 + dialog 图标 192²@scale 0.5（视觉 96²居中）+ new 红点 85.5²@锚(1,1) pos(−7.9,−12.7)（顶右探出）+ **禁用** Shaker（positionIntension(0.2,−0.2)、freq 40、time 10、maxSpeed 2、perlin，`CachedEventController.Shake 0x527940` set_enabled(false/true) 重启；`Shaker.c` 已阅）。**点击链** `OnCachedEventClicked 0x5538e0`：`Datapool.can_cached_event_settlements` TryGetValue 命中→OperationMask@0x1C0 + `OperationsExtensions.Start` + b__0 0x5728d0 收尾隐藏+`RemoveCacheEvent`；未命中→直接 `RemoveCacheEvent`。克隆落地：`ui/cached_events_view.gd`（托盘 3840×128 + 右→左条目 + notice 抖动）+ GameScreen 集成（`refresh()` 按 `cached_event` 重建、点击=未命中分支移除、mask 显隐）+ 测试 2 条 + 截图 `docs/ui_layout/cachedevents_screenshot.png` + 新纹理 dialog.png/new.png。🟡/⬜：cached_settlement 结算分支（语料零实例，🟡 未接）；Shaker perlin 曲线/SmoothDamp 轮廓（🟡 视觉近似）；红点在点击后是否隐藏无证据（🟡）；StoryNotifyController 文字通知已迁至独立任务链行 | 小 |
| global.json 其余字段（gameStatistics/doneEvent/doneRite/showedPrompt/choosedOption/showedGalleryCards/图鉴/升级/任务/overRecord/meta counter） | `save_samples/global.json` 29 字段；承载容器 GlobalState 已落地（backToPrevRound/roundRollback + `overID`/`showedGalleryCards` HashSet）。**结局记录批次 AN 已迁原作分文件链**：`OverRecordStore` 1:1 对应 Datapool `Init/Load/Add/Delete/CheckOverRecordExcess`，读取 `over_record_excerpt.json` → `OVERRECORDDATA/over_record_No.{n}.json`，旧 `Global.overRecord` 仅作缺 excerpt 时迁移源；`OverRecordView` / `OverNodeView` 分别对应两个原控制器，列表顺序、坏档剔除、200 上限、动态计数、删除及 2301×360 行几何已接。**回忆详情批次 AO**：`OnMemoryClick 0x57cfc0 -> ShowOverInfo 0x57e1e0 -> LoadPlayerOverData 0x415e40 / LoadDefaultPlayerOverData 0x414c70 -> SetRecord/Init/Hide` 已直连；非空 `player_data` 复用原作存档导入及逐字段 diff，`text_extra.Length` 修正为真实 Story 门，record 最终返回画廊而不进入 Step3。原作样本只覆盖空记录；非空回忆用 `save_samples/auto_save.json` 作为 Player 产物裁判。截图 `docs/ui_layout/galleryover_screenshot.png`。🟡：完整 `AfterStoryItem` 翻页/放大控制、Story 打字机与动态人物头像尚未迁。 | 中（结局生成、升级/任务与其余 Global 域） |
| `[back_to_prev_count]` 文本占位符（Datapool.__c b__389_6 走 GetBackToPrevCount） | 原作配置中未发现该 token 的使用实例，token 拼写无法从语料确认 | 暂缓（不猜测命名） |
| ~~回退快照持久化（Datapool 轮次文件 + IsValidRoundEnd + LoadController.LoadRound）~~ | 已落地（2026-08-18 批次 F）：`round_{N}.json` / `round_{N}_end.json` 双边界持久化、有效性门、磁盘加载刷新 continue、档案恢复清理旧时间线；内存 round_snapshots 降为同进程缓存 | — |
| ~~仪式面板“恢复上次投放”（Player.last_round_rite_data）~~ | 已落地（2026-08-18 批次 G）：`OnConfirm` 按 Rite.id 记录手动槽 guid 的 `{id,count}`，`OnLastState` 按卡牌可用量与当前槽条件逐槽恢复；存读档与原作导入桥均承载。证据：RitePanelController.c 0x58f1c0 / 0x58fdf0 + dump.cs Player@0x158、LastCardData@0x10/@0x14、RiteNode.Slot.open_adsorb@0x20 | — |
| RoundRollbackType.BACK_TO_PREV_BEGIN(3) 的写点 | dump.cs:6186 枚举存在，写点未定位（LoadRoundBegin 疑似） | 小（待双信号） |
| 成就面板 | steam_achievement 空实现 | 可选 |
| 主菜单 ButtonsGroup 三键行（图鉴/商店/剧情，405×174 间距 240）+ Contacts 行 + Version 文本 | `docs/ui_layout/StartScene.md` 真值已备；图鉴/商店/剧情面板本体未复刻（D 表各行），社交链接对克隆无意义 | 随各面板批次接入 |

## 普查程序（如何扩展本表）

1. 从 `engine_spec/dump.cs` 提取运行时类清单（Controller / Manager / Panel 优先，JsonHandler 指路数据域）。
2. 每个类归入四状态之一，登记证据指针（文件 + RVA/行号）；查无克隆对应物即入 ⬜。
3. 每个复刻批次收尾时更新所 touched 的行；每个大阶段做一次 dump.cs 增量普查。
4. 表中新增 ✅ 必须附双信号；只有单信号时写 🟡 并注明缺口。

## 对拍台（验收裁判）

- **资产**：语料库 `save_samples/`（`auto_save.json`、`save_slot_000.json`、`global.json`、`user_archive.json`）= 原作真实存档，明文 JSON。
- **阶段 1 ✅（2026-08-17）**：schema 全解码——Player 60 字段与 dump.cs 双信号吻合，零未知零类型不符；映射表与工具落地（`sim/original_save_schema.gd` + `tools/export_save_diff.gd` + `tests/test_save_diff_harness.gd`，mapped 11 / semantic 11 / missing 38）；快照文档 `docs/ORIGINAL_SAVE_SCHEMA.md`。结构发现：金币=卡 2000029 堆叠（双信号）、骰子疑 counter、手牌=bag/bagpos、仪式槽位内嵌嵌套、UI 队列不持久化、回退双轨、random_cache。
- **阶段 2 ✅（2026-09-03 状态行增量）**：导入桥——原作存档 → 克隆 GameState → v8 payload → 同刻值对拍；语料 auto_save **49/49** 全过（含 only_cards / only_rites / gen_cards / gen_tags / 苏丹重抽 profile / 终局结果 / cached_event / HUD 标志族 / Player.pins / end_open / is_armageddon / armageddon_rite_id），差异按 converted / approximated / dropped 防静默登记。此后涉及状态的批次验收 = GUT 全绿 + 对拍零差异（或差异均有原作语义解释）。
- **远期**：固定种子 trace 对拍（同一操作脚本下原作 vs 克隆的事件/结算日志序列）。
- **UI 布局对拍 ✅（2026-08-18 批次 P）**：`tools/export_ui_layout.gd` 解析语料 AssetRipper 场景/prefab YAML，产出 RectTransform 真值表（锚点/位置/尺寸/pivot/缩放 + CanvasScaler + LayoutGroup 参数 + sprite guid→语料路径）至 `docs/ui_layout/`；主画布设计空间 = **3840×2160**。表现层批次的验收 = 每个摆位数字能回指真值表行；视觉证据用 `tools/dev_screenshot_runner.tscn` 截图。

