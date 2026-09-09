# 全页面原作还原验收

2026-09-08 用户要求：将原作证据、字体、布局和交互的严格还原标准推广到每个游戏页面。本文是 METHOD_MAP 的表现层验收索引，不取代方法背书。

## 统一验收门

- 来源：每页登记原控制器 .c 方法、dump.cs 类字段和 prefab/场景/config；文档只作导航。
- 字体：逐文本节点核对字体资产、textstyle 键、字号档位、颜色、行距、自动缩放和富文本。不得统一替换成一种字体后声称完成。
- 布局：核对 anchors/pivot/size/scale、原图与网格、布局组、滚动和动态高度；静态 prefab 不代替运行时布局。
- 输入：从可见入口实际点击、拖放、选择、确认、取消、返回；验证禁用态、空态、进行中态、遮罩和焦点。直接发信号只能作为单元测试。
- 状态：验证操作前后状态与持久化，拒绝以界面看起来正确代替结算正确；涉及状态须原作产物对拍。
- 验证：1920x1080 与 1280x720 GPU 截图；与原作同语言、同字号档、同状态比较。记录引擎日志、测试及差异。不同状态截图只能辅助观察。
- 完成：证据、可见输入、视觉和状态四项均过才验收该页；缺证据、近似或未迁移明确保留，不用测试数折算完成率。

## 页面清单

以下是当前宿主表面清单，均为待按新标准复验，不代表原作页面已穷尽。下一次普查须从 dump.cs 控制器及 StartScene/GameScene/Resources prefab 增补缺失页面。

| 页面族 | 当前宿主入口 | 复验重点 |
| --- | --- | --- |
| 仪式准备、运行、结果、帮助 | rite_view.gd | 正文字体/字号档、空槽选卡、运行中锁槽、取消/返卡、结果等待 |
| 桌面、地图、手牌、分页 | game_screen.gd / map_controller.gd / hand_bag_tabs.gd | 拖放、页归属、标牌、层级、整理背包缺口 |
| 卡牌详情、改名 | card_info_view.gd / change_name_view.gd | 属性/标签字体、装备、输入与校验、返回 |
| 事件、选项、确认 | event_prompt_view.gd | 选择后确认、取消、队列等待、动态高度和人物图 |
| 主菜单、游戏菜单 | main_menu.gd / esc_game_panel.gd | 每个可见入口、禁用与返回、遮挡 |
| 设置、存读档 | settings_panel.gd / user_archive_panel.gd | 字号档与分辨率、持久化、覆盖与取消 |
| 任务、通知、缓存事件 | story_controller.gd / story_notify_controller.gd / cached_events_view.gd | 长文、目标、领取、排序、队列与点击 |
| 命运商店 | point_shop_controller.gd | 购买/激活/停用、预览、滚动与返回 |
| 图鉴、卡牌图鉴详情 | gallery_panel.gd / gallery_card_info.gd | 筛选、解锁、翻页、长内容、返回 |
| 结局、故事、后日谈 | game_over.gd / over_new_step2.gd / over_new_step2_story.gd / over_new_after_story_item.gd | 分支、动态内容、翻页与放大 |
| 回忆列表与详情 | over_record_view.gd / over_node_view.gd | 真实记录、加载、删除与取消 |
| 制作人员 | credits_controller.gd 及 credits_page_* | 分组、字体、长名单、滚动 |
| 教学与帮助 | begin_guide_bar.gd / main_help.gd | 高亮、阻断、关闭与后继事件 |

## 当前已确认的共性缺口

卡牌详情续批：原作实机 card_info_artu.jpg 证实数值属性使用 CardTag 图文预制体，“CardAttribute无徽记”只适用于纯名称标签。现有400x120四列网格保留；2026-09-09已补普通标签的显示旗标、tag_rank排序、相对初始配置的diff颜色/静态箭头、状态图数量、装备卡扇形排列及装备槽图。完整GetTags复合项、装备拖放/取回、提示、动态属性监听和TMP材质仍缺。克隆与原作存档不同时刻，只验布局结构，不验数值一致。

### 2026-09-09 连续验收批次

