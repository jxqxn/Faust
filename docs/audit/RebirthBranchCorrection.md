# A20 复核：`rebirth.s<n>` 的两分支与 冻结 门（第三十一批）

`ApproximationAudit.md` 的 A20 行原文只说 "`rebirth.s<n>` 分支仍未按源复核"，克隆注释则把第二分支写成"不可恢复的 immortal 标签、且无配置命中"。本批把两件事都查实了：**标签可恢复**（是 `冻结`/`freeze`），**配置确实命中**（8 处写点全在苏丹卡槽上），而且克隆的实现**是错的**。

## 原作事实

### 1. `Do` 只是调度，真正的写点在共享委托里

`RebirthSudanCard.Do 0x519d60` 的流程（`RebirthSudanCard.c`）：

1. 从 `<RebirthSudanCard.<>c>` 的静态字段（`DAT_18259b2f0` 的 `+0xb8`）取/建一个缓存委托——就是 `<Do>b__4_0`；
2. `OperationFilter.Filter(this.filter@+0x20, context+0x20, context+0x14, 该委托)` —— 对**上下文筛出的每张卡**调用它；
3. 然后 `GameController.UpdateSudanLife 0x55aeb0` 刷新可见倒计时。

**`Do` 自己不动 life**。克隆此前把这段读成"`Do` 里 set_life"，于是漏掉了分支，只留下了刷新。

### 2. `<>c.<Do>b__4_0 0x51dec0` 就是那两分支

```c
cVar3 = CardExtensions__HasTag(card, DAT_182596500, 0);   // "freeze"
if (card == null) abort;
if (!cVar3) { Card__set_life(card, 0); return; }          // 分支一：全新抽取
if (card + 0x68 == null) abort;                           // CardNode
iVar1 = *(int *)(card_node + 0x60);                       // card_vanishing
Card__set_life(card, iVar1 - *(int *)(player + 100));      // 分支二
```

- `player + 100 = +0x64` = `Player.sudan_card_init_life`（dump.cs）。
- 所以第二分支 = `life = card_vanishing − sudan_card_init_life`，**就是 `GenSudanCard 0x54f6f0` 给新抽苏丹卡的头起步量**，不是 `card_vanishing` 全长。

### 3. 字面量可查：`freeze`

`DAT_182596500` 与 `DAT_1825ac9e8` 此前被记为"元数据无法反查"。实际用 `il2cpp_dump/stringliteral.json` 按 **VA 去镜像基址 `0x180000000`** 就能查到：

| 反编译符号 | stringliteral.json 地址 | 值 |
| --- | --- | --- |
| `DAT_1825ac9e8` | `0x25ac9e8` | `freeze` |
| `DAT_182596500` | `0x2596500` | `sudan` |

> 记法：`DAT_<VA>` 的键 = VA − `0x180000000`。以前直接拿 `0x182...` 去查当然查不到。

`freeze` 在 `content/tag.json` 里是 `id 3019999 / name 冻结 / code freeze / type attribute / can_add 0 / can_visible 1 / tag_rank 50`——就是"冻结卡牌的时间"那个标签，语义与分支完全吻合。

### 4. 配置侧：8 处写点全部落在苏丹卡槽上

| 仪式 | 写点 | 槽条件 | 槽文本 |
| --- | --- | --- | --- |
| 5000158 逆转时光 | `rebirth.s2` | `{"type":"sudan"}` | 苏丹卡 |
| 5006558 复原的神迹 | `rebirth.s1` ×2 | `{"type":"sudan"}` | 放入苏丹卡 |
| 5000576 莎姬的噩梦 | `rebirth.s1` ×5 | `{"is":2001019}` | 神明的耐心就是莎姬生命的倒计时 |

三个文件的克隆副本与语料 SHA-256 等值。**`is_empty` 全为 0**（槽必须已填），所以 `rebirth` 永远作用于已放置的卡。

语义自证：5006558 的 `tips_text` 写"可以重置苏丹卡的剩余时间 / 你只有3次机会"，正文写重置后"就像是从女术士的宝匣里刚刚抽出来的时候一样"——**"刚抽出来的样子"正是 `card_vanishing − sudan_card_init_life`**。5000576 那条 `card_vanishing=15`（莎姬的信物），冻结分支下 `life=15−5=10`，可见倒计时回 5。

## 克隆偏差

旧实现（`sim/result.gd` 的 `rebirth.s<n>` 分支）：

```gdscript
rebirth_instance.life = 0            # 无条件走分支一
...
asc.days_left = rebirth_lifetime     # = card_vanishing，全长
```

两个错：

1. **`冻结` 分支完全缺失**——被冻结的卡应该回到难度头起步量，克隆却给了它 0（= 满额剩余）。
2. **`days_left` 写成 `card_vanishing`**——等于宣称"恢复到满额期限"，而原作是 `card_vanishing − life`。

**为什么一直没被测出来**：默认难度档 `sudan_life_time` 是 7，而 `2010001` 的 `card_vanishing` 也是 7，于是 `7 − 7 = 0`，两分支恰好同值，`days_left` 也恰好同为 7。旧测试就在这个退化点上，所以"通过"。本批把测试搬到困难档（`sudan_card_init_life = 5`）才把差别暴露出来。

## 修复

`sim/result.gd`：

- 新增 `_has_freeze_tag(instance, state, db)`：把 `freeze` 经 `db.tag_code_to_name` 解析成配置名（默认 `冻结`），再读 `effective_card_tags` 的**有效行**（定义行 + 运行时增量 + 可继承装备），对应 `CardExtensions.HasTag`。
- `rebirth.s<n>` 改为按门分流：
  ```gdscript
  var lifetime: int = db.get_card(card_id).get("card_vanishing", 7)
  if _has_freeze_tag(instance, state, db):
      instance.life = lifetime - int(state.sudan_card_init_life)
  else:
      instance.life = 0
  asc.days_left = lifetime - int(instance.life)      # UpdateSudanLife
  ```
- 注释里补上完整 SRC 指针（含 `0x51dec0`、`player+0x64`、字面量地址与 tag.json id）。

`tests/test_dsl_batch1.gd`：原 `test_rebirth_resets_slot_card_countdown` 拆成两条——

- `test_rebirth_without_freeze_restarts_life_at_zero`：无冻结 → `life == 0`、`days_left == card_vanishing`（7）。
- `test_rebirth_with_freeze_resets_to_the_difficulty_head_start`：加 `冻结` 增量 + `sudan_card_init_life = 5` → `life == card_vanishing − 5`、`days_left == 5`，并显式断言 `days_left != card_vanishing`（钉住"不是满额重置"）。

`test_dsl_batch1.gd` 43/43 通过。

## 仍未做

- `RebirthSudanCard` 的 **CardOp 记录**（`PreDo` 的 `AddCardOp_RebirthSudanCard` 0x39e760 / `<PreDo>b__1` 0x51ffc0，`CardOpType.REBIRTH_SUDAN_CARD = 12`）还没有记录点——属 A12 的表现侧，规则效果本批已可断言。
- `Do` 的共享委托缓存（`<>c.cctor 0x5251e0` 建、`Do` 首调时懒建）是纯粹的分配优化，克隆每次直接算，不需要镜像。
- `UpdateSudanLife` 的**显示**语义（数字精灵、闪动）仍未接，本批只对齐了 `days_left` 数值。
