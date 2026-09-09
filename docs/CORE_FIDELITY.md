# 核心复刻验收与当前证据

2026-09-09 连续批次：卡牌普通标签分组/rank/diff、状态图、装备展示及帮助遮罩已补；仪式正文消除段末与容器的重复间距；事件正文按PromptNew=1300、OptionNew=1100限制高度并可滚动，选项间距20，富文本子节点承载文案。完整回归487/487、3574断言；最后提示参数拆分后UI79/79、923断言，无引擎错误/泄漏。两分辨率GPU验证卡牌帮助开关、仪式滚轮及原配置5300102的选择—分支提示—event_on路径。content 3882/0。整页仍未全部验收，剩余边界见[全页面验收](ui_layout/PageFidelity.md)，不能把本段测试计数解释为13页完成。

2026-09-08 全页面续批：原作实机纠正SettingsPanelNew三分页与CardTag属性网格，应用字号按原配置五档持久化并联动已接SourceText的仪式/设置文本。CardInfoNew打开时按ui_size整体缩放；六枚徽记、四列属性、底部纯名称标签已接。全量483/483、3543断言；最后面板缩放后UI专项76/76、894断言，无引擎错误或泄漏。设置两分辨率实际选择/切页/滚动/关闭通过，卡牌两分辨率lg档渲染通过。全部13页面族仍未完成统一验收；语言、完整TMP排版、卡牌标签分组/装备diff、仪式预演提交与串行等待等缺口见PageFidelity，测试全绿不等同全页面还原。

2026-09-08 后续：成熟门与前置结算绕过普通/额外分支已修，完整回归479/479、3516断言。事件提示补运行时背景与隐藏遮罩本体、修正拉伸矩形，并恢复当前操作标量人物图；最终事件专项10/10、72断言，原配置5300102的两种窗口实际输入通过。这里更新前段“成熟门未完成”历史状态；预演/实际执行分离、串行结算、数组人物与完整动态布局仍未完成。详见 PageFidelity 与 METHOD_MAP 最新条目。

2026-09-08 续批：已补手动仪式结果的 UI 等待门，以及零日 auto_result 等待提示后关闭；提示升到仪式之上并拦截背景点击。仪式专项28/28、110断言，两种窗口分辨率实鼠标路径通过。完整边界与截图见 [全页面验收](ui_layout/PageFidelity.md)。RiteResolver 内部仍非串行 Promise，post_rite/NextDay 等待、预览读档及成熟门仍未完成，不能据此宣称结算全链一致。

本轮：2026-09-05—09-06。目标是完整复刻《苏丹的游戏》；当前尚未达到完整克隆。

2026-09-07：新增[卡面与手牌区域纠偏证据](ui_layout/CardSurface.md)。已消除错误底纹遮挡立绘、假缩略图卡面、缺失手牌底板、苏丹手牌尺寸错误与窗口启动切换桌面问题。四分页、数字精灵、动态金属光照、仪式标牌继续列为核心缺口。

## 工作主线

用户要求将优先级拉回卡牌、事件、仪式和桌面。后续批次从 METHOD_MAP 的对应近似项出发，按玩家连续操作验收，不再按容易补完的外围面板数量推进。

本轮完成桌面根布局、事件选择提交，以及事件操作串行暂停/恢复的首批纠偏。四个系统尚未审完，不能外推成全量玩法、完整 Promise 链或视觉一致。

## 已确认的问题及本轮修正