- 桌面地图与事件标牌（2026-09-09 续批）：地图改按 GameScene 相机(97,-106)/正交半高1732 与 Map 缩放1.25 做等比投影，建筑改用 Image 子节点自身尺寸与偏移（不再用 Location 容器矩形），rites 图集按实际 PNG 尺寸同比换算裁切；事件标题宽度参与 bound，避免多个事件挤在一起。1920x1080、1280x720、1600x1000（16:10）三窗口 GPU 真实点击：图标面与标题条分别打开正确实例、自宅同点4个仪式展开后不重叠、画布始终 3840x2160；截图 desktop_map_{1920,1280,1600}.png 与原作 desktop.jpg 同比例裁切，建筑吻合、标牌高度差<5%。图标留白、TMP基线、发光与像素级重叠对位仍缺，详见METHOD_MAP顶部条目。
- 桌面顶部续批：菜单与帮助在桌面之后接收鼠标，菜单恢复圆形底图；声望恢复数字底托、number_6与7100006金骰；处刑日改为剩余寿命/玩家初始寿命，补路径图、红数字及RedText缩放曲线。两尺寸GPU真实菜单打开/返回/帮助、最后一天动画、仪式槽内较老苏丹卡、不同分母及隐藏状态通过；完整490/490、3605断言，parity3882/0。精确TMP基线、发光、进度过渡和同状态逐帧对拍仍缺，详见METHOD_MAP顶部条目。
- 卡牌帮助：按原作card_info_help.jpg重放四段说明、遮罩和圈线，修复文字绘制范围；生产入口实际打开帮助、点遮罩关闭、关闭详情在1280x720与1920x1080通过。卡牌UI专项78/78、912断言；全量基线486/486、3565断言，无引擎错误或泄漏。
- 仪式正文：统一滚动树内使用原说明、分隔图、提示图、120缩进及提示颜色；滚动条预留17。Godot段末已含80间距，取消外层重复80，分隔线后保留80；最终间距版两尺寸截图及滚轮验证通过。与rite_household_font_reference.jpg对比仍有字形行高、分隔图绘制厚度及TMP sprite基线差异。
- 事件正文：按源预制体区分PromptNew的1300与OptionNew的1100上限，选项间距20；长文滚动、选项避让与底部装饰跟随，正文/选项使用对应textstyle和共享富文本。完整回归487/487、3574断言（prompt-content-final.log）；最后拆分上限后UI79/79、923断言（prompt-caps-ui.log），无引擎错误或泄漏。两分辨率长文滚轮通过，并以原配置5300102实际完成选择、改选、确认、分支提示、关闭后event_on；日志prompt-gpu-{1280,1920}.log，stderr空。
- 内容一致性：3882文件，0违规；17份源配置仍未接入。所有图像均为宿主输入/渲染证据，不能代替原作同状态动态布局对拍。

事件外围水平位置、960最小高度、选项行高、人物图组仍为近似；本批仅映射正文高度观察器，不把它升级为完整源LayoutGroup。仪式预览/实际执行分离、串行结算及存档恢复仍是状态缺口。13页族没有新增整页验收完成标记。

本批增量类普查复核dump.cs中的PromptControllerBase:323540、PromptIconController:323572、OptionController:321643、OptionItemController:321676及OptionNewItemController:321709。由此保留ConfirmNew（无高度观察器）的独立布局缺口；人物图数组、选项鼠标高亮对象、手柄提示未因此视为完成。

### 2026-09-08 实机设置页续批

原作实机为 1.0.2feaceb3，截图物理尺寸2560x1440；菜单显示的1920x1080不等于捕获尺寸。设置页实际使用 SettingsPanelNew，已替换旧版单面板：画面声音、键位说明、其他设置三分页，源背景九宫格、控件纹理、字号、可滚动16行键位表及关闭按钮。桌面显示参数仍使用现有系统适配器，音量和三个布尔偏好仍写应用设置。键位行来自源控制器顺序与 InputActions 绑定，显示键位不代表所有对应游戏动作已实现。

验证：UI专项76/76、888断言，显示设置专项6/6、41断言；tools/verify_settings_pages.gd 在1280x720及1920x1080实际点击三分页、滚轮滚动和关闭均通过，stderr空。纹理错误与测试滚轮未释放问题已修正。截图 settings_{display,keys,other}_{1280,1920}.png；原作证据 original_runtime/settings_*.jpg（原始捕获编码为JPEG，已纠正扩展名）。源布局表 SettingsPanelNew.md / KeyItem.md。

字号续批已接：五档选项直接读取 support_font_size，默认 md=小、lg=普通（默认值来源 GameApplicationConfig..cctor 0x300380 + stringliteral 0x25C2418）；应用级 GameFontSize 偏好持久化，已打开仪式/设置文本实时更新，固定标题不变。新建页面读取当前偏好，释放页面自动解除订阅。专项2/2、15断言，全量482/482、3537断言。GPU脚本使用隔离偏好文件，实际打开菜单并经输入分发器选择 lg；截图 settings_font_popup_*.png 展示展开状态。

仍未验收整页：语言选择、手柄焦点、下拉菜单选项居中/勾选位置/限高滚动未完成；主播辅助与掌机模式仅偏好字段，尚无对应渲染分支；数据收集偏好不启动遥测。下拉展开背景已使用原图 dropdown_bg；文本SDF为Godot局部适配，原TMP材质、选中高亮和字重仍有差异。不得把三分页输入通过称为全设置功能完成。

