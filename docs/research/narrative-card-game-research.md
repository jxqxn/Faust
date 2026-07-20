# 叙事卡牌设计谱系研究：密教模拟器 / 苏丹的游戏 / 诡镇奇谈 LCG

> 目的：为创意发散期的方向假设提供一份**经过查证的设计参考**，把"为什么密教/苏丹叙事强"这个问题从印象式的赞叹，落到设计师亲自定义的术语和框架上。
>
> 范围：以 Alexis Kennedy（Failbetter / Weather Factory 创始人）和 MJ Newman（AHLCG 主设计师）等**设计师本人的原话**为一手资料，回答三个问题——叙事卡牌为什么能讲故事？密教/苏丹和 AHLCG 的真正差异在哪？我们做原创提案时该用什么诊断工具？
>
> 资料状态：2026-07-20。所有带 `[已查证]` 标签的断言都有可追溯的网络来源（文末附），关键引文来自作者本人博客或访谈。这份文档遵守 `original-pitch.md §3.5` 的断言分类纪律。
>
> **追加（2026-07-20，第二轮辩证后）**：§八 追加了更广叙事游戏谱系的查证事实——Hocking 的 ludonarrative dissonance、Apocalypse World 的 fiction first/fail forward、Citizen Sleeper 的 Blades in the Dark 血统、极乐迪斯科的机制与 Planescape Torment 血统。**这些事实不连成系统**，详见 §八末尾的边界说明。本研究的过度系统化失败记录在 `docs/research/ai-over-systematization-track-record.md`。

---

## 先给结论（策划视角的 TL;DR）

1. **"叙事卡牌"不是一种类型，是一个谱系**。在这条谱系上，密教/苏丹处于一端（**资源涌现式叙事**），AHLCG 处于中间偏另一端（**脚本场景式叙事**），CRPG/Firewatch 在更远的另一端。
2. **真正的分界线不是"谁讲故事"或"卡牌是不是名词"，而是"叙事从哪里涌现"**——是从资源状态的组合中自然涌现（密教/苏丹），还是从预设的场景卡/对话树分支涌现（AHLCG/CRPG）。
3. **Kennedy 亲自定义的诊断框架叫 "resource narrative"（资源叙事）**，配套三个有效性条件：资源必须**稀缺**、**可再生产**、**可替代**。这是评估任何原创提案"叙事性强不强"的硬工具。
4. **苏丹的玩法血统不是"密教之子"**——主创亲述是 **《This Is the Police》（资源卡填入事件槽）+ 文明的"下一回合"节奏**，从密教只借鉴了**地图叙事**逻辑。内容取向从密教的"世界观"转向了**"人"**。
5. **AHLCG 主设计师和苏丹主创在做同一种叙事意图**——"塑造角色、让角色在世界中被测试"。差异不在意图，在实现机制（脚本场景 vs 资源涌现）。

---

## 一、Kennedy 的术语谱系（一手原文）

Alexis Kennedy 是 Failbetter Games（Fallen London、Sunless Sea）和 Weather Factory（Cultist Simulator、Book of Hours）的创始人，密教/苏丹这条谱系的源头设计师。他的核心叙事设计术语经过三次演化，**每次都有他本人的原文定义**。

### 1.1 第一代：Choice / Complicity / Consequence（2012）`[已查证]`

来源：Failbetter 官方博客《Choice, Complicity and Consequence》（2012-09-20）。这是 Kennedy 团队最早公开的叙事设计三支柱，**注意"Consequence"就是后来被二手评论改写成"lagged consequences"的原始词**。

Kennedy 原文定义（策划语言翻译）：

- **Choice（抉择）**：玩家在做一个**有分量的决定**之前那一刻的体验。"fulcrum-shift"（支点转动感）——可以是情感/道德抉择（救他还是救她），也可以是策略抉择（现在用掉这个人情还是留着）。
- **Complicity（共谋）**：玩家**在故事中行动**的体验。"being in the driving seat"——我在让这件事发生，我是共谋者。可以是道德共谋（"我让他去死了"），也可以是权力幻想（"我花了大价钱买的人情，现在终于可以兑现了"）。
- **Consequence（后效）**：玩家**看着事件展开**的体验。"the pleasure of the intricate ramifications of plot"——看着过去的决定像涟漪一样扩散开来。Kennedy 原文举例："and now the Don looks weak - so Tony's making his move early - which means I have to get the gold out by tomorrow"（教父现在显得软弱了——所以汤尼提前动手了——这意味着我明天之前必须把金子运走）。

