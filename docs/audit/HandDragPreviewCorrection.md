# 拖入吸附、占位及抓取钳制审计（2026-09-10）

继续 A05。只验收下述边界，不登记整个卡牌输入链完成。

## 原作方法与本批改动

- `HandCardsController.c Update 0x563520`先读取按bagpos排序的ItemInfo.pos/width/scale，以`pos+offset+(width+Space)/2`找插入候选；相等走右侧候选。此时尚未加入拖动卡空隙。删除克隆按绘制子节点顺序、旧占位位置反推下一占位的算法。
- 相同可堆叠卡/可装备目标且鼠标不在目标原始左缘之外，进入IsSticky，lastDropPos=-1；StickyStart.x为原始左缘、y为当前鼠标高度。原`GameScene.unity`主Hand的StickyRange=(240,100)。任一轴越界才释放，等于边界仍保留；释放这一帧只清IsSticky，下一次Update才能再插入空隙。`source_hand_layout.gd`复现这些判定。目标兼容性目前复用现有装备/堆叠验证器，见剩余项。
- 装备/堆叠目标直接返回可接收前，仍须执行父手牌的吸附更新。否则先前的插入空隙会残留。CardWidget转发同一事件的局部坐标，通过真实父子变换转换，不再另取一次操作系统光标位置；HandRailDrop的落点同样采用传入事件坐标。
- 原Update增加空隙时只给后续ItemInfo.pos与总宽度增加`dragWidth+Space`，子节点数量不变。移除“虚拟占位卡”参与左右钳制的实现，避免压缩区额外多出20单位格。
- 用本机dumpbin只读原GameAssembly.dll限定地址反汇编补查反编译丢失的浮点参数：`0x180564292..0x1805642c3`重新算`xmm6=available-total`并乘Range；`0x1805643e0`附近为不溢出分支；`0x180564423..0x180564452`以`xmm2=xmm6+ItemInfo.pos`、`xmm3=ItemInfo.scale`调用SetChild。确认空隙增加后会重新居中，不用目测补位置。
- 删除已经失效的_hand_pan_ratio及鼠标比例回调，边缘滚动统一使用上一批已恢复的原Range链。

## 抓取边界

`CardController.c OnBeginDrag 0x5294e0`在SetParentNormalize后调用`CalculateRelativeRectTransformBounds -> Bounds.ClosestPoint`。新增适配器对当前已迁移的active Control子树计算矩形角点并集，按归一化scale后的抓取点进行钳制。不会把透明Flash排除：原CardNew Flash active=1，Outline初始active=0。

进一步检查原引擎机器码：`CalculateRelativeRectTransformBounds 0x1bb83c0`在`0x181bb8487`清edx，再调用`0x658980`；dump.cs:344771起确认该泛型为`Component.GetComponentsInChildren<T>(bool includeInactive)`。因此它确实取active子树；`0x181bb8606`取各RectTransform角点，再变换到root空间并求界。dump.cs:546096/546099确认两重载。

**还不能宣称整棵原作边界相同。** 原CardNew包含尚未完整迁移的GamepadPrompt/输入提示节点，active与可见并非同义。当前适配覆盖已迁移节点；缺失节点可能改变极端抓取边界，保留在A05，不能用当前子树测试替代原机完整边界。独立InputManager选择与详情显示也仍待拆分。

## 验证与验证工具纠偏

- 最终GUT：UI81/1073、预览边界及集成5/24、根/钳制5/48，合计91测试/1145断言通过。预览覆盖half-spacing临界、吸附左右边界、双轴240/100包含边界、释放下一帧、旧空隙/画图顺序无关性、压缩区不增加假子节点以及真实CardWidget到手牌父层委托。
- GPU装备工具在1280/1920覆盖实际吸附置位/清空占位、人物装备、详情替换装备和旧装备回手。测试进入原方法的吸附判定区域；不能假设被空隙移开的卡面中心总在该区域内。
- GPU抓取工具在1280/1920覆盖普通/候选拖起、失败返回、扩高区域命中。现在同时移动窗口实际光标并发送GUI输入，避免帧间轮询用旧OS光标覆盖注入事件。抓取位移按实际屏幕像素核验：误差须小于一个物理光标像素；不能拿1280窗口的整数像素去要求3840设计坐标绝对相等。
- 首轮GPU吸附检查失败揭示验证工具只注入事件而未同步OS光标；修正工具后两分辨率通过。没有把失败日志当成功，也没有改宽源吸附区域来迎合测试。
- 本批未修改content，也没有启动原作同状态录像对拍。

## 剩余与下一证据点

1. 原CardController.CardStack 0x5286b0和CardDropManager.DropCard 0x4ef4f0没有克隆`_can_stack_dropped_card`的source==hand限制；槽卡拖出后再合堆链尚需连同槽归属/锁/移除语义核验，不能只改一个UI条件。
2. 原完整active子树（尤其GamepadPrompt）、独立选择/手柄持牌、拖入时携带卡宽/回退路径还需继续补齐。抓取钳制只是当前迁移子树的实现，不关闭这些缺口。
