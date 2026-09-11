# 悬停提示修正与验收（2026-09-11）

## 已确认与已修正

本轮接手的是未完成且存在编译缺口的Tips实现。直接复查.c、dump.cs、prefab与DLL常量，
发现旧文档给出的多项“真值”有误；详见 [更新后的真值表](../ui_layout/SourceTips.md)。

- PE地址映射修正：3840分母、0.8阈值、50/150夹取余量与三个世界偏移均可直接读取。
- 根pivot的上下方向、Right锚点、Left运行时启用及镜像、动态高度和边框切片已纠正。
- 移除未定义CANVAS_WIDTH_REFERENCE，统一窗口、viewport、面板局部坐标。
- 翻译优先级与unknown-key echo按GetTipText→Translate直接返回链修正。
- hover绑定目标；重复绑定、退出、隐藏、销毁均处理；逐帧跟随。
- 手柄/动态委托/卡槽提示未宣称完成。
- 输入验证发现手牌全宽矩形拦截背包及俺寻思：背包按视觉顺序排列；手牌命中排除原作
  IThink目标区域，保留其原有投放处理。移除该目标残留的自制tooltip_text。
- 截图不再强行调用show_for，必须经过viewport mouse motion命中目标。

## 本批验证

- `tests/test_source_tips.gd`：8测试、132断言通过，含两分辨率真实viewport输入路径。
- 截图：`docs/ui_layout/sourcetips_screenshot.png`，1920×1080完整游戏启动，整理按钮hover。
- 本轮没有启动原作对拍，不将克隆截图视为原作像素级一致的证明。
- 全量GUT结果在收尾后补录；存在历史失败时如实列出，不以局部绿灯替代全量验收。

## 保留的限制

字体仍由Godot而非TMP排版；正交平面投影之外的相机情况未验收；动态委托、仪式静态
holder、手柄延时、手机版及第二种卡槽提示按METHOD_MAP保留未完成状态。