**Kennedy 的关键提醒**：在这三者中，Consequence 是**最贵的**——而且复杂度越高越贵。业界以为 Consequence 是互动叙事的核心（所以 RPG 都吹"几十种结局"），但"二十种结局不比两种结局好十倍"，如果 Complicity 和 Choice 没做好，再多 Consequence 也没用。

**这条对策划的直接意义**：设计叙事卡牌时，**不要堆 Consequence（后果分支）**。先把 Choice（让玩家纠结的抉择点）和 Complicity（让玩家觉得自己在主导）做扎实，Consequence 是自然产物。

### 1.2 第二代：Quality-Based Narrative / QBN（约 2015）`[已查证]`

来源：Kennedy 在多个 GDC/AdventureX 演讲中提出，是他给 Fallen London/Sunless Sea 的底层技术模型起的名字。

**QBN 的机制**（策划语言）：
- 所有玩家状态（属性、货币、剧情进度变量）都统一抽象成 **"Quality"（特质）**。
- 剧情片段叫 **"storylet"（故事片段）**，由 Quality 状态**触发**和**分支**。
- 玩家不需要按线性顺序走剧情，storylet 根据 Quality 状态涌现。

**Kennedy 2021 年的反思**：他在博客里说，QBN 这个词误导——它听起来像"靠高品质取胜的叙事"。更重要的是，"所有 Quality 平等"这个 2009 年的设计决定，抹掉了本有用的区分（角色属性、货币、剧情变量本来应该不一样）。

### 1.3 第三代：Resource Narrative（2021）`[已查证]`

来源：Weather Factory 官方博客《I've stopped talking about quality-based narrative, I've started talking about resource narrative》（2021）。**这是 Kennedy 目前最新的、最核心的术语**。

Kennedy 原文定义（策划语言翻译）：

> **"Resource narrative"（资源叙事）= 一个有游戏感的显性叙事，玩家通过策略性地操控一组有限资源（生命、社交关系、剧情推进等）来推进。**

核心特征（Kennedy 原话）：
- **资源的本质和相互关系与故事的纹理对齐**（aligns with the grain of the story）。
- **事件从资源状态的组合中自然涌现**（emerge in a natural-seeming way from the combination of resource states）。
- **不需要 AI 导演或戏剧管理系统**——靠"资源交互的选取和设计"作为戏剧自然涌现的语境。Kennedy 把这种设计叫 **"poetic design"（诗性设计）**。

**三条件**（Kennedy 亲述，评估提案的硬工具）：

> Resource narratives are most effective when resources are **scarce, reproducible and fungible**.
> （资源叙事最有效的条件：资源**稀缺**、**可再生产**、**可替代**。）

策划解读：
- **Scarce（稀缺）**：资源必须不够用，玩家被迫做取舍。
- **Reproducible（可再生产）**：资源能被消耗也能被重新获得（不是一次性消耗品）。
- **Fungible（可替代）**：不同资源之间能互相转换（生命能换钱、钱能换情报）。

### 1.4 Kennedy 亲自列的 YES / NO 名单（诊断工具）`[已查证]`

这是整份文档**最有诊断价值的证据**——Kennedy 本人对"什么是 resource narrative"的明确划分。

**YES，是 resource narrative**：
- Sunless Sea、Fallen London（Kennedy 自己的作品）
- 80 Days
- **Darkest Dungeon**
- Dwarf Fortress
- **FTL**
- Hand of Fate
- **King of Dragon Pass**
- 育碧开放世界（Far Cry 系列）
- Stellaris
- **XCOM（任何版本）**
- **…Cultist Simulator**

**NO，不算 resource narrative**（虽然有叙事也有资源）：
- 分支叙事：Choice of Games 系列、Sorcery!、大多数 Twine 作品
- **CRPG：龙腾世纪、老滚、辐射、质量效应、异域、巫师**
- 脚本叙事优先游戏：Firewatch、Gone Home、Her Story、Oxenfree
- 沉浸式模拟：耻辱、HITMAN、网络奇兵
- 大多数 parser 互动小说

**这张名单对策划的诊断价值**：
- 你说"我们要做叙事卡牌"——好，你要做的是 YES 端还是 NO 端？
- YES 端：资源要可消耗、可恢复、可转换，叙事从资源组合涌现。
- NO 端：靠写分支剧情、场景脚本、对话树。两条路都成立，但**不能混着做**——混了既丢涌现性又丢脚本密度。

