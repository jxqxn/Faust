# AGENTS.md — 苏丹的游戏 Godot 克隆项目

## 项目目标

在 `C:\Users\User\Documents\GitHub\Faust` 用 Godot 4.x 克隆 Unity 游戏《苏丹的游戏》。

## 语料库

完整逆向产物在 `C:\Users\User\Documents\GitHub\Faust-local-source\_unpack\`（只读，不拷贝、不修改）。

## 逆向参考与验证

实现游戏逻辑时，使用 `$faust-clone-reference` skill。它提供：信任层级、SRC 指针验证、双信号规则、功能域 MANIFEST 导航、已知陷阱清单。该 skill 提供逆向方法论和验证流程。注意：skill 本身也是 .md 文档——语料库里的 .c 反编译和 dump.cs 才是事实本身，skill 教你怎么找到并验证它们。

## 当前进度

Godot 工程具备主桌面、仪式浮层、事件队列、运行时卡牌/仪式实例、v5 存读档与第一批常驻仪式。卡牌 UID、运行时标签、数量和仪式槽位归属均由 `CardInstance` 维护；v4 及更早存档明确拒绝加载且不显示继续游戏。

已验收治理家业/俺寻思/淘书生成存读档链，以及“上朝 -> 权力的游戏 -> 标签移除”实例链。全配置中未支持的 DSL 键必须继续由 `tools/export_dsl_audit.gd` 按配置 ID、次数和位置报告，不得静默视为支持。

## 项目阶段：复刻维护冻结 + 原创创意发散中（2026-07-19 修正）

复刻的研究目的已基本达成：规则引擎、Condition/Result DSL 子集、分层结算、苏丹卡循环、CardInstance、v5 存读档与首周四链均成立（251 测试 / 3091 断言全绿）。剩余缺口（全量事件/仪式内容、全 DSL、新手引导、表现层）属于内容铺量与产品化，不再是能力缺口。

**默认行为：**

- 复刻进入**维护冻结**。继续修复 bug、保持测试绿、保持 Queue/Save/DSL 审计边界不变，但**不再扩展苏丹的内容链、仪式与 DSL 覆盖**。不要把配置中的全部仪式或卡牌直接塞入正常开局。
- 原创产线当前位于**创意发散阶段**（`docs/design/sultan-innovation-production-pipeline.md` 的 Stage A 之前）。`docs/design/original-pitch.md` 是素材汇集区，**不是已通过的立项文档**：没有命题、没有核心机制、没有评审结论。允许同时并存多个互相矛盾的方向假设。
- **创意阶段纪律（2026-07-19 确立）：**
  - 任何"命题已通过""核心机制是 X""我们决定 Y"的措辞都表示走错了阶段，应回到素材发散。
  - 题材、机制、UI、数据结构、`modes/` 子目录、配置、原型代码——**都属于实施层，不在此阶段决定或产出**。
  - 命题评审只能由人在 Stage A/B 闸门处正式做出，由评审记录（`original-pitch.md` §6）记入；不能由文档或会话在正文单方面宣布"已通过"。
- 原创原型**不要直接进入 Faust 主工程**。前车之鉴：2026-07-16 `calendar_coop` 模式（8 提交 / 34 文件 / 2263 行）被整体 revert，因为它跳过了命题压缩直接进实现并污染了主分支。新原型应在独立子目录、独立 Godot 项目或纸面/表格上进行，命题评审通过后再决定接入方式。
- 复刻期的强约束在创新期依然适用：未支持的规则要进入审计而不是被静默吞掉；存档/队列边界要保留；不要按配置数量机械安排内容。

## 语料库在创新期的新角色

复刻冻结后，逆向语料库（`Faust-local-source/_unpack/`）从"实现依据"变为"设计参考"。引用原作结构（如仪式字段、苏丹卡控制流）作为设计假说的证据时仍须遵循 `faust-clone-reference` 的信任层级与双信号规则，但不再以"逐字段复刻原作"为目标。

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
- Use the reachability metadata in `tools/export_dsl_audit.gd` to choose the
  next content batch. It is a conservative static graph, not a replacement for
  source-backed runtime verification or a reason to mark every short-hop key
  supported.