仪式实机证据：original_runtime/rite_household.jpg，源 Main Content/Scroll View/Viewport/Text 实为 @MAIN_BODY；旧 @RITE_TEXT 属于 OpenTips，已修正文与提示段字体选择。停止按钮由 Show 0x5992a0 按 start && start_round == Player.round 显示，开始后隐藏LastState；处理函数也防止跨回合绕过。正文、提示与结果已接全局字号偏好，提示尚未完整回放 variable.json 的行高/缩进模板，故换行和段间距仍待修正。截图 rite_compare_1280.png 与原作不同回合，仅用于同模板几何比较。

原作 data/config/textstyle.json 中 @MAIN_BODY 和 @RITE_SETTLEMENT_TEXT 指定 xiquemuye SDF，@RITE_PANEL_TITLE 指定 CardTitle SDF。已原样导入 content/textstyle.json 和两种源字体，由 ui/source_text_style.gd 读取仪式正文、结果与标题样式。设置字号联动与Tips字体已接；自动字号、行距与 SDF 材质未完成，不能据此验收整页字体。

仪式空槽合格背包轮换、当前页排序与运行中锁槽已接，详见 METHOD_MAP。当前继续收敛仪式结算生命周期，再按上表推进。

## 结算等待与叠层（2026-09-08）

已接手动结果等待门：pending_operations 未完成时阻止确认收尾、取消、金骰与重掷；零日 auto_result 等提示完成再关闭。结算后主动刷新 GameScreen，提示覆盖仪式与桌面控件并吸收面板外点击，仍低于全局菜单。源收尾依据为 RiteResultPanelController.Settlement 0x5a4800 及闭包 b__8 0x5b4850 的 RemoveRite 调用。

tools/verify_rite_wait.gd 使用合成提示和实际鼠标事件验证等待、继续、最终确认；1920x1080 与 1280x720 图形路径通过，截图 rite_wait_1920.png / rite_wait_1280.png 已人工检查提示无遮挡。该截图不属于原作同状态对拍，不能证明 PromptNew 动态布局还原。

仍未完成：RiteResolver 内部串行操作、post_rite 提示后的清理时机、NextDay 等待、结算预览跨进程恢复。重新打开时的成熟门已由下方续批修复。不得将 UI 等待门称为完整 Promise 链。

## 基线验证

最新续批：483/483测试、3543断言，34脚本，2条既有警告，无引擎错误或泄漏。该全量覆盖字号联动、CardTag网格和自动字号范围修正；整面板ui_size最后补入后另跑UI专项，见card-info-final-ui.log。tools/verify_card_info_grid.gd在1280/1920用lg档验证1.1倍整面板和全部六枚徽记，截图card_info_normal_{1280,1920}.png。整页标题/正文样式、状态/装备差分与交互仍缺，不作全页验收。content parity仍3882文件、0违规。

续批：仪式重新打开时的成熟门已接（life < round_number 不允许提前结算）；前置结算命中后跳过普通与仪式额外结算，来源见 METHOD_MAP。完整回归479/479、3516断言，无引擎错误或泄漏。

事件背景续修：PromptNew/Full 的 m_ShowMaskGraphic=0，原遮罩纹理不应画成黑色实体；PromptControllerBase.Awake 0x589430 加载 full/item_bg 并放在裁切容器首位。已原样导入 prompt_full_item_bg.png，以 NinePatchRect 的仅裁切子项模式回放，并修正 Full 拉伸锚点换算为 (38,52)/2629x828。当前提示自己的标量 icon 已传到画面，避免从其他分支借图。事件专项10/10；tools/verify_source_option.gd 使用原事件5300102，验证选择→确认→后续剧情→完成才启用5300104，1280与1920窗口均通过。截图 source_option_1280.png / source_option_1920.png。

事件页仍未通过完整验收：多列/嵌套人物数组与 full CG、动态布局、原作同状态截图对拍、输入设备焦点链仍待完成；目前单人物的矩形还是旧截图近似，不把素材传递修复说成布局完成。

本批完整回归：34 脚本、477/477 测试、3501 断言，无引擎错误、orphan 或泄漏诊断（保留2条既有测试警告）。最终提示层级修正后另跑事件专项9/9、64断言及上述两种 GPU 路径，stderr 均空。content parity：3882文件、0违规。原作尚未集成的17个配置域仍由 METHOD_MAP 跟踪，0违规不表示配置已全部接入。

2026-09-08 本地 gut-test.log 的最终汇总为 33 脚本、471/471 测试、3454 断言。该回归不能证明字体正确、可见输入通过或全页面原作一致；此前仅有 headless 测试结果，不登记为本标准的视觉验收。