---

## 二、关于"lagged consequences"的纠错 `[已查证 → 降级]`

这一节专门记录一个**归因错误**，作为后续会话的防坑提示。

**我曾多次把"lagged consequences"（延迟后果）这个词归给 Kennedy**，作为他的核心设计概念。但多轮精准搜索（2026-07-20）证实：

- **这个词不是 Kennedy 的术语**。多次精确搜索"lagged consequences" + "Alexis Kennedy" 返回空结果。
- **行业里它也不是标准术语**——搜索工具自己确认："the term doesn't appear to be established industry jargon"。
- **Kennedy 的真术语是 Consequence**（2012 三支柱之一），后来演化成 QBN 和 resource narrative。"lagged consequences" 是**二级评论者**（GDC 笔记、博客读后感）对 Consequence 的二手改写。

**为什么这个归因错误值得记录**：它暴露了一个反复出现的失败模式——**我倾向于把听起来深刻的术语归给看起来权威的人**。"lagged consequences" 听起来像 Kennedy 会说的词，我就反复引用，从未核实原文。这是 v1→v5 track record 里"自信 ≠ 准确"的同一问题在**术语归因**上的复现。

**后续会话纪律**：任何引用 Kennedy 的术语，必须能给出他本人原文的 URL。做不到的标 `[印象]`，不能当已查证使用。

---

## 三、AHLCG 设计师一侧的声音 `[已查证]`

前几轮讨论里，我对 AHLCG 的判断一直缺少设计师一侧的资料，只有玩家评论。这一节用 MJ Newman（AHLCG 主设计师，Fantasy Flight Games）的原话补上。

### 3.1 MJ Newman 的叙事哲学（与苏丹主创几乎是同一种语言）

来源：Hall of Arkham 整理的 MJ Newman "Designer Journal" 系列访谈语录（2020-2025）。

**MJ Newman 原话**：

> "I'm a writer and a roleplayer at heart. I like to **forge worlds, create characters, and then weave a narrative wherein those characters are placed in that world and tested**. So, as you might imagine, my favorite kinds of games are those which tell a story through gameplay."

策划翻译：**"我骨子里是个写作者和角色扮演者。我喜欢铸造世界、塑造角色，然后编织一段叙事——把角色放进那个世界里去考验。所以我最爱的游戏类型，是用玩法讲故事的那些。"**

**对比苏丹主创远古之风的原文**（来自网易主创访谈）：

> "核心还是去讲一个关于世界观的故事还是讲一个关于人的故事的选择分歧…我们的热情与能力都集中在去塑造角色与细节方面，因此《苏丹的游戏》本身也是一个专注于人性本身的故事。"

**这两段话是同构的**——都是"塑造角色、把角色放进世界去考验"。这意味着：

- **AHLCG 和苏丹的叙事意图是同源的**——都做角色驱动叙事。
- 我前几轮的论点"AHLCG 系统讲故事 vs 密教/苏丹玩家讲故事"是**错的**——两边主设计师都明确在做角色叙事。
- **真正的差异不在意图，在实现**：AHLCG 用预设场景卡 + 遭遇卡（脚本驱动），密教/苏丹用 resource narrative（资源涌现）。

### 3.2 AHLCG 的卡牌作为叙事单位 `[已查证]`

**MJ Newman 关于卡牌设计的原话**：

> "What a card represents in the game's setting is an essential part of its identity, and the name is integral to establishing that representation within a player's mind. **A good card title can create a story of what happens when the card is played.**"

举例（MJ Newman 自己举的）：**"Look what I found!"（"看我发现了什么！"）** 这张卡的效果是把失败转成机会——一个好的卡名本身就在讲"这张卡被打出时发生了什么故事"。

**这条反驳了我之前"AHLCG 卡是机制单位"的判断**——AHLCG 设计师明确把卡牌当叙事单位设计，连卡名都是叙事工具。

### 3.3 AHLCG 的多角色协同（fellowship 模型）`[已查证]`

**MJ Newman 谈 AHLCG 的基础**：

> "When Nate and I first started working on Arkham, we built its foundation on The Lord of the Rings: The Card Game…one of the pillars of that game is its epic and grandiose tone. **You aren't just one character; you control a fellowship**, with each of your characters likely to be able to handle different elements of gameplay."

