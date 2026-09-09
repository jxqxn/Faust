# 桌面续修：四页、金属反光、仪式标题

2026-09-08。本轮沿已有修改继续，不改 content，不联网，不提交。

## 已实现

- 四个手牌页按钮恢复原 bag_icon/1..4_on/off 图片及 80×80、间隔 6 的布局。点击只改变当前可见页，其他页的卡仍归玩家所有。Player.BagIndex 进入存档和原作导入桥；非法页号保持原页。堆叠显示只统计当前页。
- 手牌拖放把当前页序号换算回全局 rail_order，避免其他页的卡干扰排序。槽中返回的卡进入当前页。新抽苏丹卡读取当前页。
- 金属卡底板和人物前景使用各类型原法线与金属贴图；拖动、升起引起的屏幕位置改变会更新材质偏移。石卡不附加金属反光，弹窗暂停时材质保持静止。未添加自动往返扫光。
- 仪式标题从图标内部移到独立 TitleBG 条，使用 42 字号、77 高背景、56 左空位和 57 右端。宽度按当前名字度量，标题也能点击打开对应 UID 仪式，模态时同步禁用；地图缩放同时作用于标题字号和背景。

## 原作证据

- GameController.c ChangeCurrentBag 0x54cb60；PlayerExtensions.c SetCurrentBagIndex 0x38f500；CardExtensions.c IsCurrentHandCard 0x3826a0；dump.cs Player.BagIndex 391594；GameScene BagBtnGroup。
- HandBagController.c DropCard 0x55d1f0：bagpos=插入序号+1、bag=目标页；GameController.c GenSudanCard 0x54f6f0：bag=Player.BagIndex。
- CardRender.c Update 0x53a8e0；CardRenderChar.c Init 0x538030；GameController.c GetScreenOffset 0x5508a0；dump.cs 317732、319746；GameScene ScreenXOffsetRange=(0,.05)、ScreenYOffsetRange=(.2,.4)。
- 原材料 materials/card/{char,item,sudan}/*.mat 的 BumpMap/MetallicGlossMap；char copper/silver/gold BumpScale=.3819444/.2847222/.3680556、GlossMapScale=.7847222/.8090278/.75。
- RiteRender.c Init 0x59a9e0 / OnLanguageChanged 0x59bab0；dump.cs RiteRender 324578；RiteShows.asset；[RiteNew 真值表](RiteNew.md)。TitleBG 使用 Resources/image/main_new/event-tag 下对应纹理，不能用 Texture2D 中的同名金底图代替。

## 验证与边界

- [最终 GPU 桌面截图](desktop_pages_metal_rites.png)，1920×1080 Forward+。
- 新增 5 项回归：四页边界与存档、按钮切页与模态禁用、跨页隔离下排序、金属偏移与暂停、仪式条几何及点击。
- GPU 反光检查：80,209 个可见像素，改变偏移后 33,137 个像素变色，透明度变化 0。工具：`tools/verify_card_metal.gd`。
- 事件睡眠回归由固定等待 0.1 秒改为等待结局信号（2 秒超时），避免首次桌面资源初始化导致提前断言。保留原来的信号次数、结局原因和队列清空断言。
- 全量 GUT 最终复验 469/469、3443 断言通过，186.317 秒；输出无 SCRIPT ERROR/ERROR、orphan 或资源泄漏诊断。日志 `desktop-full-final.log` / `desktop-full-final.stdout.log`。
- 原作同刻存档桥 50/50，通过新增 current_bag_index 对拍；21 张本轮纹理 SHA256 与对应原素材相同。content 未改动。
- [1280×720 截图](desktop_pages_metal_rites_720.png)也已走查，数字和标题条无尺寸撑破。

未宣称完整背包系统：HandBagPanel 总览、手动跨页搬运、自动分类、页计数和提示仍未接；新普通卡的分配仍沿已有行为。bagpos=0 的存储分区未从手牌页分离。

反射为明确的 Godot 渲染近似：导出的 cardshow.shader 是 DummyShaderTextExporter，没有原 fragment；当前保留可验证的输入和位置驱动，未恢复 Unity 的环境反射、DetailAlbedo、完整光照模型。仪式标题 PreferredSize 使用 Godot 字体度量，特殊类型 native size、位移及额外状态装饰仍待后续；尚无原作同帧像素对拍。
