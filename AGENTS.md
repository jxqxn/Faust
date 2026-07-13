# AGENTS.md — 苏丹的游戏 Godot 克隆项目

## 项目目标

在 `C:\Users\User\Documents\GitHub\Faust` 用 Godot 4.x 克隆 Unity 游戏《苏丹的游戏》。

## 语料库

完整逆向产物在 `C:\Users\User\Documents\GitHub\Faust-local-source\_unpack\`（只读，不拷贝、不修改）。

## 逆向参考与验证

实现游戏逻辑时，使用 `$faust-clone-reference` skill。它提供：信任层级、SRC 指针验证、双信号规则、功能域 MANIFEST 导航、已知陷阱清单。该 skill 提供逆向方法论和验证流程。注意：skill 本身也是 .md 文档——语料库里的 .c 反编译和 dump.cs 才是事实本身，skill 教你怎么找到并验证它们。

## 当前进度

Godot 工程具备主桌面、仪式浮层、事件队列、运行时卡牌/仪式实例、v5 存读档与第一批常驻仪式。卡牌 UID、运行时标签、数量和仪式槽位归属均由 `CardInstance` 维护；v4 及更早存档明确拒绝加载且不显示继续游戏。

已验收治理家业/俺寻思/淘书生成存读档链，以及“上朝 -> 权力的游戏 -> 标签移除”实例链。当前重点是按逆向配置补齐后续事件链、DSL 覆盖与表现层；不要把配置中的全部仪式或卡牌直接塞入正常开局。全配置中未支持的 DSL 键必须继续由 `tools/export_dsl_audit.gd` 按配置 ID、次数和位置报告，不得静默视为支持。

## 技术栈

- 引擎：Godot 4.7
- 脚本：GDScript
- 测试：GUT（`tools/run_gut.ps1`，会拦截 Godot `SCRIPT ERROR`、`ERROR`、orphan 与全部泄漏诊断）
- Live2D：第一版用静态图替代，后续按需接入

## Queue and Save Boundary

- `GameState.pending_operations` is the only mutable event/prompt/choice UI
  queue. Preserve occurrence context (`card_uid`, `rite_uid`) when adding a
  new operation type; do not deduplicate by configuration ID.
- `delayed_operations` persists v5 delay payloads and runs once at the Next
  Day boundary. Old v5 split queues are synthesized on load; v4 and earlier
  saves remain rejected without migration.
- Manual user archives are separate from `user://save.json`: use the
  `SaveSystem` archive APIs so index metadata and slot payloads stay together.
  Loading an archive refreshes the continue save; deletion removes both the
  index record and payload. Keep the 50-slot limit and the v5 player-save gate.
- The accepted first-week content batch is governance, I-think, book
  shop/search, and tagged Sultan -> Power Game. Keep all other DSL gaps in the
  machine-readable audit rather than silently marking them supported.