策划翻译：AHLCG 的构筑基础是 LOTR LCG，**核心是"玩家不止控制一个角色，而是一支队伍"**——这是 AHLCG 和密教/苏丹的另一个结构性差异：
- AHLCG：玩家控制**多个调查员**协同（队伍模型）
- 密教：玩家就是**一个人**（孤立的秘法师）
- 苏丹：玩家是**一个大臣**，但调度多个具体的人

这个差异对叙事的影响：AHLCG 的故事是"群像剧"，密教是"个人堕落史"，苏丹是"权斗中的人际网络"。

### 3.4 AHLCG 的场景叙事机制（脚本驱动）`[已查证]`

**MJ Newman 谈场景设计**：

> "Typically…the encounter deck…the person you're playing against…they need a win condition…we think about how the scenario is trying to win…usually the answer to that question is right there in the narrative. We'll make a decision based on what's happening."

策划翻译：每个场景的遭遇牌组都有一个"胜利条件"，而这个条件**直接来自剧情**——比如"你要从 A 到 B"，那遭遇牌组赢的方式就是"堵住你、包围你、杀掉你"。**叙事决定机制，机制服务叙事**——这是脚本驱动的典型做法，和 resource narrative 的"机制涌现叙事"是相反方向。

---

## 四、苏丹主创的玩法血统 `[已查证]`

这一节记录苏丹主创远古之风亲述的玩法血统，纠正"苏丹=密教之子"的简化印象。

来源：知乎/腾讯新闻转载的苏丹专访《让无数玩家甘愿成为"赛博昏君"》，以及网易主创访谈《MOD 支持即将上线！〈苏丹的游戏〉主创访谈》。

### 4.1 主创亲述的三支血统

> "其实就我个人而言我们的玩法与其说是密教还不如说是《警察故事》…我们借鉴了他们（密教）很多地图叙事的逻辑，再加上《文明》式的'下一回合'的吸引力…"

策划解读（这是苏丹玩法的真正血统）：
- **玩法骨架**：**《This Is the Police》**（2016，蜜蜂工作室）——玩家扮演警察局长，把资源卡填入各种事件内，通过选择和时间推进剧情。苏丹的"仪式槽位投入卡牌"骨架来自这里，**不是密教**。
- **节奏机制**：**《文明》系列的"再来一回合"**——那种让人停不下来的下一回合吸引力。
- **借鉴密教的部分**：只有**地图叙事的逻辑**（卡牌作为叙事符号、空间化呈现故事）。

### 4.2 主创亲述的内容取向

> "核心还是去讲一个关于世界观的故事还是讲一个关于人的故事的选择分歧。密教模拟器不论开发者在制作时的出发点是什么，实际上起到了一个收束和继承洛夫克拉夫特文学世界观的作用…比起游戏本身，这一点在文学上的价值反而更胜一筹…我们的热情与能力都集中在去塑造角色与细节方面。"

策划解读（密教 vs 苏丹的内容取向分野）：
- **密教**：核心是**世界观**——重新编织和继承洛夫克拉夫特神话体系。故事单位是**知识、密传、存在层级**。
- **苏丹**：核心是**人**——塑造具体的角色和细节。故事单位是**具体的人、人际网络、人性考验**。

**这条修正了"苏丹和密教是同一种叙事"的印象**——它们用相似的机制框架（resource narrative），但讲的是**不同对象**的故事。密教讲世界观，苏丹讲人。

### 4.3 苏丹与密教的官方捆绑包 `[已查证]`

两家工作室已推出**官方捆绑包**销售。这是业界（包括两家工作室）认可两者设计理念相似的硬证据——不是社区附会。

---

## 五、诊断框架：用 resource narrative 评估提案

这一节把前面的查证结果转成**可操作的诊断工具**，给创意发散期评估方向假设用。

### 5.1 三条件测试

任何"叙事性强"的原创提案，用 Kennedy 三条件测：

| 条件 | 测试问题 | 不通过的典型症状 |
|---|---|---|
| **稀缺（Scarce）** | 资源够不够紧？玩家被迫取舍吗？ | 资源太多 → 玩家不痛 → 抉择没分量 |
| **可再生产（Reproducible）** | 资源能消耗也能重新获得吗？ | 一次性消耗品为主 → 没有循环 → 叙事断裂 |
| **可替代（Fungible）** | 不同资源能互相转换吗？ | 每种资源独立用途 → 没有转换张力 → 决策空间扁平 |

