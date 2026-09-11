# 音频提示面、向导宿主与卡面可达性（第二十八批，2026-09-10）

本批收口 A21 / A22 / A23 三项 P2，都是"先把可达性核清楚，再决定改什么"的类型。

## A21 音频缺口

### 已确认

- 语料导出 **414 个 AudioClip**；克隆携带 **25 个**。
- 克隆能播放的提示面共 **25 个 clip 名**（23 个 SFX + 4 个 BGM，去重后 25），逐个核对：
  - **23/23 个 SFX 在语料 AudioClip 目录里都存在**；
  - **25/25 在克隆 `assets/original/audio/` 里都存在**。
- 之前的排查里出现过 `3.ogg`，那是从版本号字符串误抓的，不是 cue。
- 音频提示名**不来自内容配置**：全量扫描 `data/config` 里 `sfx/sound/audio/bgm` 字符串只有 **1 处**（一张卡的 `sfx: "cat"`）。也就是说音频路由靠 Unity 编辑器里挂的 AudioClip 引用与 `SFXManager` 的运行时查表，**不是**可从配置推出来的表。
- BGM 方面语料有 `main_game_level1/2/3.ogg`，克隆三首都在。

### 处置

- `ui/audio_manager.gd` 新增 **`CUE_CLIPS` 清单 + `all_clip_names()`**：把"能播的 clip 面"变成可断言的注册表。
- 新增 `tests/test_audio_cues.gd`（4 测试 / 43 断言）：每个 cue 资产必须存在；BGM 与四族苏丹抽卡 cue 都在注册表内；四个苏丹族映射到**互不相同**的 clip；未知 cue 静默降级（`_load_stream` 返回 null、播放池不变）。

### 仍未接（登记，不冒充）

- `LoopArmageddonController`（`PlayArmageddon 0x403520` / `GetClip 0x403240` / `GetLoopData 0x4033f0`）**未接**。它的 clip 名来自编辑器赋值的字段，`Start 0x403e80` 在该字段为空时直接 `Debug.LogError`；导出包里既没有该名字字符串也没有可搬运的编辑器引用，因此**无法从语料推导**，不猜。
- 剩余 ~391 个 clip（`alm001`/`adl001` 一类角色配音与环境层）走 `SFxManager.PlaySFx` / `PlayCharacterDub` / `SFxPlayCharacterDub`，其**文件名→调用点映射在 C# 源码里，而语料未导出 .cs**，故本批无法逐条对拍，登记为开放项。
- **视觉抖动与音频缺口分别登记**（沿用审计口径）：抖动侧属 A06 已修范围。

## A22 向导宿主 / credits / after_story

### 已确认（原登记已过期）

- **credits 与 after_story 不是空实现**：克隆有 `credits_controller.gd` + 三个子页（developer/contributor/thanks）与 `game_over.gd` 的 `SHOW_AFTER_STORY` 阶段链，`story_controller.show_after_story()` 已接。
- `credits_page.gd` 里的两个 `pass`（`previous()` / `next()`）是**基类默认**：基类 `has_previous()` / `has_next()` 恒返回 false，而两个子类都**重写**了 has/动作两对方法；控制器仅在 `has_*()` 为真时调用动作。所以它们**不可达**，不是缺口。
- **`magic_sudan` 的宿主配置一直都存在**：`data/config/wizard/wizard.json`（id `WIZARD`）与 `wizard_sudan.json`（id `WIZARD_SUDAN`），字段含 `prompt_draw_sudan_start{,_first}`、`prompt_draw_sudan_end_with{out}_times`、`name`、`text`、`options`。克隆**从未加载**过这两个文件。

### 原作事实

- `MagicSudan.ctor 0x5153f0` 调 `Datapool.AddMagicSudan` 把指令登记进 Datapool；`PreDo` 直接抛异常（不可预处理）；`Do 0x515160` 做日志与校验。
- `WizardController.LoadWizard 0x5cbdf0` 从 `Datapool+0x40`（按 id 索引的向导字典）取节点，再读 `WizardNode+0x20` 等字段配置文案。
- 配置里 **3 个事件**（`5300067` / `5300068` / `5310104`）调用 `magic_sudan`，可见该指令是可达的。

### 修复

- `ConfigDB` 新增 **`wizard_config`** 并加载 `content/wizard/`。
- 新增 **`_load_dir_by_string_id()`**：原 `_load_dir` 用 `int(id)` 建键，两个向导 id 都是字符串，会被压成同一个 0 并互相覆盖（只留最后一个）。按字符串 id 索引后两个节点都在。
- 按复刻工作法第 1 条（数据零转译）把 `wizard.json` / `wizard_sudan.json` **逐字节拷贝**进 `content/wizard/`；`tools/check_content_parity.ps1` 报 **3885 文件、0 违规**。
- 新增 `tests/test_wizard_host.gd`（3 测试 / 21 断言）：两个向导节点按字符串 id 加载；四个 prompt 键都存在（注意 `WIZARD_SUDAN.prompt_draw_sudan_end_without_times` 在原作里**就是空的**，不去"修"内容）；`magic_sudan` 至少被一个配置事件调用。
- `magic_sudan` 仍为**审计过的 no-op**（无向导渲染宿主），但注释更新为"宿主配置已加载、演示层未接"，下一步不再是"没有数据"。

## A23 卡面 fallback 可达性

### 已确认

- `cards.json` **1292 张卡全部带 `resource`**，`type` 只有三种（char 317 / item 955 / sudan 20）。
- 但**110 张卡的 resource 在 `assets/original/cards/` 下没有对应文件**（如 `2000002`、`1_item_12`），即"原作数据本身无立绘"，与既有登记一致。
- 这 110 张走 `card_type_{char,item,sudan}.png` 类型图标兜底，三个图标在克隆里都存在。
- 6 张稀有度边框（`card.png` / `card_0..card_4.png`）全部存在，且 `_style_for_card()` 的门是"**有原图或有稀有边框**就返回透明样式"——由于边框恒可解析，**纸面样式分支对任何配置卡都不可达**。

### 处置

- 该分支保留为**防御性守卫**（若将来某个边框/原图资产缺失，仍能画出可读卡面），但把上面的结论**钉进测试**，避免它悄悄变成活路径。
- 新增 `tests/test_card_face_reachability.gd`（5 测试 / 18 断言）：6 张边框与 3 张类型图标必须存在；逐张遍历 1292 张卡，确认每张"有原图或有边框"；三种 type 都被图标覆盖；有原图与无原图的卡**都**得到透明样式，并断言无原图卡的 `_rarity_frame_texture()` 非空。

## 验证

- 全量 GUT：**52 脚本 / 603 测试 / 601 通过 / 4502 断言中 4500 通过**（`r5-full2.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。两条失败仍是既有的 `test_card_flash` 与 `test_event_choice_controller`。
- `tools/check_content_parity.ps1`：3885 文件、0 违规（含新增的 2 个 wizard 文件）。
