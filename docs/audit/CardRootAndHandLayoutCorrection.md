# 卡牌根命中、拖起和手牌堆叠纠偏（2026-09-10）

对应近似审计 A05，并继续消除 A02/A03/A04 的布局遗留。该批完成下列 PC 鼠标边界，不等于完整 CardController/HandCardsController 已验收。

## 原方法与独立信号

只读源根为 `Faust-local-source/_unpack`。

- `CardController.c CardMoveUp 0x528390`：slot非空不执行；根尺寸恢复oldSize宽、高加100。`CardResetMove 0x528480`恢复oldSize，并检查当前选择对象。dump.cs:316959起确认rect@1b0、isMoveUp@216、oldSize@218；CardNew根194×422、CardShow固定中心锚。原DLL RVA1c9e4d0=`0000c842`为100。
- `HandBagController.c SetChild 0x55e360`按根尺寸、scale与pivot赋位置，底部对齐；dump.cs:320498确认签名。新增高度100不改变卡面422高，而是卡面中心升50；候选scale1.1时升55。
- `CardController.c OnPointerEnter 0x52ae70`只在CardFlashController.flash@38为false时调用MoveUp。`CardFlashController.c Update 0x52e330`在峰值清flash，下降残余currentTime不阻止新的进入；dump.cs:317258起确认两个字段不同。不能用alpha>0代替flash门。
- `CardController.c OnBeginDrag 0x5294e0`调用`UnityEntensions.SetParentNormalize 0x395630`，保留世界中心后把scale归一，再记pointer减localPosition为offset。新适配把放大/扩高根的点击坐标换成固定卡面拖动预览坐标，不再叠加一次悬停偏移。
- `HandCardsController.c Update 0x563520`与`HandBagController.c Update 0x55e510`分别提供相同的左/中/右钳制与兄弟顺序链：左段SetSiblingIndex，右段逐个SetAsFirstSibling；鼠标进入本身没有“z+20”。`dump.cs:320419`的ItemInfo为pos/width/scale；320465/320760字段提供Range、SpeedMultiple、SpeedRange等独立类型信号。
- `GameScene.unity`主Hand组件：reserveWidth0、Space10、minVisibleWidth20、Range0、SpeedMultiple200、SpeedRange100..400；根pivot(.52,0)。原DLL按PE节读取RVA1c9e558=`9a99993e`=.3，RVA1c9e764=`6f12833a`=.001，符号±1/0.5亦已核对。此处Update没有deltaTime乘数，不另造平滑速度。

## 实现改变

1. `CardWidget`以真实size/scale承载命中：悬停根194×522，固定CardVisualFace局部y50；底部不动，选中/刷新反复调用不累计位移。移除普通卡面的visual-only缩放/抬升；槽卡保留宿主scale且不扩高。
2. 候选缩放影响实际鼠标区域。上升闪光中的进入不抬升，闪光结束不伪造第二次进入。移除自制hover z+20。
3. `_get_drag_data`把局部点换算为归一化卡面坐标，普通卡及1.1候选卡拖起都保持卡面中心；失败拖动恢复源位置。
4. `source_hand_layout.gd`取代均匀压缩：中间保留完整卡间距，左右各按20单位堆叠；真实兄弟顺序和z一致。布局/插入计算按rail_order（bagpos承载）取卡，不能把画图顺序写回存放顺序。
5. 边缘滚动按原Range更新；手牌不溢出时居中并将Range恢复1。鼠标不动而卡片移动时显式刷新Godot鼠标命中，承接Unity EventSystem逐帧raycast职责。

## 验证

- UI81/1073、根几何4/44、按住提示6/26、原手牌分段布局3/18、分页6/44，共100测试/1205断言通过。最终日志无引擎错误、失败、orphan或泄漏报告。
- 原根几何重建测试首次报告32个待释放旧CardVisualFace；测试加入实际帧等待后确认queue_free全部释放，未掩盖报告或改成忽略泄漏。
- `verify_card_root_input.gd`在1280/1920验证新增上沿命中、候选横向命中、普通/候选拖动中心、失败返回。两种拖动输入的中心位移均精确等于鼠标位移。
- `verify_hand_edge_input.gd`在1280/1920通过真实窗口光标轮询验证20卡左右堆叠、双向滚动、遮挡顺序变化、静止鼠标命中刷新及存放顺序不变。截图`hand_edge_{left,right}_{1280,1920}.png`已检查1280左右图。
- 修正旧GPU工具伪造固定relative=(20,-20)的鼠标事件；边缘滚动检查还必须移动窗口实际光标，单独push_input不能替代get_local_mouse_position的每帧轮询。
- `verify_card_reference_states.gd`1280通过；`verify_card_equipment_input.gd`1920通过人物装备、详情替换、旧装备回手链。检查本批选中卡截图；未启动原作同状态重新对拍。

## 仍未完成

原BeginDrag后续`CalculateRelativeRectTransformBounds -> Bounds.ClosestPoint`对超出归一化边界的抓取点钳制尚未迁。InputManager独立选择与详情显示的完整状态区分、手柄持牌/自动Range、拖入时sticky装备/堆叠吸附区仍未完整对应。当前插入预览沿已有有效目标判定，不能把本批普通PC布局边界外推为全拖放等价。A05保留未完成状态，继续从这些方法推进。