| 问题 | 原作/运行证据 | 修正与边界 |
| --- | --- | --- |
| 点击选项直接执行，没有确认按钮 | `decompiled/OptionController.c` Show 0x576b50 置 index=-1、CurrentOption/CurrentToggle=null、Confirm 不可交互；`OptionController.__c__DisplayClass11_1.c` b__0 0x588f00 只保存选择并启用 Confirm；OnConfirm 0x576900 才隐藏并 Resolve。`dump.cs:321643-321673` 提供字段与方法独立信号 | 单选 → 可改选 → 确认一次。未选择不可提交；重复旧信号不能消费下一个提示。原配置 `event/5300102.json` 直接作为分支结果裁判 |
| 同一队列混用选择框与确定/取消框 | `ConfirmController.c` OnConfirm 0x53fc20 / OnClose 0x53fc10 → Done 0x53fb70 直接返回 true/false；`dump.cs:318365` 的 Promise<bool>；`Confirm.Do` 0x4f4e30 → ShowConfirm | 复用已有 payload.kind=confirm 区分，一次点击直接完成，无额外确认；标签字典读取 text。原开场事件 `5300000` 的确认配置覆盖确定与取消两条路径。事件调用方的 success/failed 暂停链已接；确认/取消完整视觉及仪式调用方尚未完成 |
| 键盘选项与确认没有独立步骤 | `OptionItemController.c` OnSelect 0x577400 设置 toggle；OnSubmit 0x577490 经 `OptionController.__c__DisplayClass11_0.c` b__1 0x588ec0 把焦点移到 Confirm | 选项获得焦点即选中；ui_accept 把焦点移到确认，当前按键不执行分支。没有声称覆盖完整手柄导航及 InputDisplay |
| 普通提示和选择框混发 close_prompt | `PromptController.c` Hide 0x589e20 调用 OnClosePrompt；`OptionController.c` OnConfirm 0x576900 直接 Resolve；`Option.c` Do 0x518ac0 通过 ShowOption Promise 返回。独立监听配置 `event/5300302.json` | 仅 kind=prompt 发 close_prompt；选择提交不误触该监听事件 |
| 桌面刷新重建当前选项框，无法稳定保留选择 | 克隆 `GameScreen.refresh → _refresh_event_overlay → _show_event_overlay` 原先无条件销毁重建；原作 Show/OnConfirm 之间由 CurrentOption/CurrentToggle 持有选择 | 以当前 pending_operations 队首对象身份保持 UI；连续两个内容相同的操作仍作为不同发生次数重新初始化。此身份比较属于 Godot 宿主实现，不新增游戏存档字段 |
| 正式入口的事件浮层实际上接近不可见 | 从 `scenes/main.tscn → Game._show_game` 实际 GPU 渲染记录：GameScreen.size=(0,0)、EventPromptOverlay.size=(0,0)，PromptNewCanvas.scale=(0.00001,0.00001)，面板全局宽仅 0.02705。原作根布局独立依据：GameScene MainUI 3840×2160、PromptNew 根全伸展锚点 | 两个动态根节点同时设置 anchors 和 offsets。修后同入口根为 3840×2160，canvas.scale=(1,1)，面板全局宽2705。新增测试覆盖延迟布局后的全局矩形及窗口大小变化 |
| 正文设置了无效字号键 | 克隆对 RichTextLabel 设置 Label 的 `font_size`，旧测试也读取同一个无效键；实际截图正文极小。`PromptNew.prefab` Content 的 TMP 字号为40，见 `docs/ui_layout/PromptNew.md` | 改为 RichTextLabel 的 `normal_font_size` 及粗体/斜体对应键；测试实际文本布局高度，不只读取覆盖字典 |
| 内部配置 id 被画成标题 | `PromptControllerBase.c` ShowInternal 0x589890 仅将 text 处理占位符后写入 Content；PromptNew prefab 没有该标题节点 | 删除自制标题行，`5300102_option_1` 不再出现在玩家界面 |

对应实现：`ui/event_prompt_view.gd`、`ui/game_screen.gd`。新测试：`tests/test_event_choice_controller.gd`；纠正旧契约：`tests/test_ui_layout.gd`。

## 验证为何会失真

旧 `test_game_screen_event_overlay_consumes_prompt_choice_and_followup` 明确断言点击选项后就执行分支，测试固化了错误语义；旧几何断言只检查面板局部2705×960，完全没有验证祖先缩放之后还能否被看见；旧正文测试读取的字号键未参与实际文字排版。