**策划用法**：提案写出来后，把"核心资源"列出，逐条过这三个问题。三个都通过的提案，resource narrative 潜力高；有任何一个不通过，要明确知道叙事性会打多少折扣。

### 5.2 谱系定位测试

用 Kennedy 的 YES/NO 名单定位提案：

- 提案接近 **YES 端**（Darkest Dungeon / XCOM / FTL / 密教 / 苏丹）：核心是**资源涌现叙事**，设计重点是资源交互。
- 提案接近 **NO 端**（CRPG / Firewatch / 分支叙事）：核心是**脚本驱动叙事**，设计重点是剧情写作和分支设计。
- 提案**两端都不沾**：要警惕——既没有涌现性也没有脚本密度，叙事最容易崩。

### 5.3 "卡牌=名词"的精确位置

前几轮讨论里反复出现的"卡牌=名词、动作=动词"——**这只是实现层，不是 Kennedy 的核心术语**。核心术语是 resource narrative。

**策划意义**："我们把所有游戏对象做成卡牌"本身**不构成**叙事设计——它只是选择了实现容器。真正决定叙事性的是**这些卡代表的资源是否满足三条件、以及它们的交互是否让戏剧涌现**。

---

## 六、查证前后的论点修正账本

这一节诚实记录本研究的辩证过程中，哪些论点被查证推翻或修正了。作为后续会话的防坑参考。

### 被推翻的论点

| 原论点 | 查证后的修正 |
|---|---|
| "杀戮尖塔/自走棋没有延迟后果和因果痕迹" | **错**。Kennedy 把 Darkest Dungeon、XCOM、FTL 都列入 resource narrative，这些游戏都有延迟后果和因果痕迹。真正的差异是资源的 **fungibility（可替代性）**——杀戮尖塔的牌库不够 fungible，所以 resource narrative 程度低 |
| "AHLCG 系统讲故事，密教/苏丹玩家讲故事" | **错轴**。MJ Newman 明确角色驱动叙事，和苏丹主创是同一种意图。真正差异是**脚本驱动 vs 资源涌现**，不是"谁讲故事" |
| "苏丹=密教之子（玩法直接继承）" | **部分错**。主创亲述玩法血统是 This Is the Police，从密教只借鉴地图叙事 |
| "lagged consequences 是 Kennedy 的核心术语" | **归因错误**。Kennedy 真术语是 Choice/Complicity/Consequence → QBN → resource narrative。"lagged consequences" 是二手评论改写 |

### 被确认的论点

| 论点 | 查证依据 |
|---|---|
| "卡牌=名词、动作=动词"是 Kennedy 用过的框架 | Reddit AMA 原话证实，但只是实现层 |
| 密教/苏丹在叙事卡牌谱系的同一端 | 官方捆绑包 + Kennedy 把密教列入 resource narrative YES 名单 |
| 苏丹和密教在设计理念上高度相似 | 官方捆绑包是硬证据 |

### 仍不确定的论点

| 论点 | 为什么不确定 |
|---|---|
| AHLCG 应该归入 NO 名单（脚本驱动） | 我基于"场景卡+遭遇卡"机制推断，但 Kennedy 本人没明确划分 AHLCG。这是 `[推断]` 不是 `[已查证]` |
| 杀戮尖塔的 resource narrative 程度低 | 我基于 fungibility 三条件推断，没有 Kennedy 本人或同行明确划分 |
| 具体哪款游戏在谱系的哪个位置 | 谱系是连续的，不是离散的，边界案例一定有争议 |

---

## 七、对 Faust 项目的具体应用

这一节把研究成果落到 Faust 项目的两个产线上。

### 7.1 复刻线（已冻结）

复刻线不需要这份研究做依据——它有更权威的资料（反编译语料库）。但这份研究提供了一个**评估复刻完整度的补充视角**：

- 苏丹是 resource narrative 的典型实现，其复刻完整度可以用**三条件**测：金币/时间/苏丹卡是否 scarce（✅）、是否 reproducible（✅ 金币可再获得）、是否 fungible（⚠️ 这块是复刻的薄弱点——苏丹卡之间、人物之间、资源之间的转换链是部分实现的）。
- 复刻线的 fungibility 缺口，可以作为"维护冻结期允许的正确性修复"的判断依据（参照 2026-07-19 修复苏丹卡安全期 bug 的同类决策）。

### 7.2 原创产线（创意发散期）

这份研究对原创产线的价值更高，作为 **Stage A/B 评审的查证基线**：

