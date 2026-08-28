# StoryNotify 原作真值表

## 结论

任务完成通知是 `StoryNotifyController`，与右侧 `CachedEvents` 托盘不是同一表面。当前实现按原作 Global 任务链产生通知，不接受克隆侧手写提示内容。

## 调用链

`ModifyGlobalCounter.Do 0x5176a0`
→ `GlobalExtensions.RefreshQuest(send_notify=true, init=false) 0x4fcee0`
→ `Global.OnQuestCompleted`
→ `StoryNotifyController.Show 0x5b9c00`

启动时 `StartController` 调 `RefreshQuest(false, true)`，只恢复任务状态，不重播历史通知。已有动画播放时，`Show` 把 `QuestNode` 放进 FIFO；`OnAnimationDone 0x5b99c0` 取下一项。

## RectTransform（3840×2160 设计空间）

| 节点 | Godot 左上角坐标 | 尺寸 | 内容 |
| --- | ---: | ---: | --- |
| StoryNotify | 顶部水平居中 | 630×444 | 根点击面 |
| Title | (15, 73) | 600×50 | `QuestNode.name`，字号 60 |
| Icon | (193.5, 207) | 103×110 | 原作 `point_0` |
| PointCount | (316.5, 237) | 100×50 | `+{upgrade_point}`，字号 50 |

背景直接使用语料 `prompt.png`；图标直接使用语料 `point_0.png`。

## 动画

`StoryNotify.anim` 的 Unity anchored Y 为 `0 → -444 → -444 → 0`，关键时间为 `0 / 0.33333334 / 5.3333335 / 5.6666665`，切线为零。换算到 Godot y 向下坐标即根节点顶部 `-444 → 0 → 0 → -444`。

## 证据边界

- `.c`：`StoryNotifyController.c`、`GlobalExtensions.c`、`ModifyGlobalCounter.c`、`StartController.c`。
- `dump.cs`：`Global`、`QuestNode`、`StoryNotifyController` 字段与 RVA。
- 产物：`quest.json`、`StoryNotify.prefab`、`StoryNotify.anim`、`prompt.png`、`point_0.png`。
- `save_samples/global.json` 是默认态稀疏样本，没有非默认 `quest/counter` 字段，因此不能声称任务持久态已由真实非默认存档逐字段对拍。
- 🟡 点击后的 `StoryController.Target → GameController.ShowStory` 完整任务面板与领取奖励链仍待下一批迁移；当前只发出结构对应的任务 id 请求，不虚构面板。

视觉走查：[`storynotify_screenshot.png`](storynotify_screenshot.png)。
