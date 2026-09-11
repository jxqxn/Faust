# 开局仪式重复：空配置被自制默认值覆盖

**后续修正（2026-09-11）：本文以下记录早期批次。** 原始 JSONC 的重复操作曾被 data/config 导出丢弃；现已获用户授权换用 StreamingAssets 原文件。5300066 的真实顺序为宫廷5001001 → 浴场5001501 → event_on5300029（生成书店5002006）→ 家业5000001。真实新游戏操作及原 auto_save notes 已验证四个仪式、奖励卡与出现顺序。初始人物表也已恢复。下文“未完成：初期地图”不再代表当前状态，最新证据见 [RemainingCloneConvergence](RemainingCloneConvergence.md)。

## 已确认的根因

`ConfigDB.get_default_rites()` 原先在 `init_config.default_rite` 为空时使用
`NORMAL_DEFAULT_RITES`，然后按 loot/card 生成来源过滤。这个分支没有原作背书。
过滤也不能把一张“看起来合理”的初期地图变成原作的事件生成链。

- `Datapool.c InitPlayer 0x413700` L4442–4465：逐项遍历 InitNode@0x68，调用 InitRite。
- `dump.cs:390543`：InitNode.default_rite 的 backing field 正是 @0x68。
- 原作与克隆 `init/1.json` 的 `default_rite` 都是 `[]`：空数组不生成仪式。
- `event/5300066.json`：开场剧情 action.rite=5000001，随后启用书店事件5300029。
- `rite/5000001.json`：选中的家业结算 action 创建后继5000001。
- 本批只读检查的本地 save.json 含两个5000001，UID12/13，均在round3运行。
  notes中上一轮UID8/10各生成一份后继，说明问题已经进入实例状态，不只是地图绘制。

因此，提前生成的假家业与剧情生成的真家业会进入两条后继链。
不能用全局按名称/配置ID去重修复：原作InitRite允许同ID的独立实例。

## 修正

删除自制仪式常量及过滤函数。`get_default_rites()` 只返回原配置数组的副本，
保留顺序与重复项；`setup_new_run()` 继续按配置创建实例。
加载已有存档仍读取其持久化实例，不迁移、不删除用户进度。

此前将家业“默认存在”写进测试的夹具，现在显式创建它们需要操作的实例。
这不是放松生产逻辑断言：另有专门开局回归验证真实事件生成。

## 开场与跨日回归

`tests/test_startup_rites.gd` 从setup_new_run(false)开始，触发第1回合
round_begin_ba并执行启动期苏丹抽取。明确选择哈桑、商人家族、言辞、保守、
英武妻子、接受游戏；执行实际OperationsSequence续接，不丢弃选项队列。
随后走RoundLoop至第2、3回合，验证家业始终只有一个，旧UID消失且存读档不新增。
另一反例验证两份显式创建的同ID实例在存读档后仍是两份。

检查测试时发现旧跨日辅助代码读取顶层choices，但真实选择位于payload.choices；
它会错误地直接消费选项。本专项使用严格选择处理器，遇到未知选择即失败。
全仓库旧测试辅助代码的同类普查尚未在本批完成。

## 未完成：初期地图的其他仪式

本批真实开场路径打印的first_day仪式ID为 `[5000001]`。
原作 `save_samples/auto_save.json` 包含家业、权力的游戏、浴场里的消息、书店营业，
是进一步差分的证据入口；两者尚未达到同状态地图一致。

已定位另一自制入口：ConfigDB.NORMAL_DEFAULT_CARDS仅四张，
原作InitNode.default_cards有168项，包含苏丹2000024和书店老板2000199。
`Datapool.InitPlayer` @InitNode+0x58 逐项AddCard；dump.cs确认该字段是default_cards。
书店5002006的s5必须在创建时吸附2000199，因此缺少此人物会导致生成失败。
“168项都是可见手牌”没有证据，不可直接把168张图摆在手牌区；下一批必须一起核对
原作Player.cards、IsHandCard/手牌展示过滤、装备初始化和事件生成的完整边界。

**本批仅消除自制开局仪式的重复来源，不宣称第一天/第二天完整还原。**

## 验证记录

日志置于 `C:/Users/User/Documents/Faust-cleanup-20260911/`。

- `startup-full.log`：全量62脚本/722测试，首次714通过、6失败、2无断言中断。
  失败/中断均定位为依赖自制开局仪式的旧夹具；未把这个结果写成全量全绿。
- 修正夹具后复跑 `startup-final-test_{data_db,hand_pages,integration,
  rite_input_contract,rite_view,save_system,sudan}.log`，115测试/1134断言全过。
- 新增真实开场/跨日/存读档反例 `startup-rites.log`，2测试/11断言全过。
- 最终上述专项日志无ERROR、SCRIPT ERROR、孤儿节点、资源泄漏。
  未受影响的套件采用首次全量结果，未再次全量运行。
- `startup-slot-input.log`：1920×1080真实viewport输入PASS，家业/浴场投放、
  拖出、无效落点、跨槽及运行锁均通过；该工具显式建立仪式夹具，不替代开场链验收。
- 本批未修改content；本会话逐字节配置核验3889文件/0违规。
  原作存档导入桥在全量测试中通过，开局差异与尚未恢复的初始卡牌域仍如上明确保留。
- `git diff --check`通过。未提交、未推送；保留前序未提交工作与用户存档。