- 任何方向假设里"我们要做叙事卡牌"的断言，必须能用 resource narrative 框架回答："你的资源是什么？三条件过不过？"
- 任何"我们学苏丹/密教"的断言，必须明确**学的是哪一层**——实现层（卡牌=名词）？意图层（resource narrative）？内容层（讲人 vs 讲世界观）？
- 任何"我们融合 X 和 Y"的提案，参照 calendar_coop 教训——融合前先用本研究的诊断框架过一遍。

**这份研究本身不构成命题通过的依据**。它是创意发散期的素材，按 `original-pitch.md §3.5` 的纪律，进入 Stage A/B 评审时每条断言仍需自带 `[已查证]` / `[推断]` / `[印象]` 标签。

---

## 八、更广的叙事游戏设计谱系（追加于 2026-07-20）

> 本节是后续辩证讨论中查证到的**零散硬事实**。**不连成系统**——它们是被反复放在一起讨论的设计语料，但没有统一理论解释它们为什么被放在一起。强行连成系统会重犯 §九记录的"过度系统化"错误，所以本节保持"事实清单"形态。

### 8.1 Clint Hocking 的 ludonarrative dissonance（游戏叙事失调，2009）`[已查证]`

来源：Clint Hocking 2009 年针对 BioShock 提出的概念。

- **Dissonance（失调）**：游戏机制奖励的行为与叙事主题表达的价值**矛盾**。例：BioShock 叙事讲"自由意志 vs 外部控制"，但机制是线性的、玩家无法选择回避战斗的 shooter——机制和主题矛盾。
- **Harmony（和谐）**：上述的反面——机制和叙事主题**不矛盾**。Papers, Please 是典型和谐案例（审查机制 vs 权力主题一致）。

**重要边界（自审后修正）**：
- harmony 是**必要条件**，不是**充分条件**。炉石机制和叙事不矛盾，但炉石叙事弱。
- 所以**"harmony 高"不能解释"叙事强"**——它只能解释"叙事为什么不崩"。
- 这个概念最有用的地方是**诊断**——发现提案的机制和叙事是否矛盾。不是预测叙事强度。

### 8.2 Apocalypse World（2010，Vincent & Meguey Baker）`[已查证]`

被认为是现代叙事 TTRPG 的分水岭。确立的两个核心原则：

- **Fiction first（虚构优先）**：先在虚构世界描述动作，再触发机制；不是先掷骰再编故事。
- **Fail forward（失败向前）**：失败的检定不停叙事，而是制造**新的复杂情况**。典型实现是 2d6 的 7-9"部分成功带代价"。

这两个原则通过 **Powered by the Apocalypse (PbtA)** 和 **Forged in the Dark**（Blades in the Dark 衍生）两大 TTRPG 谱系扩散。

**边界**：PbtA 是**一条设计谱系**，不是"所有叙事游戏的源头"。它在 Citizen Sleeper 上是直接源头（见 8.3），但在密教/苏丹/极乐迪斯科上是**平行演化**，不是继承关系。

### 8.3 Citizen Sleeper 的设计血统（Gareth Damian Martin 亲述）`[已查证]`

