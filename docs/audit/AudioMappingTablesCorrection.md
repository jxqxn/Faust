# A21 续：三张音频映射表全部是配置，不是"未导出的 .cs"（第三十五批）

上一批（第三十四批）从 `sfx_config.json` 定案了音乐族的 clip 名，并在文末留了一条线索：

> 其余 ~391 个角色配音/环境 clip：本批证明了**提示名来自 `sfx_config.json` 这类配置而不是编辑器字段**（至少对音乐族如此），所以"文件名→调用点在未导出 .cs 里"这条留档需要按同一思路重查——很可能也有一张配置表，只是还没找到。

本批把这条线索查完：**有三张表，全都在语料里。**

## 1. `sfx_npc_role_dub.json` —— 角色配音表

```json
{ "2000006": ["mg001","mg002","mg003"], "2000029": ["item_coin"], "2000001": [] }
```

- 键 = **卡片 id**（`CardNode.id` 域）。判定依据：`2000029`（金币卡）→ `["item_coin"]`——唯一"台词"就是金币音效，这个条目把键域钉死在卡片 id，而不是人物 id。
- 值 = **有序 clip 名数组**。顺序有意义（同一句的多个变体按序取用）。
- 规模：**584 个卡片条目，579 个非空，670 条引用，去重 123 个 clip**。
- **123 / 123 全部存在于语料 `Assets/AudioClip/`——零缺失。**

审计原文说"~391 个角色配音/环境 clip 的文件名→调用点映射在未导出的 .cs 里，无法逐条对拍"。实际是 **123** 个（441/391 那个数还包括环境音，本表不含），而且映射**完全在配置里**，可以逐条对拍。

## 2. `sfx_settle_card_new.json` —— 结算卡音效表

```json
{ "0": "settle_card_new_nomal", "1": "settle_card_new_great",
  "2000083": "settle_card_new_bad", ... }
```

只有 9 个键，但形状是关键的：**`"0"` 是默认项**，其余 8 个（`2000083`/`2000168`/`2000326`/`2000558`/`2000672`/`2000680`/`2000698`）是"坏结果"覆盖。所以查表语义是 **具体命中优先、否则落 `"0"`**，而不是未命中即静音。三种值：`nomal` / `great` / `bad`（原作拼写就是 `nomal`，不改）。

## 3. `over_music_config.json` —— 结局音乐表

150 个条目，表项形状与 `sfx_config.json` 的循环表**完全一致**：`{clip, start, loop_start, loop_end}`。

- 149 个键是**结局 id**（1..604，稀疏）。判定依据：这 149 个键**全部**能在 `content/over.json` 的 159 个属性键里找到，**零缺失**。
- 第 150 个键是 **`-1`**，clip 与结局 1..7 相同（`over_game_dead`）——它是**兜底项**，不是结局。克隆的 `over_music_entry` 起初带 `over_id <= 0` 的门，正好把这项挡掉了，已修。
- 反向不全覆盖：`over.json` 里有 **10 个结局没有自己的音乐条目**（`0, 15, 40, 204, 273, 274, 289, 290, 291, 999`），已用测试钉住这个集合。

顺带澄清 `over.json` 的形状：它是**顶层对象**（159 个属性键 = 结局 id），不是数组，**节点里没有 `id` 字段**。`ui/game_over.gd` 也是按属性键查的。此前一度把它当数组解析，被测试当场打回。

## 落地

1. **配置**（全部逐字节拷入，SHA-256 相等）：`content/sfx_npc_role_dub.json`、`content/sfx_settle_card_new.json`、`content/over_music_config.json`。parity **3886 → 3889 文件 / 0 违规**。
2. **`data/db.gd`**：新增 `npc_role_dub` / `settle_card_new` / `over_music` 三个字段与对应的 `_load_single`。
3. **`ui/audio_manager.gd`**：新增
   - `npc_dub_files(config, card_id)` / `npc_dub_file(config, card_id, index)`（索引**钳制**而非报错，与表的有序语义一致）、
   - `settle_card_cue(config, card_id)`（具体优先 → `"0"` 兜底）、
   - `over_music_entry(config, over_id)` / `over_music_clip(config, over_id)`（允许 `-1`）、
   - `_cue_file()` 统一补 `.ogg`，`armageddon_clip_for` 也改用它。
4. **音频资产**：三张表引用的 133 个 clip 里 **132 个从未进过克隆**，已全部从语料 `Assets/AudioClip/` 逐字节拷入（42.0 MB）。克隆音频目录 **35 → 167 个 ogg**；**167/167 与语料 SHA-256 相等**；表引用的 clip **语料缺失数 = 0**。
5. **`GameAudio.CUE_CLIPS`**：由手写 35 项改为**登记全部 167 个 clip**，使"盘上有、cue 面看不见"成为可断言失败。
6. **`tests/test_audio_cues.gd`**：10 → **18 测试**。新增覆盖三张表的加载与形状、键域判定、顺序与索引钳制、空/未知/`null` 三种查询路径、**每个引用 clip 必须 `ResourceLoader.exists` 且必须在 `CUE_CLIPS` 里**、`over_music` 键与 `over.json` 的双向覆盖（含 10 个无音乐结局的确切集合与 `-1` 兜底等价性）。

## 验证

- `tools/check_content_parity.ps1`：**3889 文件 / 0 违规**。
- 克隆音频 167 个文件与语料 **SHA-256 167/167 相等**。
- `tests/test_audio_cues.gd` **18/18**。
- 全量 GUT 见 `ApproximationAudit.md` A21 行。

> 流程点（与上一批相同）：新拷入的 `.ogg` 必须先 `--headless --import` 生成 `.import` 才能在 `ResourceLoader.exists` 里可见；`--import` 后 167/167 都有 sidecar。

## 仍开放

- **播放宿主**：三张表现在都可查，但 clone 尚无"何时播"的写点——`is_armageddon` / `armageddon_rite_id` 仍只有初始化与存档恢复两处写点；角色配音的触发时机（哪张卡、第几句、重复几次）在未导出的控制器里。**表 ≠ 时机**，本批只做实前者，不编造后者。
- `main_game_loop_difficulty` / `settle_loop_difficulty` 两张难度表仍无消费方。
- 语料 `Assets/AudioClip/` 共 **207** 个 ogg，克隆现有 **167**；剩余 40 个（约 21 MB）尚未被任何已集成配置引用，属环境音/其他族，未搬。