另一个旧测试以真实存在的 `5310008` 测“配置缺失”，因自制标题显示该编号而误通过。现改为真正不存在的测试ID，并先断言配置为空；没有为通过旧测试把内部编号重新显示给玩家。

因此验收同时检查：原作方法/独立信号、配置驱动的状态变化、正式入口的全局几何与实际渲染。现有存档导入桥是同刻字段对拍，不能证明等待交互期间或连续多日的执行顺序。

## 接下来只推进一个核心问题

**第二批取项：事件与仪式结算的暂停/继续顺序。** 从 METHOD_MAP B 表 `pending_operations / delayed_operations` 的 Promise 阻塞缺口取项，先沿 `EventTrigger.DoSettlements` 0x4fb1c0、`Option.Do` 0x518ac0、`OperationsExtensions.Start` 及其闭包核对完整执行链。克隆 `GameState.trigger_events` 先执行 settlement 再追加 event 展示记录；必须查明是否多弹事件摘要、是否在确认前执行了后续动作，不能因为 FIFO 保存正确就判定顺序正确。

事件路径的已确认修正见下方第二批记录；完整仪式与 NextDay 链仍未完成。下一项集中到 RiteResolver → RoundLoop.finalize_rite_settlement：提示前状态 → 等待确认 → 消费/返还槽卡 → 返回桌面，不能提前收尾。

| 核心域 | 后续验收范围 | 当前证据状态 |
| --- | --- | --- |
| 卡牌 | 手牌选中、拖出、投槽、撤回、返回、重排与数量/UID/装备归属同步；多卡重叠、缩放和悬停使用最终画面比较 | 本轮未重新逐方法审计；已有 METHOD_MAP/SRC 仅作导航，不提升状态 |
| 仪式 | 打开、可投判定、提交/撤回、跨日、检定、结果确认、消费/返还及地点节点变化，验证中途存读档 | 本轮未重新审完；沿 RitePanelController / RiteResultPanelController 的待对齐行取项 |
| 事件 | 共享 Promise 顺序；普通提示/选项/确认框各自的交互；正文、角色图与动态布局 | 选择提交、根布局与事件串行等待已修；仪式/NextDay 串行调用及完整视觉仍未完成 |
| 桌面 | 正式启动和读档进入后，卡牌/地图/仪式/事件的全局可见性、输入遮挡与缩放 | 已修 GameScreen 零尺寸根；其余按实际连续操作采样，不能用局部尺寸全绿替代 |

## 已知且未掩盖的表现缺口

- 事件新执行器已把原 `Option.icon` 保留在队列 payload；旧仪式 `_apply_option → queue_choice_prompt` 路径仍丢失，`_next_event_display` 的 prompt/choice 分支也没提供图像。源 `PromptControllerBase.ShowInternal` 支持字符串与列表，单字符串放中间槽、清左右槽；当前单个右侧 portrait 不能代表完整源结构。`5300102` 配置明有 `cards/2000001`，当前截图仍缺该立绘。
- 面板960高度、正文/选项位置仍为旧截图近似。长文本、多个选项与图片组合必须重建原动态布局；本轮不宣称无溢出，更不宣称像素级一致。
- 新截图仅是克隆正式入口的渲染证据，没有同一事件、同一窗口的原作帧与之逐像素对拍。截图中的卡牌/桌面动画也未作为本轮验收完成项。
- 原作连续操作 trace 尚未建立。原作真实存档仍用于49项同刻对拍，不能替代过程轨迹。

## 第一批验证（第二批前的历史结果）

