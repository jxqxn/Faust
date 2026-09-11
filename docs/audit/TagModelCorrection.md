# 卡牌标签模型：配置基准与运行时增量（第十九批，2026-09-10）

> 2026-09-11更正：本文关于“装备任一标签can_inherit就继承整行”及“忽略装备count”的旧结论已被原作GetTag/GetTags直接证据推翻。现按所查询标签逐项判门，递归值仍乘装备count，见[本次复核](StartupCardPopulation.md)。其他历史验收数字不代表这些错误语义正确。

起于第十八批末登记的"待核查候选"：原存档 tag 用英文 code，克隆运行时用中文名称，且不确定存档存的是整行还是增量。本批回到 `CardExtensions.GetTag` 方法体，再用存档实例与配置算术独立验证，不再沿用"克隆 instance.tags 就是整行"的旧假设。

## 原作事实

- **卡牌有两个 tag 字典**：`Card.data`（CardNode@0x68）的 tag 在 `+0x58`，`Card` 自身的 tag 在 `+0x30`。dump.cs:389759 起 CardNode 字段表与 389593 起 Card 字段表各自独立列出这两个 `Dictionary<string,int>`。
- **GetTag 0x3814a0 是加法**：先读 `Card.data+0x58`（缺失记 0），再读 `Card+0x30`（缺失记 0），相加得 `iVar8`（源码 1585-1601）。
- **装备项**：若 `Common.GetTagNode(tag)` 的 `+0x42`（can_inherit）为真，则遍历 `Card+0x40`（List&lt;Card&gt; equips），对每个装备递归 `GetTag(equip, tag, raw=true)` 并累加（1603-1618）。门控是**该标签能否继承**，但一旦通过就累加装备的**整行**，不是逐标签过滤；`raw=true` 也让装备项跳过下面的非正掩码。
- **非正掩码**：非 raw 且总和 &lt;1 时，只有当 `TagNode+0x43`（can_nagative_and_zero）为假才返回 0（1619-1622）。
- **最后乘 count**：`return iVar8 * *(int *)(Card+0x20)`（1623）。装备的 count 不参与。
- **GetTags 0x381940 是并集**：HashSet 先并入 `Card.data+0x58` 的键，再并入 `Card+0x30` 的键，最后 `UnionWith(GetTags(equip).Where(inheritable))`。它只收集键，不带值，也不乘 count。
- **AddTag 0x37e6a0 只写运行时字典**：非复合标签分支读 `Card+0x30`，写 `Card+0x30`；配置字典 `Card.data+0x58` 只作为"是否已存在"的门（`can_add` 为假且配置里已有该标签时不写）。**配置字典从不被写**。
- **存档证实是增量**：`save_samples/auto_save.json` uid 29（id 2000001）的 `tag` 是 `{"social":1,"charm":1}`；`cards.json` 2000001 的配置行是 `体魄3 魅力2 智慧1 男性1 贵族1 主角1 战斗2 社交1 已拥有1 支持1`。故运行时该卡社交=2、魅力=3。全语料 4 个存档样本只用到 9 个 code，另有 `sudan_pool_index`、`adsorb_spec` 两个非 tag.json 的簿记键。
- tag.json 442 条，name 与 code 各自唯一，可双向映射；`CanAdd`/`can_inherit`/`can_nagative_and_zero` 是三条独立旗标（例：体魄 `1/1/1`，支持 `1/1/0`，已拥有 `0/0/0`，武器 `0/0/0`）。

## 克隆偏差

1. `original_save_importer._base_card_row` 把存档的英文 code 增量字典**原样**写进 `CardInstance.tags`。
2. `GameState.card_data_for` 曾对空 tags 做"惰性填配置行"，于是同一字段有时是整行（中文名）、有时是增量（英文 code）。
3. `effective_card_tags` 只把 `instance.tags` 复制后加一层装备，**既没有配置基准，也没有 ×count，键域还可能是 code**。装备贡献按标签逐个看 can_inherit，与 GetTag 的"整行"语义不符。
4. `operation_filter._matches`、`result.gd` 的 table/total 选择器、`condition.gd` 的状态标签判定都直接读 `instance.tags`，即把增量当整行。
5. `record_card_generation` 遍历 `instance.tags` 的键，增量域会漏掉配置基准键。

## 修复

