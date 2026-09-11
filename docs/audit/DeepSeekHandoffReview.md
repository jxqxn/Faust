# DeepSeek 工作接手核验（2026-09-11）

## 日志与接手范围

用户提供的只读日志：`C:/Users/User/Downloads/dsh-session-session-7a8f4ebd-595c-4468-8605-5534a70282da/session.v3.jsonl`，6134 行；会话 cwd 为 Faust。最后用户要求停止，第三十六批全量测试被中止，最后回复明确付款辅助函数尚未接入 UI。

第十九至三十六批已经包含标签增量模型、苏丹池对象、每日吸附、cost 条件、复制/重生、文本适配、结果操作流、配置与音频素材等工作。接手时保留全部工作区，不从第十九批重做。本次只修改验收文档，不修改游戏逻辑，不提交或推送，不联网。

日志中的“全量通过”与其同段给出的失败计数有时冲突。按实际失败数验收；“已定位来源”“表加载完成”“辅助函数可测”均不等于游戏端到端完成。

## 直接复核的新发现

1. **付款未接游戏路径**：`pay_cost_into_slot` 与 `slot_cost_needed` 的调用方仅有新测试；`RiteView._place_card_in_slot` 仍调用 `add_card_to_slot`。
2. **付款源码覆盖不全**：`CardSlotController.c @ CardStack (0x53b0a0)` 的 `current@0x148` 同类可堆叠分支先合并数量，运行 `CanPutCard` 后回滚或分配余量。第三十六批只覆盖另一条路径。`dump.cs:317918` 附近字段和 `318014` 方法签名独立确认。
3. **不可堆叠语义需区分方法**：CardStack 返回 false；整张移入的执行体在 `DropCard (0x53b720)`。不能把后者写成前者的已验证分支。
4. **cost 查询仍为近似**：`slot_cost_needed` 深度优先取第一个 cost 键单独求值，丢掉完整 any/all/none 条件关系。只通过平铺/单键测试不足以批准接入游戏。
5. **配音并非全无调用点**：上述两个原作方法尾部均调用 `SFxManager.SFxPlayCharacterDub`；`dump.cs:416440` 签名为 `(int id, int rare, bool is_equip=false)`。调用点已找到，随机变体选择、限频、播放宿主尚未复核，不在本批猜测实现。

## 本次独立验证

- `tools/check_content_parity.ps1`：3889 文件、0 违规；仍未集成 DT1–DT9 与 mobile_help 共10个配置域。
- 对 `assets/original/audio/*.ogg` 与语料 `Assets/AudioClip` 同名文件逐一 SHA-256 比较：167/167 相等，总计150883986字节。该体积是目录总量，不是本次下载量；本次无下载。
- 全量 GUT 完整运行结束（791.082秒，退出码1）：55脚本、653测试、650通过、2失败、1无断言风险项；5903/5905断言通过。日志 `deepseek-handoff-full-gut.log` 无 SCRIPT ERROR、ERROR、orphan 或泄漏报告。不能称全绿。
- 两项失败：`test_card_flash.gd:73` 候选卡底边 659 vs 764；`test_event_choice_controller.gd:44` mask高度489 vs828。与日志描述吻合，但本次未通过恢复旧工作区来再次证明历史归因。
- 风险项：`test_card_op_stream.gd::test_rebuild_clears_previous_rows` 没有断言；GUT摘要把它列在先前脚本下，按运行正文和源码确定归属。
- `git diff --check` 通过。

## 后续顺序

2026-09-11 用户随后要求提交并清理工作区：上述临时日志及生成文件555个（79464282 字节）和Godot缓存（约1.22GB）已移至仓库外 `C:/Users/User/Documents/Faust-cleanup-20260911`，验收计数保留在本文。批量删除被自动审批拦截，改用可恢复迁出。原作素材、布局数据、反编译证据与截图保留，机器工具配置保留；本文引用的日志现在位于该备份目录。

先收口当前两条 UI 失败的正确预期，再从 A19 完整槽接受/成本上下文及已占槽分支推进；随后接生产拖卡路径，验真实输入、存档与结算。A12 动画、A14 骰子、A15 地点、A16 特效和 A21 播放宿主仍按主清单保留未完成边界，不继承日志中的笼统全绿。