- Godot：实测 `4.7.stable.official.5b4e0cb0f`。
- 新事件选择/根布局回归：7/7，54断言；包含原 `5300102` 分支、`5300302` close_prompt 监听及 `5300000` 确认配置。
- 原作 `save_samples/auto_save.json` 导入桥：49/49，零差异（仅同刻检查）。
- 完整 GUT：29脚本、447/447测试、3305断言，进程退出码0；最终UI组75/75。没有 SCRIPT ERROR / ERROR 或退出时资源泄漏。GUT摘要有2条 Float/Int 比较警告；非法条件输入和拒绝旧版本存档测试还会输出预期的引擎警告。
- 完整运行时，新测试曾在 queue_free 的下一帧前报告13/25个临时孤儿，根布局测试的直接赋size也产生锚点警告；已仅调整测试等待释放与父容器搭建，再专项运行7/7、54断言，日志无警告、孤儿或泄漏。未把中途节点统计隐去，也未为测试修改运行时释放语义。
- GPU 实际渲染：OpenGL Compatibility，1152×648窗口、3840×2160设计空间，选中第二项后 `pending=choice`；图见下。

![正式主场景中的事件选择，第二项已选中、尚未确认](ui_layout/core_choice_selected.png)

## 第二批：事件操作串行暂停/恢复（2026-09-06）

已确认：旧 `ResultExec.execute` 碰到 option 会跳过同级其他键，遇到 prompt/confirm 则继续执行后续状态变化；`trigger_events` 还会在真正提示之后追加事件摘要。原作 `OperationsExtensions.Start(IList<IOperation>,ctx)` 0x500a70 经 `ListExtensions.DoSequence` 0x38b120 调用 Promise.Sequence；独立符号 `dump.cs:311993-312024`。本批新增 `sim/operations_extensions.gd`，映射串行执行与等待，不写事件专用补丁、不修改原配置。

- Option 回调0x51f250 写 index+3/tag；Confirm 回调0x5061a0 经 SetLastOpState0x3a0230 写0/1。只有完成 UI 操作才恢复后续 case/success/failed。未匹配分支保留状态，执行的分支清状态（Case0x399570/Success0x3a7930/Failed0x39d5a0）。
- 原事件5300102第二项：确认后显示5300102_prompt_2；关闭它之前5300174仍未开启，关闭后才执行 event_on。原5300000确定/取消均在响应后进入5300066，显示原5300066_prompt_01。原5300258第二项恢复后创建5001027。
- `event_on` 的 start_trigger 进入嵌套事件；非重播事件先注销再执行（EventTrigger.DoSettlements0x4fb1c0）。关闭提示触发的子事件先结束，父事件才恢复，队列中无关提示随后显示。嵌套 game over 中止父链剩余动作（DoWrapper0x500510）。
- 存档仍使用已有 pending_operations，仅附运行游标与原操作 JSON。原始键序连同尚未进入的嵌套分支一起保留，避免默认 JSON 字典排序改变执行顺序；两次真实 SaveSystem.serialize/deserialize 边界覆盖了“选项等待→子提示等待→继续”。没有新增内容转译格式或手写运行内容。
- `choose:N` 的 N 大于条目数量时保留源顺序、不消耗洗牌 RNG（ChooseOperations.GetOperations0x4f3830）。不据此宣称 Unity 随机数流已等价。
- sleep 完成和改名取消恢复所属链；改名 DoClose0x5849b0 的 Promise.Resolve 是源证据。旧裸 ResultExec/DeferredEffects.execute_choice 仍留作仪式兼容入口，代码注释已明确其不等价限制。

边界仍未完成：RiteResolver 的 prior/result/action/extra 条件与清槽/返卡收尾、RoundLoop 的整日等待、Delay/Loot 内部旧执行器、counter/global_counter 的旧 event 展示入口、所有操作的状态回传与取消传播、完整原作连续运行 trace。事件修正不能使这些链自动变成1:1。旧“权力的游戏”测试把未关闭的首日教学/结果提示与另一个手工构造的保险事件混在一起；现分成“原 UID 被后继仪式复用”和“无仪式时保险事件清标签”两项，完整跨日 UI 流仍单独待验，未以清空队列冒充通过。