- `data/db.gd`：新增 `tag_code_to_name`（tag_name_to_code 的反向表），供跨域解析。
- `sim/card_instance.gd`：`tags` 明确为**运行时增量**并加 SRC 注释；存档新增 `tags_are_delta: true` 标记，v9 起写出。
- `sim/game_state.gd`：
  - `effective_card_tags(uid, db)` = (配置行 + 增量 + 每个可继承装备的整行) → 非正掩码 → × count，键统一为配置名域。
  - 新增 `effective_card_tag_names(uid, db)` 实现 GetTags 的键并集（配置键 + 增量键 + 可继承装备的键）。
  - `card_data_for` 的 `tag` 与新增的 `tags` 都取有效行（修正 `condition.gd` 读 `tags` 一直取空的死分支）；`table_card_entries`/`surface_card_entries` 的 `tags` 同样取有效行。
  - `rebase_tag_delta`：把旧克隆存档里的"整行（配置名域）"减回增量；配置未登记的运行态标签（遗世/lost/adsorb_spec）原样保留。
  - `record_card_generation` 改走键并集。
- `sim/save_system.gd`：反序列化后对 `tags_are_delta=false` 的卡逐张 rebase。
- `sim/original_save_importer.gd`：导入行显式声明 `tags_are_delta=true`（原作存档本来就是增量）。
- `core/tag.gd`：`TagSystem.apply` 增加 `effective_value` 参数——`can_add=0` 的门读的是 GetTag 结果，而配置基准永远参与，只看增量会漏判。
- `sim/result.gd`：6 处标签写入点（裸键族、GenCard 的 tag_modify、槽位、table、total、苏丹池）全部改为"写增量、用有效行做门"；苏丹池的 `sudan_pool_tags` 明确为增量，选择器改用"配置行 + 增量"的有效行。
- `sim/operation_filter.gd`：`select_total` 的选择器判定改用有效行。

## 验证

- 新增 `tests/test_tag_model.gd`（12 测试 / 38 断言）：配置与存档的双键域、无增量时等于配置行、code 增量叠加（uid 29 社交 2/魅力 3）、×count、非正掩码（支持 vs 体魄）、装备整行与 can_inherit 门（2000006 通过、2000380 全阻断）、非装备区不参与、GetTags 键并集、`can_add` 门读有效行、v9 增量往返、旧版整行 rebase。
- **原存档对拍**：测试内用"存档 JSON + 配置"独立重算 185 张卡（含装备）的 GetTag 行与 clone 逐标签比较，零不一致。该期望值不调用克隆的 tag 辅助函数。
- 全量 GUT：46 脚本 / 566 测试 / 564 通过 / 4300 断言中 4298 通过（`tag-full4.log`），无 SCRIPT ERROR、无 orphan/泄漏报告。
- 修根因时顺带发现并修掉一个更早的克隆偏差：`create_card_instance` 把**配置整行**塞进运行时增量，在新求值下会让每个数值翻倍（正是"增量当整行"假设的另一面）。现在新卡从空增量开始。

### 两条剩余失败与一批的关系（基线对照）

本批用 `git stash` 在"同一工作区、去掉本批改动"的基线上复跑确认：

- `test_card_flash.gd` 的 `candidate layout keeps the scaled bottom on the rail`：基线 40 条断言失败，本批 1 条；差异属于其他会话未完成的卡面几何，与本批无关，尚未收口。
- `test_event_choice_controller.gd` 的 mask 高度 489 vs 828：基线与本批完全相同的一条失败，属其他会话未完成的 PromptNew 布局，与本批无关。

另有 `test_gold_card.gd` 原先直接断言 `instance.tags` 里的配置标签，已按新语义改为读有效行（5 枚金币堆叠 → 配置值 ×count = 5）。

## 未完成与新增审计线索

- **key 域未全局统一**：本批只保证"物化行"（card_data_for / entries / effective_card_tags）用配置名域，`instance.tags` 仍是原样增量。若某个调用方直接读 `instance.tags` 做条件判定，仍会拿到增量。建议后续把读点全部收口到有效行 API，或改成同名 code 域一次到底。
- **苏丹池仍是按配置 id 合并**（A17 P0）：池内同 id 不同运行态会互相覆盖，本批只保证池增量语义正确，未解决对象域。
- **`result.gd` 的 `copy.*`**：复制是否携带运行时标签仍未证实（源码注释保留）。
- **`AddTag` 的复合标签分支**（`TagNode.is_composite`）与 `ValidateTagAttributes` 未在本批展开。
- `GetTagWithDiff`（0x3811e0）唯一消费者是 `CardInfoNewController.Show`，本批未改卡牌详情的数值展示；详情页现在会显示"配置+增量"的整行，与原件一致，但差分高亮仍未接。
