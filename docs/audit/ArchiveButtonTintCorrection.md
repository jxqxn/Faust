# 档案按钮状态色纠偏（2026-09-10）

A09 第九批。移除已核实档案按钮继承的自制 RGB1.15 悬停效果；未把同工厂所有调用统一视为同一Prefab。

## 来源与差异

直接核对 `Resources/prefab/UserArchive.prefab`、`UserArchiveItem.prefab`、`UserArchiveNameInput.prefab` 的 Selectable：

| 按钮 | Transition / Navigation | Disabled | TargetGraphic |
| --- | --- | --- | --- |
| UserArchive Close | ColorTint / None | RGB .78431374, A .5019608 | 114043919389829319（背景，非X） |
| Item ModifyName | ColorTint / None | 同上 | 114499726237547504 |
| Item Load | ColorTint / None | 同上 | 114232094423628703 |
| Item Delete | ColorTint / None | 同上 | 114887312969816373 |
| NameInput Confirm | ColorTint / Explicit | RGB .39215687, A 1 | 114611579644537198 |
| NameInput Cancel | ColorTint / None | RGB .78431374, A .5019608 | 114271925019662038 |

上述按钮Normal为白色，Highlighted/Selected为RGB .9607843，Pressed为RGB .78431374，ColorMultiplier=1，FadeDuration=.1。NameInput Confirm数据位于prefab约2851–2881，Cancel约3773–3803。

`decompiled/UserArchiveNameInputController.c @ Show 0x5cb0f0`及文本变化链写Selectable.interactable，没有克隆的整颗按钮alpha=.4操作。禁用状态应由指定图形的ColorBlock承担。

## 实现

共用 source_confirm_tint 增加可配置 disabled_color；只对上述已核实按钮启用，Close背景与X分开着色。名称Confirm保留可获得焦点，其显式导航图未完整迁移，不能宣称手柄等价。删除_name_confirm.modulate.a自制透明度。

## 验证与剩余

- archive_flow 3测试/19断言通过，含原作save_slot/user_archive样本摘要。
- 1280×720和1920×1080的完整GPU操作脚本通过：保存、覆盖取消、改名入口、删除取消/确认、读取取消/确认。
- 脚本实际Backspace清空名称，等待.15秒后检查按钮disabled、图形不透明深灰、根modulate保持白色，再实际键入恢复流程。也修正脚本遗漏的 `await type_text`。
- 日志 `approximation-archive-tint*.log` 无引擎错误/泄漏报告；diff检查通过。
- 行内删除确认仍使用待核实工厂路径，输入框/滚动条的状态着色、Explicit导航图尚未完成，A09继续开放。截图和GPU检查来自克隆，不代表原机同帧像素验收。

## 第十批：行内确认补核并修正

直接读取UserArchiveItem.prefab组件114012617856089587（Confirm）与114228214996573471（Close）：两者均为标准ColorTint、Navigation None、fade .1，目标分别为114321827775029018/114041320612064254。此前用于导航的114703247130969877/114641204913154593实为ActionBinder，其Button字段才指向Selectable；不能根据组件所在对象或相同fileID在另一个Prefab的含义推断类型。

Confirm的UnityEvent调用ButtonDelegater.OnSubmit及UserArchiveItemController.OnDelete 0x5c9760。Close隐藏DeleteConfirm、恢复hold_for_delete与holder_for_delete；后两者为未迁移的手柄提示树，不能据此误隐藏Delete图标。

现行内两按钮均启用源ColorTint，共用工厂删除RGB1.15悬停分支。archive_flow 3/19通过，1280/1920完整GUI流程通过，并实际移动指针到行内取消按钮、等待过渡完成后验证RGB .9607843；取消与确认删除行为仍通过。日志 `approximation-inline-delete-*`。输入框/滚动条及显式导航/手柄提示树仍未完成；上面的第九批“行内待核”由本段取代。
