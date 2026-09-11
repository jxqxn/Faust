# 仪式复刻复核法与逐项验收表

2026-09-11。主入口仍为 METHOD_MAP；本表细分它的仪式待办，不另立“已完成”口径。
本次修正与原作实机观察见 [RiteInputCorrection](RiteInputCorrection.md)。

## 为什么之前会错

| 失败方式 | 已暴露实例 | 今后的纠正方式 |
| --- | --- | --- |
| 把源码注释当行为证明 | 启动链注释误写 auto-begin | 回到方法体，恢复 script.json 的委托地址，核对被调函数 |
| 只搬一个组件或一层贴图 | 卡槽 Highlight、Outline、OutlineNew 混同 | prefab 全组件列表 → 状态处理器 → 材质开关/动画曲线分别登记 |
| 忽略调用时机 | 打开/读档时直接启动家业 | 每个写点登记触发入口；展示操作不能冒充次日逻辑 |
| 只测人工构造的成功态 | 测试手动 stop，绕过启动 bug | 从真实入口进入；不能用状态修补把失败前提抹掉 |
| 单仪式成功推及全系统 | 浴场可用，家业锁死 | 按配置差异选代表，复用相同输入序列，不添加 ID 特判 |
| 用总绿灯掩盖未测分支 | 节点存在即宣称完成 | 每条独立记规则、输入、表现、持久化四类证据；有缺口不总括完成 |

## 如何找到原作做法

1. 从 METHOD_MAP 取一个共同边界，确定行为域；有 MANIFEST 先按其文件清单阅读。
2. 原始配置确定数据与变体，不能把配置存在当作运行时可达。
3. prefab/scene 找到全部组件、引用、UnityEvent、父级、命中区、遮挡顺序。
4. dump.cs 核对字段偏移和签名，再读 `.c`；间接委托通过 script.json 解到实际方法。
5. 表现查 Sprite → Material → shader variant，以及 AnimationClip 的曲线/事件/重入。
   缺失反编译参数的分支标未知，必要时反汇编或实机验证，不能猜。
6. 原作执行“进入前 → 单次输入 → 中间态 → 稳定态 → 离开/重入”，对照卡 UID、
   槽归属、start/life、候选列表、焦点和各图层；高风险边界必须有独立第二信号。
7. 将公共规则落到共同入口，回归先保留能复现旧 bug 的真实前提，再增加反例。
8. GUT 扫错误/孤儿/泄漏；GUI 真输入；原作状态对拍；视觉单列。分别记结论，不能相互替代。

## 向仪式每个细节推广

“待复核”包含已有实现但证据或覆盖不足；“局部通过”只覆盖链接中的已记录条件。

| 域 / 细节 | 源码或资源导航入口 | 必测差异 | 当前验收 |
| --- | --- | --- | --- |
| 创建、UID、同 ID 多实例 | StartRite / InitRite | 创建/显示/开始分离、同 ID 两实例 | 待完整原作差分 |
| 开放与吸附、槽庇护 | RiteExtensions / Slot.open_adsorb | 条件变化、被占用、跨仪式卡 | 待复核 |
| 地图入口与面板重开 | AddRitePin / ShowRite / Start | 准备、运行、到期、隐藏 | 本批重建不变更 start 已测 |
| 模板几何与层级 | RitePanelShow / CardSlot prefab | 旋转、缩放、前景遮挡、透明命中 | 不以模板遍历替代像素验收 |
| 悬停与提示 | SD_SelectableHelper / SlotTips | 空槽、卡子节点、移入/移出、模态 | 家业/浴场普通路径局部通过 |
| 按下/松开/选择 | CardSlotController / GameObjectActiveProcessor | 有/无合格卡、键鼠/手柄切换 | 有合格卡已测；其余开放 |
| 点击筛卡、首张选择、分页 | HandCardSortByCondition / ClearQualifiedBags | 多页、重复点击、换槽、零结果 | 当前页局部通过；全分页待对拍 |
| 拖动合格槽广播 | DragCard / ShowSatisfiedSlot | 空槽、运行、吸附、部分费用 | 输入回归局部通过 |
| 拖放、替换、退回 | CardDropManager / TryUpdateCard | 槽/背景/卡面命中、外部拖动、无效落点 | 家业/浴场局部通过 |
| 费用与数量 | CanPutCard / cost context | 不足、恰好、超额、堆叠拆合、拒绝不变 | 部分费用已测，边界待完整对拍 |
| 卡牌详情、右键、模态 | CardController / OnPointerUp | 左右键组合、详情遮挡、关闭恢复 | 实际输入局部通过 |
| 恢复上次投放 | OnLastState / LastCardData | 缺卡、数量不足、条件改变、吸附槽 | 已有实现，仍需同存档对拍 |
| 开始与停止 | OnConfirm / OnStop | start_round/start_life/life、事件等待 | 不能由输入通过推及生命周期 |
| 自动开始 / 跨日 / 到期 | OnNextRound 委托 / DoStartAutoBeginRite | 新局不提前开始、读档不重启、多个到期 | 本批修时序，次日集成通过 |
| 候选 prior/normal/extra | EnqueueSettlement / SelectSettlements | prior 排他、装备 extra、自身 scope | 见 RiteSystemRootCause，仍需完整差分 |
| PreStart/PreDo 与骰子 | RiteResultPanelController / Dice controllers | 每条结果的准备、投骰、金骰、重投 | 明确未完成逐项演出 |
| 结果文字、卡操作演出 | ResultPanel / CardController | 跳字、逐段、自动、获得/变化/失去 | 文字部分已接，卡演出未完成 |
| 归还、action、关闭 | ReturnCards / OnClose 委托 | result 与 action 顺序、关闭后处理、final_pin | OnClose 时机仍开放 |
| 事件附加结算 | EventTrigger.DoSettlements | 普通/附加项、等待选项、嵌套事件 | 未整合完成 |
| 俺寻思锁卡/对白/动画 | ThinkController / SlotPop / clips | 连续投放、终止、effect/Folder/搬移 | 共享结算已接；表现仍开放 |
| 帮助与提示层 | RitePanelTitle / Prompt | 父级坐标、滚动、取消、遮挡 | 几何已有来源，交互组合待复核 |
| 存读档与回退 | Player / Datapool / 原作 save_samples | 各等待阶段、重启、同 ID、多仪式 | 准备/运行重建已测；结果呈现恢复开放 |
| 音效、粒子与动画同步 | Animator/Animation events / sfx config | 重入、打断、加速、暂停 | 不用自制时长冒充原作，待逐项普查 |

## 收尾门槛

每项记录配置 ID、进入方式、前置状态、输入、原作观察、克隆结果、原始来源、测试和剩余差异。
代表覆盖至少包括自动家业、手动浴场、费用槽、吸附槽、俺寻思、多实例与等待中断。
后续新发现必须加入对应行并扩展反例；不得继续把未知项埋在“1:1 完成”后的脚注里。
