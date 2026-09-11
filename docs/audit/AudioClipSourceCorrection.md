# A21 音频：`sfx_config.json` 就是 clip 名的来源（第三十四批）

A21 行里有一句写错的事实判断：

> **仍未接**：`LoopArmageddonController`（clip 名来自编辑器字段、语料无该字符串、无法推导，`Start 0x403e80` 在空名时直接 LogError）

**"语料无该字符串、无法推导"是错的。** clip 名与循环点都在 `data/config/sfx_config.json` 里，而这份文件一直躺在语料里。本批把它接上。

## 原作事实

### 1. 查找链：rite 配置 id → `armageddon_music_loop` 表项

`LoopArmageddonController.GetLoopData 0x4033f0` 与 `PlayArmageddon 0x403520` 走同一条链：

```
Datapool+0x68 → +0x60 → +0xB0 → +0x38        # 音频配置表
  Animator.GetInteger(animator, <param>)      # → 写回 controller+0x48
  FUN_180fc2200(表, key = controller+0x48, ...)  # 取表项
```

`PlayArmageddon` 里还有一处直接给出语义：clip 名为空时

```c
uVar8 = System_String__Format(DAT_1825bdb98, controller+0x40 /* clip 名 */, boxed(controller+0x48) /* id */);
UnityEngine_Debug__LogError(uVar8, 0);
```

即 `+0x40` 是 **clip 名**、`+0x48` 是**表键（配置 id）**——报错文案把两者一起打出来。`Start 0x403e80` 在 `IsNullOrEmpty(clip)` 时 LogError，与审计记的一致。

`GetClip 0x403240` 再把名字解析成 `AudioClip`：先 `Datapool.LoadModAudioClip(name)`（MOD 音频），为空则退回内建 `AudioClip[]` 数组按名查找。

### 2. 表就是 `sfx_config.json`

顶层 5 张表：`main_game_loop`、`main_game_loop_difficulty`、`settle_loop`、`settle_loop_difficulty`、`armageddon_music_loop`。每项形如：

```json
"5003027": { "clip": "secret_journey", "start": 0, "loop_start": 0, "loop_end": -1 }
```

`armageddon_music_loop` 共 **22 个 rite id**（5003027 … 5010201），用到的 clip 恰好 10 个：`secret_journey` / `dragon_slayer` / `final_battle_facing_sultan` / `the_last_sultan_card` / `seeds_of_history` / `battle_1..4` / `void_flight`。可选旗标 `play_in_rite_create`（5 处）与 `play_instant`（2 处）。`loop_end: -1` 表示"放到结尾"。

`Update 0x404110` 用 `loop_start`（`+0x34`）与 `lifeCount`（`+0x38`）做循环回卷：`AudioSource.time >= +0x38` 时 `AudioSource.time = +0x34`。

## 克隆缺口

`LoopArmageddonController`（0x403e80 / 0x404110 / 0x403f70 / 0x403520 / 0x403d90）**整个未接**。但依赖面比想象的小：

- `GameState.is_armageddon` / `armageddon_rite_id` 已经存在并在 v? 存读档与导入桥里映射（`original_save_schema.gd` 还写了"当前 armageddon_music_loop 仪式配置 id"）；
- 但全仓 `is_armageddon = ` / `armageddon_rite_id = ` 只有**初始化与存档恢复**两处写点，**没有运行时赋值**——也就是说这两个字段现在只随存读档往返，还没有驱动它的规则链（`GameController` 的 armageddon 分支不在本批范围内）。
- 语料 `save_samples/auto_save.json` 里 `is_armageddon=false`、`armageddon_rite_id=0`。

所以本批**不做播放宿主**（没有写点就没有可信的触发时机，硬接一个自制触发点违反三支柱第 3 条），只把**数据与查找**做实。

## 落地

1. **`content/sfx_config.json`**：从语料逐字节拷入（SHA-256 相等，7014 字节）。parity 由 3885 → **3886 文件 / 0 违规**。
2. **`data/db.gd`**：新增 `sfx_config` 字段 + `_load_single(content_dir + "/sfx_config.json", sfx_config)`。
3. **`ui/audio_manager.gd`**：新增 `ARMAGEDDON_TABLE_KEY`、`armageddon_rite_ids(config)`、`armageddon_loop_for(config, rite_id)`、`armageddon_clip_for(config, rite_id)`（自动补 `.ogg`）、`_armageddon_table(config)`。`rite_id <= 0`、查不到、`config == null` 三种情况都返回空——对应原作的"clip 名为空 → LogError"路径。
4. **音频资产**：`armageddon_music_loop` 用到的 10 个 clip 里有 7 个从未进过克隆（只有 `main_game_level1..3` 在）。已从语料 `Assets/AudioClip/` 逐个 SHA-256 等值拷入 `assets/original/audio/`，并把 13 个名字全部登记进 `GameAudio.CUE_CLIPS`。
5. **`tests/test_audio_cues.gd`**：4 → **10 测试**。新增：`sfx_config` 被真正加载（且必须有 `armageddon_music_loop`）；表恰好 22 项且 `secret_journey` / `play_instant` 两种形态都对；未知 rite / id 0 / config null 三种查询返回空；**22 项的每个 clip 都必须能在项目里 `ResourceLoader.exists`**（这条会把"配置写了但资产没搬"钉死）；每个 clip 都必须在 `CUE_CLIPS` 里（防止"盘上有、cue 面看不见"）；`main_game_loop` 的 clip 同样存在（防止文件被半集成）。

## 验证

- 新增的 10 个 `.ogg` 与语料 SHA-256 **10/10 相等**。
- `tools/check_content_parity.ps1`：**3886 文件 / 0 违规**。
- `tests/test_audio_cues.gd` **10/10**。
- 全量 GUT 见 `ApproximationAudit.md` A21 行。

> 过程中踩到一个流程点：新拷入的 `.ogg` 在 `ResourceLoader.exists` 里看不到，因为 Godot 还没导入。跑一次 `--headless --import` 生成 `.import` 后即通过。**不能**手写 `.import`——它由导入器生成。

## 仍开放

- **`LoopArmageddonController` 的播放宿主**：需要先有 `is_armageddon` 的运行时写点（原作的 armageddon 分支不在反编译子集里，或至少未定位），否则触发时机是自制的。本批只保证"一旦有写点，clip 名与循环点立刻可查"。
- `main_game_loop_difficulty` / `settle_loop_difficulty` 两张难度表的消费方（`GetCurrentMusicLevel` / `GetSettleMusicLevel`）未接。
- `MusicFadeOutController.FadeOutMusic` 的淡出曲线仍未复核。
- 其余 ~391 个角色配音/环境 clip：本批证明了**提示名来自 `sfx_config.json` 这类配置而不是编辑器字段**（至少对音乐族如此），所以"文件名→调用点在未导出 .cs 里"这条留档需要按同一思路重查——很可能也有一张配置表，只是还没找到。