第二批验证：事件界面9/9（64断言）；串行执行7/7（39断言）；sim 58/58；卡实例11/11；原作同刻存档桥49/49。最终完整 GUT：30脚本、457/457测试、3356断言，退出码0，耗时177.541秒；GUT摘要有2条 Float/Int 比较警告，另外有非法条件输入及拒绝不兼容存档的预期警告。完整及专项日志均未出现 SCRIPT ERROR、引擎 ERROR、孤儿节点报告或退出资源泄漏。最终日志：系统临时目录 faust-sequence-verified.log；桥日志 faust-sequence-bridge.log。git diff --check 通过。

## 默认启动窗口纠偏（2026-09-06，用户实机反馈）

此前 GPU 截图使用 `--resolution 1152x648`，没有验证默认启动尺寸。`project.godot` 只有3840×2160设计视口、window override为0；在本机2560×1440屏幕（工作区2560×1392）默认启动时，系统实际将窗口裁成2564×1421，expand 后逻辑视口3897×2160，宽高比偏离设计。

已只在 `project.godot` 设置初始窗口 override=1280×720，保留3840×2160设计视口及 canvas_items/expand。通过实际图形后端加载正式 main 场景、**不传 --resolution** 复验：窗口1280×720，位置(640,336)，逻辑视口3840×2160，退出码0。前后日志在系统临时目录 `faust-startup-size-before.log` / `faust-startup-size-after.log`。这是宿主窗口配置修复，不宣称原作全屏/分辨率选项已经迁移。

## 原作显示启动核对（2026-09-06，历史阶段；下述缺口已接通）

用户要求按原作还原后，直接核对 `GameApplication._DoInit_d__43.c` MoveNext0x4520e0 L883–984：先读取 GameResolution，再读取 GameFullScreen，调用 Screen.SetResolution。`dump.cs:542497-542500` 的缺省值为1920x1080与ExclusiveFullScreen。Unity ProjectSettings.asset 的1920×1080/windowed只是应用初始化前的工程设置，不能作为最终启动模式。

因此撤销上一节的临时1280×720窗口，`project.godot` 改为请求1920×1080、Godot exclusive fullscreen（mode4），保留3840×2160设计画布。未传 --resolution 的图形实测：窗口2560×1440覆盖本机屏幕，位置(0,0)、mode4、逻辑画布3840×2160，退出码0。日志为系统临时目录 `faust-startup-original-fullscreen.log`。

**历史边界（已由后续接线消除）**：当时恢复的是默认全屏启动与画布比例。Godot在此后端全屏使用显示器当前2560×1440模式，并未像Unity的Screen.SetResolution那样切换物理显示模式到1920×1080；设置页的显示模式/分辨率按钮仍是占位，支持模式枚举和显示偏好恢复尚未迁移。不把工程中的1920×1080请求值说成实测物理分辨率。

## 显示设置完整接线（2026-09-06）

已补齐上述物理模式切换、设置页交互、保存与新进程恢复。Windows原生适配实测默认1920×1080全屏，选窗口后恢复2560×1440桌面并应用1280×720窗口；正常/异常退出均恢复桌面。专项5/5+UI75/75通过。完整来源、图形验证与截图见 [DISPLAY_SETTINGS.md](DISPLAY_SETTINGS.md)。

## 完整克隆的完成条件

四个核心域必须分别具备原作证据、同操作过程对拍、视觉/输入验收以及已知差异登记；典型分支、边界失败、取消、跨日、读档均有覆盖。外围系统在核心链不再被这些已知缺口阻断后继续补齐。存在未验证或会改变玩家结果的差异时，结论仍是“未完成”，不按测试总数或静态配置覆盖率折算为克隆百分比。

本轮未联网、未提交或推送；开始时已有的地图、仪式、截图工具及相关测试改动保留。

复验命令（PowerShell，所有路径均在本机）：

```powershell
$env:GUT_TEST_PATH = 'res://tests/test_event_choice_controller.gd'
& 'C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tools/run_gut.gd
Remove-Item Env:GUT_TEST_PATH
& 'C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tools/run_gut.gd
& 'C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tools/export_save_diff.gd -- --bridge
git diff --check
```
