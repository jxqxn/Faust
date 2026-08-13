# Faust 研究证据入口

> 用途：让没有参与既往讨论的新会话智能体，在提出设计判断前找到可复核证据、已确认的项目判断与尚未取得的数据。
>
> 最近整理：2026-08-13

## 新会话必读

1. 先读[游戏设计数据研究总报告](faust-game-design-data-research.md)的“主张登记表”，按主张 ID 区分外部事实、本地复现、本报告计算、用户确认的项目判断、研究解释、待验证假说和未知。
2. 引用公开资料时，继续读总报告的“来源登记表”，检查来源日期、版本、样本与证据局限；易变数据在使用前重新打开原始页面。
3. 引用《苏丹的游戏》本地静态配置数字前，在仓库根目录运行：

   ```powershell
   & .\tools\export_design_research_snapshot.ps1 -Check
   ```

4. 判断《苏丹的游戏》运行时行为时，不以总报告或 JSON 配置代替事实。必须使用 `$faust-clone-reference`，回到只读逆向语料中的 `.c`、`dump.cs` 与独立信号。
5. 决定 Faust 的手牌上限、候选数量、自动化层级或认知负荷阈值前，先读总报告的“尚未取得的项目证据”。目前这些数值没有玩家实验答案，不得凭类比补写。

## 各类文档的权威边界

| 资料 | 负责回答 | 不能回答 |
|---|---|---|
| [数据研究总报告](faust-game-design-data-research.md) | 主张状态、公开来源、复现方法、证据局限、待测假说 | 原作未验证的运行时行为；尚未执行的项目实验结果 |
| [静态快照](data/faust-design-research-snapshot.json) | 指定语料指纹下的配置数量、分布与极值 | 单局可见内容、玩家实际决策、运行时可达性 |
| `docs/design/` 下的设计研究 | 用户确认的项目方向、比较框架和设计约束 | 外部因果事实；未经测试的具体参数 |
| `$faust-clone-reference` 与只读逆向语料 | 《苏丹的游戏》原作运行时与实现边界 | Faust 的玩家体验是否成立 |
| 未来的实验报告与原始遥测 | Faust 原型中的行为、耗时、错误与体验效果 | 尚未覆盖人群和版本的普遍结论 |

## 研究主题索引

- 《苏丹的游戏》人物叙事转译：[叙事转化](../design/sultans-game-narrative-transformation.md)，对应 `NARR-SYN-001`、`FAUST-DES-001`。
- 《苏丹的游戏》认知负荷与自动化：[认知负担](../design/sultans-game-cognitive-load-and-automation.md)，对应 `SG-UX-001`—`SG-UX-003`、`FAUST-HYP-001`。
- 《火焰纹章》人物化改造：[叙事转化](../design/fire-emblem-narrative-transformation.md)，对应 `FE3H-DES-001`、`FE3H-EXPL-001`。
- 《风花雪月》校园架构与《Engage》：[校园架构](../design/three-houses-campus-architecture-and-engage-contrast.md)，对应 `FE3H-BEH-001`、`FE3H-MKT-001`、`FE3H-DES-001`、`FE3H-EXPL-001`。
- 《风花雪月》、P5R 与《苏丹的游戏》日程比较：[日程比较](../design/three-houses-p5-sultan-schedule-comparison.md)与[校园循环对照](../design/three-houses-sultan-campus-loop-comparison.md)，对应 `FE3H-RULE-001`、`P5R-RULE-001`、`P5R-MODEL-001`。
- 《酒馆战棋》的自走棋化：[改造研究](../design/hearthstone-battlegrounds-transformation.md)，对应 `BG-SIM-001`、`BG-BEH-001`、`BG-METHOD-001`。
- 麻将、血流成河与自走棋共同结构：[共同结构](../design/mahjong-autobattler-common-origin.md)，对应 `MJ-MODEL-001`、`MJ-MODEL-002`、`MJ-HYP-001`。
- P5R 体验与有限日程：[MDA 基线](../design/p5r-mda-experience-baseline.md)，对应 `P5R-RULE-001`、`P5R-MODEL-001`。

## 当前证据状态

- 已有：可追溯的公开资料、来源局限、带语料指纹的本地静态统计、研究方法和可证伪假说。
- 尚无：Faust 正式玩家实验参与者、A/B 或 A—E 对照结果、逐局遥测、NASA-TLX/DRT 结果、可接受手牌规模和自动化边界。
- 因而下一步是制作可记录决策面和人物后果的最小原型并执行预注册式测试；不是继续用更多文章替代项目数据。

## 一致性检查

在仓库根目录运行：

```powershell
& .\tools\check_design_research.ps1
```

检查器会验证静态快照未过期、总报告关键结构存在、入口文档可发现，以及各核心设计研究已链接到证据总报告。