来源：[Rascal News 对 Gareth Damian Martin 的访谈](https://www.rascal.news/tracing-citizen-sleepers-circuitous-vector-from-tabletop-to-hit-video-game/)。

Martin 的原话关键点：

> **"One of the massive ones is the agency of the player in relation to dice in Blades. ... the idea of the player's body or character as being a resource that you invest in order to push fate in different directions."**

策划翻译：Citizen Sleeper 的核心机制（身体作为可投入的资源、push/stress 系统、dice pool）**直接借鉴自 Blades in the Dark**（Forged in the Dark 谱系的代表作，John Harper 设计）。

Martin 还说**骰子作为物件本身有"诗意联想"——命运、机会、脆弱**——所以他拒绝把骰子"fictionalize"成"能量核心"。

**对 Faust 的意义**：Citizen Sleeper 是"骰子叙事游戏"的另一条血统（PbtA 源头），和苏丹/密教（Kennedy resource narrative 源头）**平行**。如果要研究"骰子检定如何承载叙事"，Citizen Sleeper 是独立于苏丹的另一参考点。

### 8.4 极乐迪斯科（Disco Elysium, 2019, ZA/UM）的关键机制 `[已查证]`

来源：[GameAnalytics Rezzed 2018 对 Kurvitz 的访谈](https://www.gameanalytics.com/blog/disco-elysium-rezzed-2018-interview) + [Game Design Thinking 系统分析](https://gamedesignthinking.com/disco-elysium-rpg-system-analysis/)。

**机制心脏**：
- **4 属性 × 6 技能 = 24 个"内心声音"**——每个技能不是被动数值，是**有人格、有议程的声音**，会在对话中主动打断主角，给出（有时互相矛盾的）建议。
- **被动检定**让"主角脑子里吵架"——技能等级越高，打断越频繁，玩家越难选。**难度来自角色脑子的混乱，不来自外部敌人**。
- **思维内阁（Thought Cabinet）**：12 个槽位的思想物品栏，60+ 种思想，**玩家在内化前不知道加成**。思想会改变角色人格取向（共产主义者/自由主义者等），解锁新对话选项。

**Kurvitz 本人的设计自述**：
- 受 Planescape: Torment 影响最深——"每个 RPG 都有一个酷侦探角色，那些一直是我最爱的 RPG 部分……我想做一个只有这个的游戏"。
- 团队是 **8 个写作者**，把对话树称为 **"The Mind Shatterer"**——"I still call it 'The Mind Shatterer', it's just so difficult mentally"。

**对 Faust 的意义**：极乐迪斯科和苏丹/密教**不是同一条设计谱系**——它继承自 Planescape: Torment 的 CRPG 内省传统。把它和苏丹/密教放在一起讨论是社区共识，但**它们强化叙事的机制路径不同**。

### 8.5 学术界对密教/极乐迪斯科的并置研究 `[已查证存在]`

来源：Friedrich 2025 MDes 学位论文（Concordia University），《Modeling the Late Bronze Age Collapse in The Jagged Time》。

**注意置信度**：我确认论文存在 + 摘要里把密教和极乐迪斯科作为设计参考，但 PDF 损坏**未读全文**。所以这是"学术界在并置研究"的**存在性证据**，不是"学术界得出了什么结论"的证据。具体结论需要后续补查 PDF 全文。

### 8.6 评论界一致认为极乐迪斯科是 ludonarrative harmony 的"金标准"案例 `[已查证]`

来源：[Pop & Locke 播客](https://www.libertarianism.org/podcasts/pop-locke/disco-elysium) + [r/truegaming 讨论串](https://www.reddit.com/r/truegaming/comments/rbtked/my_eternal_quest_for_games_with_ludonarrative/)。

- Pop & Locke 播客原话：思维内阁是 **"a really, really good example of Ludonarrative harmony"**。
- r/truegaming："Disco Elysium has no dividing line at all between gameplay and narrative."

**边界**：这条断言是评论界共识，不是设计师本人自述。Kurvitz 没有用 "ludonarrative harmony" 这个词描述自己的设计。

### 8.7 本节的事实清单不构成统一理论

**自审后的诚实边界**（详见 §九）：

本节列出的六条事实是**零散的查证数据点**。它们被评论界、设计师社区、学术界反复放在一起讨论，但**没有一个统一的理论解释为什么这些游戏被放在一起**。尝试把它们连成"家族相似网络 + 共同源头 + 三种路径"的系统会重犯"过度系统化"错误——这是 §九记录的失败模式。

策划用法：把这些事实当作**独立的设计参考点**，而不是一个统一框架。每个参考点单独评估其对原创提案的启发价值，不要假设它们能被一个理论统合。

---

## 九、资料来源清单

所有 `[已查证]` 断言的可追溯来源，按可信度排序。

### 一手资料（设计师本人原话）

1. **Kennedy 2021 QBN → Resource Narrative**（Weather Factory 官方博客）— resource narrative 定义、三条件、YES/NO 名单
   https://weatherfactory.biz/qbn-to-resource-narratives/

2. **Failbetter 2012 Choice/Complicity/Consequence**（Failbetter 官方博客）— 三支柱原文定义
   https://www.failbettergames.com/news/choice-complicity-and-consequence

3. **苏丹主创远古之风访谈**（网易新闻转载）— 玩法血统、人 vs 世界观
   https://www.163.com/dy/article/K0BCUM2O0526JULF.html

4. **苏丹专访《赛博昏君》**（知乎/腾讯新闻转载）— This Is the Police 血统、文明下一回合
   https://zhuanlan.zhihu.com/p/7588271698

5. **MJ Newman Designer Journal 语录集**（Hall of Arkham 整理）— AHLCG 主设计师叙事哲学原话
   https://hallofarkham.com/2020/07/25/arkham-horror-lcg-interview-and-stream-resources/

### 二手资料（评论/分析，已交叉验证）

6. **Cultist Simulator GDC 2019 演讲**（Kennedy 本人）— 演讲存在但作者未读到文字稿
   https://www.youtube.com/watch?v=0pBvMIUk1nQ

7. **Emily Short: Beyond Branching**（叙事设计领域权威博客）— quality-based/salience-based narrative 的理论梳理
   https://emshort.blog/2016/04/12/beyond-branching-quality-based-and-salience-based-narrative-structures/

8. **知乎：隐秘而深邃-浅析密教模拟器的玩法叙事** — 中文社区对密教卡牌=万物符号的分析
   https://zhuanlan.zhihu.com/p/595041832

9. **AHLCG 评测（Zatu Games / SU&SD 等）** — 玩家侧确认 AHLCG 有 emergent stories
   https://zatu.com/blogs/reviews/arkham-horror-the-card-game-review

10. **苏丹与密教官方捆绑包报道** — 业界认可两者设计理念相似的硬证据
    https://cngame-fnscore.com/news-20260429-1038-9352

11. **Clint Hocking ludonarrative dissonance 概念文献综述**（Frédéric Seraphine 整理）— Hocking 2009 年原概念的溯源与演化
    https://www.fredericseraphine.com/index.php/2016/09/02/ludonarrative-dissonance-is-storytelling-about-reaching-harmony/

12. **Tracing Citizen Sleeper's circuitous vector from tabletop to hit video game**（Rascal News 对 Gareth Damian Martin 的访谈）— Citizen Sleeper 借鉴 Blades in the Dark 的设计师亲述
    https://www.rascal.news/tracing-citizen-sleepers-circuitous-vector-from-tabletop-to-hit-video-game/

13. **Setting Position & Effect**（Blades in the Dark 官方）— John Harper 对核心机制设计意图的原意
    https://bladesinthedark.com/setting-position-effect

14. **Glossary of Terms**（Indie Game Reading Club）— fiction first / fail forward 的术语定义
    https://indiegamereadingclub.com/glossary-of-terms/

15. **Apocalypse World**（Grokipedia 词条）— Baker 夫妇的设计影响与 PbtA 谱系
    https://grokipedia.com/page/Apocalypse_World

16. **Disco Elysium RPG System Analysis**（Game Design Thinking）— 极乐迪斯科机制的系统分析（24 技能、思维内阁、与 D&D 的对比）
    https://gamedesignthinking.com/disco-elysium-rpg-system-analysis/

17. **Disco Elysium - Rezzed 2018 Interview**（GameAnalytics 对 Kurvitz 的访谈）— Kurvitz 本人的设计自述（Planescape Torment 血统、8 人写作团队、"The Mind Shatterer"）
    https://www.gameanalytics.com/blog/disco-elysium-rezzed-2018-interview

18. **Disco Elysium | Pop & Locke Podcast** — 思维内阁作为 ludonarrative harmony 典型的评论界共识
    https://www.libertarianism.org/podcasts/pop-locke/disco-elysium

### 未读但已确认存在的资料（继续深挖的入口）

- Kennedy 的书 *Against Worldbuilding (and Other Provocations)*（2021，论文集）— 权威术语出处，超出免费网络资料范围
- MJ Newman Reddit AMA（r/arkhamhorrorlcg）— 反爬未读到全文，但 Hall of Arkham 已整理核心语录
- Kennedy GDC 2019 演讲文字稿 — 只确认演讲存在，未找到完整文字稿

---

## 十、这份文档的边界

**这份文档不是**：
- 不是命题通过的依据（按 `original-pitch.md` 纪律，命题评审只能由人在 Stage A/B 闸门正式做出）
- 不是完整的叙事卡牌设计理论（Kennedy 的书更权威，但超出本研究范围）
- 不是对苏丹复刻完整度的权威评估（复刻线的权威资料是反编译语料库）

**这份文档是**：
- 创意发散期的查证基线，防止后续会话重犯"凭印象下结论"的错误
- Stage A/B 评审时断言分类的参考来源
- 一份诚实记录了查证过程中**被推翻的论点**的账本，作为 track record 的一部分

**后续维护**：这份文档遵守 `original-pitch.md §3.5` 的断言分类纪律。任何新增断言必须带 `[已查证]` / `[推断]` / `[印象]` 标签，`[已查证]` 必须配来源 URL。
