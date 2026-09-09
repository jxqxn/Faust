# 显示模式与分辨率接线（2026-09-06）

2026-09-07 纠偏：无偏好时默认 **1920×1080 窗口**，不调用物理模式切换；显式 `--windowed` / `-w` / `--embedded` 优先于已存全屏偏好。设置页仍可主动选择全屏，并保存模式与分辨率。3840×2160仅为UI设计画布。

用户指出原作窗口化不改变桌面。上一版从原常量 ExclusiveFullScreen 推导并强制启动独占全屏，混淆了默认值与用户明确请求的窗口模式。此处按用户要求修正宿主启动政策，不再称强制独占启动是已经过原作实测的结论。

实机检查 `tools/verify_display_settings.gd -- --windowed-start`：正式 main 初始化前后 Windows 模式均2560×1440，Godot Window=1920×1080、mode=0。普通启动与带 `--windowed` 启动均验。专项测试还覆盖旧全屏偏好被显式窗口启动覆盖，均不调用原生 apply。

## 原作依据

| 原作 | 已实现 |
| --- | --- |
| `GameApplication.<DoInit>d__43.MoveNext`0x4520e0，L883–984；`dump.cs:542497-542500` 默认ExclusiveFullScreen/1920x1080，PlayerPrefs键GameFullScreen/GameResolution | `GameApplicationSettings.initialize_display` 从应用偏好恢复，正式main场景启动调用；测试内嵌Game节点不改桌面 |
| `SetFullScreen`0x43eea0 / `SetResolution`0x43f700：保持另一字段、调用Screen.SetResolution、写PlayerPrefs | 两个setter组合应用模式/尺寸后写已有application_settings.json；失败不保存、不把下拉框停在未成功的值上；玩家存档无新增字段 |
| `SettingDropDownController.InitResolutionDropDown`0x5aa0b0，闭包0x5b2af0/0x5b2b60：系统模式按宽高降序，转WxH并去重 | Windows系统枚举真实支持模式；刷新率重复项合并，没有手写分辨率表 |
| `content/variable.json.support_fullScreen`、`content/ui.json.SCREEN_MODE_0/1`；OnChangeScreenModeClicked0x5aab30/OnChangeResolutionClicked0x5aaab0 | 设置页两个真实OptionButton，模式值与文案直接读取原配置 |
| `SettingsPanel.prefab:24843-24867`：KeyMap底锚、pos(487,284)、size(405,174)、pivot(.5,.5)，父高1200 | KeyMap从错误y229改为829，解除对显示模式下拉框的遮挡 |

## Windows平台承载

`platform/windows/DisplayHost.cs` 承载Godot缺失的Unity Screen接口：根据游戏窗口所在显示器调用EnumDisplaySettingsEx、ChangeDisplaySettingsEx，先CDS_TEST验证，再CDS_FULLSCREEN临时切换。不写系统注册表显示偏好。

首次使用由已安装的Windows .NET Framework编译器在Godot用户缓存中生成小型exe，不下载依赖、不向仓库加入二进制。`display_adapter.gd` 单独创建隐藏的恢复服务，再通过短命请求进程与命名管道通信，防止继承捕获管道导致启动等待。服务保存原桌面模式，切回窗口时恢复；正常退出或游戏进程被终止时恢复并结束。返回值和实际尺寸均检查，不把Godot窗口大小当成物理显示模式的唯一证据。

当前验收平台为Windows、本机单显示器。其他平台适配和原作语言/字体选项不在本批范围；设置页整体美术也不据此宣称1:1。

## 验收结果

- 图形后端实际启动：Windows报告1920×1080，Godot窗口1920×1080，mode4，画布3840×2160。
- 2026-09-07补验全屏内分辨率切换：1920×1080→2560×1440→1920×1080，两个方向的Windows实际模式与Godot窗口尺寸均一致，mode始终4；日志 `faust-display-fullscreen-switch.log`，退出码0。
- 设置页选择Windowed与1280×720：窗口1280×720、mode0；物理桌面回到原来的2560×1440。
- 独立新进程加载测试偏好：仍为Windowed/1280×720，窗口实际尺寸一致。测试使用隔离偏好文件，没有覆盖用户的application_settings.json。
- 在1920×1080全屏状态强制结束验证进程：恢复服务将桌面恢复2560×1440，并退出；未终止用户的其他进程。
- 专项GUT：5/5、36断言；既有UI组75/75、877断言。日志无SCRIPT ERROR、引擎ERROR、孤儿节点或资源泄漏。git diff --check通过。
- 日志：系统临时目录 `faust-display-ui-write.log`、`faust-display-restart.log`、`faust-display-crash.log`、`faust-display-tests.log`、`faust-display-ui-tests.log`。早期接线测试曾暴露继承stdout造成等待，已改为独立创建服务；最终跨进程测试退出码均0。

![已接通的显示设置](ui_layout/display_settings_connected.png)

图形复验（会临时切换显示模式；Windows，需在仓库根执行）：

```powershell
& 'C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64_console.exe' --path . --rendering-method gl_compatibility --script tools/verify_display_settings.gd -- --write
& 'C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64_console.exe' --path . --rendering-method gl_compatibility --script tools/verify_display_settings.gd -- --read
```

`--hold`用于异常退出恢复探测，输出本次验证PID，在60秒后自动结束。只应终止日志中标识的验证进程。该工具以隔离文件验证应用偏好，普通游戏启动继续使用原有应用设置路径。
