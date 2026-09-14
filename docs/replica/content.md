# 原始内容与配置索引

旧两张配置大表来自有损data/config导出，已经退出裁判地位。以下完整记录保留为版本溯源，不能用于统计或实现。**当前配置入口为../../content/，统计与重复成员校验见研究快照和tools/export_design_research_snapshot.ps1 -Check。**

仪式定义、事件定义与单局实际出现必须区分；auto_begin不是auto_result，事件注册覆盖与默认启用也不是同一字段。所有规则判断回到原始JSONC、源码和运行产物。


## 证据模块

- [Original Rite Events](#e067)
- [Original Story Event Configs](#e068)

<a id="e067"></a>

## Original Rite Events

证据范围：`docs/replica/content.md#e067`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### Original Rite Events



Source: Faust-local-source/_unpack/data/config/rite/*.json. This is the card-slot rite/event surface used by entries like 5000001.



Total: 1495



| ID | Name | Location | AutoBegin | AutoResult | RoundNumber | WaitingRound | SlotConditions | OriginalConfigPath |

| --- | --- | --- | --- | --- | --- | --- | --- | --- |

| 5000001 | 治理家业 | 自宅:1 | 1 | 1 | 1 | 0 | s1: type=char, 贵族=1<br>s2: type=char<br>s3: type=item, 装潢=1<br>s4: type=item, !金币=1, any={"cost.消耗品=":1,"is":2001303,"空屋":1} | data/config/rite/5000001.json |

| 5000002 | 俺寻思 | 自宅:2 | 0 | 0 | 0 | 0 | s1: any | data/config/rite/5000002.json |

| 5000003 | 在家行淫 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=sudan, 纵欲=1<br>s2: 主角=1, type=char<br>s3: type=char, any={"!怪物":1,"is":2000433,"荆棘戒指":1}, !主角=1<br>s4: type=item, 激情=1, !is=2001138 | data/config/rite/5000003.json |

| 5000004 | 残忍的牺牲 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=sudan, 杀戮=1<br>s2: 主角=1, type=char<br>s3: 追随者=1, f:rare-s1.rare>==0, type=char, any={"!怪物":1,"荆棘戒指":1}, !主角=1 | data/config/rite/5000004.json |

| 5000005 | 稍加整修 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=sudan, 奢靡=1, rare==1<br>s2: type=item, cost.金币=3 | data/config/rite/5000005.json |

| 5000006 | 全面整修 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=sudan, 奢靡=1, rare==2<br>s2: type=item, cost.金币=5 | data/config/rite/5000006.json |

| 5000007 | 扩建 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=sudan, 奢靡=1, rare==3<br>s2: type=item, cost.金币=10 | data/config/rite/5000007.json |

| 5000008 | 大兴土木 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=sudan, 奢靡=1, rare==4<br>s2: type=item, cost.金币=20 | data/config/rite/5000008.json |

| 5000009 | 消除妻子的不满 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, 妻子=1<br>s2: any={"all":{"is":2000689,"cost.可堆叠=":1},"is":2001292}<br>s3: 主角=1, type=char<br>s4: is=2000083 | data/config/rite/5000009.json |

| 5000010 | 看书 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000010.json |

| 5000011 | 特殊的餐点 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, 正在进食=1, 食物=1<br>s2: type=char | data/config/rite/5000011.json |

| 5000012 | 匕首与弯刀 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000203, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000012.json |

| 5000013 | 古典摔跤 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000204, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":2,"is":2000123} | data/config/rite/5000013.json |

| 5000014 | 军用长矛指南 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000205, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000014.json |

| 5000015 | 马上竞技 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000206, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000015.json |

| 5000016 | 夜间的战斗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000207, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000016.json |

| 5000017 | 以弱胜强 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000208, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":4,"is":2000123} | data/config/rite/5000017.json |

| 5000018 | 体面 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000209, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000018.json |

| 5000019 | 圣训六十篇 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000210, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000019.json |

| 5000020 | 宫廷礼仪指南 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000211, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000020.json |

| 5000021 | 文书的工作 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000212, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000021.json |

| 5000022 | 艾娃日记 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000213, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000022.json |

| 5000023 | 相面术 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000214, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000023.json |

| 5000024 | 猎人故事集 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000215, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":2,"is":2000123} | data/config/rite/5000024.json |

| 5000025 | 大盗传奇 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000216, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":2,"is":2000123} | data/config/rite/5000025.json |

| 5000026 | 斥候训练手册 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000217, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000026.json |

| 5000027 | 捉贼人回忆录 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000218, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000027.json |

| 5000028 | 狗皮 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000219, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"魔力>=":1,"is":2000123} | data/config/rite/5000028.json |

| 5000029 | 歌声与寂静 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000220, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000029.json |

| 5000030 | 草药学入门 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000221, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000030.json |

| 5000031 | 地图与边疆 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000222, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000031.json |

| 5000032 | 游牧民的生活 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000223, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000032.json |

| 5000033 | 动物与植物图鉴 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000224, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":2,"is":2000123} | data/config/rite/5000033.json |

| 5000034 | 西行记 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000225, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":2,"is":2000123} | data/config/rite/5000034.json |

| 5000035 | 沙漠之书 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000226, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"魔力>=":1,"is":2000123} | data/config/rite/5000035.json |

| 5000036 | 健身手册 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000227, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000036.json |

| 5000037 | 士兵的训练 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000228, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000037.json |

| 5000038 | 勇武故事集 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000229, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":2,"is":2000123} | data/config/rite/5000038.json |

| 5000039 | 古代人的呼吸 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000230, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000039.json |

| 5000040 | 水银之血 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000231, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"魔力>=":1,"is":2000123} | data/config/rite/5000040.json |

| 5000041 | 贤者的话语 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000232, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000041.json |

| 5000042 | 思辨集 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000233, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000042.json |

| 5000043 | 方圆运算 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000234, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000043.json |

| 5000044 | 洞开的思想 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000235, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"魔力>=":1,"is":2000123} | data/config/rite/5000044.json |

| 5000045 | 如何取悦你的爱人 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000236, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000045.json |

| 5000046 | 四十七种优雅姿态 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000237, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000046.json |

| 5000047 | 神秘的精油 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000238, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000047.json |

| 5000048 | 面具的秘密 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000239, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000048.json |

| 5000049 | 密教的修行 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000240, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":4,"is":2000123} | data/config/rite/5000049.json |

| 5000050 | 第五元素 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000241, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":4,"is":2000123} | data/config/rite/5000050.json |

| 5000051 | 耳语之书 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000242, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000051.json |

| 5000052 | 蠕虫密卷 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000243, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"魔力>=":1,"is":2000123} | data/config/rite/5000052.json |

| 5000053 | 星空学徒 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000244, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"魔力>=":1,"is":2000123} | data/config/rite/5000053.json |

| 5000054 | 奥义书 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000245, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"all":{"智慧>=":5,"魔力>=":3},"is":2000123} | data/config/rite/5000054.json |

| 5000055 | 房屋出租 | 自宅:[2,12] | 0 | 0 | 0 | 7 | s1: is=2000005<br>s2: type=item, 空屋=1 | data/config/rite/5000055.json |

| 5000056 | 异国商人 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, 部落遗物=1, !已拥有=1, rare==2<br>s2: type=item, 部落遗物=1, !已拥有=1, rare==3<br>s3: type=item, 部落遗物=1, !已拥有=1, rare==4<br>s4: 租赁协议=1 | data/config/rite/5000056.json |

| 5000057 | 扩建挂毯长廊 | 奇珍:1 | 0 | 0 | 1 | 1 | s1: is=2000302<br>s2: type=item, cost.金币=7<br>s3: type=sudan, 奢靡=1, rare<==3 | data/config/rite/5000057.json |

| 5000058 | 扩建鳄鱼池 | 奇珍:4 | 0 | 0 | 1 | 1 | s1: is=2000304<br>s2: type=item, cost.金币=5<br>s3: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5000058.json |

| 5000059 | 扩建黄金猫爬架 | 奇珍:3 | 0 | 0 | 1 | 1 | s1: is=2000402<br>s2: type=item, cost.金币=9<br>s3: type=sudan, 奢靡=1, rare<==4 | data/config/rite/5000059.json |

| 5000060 | 扩建热气球升降场 | 奇珍:6 | 0 | 0 | 1 | 1 | s1: is=2000388<br>s2: type=item, cost.金币=9<br>s3: type=sudan, 奢靡=1, rare<==4 | data/config/rite/5000060.json |

| 5000061 | 扩建天文台 | 奇珍:8 | 0 | 0 | 1 | 1 | s1: is=2000380<br>s2: type=item, cost.金币=5<br>s3: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5000061.json |

| 5000062 | 珍奇之家 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 纳入收藏=1, is=2000302<br>s2: 纳入收藏=1, is=2000304<br>s3: 纳入收藏=1, is=2000402<br>s4: 纳入收藏=1, is=2000388 | data/config/rite/5000062.json |

| 5000063 | 召唤龙卷风 | 自宅:[2,12] | 0 | 0 | 3 | 1 | s1: type=item, is=2000318<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.金币=7 | data/config/rite/5000063.json |

| 5000064 | 打碎提灯 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000320<br>s2: type=char, 主角=1 | data/config/rite/5000064.json |

| 5000065 | 学术专著 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000538, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000065.json |

| 5000066 | 否认现实 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001209, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, !is=2000460<br>s3: type=item, is=2001208 | data/config/rite/5000066.json |

| 5000067 | 闯入后台 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, is=2001209, 正在阅读=1<br>s2: type=char, is=2000460<br>s3: type=char, is=2000001<br>s4: type=item, is=2001208 | data/config/rite/5000067.json |

| 5000100 | 珠宝设计 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, is=2000019<br>s2: type=item, cost.金币=5<br>s3: type=item, any={"!可堆叠":1,"cost.可堆叠":1}, !部队=1 | data/config/rite/5000100.json |

| 5000101 | 裁缝店 | 自宅:[2,12] | 0 | 0 | 2 | 1 | s1: type=char, is=2000459<br>s2: type=char, any={"!动物":1,"is":2000461}, !怪物=1, !妆扮=1<br>s3: type=item, !金币=1, any={"all":{"s2.主角":1,"is":2000680},"is":2001306}<br>s4: type=item, cost.金币=5 | data/config/rite/5000101.json |

| 5000102 | 舞乐之宴 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, is=2000129<br>s2: type=sudan, 奢靡=1, f:rare-s1.rare<==0<br>s3: type=item, any={"all":{"s1.rare=":4,"cost.金币":15}} | data/config/rite/5000102.json |

| 5000103 | 阿图娜尔的请求 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000129<br>s2: type=item, 装备=1, rare==3<br>s3: type=item, 装备=1, rare==2<br>s4: type=item, cost.金币=10 | data/config/rite/5000103.json |

| 5000104 | 阿图娜尔的请求 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000129<br>s2: type=item, 装备=1, rare==4<br>s3: type=item, 装备=1, rare==4<br>s4: type=item, cost.金币=15 | data/config/rite/5000104.json |

| 5000105 | 爱情诗 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000460<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000105.json |

| 5000106 | 史诗 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000460<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000106.json |

| 5000107 | 讽刺诗 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000460<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000107.json |

| 5000108 | 预言诗 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000460<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000108.json |

| 5000109 | 赃物商人 | 黑街:[1,9] | 0 | 0 | 1 | 0 | s1: type=item, is=2000162<br>s2: type=item, cost.金币=5 | data/config/rite/5000109.json |

| 5000110 | 有趣的情诗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000467<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000110.json |

| 5000111 | 很棒的情诗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000468<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000111.json |

| 5000112 | 不灭的情诗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000470<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000112.json |

| 5000113 | 伟大的爱情 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000472<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000113.json |

| 5000114 | 有趣的史诗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000473<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000114.json |

| 5000115 | 不凡的史诗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000474<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000115.json |

| 5000116 | 追忆过去荣光 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000475<br>s2: type=char, !贵族=1, !动物=1, !怪物=1 | data/config/rite/5000116.json |

| 5000117 | 伟大的史诗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000476<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000117.json |

| 5000118 | 历史洪流 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000478<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000118.json |

| 5000119 | 谐音谩骂 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000479<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000119.json |

| 5000120 | 精巧的讽刺 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000480<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000120.json |

| 5000121 | 挑战歌 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000481<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000121.json |

| 5000122 | 惊人的嘲讽 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000483<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000122.json |

| 5000123 | 魔幻诗歌 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000484<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000123.json |

| 5000124 | 诡异的幻听 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000485<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000124.json |

| 5000125 | 恐怖的回音 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000486<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000125.json |

| 5000126 | 黑暗根源 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000487<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000126.json |

| 5000127 | 伟大的黑暗 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000488<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000127.json |

| 5000128 | 小圆的日记 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2000576<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000128.json |

| 5000129 | 做好准备 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, 已装备=1, !is=2000461 | data/config/rite/5000129.json |

| 5000130 | 蠢妓女和活恶棍 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000547, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000130.json |

| 5000131 | 天文台 | 奇珍:8 | 1 | 0 | 7 | 0 | s1: is=2000380 | data/config/rite/5000131.json |

| 5000132 | 黄金鸟屋 | 奇珍:2 | 0 | 0 | 1 | 1 | s1: is=2000540<br>s2: type=item, cost.金币=5 | data/config/rite/5000132.json |

| 5000133 | 黄金鸟屋 | 奇珍:2 | 1 | 0 | 7 | 0 | s1: is=2000540<br>s2: type=char | data/config/rite/5000133.json |

| 5000134 | 鳄鱼池 | 奇珍:4 | 0 | 0 | 7 | 0 | s1: is=2000304<br>s2: type=item, cost.罪证==1 | data/config/rite/5000134.json |

| 5000135 | 热气球升降场 | 奇珍:6 | 0 | 0 | 7 | 0 | s1: is=2000388<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000135.json |

| 5000136 | 黄金猫爬架 | 奇珍:3 | 0 | 0 | 7 | 0 | s1: is=2000402<br>s2: any={"all":{"type":"item","cost.金币":3},"is":2000461} | data/config/rite/5000136.json |

| 5000137 | 挂毯长廊 | 奇珍:1 | 1 | 0 | 7 | 0 | s1: is=2000302 | data/config/rite/5000137.json |

| 5000138 | 被供奉的木雕 | 奇珍:7 | 0 | 0 | 1 | 1 | s1: is=2000601<br>s2: type=item, cost.金币=7<br>s3: type=sudan, 奢靡=1, f:rare-s1.rare<==0 | data/config/rite/5000138.json |

| 5000139 | 被供奉的木雕 | 奇珍:7 | 1 | 0 | 7 | 0 | s1: is=2000601 | data/config/rite/5000139.json |

| 5000140 | 群星的研究 | 神殿区:[2,10] | 0 | 0 | 3 | 1 | s1: 天象=1, 正在阅读=1<br>s2: type=char, 智慧>==5<br>s3: type=char, 智慧>==5 | data/config/rite/5000140.json |

| 5000141 | 承阳武士 | 奇珍:5 | 1 | 0 | 7 | 0 | s1: type=item, is=2000959 | data/config/rite/5000141.json |

| 5000142 | 老花园 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000797, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":3,"is":2000123} | data/config/rite/5000142.json |

| 5000143 | 列王纪 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000798, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000143.json |

| 5000144 | 等待太久 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000799, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000144.json |

| 5000145 | 不朽者之吻 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000800, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":4,"is":2000123} | data/config/rite/5000145.json |

| 5000146 | 雨林！雨林！ | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000801, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000146.json |

| 5000147 | 女主人的金拖鞋 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000802, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000147.json |

| 5000148 | 荒野集 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000803, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000148.json |

| 5000149 | 白鼬的宫廷 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000804, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000149.json |

| 5000150 | 弹球游戏 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000805, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000150.json |

| 5000151 | 哲百集 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000806, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":5,"is":2000123} | data/config/rite/5000151.json |

| 5000152 | 不要凝视群星 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000807, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000152.json |

| 5000153 | 蜘蛛的网 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000808, 正在阅读=1<br>s2: type=char, is=2000123 | data/config/rite/5000153.json |

| 5000154 | 维持家业 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000850, cost.信誉=[1,3]<br>s2: type=item, cost.金币=5 | data/config/rite/5000154.json |

| 5000155 | 石中火 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000856, 正在阅读=1<br>s2: type=char, is=2000123 | data/config/rite/5000155.json |

| 5000156 | 曲直迷思 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000857, 正在阅读=1<br>s2: type=char, is=2000123 | data/config/rite/5000156.json |

| 5000157 | 黄沙之战 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000855, 正在阅读=1<br>s2: type=char, is=2000123 | data/config/rite/5000157.json |

| 5000158 | 逆转时光 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, is=2000319<br>s2: type=sudan | data/config/rite/5000158.json |

| 5000159 | 梦中世界 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001060, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"智慧>=":5,"is":2000123} | data/config/rite/5000159.json |

| 5000160 | 君王的胸襟 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001146<br>s2: type=char, !is=2000461 | data/config/rite/5000160.json |

| 5000161 | 学会藏书室 | 自宅:[2,12] | 0 | 0 | 5 | 1 | s1: type=item, 馆藏=1<br>s2: type=item, 馆藏=1<br>s3: type=item, 馆藏=1<br>s4: type=item, cost.金币=3, s1=1 | data/config/rite/5000161.json |

| 5000162 | 贝姬夫人不见了 | 自宅:[2,12] | 1 | 0 | 3 | 0 | s1: is=2000461 | data/config/rite/5000162.json |

| 5000163 | 哲学の力量 | 自宅:[2,12] | 1 | 0 | 0 | 0 | s1: 主角=1, 黑暗幻想=1 | data/config/rite/5000163.json |

| 5000164 | 天牛之血 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1, is=2001170<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000164.json |

| 5000165 | 群山深处 | 野外:[9,14] | 0 | 0 | 7 | 7 | s1: type=char, 生存=5<br>s2: type=char, 体魄=5<br>s3: type=char, 智慧=5<br>s4: type=char, 魔力=5, 主角=1 | data/config/rite/5000165.json |

| 5000166 | 石之天平的研究 | 上城区:[1,6] | 0 | 0 | 5 | 1 | s1: is=2001154<br>s2: any={"is":2000022}, !s3=1<br>s3: any={"is":2000022}, !s2=1<br>s4: type=item, is=2000986, cost.可堆叠==1 | data/config/rite/5000166.json |

| 5000167 | 复活死者 | 野外:[1,14] | 0 | 0 | 1 | 1 | s1: 墓碑=1<br>s2: is=2001155<br>s3: is=2000001, 主角=1 | data/config/rite/5000167.json |

| 5000168 | 永生的允诺 | 野外:[1,14] | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: is=2001156 | data/config/rite/5000168.json |

| 5000201 | 驯服仪式 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001149<br>s2: type=char | data/config/rite/5000201.json |

| 5000202 | 诅咒解除 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 被驯服的人=1 | data/config/rite/5000202.json |

| 5000203 | 以凡人的方式 | 野外:[1,14] | 0 | 0 | 1 | 0 | s1: type=item, is=2000281<br>s2: type=char, is=2000352<br>s3: type=item, is=2000986, cost.可堆叠==1<br>s4: type=char, 主角=1 | data/config/rite/5000203.json |

| 5000204 | 忠贞不渝 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1, is=2001150<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000204.json |

| 5000205 | 荆棘与塔 | 野外:[9,14] | 0 | 0 | 3 | 1 | s1: type=char, any={"生存>=":4,"智慧>=":4}<br>s2: type=char, any={"隐匿>=":4,"体魄>=":4}<br>s3: type=char, any={"智慧>=":4,"魔力>=":4}<br>s4: type=char, any={"魅力>=":4,"社交>=":4} | data/config/rite/5000205.json |

| 5000206 | 异色花园 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, !追随者=1, !is=2000024, !食客=1, !主角=1<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, is=2001151 | data/config/rite/5000206.json |

| 5000301 | 诡异的镜子 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !主角=1, any={"男性":1,"女性":1} | data/config/rite/5000301.json |

| 5000302 | 映像 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, 小筹=1, 锁定小筹=1<br>s2: type=char | data/config/rite/5000302.json |

| 5000303 | 你的名字 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1, 锁定小筹=1<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000303.json |

| 5000304 | 见男人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, 男性=1, 激情=1 | data/config/rite/5000304.json |

| 5000305 | 见女人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, 女性=1, 激情=1 | data/config/rite/5000305.json |

| 5000306 | 见贵族 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, 贵族=1, 激情=1, any={"妻子":1,"is":2000352,"法拉杰":1} | data/config/rite/5000306.json |

| 5000307 | 欲望与爱情 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"妻子":1,"is":2000772,"法拉杰":1} | data/config/rite/5000307.json |

| 5000308 | 见……？ | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: any={"is":2000767,"type":"sudan"} | data/config/rite/5000308.json |

| 5000309 | 欲望与子嗣 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"妻子":1,"is":2000082,"all":{"法拉杰":1,"rare":4}} | data/config/rite/5000309.json |

| 5000310 | 欲望与代价 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000772} | data/config/rite/5000310.json |

| 5000311 | 弃用 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000311.json |

| 5000312 | 见贤者 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: any={"type":"char","all":{"type":"item","any":{"is":2000761}}} | data/config/rite/5000312.json |

| 5000313 | 一次纵欲的尝试 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !怪物=1, !动物=1, !食客=1, !is=2001182 | data/config/rite/5000313.json |

| 5000314 | 见聪明人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000314.json |

| 5000315 | 见坏人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000315.json |

| 5000316 | 见蠢人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000316.json |

| 5000317 | 囤积之乐 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, all={"!is":2000022,"!法拉杰":1}, !动物=1, !怪物=1 | data/config/rite/5000317.json |

| 5000318 | 花费之乐 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000318.json |

| 5000319 | 见讨厌钱的人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000319.json |

| 5000320 | 体验品位 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000019,"妻子":1,"主角":1} | data/config/rite/5000320.json |

| 5000321 | 见证得利 | 自宅:[2,12] | 0 | 0 | 5 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000014,"主角":1}<br>s3: type=item, cost.金币==5 | data/config/rite/5000321.json |

| 5000322 | 浪费与浪漫 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"all":{"is":2000021,"!密教徒":1},"is":2000352,"主角":1}<br>s3: type=item, cost.金币==5 | data/config/rite/5000322.json |

| 5000323 | 天降横财 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, 命运的羁绊=1<br>s3: type=item, cost.金币=[10,50] | data/config/rite/5000323.json |

| 5000324 | 见勇士 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000292,"战斗>=":6}, !怪物=1, !动物=1 | data/config/rite/5000324.json |

| 5000325 | 见战利品 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000369,"主角":1} | data/config/rite/5000325.json |

| 5000326 | 见证荣誉 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: any={"is":2000065,"火焰大王":1,"主角":1}, type=char, !怪物=1, !动物=1 | data/config/rite/5000326.json |

| 5000327 | 有理想的人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"法拉杰":1,"is":2000350,"all":{"主角":1,"!is":2000861}} | data/config/rite/5000327.json |

| 5000328 | 见奴隶 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000114,"主角":1} | data/config/rite/5000328.json |

| 5000329 | 谋逆的思想 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: any={"is":2010016} | data/config/rite/5000329.json |

| 5000330 | 见幸存者 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000013,"主角":1} | data/config/rite/5000330.json |

| 5000331 | 承担责任 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: any={"is":2000195,"主角":1} | data/config/rite/5000331.json |

| 5000332 | 一次征服的行为 | 野外:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, 小筹=1<br>s2: is=2001186, 小筹征服=1<br>s3: is=2001187, 小筹征服=1<br>s4: is=2001188, 小筹征服=1 | data/config/rite/5000332.json |

| 5000333 | 见得利者 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"妻子":1,"is":2000056,"法拉杰":1} | data/config/rite/5000333.json |

| 5000334 | 见无形之刃 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000460} | data/config/rite/5000334.json |

| 5000335 | 杀戮的诀窍 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000292} | data/config/rite/5000335.json |

| 5000336 | 死如微尘 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"is":2000197} | data/config/rite/5000336.json |

| 5000337 | 生命与期盼 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"妻子":1,"is":2000005} | data/config/rite/5000337.json |

| 5000338 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000338.json |

| 5000339 | 生命的本能 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, any={"all":{"is":2000371,"!侧室":1},"is":2000369,"法拉杰":1} | data/config/rite/5000339.json |

| 5000340 | 生死之惧 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000340.json |

| 5000341 | 如果有来生 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: any={"火焰大王":1,"is":2000461,"!动物":1}, type=char, !怪物=1 | data/config/rite/5000341.json |

| 5000342 | 死亡轮回 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 小筹=1<br>s2: any={"type":"char"}, !is=2000461 | data/config/rite/5000342.json |

| 5000343 | 金币巡回 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000343.json |

| 5000344 | 心胜于物 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000344.json |

| 5000345 | 有趣的人类 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000345.json |

| 5000346 | 书库辖员 | 奇珍:13 | 1 | 0 | 7 | 0 | s1: type=char, 小筹=1, 锁定小筹=1 | data/config/rite/5000346.json |

| 5000347 | 远方的歌 | 奇珍:14 | 1 | 0 | 7 | 0 | s1: type=char, 小筹=1, 锁定小筹=1 | data/config/rite/5000347.json |

| 5000348 | 万和之弦 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000348.json |

| 5000349 | 镜之冠冕 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000349.json |

| 5000350 | 以人为镜 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000350.json |

| 5000351 | 废弃 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 小筹=1 | data/config/rite/5000351.json |

| 5000352 | 镜子的援军 | 野外:[1,6] | 0 | 0 | 0 | 1 | s1: type=char, 小筹=1, 锁定小筹=1<br>s2: type=item, 部队=1<br>s3: type=char, 主角=1 | data/config/rite/5000352.json |

| 5000353 | 此岸彼岸 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001189, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"is":2000123,"智慧<":3} | data/config/rite/5000353.json |

| 5000501 | 阴森的宅邸 | 野外:9 | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=char<br>s3: any={"all":{"type":"sudan","杀戮":1}}<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000501.json |

| 5000502 | 未解的凶案 | 野外:8 | 0 | 0 | 1 | 0 | s1: type=char, any={"追随者":1,"主角":1}<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000502.json |

| 5000503 | 如何安息 | 野外:9 | 0 | 0 | 1 | 0 | s1: type=char<br>s2: any={"is":2000187} | data/config/rite/5000503.json |

| 5000504 | 幕后真凶 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: is=2000164<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: is=2000137 | data/config/rite/5000504.json |

| 5000505 | 宫廷处刑 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000164<br>s2: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5000505.json |

| 5000506 | 以神的名义 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: any={"is":2000384,"type":"char"}, !主角=1, !怪物=1, !动物=1<br>s2: any={"type":"char","is":2000728}, !动物=1, !怪物=1 | data/config/rite/5000506.json |

| 5000507 | 夜的栖身地 | 黑街:[1,5] | 0 | 0 | 1 | 0 | s1: is=2000022<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, any={"cost.消耗品=":1,"!金币":1,"is":2000187} | data/config/rite/5000507.json |

| 5000508 | 神圣的襄助 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: any={"all":{"is":2001071,"锁定祭司":1}}<br>s2: is=2000185<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000508.json |

| 5000509 | 邪恶的线索 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: is=2000185<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000509.json |

| 5000511 | 无法追溯的罪行 | 黑街:[1,5] | 0 | 0 | 1 | 0 | s1: is=2000137 | data/config/rite/5000511.json |

| 5000512 | 为她们复仇 | 上城区:[7,12] | 1 | 0 | 1 | 0 | s1: 决斗标记=1, is=2000164<br>s2: type=char, 决斗标记=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000512.json |

| 5000513 | 黑暗的召唤 | 黑街:[1,5] | 1 | 0 | 1 | 0 | s1: is=2000185<br>s2: type=char, 主角=1<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000513.json |

| 5000514 | 拜铃耶 | 黑街:[1,5] | 1 | 0 | 1 | 0 | s1: is=2000022<br>s2: type=char, 主角=1<br>s3: type=sudan, any={"杀戮":1,"纵欲":1}, f:rare-s1.rare<==0 | data/config/rite/5000514.json |

| 5000515 | 白蜜琥珀宝珠 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000187<br>s2: type=char, 诅咒=1 | data/config/rite/5000515.json |

| 5000520 | 失落的珍宝 | 宫廷:[2,6] | 0 | 0 | 0 | 14 | s1: is=2000280 | data/config/rite/5000520.json |

| 5000521 | 安苏亚妃来访 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000008<br>s2: type=char, any={"主角":1,"妻子":1}, !s3=1<br>s3: type=char, any={"主角":1,"妻子":1}, !s2=1<br>s4: type=item, 思潮=1, any={"is":2000541} | data/config/rite/5000521.json |

| 5000522 | 安苏亚的请求I | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: is=2000008<br>s2: is=2000287<br>s3: type=item, cost.金币=10<br>s4: type=char | data/config/rite/5000522.json |

| 5000523 | 安苏亚的请求 | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: is=2000008<br>s2: is=2000287<br>s3: type=item, cost.情报>==3, rare>==2<br>s4: type=char | data/config/rite/5000523.json |

| 5000524 | 安苏亚的请求 | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: is=2000008<br>s2: is=2000287<br>s3: type=char<br>s4: any={"is":2000283,"cost.金币":10} | data/config/rite/5000524.json |

| 5000525 | 静待时机 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000288<br>s2: is=2000287<br>s3: any={"is":2000913}<br>s4: type=char | data/config/rite/5000525.json |

| 5000526 | 复仇的伊始 | 宫廷:[2,6] | 1 | 0 | 3 | 0 | s1: is=2000008<br>s2: is=2000024 | data/config/rite/5000526.json |

| 5000527 | 玉碎珠沉 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000008 | data/config/rite/5000527.json |

| 5000528 | 弑君（废弃） | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000024<br>s2: is=2000012, !追随者=1<br>s3: type=char, 反对>==1, !追随者=1<br>s4: type=char, 反对>==1, !追随者=1 | data/config/rite/5000528.json |

| 5000529 | 弑君计划（废弃） | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000289, 开启=1<br>s2: type=item, is=2000281<br>s3: 主角=1, type=char<br>s4: type=char | data/config/rite/5000529.json |

| 5000531 | 搜寻提尔亚遗物 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000005<br>s2: type=item, cost.金币=10<br>s3: type=char<br>s4: type=item, 思潮=1 | data/config/rite/5000531.json |

| 5000532 | 弑君计划（废弃） | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000289, 开启=1<br>s2: type=item, is=2000281<br>s3: 主角=1, type=char<br>s4: type=char | data/config/rite/5000532.json |

| 5000550 | 爱的伪证 | 宫廷:[2,6] | 0 | 0 | 0 | 7 | s1: is=2000290 | data/config/rite/5000550.json |

| 5000551 | 勇武的证明 | 野外:[9,14] | 0 | 0 | 0 | 7 | s1: 主角=1, type=char<br>s2: type=item, cost.消耗品==1 | data/config/rite/5000551.json |

| 5000552 | 萨达尔尼来访 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000009<br>s2: type=char, any={"主角":1,"妻子":1}, !s3=1<br>s3: type=char, any={"主角":1,"妻子":1}, !s2=1 | data/config/rite/5000552.json |

| 5000553 | 欢愉的代价 | 宫廷:[2,6] | 0 | 0 | 1 | 1 | s1: is=2000024<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, rare==4 | data/config/rite/5000553.json |

| 5000554 | 无名的暗杀 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000342<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000554.json |

| 5000555 | 无名的暗杀 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000342<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000555.json |

| 5000556 | 无名的暗杀 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000342<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000556.json |

| 5000557 | 无名的暗杀 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000342<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000557.json |

| 5000558 | 保守秘密 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000176<br>s2: is=2000174, !s3=1<br>s3: is=2000174, !s2=1 | data/config/rite/5000558.json |

| 5000559 | 潜入篡改 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: type=char, any={"主角":1,"追随者":1}<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000559.json |

| 5000560 | 贿赂主管 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000291<br>s2: type=item, cost.金币=15 | data/config/rite/5000560.json |

| 5000561 | 消除隐患 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000176<br>s2: is=2000285 | data/config/rite/5000561.json |

| 5000562 | 真正的报偿 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000009<br>s2: type=char, any={"主角":1,"is":2000019}<br>s3: any={"is":2000283,"cost.金币":10}<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000562.json |

| 5000563 | 貌合神离 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000009<br>s2: type=char, 主角=1 | data/config/rite/5000563.json |

| 5000564 | 私情与背叛（废弃） | 野外:[9,14] | 0 | 0 | 0 | 0 | s1: is=2000012<br>s2: type=char, 主角=1 | data/config/rite/5000564.json |

| 5000565 | 不留后患 | 野外:[9,14] | 0 | 0 | 1 | 0 | s1: is=2000012<br>s2: type=char<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5000565.json |

| 5000566 | 一线生机 | 野外:[9,14] | 0 | 0 | 1 | 0 | s1: is=2000012<br>s2: type=char<br>s3: any={"is":2000412}<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000566.json |

| 5000567 | 最后的疯狂 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000176<br>s2: any={"is":2000177} | data/config/rite/5000567.json |

| 5000568 | 欢愉的代价 | 宫廷:[2,6] | 0 | 0 | 1 | 1 | s1: is=2000024<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, rare==4 | data/config/rite/5000568.json |

| 5000569 | 金子般的女人 | 宫廷:[2,6] | 0 | 0 | 1 | 7 | s1: is=2000010<br>s2: type=item, cost.金币=30<br>s3: type=item, 装备=1, 魅力=3<br>s4: type=item, 奇珍=1 | data/config/rite/5000569.json |

| 5000570 | 迎接莎姬 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000010<br>s2: type=char | data/config/rite/5000570.json |

| 5000571 | 欲望或野心 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000010<br>s2: type=char, 主角=1, !s3=1<br>s3: type=char, 主角=1, !s2=1<br>s4: any={"is":2000848} | data/config/rite/5000571.json |

| 5000572 | 黄金体验 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000010<br>s2: type=char, 主角=1<br>s3: type=item, is=2000326, cost.疯狂=1 | data/config/rite/5000572.json |

| 5000573 | 净事阉奴 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: type=char, any={"is":2000019,"隐匿":5}<br>s2: type=item, cost.金币=8<br>s3: type=char, !贵族=1, 社交=5<br>s4: type=item, is=2000416, cost.情报=1 | data/config/rite/5000573.json |

| 5000574 | 苏丹的私生活 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: type=char, any={"is":2000019,"隐匿":5}<br>s2: type=item, cost.金币=8<br>s3: type=char, !贵族=1, 社交=5<br>s4: type=item, is=2000416, cost.情报=1 | data/config/rite/5000574.json |

| 5000575 | 书店偶遇 | 商业区:[4,5] | 0 | 0 | 1 | 3 | s1: type=char, is=2001020<br>s2: type=char<br>s3: type=item, cost.金币=5<br>s4: type=item, cost.消耗品=1, !金币=1 | data/config/rite/5000575.json |

| 5000576 | 莎姬的噩梦 | 宫廷:[7,10] | 0 | 0 | 1 | 1 | s1: is=2001019<br>s2: any={"is":2000172,"all":{"is":2000913,"rare<":4}}<br>s3: any={"is":2000021,"all":{"is":2000913,"rare=":4}} | data/config/rite/5000576.json |

| 5000577 | 苏丹的套子 | 商业区:[10,19] | 0 | 0 | 3 | 0 | s1: type=char, 生存>==5<br>s2: type=char, 智慧>==5<br>s3: type=char, 社交>==5<br>s4: type=item, cost.金币=5 | data/config/rite/5000577.json |

| 5000578 | 狂乱的圣主 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: is=2001023<br>s2: type=char, any={"追随者":1,"主角":1}<br>s3: type=char, !is=2000024, 贵族=1<br>s4: is=2000545 | data/config/rite/5000578.json |

| 5000579 | 星神的契约 | 宫廷:[7,10] | 0 | 0 | 1 | 1 | s1: is=2001019<br>s2: is=2001021<br>s3: type=char, !食客=1<br>s4: type=char | data/config/rite/5000579.json |

| 5000580 | 向星星许愿 | 野外:[1,6] | 0 | 0 | 1 | 5 | s1: type=char, 你的圣主=1<br>s2: any={"is":2000848,"type":"sudan"} | data/config/rite/5000580.json |

| 5000581 | 猎神 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: is=2001019<br>s2: any={"type":"char","is":2001021}<br>s3: type=char<br>s4: type=char | data/config/rite/5000581.json |

| 5000582 | 焚星 | 神殿区:[2,10] | 0 | 0 | 5 | 3 | s1: is=2001019<br>s2: any={"天象":1,"all":{"type":"char","智慧>=":5}}<br>s3: any={"天象":1,"all":{"type":"char","智慧>=":5}}<br>s4: any={"天象":1,"all":{"type":"char","智慧>=":5}} | data/config/rite/5000582.json |

| 5000583 | 星之衰 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2001031 | data/config/rite/5000583.json |

| 5000584 | 黄金体验 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000010<br>s2: type=char, 主角=1<br>s3: type=item, is=2000326, cost.疯狂=1 | data/config/rite/5000584.json |

| 5000600 | 城外的骚乱 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: is=2000062<br>s2: 主角=1, type=char<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000600.json |

| 5000601 | 袭击者的巢穴 | 野外:[9,14] | 0 | 0 | 1 | 7 | s1: is=2000062<br>s2: type=char, 主角=1<br>s3: !主角=1, type=char<br>s4: !主角=1, type=char | data/config/rite/5000601.json |

| 5000602 | 酒庄的归属 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000314<br>s2: type=char | data/config/rite/5000602.json |

| 5000603 | 致命的邀约 | 上城区:[7,12] | 0 | 0 | 1 | 1 | s1: is=2000062<br>s2: 主角=1, type=char<br>s3: is=2000316, type=item | data/config/rite/5000603.json |

| 5000604 | 刺杀 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 主角=1, type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000604.json |

| 5000605 | 弑兄 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: is=2000314<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5000605.json |

| 5000606 | 刺杀 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 主角=1, type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000606.json |

| 5000607 | 酒庄主人再次造访 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000314<br>s2: type=char<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5000607.json |

| 5000608 | 刺杀 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 主角=1, type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000608.json |

| 5000610 | 少年的请求 | 自宅:[2,12] | 0 | 0 | 0 | 3 | s1: is=2000063<br>s2: type=char | data/config/rite/5000610.json |

| 5000611 | 武术指导 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000611.json |

| 5000612 | 唆使犯罪 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000612.json |

| 5000613 | 狩猎实战 | 野外:[1,6] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000613.json |

| 5000614 | 扎齐伊的请求 | 自宅:[2,12] | 0 | 0 | 0 | 3 | s1: is=2000063<br>s2: type=char, !is=2000063 | data/config/rite/5000614.json |

| 5000615 | 社交教习 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000615.json |

| 5000616 | 社交教习 | 上城区:[1,6] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000616.json |

| 5000617 | 社交教习 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000617.json |

| 5000618 | 扎齐伊的请求 | 自宅:[2,12] | 0 | 0 | 0 | 3 | s1: is=2000063<br>s2: type=char, !is=2000063 | data/config/rite/5000618.json |

| 5000619 | 最后的解惑 | 商业区:[4,5] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063 | data/config/rite/5000619.json |

| 5000620 | 最后的解惑 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063 | data/config/rite/5000620.json |

| 5000621 | 最后的解惑 | 黑街:[2,5] | 0 | 0 | 1 | 0 | s1: is=2000063<br>s2: type=char, !is=2000063 | data/config/rite/5000621.json |

| 5000622 | 未亡人的造访 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000062<br>s2: type=char, 主角=1 | data/config/rite/5000622.json |

| 5000623 | 年轻望族的仰慕 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: is=2000063<br>s2: type=item, 思潮=1 | data/config/rite/5000623.json |

| 5000624 | 寡妇的友谊 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: is=2000062<br>s2: type=item, 思潮=1 | data/config/rite/5000624.json |

| 5000630 | 受伤的白犀牛 | 野外:[1,6] | 0 | 0 | 1 | 0 | s1: is=2000328<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000630.json |

| 5000631 | 阿迪莱的战书 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: is=2000061<br>s2: type=char | data/config/rite/5000631.json |

| 5000632 | 王狮猎场 | 野外:[1,6] | 0 | 0 | 1 | 3 | s1: is=2000061<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: any={"is":2001139,"all":{"type":"item","cost.金币":10}} | data/config/rite/5000632.json |

| 5000633 | 处置阿迪莱 | 野外:[1,6] | 0 | 0 | 1 | 0 | s1: is=2000061<br>s2: any={"all":{"type":"sudan","纵欲":1,"f:rare-s1.rare<=":0},"is":2001139} | data/config/rite/5000633.json |

| 5000634 | 一件礼物，一个诅咒 | 上城区:[7,12] | 0 | 0 | 0 | 0 | s1: type=char, 主角=1 | data/config/rite/5000634.json |

| 5000635 | 少女审视自己 | 上城区:[7,12] | 1 | 0 | 0 | 0 | s1: is=2000061 | data/config/rite/5000635.json |

| 5000636 | 少女审视自己 | 上城区:[7,12] | 1 | 0 | 0 | 0 | s1: is=2000061 | data/config/rite/5000636.json |

| 5000637 | 勇行 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: is=2000332<br>s2: is=2000061<br>s3: type=char<br>s4: type=char | data/config/rite/5000637.json |

| 5000638 | 女战士的挑战 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: is=2000061<br>s2: type=char<br>s3: type=item, cost.消耗品==1 | data/config/rite/5000638.json |

| 5000639 | 处置阿迪莱 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000061<br>s2: any={"all":{"type":"sudan","纵欲":1,"f:rare-s1.rare<=":0}} | data/config/rite/5000639.json |

| 5000640 | 探访奈费勒 | 上城区:[7,12] | 0 | 0 | 0 | 14 | s1: is=2000312<br>s2: type=char, 主角=1<br>s3: type=item, 读物=1, rare>==2 | data/config/rite/5000640.json |

| 5000641 | 密会 | 上城区:[7,12] | 0 | 0 | 1 | 14 | s1: 主角=1, type=char<br>s2: type=item, is=2000753<br>s3: is=2000312<br>s4: type=sudan, f:rare-s3.rare<==0, any={"杀戮":1,"纵欲":1} | data/config/rite/5000641.json |

| 5000650 | 虚荣作祟 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: is=2000055<br>s2: 主角=1, type=char<br>s3: type=sudan, f:rare-s1.rare<==0, any={"纵欲":1,"杀戮":1} | data/config/rite/5000650.json |

| 5000651 | 血的妆造 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: is=2000055<br>s2: is=2000115<br>s3: 主角=1, type=char<br>s4: type=sudan, rare<==3, 杀戮=1 | data/config/rite/5000651.json |

| 5000652 | 黄金的赠礼 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: is=2000055<br>s2: 主角=1, type=char<br>s3: type=item, rare==4, any={"奇珍":1,"饰品":1}, !is=2001022<br>s4: any={"all":{"rare=":3,"type":"sudan","杀戮":1}} | data/config/rite/5000652.json |

| 5000653 | 迫不及待 | 上城区:[7,12] | 0 | 0 | 0 | 3 | s1: is=2000055<br>s2: 主角=1, type=char<br>s3: type=item, 思潮=1 | data/config/rite/5000653.json |

| 5000654 | 她的丈夫 | 上城区:[7,12] | 0 | 0 | 1 | 1 | s1: is=2000055<br>s2: is=2000327<br>s3: 主角=1, type=char<br>s4: type=sudan, f:rare-s1.rare<==0, 杀戮=1 | data/config/rite/5000654.json |

| 5000660 | 探索未知绿洲 | 野外:[1,6] | 0 | 0 | 3 | 3 | s1: is=2000069<br>s2: type=item, cost.金币=3<br>s3: type=char<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000660.json |

| 5000661 | 暗潮涌动 | 野外:[9,14] | 1 | 0 | 3 | 0 | s1: is=2000364<br>s2: type=sudan, 征服=1, f:rare-s1.rare<==0 | data/config/rite/5000661.json |

| 5000662 | 一个人的绝地探索 | 野外:[9,14] | 1 | 0 | 3 | 0 | s1: is=2000069 | data/config/rite/5000662.json |

| 5000663 | 绝地探索 | 野外:[1,6] | 1 | 0 | 5 | 0 | s1: is=2000069<br>s2: type=char<br>s3: type=item, cost.消耗品==1 | data/config/rite/5000663.json |

| 5000664 | 暗潮涌动 | 野外:[9,14] | 1 | 0 | 3 | 0 | s1: is=2000365<br>s2: type=sudan, 征服=1, f:rare-s1.rare<==0 | data/config/rite/5000664.json |

| 5000665 | 麦娜尔的道别 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000069<br>s2: type=item, cost.金币=5 | data/config/rite/5000665.json |

| 5000666 | 远方的乐土 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=item, cost.金币==1 | data/config/rite/5000666.json |

| 5000667 | 苏丹的捉弄 | 宫廷:[2,6] | 0 | 0 | 1 | 7 | s1: type=char, 质子=1, is=2000350<br>s2: type=char, 主角=1<br>s3: type=sudan, f:rare-s1.rare<==0 | data/config/rite/5000667.json |

| 5000668 | 修建暗渠 | 野外:[9,14] | 0 | 0 | 7 | 0 | s1: type=char<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.金币=8 | data/config/rite/5000668.json |

| 5000669 | 祈雨献祭 | 野外:[9,14] | 0 | 0 | 3 | 0 | s1: type=char, 黑暗知识=1<br>s2: type=char<br>s3: any={"type":"char","任意处置":1}, !主角=1, !怪物=1, !动物=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000669.json |

| 5000670 | 兴修宫殿 | 上城区:[7,12] | 0 | 0 | 3 | 7 | s1: type=item, cost.金币=10 | data/config/rite/5000670.json |

| 5000672 | 严厉刑罚 | 野外:[9,14] | 0 | 0 | 3 | 0 | s1: type=char, 智慧=5<br>s2: type=char, 体魄=5 | data/config/rite/5000672.json |

| 5000673 | 仁慈的许诺 | 野外:[9,14] | 0 | 0 | 3 | 0 | s1: type=char, 魅力=5<br>s2: type=item, cost.金币=5 | data/config/rite/5000673.json |

| 5000674 | 促成谈判 | 野外:[9,14] | 0 | 0 | 3 | 0 | s1: type=char, 社交=6<br>s2: type=item, cost.金币=6 | data/config/rite/5000674.json |

| 5000675 | 强硬驱逐 | 野外:[9,14] | 0 | 0 | 3 | 0 | s1: type=char, 战斗=6<br>s2: type=char, 战斗=6 | data/config/rite/5000675.json |

| 5000676 | 核查漏洞 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: type=char, 智慧=8<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000676.json |

| 5000677 | 神圣审判 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: type=char, any={"魔力":8,"正教的信徒":1} | data/config/rite/5000677.json |

| 5000678 | 苏丹的质询 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=item, cost.金币=8 | data/config/rite/5000678.json |

| 5000679 | 诸地暴乱 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: type=item, is=2000377<br>s2: any={"all":{"type":"item","is":2000172}}<br>s3: type=char<br>s4: type=char | data/config/rite/5000679.json |

| 5000680 | 法尔达克的友谊 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000350, 质子=1<br>s2: type=item, 思潮=1 | data/config/rite/5000680.json |

| 5000681 | 修建暗渠 | 野外:[9,14] | 0 | 0 | 7 | 0 | s1: type=char<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.金币=8 | data/config/rite/5000681.json |

| 5000682 | 祈雨献祭 | 野外:[9,14] | 0 | 0 | 3 | 0 | s1: type=char, 黑暗知识=1<br>s2: type=char<br>s3: any={"type":"char","任意处置":1}, !主角=1, !怪物=1, !动物=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000682.json |

| 5000683 | 悄无声息的离去 | 野外:[9,14] | 1 | 0 | 3 | 0 | s1: is=2000069 | data/config/rite/5000683.json |

| 5000684 | 以身试刃 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000056<br>s2: type=sudan, 杀戮=1, rare<==3 | data/config/rite/5000684.json |

| 5000685 | 实地走访 | 上城区:[1,6] | 0 | 0 | 7 | 3 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000685.json |

| 5000686 | 初步调查 | 野外:[9,14] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=char<br>s3: type=item, cost.金币=3<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000686.json |

| 5000687 | 深入调查 | 野外:[9,14] | 0 | 0 | 1 | 0 | s1: type=char, is=2000056<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000687.json |

| 5000688 | 收服盖斯 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000056<br>s2: type=item, any={"is":2000412} | data/config/rite/5000688.json |

| 5000701 | 冒险的冲动（废弃） | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000054<br>s2: type=char, !s3=1, !s4=1<br>s3: type=char, !s2=1, !s4=1<br>s4: type=char, !s2=1, !s3=1 | data/config/rite/5000701.json |

| 5000702 | 无尽黄沙 | 野外:[9,14] | 0 | 0 | 7 | 2 | s1: is=2000054, counter.7000228>==1<br>s2: type=char, 生存>==4<br>s3: type=char, 战斗>==4<br>s4: type=char, 智慧>==4 | data/config/rite/5000702.json |

| 5000703 | 狂风峡谷 | 野外:[9,14] | 0 | 0 | 3 | 2 | s1: is=2000054, counter.7000228>==1<br>s2: type=char, 魔力>==5<br>s3: type=char, 弓箭=1<br>s4: type=char, 生存>==4 | data/config/rite/5000703.json |

| 5000704 | 暗影神殿 | 野外:[9,14] | 0 | 0 | 3 | 2 | s1: is=2000054, counter.7000228>==1<br>s2: any={"type":"char","任意处置":1}, !怪物=1, !动物=1<br>s3: type=char<br>s4: type=char | data/config/rite/5000704.json |

| 5000705 | 妖精森林 | 野外:[9,14] | 0 | 0 | 3 | 2 | s1: is=2000054, counter.7000228>==1<br>s2: type=char, 生存>==4<br>s3: type=char, 战斗>==4<br>s4: type=char, 智慧>==4 | data/config/rite/5000705.json |

| 5000706 | 哲巴尔的友谊 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000054<br>s2: type=item, 思潮=1 | data/config/rite/5000706.json |

| 5000707 | 末日火山（废弃） | 野外:[9,14] | 0 | 0 | 0 | 0 | s1: is=2000317<br>s2: is=2000318<br>s3: is=2000319<br>s4: is=2000320 | data/config/rite/5000707.json |

| 5000708 | 火山魔龙 | 野外:[9,14] | 0 | 0 | 0 | 10 | s1: type=char<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5000708.json |

| 5000709 | 刀剑问答 | 自宅:[2,6] | 0 | 0 | 1 | 2 | s1: is=2000054<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000709.json |

| 5000710 | 护花使者 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000064<br>s2: type=char, 贵族=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000710.json |

| 5000711 | 足以传世的画像 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000064<br>s2: is=2000333 | data/config/rite/5000711.json |

| 5000712 | 一桩趣事 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000064<br>s2: type=char, any={"主角":1,"妻子":1} | data/config/rite/5000712.json |

| 5000713 | 靠不住的盟友 | 上城区:[1,6] | 1 | 1 | 1 | 0 | s1: is=2000064<br>s2: any={"all":{"type":"item","is":2000767}}<br>s3: type=sudan, f:rare-s1.rare<==0 | data/config/rite/5000713.json |

| 5000714 | 花花公子的收服（废弃） | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000064<br>s2: type=item, 思潮=1 | data/config/rite/5000714.json |

| 5000715 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char | data/config/rite/5000715.json |

| 5000716 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char | data/config/rite/5000716.json |

| 5000717 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char | data/config/rite/5000717.json |

| 5000718 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char | data/config/rite/5000718.json |

| 5000719 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char | data/config/rite/5000719.json |

| 5000720 | 宰相的召见 | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: is=2000349<br>s2: type=char, 主角=1 | data/config/rite/5000720.json |

| 5000721 | 无故缺勤的臣子 | 上城区:[1,6] | 0 | 0 | 1 | 5 | s1: is=2000356, 锁定穆尔台兹=1<br>s2: type=char<br>s3: type=item, cost.金币=3 | data/config/rite/5000721.json |

| 5000722 | 回报宰相 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, is=2000373 | data/config/rite/5000722.json |

| 5000723 | 宰相的召见 | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: is=2000349<br>s2: type=char, 主角=1 | data/config/rite/5000723.json |

| 5000724 | 虫豸怎敢 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: is=2000356, 锁定穆尔台兹=1<br>s2: type=char | data/config/rite/5000724.json |

| 5000725 | 终结苦痛 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: is=2000356, 锁定穆尔台兹=1<br>s2: type=char<br>s3: type=sudan, rare<==2, 杀戮=1 | data/config/rite/5000725.json |

| 5000726 | 回报宰相 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, any={"is":2000375} | data/config/rite/5000726.json |

| 5000727 | 放过他 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: is=2000356, 锁定穆尔台兹=1<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000727.json |

| 5000728 | 宰相的召见 | 宫廷:[2,6] | 1 | 0 | 0 | 0 | s1: is=2000349<br>s2: type=char | data/config/rite/5000728.json |

| 5000729 | 散尽家财 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: is=2000062<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000729.json |

| 5000730 | 回报宰相 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=10 | data/config/rite/5000730.json |

| 5000731 | 项目投资 | 上城区:[1,6] | 0 | 0 | 4 | 4 | s1: is=2000352<br>s2: type=char<br>s3: type=item, cost.金币=[5,10], 金币>==5<br>s4: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5000731.json |

| 5000732 | 项目投资·二 | 上城区:[1,6] | 0 | 0 | 4 | 4 | s1: is=2000352<br>s2: type=char<br>s3: type=item, cost.金币=[5,10], 金币>==5<br>s4: type=sudan, rare<==2, any={"奢靡":1,"杀戮":1} | data/config/rite/5000732.json |

| 5000733 | 收服玛希尔 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000352 | data/config/rite/5000733.json |

| 5000734 | 长期研究 | 上城区:[1,6] | 0 | 0 | 7 | 1 | s1: is=2000352<br>s2: type=char<br>s3: type=item, cost.金币=[5,20]<br>s4: any={"all":{"type":"item","is":2001024}} | data/config/rite/5000734.json |

| 5000735 | 火山魔龙-决战 | 野外:[9,14] | 1 | 0 | 1 | 0 | s1: is=2000332<br>s2: type=char, 屠龙者=1<br>s3: type=char, 屠龙者=1<br>s4: type=char, 屠龙者=1 | data/config/rite/5000735.json |

| 5000736 | 踏入黑夜（废弃） | 黑街:[1,9] | 0 | 0 | 1 | 7 | s1: is=2000022<br>s2: type=char, 主角=1<br>s3: any={"type":"char","任意处置":1}, !怪物=1, !动物=1<br>s4: type=sudan, any={"杀戮":1,"纵欲":1}, f:rare-s3.rare<==0 | data/config/rite/5000736.json |

| 5000737 | 活人献祭 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: is=2000462<br>s2: type=char, any={"密教徒":1,"黑暗知识":1}<br>s3: any={"!怪物":1,"妖精":1,"荆棘戒指":1}, !主角=1, !食客=1, !动物=1<br>s4: type=sudan, any={"杀戮":1,"all":{"纵欲":1,"counter.7000083<":1}}, f:rare-s3.rare<==0 | data/config/rite/5000737.json |

| 5000738 | 召唤邪物 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: is=2000489<br>s2: type=char, 黑暗知识=1<br>s3: type=char, 密教徒=1<br>s4: type=char, 密教徒=1 | data/config/rite/5000738.json |

| 5000739 | 看书-怪诞的书（废弃） | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000464<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000739.json |

| 5000740 | 血炼熔炉 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: is=2000490<br>s2: type=char, 黑暗知识=1<br>s3: type=item, 武器=1, !血肉附魔=1<br>s4: any={"type":"char","任意处置":1}, !主角=1 | data/config/rite/5000740.json |

| 5000741 | 获得禁忌的古书 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000741.json |

| 5000742 | 魔力增长仪式 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: is=2000491<br>s2: type=char, 黑暗知识=1<br>s3: type=item, cost.2000463=1<br>s4: any={"type":"char","任意处置":1}, !主角=1 | data/config/rite/5000742.json |

| 5000743 | 黑暗火锅仪式 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: is=2000466<br>s2: type=char, any={"黑暗知识":1,"密教徒":1}<br>s3: type=char, any={"黑暗知识":1,"密教徒":1}<br>s4: type=char, any={"黑暗知识":1,"密教徒":1} | data/config/rite/5000743.json |

| 5000744 | 看书-禁忌的古书 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000465<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000744.json |

| 5000745 | 研究神秘的锅 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000466<br>s2: type=char | data/config/rite/5000745.json |

| 5000746 | 传播密教理念 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: type=char, !密教徒=1, any={"!动物":1,"is":2000461}, !怪物=1, !已安利=1<br>s3: type=item, 思潮=1, any={"is":2000412}<br>s4: type=item, 空屋=1, any={"s3.is":2000412} | data/config/rite/5000746.json |

| 5000747 | 处置女邪术师 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000190<br>s2: type=char, 主角=1<br>s3: type=sudan, !s4=1, 纵欲=1, rare<==3<br>s4: type=sudan, !s3=1, 杀戮=1, rare<==3 | data/config/rite/5000747.json |

| 5000748 | 奈布哈尼决斗（废弃） | 上城区:[1,6] | 1 | 0 | 1 | 0 | s1: is=2000064<br>s2: type=char, 贵族=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000748.json |

| 5000749 | 一起玩个够 | 上城区:[1,6] | 1 | 0 | 1 | 1 | s1: is=2000064<br>s2: type=char, 主角=1<br>s3: type=sudan, 奢靡=1, f:rare-s1.rare<==0<br>s4: type=item, cost.金币==10 | data/config/rite/5000749.json |

| 5000750 | 黄沙的背后 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1, is=2000707<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000750.json |

| 5000751 | 呼啸的山风 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1, is=2000708<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000751.json |

| 5000752 | 夺宝奇兵 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1, is=2000709<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000752.json |

| 5000753 | 妖精国游记 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1, is=2000710<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000753.json |

| 5000754 | 将军夜猎 | 野外:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000054<br>s2: type=item, is=2000712<br>s3: type=char, 主角=1<br>s4: type=sudan, 征服=1, rare<==2 | data/config/rite/5000754.json |

| 5000755 | 一件残酷的礼物 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000711<br>s2: type=char, 追随者=1, !主角=1, !动物=1 | data/config/rite/5000755.json |

| 5000756 | 狰狞美味 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: type=char, !怪物=1, !动物=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000756.json |

| 5000757 | 一件残酷的礼物 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000711<br>s2: type=char, is=2000054 | data/config/rite/5000757.json |

| 5000758 | 一件凶煞的商品 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000711 | data/config/rite/5000758.json |

| 5000759 | 意料中的买家 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000054 | data/config/rite/5000759.json |

| 5000760 | 黑街的拳斗士？ | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: is=2000730 | data/config/rite/5000760.json |

| 5000761 | 您也不想别人知道吧 | 上城区:[1,12] | 0 | 0 | 1 | 1 | s1: type=char, is=2000054<br>s2: type=item, !s3=1, !s4=1, is=2000731<br>s3: type=item, !s2=1, !s4=1, is=2000731<br>s4: type=item, !s2=1, !s3=1, is=2000731 | data/config/rite/5000761.json |

| 5000762 | 公开的拳斗 | 商业区:[10,19] | 0 | 0 | 1 | 4 | s1: type=char, is=2000054<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1, 情报=1 | data/config/rite/5000762.json |

| 5000763 | 黑街扬名 | 黑街:[2,5] | 0 | 0 | 1 | 1 | s1: type=item, is=2000731 | data/config/rite/5000763.json |

| 5000764 | 有人准备挑战你 | 自宅:[2,12] | 1 | 0 | 5 | 0 | s1: is=2000064<br>s2: type=item, is=2000751 | data/config/rite/5000764.json |

| 5000765 | 护花使者 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000064<br>s2: type=char, 贵族=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000765.json |

| 5000766 | 避避风头 | 野外:[1,14] | 1 | 0 | 3 | 0 | s1: is=2000064 | data/config/rite/5000766.json |

| 5000767 | 肉体展览 | 上城区:[1,6] | 0 | 0 | 1 | 2 | s1: is=2000770<br>s2: is=2000851<br>s3: is=2000852<br>s4: is=2000064 | data/config/rite/5000767.json |

| 5000768 | 奴隶交易（废弃） | 上城区:[1,6] | 1 | 0 | 1 | 2 | s1: is=2000772<br>s2: type=item, cost.金币=[3,6]<br>s3: type=sudan, 奢靡=1, f:rare-s1.rare<==0 | data/config/rite/5000768.json |

| 5000769 | 奴隶交易(废弃) | 上城区:[1,6] | 1 | 0 | 1 | 2 | s1: is=2000772<br>s2: type=item, cost.金币=[3,6]<br>s3: type=sudan, 奢靡=1, f:rare-s1.rare<==0 | data/config/rite/5000769.json |

| 5000770 | 深夜访客 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000771, 芮尔=1<br>s2: any={"is":2010005,"all":{"is":2000382,"cost.可堆叠=":1},"cost.金币=":1} | data/config/rite/5000770.json |

| 5000771 | 浪子的思绪 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000064<br>s2: type=char, 主角=1 | data/config/rite/5000771.json |

| 5000772 | 那个女人 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: is=2000772<br>s2: is=2000064 | data/config/rite/5000772.json |

| 5000773 | 酩酊一醉 | 商业区:[10,19] | 0 | 0 | 1 | 6 | s1: is=2000064<br>s2: type=item, cost.金币=10 | data/config/rite/5000773.json |

| 5000774 | 欢愉之馆的新人 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: is=2000772 | data/config/rite/5000774.json |

| 5000775 | 浪子的思绪 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000064<br>s2: type=char, 主角=1 | data/config/rite/5000775.json |

| 5000776 | 不是故意 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000083, cost.不满=1 | data/config/rite/5000776.json |

| 5000777 | 奢侈的欢欣 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000772<br>s2: type=item, cost.金币=15 | data/config/rite/5000777.json |

| 5000778 | 久违的清净 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000083, cost.不满=1 | data/config/rite/5000778.json |

| 5000779 | 未被满足的渴求 | 自宅:[2,12] | 0 | 0 | 1 | 10 | s1: type=char, is=2000772<br>s2: type=item, 空屋=1<br>s3: type=sudan, f:rare-s2.rare<==0, 奢靡=1 | data/config/rite/5000779.json |

| 5000780 | 另谋出路 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: type=char, is=2000772 | data/config/rite/5000780.json |

| 5000781 | 懂的都懂 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000775<br>s2: type=char, any={"男性":1,"女性":1}, !怪物=1 | data/config/rite/5000781.json |

| 5000782 | 决裂 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000064<br>s2: type=char, 贵族=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, cost.消耗品==1 | data/config/rite/5000782.json |

| 5000783 | 金屋藏娇 | 奇珍:12 | 1 | 0 | 5 | 0 | s1: is=2000772, 纳入收藏=1<br>s2: type=item, 金屋藏娇=1<br>s3: type=item, cost.金币=3 | data/config/rite/5000783.json |

| 5000784 | 微小的麻烦 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2000773<br>s2: type=char, any={"追随者":1,"主角":1}<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000784.json |

| 5000785 | 精致的礼物 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000778<br>s2: type=char, any={"追随者":1,"主角":1}, !怪物=1, !动物=1 | data/config/rite/5000785.json |

| 5000786 | 火中的自由 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: is=2000773<br>s2: type=char, any={"追随者":1,"主角":1}<br>s3: type=char, any={"追随者":1,"all":{"s2":1,"any":{"怪物":1,"动物":1}}}<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000786.json |

| 5000787 | 探访 | 上城区:[7,12] | 0 | 0 | 1 | 5 | s1: is=2000773<br>s2: type=char, is=2000064<br>s3: type=char, 主角=1<br>s4: type=item, 思潮=1 | data/config/rite/5000787.json |

| 5000788 | 你所能做到的 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: is=2000773<br>s2: type=char, any={"女性":1,"is":2000064}<br>s3: type=char, any={"女性":1,"is":2000064}<br>s4: type=char, any={"女性":1,"is":2000064} | data/config/rite/5000788.json |

| 5000789 | 纺织教室 | 上城区:[7,12] | 0 | 0 | 5 | 0 | s1: is=2000773<br>s2: type=char, 智慧>==4 | data/config/rite/5000789.json |

| 5000790 | 蓝巾 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: is=2000773<br>s2: type=char, 主角=1<br>s3: type=item, any={"is":2000541} | data/config/rite/5000790.json |

| 5000791 | 黑街勇士讨伐战 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000784<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000791.json |

| 5000792 | 都城武馆征伐战 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000785<br>s2: type=char, 主角=1, !已装备=1<br>s3: type=item, cost.消耗品==1, !金币=1, 情报=1 | data/config/rite/5000792.json |

| 5000793 | 天下武学验证战 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000786<br>s2: is=2000787<br>s3: type=char, 主角=1<br>s4: type=char, is=2000064 | data/config/rite/5000793.json |

| 5000794 | 天下武学验证战？ | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: is=2000789<br>s2: type=char, is=2000064<br>s3: type=char, 主角=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000794.json |

| 5000795 | 最受欢迎的男人 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: is=2000791, 蒙面苏丹=1<br>s2: type=char, is=2000064<br>s3: type=char, 主角=1, 魅力>==5<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000795.json |

| 5000796 | 苏丹的游戏 | 商业区:[10,19] | 0 | 0 | 3 | 5 | s1: is=2000024<br>s2: type=char, 妓女=1, !is=2000792<br>s3: type=char, 妓女=1, !is=2000792<br>s4: type=char, 贵族=1, 男性=1, !主角=1, !银趴绝缘者=1 | data/config/rite/5000796.json |

| 5000797 | 游戏的准备 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: is=2000792<br>s2: type=item, cost.金币==30<br>s3: type=item, cost.金币==10 | data/config/rite/5000797.json |

| 5000798 | 你的游戏 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: is=2000024<br>s2: type=char, any={"is":2000082}<br>s3: type=char, 贵族=1, 男性=1, !主角=1, !银趴绝缘者=1<br>s4: type=char, !贵族=1, 男性=1, !主角=1, !银趴绝缘者=1 | data/config/rite/5000798.json |

| 5000799 | 寻欢作乐的高手 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000064<br>s2: type=char, 主角=1 | data/config/rite/5000799.json |

| 5000800 | 你的游戏 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: is=2000024<br>s2: type=char, any={"is":2000082}<br>s3: type=char, 贵族=1, 男性=1, !主角=1, !银趴绝缘者=1<br>s4: type=char, !贵族=1, 男性=1, !主角=1, !银趴绝缘者=1 | data/config/rite/5000800.json |

| 5000801 | 朱娜的游戏 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: is=2000080<br>s2: any={"all":{"type":"sudan","!s5.苏丹卡":1,"!s8.苏丹卡":1,"!s11.苏丹卡":1,"!s12.苏丹卡":1}}<br>s3: type=char, 被覆者=1<br>s4: type=char, !银趴绝缘者=1, !怪物=1, !动物=1, !主角=1, !is=2000024 | data/config/rite/5000801.json |

| 5000802 | 贾丽拉的游戏 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: is=2000081<br>s2: type=char, 主角=1<br>s3: type=sudan, rare<==3<br>s4: is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000802.json |

| 5000803 | 夏玛的游戏 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: any={"all":{"type":"sudan","!s3.苏丹卡":1,"!s5.苏丹卡":1,"!s7.苏丹卡":1,"!s9.苏丹卡":1}}<br>s2: type=char, is=2000082<br>s3: any={"all":{"type":"sudan","!s1.苏丹卡":1,"!s5.苏丹卡":1,"!s7.苏丹卡":1,"!s9.苏丹卡":1}}<br>s4: type=char, is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000803.json |

| 5000804 | 索拉薇儿的游戏 | 商业区:[10,19] | 1 | 0 | 1 | 3 | s1: is=2000080<br>s2: type=char, 索拉薇儿的客人=1, !银趴绝缘者=1<br>s3: type=char, 索拉薇儿的客人=1, !银趴绝缘者=1<br>s4: type=char, 索拉薇儿的客人=1, !银趴绝缘者=1 | data/config/rite/5000804.json |

| 5000805 | 浪子的悲哀 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000064<br>s2: type=char, 主角=1<br>s3: type=item, 思潮=1, !is=2000728 | data/config/rite/5000805.json |

| 5000806 | 朱娜的游戏 | 商业区:[10,19] | 1 | 0 | 1 | 3 | s1: is=2000080<br>s2: type=char, is=2000064<br>s3: type=char, 朱娜的客人=1, !银趴绝缘者=1<br>s4: type=char, 朱娜的客人=1, !银趴绝缘者=1 | data/config/rite/5000806.json |

| 5000807 | 贾丽拉的游戏 | 商业区:[10,19] | 1 | 0 | 1 | 3 | s1: is=2000080<br>s2: type=char, is=2000064<br>s3: type=char, 贾丽拉的客人=1, !银趴绝缘者=1<br>s4: type=char, 贾丽拉的客人=1, !银趴绝缘者=1 | data/config/rite/5000807.json |

| 5000808 | 夏玛的游戏 | 商业区:[10,19] | 1 | 0 | 1 | 3 | s1: is=2000080<br>s2: type=char, is=2000064<br>s3: type=char, 夏玛的客人=1, !银趴绝缘者=1<br>s4: type=char, 夏玛的客人=1, !银趴绝缘者=1 | data/config/rite/5000808.json |

| 5000809 | 索拉薇儿的游戏 | 商业区:[10,19] | 1 | 0 | 1 | 3 | s1: is=2000080<br>s2: type=char, is=2000064<br>s3: type=char, 索拉薇儿的客人=1, !银趴绝缘者=1<br>s4: type=char, 索拉薇儿的客人=1, !银趴绝缘者=1 | data/config/rite/5000809.json |

| 5000810 | 帮派斗争 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: is=2000771, 芮尔=1<br>s2: type=item, is=2000965<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.金币==5 | data/config/rite/5000810.json |

| 5000811 | 与豺狼帮合作 | 奇珍:10 | 1 | 0 | 7 | 0 | s1: is=2001057, 纳入收藏=1 | data/config/rite/5000811.json |

| 5000812 | 芮尔的匪帮 | 奇珍:11 | 0 | 0 | 1 | 0 | s1: type=item, 芮尔手下=1, is=2000965, counter.7000465<=1<br>s2: type=item, 芮尔手下=1, is=2000966, counter.7000465<=1<br>s3: type=item, 芮尔手下=1, is=2000967, counter.7000465<=1<br>s4: type=item, 芮尔手下=1, is=2000968, counter.7000465<=1 | data/config/rite/5000812.json |

| 5000813 | 追猎豺狼 | 黑街:[2,5] | 0 | 0 | 2 | 7 | s1: type=char, 芮尔=1, is=2000771<br>s2: type=item, 芮尔手下=1, is=2000965<br>s3: type=char<br>s4: type=item, cost.金币==5 | data/config/rite/5000813.json |

| 5000814 | 肝胆相照 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: type=char, 芮尔=1, is=2000771<br>s2: type=char, 主角=1<br>s3: type=char, !主角=1 | data/config/rite/5000814.json |

| 5000815 | 我要去妓院！ | 黑街:[2,5] | 0 | 0 | 1 | 7 | s1: type=char, 芮尔=1, is=2000771<br>s2: type=item, 芮尔手下=1<br>s3: type=char, any={"主角":1,"is":2000064}<br>s4: type=item, cost.金币==20 | data/config/rite/5000815.json |

| 5000816 | 惊天大姐案 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, 芮尔=1, is=2000771<br>s2: type=item, 芮尔手下=1<br>s3: type=char<br>s4: type=char | data/config/rite/5000816.json |

| 5000817 | 我，白嫖 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000792<br>s2: type=char<br>s3: type=item, cost.金币==20<br>s4: type=sudan, 奢靡=1, rare<==3 | data/config/rite/5000817.json |

| 5000818 | 追查猎奴人 | 黑街:[2,5] | 0 | 0 | 1 | 7 | s1: type=char, is=2000771, 芮尔=1<br>s2: type=char<br>s3: type=item, cost.金币==20<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000818.json |

| 5000819 | 赤裸的茶会 | 商业区:[10,19] | 0 | 0 | 1 | 7 | s1: type=char, is=2000771, 芮尔=1<br>s2: type=char, 主角=1<br>s3: type=char, !动物=1<br>s4: type=char, !主角=1, !动物=1 | data/config/rite/5000819.json |

| 5000820 | 从实招来 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: type=char, is=2000771, 芮尔=1<br>s2: type=char, is=2000971<br>s3: type=item, is=2000973<br>s4: type=item, is=2000974 | data/config/rite/5000820.json |

| 5000821 | 宰相的暗示 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=item, is=2000977<br>s2: type=char, is=2000349 | data/config/rite/5000821.json |

| 5000822 | 猎团余党 | 野外:[1,14] | 0 | 0 | 1 | 0 | s1: type=item, is=2000978<br>s2: type=item, is=2000978<br>s3: type=char, 芮尔=1, is=2000771<br>s4: type=item, 芮尔手下=1 | data/config/rite/5000822.json |

| 5000823 | 猎团余党 | 野外:[1,14] | 0 | 0 | 1 | 0 | s1: type=item, is=2000978<br>s2: type=item, is=2000978<br>s3: type=char, 芮尔=1, is=2000771<br>s4: type=item, 芮尔手下=1 | data/config/rite/5000823.json |

| 5000824 | 猎团余党 | 野外:[1,14] | 0 | 0 | 1 | 0 | s1: type=item, is=2000978<br>s2: type=item, is=2000978<br>s3: type=char, 芮尔=1, is=2000771<br>s4: type=item, 芮尔手下=1 | data/config/rite/5000824.json |

| 5000825 | 乱军 | 野外:[1,14] | 0 | 0 | 1 | 7 | s1: type=item, is=2000979<br>s2: type=item, is=2000980<br>s3: type=item, is=2000981<br>s4: type=item, is=2000968 | data/config/rite/5000825.json |

| 5000826 | 白银马鞍 | 自宅:[2,14] | 0 | 0 | 1 | 1 | s1: type=item, is=2000983<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5000826.json |

| 5000827 | 蛮野之心 | 自宅:[2,14] | 0 | 0 | 1 | 1 | s1: type=item, is=2000982<br>s2: type=char, 芮尔=1, is=2000771 | data/config/rite/5000827.json |

| 5000828 | 纠纷的任务 | 黑街:[1,5] | 0 | 0 | 1 | 7 | s1: type=char, is=2000013<br>s2: type=char, is=2000991<br>s3: type=sudan, !征服=1, any={"all":{"s7":1,"rare<=":3}}<br>s4: type=item, cost.金币=[10,20] | data/config/rite/5000828.json |

| 5000829 | 故国的复仇 | 野外:[1,14] | 1 | 0 | 1 | 0 | s1: type=char, is=2000013<br>s2: type=char, is=2000992<br>s3: type=item, is=2000993<br>s4: type=item, cost.剑客蓄势=[1,10] | data/config/rite/5000829.json |

| 5000830 | 讨伐无道 | 野外:[1,14] | 1 | 0 | 1 | 0 | s1: type=char, is=2000013<br>s2: type=char, is=2000992<br>s3: type=item, is=2000993<br>s4: type=item, cost.剑客蓄势=[1,10] | data/config/rite/5000830.json |

| 5000831 | 烂纸头 | 野外:[1,14] | 0 | 0 | 1 | 3 | s1: type=item, is=2000998<br>s2: type=item, is=2000999<br>s3: type=item, is=2001000<br>s4: any={"all":{"type":"item","cost.金币":3},"is":2000123}, s1=1 | data/config/rite/5000831.json |

| 5000832 | 建造图录 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000998<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000832.json |

| 5000833 | 花园景观残本 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000999<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000833.json |

| 5000834 | 寝食单 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001000<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5000834.json |

| 5000835 | 锐草之原 | 野外:[1,14] | 0 | 0 | 3 | 0 | s1: type=char, 生存>==4<br>s2: type=char, 魔力>==5<br>s3: type=char, 智慧>==5<br>s4: type=item, cost.金币=10 | data/config/rite/5000835.json |

| 5000836 | 六尺之下 | 野外:[1,14] | 1 | 0 | 4 | 0 | s1: type=char, is=2000013 | data/config/rite/5000836.json |

| 5000837 | 迷失于灰烬中 | 野外:[1,14] | 1 | 0 | 4 | 0 | s1: type=char, is=2000013 | data/config/rite/5000837.json |

| 5000838 | 儿子的索要 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000013<br>s2: type=item, is=2001001 | data/config/rite/5000838.json |

| 5000839 | 你最重要的 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=char, is=2000013<br>s2: any={"type":"sudan","all":{"type":"item","any":{"is":2000689,"cost.金币=":1}}} | data/config/rite/5000839.json |

| 5000840 | 剑之名 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000013<br>s2: type=char, 主角=1 | data/config/rite/5000840.json |

| 5000841 | 刀剑问答 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000013<br>s2: type=item, is=2001002<br>s3: type=item, any={"is":2000997}<br>s4: type=char, 主角=1 | data/config/rite/5000841.json |

| 5000842 | 誓言的呼唤 | 黑街:[2,5] | 0 | 0 | 1 | 0 | s1: type=char, is=2000992<br>s2: type=char, 金血之证=1 | data/config/rite/5000842.json |

| 5000843 | 暗杀 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000013<br>s2: type=char, any={"剑客暗杀目标":1,"all":{"counter.7000527>=":1,"妻子":1}} | data/config/rite/5000843.json |

| 5000844 | 趋炎附势之徒 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, any={"贵族":1,"is":2000013}, !动物=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=item, is=2000913 | data/config/rite/5000844.json |

| 5000845 | 忠贞正义之徒 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, any={"贵族":1,"is":2000013}, !动物=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=item, is=2000913 | data/config/rite/5000845.json |

| 5000846 | 迷信盲从之徒 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, any={"贵族":1,"is":2000013}, !动物=1<br>s2: type=item, is=2000913 | data/config/rite/5000846.json |

| 5000847 | 欺软怕硬之徒 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, any={"贵族":1,"is":2000013}, !动物=1<br>s2: any={"type":"char"}, 部队=1<br>s3: any={"type":"char"}, 部队=1<br>s4: any={"type":"char"}, 部队=1 | data/config/rite/5000847.json |

| 5000848 | 视财如命之徒 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, any={"贵族":1,"is":2000013}, !动物=1<br>s2: type=item, cost.金币==15<br>s3: type=item, is=2000913 | data/config/rite/5000848.json |

| 5000849 | 故国的旗帜 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000913<br>s2: type=item, any={"is":2001024} | data/config/rite/5000849.json |

| 5000850 | 敦请圣像 | 野外:[2,14] | 0 | 0 | 1 | 0 | s1: type=item, is=2001024<br>s2: any={"all":{"type":"item","any":{"is":2000848}}}<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000850.json |

| 5000851 | 回收金血之证 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000013<br>s2: 金血之证=1 | data/config/rite/5000851.json |

| 5000852 | 侍奉君主 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: type=char, 主角=1<br>s3: type=sudan, rare<==3, 纵欲=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5000852.json |

| 5000853 | 以一敌百 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: 苏丹的精兵=1, 部队=1<br>s3: type=char, 主角=1<br>s4: type=sudan, rare<==3, 征服=1 | data/config/rite/5000853.json |

| 5000854 | 无妄之灾 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: is=2000896, 被覆者=1<br>s3: type=char, !动物=1, !怪物=1, 贵族=1<br>s4: type=char, 主角=1 | data/config/rite/5000854.json |

| 5000855 | 共襄盛举 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: type=item, cost.金币==10<br>s2: type=item, is=2001058, cost.倒计时=[1,5] | data/config/rite/5000855.json |

| 5000856 | 终极羞辱 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: type=char, is=2001059<br>s2: type=char, 主角=1<br>s3: is=2000081<br>s4: is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000856.json |

| 5000857 | 夜间工作 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: type=char, is=2001059<br>s2: type=char, 主角=1<br>s3: is=2000081<br>s4: is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000857.json |

| 5000858 | 夜间工作 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: type=char, is=2001059<br>s2: type=char, 主角=1<br>s3: is=2000081<br>s4: is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000858.json |

| 5000859 | 夜间工作 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: type=char, is=2001059<br>s2: type=char, 主角=1<br>s3: is=2000081<br>s4: is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000859.json |

| 5000860 | 夜间工作 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: type=char, is=2001059<br>s2: type=char, 主角=1<br>s3: is=2000081<br>s4: is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000860.json |

| 5000861 | 夜间工作 | 商业区:[10,19] | 1 | 0 | 0 | 0 | s1: type=char, is=2001059<br>s2: type=char, 主角=1<br>s3: is=2000081<br>s4: is=2000064, 奈布哈尼准备银趴=1 | data/config/rite/5000861.json |

| 5000862 | 寻欢作乐的高手 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000064<br>s2: type=char, 主角=1 | data/config/rite/5000862.json |

| 5000863 | 偷窃圣血 | 神殿区:[2,10] | 0 | 0 | 1 | 14 | s1: type=char, is=2000352<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5000863.json |

| 5001001 | 权力的游戏 | 宫廷:1 | 1 | 1 | 1 | 0 | s1: type=item, cost.谗言=[1,999]<br>s2: is=2000024, 上朝=1<br>s3: any={"is":2000173,"all":{"被覆者":1,"苏丹的玩偶":1}}, !选妃标记=1<br>s4: type=char, 贵族=1, !决斗标记=1, !主角=1, !妻子=1, !变身公主=1, !is=2000762 | data/config/rite/5001001.json |

| 5001002 | 苏丹的戏弄 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=item, cost.金币=13<br>s2: type=item, is=2000170, cost.耐心=[1,3] | data/config/rite/5001002.json |

| 5001003 | 苏丹的戏弄（废弃） | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=item, cost.影响力=1<br>s2: type=item, 耐心=1<br>s3: type=item, 耐心=1 | data/config/rite/5001003.json |

| 5001004 | 群龙无首 | 宫廷:1 | 1 | 1 | 1 | 0 | s1: type=item, 思潮=1, 主旋律=1, !rite=5001001<br>s2: type=item, rare<==3, cost.情报=3<br>s3: type=item, rare<==3, cost.思潮=3, !is=2000913<br>s4: type=item, any={"is":2000913} | data/config/rite/5001004.json |

| 5001005 | 宫廷决斗 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, 决斗标记=1<br>s2: type=char, 贵族=1<br>s3: type=item, cost.消耗品==1 | data/config/rite/5001005.json |

| 5001006 | 探访监狱 | 宫廷:[7,10] | 0 | 0 | 0 | 0 | s1: type=item, 关闭=1, is=2000310<br>s2: type=item, cost.金币=2 | data/config/rite/5001006.json |

| 5001007 | 卑贱囚牢 | 宫廷:[7,10] | 0 | 0 | 1 | 1 | s1: type=char, 囚徒=1, !贵族=1<br>s2: type=char, 囚徒=1, !贵族=1<br>s3: type=char, 囚徒=1, !贵族=1<br>s4: type=char, 囚徒=1, !贵族=1 | data/config/rite/5001007.json |

| 5001008 | 囚牢 | 宫廷:[7,10] | 0 | 0 | 1 | 1 | s1: type=char, 囚徒=1, is=2000346<br>s2: type=char, 囚徒=1, is=2000347<br>s3: type=char, 囚徒=1, is=2000546<br>s4: type=char, 囚徒=1 | data/config/rite/5001008.json |

| 5001009 | 黑牢深处（废弃） | 宫廷:[7,10] | 0 | 0 | 1 | 1 | s1: type=char, 囚徒=1<br>s2: type=char, 囚徒=1<br>s3: type=char, 囚徒=1<br>s4: type=char, 囚徒=1 | data/config/rite/5001009.json |

| 5001010 | 黑街线人 | 黑街:[2,5] | 0 | 0 | 3 | 0 | s1: cost.金币=5, type=item | data/config/rite/5001010.json |

| 5001011 | 无名的暗杀 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000360<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1 | data/config/rite/5001011.json |

| 5001012 | 哲瓦德来访 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000057<br>s2: type=char<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5001012.json |

| 5001013 | 藏宝地 | 上城区:[1,6] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5001013.json |

| 5001014 | 脱罪的希望 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=item, cost.金币=10 | data/config/rite/5001014.json |

| 5001015 | 盖斯家的协助 | 上城区:[1,6] | 1 | 0 | 1 | 0 | s1: type=item, is=2000092, 恶名==1 | data/config/rite/5001015.json |

| 5001016 | 苏丹的戏弄 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, any={"all":{"女性":1,"小筹":1,"counter.7000837<":1}}<br>s2: type=item, is=2001051, cost.耐心=[1,4] | data/config/rite/5001016.json |

| 5001017 | 苏丹的欢愉 | 宫廷:[2,6] | 1 | 0 | 7 | 0 | s1: type=char, 侍奉苏丹=1 | data/config/rite/5001017.json |

| 5001018 | 苏丹的戏弄 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, 战斗>==4<br>s2: type=item, is=2001052, cost.耐心=[1,5] | data/config/rite/5001018.json |

| 5001019 | 和野狗对决 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=item, is=2000424<br>s2: type=char, 侍奉苏丹2=1<br>s3: type=item, cost.消耗品==1 | data/config/rite/5001019.json |

| 5001020 | 和囚犯对决 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000425<br>s2: type=char, 侍奉苏丹2=1<br>s3: type=item, cost.消耗品==1 | data/config/rite/5001020.json |

| 5001021 | 和狮子对决 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=item, is=2000426<br>s2: type=char, 侍奉苏丹2=1<br>s3: type=item, !金币=1, cost.消耗品==1 | data/config/rite/5001021.json |

| 5001022 | 和巨人对决 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000427<br>s2: type=char, 侍奉苏丹2=1<br>s3: type=item, cost.消耗品==1 | data/config/rite/5001022.json |

| 5001023 | 改朝换代 | 结局:1 | 0 | 0 | 1 | 0 | s1: type=item, is=2000901, 苏丹的精兵=1<br>s2: type=item, is=2000902, 苏丹的精兵=1<br>s3: type=item, is=2000903, 苏丹的精兵=1<br>s4: type=item, is=2000904, 苏丹的精兵=1 | data/config/rite/5001023.json |

| 5001024 | 调查罪证 | 上城区:[1,12] | 0 | 0 | 3 | 5 | s1: type=char, is=2000067<br>s2: type=item, is=2000558<br>s3: type=char<br>s4: type=char | data/config/rite/5001024.json |

| 5001025 | 破坏证据 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, cost.罪证==1<br>s2: type=char<br>s3: type=char | data/config/rite/5001025.json |

| 5001026 | 论罪与辩护 | 宫廷:[2,10] | 0 | 0 | 1 | 3 | s1: type=item, cost.罪证=[1,99]<br>s2: type=char, 贵族=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.金币==[1,50] | data/config/rite/5001026.json |

| 5001027 | 交钱赎罪 | 宫廷:[2,10] | 0 | 0 | 1 | 5 | s1: type=item, cost.金币=40 | data/config/rite/5001027.json |

| 5001028 | 进献妻妾 | 宫廷:[2,10] | 0 | 0 | 1 | 5 | s1: type=char, any={"妻子":1,"侧室":1,"新妻":1} | data/config/rite/5001028.json |

| 5001029 | 宫廷决斗 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, 决斗标记=1<br>s2: type=char, is=2000897<br>s3: type=char, is=2000898<br>s4: type=char | data/config/rite/5001029.json |

| 5001100 | 宫中传信 | 宫廷:[2,6] | 0 | 0 | 1 | 7 | s1: type=char, is=2000129<br>s2: type=char, 主角=1<br>s3: type=item, any={"cost.金币":10,"is":2000283}<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5001100.json |

| 5001101 | 遍体鳞伤的尸体 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000129 | data/config/rite/5001101.json |

| 5001102 | 阿图娜尔的约定 | 宫廷:[2,6] | 0 | 0 | 1 | 1 | s1: type=char, is=2000129<br>s2: type=char, 主角=1<br>s3: type=item, any={"cost.金币":10,"is":2000283}<br>s4: type=item, any={"is":2000172,"未被苏丹所知":1,"破除封锁":1} | data/config/rite/5001102.json |

| 5001103 | 不归之路 | 宫廷:[2,6] | 1 | 0 | 3 | 0 | s1: is=2000129<br>s2: is=2000024 | data/config/rite/5001103.json |

| 5001104 | 香消玉殒 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129 | data/config/rite/5001104.json |

| 5001501 | 浴场里的消息 | 上城区:[1,6] | 0 | 1 | 1 | 0 | s1: type=char, any={"贵族":1,"all":{"!贵族":1,"s2.is":2000524}}<br>s2: type=item, any={"cost.金币":1,"is":2000524}<br>s3: type=item, any={"all":{"cost.消耗品=":1,"!金币":1},"is":2000680} | data/config/rite/5001501.json |

| 5001502 | 蒸汽社交 | 上城区:[1,6] | 0 | 0 | 1 | 0 | s1: type=char, 贵族=1, !主角=1, !妻子=1, !is=2000024<br>s2: type=char, 贵族=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, any={"杀戮":1,"纵欲":1}, f:rare-s1.rare<==0 | data/config/rite/5001502.json |

| 5001503 | 浴场约会 | 上城区:[1,6] | 0 | 0 | 1 | 1 | s1: type=char, 妻子=1, 激情=1<br>s2: 主角=1, type=char<br>s3: type=sudan, f:rare-s1.rare<==0, any={"纵欲":1,"杀戮":1}<br>s4: is=2000192 | data/config/rite/5001503.json |

| 5001504 | 解释 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=sudan, rare<==3, 杀戮=1 | data/config/rite/5001504.json |

| 5002001 | 医馆 | 商业区:1 | 0 | 0 | 1 | 0 | s1: type=char, any={"受伤":1,"生病":1}, !怪物=1<br>s2: type=item, cost.金币=1 | data/config/rite/5002001.json |

| 5002002 | 疾病发作 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, any={"受伤":1,"生病":1}, !怪物=1, !is=2000699<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002002.json |

| 5002003 | 欢愉之馆 | 商业区:2 | 0 | 0 | 1 | 1 | s1: is=2000080, 妓女=1, !追随者=1<br>s2: type=item, cost.金币=[2,4]<br>s3: 主角=1, type=char<br>s4: type=sudan, any={"纵欲":1,"杀戮":1,"奢靡":1}, f:rare-s1.rare<==0 | data/config/rite/5002003.json |

| 5002004 | 欢愉之馆 | 商业区:2 | 0 | 0 | 1 | 1 | s1: is=2000081, 妓女=1, !追随者=1<br>s2: type=item, cost.金币=[4,8]<br>s3: 主角=1, type=char<br>s4: type=sudan, any={"纵欲":1,"杀戮":1,"奢靡":1}, f:rare-s1.rare<==0 | data/config/rite/5002004.json |

| 5002005 | 欢愉之馆 | 商业区:2 | 0 | 0 | 1 | 1 | s1: is=2000082, 妓女=1, !追随者=1<br>s2: type=item, cost.金币=[8,16]<br>s3: 主角=1, type=char<br>s4: type=sudan, any={"纵欲":1,"杀戮":1,"奢靡":1}, f:rare-s1.rare<==0 | data/config/rite/5002005.json |

| 5002006 | 书店营业 | 商业区:3 | 0 | 1 | 1 | 0 | s1: type=char<br>s2: type=char, !主角=1, !追随者=1, 爱书人=1<br>s3: type=item, any={"cost.金币":1,"is":2000525}<br>s4: type=item, any={"all":{"cost.消耗品=":1,"!金币":1},"is":2000680} | data/config/rite/5002006.json |

| 5002007 | 书店密会 | 商业区:[4,5] | 0 | 0 | 1 | 1 | s1: type=char, 激情=1, 妻子=1<br>s2: 主角=1, type=char<br>s3: type=sudan, 纵欲=1, f:rare-s1.rare<==0<br>s4: is=2000200 | data/config/rite/5002007.json |

| 5002008 | 书店门口的乞丐 | 商业区:[4,5] | 0 | 0 | 0 | 2 | s1: is=2000161<br>s2: type=item, 读物=1 | data/config/rite/5002008.json |

| 5002009 | 还书的少女 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: is=2000161<br>s2: type=item, 读物=1, 赠予少女=1<br>s3: type=sudan, f:rare-s1.rare<==0, any={"杀戮":1,"纵欲":1,"奢靡":1}<br>s4: type=item, cost.金币=5 | data/config/rite/5002009.json |

| 5002010 | 装备商人 | 商业区:6 | 0 | 0 | 0 | 0 | s1: type=item, any={"装备":1,"淫具":1}, rare==1, 装备商人=1, !已拥有=1, !部落遗物=1<br>s2: type=item, any={"装备":1,"淫具":1}, rare==2, 装备商人=1, !已拥有=1, !部落遗物=1<br>s3: type=item, any={"装备":1,"淫具":1}, rare==2, 装备商人=1, !已拥有=1, !部落遗物=1<br>s4: type=item, any={"装备":1,"淫具":1}, rare==3, 装备商人=1, !已拥有=1, !部落遗物=1 | data/config/rite/5002010.json |

| 5002011 | 装备商人 | 商业区:6 | 0 | 0 | 0 | 0 | s1: type=item, any={"装备":1,"淫具":1}, rare==1, !已拥有=1, 武器存货=1, !部落遗物=1<br>s2: type=item, any={"装备":1,"淫具":1}, rare==2, !已拥有=1, 武器存货=1, !部落遗物=1<br>s3: type=item, any={"装备":1,"淫具":1}, rare==2, !已拥有=1, 武器存货=1, !部落遗物=1<br>s4: type=item, any={"装备":1,"淫具":1}, rare==3, !已拥有=1, 武器存货=1, !部落遗物=1 | data/config/rite/5002011.json |

| 5002012 | 服装商人 | 商业区:7 | 0 | 0 | 0 | 0 | s1: type=item, 服装=1, rare==1, !已拥有=1, !部落遗物=1<br>s2: type=item, 服装=1, rare==2, !已拥有=1, !部落遗物=1<br>s3: type=item, 服装=1, rare==2, !已拥有=1, !部落遗物=1<br>s4: type=item, 服装=1, rare==3, !已拥有=1, !部落遗物=1 | data/config/rite/5002012.json |

| 5002013 | 服装商人 | 商业区:7 | 0 | 0 | 0 | 0 | s1: type=item, 服装=1, rare==1, !已拥有=1, 服装存货=1, !部落遗物=1<br>s2: type=item, 服装=1, rare==2, !已拥有=1, 服装存货=1, !部落遗物=1<br>s3: type=item, 服装=1, rare==2, !已拥有=1, 服装存货=1, !部落遗物=1<br>s4: type=item, 服装=1, rare==3, !已拥有=1, 服装存货=1, !部落遗物=1 | data/config/rite/5002013.json |

| 5002014 | 饰品商人 | 商业区:8 | 0 | 0 | 0 | 0 | s1: type=item, 饰品=1, rare==1, !已拥有=1, !部落遗物=1<br>s2: type=item, 饰品=1, rare==2, !已拥有=1, !部落遗物=1<br>s3: type=item, 饰品=1, rare==2, !已拥有=1, !部落遗物=1<br>s4: type=item, 饰品=1, rare==3, !已拥有=1, !部落遗物=1 | data/config/rite/5002014.json |

| 5002015 | 饰品商人 | 商业区:8 | 0 | 0 | 0 | 0 | s1: type=item, 饰品=1, rare==1, !已拥有=1, 饰品存货=1, !部落遗物=1<br>s2: type=item, 饰品=1, rare==2, !已拥有=1, 饰品存货=1, !部落遗物=1<br>s3: type=item, 饰品=1, rare==2, !已拥有=1, 饰品存货=1, !部落遗物=1<br>s4: type=item, 饰品=1, rare==3, !已拥有=1, 饰品存货=1, !部落遗物=1 | data/config/rite/5002015.json |

| 5002016 | 神秘商人 | 商业区:9 | 0 | 0 | 0 | 1 | s1: type=item, 淫具=1, rare==1, !已拥有=1, !部落遗物=1<br>s2: type=item, 淫具=1, rare==2, !已拥有=1, !部落遗物=1<br>s3: type=item, 淫具=1, rare==2, !已拥有=1, !部落遗物=1<br>s4: type=item, 淫具=1, rare==3, !已拥有=1, !部落遗物=1 | data/config/rite/5002016.json |

| 5002017 | 甜蜜皮鞭 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: is=2000081, 激情=1<br>s2: type=item, cost.金币=4<br>s3: 主角=1, type=char<br>s4: type=sudan, 纵欲=1, rare<==2 | data/config/rite/5002017.json |

| 5002018 | 边缘行者 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: is=2000080, 激情=1<br>s2: 主角=1, type=char<br>s3: type=sudan, 纵欲=1, rare<==3<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002018.json |

| 5002019 | 天体聚会 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: is=2000082, 激情=1<br>s2: 主角=1, type=char<br>s3: type=char, 魅力>==5<br>s4: type=char, 魅力>==5 | data/config/rite/5002019.json |

| 5002020 | 奇淫巧技-苏丹的欢愉 | 商业区:[10,19] | 0 | 0 | 1 | 7 | s1: is=2000024<br>s2: is=2000082, 激情=1<br>s3: is=2000081, 激情=1<br>s4: is=2000080, 激情=1 | data/config/rite/5002020.json |

| 5002021 | 奇淫巧技-刺杀苏丹（废弃） | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: is=2000024, 刺杀事件=1<br>s2: is=2000012, !追随者=1<br>s3: 刺杀事件=1, !主角=1<br>s4: 刺杀事件=1, !主角=1 | data/config/rite/5002021.json |

| 5002022 | 为朱娜赎身 | 商业区:[10,19] | 0 | 0 | 1 | 10 | s1: is=2000080, 激情=3<br>s2: 主角=1, type=char<br>s3: type=item, cost.金币=10<br>s4: type=sudan, any={"奢靡":1,"杀戮":1}, f:rare-s1.rare<==0 | data/config/rite/5002022.json |

| 5002023 | 畸情的呼唤 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: is=2000080<br>s2: 主角=1, type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002023.json |

| 5002024 | 处理尸体 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2000081<br>s2: type=item, is=2000378<br>s3: type=char<br>s4: type=char | data/config/rite/5002024.json |

| 5002025 | 决斗 | 上城区:[1,6] | 0 | 0 | 1 | 5 | s1: type=char, is=2000379<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002025.json |

| 5002026 | 女王做妾 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: is=2000081, 锁定妓女2=1<br>s2: 主角=1, type=char<br>s3: type=item, cost.金币=20<br>s4: type=sudan, any={"奢靡":1,"杀戮":1}, f:rare-s1.rare<==0 | data/config/rite/5002026.json |

| 5002027 | 女王的朋友 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: is=2000081<br>s2: any={"all":{"is":2000024,"魔力戒指":1}}<br>s3: any={"all":{"type":"sudan","杀戮":1,"f:rare-s2.rare<=":0}}<br>s4: type=item, 思潮=1, any={"is":2000412}, !s1.密教徒=1 | data/config/rite/5002027.json |

| 5002028 | 孤注一掷 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: is=2000082, 锁定妓女1=1 | data/config/rite/5002028.json |

| 5002029 | 夏玛的葬礼 | 商业区:[10,19] | 0 | 0 | 1 | 7 | s1: type=item, any={"all":{"rare=":4,"装备":1},"is":2000266} | data/config/rite/5002029.json |

| 5002030 | 紧急结婚 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: is=2000082, 锁定妓女1=1<br>s2: 主角=1, type=char<br>s3: type=item, cost.金币=30<br>s4: type=sudan, 奢靡=1, f:rare-s1.rare<==0 | data/config/rite/5002030.json |

| 5002031 | 师出有名 | 野外:[1,6] | 0 | 0 | 3 | 20 | s1: type=char, is=2000397<br>s2: type=item, is=2000398<br>s3: 部队=1, any={"type":"char","is":"2000554"}<br>s4: type=char | data/config/rite/5002031.json |

| 5002032 | 怒火蔓延 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000082<br>s2: cost.金币=[1,20] | data/config/rite/5002032.json |

| 5002033 | 我的主人 | 宫廷:[2,6] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=char, is=2000082 | data/config/rite/5002033.json |

| 5002034 | 升华 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000082 | data/config/rite/5002034.json |

| 5002035 | 欢愉之馆 | 商业区:2 | 0 | 0 | 1 | 1 | s1: is=2000772, 妓女=1, !追随者=1<br>s2: type=item, cost.金币=[4,8]<br>s3: 主角=1, type=char<br>s4: type=sudan, any={"纵欲":1,"杀戮":1,"奢靡":1}, f:rare-s1.rare<==0 | data/config/rite/5002035.json |

| 5002036 | 淘书 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: is=2000199<br>s2: type=char<br>s3: type=item, cost.金币=3<br>s4: type=item, any={"all":{"cost.消耗品=":1,"!金币":1}} | data/config/rite/5002036.json |

| 5002037 | 淘书 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: is=2000199<br>s2: type=char<br>s3: type=item, cost.金币=3<br>s4: type=item, any={"all":{"cost.消耗品=":1,"!金币":1}} | data/config/rite/5002037.json |

| 5002038 | 淘书 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: is=2000199<br>s2: type=char<br>s3: type=item, cost.金币=3<br>s4: type=item, any={"all":{"cost.消耗品=":1,"!金币":1}} | data/config/rite/5002038.json |

| 5002501 | 食人的野狗 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: is=2000279<br>s2: any={"type":"char","all":{"type":"item","cost.金币":8}}<br>s3: type=char<br>s4: type=char | data/config/rite/5002501.json |

| 5002502 | 被流民侵占的宅邸 | 野外:[9,14] | 0 | 0 | 1 | 0 | s1: is=2000195<br>s2: type=char<br>s3: type=char<br>s4: type=item, any={"all":{"cost.消耗品=":1,"!金币":1},"cost.金币":8} | data/config/rite/5002502.json |

| 5002503 | 远近闻名的哈马尔兄弟 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: is=2000196<br>s2: is=2000197<br>s3: type=char<br>s4: type=char | data/config/rite/5002503.json |

| 5002504 | 神赐骏马 | 野外:[1,6] | 0 | 0 | 1 | 3 | s1: type=char<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002504.json |

| 5002505 | 袭杀凶狮 | 野外:[1,6] | 0 | 0 | 1 | 2 | s1: is=2000202<br>s2: type=char<br>s3: type=char<br>s4: type=item, any={"cost.消耗品=":1,"cost.金币":1} | data/config/rite/5002505.json |

| 5002506 | 商人的遗物 | 野外:[1,6] | 0 | 0 | 1 | 1 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002506.json |

| 5002507 | 凶狮肆虐 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, !主角=1, 追随者=1 | data/config/rite/5002507.json |

| 5002508 | 狼王的踪迹 | 野外:[1,6] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002508.json |

| 5002509 | 狼穴恶战 | 野外:[1,6] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, 征服=1, rare<==2 | data/config/rite/5002509.json |

| 5002510 | 下水道的鳄鱼 | 野外:[1,6] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002510.json |

| 5002511 | 毒蛇山谷 | 野外:[1,6] | 0 | 0 | 2 | 0 | s1: type=char<br>s2: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5002511.json |

| 5002512 | 赌马 | 野外:[1,6] | 0 | 0 | 1 | 1 | s1: type=char<br>s2: type=item, 坐骑=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.金币=[1,2] | data/config/rite/5002512.json |

| 5002513 | 赌马 | 野外:[1,6] | 0 | 0 | 1 | 1 | s1: type=char<br>s2: type=item, 坐骑=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.金币=[1,4] | data/config/rite/5002513.json |

| 5002514 | 赌马 | 野外:[1,6] | 0 | 0 | 1 | 1 | s1: type=char<br>s2: type=item, 坐骑=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.金币=[1,6] | data/config/rite/5002514.json |

| 5002515 | 赌马 | 野外:[1,6] | 0 | 0 | 1 | 1 | s1: type=char<br>s2: type=item, 坐骑=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.金币=[1,8] | data/config/rite/5002515.json |

| 5002516 | 喂养凶狮 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: is=2000202<br>s2: type=item, cost.金币=1 | data/config/rite/5002516.json |

| 5002517 | 山狮最后的索求 | 野外:[1,6] | 0 | 0 | 1 | 3 | s1: is=2000202<br>s2: type=char<br>s3: type=char<br>s4: type=item, any={"cost.消耗品=":1} | data/config/rite/5002517.json |

| 5003001 | 不谐之音 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: cost.不满=[1,3], is=2000083<br>s2: 妻子=1, type=char<br>s3: 主角=1, type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003001.json |

| 5003002 | 远行访友 | 自宅:[2,12] | 1 | 0 | 5 | 0 | s1: 妻子=1, type=char | data/config/rite/5003002.json |

| 5003003 | 纾解压力 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: 妻子=1, type=char<br>s2: cost.金币=[1,5], type=item | data/config/rite/5003003.json |

| 5003004 | 风暴预兆 | 自宅:[2,12] | 1 | 0 | 3 | 0 | s1: 妻子=1, type=char<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003004.json |

| 5003005 | 积郁成疾 | 自宅:[2,12] | 1 | 0 | 3 | 0 | s1: 妻子=1, type=char | data/config/rite/5003005.json |

| 5003006 | 沉入梦中 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 主角=1, type=char<br>s2: 妻子=1, type=char | data/config/rite/5003006.json |

| 5003007 | 放你自由 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: 妻子=1, type=char<br>s2: is=2000014<br>s3: type=item, cost.金币=[1,9999] | data/config/rite/5003007.json |

| 5003008 | 面对现实 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: 妻子=1, type=char<br>s2: is=2000014<br>s3: 主角=1, type=char, !s4=1<br>s4: 主角=1, type=char, !s3=1 | data/config/rite/5003008.json |

| 5003009 | 处刑 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: 妻子=1, type=char<br>s2: is=2000014<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=sudan, 杀戮=1, f:rare-s2.rare<==0 | data/config/rite/5003009.json |

| 5003010 | 酝酿中的阴谋 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: cost.恶名=[1,3], is=2000092<br>s2: type=char<br>s3: type=char<br>s4: type=item | data/config/rite/5003010.json |

| 5003011 | 风向变化 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, 贵族=1, !追随者=1, 支持>==1, !主角=1<br>s2: type=char, 贵族=1, !追随者=1, 支持>==1, !主角=1<br>s3: type=char, 贵族=1, !追随者=1, 支持>==1, !主角=1<br>s4: type=char, 贵族=1, !追随者=1, 支持>==1, !主角=1 | data/config/rite/5003011.json |

| 5003012 | 流言四起 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, cost.影响力=[1,2] | data/config/rite/5003012.json |

| 5003013 | 正义的挑战 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 贵族=1, !追随者=1, rare>==2, !主角=1<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5003013.json |

| 5003014 | 闷棍 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 主角=1, type=char<br>s2: type=char, 追随者=1<br>s3: type=char, 追随者=1 | data/config/rite/5003014.json |

| 5003015 | 复仇的利刃 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 主角=1, type=char | data/config/rite/5003015.json |

| 5003016 | 饥不择食 | 上城区:[1,6] | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=sudan, 纵欲=1, rare<==2 | data/config/rite/5003016.json |

| 5003017 | 超级大撒币 | 黑街:[2,5] | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=sudan, 奢靡=1, rare<==2<br>s4: type=item, cost.金币=10 | data/config/rite/5003017.json |

| 5003018 | 荣誉杀戮 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=sudan, 杀戮=1, rare<==2 | data/config/rite/5003018.json |

| 5003019 | 孤高之人 | 野外:[1,6] | 0 | 0 | 2 | 1 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=sudan, 征服=1, rare<==2 | data/config/rite/5003019.json |

| 5003020 | 宫廷事务 | 宫廷:[2,6] | 0 | 1 | 1 | 1 | s1: type=char, 贵族=1<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003020.json |

| 5003021 | 皇家图书馆 | 自宅:[2,12] | 0 | 1 | 1 | 1 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003021.json |

| 5003022 | 出卖苦力 | 商业区:[10,19] | 0 | 1 | 1 | 1 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003022.json |

| 5003023 | 在宴会上演出 | 上城区:[1,6] | 0 | 1 | 1 | 1 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003023.json |

| 5003024 | 黑吃黑 | 黑街:[2,5] | 0 | 1 | 1 | 1 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003024.json |

| 5003025 | 酒馆拳斗 | 商业区:[10,19] | 0 | 1 | 1 | 1 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003025.json |

| 5003026 | 狩猎游戏 | 野外:[1,6] | 0 | 1 | 1 | 1 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5003026.json |

| 5003027 | 逃离苏丹的游戏 | 结局:2 | 0 | 0 | 1 | 0 | s1: type=item, 未被苏丹所知=1<br>s2: type=item, any={"破除封锁":1} | data/config/rite/5003027.json |

| 5004001 | 探索黑街 | 黑街:1 | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: any={"is":2000191} | data/config/rite/5004001.json |

| 5004002 | 黑街的居民 | 黑街:[2,5] | 0 | 0 | 0 | 1 | s1: type=char, 黑街居民=1, !追随者=1<br>s2: type=item, cost.金币>==1 | data/config/rite/5004002.json |

| 5004003 | 丢失的钱财 | 黑街:[2,5] | 1 | 0 | 1 | 0 | s1: type=item, cost.金币=[1,2] | data/config/rite/5004003.json |

| 5004004 | 捉贼人的调查 | 黑街:[2,5] | 1 | 0 | 1 | 0 | s1: is=2000067<br>s2: type=item, cost.黑街声望=[1,3]<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5004004.json |

| 5004005 | 轻罪 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: !s2=1, !s3=1, !s4=1, type=sudan, 征服=1, rare==1<br>s2: type=item, !s1=1, !s3=1, !s4=1, cost.金币=2<br>s3: type=item, !s1=1, !s2=1, !s4=1, cost.影响力=1<br>s4: !s1=1, !s2=1, !s3=1, type=char, rare=1 | data/config/rite/5004005.json |

| 5004006 | 中罪 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: !s2=1, !s3=1, !s4=1, type=sudan, 征服=1, rare<==2<br>s2: type=item, !s1=1, !s3=1, !s4=1, cost.金币=5<br>s3: type=item, !s1=1, !s2=1, !s4=1, cost.影响力=2<br>s4: !s1=1, !s2=1, !s3=1, type=char, rare=2 | data/config/rite/5004006.json |

| 5004007 | 重罪 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: !s2=1, !s3=1, !s4=1, type=sudan, 征服=1, rare<==3<br>s2: type=item, !s1=1, !s3=1, !s4=1, cost.金币=10<br>s3: type=item, !s1=1, !s2=1, !s4=1, cost.影响力=3<br>s4: !s1=1, !s2=1, !s3=1, type=char, rare=3 | data/config/rite/5004007.json |

| 5004010 | 扒手团体（废弃） | 黑街:[2,5] | 0 | 0 | 1 | 0 | s1: is=2000303<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5004010.json |

| 5004012 | 你不再被黑街信任 | 黑街:[2,5] | 1 | 0 | 1 | 0 | s1: is=2000191 | data/config/rite/5004012.json |

| 5004013 | 组织犯罪 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: type=item, 犯罪计划=1, !已拥有=1<br>s2: type=item, 犯罪计划=1, !已拥有=1<br>s3: type=item, s1=1, 黑街声望=1, f:s1.犯罪号召-黑街声望<==0<br>s4: type=item, s2=1, 黑街声望=1, f:s2.犯罪号召-黑街声望<==0 | data/config/rite/5004013.json |

| 5004014 | 盗窃范例 | 上城区:[7,12] | 0 | 0 | 1 | 10 | s1: is=2000307<br>s2: type=char, 魅力=4, 男性=1<br>s3: type=char, 贵族=1<br>s4: 体魄=3, type=char | data/config/rite/5004014.json |

| 5004015 | 恐吓范例 | 上城区:[7,12] | 0 | 0 | 1 | 1 | s1: is=2000308<br>s2: type=char, 贵族=1, 反对=1, !追随者=1<br>s3: 隐匿=2, type=char<br>s4: 生存=3, type=char | data/config/rite/5004015.json |

| 5004501 | 向教会求助 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=char, is=2000021<br>s2: type=char, any={"主角":1,"妻子":1} | data/config/rite/5004501.json |

| 5004502 | 虔信的审视 | 神殿区:[2,10] | 0 | 0 | 1 | 1 | s1: type=item, any={"is":2000725}<br>s2: type=char, 主角=1<br>s3: type=char | data/config/rite/5004502.json |

| 5004503 | 忏悔 | 神殿区:[2,10] | 0 | 0 | 1 | 2 | s1: any={"all":{"is":2001167}}<br>s2: type=item, any={"is":2000725}<br>s3: type=item, cost.金币=3 | data/config/rite/5004503.json |

| 5004504 | 仪式的助手 | 神殿区:[2,10] | 0 | 0 | 3 | 3 | s1: type=char, !怪物=1, !动物=1, 魅力>==5<br>s2: type=char, !怪物=1, !动物=1, 魅力>==5<br>s3: type=char, !怪物=1, !动物=1, 魅力>==5 | data/config/rite/5004504.json |

| 5004505 | 整理智库 | 神殿区:[2,10] | 0 | 0 | 3 | 3 | s1: type=char, !怪物=1, !动物=1, 智慧>==5<br>s2: type=char, !怪物=1, !动物=1, 智慧>==5<br>s3: type=char, !怪物=1, !动物=1, 智慧>==5 | data/config/rite/5004505.json |

| 5004506 | 招募信徒 | 神殿区:[2,10] | 0 | 0 | 3 | 3 | s1: type=char, !怪物=1, !动物=1, 社交>==5<br>s2: type=char, !怪物=1, !动物=1, 社交>==5<br>s3: type=char, !怪物=1, !动物=1, 社交>==5 | data/config/rite/5004506.json |

| 5004507 | 神像游行 | 神殿区:[2,10] | 0 | 0 | 3 | 3 | s1: type=char, !怪物=1, !动物=1, 体魄>==5<br>s2: type=char, !怪物=1, !动物=1, 体魄>==5<br>s3: type=char, !怪物=1, !动物=1, 体魄>==5 | data/config/rite/5004507.json |

| 5004508 | 监守自盗 | 神殿区:[2,10] | 0 | 0 | 3 | 3 | s1: type=char, !怪物=1, !动物=1, 魅力>==5, 战斗>==5<br>s2: type=char, !怪物=1, !动物=1, 魅力>==5, 战斗>==5<br>s3: type=item, 思潮=1, any={"is":2000728} | data/config/rite/5004508.json |

| 5004509 | 不再被认可的信仰 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: type=item, 思潮=1, any={"is":2000728} | data/config/rite/5004509.json |

| 5004510 | 温和拘禁 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: type=char, 追随者=1, !怪物=1, !动物=1<br>s2: type=char, 追随者=1, !怪物=1, !动物=1 | data/config/rite/5004510.json |

| 5004511 | 念念不忘 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1 | data/config/rite/5004511.json |

| 5004512 | 全民公敌 | 神殿区:[2,10] | 0 | 0 | 1 | 3 | s1: type=char, !怪物=1, !动物=1<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5004512.json |

| 5004513 | 领受神恩 | 神殿区:[2,10] | 0 | 0 | 1 | 1 | s1: type=char, any={"all":{"is":2001071,"!追随者":1,"锁定祭司":1}}<br>s2: type=char, !怪物=1, !动物=1<br>s3: type=item, cost.金币=[5,10]<br>s4: any={"all":{"s2.主角":1,"s1.is":2000021,"type":"sudan","rare<=":3,"any":{"奢靡":1,"纵欲":1,"杀戮":1}}} | data/config/rite/5004513.json |

| 5004514 | 神啊，为什么 | 神殿区:[2,10] | 0 | 0 | 1 | 7 | s1: type=char, is=2000021<br>s2: type=char, 主角=1<br>s3: type=item, any={"正神的面容":1,"邪神的面容":1}<br>s4: type=item, 思潮=1, any={"is":2000412} | data/config/rite/5004514.json |

| 5004515 | 密室中的祈祷 | 神殿区:[2,10] | 0 | 0 | 1 | 3 | s1: type=char, is=2000021<br>s2: type=char, 主角=1<br>s3: type=sudan, 纵欲=1, rare<==3 | data/config/rite/5004515.json |

| 5004516 | 秘密幽会 | 神殿区:[2,10] | 0 | 0 | 1 | 2 | s1: type=char, is=2000021<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, any={"is":2000844} | data/config/rite/5004516.json |

| 5004517 | 炎日天平 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: type=char, 被抓=1, any={"is":2000021,"主角":1}<br>s2: any={"all":{"counter.7000593<":1,"type":"item","is":2001078,"cost.可堆叠":[1,4]}}<br>s3: type=item, is=2001079, cost.倒计时=[1,3]<br>s4: type=char | data/config/rite/5004517.json |

| 5004518 | 在茉莉花香中…… | 神殿区:[2,10] | 0 | 0 | 1 | 3 | s1: type=char, is=2000021<br>s2: type=char, 主角=1 | data/config/rite/5004518.json |

| 5004519 | 揣测神意 | 神殿区:[2,10] | 0 | 0 | 1 | 2 | s1: type=char, is=2000021<br>s2: type=char, 主角=1<br>s3: type=item, is=2000847<br>s4: type=sudan, 杀戮=1, rare<==3 | data/config/rite/5004519.json |

| 5004520 | 接管教会 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=item, 思潮=1, is=2000728 | data/config/rite/5004520.json |

| 5004521 | 异端之战 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=char, is=2000021, !命运的羁绊=1<br>s2: type=item, is=2001092<br>s3: type=char, 主角=1<br>s4: type=char | data/config/rite/5004521.json |

| 5004522 | 人前显圣 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.金币==20 | data/config/rite/5004522.json |

| 5004523 | 神的仆人 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=item, 思潮=1, any={"is":2000728} | data/config/rite/5004523.json |

| 5004524 | 神圣哗变 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=item, 思潮=1, any={"is":2000728}<br>s3: type=char, is=2000021 | data/config/rite/5004524.json |

| 5004525 | 灵光之试 | 神殿区:[2,10] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=item, 思潮=1, any={"is":2000728} | data/config/rite/5004525.json |

| 5004526 | 选光者 | 神殿区:[2,10] | 0 | 0 | 1 | 3 | s1: type=char, is=2001097<br>s2: type=item, is=2001096, cost.已拥有==1<br>s3: type=char, is=2001098<br>s4: type=item, is=2001096, cost.已拥有==1 | data/config/rite/5004526.json |

| 5004527 | 神之硕鼠 | 神殿区:[2,10] | 0 | 0 | 1 | 2 | s1: cost.正教的乙太=1<br>s2: type=item, cost.金币==10<br>s3: type=item, cost.金币==10, counter.7100004<=13 | data/config/rite/5004527.json |

| 5004801 | 初梦 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1 | data/config/rite/5004801.json |

| 5004802 | 地底的呼唤 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000841 | data/config/rite/5004802.json |

| 5004803 | 心中之神 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000842 | data/config/rite/5004803.json |

| 5004804 | 神的真容 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000843 | data/config/rite/5004804.json |

| 5004805 | 光之训诫 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000845 | data/config/rite/5004805.json |

| 5004806 | 神的启示 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000846 | data/config/rite/5004806.json |

| 5004807 | 神的面容 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000847 | data/config/rite/5004807.json |

| 5004808 | 神圣的会晤 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: any={"is":2000844}<br>s2: any={"is":2000848} | data/config/rite/5004808.json |

| 5004809 | 疯癫与幻觉 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: is=2000326, cost.疯狂=[1,99]<br>s3: type=item, any={"is":2000844}<br>s4: type=item, any={"is":2000848} | data/config/rite/5004809.json |

| 5004810 | 疯癫与幻觉 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: is=2000326, cost.疯狂=[1,99]<br>s3: type=item, any={"is":2000844}<br>s4: type=item, any={"is":2000848} | data/config/rite/5004810.json |

| 5004811 | 疯癫与幻觉 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: is=2000326, cost.疯狂=[1,99]<br>s3: type=item, any={"is":2000844}<br>s4: type=item, any={"is":2000848} | data/config/rite/5004811.json |

| 5004812 | 疯癫与幻觉 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: is=2000326, cost.疯狂=[1,99]<br>s3: type=item, any={"is":2000844}<br>s4: type=item, any={"is":2000848} | data/config/rite/5004812.json |

| 5004813 | 疯癫与幻觉 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: is=2000326, cost.疯狂=[1,99]<br>s3: type=item, any={"is":2000844}<br>s4: type=item, any={"is":2000848} | data/config/rite/5004813.json |

| 5004814 | 疯癫与幻觉 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: is=2000326, cost.疯狂=[1,99]<br>s3: type=item, any={"is":2000844}<br>s4: type=item, any={"is":2000848} | data/config/rite/5004814.json |

| 5004815 | 墙垣之外 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: is=2000326, cost.疯狂=[1,99]<br>s3: any={"is":2000844}<br>s4: any={"is":2000848} | data/config/rite/5004815.json |

| 5004816 | 狂信者之油 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001056<br>s2: type=char, !主角=1 | data/config/rite/5004816.json |

| 5004817 | 消解疯狂 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000326<br>s2: type=char, 主角=1<br>s3: any={"all":{"counter.7000642<":1,"is":2000391},"is":2001308} | data/config/rite/5004817.json |

| 5004818 | 心灵之战Ⅰ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1 | data/config/rite/5004818.json |

| 5004819 | 心灵之战Ⅱ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1, !s7=1 | data/config/rite/5004819.json |

| 5004820 | 心灵之战Ⅲ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1 | data/config/rite/5004820.json |

| 5004821 | 心灵之战Ⅳ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1 | data/config/rite/5004821.json |

| 5004822 | 心灵之战Ⅴ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1, !s7=1 | data/config/rite/5004822.json |

| 5004823 | 心灵之战Ⅵ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1, !s7=1 | data/config/rite/5004823.json |

| 5004824 | 心灵之战Ⅶ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1, !s7=1 | data/config/rite/5004824.json |

| 5004825 | 心灵之战Ⅷ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1, !s7=1 | data/config/rite/5004825.json |

| 5004826 | 心灵之战Ⅸ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1, !s7=1, !s8=1 | data/config/rite/5004826.json |

| 5004827 | 心灵之战Ⅹ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, is=2000723, cost.消耗品=1, !s5=1, !s6=1, !s7=1, !s8=1 | data/config/rite/5004827.json |

| 5004828 | 心灵之战Ⅺ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, any={"all":{"is":2000723,"cost.消耗品":1},"is":2001287}, !s5=1, !s6=1, !s7=1 | data/config/rite/5004828.json |

| 5004829 | 心灵之战Ⅻ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, any={"all":{"is":2000723,"cost.消耗品":1},"is":2001287}, !s5=1, !s6=1 | data/config/rite/5004829.json |

| 5004830 | 心灵之战ⅩⅢ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, any={"all":{"is":2000723,"cost.消耗品":1},"is":2001287}, !s5=1, !s6=1, !s7=1 | data/config/rite/5004830.json |

| 5004831 | 心灵之战ⅩⅣ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, any={"all":{"is":2000723,"cost.消耗品":1},"is":2001287}, !s5=1, !s6=1, !s7=1, !s8=1 | data/config/rite/5004831.json |

| 5004832 | 心灵之战ⅩⅤ | 大敌:6 | 0 | 0 | 1 | 3 | s1: any={"is":2000844}<br>s2: any={"is":2000848}<br>s3: type=char, 主角=1<br>s4: type=item, any={"all":{"is":2000723,"cost.消耗品":1},"is":2001287}, !s5=1, !s6=1, !s7=1, !s8=1 | data/config/rite/5004832.json |

| 5004833 | 造物主的影子 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2001062<br>s2: any={"is":2000723} | data/config/rite/5004833.json |

| 5004834 | 心灵之战ⅩⅥ | 大敌:6 | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: any={"is":2001287} | data/config/rite/5004834.json |

| 5004835 | 遁世秘法 | 结局:8 | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: is=2000317<br>s3: type=char, 命运的羁绊=1<br>s4: type=char, 命运的羁绊=1 | data/config/rite/5004835.json |

| 5004901 | 梅姬不再不满 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000083, cost.不满=[1,99] | data/config/rite/5004901.json |

| 5004902 | 除魔卫道 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: is=2000054<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=item, cost.消耗品==1 | data/config/rite/5004902.json |

| 5004903 | 魅魔之力 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000680 | data/config/rite/5004903.json |

| 5004904 | 父亲的肉 | 野外:[1,14] | 0 | 0 | 1 | 0 | s1: is=2000055<br>s2: is=2000986<br>s3: type=char, 黑暗知识=1 | data/config/rite/5004904.json |

| 5004905 | 浴血玫瑰 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: cost.不满=[1,3], is=2000083<br>s2: 妻子=1, type=char<br>s3: type=char, any={"主角":1,"密教徒":1} | data/config/rite/5004905.json |

| 5004906 | 月牙，我心爱的月牙 | 野外:[1,14] | 1 | 0 | 1 | 0 | s1: is=2000065<br>s2: is=2000989<br>s3: is=2001119 | data/config/rite/5004906.json |

| 5004907 | 神的秘密 | 野外:[1,14] | 1 | 0 | 1 | 0 | s1: is=2000113, 逃跑=1<br>s2: any={"is":2000844} | data/config/rite/5004907.json |

| 5004908 | 信与理的战争 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000022<br>s2: is=2000123 | data/config/rite/5004908.json |

| 5004909 | 拥抱那力量 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000022<br>s2: type=char, is=2000371<br>s3: any={"type":"char","任意处置":1}, !主角=1<br>s4: type=item, cost.金币==5 | data/config/rite/5004909.json |

| 5004910 | 黑暗集会 | 野外:[1,14] | 0 | 0 | 7 | 0 | s1: type=char, 密教徒=1<br>s2: type=char, 密教徒=1<br>s3: type=char, 黑暗知识=1<br>s4: type=item, cost.消耗品==1, 魔力>==1 | data/config/rite/5004910.json |

| 5005101 | 白银纵欲卡 | 宫廷:1 | 0 | 0 | 1 | 0 | s1: type=char, is=2000024<br>s2: type=char, !is=2000024<br>s3: type=sudan, 纵欲=1, rare==3 | data/config/rite/5005101.json |

| 5005102 | 黄金杀戮卡 | 宫廷:1 | 0 | 0 | 1 | 0 | s1: type=char, is=2000024<br>s2: type=char, !is=2000024<br>s3: type=sudan, 杀戮=1, rare==4 | data/config/rite/5005102.json |

| 5005103 | 岩石奢靡卡 | 宫廷:1 | 0 | 0 | 1 | 0 | s1: type=char, is=2000024<br>s2: type=char, is=2000516<br>s3: any={"all":{"type":"char","!is":"2000024"}}<br>s4: type=sudan, 奢靡=1, rare==1 | data/config/rite/5005103.json |

| 5005104 | 青铜征服卡 | 宫廷:1 | 0 | 0 | 1 | 0 | s1: type=char, !is=2000024<br>s2: type=item, is=2000517<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, is=2000518 | data/config/rite/5005104.json |

| 5006001 | 处置背叛的朋友 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000535<br>s2: type=char, 主角=1<br>s3: type=sudan, any={"纵欲":1,"杀戮":1}, rare<==1 | data/config/rite/5006001.json |

| 5006002 | 如你所愿 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000536<br>s2: type=char, 主角=1<br>s3: type=sudan, 纵欲=1, rare<==1 | data/config/rite/5006002.json |

| 5006003 | 我全都要 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char<br>s2: type=item, cost.金币=10<br>s3: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006003.json |

| 5006004 | 我只要最好的 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char<br>s2: type=item, cost.金币=3 | data/config/rite/5006004.json |

| 5006005 | 一日好梦 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: type=item, is=2000083, cost.不满==1 | data/config/rite/5006005.json |

| 5006006 | 慷慨解囊 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=item, cost.金币=10<br>s3: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006006.json |

| 5006007 | 破财消灾 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=item, cost.金币=3 | data/config/rite/5006007.json |

| 5006008 | 投注资金 | 自宅:[2,12] | 0 | 0 | 7 | 7 | s1: type=item, cost.金币=20<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: is=2000539 | data/config/rite/5006008.json |

| 5006009 | 黄金鸟 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char<br>s2: type=item, cost.金币=30<br>s3: type=sudan, 奢靡=1, rare<==4<br>s4: is=2000540 | data/config/rite/5006009.json |

| 5006010 | 处置等死的奴隶 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000534<br>s2: type=char, 主角=1<br>s3: type=sudan, any={"纵欲":1,"杀戮":1}, rare<==1 | data/config/rite/5006010.json |

| 5006011 | 不洁的原料 | 自宅:[4,12] | 0 | 0 | 3 | 10 | s1: any={"all":{"!怪物":1,"!动物":1,"any":{"type":"char","任意处置":1}},"cost.金币":10}<br>s2: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s3: type=char, is=2000352 | data/config/rite/5006011.json |

| 5006012 | 苏丹的诘问 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006012.json |

| 5006013 | 一笔罚款 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=8 | data/config/rite/5006013.json |

| 5006014 | 见证奇迹的时刻 | 自宅:[4,12] | 0 | 0 | 1 | 0 | s1: is=2000554<br>s2: is=2000352<br>s3: type=char, 主角=1 | data/config/rite/5006014.json |

| 5006015 | 行尸动力工坊 | 自宅:[4,12] | 0 | 0 | 3 | 0 | s1: is=2000554<br>s2: is=2000352<br>s3: type=item, is=2000555 | data/config/rite/5006015.json |

| 5006016 | 逐渐完美的造物 | 自宅:[4,12] | 0 | 0 | 3 | 0 | s1: is=2000554<br>s2: any={"type":"char","任意处置":1}, !怪物=1<br>s3: type=sudan, 杀戮=1, f:rare-s2.rare<==0<br>s4: type=item, 装备=1 | data/config/rite/5006016.json |

| 5006017 | 行尸动力工坊 | 自宅:[4,12] | 0 | 0 | 3 | 0 | s1: is=2000554<br>s2: is=2000352<br>s3: type=item, is=2000555 | data/config/rite/5006017.json |

| 5006018 | 苏丹的索要 | 宫廷:[7,10] | 0 | 0 | 1 | 5 | s1: is=2000554 | data/config/rite/5006018.json |

| 5006019 | 苏丹的报复 | 宫廷:[7,10] | 0 | 0 | 1 | 5 | s1: is=2000352 | data/config/rite/5006019.json |

| 5006020 | 创造正强者 | 自宅:[4,12] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: is=2000556<br>s3: is=2000352 | data/config/rite/5006020.json |

| 5006021 | 强者待遇 | 自宅:[4,12] | 1 | 0 | 1 | 0 | s1: type=char, 生命权杖=1<br>s2: 主角=1<br>s3: type=sudan, 纵欲=1, f:rare-s1.rare<==0 | data/config/rite/5006021.json |

| 5006022 | 合金装备·幻痛 | 自宅:[4,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1, 生命权杖=1 | data/config/rite/5006022.json |

| 5006023 | 自然新生 | 自宅:[4,12] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1, 生命权杖=1<br>s2: type=char, is=2000352<br>s3: type=item, cost.消耗品==1, !金币=1, is=2000382<br>s4: type=item, cost.金币=5 | data/config/rite/5006023.json |

| 5006024 | 扩建生命权杖雕塑 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000556, 已拥有=1<br>s2: type=item, cost.金币=20<br>s3: type=sudan, 奢靡=1, rare<==4 | data/config/rite/5006024.json |

| 5006025 | 将权杖送给他人 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000556<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5006025.json |

| 5006026 | 快乐使我旋转 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=char, 主角=1, 生命权杖=1<br>s2: 妓女=1, !追随者=1, !is=2000772<br>s3: type=sudan, 纵欲=1, f:rare-s2.rare<==0 | data/config/rite/5006026.json |

| 5006027 | 御前试合 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: any={"all":{"type":"char","生命权杖":1}}<br>s3: type=sudan, 纵欲=1, rare<==4 | data/config/rite/5006027.json |

| 5006028 | 浴场的焦点 | 上城区:[1,6] | 0 | 0 | 1 | 5 | s1: type=char, is=2000061<br>s2: type=char, 妻子=1<br>s3: type=item, 饰品=1, rare>==3, !is=2001022<br>s4: type=item, cost.不满==1 | data/config/rite/5006028.json |

| 5006029 | 酒与肉 | 上城区:[1,6] | 0 | 0 | 1 | 5 | s1: type=char, is=2000061<br>s2: type=char, 妻子=1<br>s3: type=char, 主角=1 | data/config/rite/5006029.json |

| 5006030 | 巨龙的传说 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000664<br>s2: type=char | data/config/rite/5006030.json |

| 5006031 | 与龙相关的会面 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000054<br>s2: type=char, is=2000061 | data/config/rite/5006031.json |

| 5006032 | 战士不需要的东西 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000061<br>s2: type=char, any={"男性":1,"妻子":1} | data/config/rite/5006032.json |

| 5006033 | 独自前行 | 野外:[1,14] | 0 | 0 | 3 | 5 | s1: type=char, is=2000061<br>s2: type=item, cost.金币=8 | data/config/rite/5006033.json |

| 5006034 | 艰难前行 | 野外:[1,14] | 1 | 0 | 5 | 0 | s1: type=char, is=2000061 | data/config/rite/5006034.json |

| 5006035 | 龙巢探查 | 野外:[1,14] | 0 | 0 | 5 | 0 | s1: type=char, is=2000061<br>s2: type=char, 隐匿>==4<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006035.json |

| 5006036 | 最后的准备 | 商业区:[10,19] | 0 | 0 | 2 | 3 | s1: type=char, is=2000061<br>s2: type=item, cost.金币=20<br>s3: type=sudan, 奢靡=1, rare<==3 | data/config/rite/5006036.json |

| 5006037 | 最后的准备 | 商业区:[10,19] | 0 | 0 | 3 | 3 | s1: type=char, is=2000061<br>s2: type=char, 主角=1<br>s3: type=item, cost.金币=15 | data/config/rite/5006037.json |

| 5006038 | 屠龙的勇行 | 野外:[12,14] | 1 | 0 | 3 | 0 | s1: type=char, is=2000061<br>s2: is=2000332<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006038.json |

| 5006039 | 盛大恩赐 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=sudan | data/config/rite/5006039.json |

| 5006040 | 举世无双的赠礼 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, !动物=1, !怪物=1<br>s2: type=item, is=2000668 | data/config/rite/5006040.json |

| 5006041 | 举世无双的爱 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=item, cost.不满=1 | data/config/rite/5006041.json |

| 5006042 | 上门教学 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 妻子=1<br>s2: type=char, is=2000061 | data/config/rite/5006042.json |

| 5006043 | 梅姬的秘方 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char<br>s2: type=item, is=2000670 | data/config/rite/5006043.json |

| 5006044 | 休憩的方法 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 妻子=1<br>s2: type=char, is=2000061 | data/config/rite/5006044.json |

| 5006045 | 战斗的目的 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 妻子=1<br>s2: type=char, is=2000061 | data/config/rite/5006045.json |

| 5006046 | 屠龙之书 | 自宅:[2,12] | 0 | 0 | 2 | 1 | s1: type=item, is=2000671<br>s2: type=char, 妻子=1<br>s3: type=char, 主角=1 | data/config/rite/5006046.json |

| 5006047 | 必要的准备 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 妻子=1<br>s2: type=item, cost.金币=20<br>s3: type=char, 主角=1<br>s4: type=sudan, 奢靡=1, rare<==3 | data/config/rite/5006047.json |

| 5006048 | 阿迪莱正在寻龙 | 野外:[1,14] | 1 | 0 | 5 | 0 | s1: type=char, is=2000061 | data/config/rite/5006048.json |

| 5006049 | 临行之前 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000061<br>s2: type=item, is=2000666 | data/config/rite/5006049.json |

| 5006050 | 夫妻正应如此 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000083 | data/config/rite/5006050.json |

| 5006051 | 阿迪莱正在冒险 | 野外:[1,14] | 1 | 0 | 1 | 0 | s1: type=char, is=2000061 | data/config/rite/5006051.json |

| 5006052 | 祈福仪式 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=item, cost.金币=[10,20]<br>s2: type=sudan, 奢靡=1, rare<==3<br>s3: type=item, any={"is":2000728} | data/config/rite/5006052.json |

| 5006053 | 梅姬，我问你…… | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 妻子=1 | data/config/rite/5006053.json |

| 5006054 | 屠龙的勇行 | 野外:[1,14] | 1 | 0 | 7 | 0 | s1: type=char, is=2000061 | data/config/rite/5006054.json |

| 5006055 | 于夕色中蔓延…… | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000061<br>s2: type=char, 妻子=1<br>s3: type=item, cost.不满=[1,99] | data/config/rite/5006055.json |

| 5006056 | 婚礼献歌 | 上城区:[1,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000061<br>s2: type=char, is=2000054<br>s3: type=char, any={"主角":1,"妻子":1} | data/config/rite/5006056.json |

| 5006057 | 战士的结合 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000061<br>s2: type=char, is=2000054 | data/config/rite/5006057.json |

| 5006058 | 屠龙之书 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000671<br>s2: type=char, 主角=1, any={"魔力>=":3,"counter.7100005>=":6} | data/config/rite/5006058.json |

| 5006059 | 梦中的考验 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000671<br>s2: type=char, 主角=1, 入梦=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006059.json |

| 5006060 | 梦中的考验 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000671<br>s2: type=char, 主角=1, 入梦=1<br>s3: type=item, 服装=1, rare>==3<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006060.json |

| 5006061 | 梦中的考验 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000671<br>s2: type=char, 主角=1, 入梦=1<br>s3: type=char, 追随者=1 | data/config/rite/5006061.json |

| 5006062 | 梦中的考验 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000671<br>s2: type=char, 主角=1, 入梦=1<br>s3: type=item, cost.金币==30 | data/config/rite/5006062.json |

| 5006063 | 研读结果 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000061<br>s2: type=char, is=2000054<br>s3: type=item, is=2000692 | data/config/rite/5006063.json |

| 5006064 | 探访踪迹 | 野外:[9,14] | 0 | 0 | 3 | 0 | s1: type=char, is=2000061<br>s2: type=char, is=2000054 | data/config/rite/5006064.json |

| 5006065 | 最后的准备 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=char, is=2000352<br>s3: type=item, cost.金币=40<br>s4: type=sudan, 奢靡=1, rare<==4 | data/config/rite/5006065.json |

| 5006066 | 龙巢设伏 | 野外:[9,14] | 0 | 0 | 1 | 0 | s1: type=char, is=2000061<br>s2: type=char, is=2000054<br>s3: type=char, 隐匿>==4<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006066.json |

| 5006067 | 屠龙的勇行 | 野外:[12,14] | 0 | 0 | 2 | 0 | s1: type=char, any={"is":2000054,"all":{"主角":1,"!s2.主角":1,"!s3.主角":1,"!s4.主角":1},"命运的羁绊":1}<br>s2: type=char, any={"is":2000054,"all":{"主角":1,"!s1.主角":1,"!s3.主角":1,"!s4.主角":1},"命运的羁绊":1}<br>s3: type=char, any={"is":2000054,"all":{"主角":1,"!s2.主角":1,"!s1.主角":1,"!s4.主角":1},"命运的羁绊":1}<br>s4: type=char, any={"is":2000054,"all":{"主角":1,"!s2.主角":1,"!s3.主角":1,"!s1.主角":1},"命运的羁绊":1} | data/config/rite/5006067.json |

| 5006068 | 致命一击 | 野外:[9,14] | 1 | 0 | 1 | 0 | s1: type=char, is=2000061, 屠龙者=1<br>s2: type=char, is=2000054, 屠龙者=1<br>s3: type=char, 主角=1, 屠龙者=1<br>s4: type=char, 屠龙者=1 | data/config/rite/5006068.json |

| 5006069 | 解脱 | 野外:[9,14] | 1 | 0 | 1 | 0 | s1: is=2000332<br>s2: type=sudan<br>s3: type=char, 主角=1 | data/config/rite/5006069.json |

| 5006070 | 你需要多少钱 | 自宅:[2,12] | 0 | 0 | 3 | 3 | s1: type=item, cost.金币=3<br>s2: type=char | data/config/rite/5006070.json |

| 5006071 | 血的渴求 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char<br>s2: any={"is":2000412}<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006071.json |

| 5006072 | 处置被俘的异教徒 | 自宅:[2,12] | 0 | 0 | 3 | 1 | s1: is=2000840<br>s2: type=char, 主角=1<br>s3: type=sudan, any={"纵欲":1,"杀戮":1}, f:rare-s1.rare<==0 | data/config/rite/5006072.json |

| 5006073 | 与神沟通 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: 正神的面容=1<br>s2: 邪神的面容=1<br>s3: type=char, 魔力>==5, !s4=1<br>s4: type=char, 魔力>==5, !s3=1 | data/config/rite/5006073.json |

| 5006074 | 让我剖开你胸膛 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=item, any={"is":2000767}<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006074.json |

| 5006075 | 被魔鬼蛊惑之人 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000849<br>s2: type=char<br>s3: type=sudan, 杀戮=1, rare<==3 | data/config/rite/5006075.json |

| 5006076 | 搜寻亡骸 | 野外:[1,6] | 0 | 0 | 7 | 3 | s1: type=char | data/config/rite/5006076.json |

| 5006077 | 愿你安息 | 野外:[1,6] | 0 | 0 | 1 | 7 | s1: type=char, 魔力=5<br>s2: type=item, any={"is":2000728} | data/config/rite/5006077.json |

| 5006078 | 锻造龙鳞装备 | 自宅:[2,12] | 0 | 0 | 4 | 1 | s1: type=item, is=2000949<br>s2: type=item, is=2000949<br>s3: type=item, is=2000949<br>s4: type=item, is=2000949 | data/config/rite/5006078.json |

| 5006079 | 龙头的归属 | 宫廷:1 | 0 | 0 | 0 | 0 | s1: type=item, is=2000954, 正当性=1<br>s2: type=char, is=2000024<br>s3: type=item, is=2000954, 正当性=1<br>s4: type=char, 屠龙苏丹=1, 主角=1 | data/config/rite/5006079.json |

| 5006080 | 直面苏丹 | 结局:7 | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: type=item, is=2000915<br>s3: type=item, is=2000916<br>s4: type=item, is=2000917 | data/config/rite/5006080.json |

| 5006081 | 试刃之锋 | 结局:7 | 1 | 0 | 0 | 0 | s1: type=char, is=2000024<br>s2: type=char, 主角=1, 屠龙苏丹=1<br>s3: 正当性=1, is=2000954<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006081.json |

| 5006082 | 战败者的挽歌 | 结局:7 | 1 | 0 | 0 | 0 | s1: type=char, is=2000024<br>s2: type=char, 主角=1, 屠龙苏丹=1<br>s3: 正当性=1, is=2000954<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006082.json |

| 5006101 | 走廊上的花影 | 上城区:[1,6] | 0 | 0 | 1 | 5 | s1: type=char, is=2000011<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5006101.json |

| 5006102 | 金子、水晶与污泥 | 上城区:[1,6] | 0 | 0 | 1 | 1 | s1: type=item, is=2001200<br>s2: type=char, !怪物=1, !动物=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006102.json |

| 5006103 | 小小守护者 | 黑街:[2,5] | 0 | 0 | 1 | 0 | s1: type=char, !怪物=1, !动物=1<br>s2: type=item, cost.金币=[5,10]<br>s3: s2=1, type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006103.json |

| 5006104 | 故国的遗孤 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2001193<br>s2: any={"主角":1,"妻子":1,"is":2000057} | data/config/rite/5006104.json |

| 5006105 | 萨米尔的失望 | 上城区:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000011, any={"医典锁定":1,"!医典锁定":1}<br>s2: type=item, is=2001200 | data/config/rite/5006105.json |

| 5006106 | 意外的客人 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2001193<br>s2: type=char, is=2000011, any={"医典锁定":1,"!医典锁定":1}<br>s3: type=item, is=2001200 | data/config/rite/5006106.json |

| 5006107 | 萨米尔的感谢 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000011, any={"医典锁定":1,"!医典锁定":1}<br>s2: type=item, is=2001200 | data/config/rite/5006107.json |

| 5006108 | 意外的到访 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2001194<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006108.json |

| 5006109 | 处决 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000011, 医典锁定=1<br>s2: type=char, is=2001194, 医典锁定=1 | data/config/rite/5006109.json |

| 5006110 | 死婴案件调查 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=item, is=2001211, cost.倒计时=[1,10]<br>s2: type=char, 主角=1<br>s3: type=item, any={"is":2001212} | data/config/rite/5006110.json |

| 5006111 | 后宫质询 | 宫廷:[2,6] | 0 | 0 | 1 | 1 | s1: any={"is":2000173}<br>s2: type=char, !动物=1, !怪物=1, 主角=1 | data/config/rite/5006111.json |

| 5006112 | 萨米尔的请求 | 黑街:[2,5] | 1 | 0 | 1 | 0 | s1: is=2000011, 医典锁定=1<br>s2: type=char, 隐匿>==5 | data/config/rite/5006112.json |

| 5006113 | 御医之死 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000011, any={"医典锁定":1,"!医典锁定":1}<br>s2: type=char, is=2001194, 医典锁定=1 | data/config/rite/5006113.json |

| 5006114 | 不愿面对的真相 | 黑街:[2,5] | 1 | 0 | 3 | 0 | s1: is=2000011, 医典锁定=1<br>s2: type=char, !is=2001194, 医典锁定=1 | data/config/rite/5006114.json |

| 5006115 | 不愿面对的真相 | 黑街:[2,5] | 1 | 0 | 5 | 0 | s1: is=2000011, 医典锁定=1 | data/config/rite/5006115.json |

| 5006116 | 医典第一篇 | 上城区:[1,12] | 1 | 0 | 1 | 0 | s1: is=2000011, 医典锁定=1<br>s2: any={"cost.金币=":10,"all":{"type":"char","any":{"生存>=":5,"智慧>=":5}},"is":2000803} | data/config/rite/5006116.json |

| 5006117 | 医典第二篇 | 上城区:[1,12] | 1 | 0 | 1 | 0 | s1: is=2000011, 医典锁定=1<br>s2: any={"is":2000014,"cost.金币=":10,"all":{"type":"char","any":{"战斗>=":5,"隐匿>=":5}}} | data/config/rite/5006117.json |

| 5006118 | 医典编修中 | 上城区:[1,12] | 1 | 0 | 1 | 0 | s1: is=2000011, 医典锁定=1 | data/config/rite/5006118.json |

| 5006119 | 最后篇章 | 上城区:[1,12] | 1 | 0 | 2 | 0 | s1: is=2000011, 医典锁定=1<br>s2: type=char, any={"贵族":1,"all":{"!贵族":1,"智慧>=":5},"is":2000082}, !怪物=1, !动物=1<br>s3: type=char, any={"贵族":1,"all":{"!贵族":1,"智慧>=":5},"is":2000082}, !怪物=1, !动物=1<br>s4: type=char, any={"贵族":1,"all":{"!贵族":1,"智慧>=":5},"is":2000082}, !怪物=1, !动物=1 | data/config/rite/5006119.json |

| 5006120 | 医典编修中 | 上城区:[1,12] | 1 | 0 | 1 | 0 | s1: is=2000011, 医典锁定=1 | data/config/rite/5006120.json |

| 5006121 | 最最最后篇章 | 上城区:[1,12] | 1 | 0 | 2 | 0 | s1: is=2000011, 医典锁定=1 | data/config/rite/5006121.json |

| 5006122 | 僻静之地 | 野外:[1,14] | 0 | 0 | 2 | 0 | s1: type=item, cost.金币==8<br>s2: type=item, cost.金币==8<br>s3: type=sudan, 奢靡=1, rare<==3 | data/config/rite/5006122.json |

| 5006123 | 僻静之地 | 野外:[1,14] | 0 | 0 | 2 | 0 | s1: type=item, cost.金币==8<br>s2: type=item, cost.金币==8<br>s3: type=sudan, 奢靡=1, rare<==3 | data/config/rite/5006123.json |

| 5006124 | 强身之药 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char<br>s2: type=item, is=2001219, cost.可堆叠==1 | data/config/rite/5006124.json |

| 5006125 | 珍贵的样品 | 自宅:[2,12] | 0 | 0 | 5 | 0 | s1: type=item, is=2000382, cost.可堆叠==1 | data/config/rite/5006125.json |

| 5006126 | 治愈伤痛？ | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, 受伤=1<br>s2: type=item, is=2001196 | data/config/rite/5006126.json |

| 5006127 | 不可忽视的痛苦 | 上城区:[1,12] | 0 | 0 | 1 | 0 | s1: any={"cost.金币=":5,"is":2000021}<br>s2: any={"cost.金币=":5,"is":2000021}<br>s3: any={"cost.金币=":5,"is":2000021} | data/config/rite/5006127.json |

| 5006128 | 新药研发 | 上城区:[1,12] | 0 | 0 | 3 | 5 | s1: is=2000011<br>s2: type=char, any={"is":2000352,"智慧>":5}, !动物=1, !怪物=1 | data/config/rite/5006128.json |

| 5006129 | 救命 | 上城区:[1,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000011<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006129.json |

| 5006130 | 诡异的订单 | 上城区:[1,12] | 0 | 0 | 3 | 5 | s1: type=char, is=2000011<br>s2: type=char, any={"is":2000352,"魔力>":5} | data/config/rite/5006130.json |

| 5006131 | 并非为人类准备的 | 上城区:[1,12] | 0 | 0 | 1 | 3 | s1: type=char, !动物=1, !怪物=1<br>s2: type=item, is=2001197<br>s3: type=item, is=2001197<br>s4: type=item, is=2001197 | data/config/rite/5006131.json |

| 5006132 | 失约的惩罚 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006132.json |

| 5006133 | 纹身图样 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001198, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006133.json |

| 5006134 | 夜晚的馈赠 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001218<br>s2: type=item, is=2001199 | data/config/rite/5006134.json |

| 5006135 | 暗夜之饮 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001221<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006135.json |

| 5006136 | 宝石原石 | 商业区:[10,19] | 0 | 0 | 2 | 0 | s1: type=char<br>s2: type=item, cost.金币==2<br>s3: type=item, cost.金币==4<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006136.json |

| 5006137 | 宝石镶嵌 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 装备=1, !动物=1, !怪物=1<br>s2: type=item, 宝石=1, cost.可堆叠==1<br>s3: type=item, cost.金币==2 | data/config/rite/5006137.json |

| 5006138 | 不妥当的珍宝 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=item, is=2001267, !已拥有=1, cost.可堆叠==1<br>s2: type=item, is=2001267, !已拥有=1, cost.可堆叠==1<br>s3: type=item, is=2001267, !已拥有=1, cost.可堆叠==1<br>s4: type=item, is=2001276 | data/config/rite/5006138.json |

| 5006139 | 染血的钻石坑 | 野外:[2,14] | 0 | 0 | 1 | 7 | s1: type=char, is=2001279<br>s2: type=item, is=2001280<br>s3: type=item, is=2001281<br>s4: type=char | data/config/rite/5006139.json |

| 5006140 | 染血的财富 | 野外:[2,14] | 0 | 0 | 3 | 0 | s1: type=char<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.挖矿奴隶=[1,99] | data/config/rite/5006140.json |

| 5006141 | 希望之钻 | 野外:[2,14] | 0 | 0 | 1 | 0 | s1: type=char, any={"is":2000022,"all":{"is":2000369,"命运的羁绊":1}}<br>s2: type=item, is=2001278 | data/config/rite/5006141.json |

| 5006142 | 香烤肥鸽 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001284<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006142.json |

| 5006143 | 宝石之宴 | 上城区:[1,6] | 0 | 0 | 1 | 0 | s1: type=char, any={"妻子":1,"新妻":1}<br>s2: type=item, 已镶嵌=1<br>s3: type=item, 已镶嵌=1<br>s4: type=item, 已镶嵌=1 | data/config/rite/5006143.json |

| 5006144 | 治愈伤痛 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, 受伤=1<br>s2: type=item, is=2001196 | data/config/rite/5006144.json |

| 5006145 | 贵公子的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==5<br>s3: type=item, 宝石=1, 大颗=1, cost.可堆叠==1 | data/config/rite/5006145.json |

| 5006146 | 贵妇人的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==5<br>s3: type=item, 宝石=1, 大颗=1, cost.可堆叠==1<br>s4: type=item, 宝石=1, cost.可堆叠==1 | data/config/rite/5006146.json |

| 5006147 | 小狗的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==5<br>s3: type=item, 宝石=1, cost.可堆叠==1 | data/config/rite/5006147.json |

| 5006148 | 宝石的底板 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, any={"all":{"is":2001275,"any":{"all":{"s2.is":2000771}}}}, cost.可堆叠==1<br>s2: any={"all":{"have.2001275":1,"any":{"all":{"is":2000771,"芮尔":1,"!宝石宣传":1}}}} | data/config/rite/5006148.json |

| 5006149 | 宠妃的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==5<br>s3: type=item, 宝石=1, 大颗=1, cost.可堆叠==1 | data/config/rite/5006149.json |

| 5006150 | 女奴的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==3<br>s3: type=item, 宝石=1, cost.可堆叠==1 | data/config/rite/5006150.json |

| 5006151 | 献给苏丹的珍宝 | 自宅:[2,12] | 0 | 0 | 2 | 7 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==10<br>s3: type=item, 钻石=1, cost.可堆叠==1<br>s4: type=item, 宝石=1, any={"祖母绿":1,"红宝石":1,"蓝宝石":1,"钻石":1} | data/config/rite/5006151.json |

| 5006152 | 苏丹的征召 | 宫廷:[2,6] | 1 | 0 | 3 | 0 | s1: type=char, is=2000019 | data/config/rite/5006152.json |

| 5006153 | 品鉴王冠 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000019<br>s2: type=char, any={"is":2000460}<br>s3: type=char, any={"is":2000065}<br>s4: type=char, any={"is":2000062,"妻子":1,"all":{"is":2000195,"变身公主":1}} | data/config/rite/5006153.json |

| 5006154 | 帝国最好的珠宝匠 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000019 | data/config/rite/5006154.json |

| 5006155 | 年轻人的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==1<br>s3: type=item, 宝石=1, cost.可堆叠==1 | data/config/rite/5006155.json |

| 5006156 | 恋人的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==1<br>s3: type=item, 宝石=1, cost.可堆叠==1 | data/config/rite/5006156.json |

| 5006157 | 母亲的珠宝订单 | 自宅:[2,12] | 0 | 0 | 2 | 0 | s1: type=char, is=2000019<br>s2: type=item, cost.金币==1<br>s3: type=item, 宝石=1, cost.可堆叠==1 | data/config/rite/5006157.json |

| 5006158 | 不一样的宝石 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: type=char, !怪物=1, !动物=1, any={"妻子":1,"is":2000005,"all":{"is":2000123,"贵族":1},"法拉杰":1}<br>s2: type=char, !怪物=1, !动物=1, any={"妻子":1,"is":2000005,"all":{"is":2000123,"贵族":1},"法拉杰":1}<br>s3: type=char, !怪物=1, !动物=1, any={"妻子":1,"is":2000005,"all":{"is":2000123,"贵族":1},"法拉杰":1} | data/config/rite/5006158.json |

| 5006159 | 牛骨大狂热 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000019<br>s2: type=char | data/config/rite/5006159.json |

| 5006165 | 流光溢彩的丝绸 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000697<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006165.json |

| 5006166 | 杀人检查 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000432 | data/config/rite/5006166.json |

| 5006167 | 身体检查 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000433<br>s2: type=char, 和小安纵欲=1 | data/config/rite/5006167.json |

| 5006168 | 人类魔法 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000434 | data/config/rite/5006168.json |

| 5006169 | 人类魔法 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000434<br>s2: type=item, cost.金币=[1,5] | data/config/rite/5006169.json |

| 5006170 | 留的故事 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000434 | data/config/rite/5006170.json |

| 5006171 | 妖精的笼子 | 野外:[1,14] | 0 | 0 | 1 | 0 | s1: type=char, !贵族=1<br>s2: type=item, cost.金币==5<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006171.json |

| 5006172 | 三岔路口 | 野外:[1,14] | 0 | 0 | 1 | 0 | s1: type=item, is=2001320<br>s2: type=item, is=2001321<br>s3: type=item, is=2001322<br>s4: type=char, 主角=1, !is=2000861 | data/config/rite/5006172.json |

| 5006173 | 恳求女王 | 野外:[1,14] | 0 | 0 | 1 | 3 | s1: type=char, 魔力>==5, !s9=1<br>s2: type=char, 魔力>==5, !s9=1<br>s3: type=char, 魔力>==5, !s9=1<br>s4: type=char, 魔力>==5, !s9=1 | data/config/rite/5006173.json |

| 5006174 | 泉水牛肉 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001328<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006174.json |

| 5006175 | 辣子鸡丁 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001329<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006175.json |

| 5006176 | 驴肉火烧 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001330<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006176.json |

| 5006177 | 女王的祝福 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, is=2001327<br>s2: type=char, any={"!怪物":1,"is":2000434}, !动物=1, !女王的祝福=1 | data/config/rite/5006177.json |

| 5006178 | 女王的逃亡 | 野外:[1,14] | 1 | 0 | 1 | 0 | s1: type=item, is=2001327<br>s2: type=char, 女王的祝福=1, !主角=1<br>s3: type=char, 女王的祝福=1, !主角=1<br>s4: type=char, 女王的祝福=1, !主角=1 | data/config/rite/5006178.json |

| 5006179 | 眼球花馕 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001335<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006179.json |

| 5006180 | 杀人汽水 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001336<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006180.json |

| 5006181 | 麻辣蛇脖 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001337<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006181.json |

| 5006182 | 空壳酿肉 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001338<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006182.json |

| 5006183 | 咬人馍 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001339<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006183.json |

| 5006184 | 骷髅泡酒 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001340<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006184.json |

| 5006185 | 魅魔奶茶 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001341<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006185.json |

| 5006186 | 八宝犀牛 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001342<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006186.json |

| 5006501 | 讨伐氏族 | 宫廷:1 | 0 | 0 | 1 | 3 | s1: type=sudan, 征服=1, rare<==2 | data/config/rite/5006501.json |

| 5006502 | 强夺凋零之花 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000062<br>s2: type=char, 主角=1<br>s3: type=sudan, 纵欲=1, f:rare-s1.rare<==0 | data/config/rite/5006502.json |

| 5006503 | 那剧毒的果实 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 妻子=1<br>s2: type=char, 主角=1<br>s3: type=char, is=2000062<br>s4: type=char, is=2000063 | data/config/rite/5006503.json |

| 5006504 | 我们应该分享一切 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 妻子=1<br>s2: type=char, 主角=1<br>s3: type=char, is=2000062 | data/config/rite/5006504.json |

| 5006505 | 这或许不是最好的主意…… | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: type=char, 妻子=1<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=item, cost.不满=1, is=2000083 | data/config/rite/5006505.json |

| 5006506 | 双姝 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=char, is=2000062<br>s3: type=char, 妻子=1<br>s4: type=char, is=2000063 | data/config/rite/5006506.json |

| 5006507 | 花园里唯一的花 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 妻子=1<br>s2: type=item, is=2000083 | data/config/rite/5006507.json |

| 5006508 | 沉默的恳谈 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000063<br>s2: type=char, 主角=1<br>s3: type=char, 妻子=1<br>s4: type=char, is=2000062 | data/config/rite/5006508.json |

| 5006509 | 何为正义 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000063<br>s2: type=char, is=2000062<br>s3: any={"all":{"type":"char","妻子":1}} | data/config/rite/5006509.json |

| 5006510 | 轻易获得快乐 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000063<br>s2: type=char, any={"妻子":1,"主角":1} | data/config/rite/5006510.json |

| 5006511 | 毁尸灭迹 | 上城区:[7,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000063<br>s2: type=char, 主角=1 | data/config/rite/5006511.json |

| 5006512 | 谈判 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000063<br>s2: type=char, 主角=1<br>s3: type=sudan, any={"杀戮":1,"奢靡":1}, rare<==2<br>s4: type=item, cost.金币=[5,10] | data/config/rite/5006512.json |

| 5006513 | 家破人亡 | 上城区:[7,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000063<br>s2: type=char, is=2000062 | data/config/rite/5006513.json |

| 5006514 | 浴池里的波澜 | 上城区:[1,6] | 0 | 0 | 1 | 7 | s1: type=char, 主角=1<br>s2: type=char, is=2000063<br>s3: type=sudan, 纵欲=1, f:rare-s2.rare<==0 | data/config/rite/5006514.json |

| 5006515 | 丑闻缠身 | 野外:[9,10] | 1 | 0 | 1 | 0 | s1: type=char, is=2000063<br>s2: type=char, is=2000062 | data/config/rite/5006515.json |

| 5006516 | 我们也许不该这样 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000063<br>s2: type=char, 主角=1<br>s3: type=char, is=2000062<br>s4: type=sudan, 纵欲=1, rare<==4 | data/config/rite/5006516.json |

| 5006517 | 古语教学 | 自宅:[2,12] | 0 | 0 | 3 | 5 | s1: type=char, is=2000123<br>s2: type=char, 主角=1<br>s3: type=item, cost.金币=[5,10]<br>s4: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006517.json |

| 5006518 | 编修之苦 | 宫廷:[7,10] | 0 | 0 | 1 | 0 | s1: type=char, is=2000123 | data/config/rite/5006518.json |

| 5006519 | 星灵咒文残卷 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=item, is=2000544<br>s2: type=char, is=2000123<br>s3: type=char, 主角=1 | data/config/rite/5006519.json |

| 5006520 | 星灵之夜 | 自宅:[2,12] | 1 | 0 | 3 | 0 | s1: type=char, is=2000123 | data/config/rite/5006520.json |

| 5006521 | 星灵之夜 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000123 | data/config/rite/5006521.json |

| 5006522 | 复仇 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: type=char, is=2000546<br>s2: type=char, is=2000123<br>s3: type=char, 主角=1<br>s4: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5006522.json |

| 5006523 | 孤女复仇记 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000548<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006523.json |

| 5006524 | 受赏 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=item, is=2000083, cost.不满=1 | data/config/rite/5006524.json |

| 5006525 | 受赏 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=item, is=2000083, cost.不满=1 | data/config/rite/5006525.json |

| 5006526 | 在阴影中 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000123<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006526.json |

| 5006527 | 为她买书 | 商业区:[4,5] | 0 | 0 | 1 | 3 | s1: type=char, is=2000123<br>s2: type=item, cost.金币=[5,10]<br>s3: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006527.json |

| 5006528 | 在阴影中 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000123<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, any={"杀戮":1,"征服":1}, rare<==2 | data/config/rite/5006528.json |

| 5006529 | 复仇的滋味 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000549<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006529.json |

| 5006530 | 复仇的滋味 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000550<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006530.json |

| 5006531 | 复仇的滋味 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000551<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006531.json |

| 5006532 | 在阴影中 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000123<br>s2: type=char<br>s3: type=item, cost.金币=5<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006532.json |

| 5006533 | 血之墙 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000552<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006533.json |

| 5006534 | 蠢妓女和活恶棍 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000547<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006534.json |

| 5006535 | 正义必须…… | 上城区:[7,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000063<br>s2: type=char, is=2000062 | data/config/rite/5006535.json |

| 5006536 | 从不缺席的挑战 | 上城区:[1,6] | 0 | 0 | 1 | 5 | s1: type=char, 恶名挑战者=1<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5006536.json |

| 5006537 | 弑父 | 上城区:[7,12] | 0 | 0 | 1 | 5 | s1: is=2000578, 恶名谋杀者=1<br>s2: is=2000579, 恶名谋杀者=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0, !s4=1<br>s4: type=sudan, 杀戮=1, f:rare-s2.rare<==0, !s3=1 | data/config/rite/5006537.json |

| 5006538 | 清流与浊流 | 上城区:[7,12] | 0 | 0 | 1 | 5 | s1: is=2000580, 恶名谋杀者=1<br>s2: is=2000581, 恶名谋杀者=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0, !s4=1<br>s4: type=sudan, 杀戮=1, f:rare-s2.rare<==0, !s3=1 | data/config/rite/5006538.json |

| 5006539 | 三角漩涡 | 上城区:[7,12] | 0 | 0 | 1 | 5 | s1: is=2000582, 恶名谋杀者=1<br>s2: is=2000583, 恶名谋杀者=1<br>s3: is=2000584, 恶名谋杀者=1<br>s4: type=sudan, 杀戮=1, f:rare-s1.rare<==0, !s5=1, !s6=1 | data/config/rite/5006539.json |

| 5006540 | 致命主妇 | 上城区:[7,12] | 0 | 0 | 1 | 5 | s1: is=2000585, 恶名谋杀者=1<br>s2: is=2000586, 恶名谋杀者=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0, !s4=1<br>s4: type=sudan, 杀戮=1, f:rare-s2.rare<==0, !s3=1 | data/config/rite/5006540.json |

| 5006541 | 弑君者 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: is=2000587, 恶名谋杀者=1<br>s2: type=sudan, 杀戮=1, any={"rare=":4} | data/config/rite/5006541.json |

| 5006542 | 杀妻求荣 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2000589, 恶名谋杀者=1<br>s2: is=2000590, 恶名谋杀者=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0, !s4=1<br>s4: type=sudan, 杀戮=1, f:rare-s2.rare<==0, !s3=1 | data/config/rite/5006542.json |

| 5006543 | 殉情的请求 | 上城区:[7,12] | 0 | 0 | 1 | 5 | s1: is=2000591, 恶名谋杀者=1<br>s2: is=2000592, 恶名谋杀者=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0<br>s4: type=sudan, 杀戮=1, f:rare-s2.rare<==0 | data/config/rite/5006543.json |

| 5006544 | 刺杀的阴影 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, cost.蓄谋=[1,999]<br>s2: type=char, 大敌=1<br>s3: type=char, 大敌=1<br>s4: type=char, 大敌=1 | data/config/rite/5006544.json |

| 5006545 | 刺杀的阴影 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, cost.蓄谋=[1,999]<br>s2: type=char, 大敌=1<br>s3: type=char, 大敌=1<br>s4: type=char, 大敌=1 | data/config/rite/5006545.json |

| 5006546 | 刺杀的阴影 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, cost.蓄谋=[1,999]<br>s2: type=char, 大敌=1<br>s3: type=char, 大敌=1<br>s4: type=char, 大敌=1 | data/config/rite/5006546.json |

| 5006547 | 暗巷袭击 | 黑街:[2,5] | 1 | 0 | 1 | 0 | s1: type=char, 追随者=1, 恶名锁定=1<br>s2: type=char, 追随者=1, 恶名锁定=1 | data/config/rite/5006547.json |

| 5006548 | 刺杀的阴影 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, cost.蓄谋=[1,999]<br>s2: type=char, 大敌=1<br>s3: type=char, 大敌=1<br>s4: type=char, 大敌=1 | data/config/rite/5006548.json |

| 5006549 | 他们的复仇 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, cost.蓄谋=[1,999]<br>s2: type=char, is=2000360<br>s3: type=char, 大敌=1<br>s4: type=char, 大敌=1 | data/config/rite/5006549.json |

| 5006550 | 血色绿洲 | 野外:[1,6] | 0 | 0 | 1 | 5 | s1: is=2000595<br>s2: type=sudan, 征服=1, f:rare-s1.rare<==0<br>s3: type=char<br>s4: 部队=1, any={"type":"char","is":"2000554"} | data/config/rite/5006550.json |

| 5006551 | 玩泥巴的异族 | 野外:[1,6] | 0 | 0 | 1 | 5 | s1: is=2000596<br>s2: type=sudan, 征服=1, f:rare-s1.rare<==0<br>s3: type=char<br>s4: 部队=1, any={"type":"char","is":"2000554"} | data/config/rite/5006551.json |

| 5006552 | 劫掠商队 | 野外:[1,6] | 0 | 0 | 1 | 5 | s1: is=2000597<br>s2: type=sudan, 征服=1, f:rare-s1.rare<==0<br>s3: type=char<br>s4: 部队=1, any={"type":"char","is":"2000554"} | data/config/rite/5006552.json |

| 5006553 | 傲慢之罪 | 野外:[1,6] | 0 | 0 | 1 | 5 | s1: is=2000598<br>s2: type=sudan, 征服=1, f:rare-s1.rare<==0<br>s3: type=char<br>s4: 部队=1, any={"type":"char","is":"2000554"} | data/config/rite/5006553.json |

| 5006554 | 富有的巨魔 | 野外:[1,6] | 0 | 0 | 1 | 5 | s1: is=2000599<br>s2: type=sudan, 征服=1, f:rare-s1.rare<==0<br>s3: type=char<br>s4: 部队=1, any={"type":"char","is":"2000554"} | data/config/rite/5006554.json |

| 5006555 | 邪恶化身 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1 | data/config/rite/5006555.json |

| 5006556 | 连你也…… | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, 追随者=1, !怪物=1<br>s2: type=char, 追随者=1, !怪物=1<br>s3: type=char, 追随者=1, !怪物=1<br>s4: type=char, 大敌=1 | data/config/rite/5006556.json |

| 5006557 | 神秘的援助 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: any={"type":"sudan"}, !秘宝=1, !is=2001327 | data/config/rite/5006557.json |

| 5006558 | 复原的神迹 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=sudan | data/config/rite/5006558.json |

| 5006559 | 净化之火 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=sudan | data/config/rite/5006559.json |

| 5006560 | 修建舍馆 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: type=item, 空屋=1<br>s2: type=item, cost.金币=10<br>s3: type=sudan, 奢靡=1, rare==1 | data/config/rite/5006560.json |

| 5006561 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s2: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s3: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s4: type=char, s1=1, !有跟班=1 | data/config/rite/5006561.json |

| 5006562 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, 暂留的食客1=1<br>s2: type=char, 食客=1, !追随者=1, 暂留的食客2=1<br>s3: type=char, 食客=1, !追随者=1, 暂留的食客3=1<br>s4: type=char, s1=1, !有跟班=1 | data/config/rite/5006562.json |

| 5006563 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s2: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s3: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s4: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1 | data/config/rite/5006563.json |

| 5006564 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, 暂留的食客1=1<br>s2: type=char, 食客=1, !追随者=1, 暂留的食客2=1<br>s3: type=char, 食客=1, !追随者=1, 暂留的食客3=1<br>s4: type=char, 食客=1, !追随者=1, 暂留的食客4=1 | data/config/rite/5006564.json |

| 5006565 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s2: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s3: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s4: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1 | data/config/rite/5006565.json |

| 5006566 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, 暂留的食客1=1<br>s2: type=char, 食客=1, !追随者=1, 暂留的食客2=1<br>s3: type=char, 食客=1, !追随者=1, 暂留的食客3=1<br>s4: type=char, 食客=1, !追随者=1, 暂留的食客4=1 | data/config/rite/5006566.json |

| 5006567 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s2: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s3: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1<br>s4: type=char, 食客=1, !追随者=1, !暂留的食客1=1, !暂留的食客2=1, !暂留的食客3=1, !暂留的食客4=1, !暂留的食客5=1, !暂留的食客6=1 | data/config/rite/5006567.json |

| 5006568 | 舍馆 | 商业区:[10,19] | 0 | 0 | 0 | 0 | s1: type=char, 食客=1, !追随者=1, 暂留的食客1=1<br>s2: type=char, 食客=1, !追随者=1, 暂留的食客2=1<br>s3: type=char, 食客=1, !追随者=1, 暂留的食客3=1<br>s4: type=char, 食客=1, !追随者=1, 暂留的食客4=1 | data/config/rite/5006568.json |

| 5006569 | 隐匿小屋 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: type=item, 空屋=1<br>s2: type=item, cost.金币=8<br>s3: type=item, is=2000558 | data/config/rite/5006569.json |

| 5006570 | 隐匿小屋 | 黑街:[2,5] | 0 | 0 | 7 | 0 | s1: type=item, is=2000558, cost.罪证=[1,3]<br>s2: type=item, cost.金币=[1,3] | data/config/rite/5006570.json |

| 5006571 | 罪犯的投奔 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: any={"type":"item"}, 罪犯投奔=1<br>s2: any={"type":"char","all":{"type":"sudan","杀戮":"1","f:rare-s1.rare<=":0}} | data/config/rite/5006571.json |

| 5006572 | 老兵不死 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006572.json |

| 5006573 | 军事行动 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006573.json |

| 5006574 | 邪恶徽记 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006574.json |

| 5006575 | 军中霸凌 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006575.json |

| 5006576 | 血肉之税 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006576.json |

| 5006577 | 民间集资 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006577.json |

| 5006578 | 包税人之死 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006578.json |

| 5006579 | 苏丹的索求 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006579.json |

| 5006580 | 先王的后宫 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=sudan, 杀戮=1, rare==4 | data/config/rite/5006580.json |

| 5006581 | 打击腐败 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006581.json |

| 5006582 | 监督官吏 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006582.json |

| 5006583 | 损坏的器皿 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006583.json |

| 5006584 | 血统调查 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000349<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1<br>s4: type=item, cost.消耗品==1 | data/config/rite/5006584.json |

| 5006585 | 赤字滔天 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, cost.赤字=[1,999]<br>s2: type=item, cost.金币=15<br>s3: type=char<br>s4: type=char | data/config/rite/5006585.json |

| 5006586 | 民众的代表 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=item, cost.国民的好感=[1,3]<br>s2: type=char, 主角=1, 宰相=1 | data/config/rite/5006586.json |

| 5006587 | 休沐日 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, cost.官吏的好感=[1,3]<br>s2: type=char, 主角=1, 宰相=1 | data/config/rite/5006587.json |

| 5006588 | 战争迷雾 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, cost.军队的好感=[1,3]<br>s2: type=char, 主角=1, 宰相=1 | data/config/rite/5006588.json |

| 5006589 | 民意之盾 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: is=2000678 | data/config/rite/5006589.json |

| 5006590 | 权势之盾 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: is=2000679 | data/config/rite/5006590.json |

| 5006591 | 苏丹的猜忌 | 宫廷:[2,6] | 1 | 0 | 1 | 1 | s1: is=2000672 | data/config/rite/5006591.json |

| 5006592 | 焚书 | 商业区:3 | 1 | 0 | 0 | 1 | s1: is=2000199, 书店老板=1<br>s2: any={"is":2000161}<br>s3: type=sudan, rare<==3, any={"杀戮":1,"征服":1,"奢靡":1}<br>s4: is=2001152 | data/config/rite/5006592.json |

| 5006593 | 管不住的老婆 | 自宅:[2,12] | 1 | 0 | 7 | 1 | s1: 妻子=1, type=char | data/config/rite/5006593.json |

| 5006594 | 如你所愿 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000684<br>s2: type=char, 主角=1<br>s3: type=sudan, 纵欲=1, rare<==1 | data/config/rite/5006594.json |

| 5006595 | 未归人 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: 妻子=1, type=char<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品=1, !金币=1 | data/config/rite/5006595.json |

| 5006596 | 心有余悸 | 自宅:[2,12] | 1 | 0 | 3 | 1 | s1: 妻子=1, type=char | data/config/rite/5006596.json |

| 5006597 | 再进一步 | 自宅:[2,12] | 1 | 0 | 3 | 1 | s1: is=2000055 | data/config/rite/5006597.json |

| 5006598 | 更进一步 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000055 | data/config/rite/5006598.json |

| 5006599 | 恶毒的花嫁 | 自宅:[2,12] | 0 | 0 | 1 | 14 | s1: is=2000055<br>s2: type=char, 主角=1<br>s3: type=item, any={"奇珍":1,"饰品":1}, rare==4, !is=2001022<br>s4: type=sudan, any={"奢靡":1,"杀戮":1,"征服":1,"纵欲":1} | data/config/rite/5006599.json |

| 5006600 | 娜依拉需要你的钱 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: is=2000055<br>s2: type=item, cost.金币=10 | data/config/rite/5006600.json |

| 5006601 | 娜依拉需要你 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: is=2000055<br>s2: type=char, 主角=1 | data/config/rite/5006601.json |

| 5006602 | 娜依拉的不满 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000055<br>s2: cost.金币=[1,9999]<br>s3: is=2000698, cost.娜依拉的不满=[1,99] | data/config/rite/5006602.json |

| 5006603 | 除非…… | 自宅:[2,12] | 0 | 0 | 3 | 1 | s1: is=2000055<br>s2: type=item, cost.金币=30<br>s3: type=char, 主角=1<br>s4: type=item, cost.消耗品=1, !金币=1 | data/config/rite/5006603.json |

| 5006604 | 你最好是真的 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000055<br>s2: type=char, 主角=1, !s3=1<br>s3: type=char, 主角=1, !s2=1 | data/config/rite/5006604.json |

| 5006605 | 病弱的老女奴 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2000699<br>s2: type=item, cost.金币=[1,5] | data/config/rite/5006605.json |

| 5006606 | 难以治愈的疾病 | 商业区:[4,5] | 0 | 0 | 3 | 3 | s1: is=2000699<br>s2: type=item, cost.金币=3<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006606.json |

| 5006607 | 无法治愈的疾病 | 商业区:[4,5] | 0 | 0 | 3 | 3 | s1: is=2000699<br>s2: type=item, cost.金币=5 | data/config/rite/5006607.json |

| 5006608 | 不可阻挡的死亡 | 商业区:[4,5] | 1 | 0 | 1 | 0 | s1: is=2000699 | data/config/rite/5006608.json |

| 5006609 | 促成交欢 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: is=2000055<br>s2: type=char, any={"主角":1,"is":2000054} | data/config/rite/5006609.json |

| 5006610 | 移除诅咒（已弃用） | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: is=2000703<br>s2: type=char, 诅咒=1 | data/config/rite/5006610.json |

| 5006611 | 帝国的勇士 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: is=2000055<br>s2: type=char, 主角=1 | data/config/rite/5006611.json |

| 5006612 | 帝国的勇士 | 上城区:[7,12] | 0 | 0 | 1 | 7 | s1: is=2000055<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006612.json |

| 5006613 | 帝国勇士排行榜 | 自宅:[2,12] | 0 | 0 | 3 | 1 | s1: is=2000704<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006613.json |

| 5006614 | 帝国勇士排行榜 | 自宅:[2,12] | 0 | 0 | 3 | 1 | s1: is=2000705<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006614.json |

| 5006615 | 帝国勇士排行榜 | 自宅:[2,12] | 0 | 0 | 3 | 1 | s1: is=2000706<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006615.json |

| 5006616 | 救济日 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=5<br>s2: type=sudan, rare==1, any={"杀戮":1,"纵欲":1}<br>s3: type=item, any={"is":2000728} | data/config/rite/5006616.json |

| 5006617 | 美味的救济日 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=5<br>s2: type=char, is=2000371<br>s3: type=char, is=2000369 | data/config/rite/5006617.json |

| 5006618 | 赏赐 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=1 | data/config/rite/5006618.json |

| 5006619 | 让我尝尝 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000371<br>s2: type=char, 主角=1<br>s3: type=char, 妻子=1<br>s4: type=char, is=2000369 | data/config/rite/5006619.json |

| 5006620 | 背叛和逃亡 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000369<br>s2: type=char, is=2000371 | data/config/rite/5006620.json |

| 5006621 | 巨大的玩具 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000369<br>s2: type=char, any={"is":2000055}<br>s3: type=char, 主角=1<br>s4: type=sudan, 纵欲=1, rare<==3 | data/config/rite/5006621.json |

| 5006622 | 石餐盒 | 自宅:[2,12] | 0 | 1 | 2 | 2 | s1: type=char, is=2000369 | data/config/rite/5006622.json |

| 5006623 | 大量石餐盒 | 自宅:[2,12] | 0 | 0 | 8 | 3 | s1: type=char, is=2000369 | data/config/rite/5006623.json |

| 5006624 | 餐盒收购 | 自宅:[2,12] | 0 | 0 | 1 | 14 | s1: type=item, is=2000732<br>s2: type=item, is=2000732<br>s3: type=item, is=2000732 | data/config/rite/5006624.json |

| 5006625 | 沙尘往事 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, is=2000369<br>s2: type=item, 思潮=1, any={"is":2000172} | data/config/rite/5006625.json |

| 5006626 | 主人的宴会 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000369 | data/config/rite/5006626.json |

| 5006627 | 所有人的宴会 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=char, is=2000369<br>s3: type=char, !is=2000369, !主角=1<br>s4: type=char, !is=2000369, !主角=1 | data/config/rite/5006627.json |

| 5006628 | 吹响骨笛 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=item, is=2000734<br>s2: type=item, cost.金币=8 | data/config/rite/5006628.json |

| 5006629 | 无法拒绝的安慰 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000371<br>s2: type=char, 主角=1<br>s3: type=sudan, 纵欲=1, f:rare-s1.rare<==0 | data/config/rite/5006629.json |

| 5006630 | 成婚 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000371<br>s2: type=char, 主角=1<br>s3: type=item, cost.金币=5<br>s4: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006630.json |

| 5006631 | 彻夜狂奔 | 野外:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000371<br>s2: type=char, is=2000369<br>s3: type=char, !妻子=1<br>s4: type=char, !妻子=1 | data/config/rite/5006631.json |

| 5006632 | 寸步不离 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000371<br>s2: type=char, !贵族=1 | data/config/rite/5006632.json |

| 5006633 | 息事宁人 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000738<br>s2: type=item, cost.金币=10 | data/config/rite/5006633.json |

| 5006634 | 处置奴隶 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000738<br>s2: type=char, is=2000371 | data/config/rite/5006634.json |

| 5006635 | 私下调查 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, 贵族=1 | data/config/rite/5006635.json |

| 5006636 | 下次还敢吗？ | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000738<br>s2: type=char, 主角=1<br>s3: type=sudan, f:rare-s1.rare<==0, any={"杀戮":1,"纵欲":1,"征服":1}<br>s4: any={"部队":1,"all":{"type":"item","cost.消耗品=":1,"!金币":1}} | data/config/rite/5006636.json |

| 5006637 | 强取 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000371 | data/config/rite/5006637.json |

| 5006638 | 郁郁寡欢 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000369<br>s2: type=item, any={"is":2000541} | data/config/rite/5006638.json |

| 5006639 | 进贡 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=item, cost.金币=20, !s4=1, !s5=1<br>s4: type=item, rare==4, 装备=1, !s3=1, !s5=1 | data/config/rite/5006639.json |

| 5006640 | 强取 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: type=char, is=2000371 | data/config/rite/5006640.json |

| 5006641 | 当堂对峙 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: type=char, is=2000738<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006641.json |

| 5006642 | 自由之人 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000371<br>s2: type=item, 饰品=1, !is=2001022 | data/config/rite/5006642.json |

| 5006643 | 冗长的问询 | 宫廷:[7,10] | 0 | 0 | 1 | 2 | s1: type=char<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006643.json |

| 5006644 | 宫门募捐 | 宫廷:[7,10] | 0 | 0 | 1 | 2 | s1: type=item, cost.金币=3 | data/config/rite/5006644.json |

| 5006645 | 被弃的丑态 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, !主角=1, 贵族=1<br>s2: type=item, is=2000680 | data/config/rite/5006645.json |

| 5006646 | 穷人到底需要什么？ | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1, !s2=1, !s3=1, !s4=1<br>s2: type=item, cost.金币=5, !s1=1, !s3=1, !s4=1<br>s3: type=item, any={"is":2000728}, !s1=1, !s2=1, !s4=1<br>s4: type=char, !s1=1, !s2=1, !s3=1 | data/config/rite/5006646.json |

| 5006647 | 母亲的水滴 | 野外:[9,14] | 0 | 0 | 3 | 5 | s1: type=item, cost.金币=6 | data/config/rite/5006647.json |

| 5006648 | 奈费勒的行动 | 野外:[9,14] | 0 | 0 | 3 | 5 | s1: type=item, cost.金币=6 | data/config/rite/5006648.json |

| 5006649 | 带来的改变 | 上城区:[7,12] | 0 | 0 | 1 | 14 | s1: type=char, is=2000312<br>s2: type=char, 主角=1 | data/config/rite/5006649.json |

| 5006650 | 神之恩 | 野外:[9,14] | 0 | 0 | 3 | 5 | s1: type=item, cost.金币=6<br>s2: type=item, 思潮=1, any={"is":2000728} | data/config/rite/5006650.json |

| 5006651 | 奈费勒的行动 | 野外:[9,14] | 0 | 0 | 3 | 5 | s1: type=item, cost.金币=6<br>s2: type=item, 思潮=1, any={"is":2000728} | data/config/rite/5006651.json |

| 5006652 | 未能改变的 | 上城区:[7,12] | 0 | 0 | 1 | 14 | s1: type=char, is=2000312<br>s2: type=char, 主角=1 | data/config/rite/5006652.json |

| 5006653 | 黄金的工具 | 野外:[9,14] | 0 | 0 | 3 | 5 | s1: type=item, cost.金币=6<br>s2: type=char, 智慧>==4 | data/config/rite/5006653.json |

| 5006654 | 奈费勒的行动 | 野外:[9,14] | 0 | 0 | 3 | 5 | s1: type=item, cost.金币=6 | data/config/rite/5006654.json |

| 5006655 | 带来希望的 | 上城区:[7,12] | 0 | 0 | 1 | 14 | s1: type=char, is=2000312<br>s2: type=char, 主角=1 | data/config/rite/5006655.json |

| 5006656 | 惩罚之火 | 野外:[9,14] | 0 | 0 | 1 | 14 | s1: type=char, 隐匿>==5, 已装备<=1, !主角=1<br>s2: type=item, cost.金币=10<br>s3: type=char, 火焰大王=1, is=2000762 | data/config/rite/5006656.json |

| 5006657 | 劫富济贫 | 商业区:[10,19] | 0 | 0 | 3 | 5 | s1: type=char, is=2000762, 火焰大王=1<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006657.json |

| 5006658 | 正义复仇 | 商业区:[10,19] | 0 | 0 | 3 | 5 | s1: type=char, is=2000762, 火焰大王=1<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006658.json |

| 5006659 | 恐怖庄园 | 野外:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000762, 火焰大王=1 | data/config/rite/5006659.json |

| 5006660 | 勇气与团结 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000762, 火焰大王=1<br>s2: type=char, 主角=1<br>s3: type=char, is=2000312 | data/config/rite/5006660.json |

| 5006661 | 烈焰呼唤 | 自宅:14 | 0 | 0 | 1 | 14 | s1: type=char, 已装备<=1<br>s2: type=char, 火焰大王=1, is=2000762 | data/config/rite/5006661.json |

| 5006662 | 清流交汇 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000312<br>s2: type=char, is=2000764<br>s3: type=char, is=2000765<br>s4: type=char, is=2000766 | data/config/rite/5006662.json |

| 5006663 | 干净的队伍 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000312<br>s2: type=char, is=2000764<br>s3: type=char, 主角=1 | data/config/rite/5006663.json |

| 5006664 | 享用美酒 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=char, !主角=1<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5006664.json |

| 5006665 | 被独自关押的奈费勒 | 宫廷:[7,10] | 0 | 0 | 1 | 10 | s1: type=char, is=2000312, 囚徒奈费勒=1<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, f:rare-s1.rare<==0 | data/config/rite/5006665.json |

| 5006666 | 干净的队伍 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000312<br>s2: type=char, is=2000764<br>s3: type=char, is=2000765<br>s4: type=char, is=2000766 | data/config/rite/5006666.json |

| 5006667 | 忠心可鉴 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=6 | data/config/rite/5006667.json |

| 5006668 | 沉重的代价 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: type=item, 奇珍=1, rare>==3 | data/config/rite/5006668.json |

| 5006669 | 恶意的捉弄 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=6 | data/config/rite/5006669.json |

| 5006670 | 恶意的玩笑 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: any={"all":{"type":"item","cost.金币":6}}<br>s2: s1.主角=1, type=sudan, 纵欲=1, rare<==2 | data/config/rite/5006670.json |

| 5006671 | 流浊之地 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000312<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006671.json |

| 5006672 | 囚犯与绑匪 | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: type=char, is=2000349, 等死吧阿卜德=1<br>s2: type=char, is=2000312<br>s3: type=char<br>s4: type=item, is=2000768 | data/config/rite/5006672.json |

| 5006673 | 一则蹊跷的新闻 | 上城区:[7,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000312 | data/config/rite/5006673.json |

| 5006674 | 无用的施舍 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币==3<br>s2: type=sudan, 奢靡=1, rare==1 | data/config/rite/5006674.json |

| 5006675 | 异想天开的构思 | 上城区:[7,12] | 0 | 0 | 3 | 7 | s1: type=char, is=2000312<br>s2: type=item, cost.金币=[10,20]<br>s3: type=sudan, 奢靡=1, rare<==2, s2.金币=20 | data/config/rite/5006675.json |

| 5006676 | 苗圃 | 奇珍:9 | 1 | 0 | 1 | 0 | s1: type=char, is=2000312<br>s2: type=item, 爱=1<br>s3: type=item, 智=1<br>s4: type=item, 信=1 | data/config/rite/5006676.json |

| 5006677 | 苗圃 | 奇珍:9 | 0 | 0 | 1 | 0 | s1: !已收容=1, any={"孤儿":1,"妻子":1,"is":2000989,"all":{"any":{"is":2000728}}}<br>s2: type=item, cost.金币=5<br>s3: type=item, 爱=1<br>s4: type=item, 智=1 | data/config/rite/5006677.json |

| 5006678 | 最后的愿望 | 商业区:1 | 0 | 0 | 1 | 5 | s1: type=char, is=2000899<br>s2: type=char<br>s3: 火焰大王=1<br>s4: type=item, is=2000382 | data/config/rite/5006678.json |

| 5006679 | 可疑的金币 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2001190<br>s2: type=char, !怪物=1, !动物=1 | data/config/rite/5006679.json |

| 5006680 | 吐露真相 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000005<br>s2: type=char, 主角=1, !s3=1, !s4=1<br>s3: type=char, 主角=1, !s2=1, !s4=1<br>s4: type=char, 主角=1, !s2=1, !s3=1 | data/config/rite/5006680.json |

| 5006681 | 审问 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: is=2000005<br>s2: type=char, !怪物=1, !动物=1<br>s3: type=char, !怪物=1, !动物=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006681.json |

| 5006682 | 搜刮 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006682.json |

| 5006683 | 苏丹的质询 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=item, is=2000029, cost.金币=10<br>s3: type=item, is=2001190, cost.金币=10<br>s4: type=item, is=2001191 | data/config/rite/5006683.json |

| 5006684 | 满足苏丹 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: type=item, is=2000029, cost.金币=10<br>s3: type=item, is=2001190, cost.金币=10<br>s4: type=item, is=2001191 | data/config/rite/5006684.json |

| 5006685 | 造币 | 自宅:[2,12] | 0 | 0 | 3 | 0 | s1: type=char, !怪物=1, !动物=1<br>s2: type=char<br>s3: type=item, is=2000029, cost.金币=10<br>s4: type=char | data/config/rite/5006685.json |

| 5006686 | 一道名菜 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=item, any={"情诗":1,"史诗":1,"讽刺诗":1,"预言诗":1}<br>s2: type=char, is=2000460<br>s3: type=char, 主角=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006686.json |

| 5006687 | 报菜名 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001192<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006687.json |

| 5006688 | 当我们谈论爱情的时候 | 上城区:[1,6] | 0 | 0 | 1 | 0 | s1: type=char, is=2000460<br>s2: type=char, 女性=1 | data/config/rite/5006688.json |

| 5006689 | 作祟 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000460<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006689.json |

| 5006690 | 哈桑的苦役 | 上城区:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000001<br>s2: type=char, is=2000001<br>s3: type=char, is=2000001<br>s4: type=char, is=2000001 | data/config/rite/5006690.json |

| 5006691 | 欢愉之诗 | 商业区:[10,19] | 1 | 0 | 3 | 0 | s1: type=char, is=2000460 | data/config/rite/5006691.json |

| 5006692 | 苗圃的学习 | 商业区:[10,19] | 1 | 0 | 3 | 0 | s1: type=char, is=2000460 | data/config/rite/5006692.json |

| 5006693 | 艺术顾问 | 商业区:[7,10] | 1 | 0 | 3 | 0 | s1: type=char, is=2000460 | data/config/rite/5006693.json |

| 5006694 | 宫廷诗人 | 宫廷:[2,6] | 1 | 0 | 3 | 0 | s1: type=char, is=2000460 | data/config/rite/5006694.json |

| 5006695 | 诗人的名望 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, is=2000460<br>s2: type=item, any={"情诗":1,"讽刺诗":1,"史诗":1,"预言诗":1}<br>s3: type=char, 贵族=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006695.json |

| 5006696 | 诗人的羊 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000460<br>s2: type=char, 主角=1, is=2000001<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=char, any={"is":2000861} | data/config/rite/5006696.json |

| 5006697 | 奇怪的攻击 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000460<br>s2: type=char, is=2000001<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: is=2001201 | data/config/rite/5006697.json |

| 5006698 | 一桩怪谈 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001208<br>s2: type=char, any={"is":2000861} | data/config/rite/5006698.json |

| 5006699 | 你怎么敢咩！ | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000460<br>s2: type=char, is=2000001<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: is=2001204 | data/config/rite/5006699.json |

| 5006700 | 命运的书店 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=char, is=2000001<br>s2: type=char, any={"is":2000861}<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006700.json |

| 5006701 | 诗人来访 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, is=2000460<br>s2: any={"all":{"type":"char","诅咒":1},"is":2000326} | data/config/rite/5006701.json |

| 5006702 | 珠宝匠来访 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, is=2000019<br>s2: any={"all":{"type":"char","诅咒":1},"is":2000326} | data/config/rite/5006702.json |

| 5006703 | 舞姬的拜访 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, is=2000129<br>s2: any={"all":{"type":"char","诅咒":1},"is":2000326} | data/config/rite/5006703.json |

| 5006704 | 喵，喵喵 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, is=2000461<br>s2: any={"all":{"type":"char","诅咒":1},"is":2000326} | data/config/rite/5006704.json |

| 5006705 | 妆娘造访 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, is=2000459<br>s2: any={"all":{"type":"char","诅咒":1},"is":2000326} | data/config/rite/5006705.json |

| 5006706 | 同命鸟 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, is=2000861<br>s2: any={"all":{"type":"char","诅咒":1},"is":2000326} | data/config/rite/5006706.json |

| 5006710 | 书店老板上门 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000199<br>s2: is=2001230<br>s3: type=item, cost.金币=5 | data/config/rite/5006710.json |

| 5006711 | 难解之意 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001230, 正在阅读=1<br>s2: type=char, 主角=1 | data/config/rite/5006711.json |

| 5006712 | 奇怪的流言 | 黑街:[2,9] | 0 | 0 | 1 | 3 | s1: type=char, !主角=1<br>s2: type=item, any={"all":{"!金币":1,"cost.消耗品=":1},"cost.金币":3} | data/config/rite/5006712.json |

| 5006713 | 午夜欢宴 | 黑街:[2,9] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1, 欢宴之主=1 | data/config/rite/5006713.json |

| 5006714 | 更加奇怪的流言 | 黑街:[2,9] | 0 | 0 | 1 | 3 | s1: type=char, !主角=1<br>s2: type=item, any={"all":{"!金币":1,"cost.消耗品=":1},"cost.金币":5} | data/config/rite/5006714.json |

| 5006715 | 凡人的研究 | 商业区:[10,19] | 0 | 0 | 3 | 2 | s1: type=char, is=2000199, 锁定阿萨尔=1<br>s2: type=char, f:智慧+魔力+0>==10 | data/config/rite/5006715.json |

| 5006716 | 午夜欢宴 | 黑街:[2,9] | 1 | 0 | 1 | 0 | s1: type=char, is=2000199, 锁定阿萨尔=1<br>s2: type=item, is=2001232<br>s3: type=char, 主角=1, 欢宴之主=1<br>s4: type=char | data/config/rite/5006716.json |

| 5006717 | 来龙去脉 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000199<br>s2: type=sudan, 杀戮=1, f:s2.rare-s1.rare<==0 | data/config/rite/5006717.json |

| 5006718 | 百科全书 | 奇珍:15 | 0 | 0 | 1 | 0 | s1: type=item, is=2001235<br>s2: type=item, is=2001236<br>s3: type=item, is=2001237<br>s4: type=item, is=2001238 | data/config/rite/5006718.json |

| 5006719 | 敲门砖 | 上城区:[7,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000199<br>s2: type=item, is=2001247<br>s3: type=char, 主角=1<br>s4: type=item, 读物=1, rare>==3 | data/config/rite/5006719.json |

| 5006720 | 书窖 | 上城区:[7,12] | 0 | 0 | 1 | 1 | s1: type=char, is=2000199<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006720.json |

| 5006721 | 抄书人 | 上城区:[7,12] | 1 | 0 | 5 | 0 | s1: type=char, is=2000199 | data/config/rite/5006721.json |

| 5006722 | 归木于林 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000199<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006722.json |

| 5006723 | 因笔墨获罪者 | 上城区:[7,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000199<br>s2: type=item, is=2000172, cost.思潮=[1,99]<br>s3: type=item, is=2000171, cost.思潮=[1,99]<br>s4: type=item, is=2000541, cost.思潮=[1,99] | data/config/rite/5006723.json |

| 5006724 | 不合时宜的思想 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001248, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006724.json |

| 5006725 | 一本书的诞生 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=[5,10]<br>s2: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5006725.json |

| 5006726 | 印刷方略 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001249, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006726.json |

| 5006727 | 请支持正版 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, !怪物=1, !动物=1<br>s2: type=item, cost.消耗品==1, !金币=1<br>s3: type=sudan, 杀戮=1, rare<==2 | data/config/rite/5006727.json |

| 5006728 | 也许应该分享给她 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币=[1,3]<br>s2: type=char, is=2000123 | data/config/rite/5006728.json |

| 5006729 | 故事的赞助人 | 商业区:[10,19] | 0 | 0 | 3 | 2 | s1: type=item, cost.金币=3<br>s2: type=char, is=2000123 | data/config/rite/5006729.json |

| 5006730 | 碎肉与骨粉 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001251, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006730.json |

| 5006731 | 迷宫之心 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001252, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006731.json |

| 5006732 | 无人知晓的地方 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001253, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006732.json |

| 5006733 | 小星星 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001254, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006733.json |

| 5006734 | 批评他人的尺度 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001255, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006734.json |

| 5006735 | 伊萨尔远征记 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001256, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006735.json |

| 5006736 | 山居往事 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001257, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006736.json |

| 5006737 | 垂钓者与我 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001258, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006737.json |

| 5006738 | 印刷详解 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001259, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006738.json |

| 5006739 | 宇宙之弦 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001260, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006739.json |

| 5006740 | 赠人玫瑰油 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, is=2001292<br>s2: type=char | data/config/rite/5006740.json |

| 5006741 | 绳索的锤炼 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001234, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006741.json |

| 5006742 | 妆娘的拜访 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000459<br>s2: type=char | data/config/rite/5006742.json |

| 5006743 | 善之形 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000459<br>s2: any={"all":{"主角":1,"counter.7100001":8}} | data/config/rite/5006743.json |

| 5006744 | 恶之形 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000459<br>s2: any={"all":{"主角":1,"counter.7100002":8}} | data/config/rite/5006744.json |

| 5006745 | 权之形 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000459<br>s2: type=char, 主角=1, !s3=1, !s4=1, !s5=1<br>s3: type=char, 主角=1, !s2=1, !s4=1, !s5=1<br>s4: type=char, 主角=1, !s2=1, !s3=1, !s5=1 | data/config/rite/5006745.json |

| 5006746 | 侠之形 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000459<br>s2: any={"all":{"主角":1,"counter.7100004":8}} | data/config/rite/5006746.json |

| 5006747 | 藏木于林 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001247, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5006747.json |

| 5006748 | 神的侍从 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, any={"妻子":1,"all":{"命运的羁绊":1,"is":2000019}} | data/config/rite/5006748.json |

| 5006749 | 初试神威 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, 主角=1, 入圣=1<br>s2: type=char, 神的侍从=1<br>s3: type=sudan<br>s4: type=item, cost.消耗品=1, !金币=1 | data/config/rite/5006749.json |

| 5006800 | 游猎会 | 野外:[1,6] | 0 | 0 | 2 | 0 | s1: type=char, 主角=1<br>s2: type=char, is=2000064<br>s3: type=char, is=2000065<br>s4: type=char, is=2000054 | data/config/rite/5006800.json |

| 5006801 | 奴隶与主人 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1, 被向导=1<br>s2: type=char, is=2000114<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006801.json |

| 5006802 | 战士之间 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000064<br>s2: type=char, is=2000114<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006802.json |

| 5006803 | 沼泽之王 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000292<br>s2: type=char, is=2000114<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006803.json |

| 5006804 | 捉捕大岩羊 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000054<br>s2: type=char, is=2000114<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006804.json |

| 5006805 | 鹰身女妖 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000061<br>s2: type=char, is=2000114<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006805.json |

| 5006806 | 猎人的陷阱 | 野外:[1,6] | 1 | 0 | 1 | 0 | s1: type=char, is=2000063<br>s2: type=char, is=2000114<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006806.json |

| 5006807 | 游猎沙威玛 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001302<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006807.json |

| 5006808 | 涓滴希望 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001308<br>s2: type=char, 女性=1 | data/config/rite/5006808.json |

| 5006809 | 社会化训练 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=char, is=2000114<br>s2: type=char, any={"is":2000113,"法拉杰":1,"all":{"is":2000082,"奴隶":1}}<br>s3: type=item, cost.金币=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5006809.json |

| 5006810 | 油炸河鲜 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001312<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006810.json |

| 5006811 | 盐烤牛心 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001313<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5006811.json |

| 5007001 | 决战奈费勒 | 大敌:1 | 0 | 0 | 1 | 3 | s1: is=2000312<br>s2: is=2000567<br>s3: is=2000568<br>s4: is=2000569 | data/config/rite/5007001.json |

| 5007002 | 积累优势 | 大敌:1 | 1 | 0 | 1 | 0 | s1: is=2000312<br>s2: is=2000567<br>s3: is=2000568<br>s4: is=2000569 | data/config/rite/5007002.json |

| 5007003 | 破坏名声 | 大敌:1 | 1 | 0 | 1 | 0 | s1: is=2000312<br>s2: is=2000567<br>s3: is=2000568<br>s4: is=2000569 | data/config/rite/5007003.json |

| 5007004 | 宫廷暗流 | 大敌:1 | 1 | 0 | 1 | 0 | s1: type=char, 支持>==1, !追随者=1, !主角=1 | data/config/rite/5007004.json |

| 5007005 | 散布谣言 | 大敌:1 | 1 | 0 | 1 | 0 | s1: is=2000312<br>s2: is=2000567<br>s3: is=2000568<br>s4: is=2000569 | data/config/rite/5007005.json |

| 5007006 | 离间计划 | 大敌:1 | 1 | 0 | 1 | 0 | s1: is=2000312<br>s2: is=2000567<br>s3: is=2000568<br>s4: is=2000569 | data/config/rite/5007006.json |

| 5007007 | 离间计 | 大敌:1 | 1 | 0 | 1 | 0 | s1: type=char, 贵族=1, 追随者=1 | data/config/rite/5007007.json |

| 5007008 | 突袭贫民窟 | 大敌:2 | 0 | 0 | 1 | 3 | s1: is=2000369<br>s2: is=2000573<br>s3: is=2000574<br>s4: is=2000371 | data/config/rite/5007008.json |

| 5007009 | 窥视财物 | 大敌:2 | 1 | 0 | 1 | 0 | s1: is=2000369<br>s2: is=2000573<br>s3: is=2000574<br>s4: is=2000371 | data/config/rite/5007009.json |

| 5007010 | 这不算偷 | 大敌:2 | 1 | 0 | 1 | 0 | s1: type=item, 已拥有=1, any={"装备":1,"读物":1}<br>s2: type=item, cost.金币=[1,3]<br>s3: type=char, is=2000369<br>s4: type=char, is=2000371 | data/config/rite/5007010.json |

| 5007011 | 招募手下 | 大敌:2 | 1 | 0 | 1 | 0 | s1: is=2000369<br>s2: is=2000573<br>s3: is=2000574<br>s4: is=2000371 | data/config/rite/5007011.json |

| 5007012 | 伺机伤人 | 大敌:2 | 1 | 0 | 1 | 0 | s1: is=2000369<br>s2: is=2000573<br>s3: is=2000574<br>s4: is=2000371 | data/config/rite/5007012.json |

| 5007013 | 受害者 | 大敌:2 | 1 | 0 | 1 | 0 | s1: type=char, 追随者=1 | data/config/rite/5007013.json |

| 5007014 | 暗中破坏 | 大敌:2 | 1 | 0 | 1 | 0 | s1: is=2000369<br>s2: is=2000573<br>s3: is=2000574<br>s4: is=2000371 | data/config/rite/5007014.json |

| 5007015 | 无谋的复仇 | 大敌:2 | 1 | 0 | 1 | 0 | s1: is=2000369<br>s2: is=2000573<br>s3: is=2000574<br>s4: is=2000371 | data/config/rite/5007015.json |

| 5007016 | 孤注一掷 | 大敌:2 | 0 | 0 | 1 | 3 | s1: is=2000369<br>s2: is=2000573<br>s3: is=2000574<br>s4: is=2000371 | data/config/rite/5007016.json |

| 5008001 | 妻子的忧虑 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: 妻子=1<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008001.json |

| 5008002 | 武装娇妻 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: 妻子=1<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008002.json |

| 5008003 | 特殊的枕头 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=sudan, 纵欲=1, f:rare-s3.rare<==0<br>s2: type=char, 主角=1<br>s3: type=char, 妻子=1 | data/config/rite/5008003.json |

| 5008004 | 为你辩解 | 自宅:[2,12] | 0 | 0 | 0 | 3 | s1: 妻子=1<br>s2: is=2000083 | data/config/rite/5008004.json |

| 5008005 | 妻子的茶会 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: 妻子=1, type=char<br>s2: type=char, any={"主角":1,"all":{"is":2000062,"密教徒":1,"侧室":1}}<br>s3: all={"type":"sudan","any":{"纵欲":1,"奢靡":1},"s2.主角":1,"rare<=":3,"counter.7000234<":1}<br>s4: type=item, any={"all":{"s3.奢靡":1,"s3.rare=":3,"cost.金币>=":15,"s2.主角":1}} | data/config/rite/5008005.json |

| 5008006 | 鼓励 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: 法拉杰=1<br>s2: type=char, any={"妻子":1,"主角":1}<br>s3: type=char, any={"妻子":1,"主角":1}<br>s4: type=char, any={"妻子":1,"主角":1} | data/config/rite/5008006.json |

| 5008007 | 激励 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: 法拉杰=1<br>s2: type=char, any={"妻子":1,"主角":1}<br>s3: type=char, any={"妻子":1,"主角":1}<br>s4: type=char, any={"妻子":1,"主角":1} | data/config/rite/5008007.json |

| 5008008 | 欲望与幸福 | 自宅:[2,12] | 0 | 0 | 1 | 15 | s1: type=char, 法拉杰=1<br>s2: type=sudan, 纵欲=1, f:rare-s1.rare<==0<br>s3: type=char, 主角=1<br>s4: type=char, 妻子=1 | data/config/rite/5008008.json |

| 5008009 | 背叛 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 法拉杰=1<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, any={"纵欲":1,"杀戮":1}, f:rare-s1.rare<==0 | data/config/rite/5008009.json |

| 5008010 | 青年的帷幕 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: 法拉杰=1, type=char<br>s2: is=2000735<br>s3: 主角=1, type=char<br>s4: type=item, any={"cost.金币":[1,15],"is":2000172} | data/config/rite/5008010.json |

| 5008011 | 危险的聚会 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: 法拉杰=1, type=char<br>s2: is=2000736<br>s3: 主角=1, type=char<br>s4: type=item, any={"cost.金币":[1,15],"is":2000172} | data/config/rite/5008011.json |

| 5008012 | 革命的沙龙 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: 法拉杰=1, type=char<br>s2: is=2000748<br>s3: 主角=1, type=char<br>s4: type=item, cost.金币=[1,15] | data/config/rite/5008012.json |

| 5008013 | 收买头衔 | 上城区:[2,10] | 0 | 0 | 1 | 7 | s1: type=item, cost.金币=10<br>s2: type=char<br>s3: is=2000743<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008013.json |

| 5008014 | 荣耀回归 | 上城区:[3,12] | 0 | 0 | 1 | 0 | s1: is=2000056<br>s2: type=item, is=2000741 | data/config/rite/5008014.json |

| 5008015 | 购买头衔 | 上城区:[2,10] | 0 | 0 | 1 | 5 | s1: type=item, cost.金币=10<br>s2: type=char | data/config/rite/5008015.json |

| 5008016 | 最后的道别 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: is=2000056 | data/config/rite/5008016.json |

| 5008017 | 恰当的价码 | 黑街:[1,5] | 0 | 0 | 1 | 5 | s1: type=item, cost.金币=10 | data/config/rite/5008017.json |

| 5008018 | 过时不候 | 自宅:[3,12] | 1 | 0 | 1 | 1 | s1: is=2000056 | data/config/rite/5008018.json |

| 5008019 | 荣耀回归 | 上城区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000056<br>s2: is=2000741 | data/config/rite/5008019.json |

| 5008020 | 永世流传之物 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=item, is=2000742<br>s2: is=2000056 | data/config/rite/5008020.json |

| 5008021 | 废弃 | 自宅:[2,10] | 0 | 0 | 1 | 5 | s1: any | data/config/rite/5008021.json |

| 5008022 | 废弃 | 自宅:[2,10] | 0 | 0 | 1 | 0 | s1: is=2000756 | data/config/rite/5008022.json |

| 5008023 | 丰产的仪式 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=sudan, f:rare-s3.rare<==0, 杀戮=1<br>s2: 主角=1, type=char<br>s3: is=2000056, type=char<br>s4: is=2000757 | data/config/rite/5008023.json |

| 5008024 | 销毁图纸 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000757 | data/config/rite/5008024.json |

| 5008025 | 内宅的仪式 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=sudan, f:rare-s3.rare<==0, 纵欲=1<br>s2: 主角=1, type=char<br>s3: all={"type":"char","any":{"is":2000056,"妻子":1,"激情>=":1}}<br>s4: is=2000758 | data/config/rite/5008025.json |

| 5008026 | 挽回的余地 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 妻子=1<br>s2: type=item, 饰品=1, rare>==3, !is=2001022 | data/config/rite/5008026.json |

| 5008027 | 挽回的余地 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 妻子=1<br>s2: type=char, 主角=1<br>s3: type=item, 饰品=1, rare>==3, !is=2001022<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008027.json |

| 5008028 | 我都知道了！ | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 妻子=1<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008028.json |

| 5008029 | 剑盾的仪式 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: is=2000759<br>s2: 部队=1, any={"type":"char","is":"2000554"}<br>s3: type=char<br>s4: type=item, cost.金币=[10,20] | data/config/rite/5008029.json |

| 5008030 | 气急败坏 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000057<br>s2: !s3=1, type=char<br>s3: !s2=1, type=char<br>s4: type=item, is=2000776 | data/config/rite/5008030.json |

| 5008031 | 决斗 | 上城区:[1,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000057<br>s2: type=char, is=2000774<br>s3: type=char, is=2000777<br>s4: type=char | data/config/rite/5008031.json |

| 5008032 | 末路 | 上城区:[1,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000057<br>s2: type=char, is=2000774 | data/config/rite/5008032.json |

| 5008033 | 别人的女儿 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000774<br>s2: 主角=1, type=char<br>s3: type=sudan, !s4=1, 纵欲=1, rare<==2 | data/config/rite/5008033.json |

| 5008034 | 积累优势 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000781<br>s4: is=2000774 | data/config/rite/5008034.json |

| 5008035 | 隐身幕后 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000781<br>s4: is=2000774 | data/config/rite/5008035.json |

| 5008036 | 策划袭击 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000781<br>s4: is=2000774 | data/config/rite/5008036.json |

| 5008037 | 突袭 | 大敌:3 | 1 | 0 | 1 | 0 | s1: type=char, 追随者=1 | data/config/rite/5008037.json |

| 5008038 | 干扰生意 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000781<br>s4: is=2000774 | data/config/rite/5008038.json |

| 5008039 | 破坏名声 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000774<br>s4: is=2000781 | data/config/rite/5008039.json |

| 5008040 | 进谗言 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000774<br>s4: is=2000781 | data/config/rite/5008040.json |

| 5008041 | 策划诉讼 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000774<br>s4: is=2000781 | data/config/rite/5008041.json |

| 5008042 | 策划暗杀 | 大敌:3 | 1 | 0 | 1 | 0 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000774<br>s4: is=2000781 | data/config/rite/5008042.json |

| 5008043 | 一次暗杀 | 大敌:3 | 1 | 0 | 5 | 1 | s1: is=2000057<br>s2: is=2000781<br>s3: is=2000774<br>s4: type=char, 主角=1 | data/config/rite/5008043.json |

| 5008044 | 牢狱之灾 | 大敌:3 | 1 | 0 | 5 | 1 | s1: type=char, 追随者=1, !主角=1 | data/config/rite/5008044.json |

| 5008045 | 突袭贪官宅邸 | 大敌:3 | 0 | 0 | 1 | 3 | s1: is=2000057<br>s2: is=2000782<br>s3: is=2000781<br>s4: is=2000774 | data/config/rite/5008045.json |

| 5008046 | 还来？ | 自宅:[1,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000774<br>s2: type=char, 妻子=1, !s3=1, !s4=1<br>s3: type=char, !s2=1, !s4=1<br>s4: type=char, 主角=1, !s2=1, !s3=1 | data/config/rite/5008046.json |

| 5008047 | 欢宴 | 上城区:[7,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000774<br>s2: type=char, 主角=1<br>s3: type=char, !奴隶=1, !主角=1<br>s4: type=char, 奴隶=1 | data/config/rite/5008047.json |

| 5008048 | 一次愉快的回忆 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=item, cost.不满=[1,99] | data/config/rite/5008048.json |

| 5008049 | 快脚的约会 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000370 | data/config/rite/5008049.json |

| 5008050 | 赘婿的金币 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000057<br>s2: type=char, is=2000774<br>s3: type=char, is=2000370<br>s4: cost.2000813=[1,20], !已拥有=1 | data/config/rite/5008050.json |

| 5008051 | 欢快的访客 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000794<br>s2: type=char | data/config/rite/5008051.json |

| 5008052 | 快脚的安家费 | 自宅:[2,12] | 0 | 0 | 7 | 7 | s1: type=char, is=2000370<br>s2: type=item, cost.金币=5 | data/config/rite/5008052.json |

| 5008053 | 失踪的快脚 | 自宅:[2,12] | 1 | 0 | 3 | 1 | s1: type=char, is=2000370 | data/config/rite/5008053.json |

| 5008054 | 快脚的安家费 | 自宅:[2,12] | 0 | 0 | 3 | 7 | s1: type=char, is=2000370<br>s2: type=item, cost.金币=3 | data/config/rite/5008054.json |

| 5008055 | 归乡之径（作废） | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: is=2000350<br>s2: is=2000069<br>s3: type=char, !s4=1<br>s4: type=char, !s3=1 | data/config/rite/5008055.json |

| 5008056 | 应许时刻 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000350<br>s2: type=char, 主角=1, !s3=1, !s4=1<br>s3: type=char, 主角=1, !s2=1, !s4=1<br>s4: type=char, 主角=1, !s2=1, !s3=1 | data/config/rite/5008056.json |

| 5008057 | 同一场风暴 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000350<br>s2: 主角=1, type=char<br>s3: type=sudan, !s4=1, 纵欲=1, rare<==3 | data/config/rite/5008057.json |

| 5008058 | 让我成为你的盾 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000350<br>s2: any={"部队":1,"is":2000172} | data/config/rite/5008058.json |

| 5008059 | 老鼠一样的逃亡 | 野外:[1,6] | 0 | 0 | 1 | 5 | s1: is=2000853<br>s2: type=char, is=2000350<br>s3: type=item, cost.金币=10<br>s4: any={"is":2000772,"部队":1} | data/config/rite/5008059.json |

| 5008060 | 证婚人 | 自宅:[4,12] | 0 | 0 | 1 | 5 | s1: type=char, 女性=1 | data/config/rite/5008060.json |

| 5008061 | 过时不候 | 自宅:[3,12] | 1 | 0 | 1 | 1 | s1: is=2000056 | data/config/rite/5008061.json |

| 5008062 | 第一眼 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000350<br>s2: type=char, is=2000123<br>s3: 主角=1, type=char<br>s4: type=item, cost.金币=18 | data/config/rite/5008062.json |

| 5008063 | 年轻人的婚礼 | 上城区:[1,6] | 0 | 0 | 1 | 10 | s1: type=char, is=2000350<br>s2: type=char, is=2000123<br>s3: type=char, any={"主角":1,"妻子":1}<br>s4: type=char, any={"主角":1,"妻子":1} | data/config/rite/5008063.json |

| 5008064 | 归乡之路 | 野外:[9,14] | 1 | 0 | 7 | 1 | s1: type=char, is=2000350<br>s2: type=char, is=2000123 | data/config/rite/5008064.json |

| 5008065 | 老乡见老乡 | 商业区:[10,19] | 1 | 0 | 3 | 1 | s1: type=char, is=2000350 | data/config/rite/5008065.json |

| 5008066 | 为您效劳 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000350<br>s2: type=char, is=2000860<br>s3: type=item, any={"cost.金币":18,"is":2000172,"部队":1} | data/config/rite/5008066.json |

| 5008067 | 抓贼 | 黑街:[2,5] | 1 | 0 | 1 | 1 | s1: type=item, is=2000885<br>s2: type=item, 已拥有=1, cost.金币=[1,2]<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008067.json |

| 5008068 | 一手拿货 | 黑街:[2,5] | 0 | 0 | 0 | 3 | s1: type=char, is=2000113<br>s2: type=item, is=2000987<br>s3: type=item, any={"cost.金币":5,"is":2000885}<br>s4: type=char | data/config/rite/5008068.json |

| 5008069 | 先钱后货 | 黑街:[2,5] | 0 | 0 | 0 | 3 | s1: type=char, is=2000113<br>s2: type=item, is=2000987<br>s3: type=item, cost.金币=[1,5]<br>s4: type=char | data/config/rite/5008069.json |

| 5008070 | 小贼的命运 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2000885<br>s2: type=char, 主角=1<br>s3: type=sudan, 杀戮=1, rare<==1 | data/config/rite/5008070.json |

| 5008071 | 夜盗 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000113<br>s2: type=item, is=2000885<br>s3: type=item, cost.金币=[1,10]<br>s4: type=char | data/config/rite/5008071.json |

| 5008072 | 腐烂之巢 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: type=char, is=2000886<br>s2: type=item, is=2000892<br>s3: type=char, is=2000113<br>s4: type=char | data/config/rite/5008072.json |

| 5008073 | 乞儿们 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: is=2000887<br>s2: type=item, cost.金币=3 | data/config/rite/5008073.json |

| 5008074 | 白肚皮 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: type=char, is=2000113<br>s2: type=char, is=2000886<br>s3: is=2000893, !s5=1<br>s4: type=char, 主角=1 | data/config/rite/5008074.json |

| 5008075 | 拉磨 | 商业区:[10,19] | 0 | 0 | 1 | 7 | s1: type=item, is=2000885<br>s2: type=char<br>s3: type=item, cost.金币=1 | data/config/rite/5008075.json |

| 5008076 | 贼的志愿生 | 黑街:[2,5] | 0 | 0 | 1 | 5 | s1: type=char, is=2000113<br>s2: type=item, is=2000885<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008076.json |

| 5008077 | 阿里木的大餐 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: type=char, is=2000113<br>s2: type=char, !主角=1<br>s3: type=char, !主角=1<br>s4: type=char, 主角=1 | data/config/rite/5008077.json |

| 5008078 | 饥饿的嘴 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: is=2000887<br>s2: type=item, cost.金币=3 | data/config/rite/5008078.json |

| 5008079 | 做鸡 | 黑街:[1,5] | 1 | 0 | 1 | 1 | s1: is=2000887 | data/config/rite/5008079.json |

| 5008080 | 做牛马 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: is=2000887<br>s2: type=item, cost.金币=5 | data/config/rite/5008080.json |

| 5008081 | 做羔羊 | 神殿区:[2,10] | 1 | 0 | 1 | 0 | s1: is=2000887<br>s2: type=item, cost.金币=[10,20]<br>s3: type=sudan, 奢靡=1, f:rare-s1.rare<==0<br>s4: type=item, any={"is":2000728} | data/config/rite/5008081.json |

| 5008082 | 做狗 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000887<br>s2: type=item, cost.金币=10 | data/config/rite/5008082.json |

| 5008083 | 做羔羊？ | 黑街:[2,5] | 1 | 0 | 1 | 0 | s1: is=2000887<br>s2: type=item, 思潮=1, any={"is":2000412} | data/config/rite/5008083.json |

| 5008084 | 做老鼠 | 黑街:[1,5] | 1 | 0 | 1 | 0 | s1: is=2000887<br>s2: type=item, cost.金币=8 | data/config/rite/5008084.json |

| 5008085 | 做人 | 上城区:[7,12] | 1 | 0 | 1 | 0 | s1: type=char, is=2000113<br>s2: type=item, cost.金币=[10,20]<br>s3: type=sudan, 奢靡=1, rare<==2, s2.金币=20<br>s4: is=2000887 | data/config/rite/5008085.json |

| 5008086 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char | data/config/rite/5008086.json |

| 5008087 | 狗窝 | 黑街:[2,5] | 0 | 0 | 1 | 7 | s1: type=item, is=2000888<br>s2: type=char, is=2000113<br>s3: type=char<br>s4: type=item, any={"cost.金币":10,"大餐":1} | data/config/rite/5008087.json |

| 5008088 | 合宜的一餐 | 商业区:[10,19] | 0 | 0 | 1 | 7 | s1: type=char, is=2000014<br>s2: type=item, cost.金币=[1,10]<br>s3: type=sudan, s2.金币==10, 奢靡=1, rare==1 | data/config/rite/5008088.json |

| 5008089 | 她不开心 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000083<br>s2: type=char, is=2000014<br>s3: type=char, any={"主角":1,"is":2000371}<br>s4: type=char, 主角=1 | data/config/rite/5008089.json |

| 5008090 | 大家一起来！ | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2000932<br>s2: 主角=1, type=char<br>s3: 妻子=1, type=char<br>s4: !贵族=1, !主角=1, type=char | data/config/rite/5008090.json |

| 5008091 | 有人没吃到 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: type=char, is=2000931<br>s2: type=item, any={"cost.金币":3,"大餐":1}<br>s3: type=char, !主角=1 | data/config/rite/5008091.json |

| 5008092 | 贵族也想吃 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2001004<br>s2: type=item, any={"cost.金币":5,"大餐":1}<br>s3: any={"is":2000014,"主角":1}, type=char | data/config/rite/5008092.json |

| 5008093 | 开饭咯 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: type=item, is=2000939<br>s2: type=char<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5008093.json |

| 5008094 | 疗愈的食物 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: is=2000083<br>s2: type=char, 妻子=1<br>s3: type=char, 主角=1 | data/config/rite/5008094.json |

| 5008095 | 一罐蜜饯 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=item, is=2000941<br>s2: type=char, 主角=1<br>s3: type=char, 追随者=1, !主角=1<br>s4: type=char, 追随者=1, !主角=1 | data/config/rite/5008095.json |

| 5008096 | 免费的盛宴 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2000940<br>s2: is=2000932<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5008096.json |

| 5008097 | 闹事的老鼠 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: is=2000933<br>s2: type=char<br>s3: type=item, cost.金币=10 | data/config/rite/5008097.json |

| 5008098 | 硕鼠 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: is=2000934<br>s2: type=char, any={"贵族":1,"主角":1}<br>s3: type=sudan, !s3.奢靡=1, s2.主角=1, rare<==2 | data/config/rite/5008098.json |

| 5008099 | 全家福 | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: is=2000964<br>s2: type=char<br>s3: !消耗品=1, !思潮=1, !情报=1, !大餐=1, !装备=1, !金币=1, any={"type":"item","部队":1,"追随者":1}<br>s4: !消耗品=1, !思潮=1, !情报=1, !大餐=1, !装备=1, !金币=1, any={"type":"item","部队":1,"追随者":1} | data/config/rite/5008099.json |

| 5008100 | 等待一餐 | 商业区:[10,19] | 0 | 0 | 1 | 7 | s1: type=char, is=2000935<br>s2: type=item, 大餐=1 | data/config/rite/5008100.json |

| 5008101 | 冷淡的消遣 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2000083<br>s2: type=char, 妻子=1 | data/config/rite/5008101.json |

| 5008102 | 热辣欢宴 | 商业区:[10,19] | 0 | 0 | 3 | 3 | s1: type=char, is=2000014<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008102.json |

| 5008103 | 勇士欢宴 | 商业区:[10,19] | 0 | 0 | 3 | 3 | s1: type=char, is=2000014<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008103.json |

| 5008104 | 宫廷华宴 | 商业区:[10,19] | 0 | 0 | 3 | 3 | s1: type=char, is=2000014<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008104.json |

| 5008105 | 颂神会 | 商业区:[10,19] | 0 | 0 | 3 | 3 | s1: type=char, is=2000014<br>s2: type=item, cost.金币=10<br>s3: type=char<br>s4: type=char | data/config/rite/5008105.json |

| 5008106 | 谢肉祭 | 商业区:[10,19] | 0 | 0 | 3 | 3 | s1: type=char, is=2000014<br>s2: type=char, is=2000022<br>s3: any={"type":"char","任意处置":1}, !主角=1, !怪物=1, !动物=1<br>s4: type=char, any={"密教徒":1,"黑暗知识":1} | data/config/rite/5008106.json |

| 5008107 | 阁楼里的笑声 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: type=char, any={"is":2000789,"妓女":1} | data/config/rite/5008107.json |

| 5008108 | 合伙金 | 商业区:[10,19] | 0 | 0 | 1 | 0 | s1: type=item, cost.金币=10 | data/config/rite/5008108.json |

| 5008109 | 阁楼里熟悉的笑声 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, any={"is":2000500,"all":{"counter.7000251>=":1,"is":2000369}} | data/config/rite/5008109.json |

| 5008110 | 阁楼里熟悉的笑声 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, any={"is":2000500,"all":{"counter.7000251>=":1,"is":2000369}} | data/config/rite/5008110.json |

| 5008111 | 阁楼里偶尔的笑声 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: type=char, any={"is":2000789,"妓女":1} | data/config/rite/5008111.json |

| 5008112 | 阁楼里的笑声 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: type=char, any={"is":2000789,"妓女":1} | data/config/rite/5008112.json |

| 5008113 | 腐败的玫瑰 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: is=2000937<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008113.json |

| 5008114 | 黑暗之主的雕琢 | 野外:[9,14] | 0 | 0 | 7 | 7 | s1: type=char, is=2000022<br>s2: type=char, is=2000937<br>s3: type=item, is=2000986 | data/config/rite/5008114.json |

| 5008115 | 恶臭的阁楼 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: type=char, !主角=1, 追随者=1, 男性=1, !银趴绝缘者=1, !is=2000054<br>s2: type=char, !主角=1, 追随者=1, 男性=1, !银趴绝缘者=1, !is=2000054 | data/config/rite/5008115.json |

| 5008116 | 丝绒暗室 | 商业区:[10,19] | 1 | 0 | 1 | 0 | s1: type=char, !苏丹=1, !主角=1, 贵族=1<br>s2: type=char, !苏丹=1, !主角=1, 贵族=1 | data/config/rite/5008116.json |

| 5008117 | 过于尊贵的客人 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2001005<br>s2: type=char, 贵族=1<br>s3: type=char, 贵族=1<br>s4: type=char, 贵族=1 | data/config/rite/5008117.json |

| 5008118 | 如何款待尊贵的客人 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: type=char, is=2000024<br>s2: type=char, any={"all":{"魅力>=":5,"女性":1},"主角":1}<br>s3: type=item, 大餐=1<br>s4: type=item, any={"is":2000412} | data/config/rite/5008118.json |

| 5008119 | 御厨 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: is=2000014<br>s2: type=char, 贵族=1<br>s3: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008119.json |

| 5008120 | 苏丹的戏弄 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: type=item, 大餐=1<br>s2: type=item, is=2001053, cost.耐心=[1,3] | data/config/rite/5008120.json |

| 5008121 | 哈比卜逃亡 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: is=2000014<br>s2: type=char<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, f:rare-s1.rare<==0, 杀戮=1, s2.主角=1 | data/config/rite/5008121.json |

| 5008122 | 苏丹的偏爱 | 上城区:[7,12] | 0 | 0 | 2 | 5 | s1: type=char, 苏丹的猎物=1 | data/config/rite/5008122.json |

| 5008123 | 冒险者酒吧 | 黑街:10 | 0 | 0 | 7 | 0 | s1: type=char, is=2000948<br>s2: type=item, any={"情报":1,"cost.金币":[1,10],"all":{"counter.7000516<":1,"any":{"is":2000412}},"is":2001195} | data/config/rite/5008123.json |

| 5008125 | 午夜利刃 | 黑街:[2,5] | 1 | 0 | 1 | 1 | s1: type=item, cost.冤魂=[1,8]<br>s2: type=char<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008125.json |

| 5008126 | 收手吧 | 黑街:[2,5] | 0 | 0 | 1 | 3 | s1: is=2000013<br>s2: is=2000947<br>s3: type=char<br>s4: type=char | data/config/rite/5008126.json |

| 5008127 | 你是最后一个 | 黑街:[2,5] | 0 | 0 | 1 | 1 | s1: is=2000013<br>s2: type=char, 主角=1<br>s3: type=item, cost.消耗品==1, !金币=1<br>s4: type=sudan, 杀戮=1 | data/config/rite/5008127.json |

| 5008128 | 如露散 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: is=2000014 | data/config/rite/5008128.json |

| 5008129 | 食物中毒 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: is=2000014 | data/config/rite/5008129.json |

| 5008130 | 持刀的绵羊 | 商业区:[10,19] | 1 | 0 | 1 | 1 | s1: is=2000014 | data/config/rite/5008130.json |

| 5008131 | 火！火！火！ | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008131.json |

| 5008132 | 能吃吗？好吃吗？怎么吃？ | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=char, is=2000014<br>s2: any={"is":2001138,"all":{"have.2000014.魔厨":1,"any":{"is":2001111}},"any":{"is":2001326,"all":{"is":2000434,"驯兽":1}}}<br>s3: type=item, cost.金币=10 | data/config/rite/5008132.json |

| 5008133 | 手抓鳄鱼饭 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001006<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008133.json |

| 5008134 | 熏狮子全餐 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001007<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008134.json |

| 5008135 | 生命布丁 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001008<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008135.json |

| 5008136 | 荒野一锅炖 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001009<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008136.json |

| 5008137 | 草药炖大雁 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001010<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008137.json |

| 5008138 | 烤全驼 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001011<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008138.json |

| 5008139 | 精力套餐 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001012<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008139.json |

| 5008140 | 仙人掌蛋糕 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001013<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008140.json |

| 5008141 | 圣餐饼 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001014<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008141.json |

| 5008142 | 国王烤肉 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001015<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008142.json |

| 5008143 | 饼夹一切 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001016<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008143.json |

| 5008144 | 蜂蜜蛋饼 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001017<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008144.json |

| 5008145 | 冒险者们的报恩 | 黑街:10 | 0 | 0 | 0 | 0 | s1: type=char | data/config/rite/5008145.json |

| 5008146 | 黑街赛狗 | 黑街:[2,5] | 1 | 0 | 1 | 1 | s1: is=2000990<br>s2: is=2001027<br>s3: is=2001028<br>s4: is=2001029 | data/config/rite/5008146.json |

| 5008147 | 比嘬嘬嘬更有用 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: is=2001032<br>s2: type=char | data/config/rite/5008147.json |

| 5008148 | 超高校级黑街赛狗 | 黑街:[2,5] | 1 | 0 | 1 | 1 | s1: is=2000990<br>s2: is=2001027<br>s3: is=2001028<br>s4: is=2001029 | data/config/rite/5008148.json |

| 5008149 | 复仇的请求 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: is=2000065<br>s2: type=char, !s3=1<br>s3: type=char, !s2=1 | data/config/rite/5008149.json |

| 5008150 | 拼凑真相 | 黑街:[2,5] | 0 | 0 | 3 | 0 | s1: type=char<br>s2: any={"all":{"cost.消耗品=":1,"type":"item","情报":1}}<br>s3: type=char<br>s4: any={"all":{"cost.消耗品=":1,"type":"item","情报":1}} | data/config/rite/5008150.json |

| 5008151 | 唯一的答案 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000065<br>s2: type=char, 主角=1<br>s3: any={"is":2000412,"all":{"type":"sudan","s2":1,"杀戮":1,"f:rare-s1.rare<=":0}}<br>s4: type=item, is=2001043 | data/config/rite/5008151.json |

| 5008152 | 稀有的肉干 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=item, is=2000942<br>s2: type=char, 主角=1<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5008152.json |

| 5008153 | 比最好更好的 | 宫廷:[2,6] | 0 | 0 | 1 | 7 | s1: any={"all":{"type":"char","any":{"is":2000022}}} | data/config/rite/5008153.json |

| 5008154 | 法德耶来访 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000173<br>s2: type=char, !s3=1, !s4=1, 主角=1<br>s3: type=char, !s2=1, !s4=1, any={"主角":1,"妻子":1}<br>s4: type=char, !s2=1, !s3=1, any={"all":{"counter.7000592>=":1,"is":2000065},"主角":1} | data/config/rite/5008154.json |

| 5008155 | 苏丹的特使？ | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: is=2000173<br>s2: type=char, any={"主角":1,"妻子":1}<br>s3: type=sudan, s2.主角=1, 纵欲=1, f:rare-s1.rare<==0 | data/config/rite/5008155.json |

| 5008156 | 绝望中的救赎 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: is=2000173<br>s2: type=item, any={"is":2000412} | data/config/rite/5008156.json |

| 5008157 | 法德耶的帮助 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000173<br>s2: type=item, is=2000680 | data/config/rite/5008157.json |

| 5008158 | 老派花园大餐 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001049<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008158.json |

| 5008159 | 禽肉炒蘑菇 | 商业区:[10,19] | 0 | 0 | 1 | 1 | s1: type=item, is=2001050<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008159.json |

| 5008160 | 古怪的邀请 | 黑街:[1,9] | 0 | 0 | 1 | 5 | s1: is=2000065<br>s2: 主角=1, type=char | data/config/rite/5008160.json |

| 5008161 | 新月想出去玩 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: is=2000989<br>s2: any={"type":"char","is":2001305} | data/config/rite/5008161.json |

| 5008162 | 小狗和月亮之歌 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, is=2001054<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5008162.json |

| 5008163 | 新月升起 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: is=2000989 | data/config/rite/5008163.json |

| 5008164 | 破除洁净 | 神殿区:[2,10] | 0 | 0 | 1 | 5 | s1: is=2000022<br>s2: is=2000726<br>s3: type=char, !s4=1, !s5=1<br>s4: type=char, !s3=1, !s5=1 | data/config/rite/5008164.json |

| 5008165 | 废弃 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: is=2000022<br>s2: type=char, any={"主角":1,"妻子":1}<br>s3: type=char, !s2.妻子=1, any={"邪神的面容":1,"is":2000185}<br>s4: type=sudan, s2.主角=1, !s2.妻子=1, !s3=1, f:rare-s1.rare<==0, any={"纵欲":1,"杀戮":1} | data/config/rite/5008165.json |

| 5008166 | 不洁的代言人 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: is=2000022<br>s2: type=char, any={"主角":1,"妻子":1} | data/config/rite/5008166.json |

| 5008167 | 不洁的援助 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=sudan | data/config/rite/5008167.json |

| 5008168 | 命运之死 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=sudan, 不洁的援助=1<br>s2: type=char, !苏丹=1, !主角=1, !怪物=1, f:rare-s1.rare>==0 | data/config/rite/5008168.json |

| 5008169 | 后宫的空缺 | 宫廷:[2,6] | 0 | 0 | 1 | 5 | s1: type=char, 魅力>==5, 女性=1 | data/config/rite/5008169.json |

| 5008170 | 废弃 | 自宅:[2,12] | 1 | 0 | 1 | 0 |  | data/config/rite/5008170.json |

| 5008171 | 荒诞之欢 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: 援助怪物=1<br>s3: type=sudan, 不洁的援助=1 | data/config/rite/5008171.json |

| 5008172 | 饕餮之欲 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: any={"all":{"type":"char","追随者":1}}<br>s2: any={"all":{"type":"char","追随者":1}}<br>s3: any={"all":{"type":"char","追随者":1}}<br>s4: any={"all":{"type":"char","追随者":1}} | data/config/rite/5008172.json |

| 5008173 | 饕餮之欲 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: any={"all":{"type":"char","追随者":1}}<br>s2: any={"all":{"type":"char","追随者":1}}<br>s3: any={"all":{"type":"char","追随者":1}}<br>s4: type=sudan, 不洁的援助=1 | data/config/rite/5008173.json |

| 5008174 | 饕餮之欲 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: any={"all":{"type":"char","追随者":1}}<br>s2: any={"all":{"type":"char","追随者":1}}<br>s3: type=sudan, 不洁的援助=1 | data/config/rite/5008174.json |

| 5008175 | 饕餮之欲 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: any={"all":{"type":"char","追随者":1}}<br>s2: type=sudan, 不洁的援助=1 | data/config/rite/5008175.json |

| 5008176 | 暴食者雕像 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: any={"is":2001075}<br>s2: type=item, is=2000986 | data/config/rite/5008176.json |

| 5008177 | 无妄之灾 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: 援助怪物=1<br>s2: type=char, 追随者=1<br>s3: type=sudan, 不洁的援助=1<br>s4: type=char, 主角=1 | data/config/rite/5008177.json |

| 5008178 | 刺肉者 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: is=2000022<br>s2: type=char, any={"追随者":1,"主角":1}, !刺青=1<br>s3: type=item, cost.金币=5 | data/config/rite/5008178.json |

| 5008179 | 清洗异端 | 黑街:[2,5] | 0 | 0 | 1 | 5 | s1: is=2001092<br>s2: is=2001093<br>s3: type=char, 追随者=1, !密教徒=1, !s7=1, !s4=1, !s8=1<br>s4: any={"all":{"type":"item","cost.金币":10},"is":2000728} | data/config/rite/5008179.json |

| 5008180 | 处置俘虏 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: is=2001101<br>s2: type=char, 主角=1<br>s3: type=sudan, any={"征服":1,"杀戮":1}, rare<==3 | data/config/rite/5008180.json |

| 5008181 | 神啊，降临吧！ | 黑街:[1,9] | 0 | 0 | 1 | 7 | s1: type=char, is=2000022<br>s2: type=char, 主角=1<br>s3: type=item, any={"正神的面容":1,"邪神的面容":1}<br>s4: type=item, 思潮=1, any={"is":2000412} | data/config/rite/5008181.json |

| 5008182 | 降神仪式 | 黑街:[1,9] | 0 | 0 | 1 | 7 | s1: type=char, is=2000022<br>s2: is=2001104<br>s3: type=sudan, !奢靡=1, rare<==3, !s4=1<br>s4: type=sudan, !奢靡=1, rare<==3, !s3=1 | data/config/rite/5008182.json |

| 5008183 | 怪异的降临 | 上城区:[1,6] | 1 | 0 | 1 | 1 | s1: is=2001121<br>s2: type=char, any={"主角":1,"追随者":1}<br>s3: type=char, !苏丹=1, 贵族=1<br>s4: any={"邪神的面容":1,"正神的面容":1,"is":2000728} | data/config/rite/5008183.json |

| 5008184 | 怨恨诅咒 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: is=2001105 | data/config/rite/5008184.json |

| 5008185 | 废弃 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: any | data/config/rite/5008185.json |

| 5008186 | 降神仪式 | 黑街:[1,9] | 0 | 0 | 1 | 3 | s1: type=char, is=2000022<br>s2: type=char, 主角=1<br>s3: is=2001094 | data/config/rite/5008186.json |

| 5008187 | 密室中 | 黑街:[1,9] | 1 | 0 | 1 | 1 | s1: is=2001121<br>s2: any={"邪神的面容":1,"正神的面容":1,"is":2000723}<br>s3: type=char, is=2000022<br>s4: type=char, any={"is":2000021,"妻子":1} | data/config/rite/5008187.json |

| 5008188 | 密神的诅咒 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2001121<br>s2: any={"邪神的面容":1,"正神的面容":1,"is":2000393} | data/config/rite/5008188.json |

| 5008189 | 自由之花 | 野外:[9,14] | 0 | 0 | 1 | 15 | s1: is=2000022<br>s2: 主角=1, type=char<br>s3: type=item, 邪神的面容=1<br>s4: type=item, 正神的面容=1 | data/config/rite/5008189.json |

| 5008190 | 堕神的呼唤 | 黑街:[1,9] | 0 | 0 | 1 | 3 | s1: type=item, is=2001161<br>s2: type=char, 追随者=1, !is=2000461<br>s3: type=char, 追随者=1, !is=2000461<br>s4: type=char, 追随者=1, !is=2000461 | data/config/rite/5008190.json |

| 5008191 | 蛇之国 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, 正在阅读=1, 读物=1, is=2001165<br>s2: type=char, !动物=1, !怪物=1 | data/config/rite/5008191.json |

| 5008192 | 毒蛇神殿 | 野外:[9,14] | 0 | 0 | 3 | 7 | s1: any={"all":{"type":"char","体魄>=":7},"is":2000461}<br>s2: any={"all":{"type":"char","智慧>=":7},"is":2000461}<br>s3: any={"all":{"type":"char","魅力>=":7},"is":2000461}<br>s4: any={"all":{"type":"char","魔力>=":7},"is":2000461} | data/config/rite/5008192.json |

| 5008193 | 欲望之蛇 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=sudan, rare<==3, 纵欲=1<br>s2: 主角=1, type=char<br>s3: type=char, 追随者=1, !动物=1, !怪物=1, 毒蛇之链=1 | data/config/rite/5008193.json |

| 5008194 | 蛇之净化 | 神殿区:[2,10] | 0 | 0 | 1 | 7 | s1: type=item, is=2001167 | data/config/rite/5008194.json |

| 5008195 | 佣兵的笔记 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2000945, 正在阅读=1<br>s2: type=char, !动物=1, !怪物=1, any={"生存>=":1,"is":2000123} | data/config/rite/5008195.json |

| 5008196 | 流民的索要 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: type=char, is=2000195<br>s2: type=item, is=2001223<br>s3: type=item, any={"大餐":1,"cost.金币":[8,16]}<br>s4: type=sudan, any={"all":{"!s3":1,"杀戮":1}}, rare<==2 | data/config/rite/5008196.json |

| 5008197 | 流民的帮闲 | 自宅:[2,12] | 1 | 0 | 3 | 1 | s1: type=item, is=2001229 | data/config/rite/5008197.json |

| 5008198 | 流民的索要 | 商业区:[10,19] | 0 | 0 | 1 | 5 | s1: type=char, is=2000195<br>s2: type=item, is=2001223<br>s3: type=item, is=2001229<br>s4: type=item, any={"空屋":1,"cost.金币":20} | data/config/rite/5008198.json |

| 5008199 | 无赖租客 | 商业区:[10,19] | 0 | 0 | 1 | 7 | s1: type=item, is=2001223<br>s2: type=item, 空屋=1<br>s3: any={"all":{"type":"item","cost.金币":20}}<br>s4: any={"type":"char"}, 部队=1, !is=2000431 | data/config/rite/5008199.json |

| 5008200 | 流民的帮闲 | 自宅:[2,12] | 1 | 0 | 3 | 1 | s1: type=item, is=2001233 | data/config/rite/5008200.json |

| 5008201 | [player.name]堡 | 商业区:20 | 0 | 0 | 1 | 5 | s1: type=char, is=2000195<br>s2: type=item, is=2001233<br>s3: any={"all":{"type":"sudan","any":{"征服":1,"杀戮":1},"rare<=":2}} | data/config/rite/5008201.json |

| 5008202 | [player.name]堡 | 商业区:20 | 0 | 0 | 3 | 0 | s1: type=item, is=2001233<br>s2: any={"all":{"type":"item","any":{"all":{"counter.7000847<":1,"is":2000884},"情报":1,"天象":1}}} | data/config/rite/5008202.json |

| 5008203 | 困顿的堡垒 | 商业区:20 | 0 | 0 | 1 | 7 | s1: type=char, is=2000195<br>s2: type=item, any={"cost.金币":40,"is":2001246} | data/config/rite/5008203.json |

| 5008204 | 忙碌的拉伊德 | 黑街:[1,5] | 1 | 0 | 3 | 0 | s1: type=char, is=2000195 | data/config/rite/5008204.json |

| 5008205 | 伪造公主 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000195<br>s2: type=char, 贵族=1, 隐匿>==5, 社交>==5<br>s3: type=char, any={"all":{"!is":2000064,"贵族":1,"社交>=":6},"is":2000057}<br>s4: type=char, any={"all":{"!is":2000064,"贵族":1,"社交>=":6},"is":2000057} | data/config/rite/5008205.json |

| 5008206 | 长袖善舞 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000195<br>s2: type=char, 贵族=1, !苏丹=1, !主角=1, !is=2000195<br>s3: type=char, 贵族=1, !苏丹=1, !主角=1, !is=2000195<br>s4: type=item, any={"is":2001226} | data/config/rite/5008206.json |

| 5008207 | 闪闪发光 | 上城区:[7,12] | 0 | 0 | 1 | 0 | s1: type=char, is=2000195<br>s2: type=char, !is=2000195, !大敌=1, !主角=1, any={"贵族":1,"is":2000022}<br>s3: type=char, !is=2000195, !大敌=1, !主角=1, any={"贵族":1,"is":2000022}<br>s4: type=item, any={"is":2001291} | data/config/rite/5008207.json |

| 5008208 | 哲瓦德的笑容 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000057<br>s2: type=item, 情报=1, rare>==3, cost.消耗品==1<br>s3: type=item, 情报=1, rare>==3, cost.消耗品==1<br>s4: type=item, 情报=1, rare>==3, cost.消耗品==1 | data/config/rite/5008208.json |

| 5008209 | 御医的诊治 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000011<br>s2: type=item, cost.金币=[8,16]<br>s3: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5008209.json |

| 5008210 | 密神的恩惠 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000022<br>s2: type=item, cost.金币=[8,16]<br>s3: type=sudan, 奢靡=1, rare<==2 | data/config/rite/5008210.json |

| 5008211 | 正神的恩惠 | 神殿区:[2,10] | 0 | 0 | 1 | 3 | s1: type=char, is=2000021<br>s2: type=item, cost.金币=[8,16]<br>s3: type=sudan, 奢靡=1, rare<==2<br>s4: type=item, any={"is":2000728} | data/config/rite/5008211.json |

| 5008212 | 机灵的仆役 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, 妻子=1<br>s2: type=item, 情报=1, rare>==3, cost.消耗品==1<br>s3: type=item, 情报=1, rare>==3, cost.消耗品==1<br>s4: type=item, 情报=1, rare>==3, cost.消耗品==1 | data/config/rite/5008212.json |

| 5008213 | 逆向工程 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000352<br>s2: type=item, any={"is":2000388}<br>s3: type=item, cost.金币=10 | data/config/rite/5008213.json |

| 5008214 | 花与剑 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000064<br>s2: type=char, 追随者=1, 魅力>==5<br>s3: type=char, 追随者=1, 魅力>==5 | data/config/rite/5008214.json |

| 5008215 | 苏丹的召见 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: type=char, is=2000195<br>s2: type=char, any={"is":2000019,"妻子":1}<br>s3: type=char, !主角=1, 贵族=1<br>s4: type=char, 主角=1 | data/config/rite/5008215.json |

| 5008216 | 她是谁？ | 自宅:[2,12] | 0 | 0 | 3 | 7 | s1: type=item, is=2001228<br>s2: type=char, 追随者=1, 贵族=1, !is=2000195, counter.7100003>==15<br>s3: type=char, 追随者=1, !贵族=1, !is=2000195, counter.7100004>==8<br>s4: any={"all":{"type":"item","cost.金币":5},"妓女":1} | data/config/rite/5008216.json |

| 5008217 | 女儿的故事 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=item, is=2001246<br>s2: type=char, any={"is":2000013} | data/config/rite/5008217.json |

| 5008218 | 死斗 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000195<br>s2: type=char, is=2000013 | data/config/rite/5008218.json |

| 5008219 | 杀戮与激情 | 自宅:[2,12] | 0 | 0 | 1 | 2 | s1: type=char, is=2000195<br>s2: type=char, 主角=1 | data/config/rite/5008219.json |

| 5008220 | 血亲之乐 | 宫廷:[7,10] | 1 | 0 | 1 | 1 | s1: type=char, is=2000195 | data/config/rite/5008220.json |

| 5008221 | 流落的血脉 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000129, !have.2000129.贬斥=1<br>s2: type=char, 主角=1<br>s3: type=char, 妻子=1 | data/config/rite/5008221.json |

| 5008222 | 石榴树的畸枝 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, 妻子=1<br>s2: type=char, 主角=1<br>s3: type=char, is=2000129 | data/config/rite/5008222.json |

| 5008223 | 更适合的差事 | 野外:[9,14] | 1 | 0 | 3 | 0 | s1: type=char, is=2000129 | data/config/rite/5008223.json |

| 5008224 | 兄妹之间 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=char, is=2000129<br>s3: type=item, 疯狂=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008224.json |

| 5008225 | 突然的坦白 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000129<br>s2: type=char, 妻子=1<br>s3: type=char, 主角=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008225.json |

| 5008226 | 愧疚与宝石 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, 妻子=1<br>s2: type=char, 主角=1<br>s3: type=item, cost.金币=[20,40]<br>s4: type=sudan, 奢靡=1, rare<==3, s3.金币=40 | data/config/rite/5008226.json |

| 5008227 | 兴师问罪 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000129<br>s2: type=char, 主角=1 | data/config/rite/5008227.json |

| 5008228 | 落幕之舞 | 自宅:[2,12] | 1 | 0 | 1 | 1 | s1: type=char, is=2000129<br>s2: type=item, is=2001307<br>s3: type=char, 主角=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5008228.json |

| 5008229 | 最后的谈话 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=char, 妻子=1 | data/config/rite/5008229.json |

| 5008230 | 舞乐之宴 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000129<br>s2: type=char, 主角=1<br>s3: type=char, 追随者=1<br>s4: type=char, 追随者=1 | data/config/rite/5008230.json |

| 5008231 | 贵族的邀请 | 自宅:[2,12] | 0 | 0 | 1 | 7 | s1: type=char, is=2000129<br>s2: type=char, 女性=1, 追随者=1, 贵族=1<br>s3: type=char, 追随者=1, !贵族=1, !is=2000129, !动物=1, !怪物=1<br>s4: type=item, cost.金币=3 | data/config/rite/5008231.json |

| 5008232 | 遍野流言 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, 追随者=1<br>s2: type=item, 情报=1, rare>==3<br>s3: type=item, 情报=1, rare>==3<br>s4: type=item, 情报=1, rare>==3 | data/config/rite/5008232.json |

| 5008233 | 沟渠的邀请 | 商业区:[10,19] | 0 | 0 | 1 | 3 | s1: type=char, is=2000129<br>s2: type=char, 追随者=1, !贵族=1<br>s3: type=char, 追随者=1, !贵族=1<br>s4: type=item, cost.金币=2 | data/config/rite/5008233.json |

| 5008234 | 欢愉之女的自由日 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, is=2000129<br>s2: type=char, 追随者=1, !妻子=1<br>s3: type=char, 追随者=1, !妻子=1<br>s4: type=char, 追随者=1, !妻子=1 | data/config/rite/5008234.json |

| 5008235 | 苏丹的兴致 | 宫廷:[2,6] | 0 | 0 | 1 | 3 | s1: type=char, is=2000129<br>s2: any={"all":{"type":"item","cost.金币":30}} | data/config/rite/5008235.json |

| 5008236 | 一支奇怪的舞蹈 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=char, is=2000129<br>s2: type=char, 主角=1 | data/config/rite/5008236.json |

| 5008237 | 失踪的舞姬 | 黑街:[2,5] | 0 | 0 | 1 | 2 | s1: type=char, is=2000129<br>s2: type=char, 追随者=1 | data/config/rite/5008237.json |

| 5008238 | 坟墓前的恳谈 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=char, is=2000129<br>s2: type=char, 主角=1<br>s3: type=char, 妻子=1<br>s4: type=sudan, rare<==3, 纵欲=1 | data/config/rite/5008238.json |

| 5008239 | 流浪的果实 | 野外:[9,14] | 0 | 0 | 1 | 3 | s1: type=char, is=2000129<br>s2: type=item, cost.金币=10<br>s3: type=char, !贵族=1, 追随者=1<br>s4: type=char, 主角=1 | data/config/rite/5008239.json |

| 5008240 | 太阳之舞 | 自宅:[2,12] | 0 | 0 | 1 | 5 | s1: type=char, 主角=1<br>s2: type=char, 追随者=1<br>s3: type=char, 追随者=1<br>s4: type=char, 追随者=1 | data/config/rite/5008240.json |

| 5008241 | 细鳞鱼干 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=item, is=2001316<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5008241.json |

| 5008242 | 美人的武装 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: is=2000129<br>s2: type=item, cost.金币=10<br>s3: type=item, 饰品=1, 魅力>==4<br>s4: type=char, 贵族=1, 女性=1 | data/config/rite/5008242.json |

| 5008243 | 散落的果实 | 宫廷:[2,6] | 1 | 0 | 1 | 1 | s1: is=2000129 | data/config/rite/5008243.json |

| 5008244 | 女奴的撕扯 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129<br>s2: type=char, 贵族=1<br>s3: type=item, cost.金币=5 | data/config/rite/5008244.json |

| 5008245 | 有毒的花丛 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129<br>s2: type=item, any={"is":2000391} | data/config/rite/5008245.json |

| 5008246 | 花朵的战争 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129, 苏丹的妃子=1<br>s2: type=item, 情报=1, rare==4, cost.消耗品==1<br>s3: type=item, 情报=1, rare==4, cost.消耗品==1<br>s4: type=item, 情报=1, rare==4, cost.消耗品==1 | data/config/rite/5008246.json |

| 5008247 | 好茶 | 自宅:[2,12] | 0 | 0 | 1 | 3 | s1: type=item, is=2001333<br>s2: type=char, 主角=1<br>s3: type=char, any={"妻子":1,"侧室":1,"新妻":1,"is":2000082}<br>s4: any={"all":{"s3.新妻":1,"is":2000698}} | data/config/rite/5008247.json |

| 5008248 | 夜晚的权利 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129, 苏丹的妃子=1<br>s2: type=char, 贵族=1, 魅力>==5, 魔力>==5<br>s3: type=item, 天象=1 | data/config/rite/5008248.json |

| 5008249 | 更贵的美 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129, 苏丹的妃子=1<br>s2: type=item, 大颗=1, 饰品=1<br>s3: type=item, 大颗=1, 饰品=1 | data/config/rite/5008249.json |

| 5008250 | 寝技的比拼 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129, 苏丹的妃子=1<br>s2: type=char, 追随者=1, any={"is":2000082}<br>s3: type=item, cost.金币=20 | data/config/rite/5008250.json |

| 5008251 | 拥挤的王座 | 宫廷:[2,6] | 0 | 0 | 1 | 1 | s1: is=2000129, 苏丹的妃子=1<br>s2: is=2000010<br>s3: type=char, 主角=1<br>s4: type=char, 主角=1 | data/config/rite/5008251.json |

| 5008252 | 我想要她美丽的头颅 | 宫廷:[2,6] | 1 | 0 | 1 | 1 | s1: type=char, is=2000129 | data/config/rite/5008252.json |

| 5008253 | 无头之舞 | 宫廷:[2,6] | 1 | 0 | 1 | 1 | s1: type=char, is=2000129 | data/config/rite/5008253.json |

| 5008254 | 宠妃的心愿 | 宫廷:[2,6] | 1 | 0 | 1 | 1 | s1: type=char, is=2000129 | data/config/rite/5008254.json |

| 5008255 | 玫瑰的刺 | 宫廷:[2,6] | 1 | 0 | 1 | 0 | s1: is=2000129<br>s2: is=2000010<br>s3: !s4=1, any={"all":{"type":"item","情报":1}}<br>s4: any={"all":{"type":"item","情报":1}} | data/config/rite/5008255.json |

| 5008256 | 唯一的宠妃 | 宫廷:[2,6] | 1 | 0 | 1 | 1 | s1: type=char, is=2000129 | data/config/rite/5008256.json |

| 5008257 | 臣服 | 结局:5 | 1 | 0 | 0 | 1 | s1: any={"all":{"type":"char","妻子":1},"侧室":1,"新妻":1} | data/config/rite/5008257.json |

| 5008258 | 期待 | 结局:5 | 1 | 0 | 0 | 1 | s1: any={"all":{"type":"char","is":2000123},"孤儿":1,"is":2000989} | data/config/rite/5008258.json |

| 5008259 | 敌人 | 结局:5 | 1 | 0 | 0 | 1 | s1: type=item, any={"is":2000694} | data/config/rite/5008259.json |

| 5008260 | 蓝图 | 结局:5 | 1 | 0 | 0 | 1 | s1: type=item, any={"is":2000706} | data/config/rite/5008260.json |

| 5010000 | 逃亡倒计时 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, cost.权势的遮掩=[1,5]<br>s2: type=item, cost.善名的遮掩=[1,5]<br>s3: type=item, cost.侠名的遮掩=[1,5]<br>s4: type=item, cost.灵视的遮掩=[1,5] | data/config/rite/5010000.json |

| 5010001 | 出发！ | 结局:2 | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: 目的地=1<br>s3: type=item, cost.打包的财物=[1,999]<br>s4: type=char, 追随的人=1 | data/config/rite/5010001.json |

| 5010002 | 裂魂之夜 | 结局:2 | 1 | 0 | 0 | 0 | s1: type=char, 主角=1, 追随的人=1 | data/config/rite/5010002.json |

| 5010003 | 最后的纵欲卡 | 结局:2 | 1 | 0 | 1 | 0 | s1: type=char, 追随的人=1<br>s2: type=sudan, 纵欲=1<br>s3: is=2000545 | data/config/rite/5010003.json |

| 5010004 | 最后的杀戮卡 | 结局:2 | 1 | 0 | 1 | 0 | s1: type=char, 追随的人=1<br>s2: type=sudan, 杀戮=1<br>s3: is=2000545 | data/config/rite/5010004.json |

| 5010005 | 最后的征服卡 | 结局:2 | 1 | 0 | 1 | 0 | s1: type=char, 追随的人=1<br>s2: type=sudan, 征服=1<br>s3: is=2000545 | data/config/rite/5010005.json |

| 5010006 | 最后的奢靡卡 | 结局:2 | 1 | 0 | 1 | 0 | s1: type=item, cost.打包的财物=[1,999]<br>s2: type=sudan, 奢靡=1<br>s3: is=2000545 | data/config/rite/5010006.json |

| 5010007 | 于黎明前 | 结局:1 | 0 | 0 | 1 | 3 | s1: type=char, 主角=1<br>s2: any={"type":"sudan"}, 正当性=1<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5010007.json |

| 5010008 | 集结部队 | 结局:1 | 1 | 1 | 1 | 0 | s1: type=item, is=2000914, cost.倒计时=[1,5]<br>s2: any={"type":"sudan"}, 正当性=1 | data/config/rite/5010008.json |

| 5010009 | 誓师 | 结局:3 | 0 | 0 | 1 | 1 | s1: type=char, 主角=1<br>s2: any={"type":"sudan"}, 正当性=1<br>s3: any={"type":"char"}, 部队=1, !is=2000431<br>s4: any={"type":"char"}, 部队=1, !is=2000431 | data/config/rite/5010009.json |

| 5010010 | 苏丹的近卫们 | 宫廷:7 | 0 | 0 | 0 | 1 | s1: type=char, is=2000064, 追随者=1<br>s2: type=char, is=2000065, 追随者=1<br>s3: type=char, is=2000054, 追随者=1<br>s4: type=char, is=2000292, 追随者=1 | data/config/rite/5010010.json |

| 5010011 | 苏丹的城墙 | 结局:3 | 1 | 0 | 0 | 0 | s1: 苏丹的精兵=1<br>s2: type=char<br>s3: any={"all":{"any":{"type":"char"},"部队":1},"type":"char","is":2000477}<br>s4: 苏丹的精兵=1 | data/config/rite/5010011.json |

| 5010012 | 燃烧的城市 | 结局:4 | 1 | 0 | 0 | 0 | s1: 苏丹的精兵=1<br>s2: type=char, !失去战力=1<br>s3: any={"all":{"any":{"type":"char"},"部队":1},"type":"char","is":2000477}, !失去战力=1<br>s4: 苏丹的精兵=1 | data/config/rite/5010012.json |

| 5010013 | 皇宫 | 结局:5 | 1 | 0 | 0 | 0 | s1: 苏丹的精兵=1<br>s2: type=char, !失去战力=1<br>s3: any={"all":{"any":{"type":"char"},"部队":1},"type":"char","is":2000385}, !失去战力=1<br>s4: 苏丹的精兵=1 | data/config/rite/5010013.json |

| 5010014 | 直面苏丹 | 结局:6 | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: type=item, is=2000915<br>s3: type=item, is=2000916<br>s4: type=item, is=2000917 | data/config/rite/5010014.json |

| 5010015 | 近卫的承诺 | 结局:6 | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: is=2000064<br>s3: is=2000054<br>s4: is=2000292 | data/config/rite/5010015.json |

| 5010016 | 为所欲为 | 结局:6 | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: type=char, 主角=1, !s3=1, !s4=1, !s5=1<br>s3: any={"all":{"type":"item","is":2000959}}, !s2=1, !s4=1, !s5=1<br>s4: type=char, 主角=1, !s2=1, !s3=1, !s5=1 | data/config/rite/5010016.json |

| 5010017 | 光之舞 | 结局:6 | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: any={"is":2000281,"变革戒":1,"群星戒":1}<br>s3: type=item, is=2000545<br>s4: type=char | data/config/rite/5010017.json |

| 5010018 | 剑之舞 | 结局:6 | 1 | 0 | 0 | 0 | s1: type=char, 苏丹的近卫=1<br>s2: type=char, 苏丹的近卫=1<br>s3: type=char, 苏丹的近卫=1<br>s4: type=char, 苏丹的近卫=1 | data/config/rite/5010018.json |

| 5010019 | 王之舞 | 结局:6 | 1 | 0 | 0 | 0 | s1: type=char, is=2000024<br>s2: type=char, 主角=1<br>s3: 正当性=1<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5010019.json |

| 5010020 | 奈费勒的毒箭 | 上城区:3 | 0 | 0 | 0 | 1 | s1: type=char, is=2000312<br>s2: type=char, 主角=1 | data/config/rite/5010020.json |

| 5010021 | 娜依拉的索求 | 自宅:10 | 0 | 0 | 1 | 3 | s1: type=char, is=2000055<br>s2: type=item, cost.金币=40<br>s3: type=char<br>s4: type=item, cost.消耗品==1, !金币=1 | data/config/rite/5010021.json |

| 5010022 | 帷幕之后 | 结局:6 | 1 | 0 | 1 | 0 | s1: any={"type":"sudan"}, 正当性=1<br>s2: type=item, any={"is":2001107}<br>s3: type=char, 主角=1 | data/config/rite/5010022.json |

| 5010023 | 阶梯 | 结局:6 | 0 | 0 | 1 | 0 | s1: any={"all":{"type":"char","妖精":1,"!s6.妖精":1,"!s7.妖精":1,"!s8.妖精":1,"!s9.妖精":1,"!s10.妖精":1}}<br>s2: any={"all":{"type":"char","妖精":1,"!s6.妖精":1,"!s7.妖精":1,"!s8.妖精":1,"!s9.妖精":1,"!s10.妖精":1}}<br>s3: any={"all":{"type":"char","妖精":1,"!s6.妖精":1,"!s7.妖精":1,"!s8.妖精":1,"!s9.妖精":1,"!s10.妖精":1}}<br>s4: any={"all":{"type":"char","妖精":1,"!s6.妖精":1,"!s7.妖精":1,"!s8.妖精":1,"!s9.妖精":1,"!s10.妖精":1}} | data/config/rite/5010023.json |

| 5010024 | 果实 | 结局:6 | 0 | 0 | 1 | 0 | s1: any={"type":"sudan"}, 正当性=1<br>s2: type=char, any={"主角":1,"all":{"s1.is":2000913,"is":2000013}}<br>s3: any={"all":{"s4.is":2000412,"is":2000022}}<br>s4: type=item, any={"all":{"s2.主角":1,"is":2001296}} | data/config/rite/5010024.json |

| 5010025 | 集结部队 | 结局:1 | 1 | 0 | 1 | 0 | s1: type=item, is=2000914, cost.倒计时=[1,5]<br>s2: any={"type":"sudan"}, 正当性=1 | data/config/rite/5010025.json |

| 5010026 | 最后的纵欲卡 | 宫廷:1 | 0 | 0 | 1 | 1 | s1: type=char, is=2000024<br>s2: type=char, 主角=1<br>s3: type=sudan<br>s4: any={"is":2000173,"all":{"被覆者":1,"苏丹的玩偶":1}} | data/config/rite/5010026.json |

| 5010027 | 最后的杀戮卡 | 宫廷:1 | 0 | 0 | 1 | 1 | s1: type=char, is=2000024<br>s2: type=char, 主角=1<br>s3: type=sudan<br>s4: any={"is":2000173,"all":{"被覆者":1,"苏丹的玩偶":1}} | data/config/rite/5010027.json |

| 5010028 | 最后的奢靡卡 | 宫廷:1 | 0 | 0 | 1 | 1 | s1: type=char, is=2000024<br>s2: type=char, 主角=1<br>s3: type=sudan<br>s4: any={"is":2000173,"all":{"被覆者":1,"苏丹的玩偶":1}} | data/config/rite/5010028.json |

| 5010029 | 最后的征服卡 | 宫廷:1 | 0 | 0 | 1 | 1 | s1: type=char, is=2000024<br>s2: type=char, 主角=1<br>s3: type=sudan<br>s4: any={"is":2000173,"all":{"被覆者":1,"苏丹的玩偶":1}} | data/config/rite/5010029.json |

| 5010030 | 深渊的邀请 | 自宅:[2,12] | 0 | 0 | 0 | 0 | s1: type=char, 主角=1<br>s2: type=sudan<br>s3: any={"妻子":1,"all":{"type":"char","命运的羁绊":1}}<br>s4: any={"妻子":1,"all":{"type":"char","命运的羁绊":1}} | data/config/rite/5010030.json |

| 5010031 | 女术士的邀请 | 宫廷:2 | 0 | 0 | 0 | 0 | s1: type=char, 主角=1 | data/config/rite/5010031.json |

| 5010032 | 苏丹的奖赏 | 宫廷:1 | 0 | 0 | 1 | 1 | s1: type=char, is=2000024<br>s2: type=char, 主角=1<br>s3: any={"is":2000173,"all":{"被覆者":1,"苏丹的玩偶":1}}<br>s4: type=char, 贵族=1, !主角=1 | data/config/rite/5010032.json |

| 5010033 | 古老的道路 | 上城区:3 | 0 | 0 | 1 | 1 | s1: type=item, is=2001033<br>s2: type=char, 主角=1 | data/config/rite/5010033.json |

| 5010034 | 神圣的烙印 | 神殿区:[2,10] | 1 | 1 | 1 | 0 | s1: type=item, is=2001076, cost.耐心=[1,99]<br>s2: type=item, is=2001077<br>s3: type=item, is=2001036, 塔=1<br>s4: type=item, is=2001037, 塔=1 | data/config/rite/5010034.json |

| 5010035 | 废弃 | 上城区:3 | 0 | 0 | 1 | 1 | s1: type=item, is=2001033<br>s2: type=char, 主角=1 | data/config/rite/5010035.json |

| 5010036 | 觐见苏丹 | 宫廷:[7,10] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: type=char, !主角=1, !密教徒=1<br>s3: type=item, cost.金币=20 | data/config/rite/5010036.json |

| 5010037 | 立柱 | 神殿区:11 | 0 | 0 | 5 | 0 | s1: type=char, 智慧>==8<br>s2: type=char, 体魄>==5, 社交>==5<br>s3: type=char, 贵族=1, 智慧>==5, 隐匿>==5<br>s4: type=item, cost.金币=15 | data/config/rite/5010037.json |

| 5010038 | 镀金 | 神殿区:11 | 0 | 0 | 3 | 0 | s1: !s3=1, type=char<br>s2: !s3=1, type=item, cost.金币=15<br>s3: type=item, is=2001035<br>s4: !s3=1, type=sudan, 奢靡=1 | data/config/rite/5010038.json |

| 5010039 | 引火物 | 神殿区:11 | 0 | 0 | 0 | 0 | s1: !s2=1, type=sudan, 征服=1<br>s2: type=item, is=2001036 | data/config/rite/5010039.json |

| 5010040 | 审判烈焰 | 神殿区:11 | 0 | 0 | 0 | 0 | s1: type=sudan, 征服=1, 塔=1<br>s2: type=char, any={"all":{"s1.rare=":4,"any":{"is":2001089,"all":{"is":2000082,"rare=":4}}}} | data/config/rite/5010040.json |

| 5010041 | 最后的诱惑 | 神殿区:11 | 0 | 0 | 1 | 0 | s1: !s3=1, type=char, 主角=1<br>s2: !s3=1, type=char, any={"激情":1,"is":2000021}<br>s3: type=item, is=2001037<br>s4: !s3=1, type=sudan, 纵欲=1 | data/config/rite/5010041.json |

| 5010042 | 神临仪式 | 神殿区:11 | 0 | 0 | 0 | 3 | s1: type=char, any={"主角":1,"is":2000021}<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5010042.json |

| 5010043 | 弑神（废弃） | 神殿区:11 | 1 | 0 | 0 | 3 | s1: type=char, any={"主角":1,"is":2000021}<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5010043.json |

| 5010044 | 教领的特权 | 神殿区:[2,10] | 0 | 1 | 1 | 0 | s1: type=item, cost.正教的乙太=1<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5010044.json |

| 5010045 | 世界之眼 | 神殿区:11 | 1 | 0 | 0 | 0 | s1: cost.正教的乙太=[1,2]<br>s2: is=2000545<br>s3: type=char, any={"主角":1,"is":2001023}<br>s4: type=char | data/config/rite/5010045.json |

| 5010046 | 大猎捕 | 神殿区:11 | 1 | 0 | 0 | 0 | s1: type=item, cost.正教的乙太=[1,2]<br>s2: is=2001102<br>s3: is=2000844<br>s4: type=char | data/config/rite/5010046.json |

| 5010047 | 匕首之路 | 神殿区:11 | 1 | 0 | 0 | 0 | s1: type=item, cost.正教的乙太=[1,2]<br>s2: type=char, !失去战力=1<br>s3: type=char, !失去战力=1<br>s4: type=char, !失去战力=1 | data/config/rite/5010047.json |

| 5010048 | 天空之火 | 神殿区:11 | 1 | 0 | 0 | 0 | s1: type=item, cost.正教的乙太=[1,2]<br>s2: type=char, !失去战力=1<br>s3: type=char, !失去战力=1<br>s4: type=char, !失去战力=1 | data/config/rite/5010048.json |

| 5010049 | 转生的真神 | 神殿区:11 | 1 | 0 | 0 | 0 | s1: type=item, cost.正教的乙太=[1,99]<br>s2: is=2000848<br>s3: type=char, 主角=1<br>s4: type=char, is=2000024 | data/config/rite/5010049.json |

| 5010050 | 恶之华 | 黑街:[1,9] | 1 | 1 | 1 | 0 | s1: type=item, is=2001122, cost.耐心=[1,99]<br>s2: type=item, is=2001123<br>s3: type=item, is=2001126<br>s4: type=item, is=2001039, 诞生=1 | data/config/rite/5010050.json |

| 5010051 | 受孕 | 自宅:[2,12] | 0 | 0 | 1 | 0 | s1: type=item, is=2000412<br>s2: type=char, any={"主角":1,"妻子":1,"all":{"is":2000022,"密教徒":1}}<br>s3: type=char, 黑暗知识=1, 魔力>==6<br>s4: type=char, 密教徒=1 | data/config/rite/5010051.json |

| 5010052 | 喂食 | 自宅:[2,12] | 0 | 0 | 1 | 1 | s1: type=item, is=2001123<br>s2: any={"type":"char","任意处置":1,"all":{"type":"item","动物":1}}, !怪物=1<br>s3: type=item, is=2001040<br>s4: !s3=1, type=sudan, 奢靡=1 | data/config/rite/5010052.json |

| 5010053 | 饥渴 | 自宅:[2,12] | 1 | 0 | 1 | 0 | s1: type=item, is=2001123<br>s2: any={"all":{"type":"char","追随者":1},"任意处置":1}, !怪物=1 | data/config/rite/5010053.json |

| 5010054 | 救赎的机会 | 神殿区:[2,10] | 0 | 0 | 1 | 0 | s1: type=char, is=2000021<br>s2: type=char, 主角=1<br>s3: type=item, is=2001123 | data/config/rite/5010054.json |

| 5010055 | 子宫 | 黑街:[1,9] | 0 | 0 | 1 | 0 | s1: type=item, is=2001125<br>s2: any={"type":"char"}, 部队=1<br>s3: type=item, is=2001042<br>s4: !s3=1, type=sudan, 征服=1 | data/config/rite/5010055.json |

| 5010056 | 献祭 | 黑街:[1,9] | 0 | 0 | 1 | 0 | s1: type=item, is=2001126<br>s2: type=char, 密教徒=1<br>s3: type=char, 密教徒=1<br>s4: type=char, 密教徒=1 | data/config/rite/5010056.json |

| 5010057 | 苏丹的诘问 | 宫廷:[7,10] | 0 | 0 | 1 | 3 | s1: type=item, cost.金币==20<br>s2: type=char, 怪物=1, 体魄>==5, 战斗>==5<br>s3: type=char, any={"密教徒":1,"怪物":1}, 魅力>==10<br>s4: type=item, is=2001126 | data/config/rite/5010057.json |

| 5010058 | 讨伐 | 自宅:[2,12] | 0 | 0 | 3 | 0 | s1: any={"all":{"type":"char","追随者":1,"!密教徒":1,"!命运的羁绊":1,"!怪物":1}}, !主角=1<br>s2: any={"all":{"type":"char","追随者":1,"!密教徒":1,"!命运的羁绊":1,"!怪物":1}}, !主角=1<br>s3: any={"all":{"type":"char","追随者":1,"!密教徒":1,"!命运的羁绊":1,"!怪物":1}}, !主角=1<br>s4: any={"all":{"is":2000021,"!密教徒":1,"!命运的羁绊":1},"is":2001093} | data/config/rite/5010058.json |

| 5010059 | 神的诞生 | 黑街:[1,9] | 0 | 0 | 0 | 3 | s1: type=item, is=2001123<br>s2: type=item, is=2001126<br>s3: any={"all":{"黑暗知识":1,"type":"char"},"孤儿":1,"is":2001124}<br>s4: type=item, is=2001039, 诞生=1 | data/config/rite/5010059.json |

| 5010060 | 暗影渐起 | 黑街:[1,9] | 1 | 0 | 0 | 0 | s1: type=char, 主角=1<br>s2: any={"type":"char","all":{"type":"item","部队":1}}<br>s3: any={"type":"char","all":{"type":"item","部队":1}}<br>s4: any={"type":"char","all":{"type":"item","部队":1}} | data/config/rite/5010060.json |

| 5010061 | 末日风暴 | 黑街:[1,9] | 1 | 0 | 0 | 0 | s1: any={"type":"char","all":{"type":"item","部队":1}}<br>s2: any={"type":"char","all":{"type":"item","部队":1}}<br>s3: any={"type":"char","all":{"type":"item","部队":1}}<br>s4: any={"type":"char","all":{"type":"item","部队":1}} | data/config/rite/5010061.json |

| 5010062 | 迷梦之刃 | 黑街:[1,9] | 1 | 0 | 0 | 0 | s1: type=char<br>s2: type=char<br>s3: type=char<br>s4: type=char | data/config/rite/5010062.json |

| 5010063 | 造化歧路 | 黑街:[1,9] | 1 | 0 | 0 | 0 | s1: is=2001128<br>s2: type=char<br>s3: is=2001129<br>s4: type=char | data/config/rite/5010063.json |

| 5010064 | 混沌之王 | 黑街:[1,9] | 1 | 0 | 0 | 0 | s1: is=2000844<br>s2: 吸收天使=1<br>s3: 吸收念珠=1<br>s4: 吸收信徒=1 | data/config/rite/5010064.json |

| 5010065 | 龙眼的研究 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: is=2000668<br>s2: any={"type":"char","all":{"type":"item","any":{"is":2000848}}} | data/config/rite/5010065.json |

| 5010066 | 魔力熔炉 | 黑街:[1,9] | 0 | 0 | 3 | 0 | s1: is=2000668<br>s2: is=2000352<br>s3: is=2000986, cost.可堆叠==1<br>s4: any={"type":"item"}, 魔力>==1 | data/config/rite/5010066.json |

| 5010067 | 龙眼的雕琢 | 黑街:[1,9] | 0 | 0 | 3 | 0 | s1: is=2000668<br>s2: is=2000352<br>s3: is=2000986, cost.可堆叠==1<br>s4: type=item, 武器=1, rare==4 | data/config/rite/5010067.json |

| 5010068 | 最后的打磨 | 黑街:[1,9] | 0 | 0 | 1 | 0 | s1: is=2001300<br>s2: any={"is":2000352,"主角":1}<br>s3: is=2000986, cost.可堆叠==1<br>s4: any={"cost.金币":60,"all":{"is":2001267,"cost.钻石":3}} | data/config/rite/5010068.json |

| 5010069 | 趁生命气息逗留 | 黑街:[1,9] | 1 | 0 | 1 | 0 | s1: is=2001300<br>s2: type=char, 主角=1<br>s3: type=char, 妻子=1<br>s4: is=2001299 | data/config/rite/5010069.json |

| 5010070 | 成神 | 黑街:[1,9] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1, 入圣=1<br>s2: type=char, 主角=1, !入圣=1 | data/config/rite/5010070.json |

| 5010071 | 疏离感 | 黑街:[1,9] | 0 | 0 | 1 | 0 | s1: type=char, 主角=1, 入圣=1<br>s2: type=char, 主角=1, !入圣=1 | data/config/rite/5010071.json |

| 5010072 | 你的代言人 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: type=char, any={"all":{"counter.7000922":1,"is":2000352},"妻子":1} | data/config/rite/5010072.json |

| 5010073 | 布道 | 黑街:[1,9] | 0 | 0 | 1 | 3 | s1: 神的代言人=1<br>s2: type=item, 神性=1<br>s3: type=char, !妻子=1, !动物=1, !怪物=1<br>s4: type=char, !妻子=1, !动物=1, !怪物=1 | data/config/rite/5010073.json |

| 5010074 | 近卫的职责 | 结局:6 | 1 | 0 | 0 | 0 | s1: any={"is":2000923}<br>s2: any={"is":2000925}<br>s3: any={"is":2000292}<br>s4: any={"is":2000926} | data/config/rite/5010074.json |

| 5010075 | 蚁群 | 黑街:[1,9] | 0 | 0 | 1 | 1 | s1: type=char, 神的代言人=1<br>s2: 神性=1<br>s3: type=char, !妻子=1, !动物=1, !怪物=1<br>s4: any={"动物":1,"怪物":1} | data/config/rite/5010075.json |

| 5010076 | 土丘 | 结局:3 | 1 | 0 | 0 | 0 | s1: 苏丹的精兵=1<br>s2: type=char, !神选冠军=1<br>s3: any={"type":"char"}, 部队=1, !is=2000431<br>s4: 苏丹的精兵=1 | data/config/rite/5010076.json |

| 5010077 | 蚁穴 | 结局:4 | 1 | 0 | 0 | 0 | s1: 苏丹的精兵=1<br>s2: type=char, !神选冠军=1<br>s3: any={"type":"char"}, 部队=1, !is=2000431<br>s4: 苏丹的精兵=1 | data/config/rite/5010077.json |

| 5010078 | 宝盒 | 结局:5 | 1 | 0 | 0 | 0 | s1: 苏丹的精兵=1<br>s2: type=char, !神选冠军=1<br>s3: any={"type":"char"}, 部队=1, !is=2000431<br>s4: 苏丹的精兵=1 | data/config/rite/5010078.json |

| 5010079 | 火焰大王 | 自宅:[2,12] | 0 | 0 | 0 | 1 | s1: type=item, 神性=1<br>s2: is=2000762 | data/config/rite/5010079.json |

| 5010080 | 倾覆之塔 | 结局:6 | 1 | 0 | 0 | 0 | s1: is=2000024<br>s2: is=2000064, 苏丹的近卫=1<br>s3: is=2000054, 苏丹的近卫=1<br>s4: any={"is":2000292}, 苏丹的近卫=1 | data/config/rite/5010080.json |

| 5010081 | 废墟之上（废弃） | 结局:6 | 1 | 0 | 1 | 0 | s1: 神性=1<br>s2: type=item, any={"is":2001031} | data/config/rite/5010081.json |

| 5010082 | 神之天平（废弃） | 结局:6 | 0 | 0 | 1 | 0 | s1: type=char, !主角=1<br>s2: type=char, !主角=1<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5010082.json |

| 5010083 | 神之天平（废弃） | 结局:6 | 0 | 0 | 1 | 0 | s1: type=char, !主角=1<br>s2: type=char, !主角=1<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5010083.json |

| 5010084 | 神之天平（废弃） | 结局:6 | 0 | 0 | 1 | 0 | s1: type=char, !主角=1<br>s2: type=char, !主角=1<br>s3: type=char, !主角=1<br>s4: type=char, !主角=1 | data/config/rite/5010084.json |

| 5010085 | 新纪元（废弃） | 结局:6 | 0 | 0 | 1 | 0 | s1: 神性=1<br>s2: type=char, !主角=1, !妻子=1<br>s3: type=char, !主角=1, !妻子=1<br>s4: any={"is":2001332} | data/config/rite/5010085.json |

| 5010086 | 神座 | 奇珍:6 | 1 | 0 | 1 | 0 | s1: 主角=1, 神明=1 | data/config/rite/5010086.json |

| 5010087 | 神与人 | 结局:6 | 0 | 0 | 1 | 0 | s1: 神的代言人=1<br>s2: any={"火焰大王2":1,"all":{"type":"char","!主角":1}}<br>s3: any={"火焰大王2":1,"all":{"type":"char","!主角":1}}<br>s4: any={"火焰大王2":1,"all":{"type":"char","!主角":1}} | data/config/rite/5010087.json |

| 5010088 | 沐浴龙血 | 野外:[9,14] | 0 | 0 | 0 | 0 | s1: is=2000954<br>s2: any={"type":"char","all":{"type":"item","部队":1}}<br>s3: any={"type":"char","all":{"type":"item","部队":1}}<br>s4: any={"type":"char","all":{"type":"item","部队":1}} | data/config/rite/5010088.json |

| 5010201 | 往新世界 | 结局:9 | 1 | 0 | 0 | 0 | s1: 主角=1<br>s2: type=item, is=2001299 | data/config/rite/5010201.json |

| 5010202 | 羊肉炉的飞升 | 结局:14 | 1 | 0 | 1 | 0 | s1: type=item, is=2001344, cost.羊肉炉飞升进度=[1,7] | data/config/rite/5010202.json |

| 5010203 | 尘世墨水 | 结局:10 | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: any={"!消耗品":1,"is":2001185}<br>s3: any={"!消耗品":1,"is":2001185}, !s5=1<br>s4: any={"!消耗品":1,"is":2001185}, !s6=1 | data/config/rite/5010203.json |

| 5010204 | 自我认同 | 结局:11 | 1 | 0 | 0 | 0 | s1: type=char, 主角=1<br>s2: any={"is":2000461,"主角":1}<br>s3: is=2001345 | data/config/rite/5010204.json |

| 5010205 | 虚空之火 | 结局:11 | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: any={"!消耗品":1,"is":2001185}<br>s3: any={"!消耗品":1,"is":2001185}, !s5=1<br>s4: any={"!消耗品":1,"is":2001185}, !s6=1 | data/config/rite/5010205.json |

| 5010206 | 造化之风 | 结局:12 | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: any={"!消耗品":1,"is":2001185}<br>s3: any={"!消耗品":1,"is":2001185}, !s5=1<br>s4: any={"!消耗品":1,"is":2001185}, !s6=1 | data/config/rite/5010206.json |

| 5010207 | 陶土之门 | 结局:13 | 0 | 0 | 1 | 0 | s1: type=char, 主角=1<br>s2: any={"!消耗品":1,"is":2001185}<br>s3: any={"!消耗品":1,"is":2001185}, !s5=1<br>s4: any={"!消耗品":1,"is":2001185}, !s6=1 | data/config/rite/5010207.json |

| 5010208 | 终极问题 | 结局:13 | 0 | 0 | 0 | 0 | s1: any={"主角":1,"妻子":1,"is":2000689} | data/config/rite/5010208.json |

| 5010209 | 羊肉炉的飞升 | 结局:15 | 1 | 0 | 1 | 0 | s1: is=2001344, cost.羊肉炉飞升进度=[1,7] | data/config/rite/5010209.json |

| 5010210 | 羊肉炉的飞升 | 结局:16 | 1 | 0 | 1 | 0 | s1: is=2001344, cost.羊肉炉飞升进度=[1,7] | data/config/rite/5010210.json |

| 5010211 | 羊肉炉的飞升 | 结局:17 | 1 | 0 | 1 | 0 | s1: is=2001344, cost.羊肉炉飞升进度=[1,7] | data/config/rite/5010211.json |

| 5010212 | 羊肉炉的飞升 | 结局:18 | 1 | 0 | 1 | 0 | s1: is=2001344, cost.羊肉炉飞升进度=[1,7] | data/config/rite/5010212.json |

| 5010213 | 羊肉炉的飞升 | 结局:19 | 1 | 0 | 1 | 0 | s1: is=2001344, cost.羊肉炉飞升进度=[1,7] | data/config/rite/5010213.json |

| 5010214 | 羊肉炉的飞升 | 结局:20 | 1 | 0 | 1 | 0 | s1: is=2001344, cost.羊肉炉飞升进度=[1,7] | data/config/rite/5010214.json |


</details>


<a id="e068"></a>

## Original Story Event Configs

证据范围：`docs/replica/content.md#e068`，基准`843f0100`。以下为原批次事实、推理和验证记录，**局部通过/未决均不自动成为当前全局状态；当前决定以本章顶部与METHOD_MAP为准**。

<details>
<summary>展开来源、方法、边界和验证细节</summary>

### Original Story Event Configs



Source: Faust-local-source/_unpack/data/config/event/*.json. These are story trigger/branch configs, not the same as the card-slot rite UI.



Total: 1863



| ID | TextOrName | AutoStart | StartTrigger | TriggerKeys | SettlementCount | OriginalConfigPath |

| --- | --- | --- | --- | --- | --- | --- |

| 5300000 | 开场介绍 | false | true | round_begin_ba | 1 | data/config/event/5300000.json |

| 5300002 | 向神殿求助 | false | true | round_begin_ba | 1 | data/config/event/5300002.json |

| 5300003 | 研究邪术 | false | true | round_begin_ba | 1 | data/config/event/5300003.json |

| 5300004 | 拜访法务官 | false | true | round_begin_ba | 1 | data/config/event/5300004.json |

| 5300005 | 法务官之死 | false | true | round_begin_ba | 1 | data/config/event/5300005.json |

| 5300006 | 一桩无法追溯的罪行 | false | true | round_begin_ba | 1 | data/config/event/5300006.json |

| 5300007 | 邪术师的藏匿点A | false | true | round_begin_ba | 1 | data/config/event/5300007.json |

| 5300008 | 邪术师的藏匿点B | false | true | round_begin_ba | 1 | data/config/event/5300008.json |

| 5300009 | 蒸汽社交 | false | false | round_begin_ba | 1 | data/config/event/5300009.json |

| 5300010 | 浴场约会 | false | false | round_begin_ba | 1 | data/config/event/5300010.json |

| 5300011 | 疾病肆虐 |  | false | round_begin_ba | 1 | data/config/event/5300011.json |

| 5300012 | 普通妓院 | false | true | round_begin_ba | 1 | data/config/event/5300012.json |

| 5300013 | 普通妓院（石美人死了） | false | true | round_begin_ba | 1 | data/config/event/5300013.json |

| 5300014 | 普通妓院（铜美人死了） | false | true | round_begin_ba | 1 | data/config/event/5300014.json |

| 5300015 | 普通妓院（银美人死了） | false | true | round_begin_ba | 1 | data/config/event/5300015.json |

| 5300016 | 普通妓院（石铜美人死了） | false | true | round_begin_ba | 1 | data/config/event/5300016.json |

| 5300017 | 普通妓院（石银美人死了） | false | true | round_begin_ba | 1 | data/config/event/5300017.json |

| 5300018 | 普通妓院（铜银美人死了） | false | true | round_begin_ba | 1 | data/config/event/5300018.json |

| 5300019 | 食人的流浪狗 | false | true | round_begin_ba | 1 | data/config/event/5300019.json |

| 5300020 | 没头脑和不高兴 | false | true | round_begin_ba | 1 | data/config/event/5300020.json |

| 5300021 | 私奔 | false | true | round_begin_ba | 1 | data/config/event/5300021.json |

| 5300022 | 死于睡梦中 | false | true | round_begin_ba | 1 | data/config/event/5300022.json |

| 5300023 | 妻子正在酝酿不满 |  | false | round_begin_ba | 1 | data/config/event/5300023.json |

| 5300024 | 捉奸 | false | true | round_begin_ba | 1 | data/config/event/5300024.json |

| 5300025 | 死于睡梦中(源自妻子出轨的累积) |  | false | round_begin_ba | 1 | data/config/event/5300025.json |

| 5300026 | 书店约会 | false | false | round_begin_ba | 1 | data/config/event/5300026.json |

| 5300027 | 书店门口的乞丐 |  | false | round_begin_ba | 1 | data/config/event/5300027.json |

| 5300028 | 还书 | false | false | round_begin_ba | 1 | data/config/event/5300028.json |

| 5300029 | 书店营业 | false | true | round_begin_ba | 1 | data/config/event/5300029.json |

| 5300030 | 书店营业 |  | false | round_begin_ba | 1 | data/config/event/5300030.json |

| 5300031 | 不羁骏马 | false | false | round_begin_ba | 1 | data/config/event/5300031.json |

| 5300032 | 袭杀山狮 | false | false | round_begin_ba | 1 | data/config/event/5300032.json |

| 5300033 | 商人的遗物 | false | false | round_begin_ba | 1 | data/config/event/5300033.json |

| 5300034 | 山狮肆虐 | false | false | round_begin_ba | 1 | data/config/event/5300034.json |

| 5300035 | 装备商人 | false | true | round_begin_ba | 1 | data/config/event/5300035.json |

| 5300036 | 服装商人 | false | true | round_begin_ba | 1 | data/config/event/5300036.json |

| 5300037 | 饰品商人 | false | true | round_begin_ba | 1 | data/config/event/5300037.json |

| 5300038 | 神秘商人 | false | false | round_begin_ba | 1 | data/config/event/5300038.json |

| 5300039 | 奇淫巧技-鞭子 |  | false | round_begin_ba | 1 | data/config/event/5300039.json |

| 5300040 | 奇淫巧技-窒息 | false | false | round_begin_ba | 1 | data/config/event/5300040.json |

| 5300041 | 奇淫巧技-银趴 | false | false | round_begin_ba | 1 | data/config/event/5300041.json |

| 5300042 | 奇淫巧技-苏丹的欢愉 | false | false | round_begin_ba | 1 | data/config/event/5300042.json |

| 5300043 | 恶名正在发酵 | false | false | round_begin_ba | 1 | data/config/event/5300043.json |

| 5300044 | 刺杀 | false | true | round_begin_ba | 1 | data/config/event/5300044.json |

| 5300045 | 妃子A来访 | false | false | round_begin_ba | 1 | data/config/event/5300045.json |

| 5300046 | 索要物资I | false | false | round_begin_ba | 1 | data/config/event/5300046.json |

| 5300047 | 索要物资2 | false | false | round_begin_ba | 1 | data/config/event/5300047.json |

| 5300048 | 索要物资3 | false | false | round_begin_ba | 1 | data/config/event/5300048.json |

| 5300049 | 偷戒指 | false | false | round_begin_ba | 1 | data/config/event/5300049.json |

| 5300050 | 东窗事发 | false | false | card_clean | 1 | data/config/event/5300050.json |

| 5300051 | 弑君 | false | false | round_begin_ba | 1 | data/config/event/5300051.json |

| 5300052 | 妃子B来访 | false | true | round_begin_ba | 1 | data/config/event/5300052.json |

| 5300053 | 脱罪 | false | true | round_begin_ba | 1 | data/config/event/5300053.json |

| 5300054 | 暗杀1 | false | true | round_begin_ba | 1 | data/config/event/5300054.json |

| 5300055 | 妃子B的请求 | false | true | round_begin_ba | 1 | data/config/event/5300055.json |

| 5300056 | 暗杀2 | false | true | round_begin_ba | 1 | data/config/event/5300056.json |

| 5300057 | 合作 | false | true | round_begin_ba | 1 | data/config/event/5300057.json |

| 5300058 | 暗杀3 | false | false | round_begin_ba | 1 | data/config/event/5300058.json |

| 5300059 | 真正的报偿 | false | false | round_begin_ba | 1 | data/config/event/5300059.json |

| 5300060 | 暗杀4 | false | false | round_begin_ba | 1 | data/config/event/5300060.json |

| 5300061 | 貌合神离 | false | false | round_begin_ba | 1 | data/config/event/5300061.json |

| 5300062 | 背叛（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300062.json |

| 5300063 | 失去 | false | false | round_begin_ba | 1 | data/config/event/5300063.json |

| 5300064 | 选择如何处理禁卫队长 | false | false | rite_end | 1 | data/config/event/5300064.json |

| 5300065 | 说服禁卫队长 | false | false | round_begin_ba | 1 | data/config/event/5300065.json |

| 5300066 | 生成治理家业 | false | true | round_begin_ba | 1 | data/config/event/5300066.json |

| 5300067 | 是否有君王的胸襟 | false | true | round_begin_ba | 1 | data/config/event/5300067.json |

| 5300068 | 没有乳链子 | false | true | round_begin_ba | 1 | data/config/event/5300068.json |

| 5300072 | 激活蒸汽社交（测试） | false | true | round_begin_ba | 1 | data/config/event/5300072.json |

| 5300073 | 激活医院 |  | true | round_begin_ba | 1 | data/config/event/5300073.json |

| 5300074 | 黑街居民 | false | false | round_begin_ba | 1 | data/config/event/5300074.json |

| 5300075 | 捉贼人的调查 | false | false | round_begin_ba | 1 | data/config/event/5300075.json |

| 5300076 | 扒手团体（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300076.json |

| 5300077 | 探访黑街 | false | true | round_begin_ba | 1 | data/config/event/5300077.json |

| 5300078 | 狼王的踪迹 | false | true | round_begin_ba | 1 | data/config/event/5300078.json |

| 5300079 | 狼穴恶战 | false | true | round_begin_ba | 1 | data/config/event/5300079.json |

| 5300080 | 下水道的鳄鱼 | false | true | round_begin_ba | 1 | data/config/event/5300080.json |

| 5300081 | 毒蛇山谷 | false | true | round_begin_ba | 1 | data/config/event/5300081.json |

| 5300082 | 恐吓计划（测试用） |  | false | round_begin_ba | 1 | data/config/event/5300082.json |

| 5300083 | 组织犯罪 | false | false | round_begin_ba | 1 | data/config/event/5300083.json |

| 5300084 | 盗窃计划（测试用） |  | false | round_begin_ba | 1 | data/config/event/5300084.json |

| 5300085 | 探访监狱 | false | true | round_begin_ba | 1 | data/config/event/5300085.json |

| 5300086 | 搜寻提尔亚遗物 |  | false | round_begin_ba | 1 | data/config/event/5300086.json |

| 5300087 | 房屋出租 | false | true | round_begin_ba | 1 | data/config/event/5300087.json |

| 5300088 | 异国商人 | false | true | round_begin_ba | 1 | data/config/event/5300088.json |

| 5300089 | 权力的游戏 | false | false | rite_end | 1 | data/config/event/5300089.json |

| 5300090 | 浴场移除提示 |  | false | round_begin_ba | 1 | data/config/event/5300090.json |

| 5300091 | 权力的游戏开启提示 |  | false | round_begin_ba | 1 | data/config/event/5300091.json |

| 5300092 | 赌马 |  | false | round_begin_ba | 1 | data/config/event/5300092.json |

| 5300093 | 挂毯长廊每回合随机掉情报 | false | false | round_begin_ba | 1 | data/config/event/5300093.json |

| 5300094 | 鳄鱼池每回合随机金币 | false | false | round_begin_ba | 1 | data/config/event/5300094.json |

| 5300095 | 激活约会相关的仪式 |  | false | round_begin_ba | 1 | data/config/event/5300095.json |

| 5300096 | 根据度过的回合计数 |  | true | round_begin_ba | 1 | data/config/event/5300096.json |

| 5300097 | 第3天生成妓院 |  | false | round_begin_ba | 1 | data/config/event/5300097.json |

| 5300098 | 第5天生成商人 |  | false | round_begin_ba | 1 | data/config/event/5300098.json |

| 5300099 | 第8天生成黑街 | false | false | round_begin_ba | 1 | data/config/event/5300099.json |

| 5300100 | 城外的骚乱 |  | false | round_begin_ba | 1 | data/config/event/5300100.json |

| 5300101 | 酒庄主人造访 | false | false | round_begin_ba | 1 | data/config/event/5300101.json |

| 5300102 | 邀请寡妇 | false | false | rite_end | 1 | data/config/event/5300102.json |

| 5300103 | 刺杀 | false | false | round_begin_ba | 1 | data/config/event/5300103.json |

| 5300104 | 弑兄 | false | false | round_begin_ba | 1 | data/config/event/5300104.json |

| 5300105 | 造访2 | false | false | round_begin_ba | 1 | data/config/event/5300105.json |

| 5300106 | 刺杀 | false | false | round_begin_ba | 1 | data/config/event/5300106.json |

| 5300107 | 绑架年轻望族 | false | false | round_begin_ba | 1 | data/config/event/5300107.json |

| 5300108 | 年轻望族的请求 | false | false | round_begin_ba | 1 | data/config/event/5300108.json |

| 5300109 | 年轻望族的请求II | false | false | round_begin_ba | 1 | data/config/event/5300109.json |

| 5300110 | 年轻望族的请求III | false | false | round_begin_ba | 1 | data/config/event/5300110.json |

| 5300111 | 寡妇登门 | false | false | round_begin_ba | 1 | data/config/event/5300111.json |

| 5300112 | 探访奈费勒 | false | false | round_begin_ba | 1 | data/config/event/5300112.json |

| 5300113 | 贵妇的邀请 |  | false | card_clean | 1 | data/config/event/5300113.json |

| 5300114 | 贵妇的邀请（113的补充） | false | false | round_begin_ba | 1 | data/config/event/5300114.json |

| 5300115 | 贵妇杀戮 | false | false | round_begin_ba | 1 | data/config/event/5300115.json |

| 5300116 | 贵妇奢靡 | false | false | round_begin_ba | 1 | data/config/event/5300116.json |

| 5300117 | 收服贵妇 | false | true | round_begin_ba | 1 | data/config/event/5300117.json |

| 5300118 | 贵妇杀夫 | false | false | round_begin_ba | 1 | data/config/event/5300118.json |

| 5300119 | 受伤的白犀牛 |  | false | round_begin_ba | 1 | data/config/event/5300119.json |

| 5300120 | 女战士的战书 | false | false | round_begin_ba | 1 | data/config/event/5300120.json |

| 5300121 | 王狮猎场 | false | false | round_begin_ba | 1 | data/config/event/5300121.json |

| 5300122 | 处置女战士 | false | false | round_begin_ba | 1 | data/config/event/5300122.json |

| 5300123 | 被羞辱的少女 |  | false | round_begin_ba | 1 | data/config/event/5300123.json |

| 5300124 | 少女审视自己 | false | false | round_begin_ba | 1 | data/config/event/5300124.json |

| 5300125 | 少女审视自己2 | false | false | round_begin_ba | 1 | data/config/event/5300125.json |

| 5300126 | 勇行 | false | false | round_begin_ba | 1 | data/config/event/5300126.json |

| 5300127 | 贵妇的邀请的提示 | false | false | round_begin_ba | 1 | data/config/event/5300127.json |

| 5300128 | 贵妇被无视的提示 |  | false | round_begin_ba | 1 | data/config/event/5300128.json |

| 5300129 | 女战士的挑战 | false | true | round_begin_ba | 1 | data/config/event/5300129.json |

| 5300130 | 开启贵族囚牢 | false | true | round_begin_ba | 1 | data/config/event/5300130.json |

| 5300131 | 开启黑街线人 | false | true | round_begin_ba | 1 | data/config/event/5300131.json |

| 5300132 | 无罪释放 | false | true | round_begin_ba | 1 | data/config/event/5300132.json |

| 5300133 | 无名的暗杀 | false | false | round_begin_ba | 1 | data/config/event/5300133.json |

| 5300134 | 胖贵族来访 | false | false | round_begin_ba | 1 | data/config/event/5300134.json |

| 5300142 | 脱罪的希望 |  | false | rite_end | 1 | data/config/event/5300142.json |

| 5300144 | 年轻望族的请求 | false | false | rite_end | 1 | data/config/event/5300144.json |

| 5300145 | 年轻望族的请求II | false | false | rite_end | 1 | data/config/event/5300145.json |

| 5300146 | 年轻望族的请求3 | false | false | rite_end | 1 | data/config/event/5300146.json |

| 5300147 | 赞助请求 |  | false | round_begin_ba | 1 | data/config/event/5300147.json |

| 5300148 | 赞助请求 | false | false | round_begin_ba | 1 | data/config/event/5300148.json |

| 5300149 | 用来重新激活-赞助请求的幕后机制 | false | false | round_begin_ba | 1 | data/config/event/5300149.json |

| 5300150 | 暗潮涌动 | false | false | round_begin_ba | 1 | data/config/event/5300150.json |

| 5300151 | 暗潮涌动--征服卡结局 | false | false | rite_end | 1 | data/config/event/5300151.json |

| 5300152 | 暗潮涌动--征服卡结局2 | false | true | round_begin_ba | 1 | data/config/event/5300152.json |

| 5300153 | 绝地探索 | false | false | round_begin_ba | 1 | data/config/event/5300153.json |

| 5300154 | 暗潮涌动2 | false | false | round_begin_ba | 1 | data/config/event/5300154.json |

| 5300155 | 麦娜尔的道别 | false | false | round_begin_ba | 1 | data/config/event/5300155.json |

| 5300156 | 远方的乐土 | false | false | round_begin_ba | 1 | data/config/event/5300156.json |

| 5300157 | 开启弑君计划 | false | false | rite_end | 1 | data/config/event/5300157.json |

| 5300158 | 远来的质子 |  | false | rite_end | 1 | data/config/event/5300158.json |

| 5300159 | 附属领地的难题 |  | false | rite_end | 1 | data/config/event/5300159.json |

| 5300160 | 质子的请求 |  | false | rite_end | 1 | data/config/event/5300160.json |

| 5300161 | 税务官的请求 | false | false | round_begin_ba | 1 | data/config/event/5300161.json |

| 5300162 | 邪恶祭祀 | false | false | round_begin_ba | 1 | data/config/event/5300162.json |

| 5300163 | 质子的请求 |  | false | rite_end | 1 | data/config/event/5300163.json |

| 5300164 | 质子的请求 | false | false | round_begin_ba | 1 | data/config/event/5300164.json |

| 5300165 | 税务官的请求2 | false | false | round_begin_ba | 1 | data/config/event/5300165.json |

| 5300166 | 税务官的请求3 | false | false | round_begin_ba | 1 | data/config/event/5300166.json |

| 5300167 | 善行计数结算 | false | false | rite_end | 1 | data/config/event/5300167.json |

| 5300168 | 善行计数结算 | false | false | rite_end | 1 | data/config/event/5300168.json |

| 5300169 | 生成部队 | false | false | rite_end | 1 | data/config/event/5300169.json |

| 5300170 | 暗潮涌动2--征服卡结局 | false | false | rite_end | 1 | data/config/event/5300170.json |

| 5300171 | 暗潮涌动2--征服卡结局 | false | true | round_begin_ba | 1 | data/config/event/5300171.json |

| 5300172 | 邪恶祭祀（无质子） | false | false | round_begin_ba | 1 | data/config/event/5300172.json |

| 5300173 | 刺杀 | false | false | round_begin_ba | 1 | data/config/event/5300173.json |

| 5300174 | 激活放迷药仪式 | false | false | round_begin_ba | 1 | data/config/event/5300174.json |

| 5300175 | 淘书仪式 | false | true | round_begin_ba | 1 | data/config/event/5300175.json |

| 5300176 | 这不是偷 | false | false | rite_end | 1 | data/config/event/5300176.json |

| 5300177 | 你礼貌吗？ | false | false | rite_end | 1 | data/config/event/5300177.json |

| 5300178 | 先到先得 | false | false | rite_end | 1 | data/config/event/5300178.json |

| 5300179 | 淘书仪式 | false | false | round_begin_ba | 1 | data/config/event/5300179.json |

| 5300180 | 浴场约会-2 | false | true | round_begin_ba | 1 | data/config/event/5300180.json |

| 5300181 | 书店约会 | false | true | round_begin_ba | 1 | data/config/event/5300181.json |

| 5300182 | 妻子正在酝酿不满 | false | false | round_begin_ba | 1 | data/config/event/5300182.json |

| 5300183 | 浴场小鳄鱼事件 | false | false | rite_end | 1 | data/config/event/5300183.json |

| 5300184 | 浴场小鳄鱼事件2 | false | false | rite_end | 1 | data/config/event/5300184.json |

| 5300201 | 监听使用征服卡（再利用） |  | false | card_clean | 1 | data/config/event/5300201.json |

| 5300202 | 无尽黄沙 | false | false | round_begin_ba | 1 | data/config/event/5300202.json |

| 5300203 | 狂风峡谷 | false | false | round_begin_ba | 1 | data/config/event/5300203.json |

| 5300204 | 暗影神庙 | false | false | round_begin_ba | 1 | data/config/event/5300204.json |

| 5300205 | 女妖森林 | false | false | round_begin_ba | 1 | data/config/event/5300205.json |

| 5300206 | 将军的收服 | false | false | round_begin_ba | 1 | data/config/event/5300206.json |

| 5300207 | 火山魔龙 | false | false | round_begin_ba | 1 | data/config/event/5300207.json |

| 5300208 | 奈布哈尼准备挑战你 | false | false | round_begin_ba | 1 | data/config/event/5300208.json |

| 5300209 | 足以传世的画像（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300209.json |

| 5300210 | 仅仅只是有趣而已 | false | false | round_begin_ba | 1 | data/config/event/5300210.json |

| 5300211 | 不可靠的盟友 | false | false | rite_end | 1 | data/config/event/5300211.json |

| 5300212 | 不可靠的盟友延迟一回合 | false | false | round_begin_ba | 1 | data/config/event/5300212.json |

| 5300213 | 花花公子的收服（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300213.json |

| 5300214 | 废弃 | false | false | round_begin_ba | 1 | data/config/event/5300214.json |

| 5300215 | 废弃 | false | false | round_begin_ba | 1 | data/config/event/5300215.json |

| 5300216 | 废弃 | false | false | round_begin_ba | 1 | data/config/event/5300216.json |

| 5300217 | 废弃 | false | false | round_begin_ba | 1 | data/config/event/5300217.json |

| 5300218 | 废弃 | false | false | round_begin_ba | 1 | data/config/event/5300218.json |

| 5300219 | 不可靠的盟友初次触发延后三回合 | false | false | round_begin_ba | 1 | data/config/event/5300219.json |

| 5300220 | 第5天生成纵欲苏丹卡仪式 | false | false | round_begin_ba | 1 | data/config/event/5300220.json |

| 5300221 | 常规纵欲苏丹卡 | false | false | round_begin_ba | 1 | data/config/event/5300221.json |

| 5300222 | 常规奢靡苏丹卡 | false | false | round_begin_ba | 1 | data/config/event/5300222.json |

| 5300223 | 常规杀戮苏丹卡 | false | false | round_begin_ba | 1 | data/config/event/5300223.json |

| 5300224 | 常规征服苏丹卡 | false | false | round_begin_ba | 1 | data/config/event/5300224.json |

| 5300225 | 常规数值检定仪式随机生成幕后 | false | false | round_begin_ba | 1 | data/config/event/5300225.json |

| 5300226 | 第5天生成奢靡苏丹卡仪式 | false | false | round_begin_ba | 1 | data/config/event/5300226.json |

| 5300227 | 第5天生成杀戮苏丹卡仪式 | false | false | round_begin_ba | 1 | data/config/event/5300227.json |

| 5300228 | 第5天生成征服苏丹卡仪式 | false | false | round_begin_ba | 1 | data/config/event/5300228.json |

| 5300229 | 生成宰相的召见-初次 |  | false | round_begin_ba | 1 | data/config/event/5300229.json |

| 5300230 | 生成宰相的召见-二 | false | false | round_begin_ba | 1 | data/config/event/5300230.json |

| 5300231 | 如何处置 | false | false | rite_end | 1 | data/config/event/5300231.json |

| 5300232 | 生成宰相的召见-随机 | false | false | round_begin_ba | 1 | data/config/event/5300232.json |

| 5300233 | 散尽家财 | false | false | rite_end | 1 | data/config/event/5300233.json |

| 5300234 | 散尽家财下回合启动 | false | false | round_begin_ba | 1 | data/config/event/5300234.json |

| 5300235 | 资助研究·一 |  | false | round_begin_ba | 1 | data/config/event/5300235.json |

| 5300236 | 资助研究·二 | false | false | round_begin_ba | 1 | data/config/event/5300236.json |

| 5300237 | 女工匠来访 | false | false | round_begin_ba | 1 | data/config/event/5300237.json |

| 5300238 | 逃离 |  | false | card_clean | 1 | data/config/event/5300238.json |

| 5300239 | 接受逃离 | false | true | rite_end | 1 | data/config/event/5300239.json |

| 5300240 | 拒绝逃离 | false | true |  | 1 | data/config/event/5300240.json |

| 5300241 | 珍奇之家 | false | false | round_begin_ba | 1 | data/config/event/5300241.json |

| 5300242 | 政敌初见（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300242.json |

| 5300243 | 获得献祭仪式图纸 |  | false | round_begin_ba | 1 | data/config/event/5300243.json |

| 5300244 | 获取召唤邪物图纸 |  | false | round_begin_ba | 1 | data/config/event/5300244.json |

| 5300245 | 获得附魔仪式的幕后 | false | false | round_begin_ba | 1 | data/config/event/5300245.json |

| 5300246 | 获得禁忌的古书的幕后（废弃，获取方法另做） | false | false | round_begin_ba | 1 | data/config/event/5300246.json |

| 5300247 | 获得神秘的锅的幕后（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300247.json |

| 5300248 | 征服欲 |  | false | round_begin_ba | 1 | data/config/event/5300248.json |

| 5300249 | 逃离 |  | false | round_begin_ba | 1 | data/config/event/5300249.json |

| 5300250 | 获得禁忌的古书的幕后（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300250.json |

| 5300251 | 萨达尔尼加支持的幕后 | false | false | round_begin_ba | 1 | data/config/event/5300251.json |

| 5300252 | 萨达尔尼加反对的幕后 | false | false | round_begin_ba | 1 | data/config/event/5300252.json |

| 5300253 | 7天后再开启不可靠的盟友 | false | false | round_begin_ba | 1 | data/config/event/5300253.json |

| 5300254 | 法律的底线的第一次开启 |  | false | round_begin_ba | 1 | data/config/event/5300254.json |

| 5300255 | 法律的底线的重复开启 | false | false | round_begin_ba | 1 | data/config/event/5300255.json |

| 5300256 | 艾迪勒受伤养伤 | false | false | round_begin_ba | 1 | data/config/event/5300256.json |

| 5300257 | 论罪与辩护 | false | false | round_begin_ba | 1 | data/config/event/5300257.json |

| 5300258 | 审判 | false | false | round_begin_ba | 1 | data/config/event/5300258.json |

| 5300259 | 调查施加压力归0 | false | false | round_begin_ba | 1 | data/config/event/5300259.json |

| 5300260 | 监听妻子死亡的幕后 |  | false | card_clean | 1 | data/config/event/5300260.json |

| 5300261 | 脱罪 | false | true | round_begin_ba | 1 | data/config/event/5300261.json |

| 5300262 | 处置凶兽头颅 | false | true | round_begin_ba | 1 | data/config/event/5300262.json |

| 5300263 | 苏丹奔赴猎场 | false | true | round_begin_ba | 1 | data/config/event/5300263.json |

| 5300264 | 认识异国商人 | false | true | round_begin_ba | 1 | data/config/event/5300264.json |

| 5300265 | 不认识异国商人 | false | true | round_begin_ba | 1 | data/config/event/5300265.json |

| 5300266 | 意料之中的买家 | false | false | round_begin_ba | 1 | data/config/event/5300266.json |

| 5300267 | 黑街的邀约 |  | false | round_begin_ba | 1 | data/config/event/5300267.json |

| 5300268 | 再一次拳斗 | false | false | round_begin_ba | 1 | data/config/event/5300268.json |

| 5300269 | 利用 | false | true | round_begin_ba | 1 | data/config/event/5300269.json |

| 5300270 | 处理拳斗士的证明 | false | false | round_begin_ba | 1 | data/config/event/5300270.json |

| 5300271 | 哲巴尔决斗的开启 | false | false | round_begin_ba | 1 | data/config/event/5300271.json |

| 5300272 | 被偏爱的与被冷落的 | false | false | rite_end | 1 | data/config/event/5300272.json |

| 5300273 | 肉体展览 | false | true | rite_end | 1 | data/config/event/5300273.json |

| 5300274 | 燃烧的奴隶市场 |  | false | round_begin_ba | 1 | data/config/event/5300274.json |

| 5300275 | 浪子的思绪 | false | false | rite_end | 1 | data/config/event/5300275.json |

| 5300276 | 柔弱的女奴 | false | true | rite_end | 1 | data/config/event/5300276.json |

| 5300277 | 辣个女人 | false | false | rite_end | 1 | data/config/event/5300277.json |

| 5300278 | 如此大恩 | false | false | rite_end | 1 | data/config/event/5300278.json |

| 5300279 | 浪子的思绪 | false | false | rite_end | 1 | data/config/event/5300279.json |

| 5300280 | 我不如她吗 | false | false | round_begin_ba | 1 | data/config/event/5300280.json |

| 5300281 | 不是故意的 | false | false | round_begin_ba | 1 | data/config/event/5300281.json |

| 5300282 | 奢侈的欢欣 | false | false | round_begin_ba | 1 | data/config/event/5300282.json |

| 5300283 | 久违的清静 | false | false | card_clean | 1 | data/config/event/5300283.json |

| 5300284 | 久违的清静 | false | false | round_begin_ba | 1 | data/config/event/5300284.json |

| 5300285 | 未被满足的渴求 | false | false | round_begin_ba | 1 | data/config/event/5300285.json |

| 5300286 | 欢愉之馆的新人 | false | false | round_begin_ba | 1 | data/config/event/5300286.json |

| 5300287 | 如此大恩2 | false | false | rite_end | 1 | data/config/event/5300287.json |

| 5300288 | 奈布哈尼的耻笑 | false | true | round_begin_ba | 1 | data/config/event/5300288.json |

| 5300289 | 微小的麻烦前置 | false | false | rite_end | 1 | data/config/event/5300289.json |

| 5300290 | 更多的细纱 | false | false | round_begin_ba | 1 | data/config/event/5300290.json |

| 5300291 | 工匠街区的意外 | false | false | round_begin_ba | 1 | data/config/event/5300291.json |

| 5300292 | 苏丹的游戏 | false | true | round_begin_ba | 1 | data/config/event/5300292.json |

| 5300293 | 一个提议 | false | true | rite_end | 1 | data/config/event/5300293.json |

| 5300294 | 友情提示 | false | true | rite_end | 1 | data/config/event/5300294.json |

| 5300295 | 游戏的准备 | false | true | round_begin_ba | 1 | data/config/event/5300295.json |

| 5300296 | 你的游戏前置 | false | false | round_begin_ba | 1 | data/config/event/5300296.json |

| 5300297 | 出让钥匙 | false | false | round_begin_ba | 1 | data/config/event/5300297.json |

| 5300298 | 你的游戏pro前置 | false | false | round_begin_ba | 1 | data/config/event/5300298.json |

| 5300299 | 妓女的游戏前置 | false | true | round_begin_ba | 1 | data/config/event/5300299.json |

| 5300300 | PPT式新手引导测试 | false | true | round_begin_ba | 1 | data/config/event/5300300.json |

| 5300301 | PPT式新手引导测试2 | false | false | open_rite | 1 | data/config/event/5300301.json |

| 5300302 | PPT式新手引导测试2 | false | false | close_prompt | 1 | data/config/event/5300302.json |

| 5300303 | PPT式新手引导测试2 | false | false | open_card_info | 1 | data/config/event/5300303.json |

| 5300304 | 石妓女赎身 | false | false | round_begin_ba | 1 | data/config/event/5300304.json |

| 5300305 | 畸恋 | false | false | round_begin_ba | 1 | data/config/event/5300305.json |

| 5300306 | 铜妓女处理尸体 | false | false | round_begin_ba | 1 | data/config/event/5300306.json |

| 5300307 | 决斗 | false | false | rite_end | 1 | data/config/event/5300307.json |

| 5300308 | 贾丽拉成为盟友 | false | false | round_begin_ba | 1 | data/config/event/5300308.json |

| 5300309 | 贾丽拉被处死的消息 | false | false | round_begin_ba | 1 | data/config/event/5300309.json |

| 5300310 | 女王的朋友 | false | false | round_begin_ba | 1 | data/config/event/5300310.json |

| 5300311 | 父亲的刺客 |  | false | round_begin_ba | 1 | data/config/event/5300311.json |

| 5300312 | 孤注一掷 | false | true | round_begin_ba | 1 | data/config/event/5300312.json |

| 5300313 | 葬礼 | false | false | round_begin_ba | 1 | data/config/event/5300313.json |

| 5300314 | 纳妾 | false | true | round_begin_ba | 1 | data/config/event/5300314.json |

| 5300315 | 逆子之死 | false | false | round_begin_ba | 1 | data/config/event/5300315.json |

| 5300316 | 继承人推荐 | false | true | round_begin_ba | 1 | data/config/event/5300316.json |

| 5300317 | 升华 | false | true | round_begin_ba | 1 | data/config/event/5300317.json |

| 5300318 | 治理领地（废弃） | false | false | round_begin_ba | 1 | data/config/event/5300318.json |

| 5300319 | 探访监狱(首次) |  | false | round_begin_ba | 1 | data/config/event/5300319.json |

| 5300320 | 和野狗对决 | false | true | round_begin_ba | 1 | data/config/event/5300320.json |

| 5300321 | 和囚犯对决 | false | true | round_begin_ba | 1 | data/config/event/5300321.json |

| 5300322 | 和狮子对决 | false | true | round_begin_ba | 1 | data/config/event/5300322.json |

| 5300323 | 和巨人对决 | false | true | round_begin_ba | 1 | data/config/event/5300323.json |

| 5300324 | 升级舞姬 |  | false | round_begin_ba | 1 | data/config/event/5300324.json |

| 5300325 | 升级舞姬2 | false | false | round_begin_ba | 1 | data/config/event/5300325.json |

| 5300326 | 和舞姬密会 | false | false | round_begin_ba | 1 | data/config/event/5300326.json |

| 5300327 | 虐待致死 | false | false | round_begin_ba | 1 | data/config/event/5300327.json |

| 5300328 | 虐待致死-重试 | false | false | round_begin_ba | 1 | data/config/event/5300328.json |

| 5300329 | 与舞姬密会-重试 | false | false | round_begin_ba | 1 | data/config/event/5300329.json |

| 5300330 | 和舞姬密会-常例 | false | false | round_begin_ba | 1 | data/config/event/5300330.json |

| 5300331 | 与舞姬密会-常例-重试 | false | false | round_begin_ba | 1 | data/config/event/5300331.json |

| 5300332 | 出逃被追回的提示 | false | false | round_begin_ba | 1 | data/config/event/5300332.json |

| 5300333 | 舞姬偷戒指事发 | false | false | round_begin_ba | 1 | data/config/event/5300333.json |

| 5300334 | 舞姬偷戒指事发-重试 | false | false | round_begin_ba | 1 | data/config/event/5300334.json |

| 5300335 | 赃物商人 |  | false | round_begin_ba | 1 | data/config/event/5300335.json |

| 5300336 | 记录玩家是否有战斗力超过4的人 |  | false | round_begin_ba | 1 | data/config/event/5300336.json |

| 5300337 | 书店不营业了 |  | false | round_begin_ba | 1 | data/config/event/5300337.json |

| 5300338 | 首次抽到苏丹卡的提示 |  | false | round_begin_ba | 1 | data/config/event/5300338.json |

| 5300339 | 首次抽到苏丹卡的提示 |  | false | round_begin_ba | 1 | data/config/event/5300339.json |

| 5300340 | 首次抽到苏丹卡的提示 |  | false | round_begin_ba | 1 | data/config/event/5300340.json |

| 5300341 | 正直官员的回馈 | false | false | round_begin_ba | 1 | data/config/event/5300341.json |

| 5300342 | 正直官员的回馈 | false | false | round_begin_ba | 1 | data/config/event/5300342.json |

| 5300343 | 诉冤的女人 | false | false | round_begin_ba | 1 | data/config/event/5300343.json |

| 5300344 | 初步调查 | false | true | round_begin_ba | 1 | data/config/event/5300344.json |

| 5300345 | 深入调查 | false | true | round_begin_ba | 1 | data/config/event/5300345.json |

| 5300346 | 收服正直的官员 | false | false | round_begin_ba | 1 | data/config/event/5300346.json |

| 5300347 | 诉冤的女人2 | false | false | round_begin_ba | 1 | data/config/event/5300347.json |

| 5300348 | 诉冤的女人3 | false | false | round_begin_ba | 1 | data/config/event/5300348.json |

| 5300349 | 倒霉鬼 | false | false | round_begin_ba | 1 | data/config/event/5300349.json |

| 5300350 | 同日死去 | false | false | round_begin_ba | 1 | data/config/event/5300350.json |

| 5300351 | 是我做的 | false | false | round_begin_ba | 1 | data/config/event/5300351.json |

| 5300352 | 算你识相 | false | false | round_begin_ba | 1 | data/config/event/5300352.json |

| 5300353 | 等待 | false | true | round_begin_ba | 1 | data/config/event/5300353.json |

| 5300354 | 偷取苏丹的戒指 | false | false | round_begin_ba | 1 | data/config/event/5300354.json |

| 5300355 | 激活神殿（废弃） | false | true | round_begin_ba | 1 | data/config/event/5300355.json |

| 5300356 | 权力的游戏 | false | true | round_begin_ba | 1 | data/config/event/5300356.json |

| 5300357 | 群龙无首和权力游戏的保险机制 |  | false | round_begin_ba | 1 | data/config/event/5300357.json |

| 5300501 | 偷盗的仆人 | false | true | round_begin_ba | 1 | data/config/event/5300501.json |

| 5300502 | 欠钱的朋友 | false | true | round_begin_ba | 1 | data/config/event/5300502.json |

| 5300503 | 打老婆的邻居 | false | true | round_begin_ba | 1 | data/config/event/5300503.json |

| 5300504 | 贼人之手 | false | true | round_begin_ba | 1 | data/config/event/5300504.json |

| 5300505 | 读书人 | false | true | round_begin_ba | 1 | data/config/event/5300505.json |

| 5300506 | 祖传的…… | false | true | round_begin_ba | 1 | data/config/event/5300506.json |

| 5300507 | 妻子的梦 | false | true | round_begin_ba | 1 | data/config/event/5300507.json |

| 5300508 | 以神之名 | false | true | round_begin_ba | 1 | data/config/event/5300508.json |

| 5300509 | 躲雨的人 | false | true | round_begin_ba | 1 | data/config/event/5300509.json |

| 5300510 | 行脚僧 | false | true | round_begin_ba | 1 | data/config/event/5300510.json |

| 5300511 | 喝醉的同僚 | false | true | round_begin_ba | 1 | data/config/event/5300511.json |

| 5300512 | 商队投资 | false | true | round_begin_ba | 1 | data/config/event/5300512.json |

| 5300513 | 午夜美人 | false | true | round_begin_ba | 1 | data/config/event/5300513.json |

| 5300514 | 神秘的符号 | false | true | round_begin_ba | 1 | data/config/event/5300514.json |

| 5300515 | 骗子登门 | false | true | round_begin_ba | 1 | data/config/event/5300515.json |

| 5300516 | 邻居投诉 | false | true | round_begin_ba | 1 | data/config/event/5300516.json |

| 5300517 | 邻居著作 | false | false | round_begin_ba | 1 | data/config/event/5300517.json |

| 5300518 | 苏丹的金苹果 | false | true | round_begin_ba | 1 | data/config/event/5300518.json |

| 5300519 | 贸易路线 | false | true | round_begin_ba | 1 | data/config/event/5300519.json |

| 5300520 | 吉兆 | false | true | round_begin_ba | 1 | data/config/event/5300520.json |

| 5300521 | 两个丈夫 | false | true | round_begin_ba | 1 | data/config/event/5300521.json |

| 5300522 | 奇异的机械 | false | true | round_begin_ba | 1 | data/config/event/5300522.json |

| 5300523 | 不敬之书 | false | true | round_begin_ba | 1 | data/config/event/5300523.json |

| 5300524 | 河流的方向 | false | true | round_begin_ba | 1 | data/config/event/5300524.json |

| 5300525 | 苏丹的梦 | false | true | round_begin_ba | 1 | data/config/event/5300525.json |

| 5300526 | 苦水 | false | true | round_begin_ba | 1 | data/config/event/5300526.json |

| 5300527 | 浪子的悲哀前置 | false | false | round_begin_ba | 1 | data/config/event/5300527.json |

| 5300528 | 痴心妄想 | false | true | rite_end | 1 | data/config/event/5300528.json |

| 5300529 | 友情提示（废弃） | false | true | rite_end | 1 | data/config/event/5300529.json |

| 5300530 | 出让钥匙 | false | false | round_begin_ba | 1 | data/config/event/5300530.json |

| 5300531 | 妓女的游戏前置 | false | true | round_begin_ba | 1 | data/config/event/5300531.json |

| 5300532 | 妻子远行的前置 | false | false | round_begin_ba | 1 | data/config/event/5300532.json |

| 5300533 | 想开妓女的游戏但大伙都不在了 | false | true | round_begin_ba | 1 | data/config/event/5300533.json |

| 5300534 | 想开妓女的游戏但大伙都被赎身了 | false | true | round_begin_ba | 1 | data/config/event/5300534.json |

| 5300535 | 妓女的游戏开起不来的其它状况 | false | true | round_begin_ba | 1 | data/config/event/5300535.json |

| 5300536 | 监听奈布哈尼追随者tag，移除时关闭不可靠的盟友系列 | false | false | round_begin_ba | 1 | data/config/event/5300536.json |

| 5300537 | 银趴前提示语 | false | true | rite_end | 1 | data/config/event/5300537.json |

| 5300538 | 深夜访客 | false | false | round_begin_ba | 1 | data/config/event/5300538.json |

| 5300539 | 帮派斗争 | false | false | round_begin_ba | 1 | data/config/event/5300539.json |

| 5300540 | 追击豺狼帮 | false | false | round_begin_ba | 1 | data/config/event/5300540.json |

| 5300541 | 吃掉他的肝脏 | false | false | round_begin_ba | 1 | data/config/event/5300541.json |

| 5300542 | 我要去妓院2！ | false | false | round_begin_ba | 1 | data/config/event/5300542.json |

| 5300543 | 枪姬众 | false | false | round_begin_ba | 1 | data/config/event/5300543.json |

| 5300544 | 我白嫖前置 | false | false | round_begin_ba | 1 | data/config/event/5300544.json |

| 5300545 | 追查猎奴人 | false | false | round_begin_ba | 1 | data/config/event/5300545.json |

| 5300546 | 审问猎奴人 | false | false | round_begin_ba | 1 | data/config/event/5300546.json |

| 5300547 | 处置猎奴人 | false | false | round_begin_ba | 1 | data/config/event/5300547.json |

| 5300548 | 微妙的感谢 | false | false | round_begin_ba | 1 | data/config/event/5300548.json |

| 5300549 | 宰相的罪证后续 |  | false | round_begin_ba | 1 | data/config/event/5300549.json |

| 5300550 | 奴隶暴动 | false | false | round_begin_ba | 1 | data/config/event/5300550.json |

| 5300551 | 宰相之死 | false | false | round_begin_ba | 1 | data/config/event/5300551.json |

| 5300552 | 族长的祝福 | false | false | round_begin_ba | 1 | data/config/event/5300552.json |

| 5300553 | 芮尔的匪帮助阵 | false | false | round_begin_ba | 1 | data/config/event/5300553.json |

| 5300554 | 我叫小薇 | false | true | round_begin_ba | 1 | data/config/event/5300554.json |

| 5300555 | 小安留下了 | false | true | round_begin_ba | 1 | data/config/event/5300555.json |

| 5300556 | 小留留下了 | false | true | round_begin_ba | 1 | data/config/event/5300556.json |

| 5300557 | 宰相之死 | false | false | round_begin_ba | 1 | data/config/event/5300557.json |

| 5300558 | 不守规矩的佣兵 |  | false | round_begin_ba | 1 | data/config/event/5300558.json |

| 5300559 | 讨伐无道 | false | false | round_begin_ba | 1 | data/config/event/5300559.json |

| 5300560 | 烂纸头启动 |  | false | round_begin_ba | 1 | data/config/event/5300560.json |

| 5300561 | 锐草之地幕后 | false | false | round_begin_ba | 1 | data/config/event/5300561.json |

| 5300562 | 儿子的索要 | false | false | round_begin_ba | 1 | data/config/event/5300562.json |

| 5300563 | 你最重要的…… | false | false | card_clean | 1 | data/config/event/5300563.json |

| 5300564 | 你最重要的…… | false | false | round_begin_ba | 1 | data/config/event/5300564.json |

| 5300565 | 剑客问询 | false | true | round_begin_ba | 1 | data/config/event/5300565.json |

| 5300566 | 剑客有可杀之人 | false | false | round_begin_ba | 1 | data/config/event/5300566.json |

| 5300567 | 剑客无可杀之人 | false | false | round_begin_ba | 1 | data/config/event/5300567.json |

| 5300568 | 消除一个苏丹的猜忌 | false | false | round_begin_ba | 1 | data/config/event/5300568.json |

| 5300569 | 誓言之证1升2 | false | false | round_begin_ba | 1 | data/config/event/5300569.json |

| 5300570 | 誓言之证2升3 | false | false | round_begin_ba | 1 | data/config/event/5300570.json |

| 5300571 | 誓言之证3升4 | false | false | round_begin_ba | 1 | data/config/event/5300571.json |

| 5300572 | 敦请圣像 | false | false | round_begin_ba | 1 | data/config/event/5300572.json |

| 5300573 | 回收金血之证 | false | false | round_begin_ba | 1 | data/config/event/5300573.json |

| 5300574 | 无可回收的金血之证 | false | false | round_begin_ba | 1 | data/config/event/5300574.json |

| 5300575 | 妻子成为秘教徒后定期消除妻子的不满的仪式 | false | false | round_begin_ba | 1 | data/config/event/5300575.json |

| 5300576 | 疯狂面具 | false | false | round_begin_ba | 1 | data/config/event/5300576.json |

| 5300577 | 父亲的肉 | false | false | round_begin_ba | 1 | data/config/event/5300577.json |

| 5300578 | 月牙女王 | false | false | round_begin_ba | 1 | data/config/event/5300578.json |

| 5300579 | 神的秘密 | false | false | round_begin_ba | 1 | data/config/event/5300579.json |

| 5300580 | 拜铃耶的嫉恨 | false | false | round_begin_ba | 1 | data/config/event/5300580.json |

| 5300581 | 拜铃耶的训练 | false | false | round_begin_ba | 1 | data/config/event/5300581.json |

| 5300582 | 拜铃耶的训练 | false | false | round_begin_ba | 1 | data/config/event/5300582.json |

| 5300583 | 密教基地启动 | false | false | round_begin_ba | 1 | data/config/event/5300583.json |

| 5300584 | 奈布哈尼的离去 | false | false | round_begin_ba | 1 | data/config/event/5300584.json |

| 5300585 | 阿里木的手下助阵 | false | false | round_begin_ba | 1 | data/config/event/5300585.json |

| 5300601 | 随机小事件 | false | true | round_begin_ba | 1 | data/config/event/5300601.json |

| 5300602 | 讽刺的歌 | false | true | round_begin_ba | 1 | data/config/event/5300602.json |

| 5300603 | 蛇鼠一窝 | false | true | round_begin_ba | 1 | data/config/event/5300603.json |

| 5300604 | 诡异的游戏 | false | true | round_begin_ba | 1 | data/config/event/5300604.json |

| 5300605 | 禁忌的画册 | false | true | round_begin_ba | 1 | data/config/event/5300605.json |

| 5300606 | 懈怠的士兵 | false | true | round_begin_ba | 1 | data/config/event/5300606.json |

| 5300607 | 着火的宅子 | false | true | round_begin_ba | 1 | data/config/event/5300607.json |

| 5300608 | 询问品级 | false | true | round_begin_ba | 1 | data/config/event/5300608.json |

| 5300609 | 分羊 | false | true | round_begin_ba | 1 | data/config/event/5300609.json |

| 5300610 | 染血的赌约 | false | true | round_begin_ba | 1 | data/config/event/5300610.json |

| 5300611 | 商人之争 | false | true | round_begin_ba | 1 | data/config/event/5300611.json |

| 5300612 | 神的栖所 | false | true | round_begin_ba | 1 | data/config/event/5300612.json |

| 5300613 | 撤回的献祭 | false | true | round_begin_ba | 1 | data/config/event/5300613.json |

| 5300614 | 你的心中栖有魔鬼 | false | true | round_begin_ba | 1 | data/config/event/5300614.json |

| 5300615 | 寄养子之死 | false | true | round_begin_ba | 1 | data/config/event/5300615.json |

| 5300616 | 苏丹引导-强制5 |  | false | show_wizard_option | 1 | data/config/event/5300616.json |

| 5300617 | 苏丹引导-强制7 |  | false | sudan_redraw_start | 1 | data/config/event/5300617.json |

| 5300650 | 众筹道具-黑暗幻想1 |  | false | round_begin_ba | 1 | data/config/event/5300650.json |

| 5300651 | 众筹道具-黑暗幻想2 |  | false | round_begin_ba | 1 | data/config/event/5300651.json |

| 5300652 | 众筹道具-生命之心-梅姬死亡 |  | false | card_clean | 1 | data/config/event/5300652.json |

| 5300653 | 众筹道具-生命之心-奈布哈尼死亡 |  | false | card_clean | 1 | data/config/event/5300653.json |

| 5300654 | 众筹道具-生命之心-奈费勒死亡 |  | false | card_clean | 1 | data/config/event/5300654.json |

| 5300655 | 众筹道具-生命之心-伊曼死亡 |  | false | card_clean | 1 | data/config/event/5300655.json |

| 5300656 | 众筹道具-生命之心-夏玛死亡 |  | false | card_clean | 1 | data/config/event/5300656.json |

| 5300657 | 众筹道具-生命之心-朱娜死亡 |  | false | card_clean | 1 | data/config/event/5300657.json |

| 5300658 | 众筹道具-生命之心-贾丽拉死亡 |  | false | card_clean | 1 | data/config/event/5300658.json |

| 5300659 | 众筹道具-生命之心-梅姬复活 | false | false | rite_end | 1 | data/config/event/5300659.json |

| 5300660 | 众筹道具-生命之心-奈布哈尼复活 | false | false | rite_end | 1 | data/config/event/5300660.json |

| 5300661 | 众筹道具-生命之心-奈费勒复活 | false | false | rite_end | 1 | data/config/event/5300661.json |

| 5300662 | 众筹道具-生命之心-伊曼复活 | false | false | rite_end | 1 | data/config/event/5300662.json |

| 5300663 | 众筹道具-生命之心-夏玛复活 | false | false | rite_end | 1 | data/config/event/5300663.json |

| 5300664 | 众筹道具-生命之心-朱娜复活 | false | false | rite_end | 1 | data/config/event/5300664.json |

| 5300665 | 众筹道具-生命之心-贾丽拉复活 | false | false | rite_end | 1 | data/config/event/5300665.json |

| 5300666 | 众筹道具-生命之心-怪物的气泡 | false | false | round_begin_ba | 1 | data/config/event/5300666.json |

| 5300667 | 众筹道具-生命之心-怪物死亡时的气泡 |  | false | card_clean | 1 | data/config/event/5300667.json |

| 5300668 | 众筹道具-生命之心-怪物死亡时的气泡 |  | false | card_clean | 1 | data/config/event/5300668.json |

| 5300669 | 众筹道具-生命之心-怪物死亡时的气泡 |  | false | card_clean | 1 | data/config/event/5300669.json |

| 5300670 | 众筹道具-生命之心-怪物死亡时的气泡 |  | false | card_clean | 1 | data/config/event/5300670.json |

| 5300671 | 众筹道具-生命之心-怪物死亡时的气泡 |  | false | card_clean | 1 | data/config/event/5300671.json |

| 5300672 | 众筹道具-生命之心-怪物死亡时的气泡 |  | false | card_clean | 1 | data/config/event/5300672.json |

| 5300673 | 众筹道具-生命之心-怪物死亡时的气泡 |  | false | card_clean | 1 | data/config/event/5300673.json |

| 5300674 | 众筹道具-超级贝姬夫人 |  | false | rite_end | 1 | data/config/event/5300674.json |

| 5300701 | 马衔倒计时6天 | false | false | round_begin_ba | 1 | data/config/event/5300701.json |

| 5300702 | 马衔倒计时每天 | false | false | round_begin_ba | 1 | data/config/event/5300702.json |

| 5300703 | 重铸魔戒 | false | true | round_begin_ba | 1 | data/config/event/5300703.json |

| 5300801 | 小筹启动 |  | false | round_begin_ba | 1 | data/config/event/5300801.json |

| 5300802 | 监听纵欲卡 | false | false | card_clean | 1 | data/config/event/5300802.json |

| 5300803 | 小筹启动诗人第一问 | false | false | round_begin_ba | 1 | data/config/event/5300803.json |

| 5300804 | 小筹启动诗人第二问 | false | false | round_begin_ba | 1 | data/config/event/5300804.json |

| 5300805 | 小筹启动诗人第三问 | false | false | round_begin_ba | 1 | data/config/event/5300805.json |

| 5300806 | 小筹启动 | false | false | round_begin_ba | 1 | data/config/event/5300806.json |

| 5300807 | 监听奢靡卡 | false | false | card_clean | 1 | data/config/event/5300807.json |

| 5300808 | 小筹启动智者第一问 | false | false | round_begin_ba | 1 | data/config/event/5300808.json |

| 5300809 | 小筹启动智者第二问 | false | false | round_begin_ba | 1 | data/config/event/5300809.json |

| 5300810 | 小筹启动智者第三问 | false | false | round_begin_ba | 1 | data/config/event/5300810.json |

| 5300811 | 小筹启动智者第四问 | false | false | round_begin_ba | 1 | data/config/event/5300811.json |

| 5300812 | 监听征服卡 | false | false | card_clean | 1 | data/config/event/5300812.json |

| 5300813 | 小筹启动贵族第一问 | false | false | round_begin_ba | 1 | data/config/event/5300813.json |

| 5300814 | 小筹启动贵族第二问 | false | false | round_begin_ba | 1 | data/config/event/5300814.json |

| 5300815 | 小筹启动贵族第三问 | false | false | round_begin_ba | 1 | data/config/event/5300815.json |

| 5300816 | 小筹启动贵族第四问 | false | false | round_begin_ba | 1 | data/config/event/5300816.json |

| 5300817 | 小筹启动诗人第四问 | false | false | round_begin_ba | 1 | data/config/event/5300817.json |

| 5300818 | 小筹成为追随者的命名后弹窗 | false | false | round_begin_ba | 1 | data/config/event/5300818.json |

| 5300819 | 监听杀戮卡 | false | false | card_clean | 1 | data/config/event/5300819.json |

| 5300820 | 小筹启动战士第一问 | false | false | round_begin_ba | 1 | data/config/event/5300820.json |

| 5300821 | 小筹启动战士第二问 | false | false | round_begin_ba | 1 | data/config/event/5300821.json |

| 5300822 | 小筹启动战士第三问 | false | false | round_begin_ba | 1 | data/config/event/5300822.json |

| 5300823 | 小筹启动战士第四问 | false | false | round_begin_ba | 1 | data/config/event/5300823.json |

| 5300824 | 金币巡回前 | false | false | round_begin_ba | 1 | data/config/event/5300824.json |

| 5300825 | 心胜于物前 | false | true | round_begin_ba | 1 | data/config/event/5300825.json |

| 5300826 | 有趣的人类前 | false | true | round_begin_ba | 1 | data/config/event/5300826.json |

| 5300827 | 金币的归返1 | false | false | round_begin_ba | 1 | data/config/event/5300827.json |

| 5300828 | 金币的归返2 | false | false | round_begin_ba | 1 | data/config/event/5300828.json |

| 5300829 | 小筹第二问的奖励 | false | true | round_begin_ba | 1 | data/config/event/5300829.json |

| 5300830 | 小筹的人性 | false | true | round_begin_ba | 1 | data/config/event/5300830.json |

| 5300831 | 均衡的性质 | false | true | round_begin_ba | 1 | data/config/event/5300831.json |

| 5300832 | 琴声独享 | false | true | round_begin_ba | 1 | data/config/event/5300832.json |

| 5300833 | 不干涉小筹征服 | false | true | round_begin_ba | 1 | data/config/event/5300833.json |

| 5300834 | 不干涉小筹征服 | false | true | round_begin_ba | 1 | data/config/event/5300834.json |

| 5300835 | 不干涉小筹征服 | false | true | round_begin_ba | 1 | data/config/event/5300835.json |

| 5300836 | 镜土的领主 | false | true |  | 1 | data/config/event/5300836.json |

| 5300837 | 支持小筹获胜 | false | true | round_begin_ba | 1 | data/config/event/5300837.json |

| 5300838 | 支持小筹获胜 | false | true | round_begin_ba | 1 | data/config/event/5300838.json |

| 5300839 | 镜土的领主 | false | true |  | 1 | data/config/event/5300839.json |

| 5300840 | 支持小筹失败 | false | true | round_begin_ba | 1 | data/config/event/5300840.json |

| 5300841 | 支持小筹失败 | false | true | round_begin_ba | 1 | data/config/event/5300841.json |

| 5300842 | 支持领主小筹胜利 | false | true | round_begin_ba | 1 | data/config/event/5300842.json |

| 5300843 | 支持领主小筹胜利 | false | true | round_begin_ba | 1 | data/config/event/5300843.json |

| 5300844 | 支持领主小筹失败 | false | true | round_begin_ba | 1 | data/config/event/5300844.json |

| 5300845 | 支持领主小筹失败 | false | true | round_begin_ba | 1 | data/config/event/5300845.json |

| 5300846 | 镜土的领主 | false | true |  | 1 | data/config/event/5300846.json |

| 5300847 | 小筹诗人直接进行结果判定 | false | false | round_begin_ba | 1 | data/config/event/5300847.json |

| 5310000 | 开场演出1测试 | false | true | round_begin_ba | 1 | data/config/event/5310000.json |

| 5310001 | 开场演出2测试 | false | true | round_begin_ba | 1 | data/config/event/5310001.json |

| 5310002 | 开场演出3测试 | false | true | round_begin_ba | 1 | data/config/event/5310002.json |

| 5310003 | 开场演出4测试 | false | true | round_begin_ba | 1 | data/config/event/5310003.json |

| 5310004 | 开场演出5测试 | false | true | round_begin_ba | 1 | data/config/event/5310004.json |

| 5310005 | 仪式结束选择测试 | false | false | rite_end | 1 | data/config/event/5310005.json |

| 5310006 | 开场演出1-最开始 |  | true | round_begin_ba | 1 | data/config/event/5310006.json |

| 5310007 | 获得第一本书时，放入俺寻思的提示 |  | false | round_begin_ba | 1 | data/config/event/5310007.json |

| 5310008 | 俺寻思的自我介绍 | false | true | round_begin_ba | 1 | data/config/event/5310008.json |

| 5310009 | 困难难度需要维持信誉 |  | false | round_begin_ba | 1 | data/config/event/5310009.json |

| 5310010 | 分身说的话 |  | true | round_begin_ba | 1 | data/config/event/5310010.json |

| 5310100 | 苏丹引导-day1-弹框1 |  | false | round_begin_ba | 1 | data/config/event/5310100.json |

| 5310101 | 苏丹引导-day1-弹框2 | false | true | round_begin_ba | 1 | data/config/event/5310101.json |

| 5310102 | 苏丹引导-day1-卡牌发言 | false | true | round_begin_ba | 1 | data/config/event/5310102.json |

| 5310103 | 苏丹引导-day1-弹框3 | false | true | round_begin_ba | 1 | data/config/event/5310103.json |

| 5310104 | 苏丹引导-day1-弹框4 | false | true | round_begin_ba | 1 | data/config/event/5310104.json |

| 5310105 | 苏丹引导-day1-弹框5 | false | true | round_begin_ba | 1 | data/config/event/5310105.json |

| 5310106 | 苏丹引导-day1-事件上的气泡提示 | false | true | round_begin_ba | 1 | data/config/event/5310106.json |

| 5310107 | 苏丹引导-day1-仪式运行中提示 |  | false | rite_start | 1 | data/config/event/5310107.json |

| 5310108 | 苏丹引导-day2-弹框6 | false | false | rite_end | 1 | data/config/event/5310108.json |

| 5310109 | 苏丹引导-day2-弹框7 | false | false | close_wizard | 1 | data/config/event/5310109.json |

| 5310110 | 苏丹引导-day2-事件上的气泡提示 | false | true | round_begin_ba | 1 | data/config/event/5310110.json |

| 5310111 | 苏丹引导-day2-仪式运行中提示 |  | false | rite_start | 1 | data/config/event/5310111.json |

| 5310112 | 苏丹引导-day3-弹框8 | false | false | rite_end | 1 | data/config/event/5310112.json |

| 5310113 | 苏丹引导-day3-弹框9 | false | false | close_wizard | 1 | data/config/event/5310113.json |

| 5310114 | 苏丹引导-day3-事件上的气泡提示 | false | true | round_begin_ba | 1 | data/config/event/5310114.json |

| 5310115 | 苏丹引导-day3-仪式运行中提示 |  | false | rite_start | 1 | data/config/event/5310115.json |

| 5310116 | 苏丹引导-day4-弹框10 | false | false | rite_end | 1 | data/config/event/5310116.json |

| 5310117 | 苏丹引导-day3-弹框11 | false | false | close_wizard | 1 | data/config/event/5310117.json |

| 5310118 | 苏丹引导-day4-事件上的气泡提示 | false | true | round_begin_ba | 1 | data/config/event/5310118.json |

| 5310119 | 苏丹引导-day3-仪式运行中提示 |  | false | rite_start | 1 | data/config/event/5310119.json |

| 5310120 | 苏丹引导-day5-弹框12 | false | false | rite_end | 1 | data/config/event/5310120.json |

| 5310121 | 苏丹引导-day5-弹框13 | false | true | round_begin_ba | 1 | data/config/event/5310121.json |

| 5310122 | 苏丹引导-day5-弹框14 | false | true | round_begin_ba | 1 | data/config/event/5310122.json |

| 5310123 | 苏丹引导-day5-弹框16 | false | true | round_begin_ba | 1 | data/config/event/5310123.json |

| 5310124 | 苏丹引导-day5-弹框17 | false | true | round_begin_ba | 1 | data/config/event/5310124.json |

| 5310125 | 苏丹引导-day5-弹框17 | false | true | round_begin_ba | 1 | data/config/event/5310125.json |

| 5310126 | 苏丹引导-day5-弹框14 | false | true | round_begin_ba | 1 | data/config/event/5310126.json |

| 5310127 | 苏丹引导-强制1 |  | false | open_rite_end | 1 | data/config/event/5310127.json |

| 5310128 | 苏丹引导-强制2 |  | false | close_begin_guide | 1 | data/config/event/5310128.json |

| 5310129 | 苏丹引导-强制3 |  | false | rite_can_start | 1 | data/config/event/5310129.json |

| 5310130 | 苏丹引导-强制4 |  | false | rite_start | 1 | data/config/event/5310130.json |

| 5310132 | 苏丹引导-强制6（废弃） | false | false | close_begin_guide | 1 | data/config/event/5310132.json |

| 5310134 | 苏丹引导-强制8 | false | true | sudan_redraw_start | 1 | data/config/event/5310134.json |

| 5310135 | 苏丹引导-强制9 |  | false | round_begin_ba | 1 | data/config/event/5310135.json |

| 5310136 | 苏丹引导-强制10 |  | false | round_begin_ba | 1 | data/config/event/5310136.json |

| 5310137 | 苏丹引导-强制11 |  | false | close_begin_guide | 1 | data/config/event/5310137.json |

| 5310138 | 苏丹引导-强制12 |  | false | open_card_info_end | 1 | data/config/event/5310138.json |

| 5310139 | 苏丹引导-强制14 |  | false | rite_can_fill | 1 | data/config/event/5310139.json |

| 5310140 | 苏丹引导-强制15 |  | false | rite_can_stop | 1 | data/config/event/5310140.json |

| 5310400 | 结局-逃跑-倒计时 | false | false | rite_end | 1 | data/config/event/5310400.json |

| 5310401 | 结局-逃跑-出发 | false | false | rite_end | 1 | data/config/event/5310401.json |

| 5310402 | 结局-逃跑-梅姬的责难 | false | false | rite_end | 1 | data/config/event/5310402.json |

| 5310403 | 结局-逃跑-最后的苏丹卡 | false | true | round_begin_ba | 1 | data/config/event/5310403.json |

| 5310404 | 结局-逃跑-最后的苏丹卡2 | false | true | round_begin_ba | 1 | data/config/event/5310404.json |

| 5310405 | 结局-逃跑-最后的苏丹卡2 | false | true | round_begin_ba | 1 | data/config/event/5310405.json |

| 5310406 | 结局-逃跑-最后的苏丹卡2 | false | true | round_begin_ba | 1 | data/config/event/5310406.json |

| 5310407 | 结局-逃跑-最后的苏丹卡2 | false | true | round_begin_ba | 1 | data/config/event/5310407.json |

| 5310408 | 结局-逃跑-最后的苏丹卡 | false | true | round_begin_ba | 1 | data/config/event/5310408.json |

| 5310409 | 结局-逃跑-最后的苏丹卡 | false | false | rite_end | 1 | data/config/event/5310409.json |

| 5310410 | 结局-逃跑-激活结局弹框 | false | true | rite_end | 1 | data/config/event/5310410.json |

| 5310411 | 结局-逃跑-激活结局弹框 | false | true | rite_end | 1 | data/config/event/5310411.json |

| 5310412 | 结局-逃跑-激活结局弹框 | false | true | rite_end | 1 | data/config/event/5310412.json |

| 5310413 | 结局-造反-攻打王都城墙 | false | false | rite_end | 1 | data/config/event/5310413.json |

| 5310414 | 结局-造反-攻打王都城墙 | false | false | rite_end | 1 | data/config/event/5310414.json |

| 5310415 | 结局-造反-巷战 | false | false | rite_end | 1 | data/config/event/5310415.json |

| 5310416 | 结局-造反-巷战 | false | false | rite_end | 1 | data/config/event/5310416.json |

| 5310417 | 结局-造反-直面苏丹 | false | false | rite_end | 1 | data/config/event/5310417.json |

| 5310418 | 结局-造反-铁卫得背叛 | false | false | rite_end | 1 | data/config/event/5310418.json |

| 5310419 | 结局-造反-攻入王宫 | false | false | rite_end | 1 | data/config/event/5310419.json |

| 5310420 | 结局-造反-与苏丹决战 | false | false | rite_end | 1 | data/config/event/5310420.json |

| 5310421 | 结局-造反-与苏丹决战 | false | false | rite_end | 1 | data/config/event/5310421.json |

| 5310422 | 结局-造反-与苏丹决战 | false | false | rite_end | 1 | data/config/event/5310422.json |

| 5310423 | 结局-造反-苗圃的守卫者 | false | true | round_begin_ba | 1 | data/config/event/5310423.json |

| 5310424 | 结局-造反-铁头的军队 | false | true | round_begin_ba | 1 | data/config/event/5310424.json |

| 5310425 | 守誓 | false | false | rite_end | 1 | data/config/event/5310425.json |

| 5310426 | 结局-造反-奈布哈尼死亡时补员 |  | false | card_clean | 1 | data/config/event/5310426.json |

| 5310427 | 结局-造反-赛里曼死亡时的说明 | false | false | card_clean | 1 | data/config/event/5310427.json |

| 5310428 | 结局-造反-哲巴尔死亡时补员 |  | false | card_clean | 1 | data/config/event/5310428.json |

| 5310429 | 结局-造反-法里斯死亡时补员 |  | false | card_clean | 1 | data/config/event/5310429.json |

| 5310430 | 结局-逃跑-冻结苏丹卡和猜忌卡 |  | false | rite_start | 1 | data/config/event/5310430.json |

| 5310431 | 结局-逃跑-冻结苏丹卡和猜忌卡 |  | false | rite_start | 1 | data/config/event/5310431.json |

| 5310432 | 结局-逃跑-冻结苏丹卡和猜忌卡 |  | false | rite_cancel | 1 | data/config/event/5310432.json |

| 5310433 | 结局-逃跑-冻结苏丹卡和猜忌卡 |  | false | rite_cancel | 1 | data/config/event/5310433.json |

| 5310434 | 结局-造反-集结提示 | false | false | rite_end | 1 | data/config/event/5310434.json |

| 5310435 | 结局-造反-铁卫的职责 | false | false | rite_end | 1 | data/config/event/5310435.json |

| 5310436 | 结局-造反-蓝巾军 | false | true | round_begin_ba | 1 | data/config/event/5310436.json |

| 5310437 | 结局-造反-征服者-宫廷那一波人 | false | false | rite_end | 1 | data/config/event/5310437.json |

| 5310438 | 结局-造反-征服者-普通贵族一波 | false | true | rite_end | 1 | data/config/event/5310438.json |

| 5310439 | 结局-造反-征服者-平民一波 | false | true | rite_end | 1 | data/config/event/5310439.json |

| 5310440 | 结局-造反-征服者-神职人员 | false | true | rite_end | 1 | data/config/event/5310440.json |

| 5310441 | 结局-造反-征服者-奈费勒-没有交集的时候 | false | true | rite_end | 1 | data/config/event/5310441.json |

| 5310442 | 结局-造反-征服者-奈费勒-是大敌的情况 | false | true | rite_end | 1 | data/config/event/5310442.json |

| 5310443 | 结局-造反-征服者-奈费勒-非大敌，有秘誓的情况 | false | true | rite_end | 1 | data/config/event/5310443.json |

| 5310444 | 结局-造反-征服者-哲瓦德-非大敌 | false | true | rite_end | 1 | data/config/event/5310444.json |

| 5310445 | 结局-造反-征服者-哲瓦德-大敌 | false | true | rite_end | 1 | data/config/event/5310445.json |

| 5310446 | 结局-造反-征服者-娜依拉-非大敌 | false | true | rite_end | 1 | data/config/event/5310446.json |

| 5310447 | 结局-造反-征服者-娜依拉-大敌 | false | true | rite_end | 1 | data/config/event/5310447.json |

| 5310448 | 结局-造反-征服者-小圆-非大敌 | false | true | rite_end | 1 | data/config/event/5310448.json |

| 5310449 | 结局-造反-征服者-小圆-铁头大敌 | false | true | rite_end | 1 | data/config/event/5310449.json |

| 5310450 | 结局-造反-征服者-铁头-非大敌 | false | true | rite_end | 1 | data/config/event/5310450.json |

| 5310451 | 结局-造反-征服者-铁头-大敌 | false | true | rite_end | 1 | data/config/event/5310451.json |

| 5310452 | 结局-造反-给角色加改革和传统的tag | false | true | rite_end | 1 | data/config/event/5310452.json |

| 5310453 | 结局-消除苏丹卡 |  | false | rite_end, round_begin_ba, close_wizard | 1 | data/config/event/5310453.json |

| 5310454 | 结局-消除苏丹卡-深渊的邀请（废弃） | false | true | round_begin_ba | 1 | data/config/event/5310454.json |

| 5310455 | 结局-消除苏丹卡 | false | true | round_begin_ba | 1 | data/config/event/5310455.json |

| 5310456 | 结局-消除苏丹卡 |  | false | round_begin_ba, rite_end, close_wizard | 1 | data/config/event/5310456.json |

| 5310457 | 结局-苏丹的召见 | false | true | round_begin_ba | 1 | data/config/event/5310457.json |

| 5310458 | 结局-逃跑-荒野 | false | true | rite_end | 1 | data/config/event/5310458.json |

| 5310459 | 结局-造反给倒计时 | false | true | rite_end | 1 | data/config/event/5310459.json |

| 5310460 | 结局-新月之书 | false | true | rite_end | 1 | data/config/event/5310460.json |

| 5310461 | 结局-新日之坠 | false | true | rite_end | 1 | data/config/event/5310461.json |

| 5310462 | 结局-日之牢笼 | false | true | rite_end | 1 | data/config/event/5310462.json |

| 5310463 | 结局-直面苏丹的暗道 | false | false | rite_end | 1 | data/config/event/5310463.json |

| 5310464 | 结局-直面苏丹的暗道 | false | false | rite_end | 1 | data/config/event/5310464.json |

| 5310465 | 结局-直面苏丹的暗道 | false | true | rite_end | 1 | data/config/event/5310465.json |

| 5310466 | 神临之塔 |  | false | round_begin_ba | 1 | data/config/event/5310466.json |

| 5310467 | 审判烈焰 | false | false | rite_end | 1 | data/config/event/5310467.json |

| 5310468 | 神临之塔完成了 | false | false | rite_end | 1 | data/config/event/5310468.json |

| 5310469 | 反抗？ | false | false | rite_end | 1 | data/config/event/5310469.json |

| 5310470 | 苏丹的戒指被偷了吗 | false | true | rite_end | 1 | data/config/event/5310470.json |

| 5310471 | 苏丹的戒指被偷了吗 | false | true | rite_end | 1 | data/config/event/5310471.json |

| 5310472 | 圣主驾到 | false | true | rite_end | 1 | data/config/event/5310472.json |

| 5310473 | 神秘的女士 | false | true | rite_end | 1 | data/config/event/5310473.json |

| 5310474 | 承阳武士-拔剑 | false | true | round_begin_ba | 1 | data/config/event/5310474.json |

| 5310475 | 结局-征服之末 | false | true | rite_end | 1 | data/config/event/5310475.json |

| 5310476 | 结局-游戏之国 | false | true | rite_end | 1 | data/config/event/5310476.json |

| 5310477 | 结局-征服者的牢笼 | false | true | rite_end | 1 | data/config/event/5310477.json |

| 5310478 | 结局-征服者的奖赏 | false | true | rite_end | 1 | data/config/event/5310478.json |

| 5310479 | 结局-站着的苏丹 | false | true | rite_end | 1 | data/config/event/5310479.json |

| 5310480 | 结局-忠诚之刃 | false | true | rite_end | 1 | data/config/event/5310480.json |

| 5310481 | 结局-游戏之国 | false | true | rite_end | 1 | data/config/event/5310481.json |

| 5310482 | 结局-破盾终局 | false | true | rite_end | 1 | data/config/event/5310482.json |

| 5310483 | 结局-血脉的囚笼 | false | true | rite_end | 1 | data/config/event/5310483.json |

| 5310484 | 结局-一国二王 | false | true | rite_end | 1 | data/config/event/5310484.json |

| 5310485 | 结局-金血之末 | false | true | rite_end | 1 | data/config/event/5310485.json |

| 5310486 | 结局-游戏之国 | false | true | rite_end | 1 | data/config/event/5310486.json |

| 5310487 | 结局-金血之囚 | false | true | rite_end | 1 | data/config/event/5310487.json |

| 5310488 | 结局-追忆之国 | false | true | rite_end | 1 | data/config/event/5310488.json |

| 5310489 | 结局-红袍的叛星者 | false | true | rite_end | 1 | data/config/event/5310489.json |

| 5310490 | 结局-星剑的遗言 | false | true | rite_end | 1 | data/config/event/5310490.json |

| 5310491 | 结局-丛林之国 | false | true | rite_end | 1 | data/config/event/5310491.json |

| 5310492 | 结局-星剑之国 | false | true | rite_end | 1 | data/config/event/5310492.json |

| 5310493 | 结局-誓言的囚徒 | false | true | rite_end | 1 | data/config/event/5310493.json |

| 5310494 | 结局-坠星冉升 | false | true | rite_end | 1 | data/config/event/5310494.json |

| 5310495 | 结局-丛林之国 | false | true | rite_end | 1 | data/config/event/5310495.json |

| 5310496 | 结局-伟业之国 | false | true | rite_end | 1 | data/config/event/5310496.json |

| 5310497 | 结局-终点的笑声 | false | true | rite_end | 1 | data/config/event/5310497.json |

| 5310498 | 结局-命运之剪 | false | true | rite_end | 1 | data/config/event/5310498.json |

| 5310499 | 结局-遭窃的果实 | false | true | rite_end | 1 | data/config/event/5310499.json |

| 5310501 | 结局-逃跑-激活结局弹框 | false | true | rite_end | 1 | data/config/event/5310501.json |

| 5310502 | 结局-屠龙-牺牲结局妻子存活弹框 | false | true | rite_end | 1 | data/config/event/5310502.json |

| 5310503 | 结局-逃跑-牺牲结局妻子死亡弹框 | false | true | rite_end | 1 | data/config/event/5310503.json |

| 5310504 | 结局-逃跑-冻结苏丹卡和猜忌卡 |  | false | rite_end | 1 | data/config/event/5310504.json |

| 5310505 | 高原人的回响 | false | true | rite_end | 1 | data/config/event/5310505.json |

| 5310506 | 结局-千廊之国 | false | true | rite_end | 1 | data/config/event/5310506.json |

| 5310507 | 结局-灯影下 | false | true | rite_end | 1 | data/config/event/5310507.json |

| 5310508 | 结局-命运的报偿 | false | true | rite_end | 1 | data/config/event/5310508.json |

| 5310509 | 结局-低垂的果实 | false | true | rite_end | 1 | data/config/event/5310509.json |

| 5310510 | 结局-人之国 | false | true | rite_end | 1 | data/config/event/5310510.json |

| 5310511 | 结局-有罪的石头 | false | true | rite_end | 1 | data/config/event/5310511.json |

| 5310512 | 结局-荒野的呼号 | false | true | rite_end | 1 | data/config/event/5310512.json |

| 5310513 | 结局-流浪欲 | false | true | rite_end | 1 | data/config/event/5310513.json |

| 5310514 | 结局-人之国 | false | true | rite_end | 1 | data/config/event/5310514.json |

| 5310515 | 结局-有罪的石头 | false | true | rite_end | 1 | data/config/event/5310515.json |

| 5310516 | 结局-不起眼的朋友 | false | true | rite_end | 1 | data/config/event/5310516.json |

| 5310517 | 结局-流浪欲 | false | true | rite_end | 1 | data/config/event/5310517.json |

| 5310518 | 结局-贤者之国 | false | true | rite_end | 1 | data/config/event/5310518.json |

| 5310519 | 结局-终点的笑声 | false | true | rite_end | 1 | data/config/event/5310519.json |

| 5310520 | 结局-命运之剪 | false | true | rite_end | 1 | data/config/event/5310520.json |

| 5310521 | 结局-遭窃的果实 | false | true | rite_end | 1 | data/config/event/5310521.json |

| 5310522 | 结局-均衡之国 | false | true | rite_end | 1 | data/config/event/5310522.json |

| 5310523 | 结局-终点的笑声 | false | true | rite_end | 1 | data/config/event/5310523.json |

| 5310524 | 结局-命运之剪 | false | true | rite_end | 1 | data/config/event/5310524.json |

| 5310525 | 结局-遭窃的果实 | false | true | rite_end | 1 | data/config/event/5310525.json |

| 5310526 | 结局-英雄之国 | false | true | rite_end | 1 | data/config/event/5310526.json |

| 5310527 | 结局-征伐之国 | false | true | rite_end | 1 | data/config/event/5310527.json |

| 5310528 | 结局-伯劳的森林 | false | true | rite_end | 1 | data/config/event/5310528.json |

| 5310529 | 结局-英雄之国 | false | true | rite_end | 1 | data/config/event/5310529.json |

| 5310530 | 结局-征伐之国 | false | true | rite_end | 1 | data/config/event/5310530.json |

| 5310531 | 结局-伯劳的森林 | false | true | rite_end | 1 | data/config/event/5310531.json |

| 5310532 | 结局-英雄之国 | false | true | rite_end | 1 | data/config/event/5310532.json |

| 5310533 | 结局-征伐之国 | false | true | rite_end | 1 | data/config/event/5310533.json |

| 5310534 | 结局-伯劳的森林 | false | true | rite_end | 1 | data/config/event/5310534.json |

| 5310535 | 结局-加个冻结的保险 | false | false | round_begin_ba | 1 | data/config/event/5310535.json |

| 5310536 | 结局-君权神授 | false | true | rite_end | 1 | data/config/event/5310536.json |

| 5310537 | 结局-昼夜契约 | false | true | rite_end | 1 | data/config/event/5310537.json |

| 5310550 | 结局-梦幻宫殿 | false | true | rite_end | 1 | data/config/event/5310550.json |

| 5310551 | 结局-梦幻宫殿 | false | true | rite_end | 1 | data/config/event/5310551.json |

| 5310552 | 结局-梦幻宫殿 | false | true | rite_end | 1 | data/config/event/5310552.json |

| 5310553 | 结局-百科全书 | false | true | rite_end | 1 | data/config/event/5310553.json |

| 5310554 | 结局-英雄之国 | false | true | rite_end | 1 | data/config/event/5310554.json |

| 5310555 | 结局-征伐之国 | false | true | rite_end | 1 | data/config/event/5310555.json |

| 5310556 | 结局-伯劳的森林 | false | true | rite_end | 1 | data/config/event/5310556.json |

| 5310557 | 结局-英雄之国 | false | true | rite_end | 1 | data/config/event/5310557.json |

| 5310558 | 结局-征伐之国 | false | true | rite_end | 1 | data/config/event/5310558.json |

| 5310559 | 结局-伯劳的森林 | false | true | rite_end | 1 | data/config/event/5310559.json |

| 5310601 | 正教第一个幕后 |  | false | card_clean | 1 | data/config/event/5310601.json |

| 5310602 | 正教第一个幕后 | false | false | card_clean | 1 | data/config/event/5310602.json |

| 5310603 | 正教第一个幕后 | false | false | card_clean | 1 | data/config/event/5310603.json |

| 5310604 | 正教第一个幕后 | false | false | round_begin_ba | 1 | data/config/event/5310604.json |

| 5310605 | 忏悔 | false | false | round_begin_ba | 1 | data/config/event/5310605.json |

| 5310606 | 给正教打工 | false | false | round_begin_ba | 1 | data/config/event/5310606.json |

| 5310607 | 与正教决裂 |  | false | round_begin_ba | 1 | data/config/event/5310607.json |

| 5310608 | 正教的干扰 | false | false | round_begin_ba | 1 | data/config/event/5310608.json |

| 5310609 | 伊曼的祈祷开启的幕后 | false | false | round_begin_ba | 1 | data/config/event/5310609.json |

| 5310610 | 伊曼辩经 | false | false | round_begin_ba | 1 | data/config/event/5310610.json |

| 5310611 | 秘密幽会 | false | false | round_begin_ba | 1 | data/config/event/5310611.json |

| 5310612 | 通奸被抓 | false | true | round_begin_ba | 1 | data/config/event/5310612.json |

| 5310613 | 伊曼的羁绊 | false | false | round_begin_ba | 1 | data/config/event/5310613.json |

| 5310614 | 伊曼的感谢信 | false | false | round_begin_ba | 1 | data/config/event/5310614.json |

| 5310615 | 成为教领的启动 | false | false | round_begin_ba | 1 | data/config/event/5310615.json |

| 5310616 | 没有决裂伊曼存活 | false | true | round_begin_ba | 1 | data/config/event/5310616.json |

| 5310617 | 没有决裂伊曼死亡 | false | true | round_begin_ba | 1 | data/config/event/5310617.json |

| 5310618 | 决裂伊曼存活 | false | true | round_begin_ba | 1 | data/config/event/5310618.json |

| 5310619 | 决裂伊曼死亡 | false | true | round_begin_ba | 1 | data/config/event/5310619.json |

| 5310620 | 正教第一个幕后 | false | false | round_begin_ba | 1 | data/config/event/5310620.json |

| 5310621 | 生成正教的乙太的幕后 |  | false | round_begin_ba | 1 | data/config/event/5310621.json |

| 5310622 | 抉择 | false | false | rite_end | 1 | data/config/event/5310622.json |

| 5310623 | 辨识灵光 | false | false | round_begin_ba | 1 | data/config/event/5310623.json |

| 5310624 | 选光者 | false | false | round_begin_ba | 1 | data/config/event/5310624.json |

| 5310625 | 开启神之硕鼠 | false | false | round_begin_ba | 1 | data/config/event/5310625.json |

| 5310626 | 贵族子弟之死 | false | false | round_begin_ba | 1 | data/config/event/5310626.json |

| 5310627 | 无知少年之死之死 | false | false | round_begin_ba | 1 | data/config/event/5310627.json |

| 5310628 | 伊曼的解释 | false | false | round_begin_ba | 1 | data/config/event/5310628.json |

| 5310629 | 黑暗之神的诱惑 |  | false | round_begin_ba | 1 | data/config/event/5310629.json |

| 5310630 | 饥渴 | false | false | round_begin_ba | 1 | data/config/event/5310630.json |

| 5310631 | 饥渴 | false | false | round_begin_ba | 1 | data/config/event/5310631.json |

| 5310632 | 伊曼的离开 | false | false | round_begin_ba | 1 | data/config/event/5310632.json |

| 5310633 | 苏丹在玩魅魔 | false | false | round_begin_ba | 1 | data/config/event/5310633.json |

| 5310634 | 正教的讨伐 | false | false | rite_end | 1 | data/config/event/5310634.json |

| 5310635 | 大敌的讨伐 | false | false | rite_end | 1 | data/config/event/5310635.json |

| 5310636 | 讨伐 | false | false | round_begin_ba | 1 | data/config/event/5310636.json |

| 5310637 | 要反悔吗 | false | true | rite_end | 1 | data/config/event/5310637.json |

| 5310638 | 要接受吗 | false | true | rite_end | 1 | data/config/event/5310638.json |

| 5310639 | 圣主驾到 | false | true | rite_end | 1 | data/config/event/5310639.json |

| 5310640 | 打密神苏丹入队 | false | true | rite_end | 1 | data/config/event/5310640.json |

| 5310641 | 打密神君临 | false | true | rite_end | 1 | data/config/event/5310641.json |

| 5310642 | 要接受吗 | false | true | rite_end | 1 | data/config/event/5310642.json |

| 5310643 | 黑暗知识主角反悔 | false | true | rite_end | 1 | data/config/event/5310643.json |

| 5310690 | 百科全书成就 |  | false | round_begin_ba | 1 | data/config/event/5310690.json |

| 5310691 | 陶土钥匙成就 |  | false | round_begin_ba | 1 | data/config/event/5310691.json |

| 5310801 | 神的面容 |  | false | round_begin_ba | 1 | data/config/event/5310801.json |

| 5310802 | 地底的呼唤 |  | false | round_begin_ba | 1 | data/config/event/5310802.json |

| 5310803 | 心中之神 |  | false | round_begin_ba | 1 | data/config/event/5310803.json |

| 5310804 | 腐化真容 |  | false | round_begin_ba | 1 | data/config/event/5310804.json |

| 5310805 | 光之训诫 |  | false | round_begin_ba | 1 | data/config/event/5310805.json |

| 5310806 | 神的启示 |  | false | round_begin_ba | 1 | data/config/event/5310806.json |

| 5310807 | 毁灭真容 |  | false | round_begin_ba | 1 | data/config/event/5310807.json |

| 5310808 | 神圣的会晤 |  | false | round_begin_ba | 1 | data/config/event/5310808.json |

| 5310809 | 疯癫与幻觉 |  | false | round_begin_ba | 1 | data/config/event/5310809.json |

| 5310810 | 消解疯狂-检定妻子的体魄 | false | false | rite_end | 1 | data/config/event/5310810.json |

| 5310811 | 消解疯狂-检定法拉杰的体魄 | false | false | rite_end | 1 | data/config/event/5310811.json |

| 5310812 | 消解疯狂-检定玩家的体魄 | false | false | rite_end | 1 | data/config/event/5310812.json |

| 5310813 | 心灵之战-1 | false | false | round_begin_ba | 1 | data/config/event/5310813.json |

| 5310814 | 心灵之战-1-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310814.json |

| 5310815 | 心灵之战-2 | false | false | round_begin_ba | 1 | data/config/event/5310815.json |

| 5310816 | 心灵之战-2-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310816.json |

| 5310817 | 心灵之战-3 | false | false | round_begin_ba | 1 | data/config/event/5310817.json |

| 5310818 | 心灵之战-3-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310818.json |

| 5310819 | 心灵之战-4 | false | false | round_begin_ba | 1 | data/config/event/5310819.json |

| 5310820 | 心灵之战-4-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310820.json |

| 5310821 | 心灵之战-5 | false | false | round_begin_ba | 1 | data/config/event/5310821.json |

| 5310822 | 心灵之战-5-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310822.json |

| 5310823 | 心灵之战-6 | false | false | round_begin_ba | 1 | data/config/event/5310823.json |

| 5310824 | 心灵之战-6-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310824.json |

| 5310825 | 心灵之战-7 | false | false | round_begin_ba | 1 | data/config/event/5310825.json |

| 5310826 | 心灵之战-7-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310826.json |

| 5310827 | 心灵之战-8 | false | false | round_begin_ba | 1 | data/config/event/5310827.json |

| 5310828 | 心灵之战-8-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310828.json |

| 5310829 | 心灵之战-9 | false | false | round_begin_ba | 1 | data/config/event/5310829.json |

| 5310830 | 心灵之战-9-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310830.json |

| 5310831 | 心灵之战-10 | false | false | round_begin_ba | 1 | data/config/event/5310831.json |

| 5310832 | 心灵之战-10-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310832.json |

| 5310833 | 心灵之战-11 | false | false | round_begin_ba | 1 | data/config/event/5310833.json |

| 5310834 | 心灵之战-11-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310834.json |

| 5310835 | 心灵之战-12 | false | false | round_begin_ba | 1 | data/config/event/5310835.json |

| 5310836 | 心灵之战-12-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310836.json |

| 5310837 | 心灵之战-13 | false | false | round_begin_ba | 1 | data/config/event/5310837.json |

| 5310838 | 心灵之战-13-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310838.json |

| 5310839 | 心灵之战-14 | false | false | round_begin_ba | 1 | data/config/event/5310839.json |

| 5310840 | 心灵之战-14-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310840.json |

| 5310841 | 心灵之战-15 | false | false | round_begin_ba | 1 | data/config/event/5310841.json |

| 5310842 | 心灵之战-15-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5310842.json |

| 5310843 | 心灵之战-16 | false | false | round_begin_ba | 1 | data/config/event/5310843.json |

| 5310844 | 神的警告 | false | false | rite_end | 1 | data/config/event/5310844.json |

| 5310845 | 神的警告 | false | false | rite_end | 1 | data/config/event/5310845.json |

| 5310846 | 可悲的凡人(正教先来) | false | false | rite_end | 1 | data/config/event/5310846.json |

| 5310847 | 可悲的凡人(邪教先来) | false | false | rite_end | 1 | data/config/event/5310847.json |

| 5310848 | 可悲的凡人(两个人一起来) | false | false | rite_end | 1 | data/config/event/5310848.json |

| 5310849 | 消解疯狂-检定妻子的体魄-重置计数 |  | false | rite_end | 1 | data/config/event/5310849.json |

| 5310850 | 消解疯狂-检定法拉杰的体魄 |  | false | rite_end | 1 | data/config/event/5310850.json |

| 5310851 | 消解疯狂-检定玩家的体魄 |  | false | rite_end | 1 | data/config/event/5310851.json |

| 5310852 | 玛希尔的问题 | false | false | rite_end | 1 | data/config/event/5310852.json |

| 5310853 | 我是…… | false | false | rite_end | 1 | data/config/event/5310853.json |

| 5310854 | 我是…… | false | false | rite_end | 1 | data/config/event/5310854.json |

| 5310855 |  | false | false | rite_end | 1 | data/config/event/5310855.json |

| 5310856 |  | false | false | rite_end | 1 | data/config/event/5310856.json |

| 5310857 | 监听代言人死活 | false | false | rite_end | 1 | data/config/event/5310857.json |

| 5310858 | 奈费勒 | false | false | rite_end | 1 | data/config/event/5310858.json |

| 5310859 | 承阳剑 | false | false | rite_end | 1 | data/config/event/5310859.json |

| 5310860 | 苏丹的近卫 | false | false | rite_end | 1 | data/config/event/5310860.json |

| 5310861 | 星之战士 | false | false | rite_end | 1 | data/config/event/5310861.json |

| 5310862 | 苏丹的军队 | false | false | rite_end | 1 | data/config/event/5310862.json |

| 5310863 | 火焰大王 | false | false | rite_end | 1 | data/config/event/5310863.json |

| 5310864 | 蓝巾军-君权神授 | false | true | round_begin_ba | 1 | data/config/event/5310864.json |

| 5310865 | 蓝巾军-昼夜契约 | false | true | round_begin_ba | 1 | data/config/event/5310865.json |

| 5310866 | 蓝巾军-纪元 | false | true | round_begin_ba | 1 | data/config/event/5310866.json |

| 5310867 | 塔-过渡弹框 | false | false | rite_end | 1 | data/config/event/5310867.json |

| 5310868 | 结局-龙眼-宫廷那一波人 | false | false | rite_end | 1 | data/config/event/5310868.json |

| 5310869 | 结局-龙眼-普通贵族一波 | false | true | rite_end | 1 | data/config/event/5310869.json |

| 5310870 | 结局-龙眼--平民一波 | false | true | rite_end | 1 | data/config/event/5310870.json |

| 5310871 | 结局-龙眼-神职人员 | false | true | rite_end | 1 | data/config/event/5310871.json |

| 5310872 | 结局-龙眼-奈费勒-没有交集的时候 | false | true | rite_end | 1 | data/config/event/5310872.json |

| 5310873 | 结局-龙眼-奈费勒-是大敌的情况 | false | true | rite_end | 1 | data/config/event/5310873.json |

| 5310874 | 结局-龙眼-奈费勒-非大敌，有秘誓的情况 | false | true | rite_end | 1 | data/config/event/5310874.json |

| 5310875 | 结局-龙眼-哲瓦德-非大敌 | false | true | rite_end | 1 | data/config/event/5310875.json |

| 5310876 | 结局-龙眼-哲瓦德-大敌 | false | true | rite_end | 1 | data/config/event/5310876.json |

| 5310877 | 结局-龙眼-娜依拉-非大敌 | false | true | rite_end | 1 | data/config/event/5310877.json |

| 5310878 | 结局-龙眼-大敌 | false | true | rite_end | 1 | data/config/event/5310878.json |

| 5310879 | 结局-龙眼-铁头-大敌 | false | true | rite_end | 1 | data/config/event/5310879.json |

| 5310880 | 开悟的领悟-无星灵 | false | false | rite_end | 1 | data/config/event/5310880.json |

| 5310881 | 开悟的领悟-有星灵 | false | false | rite_end | 1 | data/config/event/5310881.json |

| 5310882 | 开悟之后-星灵诞生 | false | false | round_begin_ba | 1 | data/config/event/5310882.json |

| 5310883 | 星之战士-昼夜契约 | false | true | rite_end | 1 | data/config/event/5310883.json |

| 5310884 | 星之战士-纪元 | false | true | rite_end | 1 | data/config/event/5310884.json |

| 5310885 | 星之战士-君权神授 | false | true | rite_end | 1 | data/config/event/5310885.json |

| 5310886 | 奈费勒-君权神授 | false | true | rite_end | 1 | data/config/event/5310886.json |

| 5310887 | 奈费勒-昼夜契约 | false | true | rite_end | 1 | data/config/event/5310887.json |

| 5310888 | 奈费勒-纪元 | false | true | rite_end | 1 | data/config/event/5310888.json |

| 5310889 | 承阳剑-君权神授 | false | true | rite_end | 1 | data/config/event/5310889.json |

| 5310890 | 承阳剑-昼夜契约 | false | true | rite_end | 1 | data/config/event/5310890.json |

| 5310891 | 承阳剑-纪元 | false | true | rite_end | 1 | data/config/event/5310891.json |

| 5310892 | 君权神授神性 | false | true | rite_end | 1 | data/config/event/5310892.json |

| 5310893 | 君权神授人性 | false | true | rite_end | 1 | data/config/event/5310893.json |

| 5310894 | 昼夜契约神性 | false | true | rite_end | 1 | data/config/event/5310894.json |

| 5310895 | 昼夜契约人性 | false | true | rite_end | 1 | data/config/event/5310895.json |

| 5310896 | 纪元神性 | false | true | rite_end | 1 | data/config/event/5310896.json |

| 5310897 | 纪元人性 | false | true | rite_end | 1 | data/config/event/5310897.json |

| 5310898 | 女术士的话 | false | true | rite_end | 1 | data/config/event/5310898.json |

| 5310899 | 移除疯癫与幻觉 | false | true | rite_end | 1 | data/config/event/5310899.json |

| 5310900 | 移除神的面容 | false | true | round_begin_ba | 1 | data/config/event/5310900.json |

| 5310901 | 宣战 | false | false | rite_end | 1 | data/config/event/5310901.json |

| 5310902 | 屠龙之梦-有两个正当性 | false | false | rite_end | 1 | data/config/event/5310902.json |

| 5310903 | 屠龙之梦-有两个正当性 | false | false | rite_end | 1 | data/config/event/5310903.json |

| 5310904 | 苏丹的军队 | false | false | rite_end | 1 | data/config/event/5310904.json |

| 5311001 | 飞升线加入手牌的幕后 | false | true | round_begin_ba | 1 | data/config/event/5311001.json |

| 5311002 | 是否臣服 | false | false | rite_end | 1 | data/config/event/5311002.json |

| 5311003 | 结算陶土之门是否完成 | false | true | rite_end | 1 | data/config/event/5311003.json |

| 5311004 | 结算墨色褪去是否完成 | false | false | rite_end | 1 | data/config/event/5311004.json |

| 5311005 | 结算墨色褪去是否完成 | false | false | rite_end | 1 | data/config/event/5311005.json |

| 5311006 | 结算虚空之火是否完成 | false | false | rite_end | 1 | data/config/event/5311006.json |

| 5311007 | 结算虚空之火是否完成 | false | false | rite_end | 1 | data/config/event/5311007.json |

| 5311008 | 结算造化之风是否完成 | false | false | rite_end | 1 | data/config/event/5311008.json |

| 5311009 | 结算造化之风是否完成 | false | false | rite_end | 1 | data/config/event/5311009.json |

| 5311010 | 结算陶土之门是否完成 | false | false | rite_end | 1 | data/config/event/5311010.json |

| 5311011 | 结算陶土之门是否完成 | false | false | rite_end | 1 | data/config/event/5311011.json |

| 5311012 | 飞升线梅姬成功 | false | true | round_begin_ba | 1 | data/config/event/5311012.json |

| 5311013 | 飞升线安苏亚成功 | false | true | round_begin_ba | 1 | data/config/event/5311013.json |

| 5311014 | 飞升线莎姬成功 | false | true | round_begin_ba | 1 | data/config/event/5311014.json |

| 5311015 | 飞升线流浪剑客成功 | false | true | round_begin_ba | 1 | data/config/event/5311015.json |

| 5311016 | 飞升线热娜成功 | false | true | round_begin_ba | 1 | data/config/event/5311016.json |

| 5311017 | 飞升线伊曼成功 | false | true | round_begin_ba | 1 | data/config/event/5311017.json |

| 5311018 | 飞升线拜铃耶成功 | false | true | round_begin_ba | 1 | data/config/event/5311018.json |

| 5311019 | 飞升线苏丹成功 | false | true | round_begin_ba | 1 | data/config/event/5311019.json |

| 5311020 | 飞升线哲巴尔成功 | false | true | round_begin_ba | 1 | data/config/event/5311020.json |

| 5311021 | 飞升线娜依拉成功 | false | true | round_begin_ba | 1 | data/config/event/5311021.json |

| 5311022 | 飞升线盖斯成功 | false | true | round_begin_ba | 1 | data/config/event/5311022.json |

| 5311023 | 飞升线阿迪莱成功 | false | true | round_begin_ba | 1 | data/config/event/5311023.json |

| 5311024 | 飞升线法图娜成功 | false | true | round_begin_ba | 1 | data/config/event/5311024.json |

| 5311025 | 飞升线奈布哈尼成功 | false | true | round_begin_ba | 1 | data/config/event/5311025.json |

| 5311026 | 飞升线麦娜尔成功 | false | true | round_begin_ba | 1 | data/config/event/5311026.json |

| 5311027 | 飞升线朱娜成功 | false | true | round_begin_ba | 1 | data/config/event/5311027.json |

| 5311028 | 飞升线贾丽拉成功 | false | true | round_begin_ba | 1 | data/config/event/5311028.json |

| 5311029 | 飞升线夏玛成功 | false | true | round_begin_ba | 1 | data/config/event/5311029.json |

| 5311030 | 飞升线阿里木成功 | false | true | round_begin_ba | 1 | data/config/event/5311030.json |

| 5311031 | 飞升线鲁梅拉成功 | false | true | round_begin_ba | 1 | data/config/event/5311031.json |

| 5311032 | 飞升线鲁梅拉星灵成功 | false | true | round_begin_ba | 1 | data/config/event/5311032.json |

| 5311033 | 飞升线弑君的计划成功 | false | true | round_begin_ba | 1 | data/config/event/5311033.json |

| 5311034 | 飞升线金杀戮成功 | false | true | round_begin_ba | 1 | data/config/event/5311034.json |

| 5311035 | 飞升线金纵欲成功 | false | true | round_begin_ba | 1 | data/config/event/5311035.json |

| 5311036 | 飞升线金奢靡成功 | false | true | round_begin_ba | 1 | data/config/event/5311036.json |

| 5311037 | 飞升线金征服成功 | false | true | round_begin_ba | 1 | data/config/event/5311037.json |

| 5311038 | 飞升线法尔达克成功 | false | true | round_begin_ba | 1 | data/config/event/5311038.json |

| 5311039 | 飞升线铁头成功 | false | true | round_begin_ba | 1 | data/config/event/5311039.json |

| 5311040 | 飞升线小圆成功 | false | true | round_begin_ba | 1 | data/config/event/5311040.json |

| 5311041 | 飞升线法拉杰成功 | false | true | round_begin_ba | 1 | data/config/event/5311041.json |

| 5311042 | 飞升线完美世界成功 | false | true | round_begin_ba | 1 | data/config/event/5311042.json |

| 5311043 | 飞升线新世界成功 | false | true | round_begin_ba | 1 | data/config/event/5311043.json |

| 5311044 | 飞升线马尔基娜成功 | false | true | round_begin_ba | 1 | data/config/event/5311044.json |

| 5311045 | 飞升线哈桑成功 | false | true | round_begin_ba | 1 | data/config/event/5311045.json |

| 5311046 | 飞升线革命的计划成功 | false | true | round_begin_ba | 1 | data/config/event/5311046.json |

| 5311047 | 飞升线火焰大王成功 | false | true | round_begin_ba | 1 | data/config/event/5311047.json |

| 5311048 | 飞升线芮尔成功 | false | true | round_begin_ba | 1 | data/config/event/5311048.json |

| 5311049 | 飞升线承阳剑成功 | false | true | round_begin_ba | 1 | data/config/event/5311049.json |

| 5311050 | 飞升线星神的信仰成功 | false | true | round_begin_ba | 1 | data/config/event/5311050.json |

| 5311051 | 飞升线镜灵成功 | false | true | round_begin_ba | 1 | data/config/event/5311051.json |

| 5311052 | 飞升线妖精女王提灯成功 | false | true | round_begin_ba | 1 | data/config/event/5311052.json |

| 5311053 | 飞升线法里斯成功 | false | true | round_begin_ba | 1 | data/config/event/5311053.json |

| 5311054 | 飞升线哈比卜成功 | false | true | round_begin_ba | 1 | data/config/event/5311054.json |

| 5311055 | 飞升线伊曼失败 | false | true | round_begin_ba | 1 | data/config/event/5311055.json |

| 5311056 | 飞升线拜铃耶失败 | false | true | round_begin_ba | 1 | data/config/event/5311056.json |

| 5311057 | 飞升线娜依拉失败 | false | true | round_begin_ba | 1 | data/config/event/5311057.json |

| 5311058 | 飞升线法图娜失败 | false | true | round_begin_ba | 1 | data/config/event/5311058.json |

| 5311059 | 废弃 | false | true | round_begin_ba | 1 | data/config/event/5311059.json |

| 5311060 | 飞升线夏玛失败 | false | true | round_begin_ba | 1 | data/config/event/5311060.json |

| 5311061 | 飞升线妻子的不满失败 | false | true | round_begin_ba | 1 | data/config/event/5311061.json |

| 5311062 | 飞升线奈费勒失败 | false | true | round_begin_ba | 1 | data/config/event/5311062.json |

| 5311063 | 飞升线万逝戒失败 | false | true | round_begin_ba | 1 | data/config/event/5311063.json |

| 5311064 | 飞升线被困的星神失败 | false | true | round_begin_ba | 1 | data/config/event/5311064.json |

| 5311065 | 飞升线罪孽失败 | false | true | round_begin_ba | 1 | data/config/event/5311065.json |

| 5311066 | 飞升线污渍失败 | false | true | round_begin_ba | 1 | data/config/event/5311066.json |

| 5311067 | 飞升线盖斯失败 | false | true | round_begin_ba | 1 | data/config/event/5311067.json |

| 5311068 | 飞升线扎齐伊成功 | false | true | round_begin_ba | 1 | data/config/event/5311068.json |

| 5311069 | 飞升线主角成功 | false | true | round_begin_ba | 1 | data/config/event/5311069.json |

| 5311070 | 飞升线玛希尔成功 | false | true | round_begin_ba | 1 | data/config/event/5311070.json |

| 5311071 | 飞升线百科全书目录成功 | false | true | round_begin_ba | 1 | data/config/event/5311071.json |

| 5311072 | 飞升线萨米尔成功 | false | true | round_begin_ba | 1 | data/config/event/5311072.json |

| 5311073 | 飞升线阿图娜尔成功 | false | true | round_begin_ba | 1 | data/config/event/5311073.json |

| 5311074 | 飞升线拉伊德成功 | false | true | round_begin_ba | 1 | data/config/event/5311074.json |

| 5311075 | 飞升线最后一天进入陶土之门成就幕后 | false | true | round_begin_ba | 1 | data/config/event/5311075.json |

| 5320001 | 领路者 | false | false | rite_end | 1 | data/config/event/5320001.json |

| 5320002 | 昔日之影 | false | false | rite_end | 1 | data/config/event/5320002.json |

| 5320003 | 抉择 | false | false | rite_end | 1 | data/config/event/5320003.json |

| 5320004 | 剧毒的果实 | false | false | card_clean | 1 | data/config/event/5320004.json |

| 5320005 | 剧毒的果实 | false | true | round_begin_ba | 1 | data/config/event/5320005.json |

| 5320006 | 询问妻子的意见 | false | false | round_begin_ba | 1 | data/config/event/5320006.json |

| 5320007 | 选择 | false | true | rite_end | 1 | data/config/event/5320007.json |

| 5320008 | 妻子的宽容 | false | true | round_begin_ba | 1 | data/config/event/5320008.json |

| 5320009 | 与法图娜的婚礼 | false | true | round_begin_ba | 1 | data/config/event/5320009.json |

| 5320010 | 与法图娜的婚礼 | false | false | round_begin_ba | 1 | data/config/event/5320010.json |

| 5320011 | 楷模 | false | false | rite_end | 1 | data/config/event/5320011.json |

| 5320012 | 不义之事 | false | false | rite_end | 1 | data/config/event/5320012.json |

| 5320013 | 正义必须得到伸张 | false | false | round_begin_ba | 1 | data/config/event/5320013.json |

| 5320014 | 轻易获得快乐 | false | false | rite_end | 1 | data/config/event/5320014.json |

| 5320015 | 我不是故意的 | false | false | rite_end | 1 | data/config/event/5320015.json |

| 5320016 | 家破人亡 | false | false | round_begin_ba | 1 | data/config/event/5320016.json |

| 5320017 | 逐日之徒 | false | false | rite_end | 1 | data/config/event/5320017.json |

| 5320019 | 一桩丑闻 | false | false | round_begin_ba | 1 | data/config/event/5320019.json |

| 5320020 | 第二次机会 | false | false | rite_end | 1 | data/config/event/5320020.json |

| 5320021 | 这么多的书…… | false | false | rite_end | 1 | data/config/event/5320021.json |

| 5320022 | 读书会 | false | false | round_begin_ba | 1 | data/config/event/5320022.json |

| 5320023 | 继续深造 | false | false | rite_end | 1 | data/config/event/5320023.json |

| 5320024 | 编修之苦 | false | false | rite_end | 1 | data/config/event/5320024.json |

| 5320025 | 发现的诱惑 | false | false | rite_end | 1 | data/config/event/5320025.json |

| 5320026 | 星灵之夜 | false | false | rite_end | 1 | data/config/event/5320026.json |

| 5320027 | 开小差 | false | false | rite_end | 1 | data/config/event/5320027.json |

| 5320028 | 一桩公开宣扬的复仇 | false | true | round_begin_ba | 1 | data/config/event/5320028.json |

| 5320029 | 激活廊下的故事 | false | false | round_begin_ba | 1 | data/config/event/5320029.json |

| 5320030 | 廊下的故事 | false | false | rite_end | 1 | data/config/event/5320030.json |

| 5320031 | 孤女复仇记 | false | false | round_begin_ba | 1 | data/config/event/5320031.json |

| 5320032 | 坦白 | false | true | rite_end | 1 | data/config/event/5320032.json |

| 5320033 | 意外的赏赐 | false | false | round_begin_ba | 1 | data/config/event/5320033.json |

| 5320034 | 意外的赏赐 | false | false | round_begin_ba | 1 | data/config/event/5320034.json |

| 5320035 | 腐臭的生意人 | false | false | round_begin_ba | 1 | data/config/event/5320035.json |

| 5320036 | 痛苦 | false | false | round_begin_ba | 1 | data/config/event/5320036.json |

| 5320037 | 复仇的滋味1 | false | false | round_begin_ba | 1 | data/config/event/5320037.json |

| 5320038 | 复仇的滋味2 | false | false | round_begin_ba | 1 | data/config/event/5320038.json |

| 5320039 | 复仇的滋味3 | false | false | round_begin_ba | 1 | data/config/event/5320039.json |

| 5320040 | 血墙 | false | false | round_begin_ba | 1 | data/config/event/5320040.json |

| 5320041 | 复仇的滋味3 | false | false | round_begin_ba | 1 | data/config/event/5320041.json |

| 5320042 | 滋味如何 | false | true | round_begin_ba | 1 | data/config/event/5320042.json |

| 5320043 | 法图娜声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320043.json |

| 5320044 | 扎齐伊声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320044.json |

| 5320045 | 鲁梅拉声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320045.json |

| 5320046 | 鲁梅拉在阴影中再触发 | false | false | round_begin_ba | 1 | data/config/event/5320046.json |

| 5320047 | 鲁梅拉在阴影中再触发 | false | false | round_begin_ba | 1 | data/config/event/5320047.json |

| 5320048 | 鲁梅拉在阴影中再触发 | false | false | round_begin_ba | 1 | data/config/event/5320048.json |

| 5320049 | 何为正义 | false | false | round_begin_ba | 1 | data/config/event/5320049.json |

| 5320050 | 另一封信 | false | false | round_begin_ba | 1 | data/config/event/5320050.json |

| 5320051 | 一封信 | false | false | round_begin_ba | 1 | data/config/event/5320051.json |

| 5320052 | 正义必须执行 | false | false | round_begin_ba | 1 | data/config/event/5320052.json |

| 5320053 | 恶名一阶段事件 |  | false | round_begin_ba | 1 | data/config/event/5320053.json |

| 5320054 | 下次再来 | false | false | round_begin_ba | 1 | data/config/event/5320054.json |

| 5320055 | 奈费勒大敌事件 | false | false | round_begin_ba | 1 | data/config/event/5320055.json |

| 5320056 | 奈费勒大敌事件再起 | false | false | card_clean | 1 | data/config/event/5320056.json |

| 5320057 | 铁头大敌事件 | false | false | round_begin_ba | 1 | data/config/event/5320057.json |

| 5320058 | 铁头大敌事件再起 | false | false | card_clean | 1 | data/config/event/5320058.json |

| 5320059 | 铁头的暗杀 | false | false | rite_end | 1 | data/config/event/5320059.json |

| 5320060 | 铁头的背叛 |  | false | round_begin_ba | 1 | data/config/event/5320060.json |

| 5320061 | 奈费勒大敌事件-重复阶段 | false | false | round_begin_ba | 1 | data/config/event/5320061.json |

| 5320062 | 铁头大敌事件-重复阶段 | false | false | round_begin_ba | 1 | data/config/event/5320062.json |

| 5320063 | 恶名2阶段事件 |  | false | round_begin_ba | 1 | data/config/event/5320063.json |

| 5320064 | 恶名2阶段事件-重复刷的时期 | false | false | round_begin_ba | 1 | data/config/event/5320064.json |

| 5320065 | 恶名3阶段事件-刺杀 | false | true | round_begin_ba | 1 | data/config/event/5320065.json |

| 5320066 | 恶名3阶段事件 |  | false | round_begin_ba | 1 | data/config/event/5320066.json |

| 5320067 | 恶名3阶段事件-重复刷的时期 | false | false | round_begin_ba | 1 | data/config/event/5320067.json |

| 5320068 | 恶名3阶段事件-重复刷的时期 | false | false | round_begin_ba | 1 | data/config/event/5320068.json |

| 5320069 | 罪恶滔天的俺寻思提示 |  | false | round_begin_ba | 1 | data/config/event/5320069.json |

| 5320070 | 罪恶滔天的俺寻思提示 |  | false | round_begin_ba | 1 | data/config/event/5320070.json |

| 5320071 | 背叛的黎明 | false | false | round_begin_ba | 1 | data/config/event/5320071.json |

| 5320072 | 善名1阶段事件 |  | false | round_begin_ba | 1 | data/config/event/5320072.json |

| 5320073 | 善名1阶段事件-重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320073.json |

| 5320074 | 善名2阶段事件 |  | false | round_begin_ba | 1 | data/config/event/5320074.json |

| 5320075 | 善名3阶段事件 |  | false | round_begin_ba | 1 | data/config/event/5320075.json |

| 5320076 | 侠名1阶段事件 |  | false | round_begin_ba | 1 | data/config/event/5320076.json |

| 5320077 | 岩石舍馆 | false | true | round_begin_ba | 1 | data/config/event/5320077.json |

| 5320078 | 青铜舍馆 | false | true | round_begin_ba | 1 | data/config/event/5320078.json |

| 5320079 | 白银舍馆 | false | true | round_begin_ba | 1 | data/config/event/5320079.json |

| 5320080 | 黄金舍馆 | false | true | round_begin_ba | 1 | data/config/event/5320080.json |

| 5320081 | 安全屋的俺寻思提示 |  | false | round_begin_ba | 1 | data/config/event/5320081.json |

| 5320082 | 侠名2的事件--罪犯的投奔 |  | false | round_begin_ba | 1 | data/config/event/5320082.json |

| 5320083 | 侠名2的事件--罪犯的投奔--重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320083.json |

| 5320084 | 权势2的事件--公文处理-首次处理 |  | false | round_begin_ba | 1 | data/config/event/5320084.json |

| 5320085 | 权势2的事件--公文处理-重复刷新 | false | false | round_begin_ba | 1 | data/config/event/5320085.json |

| 5320086 | 权势3的事件--宰相处理政务 | false | false | round_begin_ba | 1 | data/config/event/5320086.json |

| 5320087 | 权势3的事件--苏丹的猜忌 | false | false | round_begin_ba | 1 | data/config/event/5320087.json |

| 5320088 | 权势3的事件--苏丹的猜忌-重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320088.json |

| 5320089 | 权势3的事件--苏丹的猜忌-疲软的丑态 | false | false | card_clean | 1 | data/config/event/5320089.json |

| 5320090 | 权势3的事件--苏丹的猜忌-疲软的丑态 | false | false | round_begin_ba | 1 | data/config/event/5320090.json |

| 5320091 | 权势3的事件--苏丹让你成为宰相--宰相已死（废弃） | false | false | round_begin_ba | 1 | data/config/event/5320091.json |

| 5320092 | 权势3的事件--赤字滔天 | false | false | round_begin_ba | 1 | data/config/event/5320092.json |

| 5320093 | 权势3的事件--赤字滔天--重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320093.json |

| 5320094 | 权势3的事件--苏丹让你成为宰相--宰相还没死死（废弃） | false | false | round_begin_ba | 1 | data/config/event/5320094.json |

| 5320095 | 苏丹的猜忌卡牌消失后的死亡 | false | true | round_begin_ba | 1 | data/config/event/5320095.json |

| 5320096 | 苏丹猜忌正常消解卡牌会重置计数器 | false | true | round_begin_ba | 1 | data/config/event/5320096.json |

| 5320097 | 法图娜离去，扎齐伊也离去 |  | false | round_begin_ba | 1 | data/config/event/5320097.json |

| 5320098 | 扎齐伊离去，法图娜也离去 |  | false | round_begin_ba | 1 | data/config/event/5320098.json |

| 5320099 | 鲁梅拉解读完星卷的3天后 | false | false | round_begin_ba | 1 | data/config/event/5320099.json |

| 5320100 | 检定每日囚牢是否开启 | false | true | round_begin_ba | 1 | data/config/event/5320100.json |

| 5320101 | 妻子死亡的反馈 | false | true | round_begin_ba | 1 | data/config/event/5320101.json |

| 5320102 | 如果妻子存活，关闭妻子死亡的反馈 | false | true | round_begin_ba | 1 | data/config/event/5320102.json |

| 5320103 | 娜依拉声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320103.json |

| 5320104 | 帝国之花 | false | false | rite_end | 1 | data/config/event/5320104.json |

| 5320105 | 娜依拉声望事件--未归人1 | false | false | round_begin_ba | 1 | data/config/event/5320105.json |

| 5320106 | 娜依拉声望事件--未归人1 | false | true | round_begin_ba | 1 | data/config/event/5320106.json |

| 5320107 | 娜依拉声望事件--触发对名单内npc死亡的回应 | false | true | round_begin_ba | 1 | data/config/event/5320107.json |

| 5320108 | 娜依拉声望事件--妻子死亡的回应1 | false | false | card_clean | 1 | data/config/event/5320108.json |

| 5320109 | 娜依拉声望事件--妻子死亡的回应2 | false | false | round_begin_ba | 1 | data/config/event/5320109.json |

| 5320110 | 娜依拉声望事件--莎姬死亡的回应1 | false | false | card_clean | 1 | data/config/event/5320110.json |

| 5320111 | 娜依拉声望事件--莎姬死亡的回应2 | false | false | round_begin_ba | 1 | data/config/event/5320111.json |

| 5320112 | 娜依拉声望事件--萨达尔尼死亡的回应1 | false | false | card_clean | 1 | data/config/event/5320112.json |

| 5320113 | 娜依拉声望事件--萨达尔尼死亡的回应2 | false | false | round_begin_ba | 1 | data/config/event/5320113.json |

| 5320114 | 娜依拉声望事件--拜铃耶死亡的回应1 | false | false | card_clean | 1 | data/config/event/5320114.json |

| 5320115 | 娜依拉声望事件--拜铃耶死亡的回应2 | false | false | round_begin_ba | 1 | data/config/event/5320115.json |

| 5320116 | 娜依拉声望事件--夏玛死亡的回应1 | false | false | card_clean | 1 | data/config/event/5320116.json |

| 5320117 | 娜依拉声望事件--夏玛死亡的回应2 | false | false | round_begin_ba | 1 | data/config/event/5320117.json |

| 5320118 | 娜依拉声望事件--贾丽拉死亡的回应1 | false | false | card_clean | 1 | data/config/event/5320118.json |

| 5320119 | 娜依拉声望事件--贾丽拉死亡的回应2 | false | false | round_begin_ba | 1 | data/config/event/5320119.json |

| 5320120 | 娜依拉声望事件--死亡计数 |  | false | card_clean | 1 | data/config/event/5320120.json |

| 5320121 | 娜依拉声望事件--死亡计数 |  | false | card_clean | 1 | data/config/event/5320121.json |

| 5320122 | 娜依拉声望事件--死亡计数 |  | false | card_clean | 1 | data/config/event/5320122.json |

| 5320123 | 娜依拉声望事件--死亡计数 |  | false | card_clean | 1 | data/config/event/5320123.json |

| 5320124 | 娜依拉声望事件--死亡计数 |  | false | card_clean | 1 | data/config/event/5320124.json |

| 5320125 | 娜依拉声望事件--死亡计数 |  | false | card_clean | 1 | data/config/event/5320125.json |

| 5320126 | 娜依拉声望事件--达成杀夫条件 | false | false | round_begin_ba | 1 | data/config/event/5320126.json |

| 5320127 | 娜依拉声望事件--杀夫激活 | false | false | rite_end | 1 | data/config/event/5320127.json |

| 5320128 | 娜依拉声望事件--恶毒的花嫁 | false | false | round_begin_ba | 1 | data/config/event/5320128.json |

| 5320129 | 娜依拉声望事件--恶毒的花嫁-满意 | false | false | round_begin_ba | 1 | data/config/event/5320129.json |

| 5320130 | 娜依拉声望事件--大肆吹捧 | false | true | round_begin_ba | 1 | data/config/event/5320130.json |

| 5320131 | 娜依拉声望事件--娜依拉的战斗 | false | true | round_begin_ba | 1 | data/config/event/5320131.json |

| 5320132 | 娜依拉声望事件--别丢我的脸 | false | true | round_begin_ba | 1 | data/config/event/5320132.json |

| 5320133 | 娜依拉声望事件--世界不止属于男人 | false | true | round_begin_ba | 1 | data/config/event/5320133.json |

| 5320134 | 娜依拉声望事件--恶毒的花嫁-不满意 | false | false | round_begin_ba | 1 | data/config/event/5320134.json |

| 5320135 | 娜依拉声望事件--恶毒的花嫁-不满意 | false | true | round_begin_ba | 1 | data/config/event/5320135.json |

| 5320136 | 娜依拉声望事件--恶毒的花嫁-不满意 | false | true | round_begin_ba | 1 | data/config/event/5320136.json |

| 5320137 | 娜依拉声望事件--全能老妇 |  | false | round_begin_ba | 1 | data/config/event/5320137.json |

| 5320138 | 娜依拉声望事件--意外的拜访 | false | false | round_begin_ba | 1 | data/config/event/5320138.json |

| 5320139 | 娜依拉声望事件--意外的拜访2 | false | false | round_begin_ba | 1 | data/config/event/5320139.json |

| 5320140 | 娜依拉声望事件--唯一裂隙 | false | false | round_begin_ba | 1 | data/config/event/5320140.json |

| 5320141 | 娜依拉声望事件--唯一裂隙 | false | true | round_begin_ba | 1 | data/config/event/5320141.json |

| 5320142 | 娜依拉声望事件--唯一裂隙 | false | false | round_begin_ba | 1 | data/config/event/5320142.json |

| 5320143 | 娜依拉声望事件--逝去之物 | false | true | round_begin_ba | 1 | data/config/event/5320143.json |

| 5320144 | 娜依拉声望事件--扭曲的想象力 | false | false | rite_end | 1 | data/config/event/5320144.json |

| 5320145 | 娜依拉声望事件--扭曲的想象力-名单 | false | true | round_begin_ba | 1 | data/config/event/5320145.json |

| 5320146 | 娜依拉声望事件--帝国的勇士 | false | false | rite_end | 1 | data/config/event/5320146.json |

| 5320147 | 娜依拉声望事件--泄露的秘密 | false | false | round_begin_ba | 1 | data/config/event/5320147.json |

| 5320148 | 娜依拉声望事件--帝国的勇士-重复触发 | false | false | round_begin_ba | 1 | data/config/event/5320148.json |

| 5320149 | 娜依拉声望事件--帝国的勇士-重复触发 | false | true | round_begin_ba | 1 | data/config/event/5320149.json |

| 5320150 | 娜依拉声望事件--这是真的？ | false | false | round_begin_ba | 1 | data/config/event/5320150.json |

| 5320151 | 娜依拉声望事件--帝国的勇士-重复触发 | false | false | round_begin_ba | 1 | data/config/event/5320151.json |

| 5320152 | 娜依拉声望事件--帝国的勇士-重复触发 | false | true | round_begin_ba | 1 | data/config/event/5320152.json |

| 5320153 | 娜依拉声望事件-促成交欢 |  | false | round_begin_ba | 1 | data/config/event/5320153.json |

| 5320154 | 娜依拉声望事件-促成交欢 | false | true | round_begin_ba | 1 | data/config/event/5320154.json |

| 5320155 | 救济日 |  | false | round_begin_ba | 1 | data/config/event/5320155.json |

| 5320156 | 铁头-善1-救济日重复触发 | false | false | round_begin_ba | 1 | data/config/event/5320156.json |

| 5320157 | 铁头声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320157.json |

| 5320158 | 铁头声望事件--这粥的味道 | false | false | rite_end | 1 | data/config/event/5320158.json |

| 5320159 | 铁头声望事件--石餐盒 | false | false | rite_end | 1 | data/config/event/5320159.json |

| 5320160 | 铁头声望事件--错位的水果 | false | false | round_begin_ba | 1 | data/config/event/5320160.json |

| 5320161 | 小圆声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320161.json |

| 5320162 | 小圆声望事件-让我尝尝 | false | false | rite_end | 1 | data/config/event/5320162.json |

| 5320163 | 铁头声望事件-巨大的玩具 | false | true | round_begin_ba | 1 | data/config/event/5320163.json |

| 5320164 | 铁头声望事件--新鲜货 | false | false | round_begin_ba | 1 | data/config/event/5320164.json |

| 5320165 | 铁头声望事件-石餐盒 | false | true | round_begin_ba | 1 | data/config/event/5320165.json |

| 5320166 | 铁头声望事件--大批新鲜货 | false | false | round_begin_ba | 1 | data/config/event/5320166.json |

| 5320167 | 铁头声望事件-大量石餐盒 | false | false | round_begin_ba | 1 | data/config/event/5320167.json |

| 5320168 | 铁头声望事件--沙尘往事 | false | false | rite_end | 1 | data/config/event/5320168.json |

| 5320169 | 铁头声望事件--主人的宴会 | false | false | round_begin_ba | 1 | data/config/event/5320169.json |

| 5320170 | 铁头声望事件--是奴隶，也是主人 | false | false | rite_end | 1 | data/config/event/5320170.json |

| 5320171 | 铁头声望事件--铁头死了军队会跑 | false | false | round_begin_ba | 1 | data/config/event/5320171.json |

| 5320172 | 铁头声望事件--激活美味的救济日 | false | false | round_begin_ba | 1 | data/config/event/5320172.json |

| 5320173 | 小圆声望事件--不安的梦 |  | false | round_begin_ba | 1 | data/config/event/5320173.json |

| 5320174 | 小圆声望事件--石榴糖浆 | false | false | round_begin_ba | 1 | data/config/event/5320174.json |

| 5320175 | 小圆声望事件--梦中之狼 | false | false | rite_end | 1 | data/config/event/5320175.json |

| 5320176 | 小圆声望事件--庭院树下 | false | false | round_begin_ba | 1 | data/config/event/5320176.json |

| 5320177 | 小圆声望事件--狼目 | false | false | round_begin_ba | 1 | data/config/event/5320177.json |

| 5320178 | 小圆声望事件--女人的谈判 | false | false | round_begin_ba | 1 | data/config/event/5320178.json |

| 5320179 | 小圆声望事件--成婚 | false | true | round_begin_ba | 1 | data/config/event/5320179.json |

| 5320180 | 小圆声望事件--夜袭 | false | false | round_begin_ba | 1 | data/config/event/5320180.json |

| 5320181 | 小圆声望事件--小圆失踪 | false | false | round_begin_ba | 1 | data/config/event/5320181.json |

| 5320182 | 小圆声望事件--殴斗 | false | false | round_begin_ba | 1 | data/config/event/5320182.json |

| 5320183 | 小圆声望事件--微小的波澜 | false | false | round_begin_ba | 1 | data/config/event/5320183.json |

| 5320184 | 小圆声望事件--微小的波澜2 | false | false | round_begin_ba | 1 | data/config/event/5320184.json |

| 5320185 | 小圆声望事件--恶意的赞扬 | false | false | round_begin_ba | 1 | data/config/event/5320185.json |

| 5320186 | 小圆声望事件--悲伤的铁头 | false | false | round_begin_ba | 1 | data/config/event/5320186.json |

| 5320187 | 小圆声望事件--心之声 | false | false | rite_end | 1 | data/config/event/5320187.json |

| 5320188 | 小圆声望事件--激活这是我的主意 | false | false | round_begin_ba | 1 | data/config/event/5320188.json |

| 5320189 | 小圆声望事件--自由之人 | false | false | round_begin_ba | 1 | data/config/event/5320189.json |

| 5320190 | 小圆声望事件--闭上的那只眼睛 | false | false | round_begin_ba | 1 | data/config/event/5320190.json |

| 5320191 | 奈费勒声望事件--初见--杀戮 |  | false | card_clean | 1 | data/config/event/5320191.json |

| 5320192 | 奈费勒声望事件--初见--纵欲 |  | false | card_clean | 1 | data/config/event/5320192.json |

| 5320193 | 奈费勒声望事件--初见--奢靡 |  | false | card_clean | 1 | data/config/event/5320193.json |

| 5320194 | 奈费勒声望事件--初见--征服 |  | false | card_clean | 1 | data/config/event/5320194.json |

| 5320195 | 奈费勒声望事件--冗长的询问 | false | false | round_begin_ba | 1 | data/config/event/5320195.json |

| 5320196 | 奈费勒声望事件--好人蒙冤 | false | false | round_begin_ba | 1 | data/config/event/5320196.json |

| 5320197 | 奈费勒声望事件--男人本应如此 | false | false | round_begin_ba | 1 | data/config/event/5320197.json |

| 5320198 | 奈费勒声望事件--宫门募捐 | false | false | round_begin_ba | 1 | data/config/event/5320198.json |

| 5320199 | 奈费勒声望事件--花点钱有什么不好 | false | false | round_begin_ba | 1 | data/config/event/5320199.json |

| 5320200 | 奈费勒声望事件--不支持的队伍 | false | false | round_begin_ba | 1 | data/config/event/5320200.json |

| 5320201 | 奈费勒声望事件--这是至高的荣耀 | false | false | round_begin_ba | 1 | data/config/event/5320201.json |

| 5320202 | 奈费勒声望事件--冤家路窄 | false | false | round_begin_ba | 1 | data/config/event/5320202.json |

| 5320203 | 奈费勒声望事件--无用的施舍延时触发器 | false | false | round_begin_ba | 1 | data/config/event/5320203.json |

| 5320204 | 奈费勒声望事件--无用的施舍 | false | true | round_begin_ba | 1 | data/config/event/5320204.json |

| 5320205 | 奈费勒声望事件--无用的施舍-奈费勒的来信 | false | false | round_begin_ba | 1 | data/config/event/5320205.json |

| 5320206 | 奈费勒声望事件--思索与探求 | false | false | rite_end | 1 | data/config/event/5320206.json |

| 5320207 | 奈费勒声望事件--思索与探求 | false | false | rite_end | 1 | data/config/event/5320207.json |

| 5320208 | 奈费勒声望事件--思索与探求 | false | false | rite_end | 1 | data/config/event/5320208.json |

| 5320209 | 奈费勒声望事件--母亲的水滴重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320209.json |

| 5320210 | 奈费勒声望事件--奶与蛋 | false | false | round_begin_ba | 1 | data/config/event/5320210.json |

| 5320211 | 奈费勒声望事件--稀疏的队伍 | false | true | round_begin_ba | 1 | data/config/event/5320211.json |

| 5320212 | 奈费勒声望事件--稀疏的队伍重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320212.json |

| 5320213 | 奈费勒声望事件--带来的改变 | false | false | round_begin_ba | 1 | data/config/event/5320213.json |

| 5320214 | 奈费勒声望事件--带来的改变 | false | true | round_begin_ba | 1 | data/config/event/5320214.json |

| 5320215 | 奈费勒声望事件--神之恩重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320215.json |

| 5320216 | 奈费勒声望事件--正教传播事件 | false | false | round_begin_ba | 1 | data/config/event/5320216.json |

| 5320217 | 奈费勒声望事件--密教传播事件 | false | false | round_begin_ba | 1 | data/config/event/5320217.json |

| 5320218 | 奈费勒声望事件--稀疏的队伍 | false | true | round_begin_ba | 1 | data/config/event/5320218.json |

| 5320219 | 奈费勒声望事件--未能改变的 | false | false | round_begin_ba | 1 | data/config/event/5320219.json |

| 5320220 | 奈费勒声望事件--未能改变的 | false | true | round_begin_ba | 1 | data/config/event/5320220.json |

| 5320221 | 奈费勒声望事件--黄金的工具重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320221.json |

| 5320222 | 奈费勒声望事件--粗糙的心意 | false | false | round_begin_ba | 1 | data/config/event/5320222.json |

| 5320223 | 奈费勒声望事件--稀疏的队伍3 | false | true | round_begin_ba | 1 | data/config/event/5320223.json |

| 5320224 | 奈费勒声望事件--稀疏的队伍3重复刷 | false | false | round_begin_ba | 1 | data/config/event/5320224.json |

| 5320225 | 奈费勒声望事件--带来希望的 | false | false | round_begin_ba | 1 | data/config/event/5320225.json |

| 5320226 | 奈费勒声望事件--带来希望的 | false | true | round_begin_ba | 1 | data/config/event/5320226.json |

| 5320227 | 奈费勒声望事件--火焰大王名声显赫 | false | false | rite_end | 1 | data/config/event/5320227.json |

| 5320228 | 奈费勒声望事件--团结他们的 | false | true | round_begin_ba | 1 | data/config/event/5320228.json |

| 5320229 | 奈费勒声望事件--火焰大王的呼唤 | false | true | round_begin_ba | 1 | data/config/event/5320229.json |

| 5320230 | 奈费勒声望事件--清流交汇 | false | false | round_begin_ba | 1 | data/config/event/5320230.json |

| 5320231 | 奈费勒声望事件--泄露的消息3 | false | false | round_begin_ba | 1 | data/config/event/5320231.json |

| 5320232 | 奈费勒声望事件--获释的消息 | false | false | round_begin_ba | 1 | data/config/event/5320232.json |

| 5320233 | 奈费勒声望事件-年轻的叛徒 | false | false | round_begin_ba | 1 | data/config/event/5320233.json |

| 5320234 | 奈费勒声望事件--泄露的消息1 | false | false | round_begin_ba | 1 | data/config/event/5320234.json |

| 5320235 | 奈费勒声望事件--泄露的消息2 | false | false | round_begin_ba | 1 | data/config/event/5320235.json |

| 5320236 | 奈费勒声望事件--恶意的捉弄 |  | false | round_begin_ba | 1 | data/config/event/5320236.json |

| 5320237 | 奈费勒声望事件--恶意的捉弄 | false | false | round_begin_ba | 1 | data/config/event/5320237.json |

| 5320238 | 奈费勒声望事件--恶意的玩笑 | false | false | round_begin_ba | 1 | data/config/event/5320238.json |

| 5320239 | 奈费勒声望事件--同盟还是敌人 | false | false | round_begin_ba | 1 | data/config/event/5320239.json |

| 5320240 | 奈费勒声望事件--伏击 | false | false | round_begin_ba | 1 | data/config/event/5320240.json |

| 5320241 | 奈费勒声望事件--伏击 | false | false | round_begin_ba | 1 | data/config/event/5320241.json |

| 5320242 | 奈费勒--空椅子 |  | false | round_begin_ba | 1 | data/config/event/5320242.json |

| 5320243 | 奈费勒--脏兮兮的空椅子 |  | false | round_begin_ba | 1 | data/config/event/5320243.json |

| 5320244 | 奈费勒--奈费勒的谢礼 | false | false | round_begin_ba | 1 | data/config/event/5320244.json |

| 5320245 | 奈费勒--一则蹊跷的新闻 | false | false | round_begin_ba | 1 | data/config/event/5320245.json |

| 5320246 | 奈费勒声望事件--初见--纵欲 |  | false | card_clean | 1 | data/config/event/5320246.json |

| 5320247 | 奈费勒声望事件-思想的苗圃 |  | false | round_begin_ba | 1 | data/config/event/5320247.json |

| 5320248 | 奈费勒声望事件-为希望而战 | false | true | round_begin_ba | 1 | data/config/event/5320248.json |

| 5320249 | 奈费勒声望事件-思想的苗圃2 |  | false | round_begin_ba | 1 | data/config/event/5320249.json |

| 5320250 | 奈费勒声望事件-最后的愿望 |  | false | round_begin_ba | 1 | data/config/event/5320250.json |

| 5320251 | 苏丹猜忌的检定 |  | false | card_clean | 1 | data/config/event/5320251.json |

| 5320252 | 承阳武士-拔剑 | false | false | rite_end | 1 | data/config/event/5320252.json |

| 5320253 | 宫廷-索要妃子-迎接莎姬 | false | true | round_begin_ba | 1 | data/config/event/5320253.json |

| 5320254 | 宫廷-索要妃子-欲望或者野心 | false | true | round_begin_ba | 1 | data/config/event/5320254.json |

| 5320255 | 宫廷-索要妃子-黄金体验 | false | true | round_begin_ba | 1 | data/config/event/5320255.json |

| 5320256 | 莎姬的礼物 | false | false | round_begin_ba | 1 | data/config/event/5320256.json |

| 5320257 | 宫廷-索要妃子-要答应莎姬的请求么 | false | false | rite_end | 1 | data/config/event/5320257.json |

| 5320258 | 宫廷-索要妃子-莎姬的催促 | false | false | round_begin_ba | 1 | data/config/event/5320258.json |

| 5320259 | 宫廷-索要妃子-莎姬的催促 | false | false | round_begin_ba | 1 | data/config/event/5320259.json |

| 5320260 | 宫廷-索要妃子-莎姬的催促 | false | false | round_begin_ba | 1 | data/config/event/5320260.json |

| 5320261 | 宫廷-索要妃子-莎姬的死亡 | false | false | round_begin_ba | 1 | data/config/event/5320261.json |

| 5320262 | 宫廷-索要妃子-调查苏丹的奴隶 | false | false | rite_end | 1 | data/config/event/5320262.json |

| 5320263 | 宫廷-索要妃子-调查苏丹的避孕的方法 | false | false | rite_end | 1 | data/config/event/5320263.json |

| 5320264 | 宫廷-索要妃子-星星的秘密 | false | false | round_begin_ba | 1 | data/config/event/5320264.json |

| 5320265 | 宫廷-索要妃子-星星的信号 | false | false | round_begin_ba | 1 | data/config/event/5320265.json |

| 5320266 | 宫廷-索要妃子-书店偶遇 | false | false | round_begin_ba | 1 | data/config/event/5320266.json |

| 5320267 | 宫廷-索要妃子-急迫的欢愉（废弃） | false | true | round_begin_ba | 1 | data/config/event/5320267.json |

| 5320268 | 宫廷-索要妃子-监听是否适用了纵欲卡 | false | false | card_clean | 1 | data/config/event/5320268.json |

| 5320269 | 宫廷-索要妃子-最后一步 | false | false | round_begin_ba | 1 | data/config/event/5320269.json |

| 5320270 | 宫廷-索要妃子-契约完成 | false | false | round_begin_ba | 1 | data/config/event/5320270.json |

| 5320271 | 宫廷-索要妃子-苏丹奴隶的提示 | false | false | round_begin_ba | 1 | data/config/event/5320271.json |

| 5320272 | 宫廷-索要妃子-苏丹奴隶的提示 | false | false | round_begin_ba | 1 | data/config/event/5320272.json |

| 5320273 | 宫廷-索要妃子-报复来临 | false | false | round_begin_ba | 1 | data/config/event/5320273.json |

| 5320274 | 宫廷-索要妃子-销毁圣像 | false | false | round_begin_ba | 1 | data/config/event/5320274.json |

| 5320275 | 宫廷-索要妃子-仿制 | false | false | round_begin_ba | 1 | data/config/event/5320275.json |

| 5320276 | 宫廷-索要妃子-莎姬拜访 | false | false | round_begin_ba | 1 | data/config/event/5320276.json |

| 5320277 | 宫廷-索要妃子-苏丹的奴隶事后感谢 | false | false | round_begin_ba | 1 | data/config/event/5320277.json |

| 5320278 | 宫廷-索要妃子-苏丹的奴隶事后感谢 | false | false | round_begin_ba | 1 | data/config/event/5320278.json |

| 5320279 | 星之衰 | false | true | rite_end | 1 | data/config/event/5320279.json |

| 5320280 | 星之衰 | false | false | round_begin_ba | 1 | data/config/event/5320280.json |

| 5320281 | 莎姬的邀约 | false | false | round_begin_ba | 1 | data/config/event/5320281.json |

| 5320282 | 可疑的房租 |  | false | rite_end | 1 | data/config/event/5320282.json |

| 5320283 | 跑路的巴拉特 | false | false | round_begin_ba | 1 | data/config/event/5320283.json |

| 5320284 | 被捕的异国商人 | false | false | round_begin_ba | 1 | data/config/event/5320284.json |

| 5320285 | 不安的访客 | false | false | round_begin_ba | 1 | data/config/event/5320285.json |

| 5320286 | 苏丹的问询 | false | false | round_begin_ba | 1 | data/config/event/5320286.json |

| 5320287 | 苏丹的追问 | false | false | round_begin_ba | 1 | data/config/event/5320287.json |

| 5320288 | 安的噩耗 | false | false | round_begin_ba | 1 | data/config/event/5320288.json |

| 5320289 | 诺言 | false | false | round_begin_ba | 1 | data/config/event/5320289.json |

| 5320290 | 诺言 | false | false | round_begin_ba | 1 | data/config/event/5320290.json |

| 5320291 | 阔别已久 | false | false | round_begin_ba | 1 | data/config/event/5320291.json |

| 5320292 | 可疑的收入 |  | false | rite_end | 1 | data/config/event/5320292.json |

| 5320293 | 诗人与美食 |  | false | rite_end | 1 | data/config/event/5320293.json |

| 5320294 | 诗人与美食 | false | false | round_begin_ba | 1 | data/config/event/5320294.json |

| 5320295 | 诗人与美食 | false | false | round_begin_ba | 1 | data/config/event/5320295.json |

| 5320296 | 诗人与美食 | false | true | round_begin_ba | 1 | data/config/event/5320296.json |

| 5320297 | 诗人与美食 | false | true | round_begin_ba | 1 | data/config/event/5320297.json |

| 5320298 | 倒胃口 | false | false | round_begin_ba | 1 | data/config/event/5320298.json |

| 5320299 | 诗人与美人 |  | false | round_begin_ba | 1 | data/config/event/5320299.json |

| 5320300 | 诗人与美人 | false | true | round_begin_ba | 1 | data/config/event/5320300.json |

| 5320301 | 够了！够了！ | false | false | rite_end | 3 | data/config/event/5320301.json |

| 5320302 | 爱的教育 | false | false | round_begin_ba | 1 | data/config/event/5320302.json |

| 5320303 | 羊的抱怨 | false | false | rite_end | 1 | data/config/event/5320303.json |

| 5320304 | 青楼诗人 | false | false | round_begin_ba | 1 | data/config/event/5320304.json |

| 5320305 | 教学的工作 | false | false | round_begin_ba | 1 | data/config/event/5320305.json |

| 5320306 | 诗歌审查员 | false | false | round_begin_ba | 1 | data/config/event/5320306.json |

| 5320307 | 宫廷诗人 | false | false | round_begin_ba | 1 | data/config/event/5320307.json |

| 5320308 | 时机成熟了 | false | false | round_begin_ba | 1 | data/config/event/5320308.json |

| 5320309 | 选择布缇娜 | false | true | round_begin_ba | 1 | data/config/event/5320309.json |

| 5320310 | 选择奈费勒 | false | true | round_begin_ba | 1 | data/config/event/5320310.json |

| 5320311 | 选择阿卜德 | false | true | round_begin_ba | 1 | data/config/event/5320311.json |

| 5320312 | 选择苏丹 | false | true | round_begin_ba | 1 | data/config/event/5320312.json |

| 5320313 | 生气的羊肉炉 |  | false | round_begin_ba | 1 | data/config/event/5320313.json |

| 5320314 | 诗人登门 | false | false | round_begin_ba | 1 | data/config/event/5320314.json |

| 5320315 | 奇怪的攻击 | false | false | rite_end | 1 | data/config/event/5320315.json |

| 5320316 | 和咩咩对谈 | false | false | rite_end | 1 | data/config/event/5320316.json |

| 5320317 | 命运的诗集 | false | false | rite_end | 1 | data/config/event/5320317.json |

| 5320318 | 你怎么敢咩 | false | false | rite_end | 1 | data/config/event/5320318.json |

| 5320319 | 攻击间隙 | false | false | rite_end | 1 | data/config/event/5320319.json |

| 5320320 | 羊肉炉的恶意 | false | false | rite_end | 1 | data/config/event/5320320.json |

| 5320321 | 命运变动 | false | false | round_begin_ba | 1 | data/config/event/5320321.json |

| 5320322 | 我也来一首 |  | false | rite_end | 1 | data/config/event/5320322.json |

| 5320323 | 可爱的蹄子 | false | false | round_begin_ba | 1 | data/config/event/5320323.json |

| 5320324 | 可疑的钱币 |  | false | round_begin_ba | 1 | data/config/event/5320324.json |

| 5320325 | 难解之意 |  | false | round_begin_ba | 1 | data/config/event/5320325.json |

| 5320326 | 奇怪的流言 | false | false | rite_end | 1 | data/config/event/5320326.json |

| 5320327 | 午夜欢宴 | false | true | round_begin_ba | 1 | data/config/event/5320327.json |

| 5320328 | 奇怪的流言 | false | false | rite_end | 1 | data/config/event/5320328.json |

| 5320329 | 凡人的武器 | false | false | rite_end | 1 | data/config/event/5320329.json |

| 5320330 | 赴宴 | false | false | round_begin_ba | 1 | data/config/event/5320330.json |

| 5320331 | 阿萨尔的歉意 | false | false | round_begin_ba | 1 | data/config/event/5320331.json |

| 5320332 | 百科全书 | false | false | round_begin_ba | 1 | data/config/event/5320332.json |

| 5320333 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320333.json |

| 5320334 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320334.json |

| 5320335 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320335.json |

| 5320336 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320336.json |

| 5320337 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320337.json |

| 5320338 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320338.json |

| 5320339 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320339.json |

| 5320340 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320340.json |

| 5320341 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320341.json |

| 5320342 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320342.json |

| 5320343 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320343.json |

| 5320344 | 百科全书已集齐的页 | false | true | round_begin_ba | 1 | data/config/event/5320344.json |

| 5320345 | 另一位爱书的权臣 |  | false | round_begin_ba | 1 | data/config/event/5320345.json |

| 5320346 | 要阻止他吗 | false | false | rite_end | 1 | data/config/event/5320346.json |

| 5320347 | 归于木林 | false | true | round_begin_ba | 1 | data/config/event/5320347.json |

| 5320348 | 不合时宜的思想 | false | false | round_begin_ba | 1 | data/config/event/5320348.json |

| 5320349 | 书窖里的窃贼 | false | false | round_begin_ba | 1 | data/config/event/5320349.json |

| 5320350 | 提醒 | false | false | round_begin_ba | 1 | data/config/event/5320350.json |

| 5320351 | 可怜的阿萨尔 | false | false | round_begin_ba | 1 | data/config/event/5320351.json |

| 5320352 | 一本书的诞生-1 |  | false | round_begin_ba | 1 | data/config/event/5320352.json |

| 5320353 | 一本书的诞生-2 | false | false | round_begin_ba | 1 | data/config/event/5320353.json |

| 5320354 | 大麦 | false | false | round_begin_ba | 1 | data/config/event/5320354.json |

| 5320355 | 第一次版税 | false | false | round_begin_ba | 1 | data/config/event/5320355.json |

| 5320356 | 盗版横行 | false | false | round_begin_ba | 1 | data/config/event/5320356.json |

| 5320357 | 不受欢迎的小书 | false | false | round_begin_ba | 1 | data/config/event/5320357.json |

| 5320358 | 也许该分享给她 | false | true | round_begin_ba | 1 | data/config/event/5320358.json |

| 5320359 | 思考之后 | false | false | round_begin_ba | 1 | data/config/event/5320359.json |

| 5320360 | 后续版税 | false | false | round_begin_ba | 1 | data/config/event/5320360.json |

| 5320361 | 故事的赞助人 | false | true | round_begin_ba | 1 | data/config/event/5320361.json |

| 5320362 | 命运的书店不处理的诅咒 | false | true | round_begin_ba | 1 | data/config/event/5320362.json |

| 5320363 | 一桩纠纷 |  | false | round_begin_ba | 1 | data/config/event/5320363.json |

| 5320364 | 街边的风 | false | false | round_begin_ba | 1 | data/config/event/5320364.json |

| 5320365 | 马尔基娜来找你 | false | false | round_begin_ba | 1 | data/config/event/5320365.json |

| 5320366 | 马尔基娜事件提示 | false | false | round_begin_ba | 1 | data/config/event/5320366.json |

| 5320367 | 更深的塑造 | false | true | round_begin_ba | 1 | data/config/event/5320367.json |

| 5320368 | 善良的样子-不满足 | false | true | round_begin_ba | 1 | data/config/event/5320368.json |

| 5320369 | 恶名的样子-不满足 | false | true | round_begin_ba | 1 | data/config/event/5320369.json |

| 5320370 | 权势的样子-不满足 | false | true | round_begin_ba | 1 | data/config/event/5320370.json |

| 5320371 | 侠名的样子-不满足 | false | true | round_begin_ba | 1 | data/config/event/5320371.json |

| 5320372 | 善良的样子-已完成 | false | true | round_begin_ba | 1 | data/config/event/5320372.json |

| 5320373 | 恶人的样子-已完成 | false | true | round_begin_ba | 1 | data/config/event/5320373.json |

| 5320374 | 权势的样子-已完成 | false | true | round_begin_ba | 1 | data/config/event/5320374.json |

| 5320375 | 强侠的样子-已完成 | false | true | round_begin_ba | 1 | data/config/event/5320375.json |

| 5320376 | 额外的问题 | false | false | rite_end | 1 | data/config/event/5320376.json |

| 5320377 | 额外的问题 | false | false | rite_end | 1 | data/config/event/5320377.json |

| 5320378 | 某位取悦君主的女性…… | false | true | rite_end | 1 | data/config/event/5320378.json |

| 5320379 | 某位持剑的铁卫…… | false | true | rite_end | 1 | data/config/event/5320379.json |

| 5320380 | 某位掌权的老爷…… | false | true | rite_end | 1 | data/config/event/5320380.json |

| 5320381 | 内与外，人与神 | false | false | round_begin_ba | 1 | data/config/event/5320381.json |

| 5320382 | 访圣 | false | false | rite_end | 1 | data/config/event/5320382.json |

| 5320383 | 百科全书--阿萨尔 | false | false | round_begin_ba | 1 | data/config/event/5320383.json |

| 5320384 | 百科全书--全收集 | false | false | round_begin_ba | 1 | data/config/event/5320384.json |

| 5320385 | 权的总结 | false | false | rite_end | 1 | data/config/event/5320385.json |

| 5320386 | 内与外，人与神 | false | false | round_begin_ba | 1 | data/config/event/5320386.json |

| 5320390 | 游猎会 | false | false | round_begin_ba | 1 | data/config/event/5320390.json |

| 5320391 | 用来关闭游猎会 | false | false | round_begin_ba | 1 | data/config/event/5320391.json |

| 5320392 | 用来关闭游猎会 | false | true | rite_end | 1 | data/config/event/5320392.json |

| 5320393 | 游猎之后 | false | false | rite_end | 1 | data/config/event/5320393.json |

| 5320394 | 古利斯-虎皮献给苏丹后 | false | false | round_begin_ba | 1 | data/config/event/5320394.json |

| 5320395 | 游猎之后 | false | false | rite_end | 1 | data/config/event/5320395.json |

| 5320396 | 借一步说话 | false | false | rite_end | 1 | data/config/event/5320396.json |

| 5320397 | 宫中的传闻 | false | false | round_begin_ba | 1 | data/config/event/5320397.json |

| 5320398 | 奴隶阿本分 | false | false | rite_end | 1 | data/config/event/5320398.json |

| 5320399 | 古利斯地兴趣 | false | false | round_begin_ba | 1 | data/config/event/5320399.json |

| 5320400 | 古利斯地兴趣-夜酒 | false | true | round_begin_ba | 1 | data/config/event/5320400.json |

| 5320401 | 古利斯地兴趣-赌狗 | false | true | round_begin_ba | 1 | data/config/event/5320401.json |

| 5320402 | 古利斯地兴趣-赌狗 | false | true | round_begin_ba | 1 | data/config/event/5320402.json |

| 5320403 | 古利斯地兴趣-欢愉 | false | true | round_begin_ba | 1 | data/config/event/5320403.json |

| 5320404 | 古利斯地兴趣-浴场 | false | true | round_begin_ba | 1 | data/config/event/5320404.json |

| 5320405 | 古利斯地兴趣-闲逛 | false | true | round_begin_ba | 1 | data/config/event/5320405.json |

| 5320406 | 古利斯地兴趣-闲逛 | false | true | round_begin_ba | 1 | data/config/event/5320406.json |

| 5320407 | 古利斯地兴趣-闲逛 | false | true | round_begin_ba | 1 | data/config/event/5320407.json |

| 5320408 | 教育扎齐伊 | false | true | rite_end | 1 | data/config/event/5320408.json |

| 5320409 | 母熊的谢礼 | false | false | round_begin_ba | 1 | data/config/event/5320409.json |

| 5320410 | 古利斯的工作 | false | false | round_begin_ba | 1 | data/config/event/5320410.json |

| 5320411 | 老妇病死补充 | false | false | round_begin_ba | 1 | data/config/event/5320411.json |

| 5320412 | 可疑的钱币 | false | false | round_begin_ba | 1 | data/config/event/5320412.json |

| 5320414 | 小圆声望事件--梦中之狼 | false | false | rite_end | 1 | data/config/event/5320414.json |

| 5320420 | 移除誓言之证的情况 |  | false | rite_end, round_begin_ba | 1 | data/config/event/5320420.json |

| 5320421 | 移除誓言之证的情况 | false | false | rite_end, round_begin_ba | 1 | data/config/event/5320421.json |

| 5320501 | 再利用 | false | true | round_begin_ba | 1 | data/config/event/5320501.json |

| 5320502 | 没别人，进来吧 | false | true | round_begin_ba | 1 | data/config/event/5320502.json |

| 5320503 | 触发见证奇迹的时刻 | false | false | round_begin_ba | 1 | data/config/event/5320503.json |

| 5320504 | 对行尸的处理 | false | true | round_begin_ba | 1 | data/config/event/5320504.json |

| 5320505 | 对行尸的处理 | false | true | round_begin_ba | 1 | data/config/event/5320505.json |

| 5320506 | 对行尸的处理 | false | true | round_begin_ba | 1 | data/config/event/5320506.json |

| 5320507 | 只有税收不可避免 | false | true | round_begin_ba | 1 | data/config/event/5320507.json |

| 5320508 | 咬了苏丹一口 | false | false | round_begin_ba | 1 | data/config/event/5320508.json |

| 5320509 | 男人真正想要的 | false | true | round_begin_ba | 1 | data/config/event/5320509.json |

| 5320510 | 高速旋转的那个什么…… | false | true | round_begin_ba | 1 | data/config/event/5320510.json |

| 5320511 | 重开创造正强者 | false | false | round_begin_ba | 1 | data/config/event/5320511.json |

| 5320512 | 2天后 | false | false | round_begin_ba | 1 | data/config/event/5320512.json |

| 5320513 | 每5天判定一次强者待遇 | false | false | round_begin_ba | 1 | data/config/event/5320513.json |

| 5320514 | 合金装备幻痛 | false | false | round_begin_ba | 1 | data/config/event/5320514.json |

| 5320515 | 合金装备幻痛 | false | false | card_clean | 1 | data/config/event/5320515.json |

| 5320516 | 世上唯一的珍宝 | false | true | round_begin_ba | 1 | data/config/event/5320516.json |

| 5320517 | 白嫖的快乐 | false | false | round_begin_ba | 1 | data/config/event/5320517.json |

| 5320518 | 白嫖 | false | true | round_begin_ba | 1 | data/config/event/5320518.json |

| 5320519 | 白嫖 | false | false | round_begin_ba | 1 | data/config/event/5320519.json |

| 5320520 | 伤痕与友情 | false | false | round_begin_ba | 1 | data/config/event/5320520.json |

| 5320521 | 阿迪莱声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320521.json |

| 5320522 | 酒与肉 | false | false | rite_end | 1 | data/config/event/5320522.json |

| 5320523 | 废弃 | false | false | round_begin_ba | 1 | data/config/event/5320523.json |

| 5320524 | 战士不需要的东西 | false | false | rite_end | 1 | data/config/event/5320524.json |

| 5320525 | 唯一的人选 | false | false | round_begin_ba | 1 | data/config/event/5320525.json |

| 5320526 | 最后的准备 | false | false | round_begin_ba | 1 | data/config/event/5320526.json |

| 5320527 | 屠龙的勇行 | false | false | round_begin_ba | 1 | data/config/event/5320527.json |

| 5320528 | 处置龙眼宝石 | false | true | round_begin_ba | 1 | data/config/event/5320528.json |

| 5320529 | 举世无双的爱 | false | false | round_begin_ba | 1 | data/config/event/5320529.json |

| 5320530 | 如果我…… | false | false | rite_end | 1 | data/config/event/5320530.json |

| 5320531 | 妻子声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320531.json |

| 5320532 | 滋养与杀戮 | false | false | rite_end | 1 | data/config/event/5320532.json |

| 5320533 | 休憩的方法 | false | false | rite_end | 1 | data/config/event/5320533.json |

| 5320534 | 战斗的目的幕后 | false | false | round_begin_ba | 1 | data/config/event/5320534.json |

| 5320535 | 奇怪的气氛 | false | true | rite_end | 1 | data/config/event/5320535.json |

| 5320536 | 唯一的人选？幕后 | false | false | round_begin_ba | 1 | data/config/event/5320536.json |

| 5320537 | 唯一的人选？ | false | true | round_begin_ba | 1 | data/config/event/5320537.json |

| 5320538 | 精打细算 | false | false | round_begin_ba | 1 | data/config/event/5320538.json |

| 5320539 | 心焦之人 | false | false | round_begin_ba | 1 | data/config/event/5320539.json |

| 5320540 | 祈福仪式 | false | false | round_begin_ba | 1 | data/config/event/5320540.json |

| 5320541 | 突然的摊牌 | false | false | round_begin_ba | 1 | data/config/event/5320541.json |

| 5320542 | 突然的摊牌妻子的反应 | false | false | rite_end | 1 | data/config/event/5320542.json |

| 5320543 | 屠龙的勇行 | false | false | round_begin_ba | 1 | data/config/event/5320543.json |

| 5320544 | 屠龙的勇行开启 | false | false | round_begin_ba | 1 | data/config/event/5320544.json |

| 5320545 | 密会开启 | false | false | round_begin_ba | 1 | data/config/event/5320545.json |

| 5320546 | 询问妻子 | false | false | rite_end | 1 | data/config/event/5320546.json |

| 5320547 | 启动婚礼献歌的幕后 | false | false | round_begin_ba | 1 | data/config/event/5320547.json |

| 5320548 | 启动婚礼献歌的幕后 | false | false | round_begin_ba | 1 | data/config/event/5320548.json |

| 5320549 | 战士的结合幕后 | false | false | rite_end | 1 | data/config/event/5320549.json |

| 5320550 | 深潜 | false | false | round_begin_ba | 1 | data/config/event/5320550.json |

| 5320551 | 深谈 | false | false | round_begin_ba | 1 | data/config/event/5320551.json |

| 5320552 | 深谈 | false | true | round_begin_ba | 1 | data/config/event/5320552.json |

| 5320553 | 龙的最期 | false | true | round_begin_ba | 1 | data/config/event/5320553.json |

| 5320554 | 奈布哈尼声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320554.json |

| 5320555 | 法尔达克声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5320555.json |

| 5320556 | 走廊上的花影，已经完成医典 | false | false | round_begin_ba | 1 | data/config/event/5320556.json |

| 5320557 | 走廊上的花影，医典进行中 | false | false | round_begin_ba | 1 | data/config/event/5320557.json |

| 5320558 | 走廊上的花影，未开始医典 | false | false | round_begin_ba | 1 | data/config/event/5320558.json |

| 5320559 | 萨米尔与安妮塔 | false | false | round_begin_ba | 1 | data/config/event/5320559.json |

| 5320560 | 萨米尔的失望 | false | false | round_begin_ba | 1 | data/config/event/5320560.json |

| 5320561 | 萨米尔的感谢 | false | false | round_begin_ba | 1 | data/config/event/5320561.json |

| 5320562 | 萨米尔的十回合倒计时 | false | false | round_begin_ba | 1 | data/config/event/5320562.json |

| 5320563 | 萨米尔的死亡 | false | true | round_begin_ba | 1 | data/config/event/5320563.json |

| 5320564 | 相熟的访客 | false | true | round_begin_ba | 1 | data/config/event/5320564.json |

| 5320565 | 开启宫廷中的调查 | false | true | round_begin_ba | 1 | data/config/event/5320565.json |

| 5320566 | 萨米尔的死亡 | false | true | round_begin_ba | 1 | data/config/event/5320566.json |

| 5320567 | 父亲认罪后的僻静之地 | false | false | round_begin_ba | 1 | data/config/event/5320567.json |

| 5320568 | 卡帕尔死后的僻静之地 | false | false | round_begin_ba | 1 | data/config/event/5320568.json |

| 5320569 | 生命之水获得监听 |  | false | round_begin_ba | 1 | data/config/event/5320569.json |

| 5320570 | 生命之露 |  | false | round_begin_ba | 1 | data/config/event/5320570.json |

| 5320571 | 新药研发 | false | true | round_begin_ba | 1 | data/config/event/5320571.json |

| 5320572 | 萨米尔被袭击 | false | true | round_begin_ba | 1 | data/config/event/5320572.json |

| 5320573 | 失约的惩罚 | false | true | round_begin_ba | 1 | data/config/event/5320573.json |

| 5320574 | 另一个世界的结晶 | false | false | round_begin_ba | 1 | data/config/event/5320574.json |

| 5320575 | 医典编修简单模式的开启幕后 | false | true | round_begin_ba | 1 | data/config/event/5320575.json |

| 5320576 | 热娜收集珠宝启动 | false | true | round_begin_ba | 1 | data/config/event/5320576.json |

| 5320577 | 热娜收集珠宝启动 | false | true | round_begin_ba | 1 | data/config/event/5320577.json |

| 5320578 | 收集玛瑙计数器 | false | true | round_begin_ba | 1 | data/config/event/5320578.json |

| 5320579 | 收集红玉髓计数器 | false | true | round_begin_ba | 1 | data/config/event/5320579.json |

| 5320580 | 收集紫水晶计数器 | false | true | round_begin_ba | 1 | data/config/event/5320580.json |

| 5320581 | 收集祖母绿计数器 | false | true | round_begin_ba | 1 | data/config/event/5320581.json |

| 5320582 | 收集红宝石计数器 | false | true | round_begin_ba | 1 | data/config/event/5320582.json |

| 5320583 | 收集蓝宝石计数器 | false | true | round_begin_ba | 1 | data/config/event/5320583.json |

| 5320584 | 钻石事件触发 | false | false | round_begin_ba | 1 | data/config/event/5320584.json |

| 5320585 | 钻石事件后续开启 | false | false | round_begin_ba | 1 | data/config/event/5320585.json |

| 5320586 | 阿里木的猜疑 | false | true | round_begin_ba | 1 | data/config/event/5320586.json |

| 5320587 | 拉伊德的猜疑 | false | true | round_begin_ba | 1 | data/config/event/5320587.json |

| 5320588 | 钻石事件苏丹之怒 | false | false | round_begin_ba | 1 | data/config/event/5320588.json |

| 5320589 | 如何处置血钻坑呢 | false | true | round_begin_ba | 1 | data/config/event/5320589.json |

| 5320590 | 血钻坑芮尔离队 | false | true | round_begin_ba | 1 | data/config/event/5320590.json |

| 5320591 | 血钻坑阿里木离队 | false | true | round_begin_ba | 1 | data/config/event/5320591.json |

| 5320592 | 血钻坑拉伊德离队 | false | true | round_begin_ba | 1 | data/config/event/5320592.json |

| 5320593 | 一只肥鸽子 | false | false | round_begin_ba | 1 | data/config/event/5320593.json |

| 5320594 | 秘密钻石 | false | false | round_begin_ba | 1 | data/config/event/5320594.json |

| 5320595 | 想成为最好的珠宝商 | false | false | card_clean | 1 | data/config/event/5320595.json |

| 5320596 | 想成为最好的珠宝商 | false | true | round_begin_ba | 1 | data/config/event/5320596.json |

| 5320597 | 想成为最好的珠宝商 | false | true | round_begin_ba | 1 | data/config/event/5320597.json |

| 5320598 | 想成为最好的珠宝商 | false | true | round_begin_ba | 1 | data/config/event/5320598.json |

| 5320599 | 想成为最好的珠宝商 | false | true | round_begin_ba | 1 | data/config/event/5320599.json |

| 5320600 | 放心吧 | false | true | round_begin_ba | 1 | data/config/event/5320600.json |

| 5320601 | 贵族之间的宣传 | false | true | round_begin_ba | 1 | data/config/event/5320601.json |

| 5320602 | 权臣的格调 | false | false | round_begin_ba | 1 | data/config/event/5320602.json |

| 5320603 | 污泥中的金粒 | false | false | round_begin_ba | 1 | data/config/event/5320603.json |

| 5320604 | 萨米尔的死亡 | false | true | round_begin_ba | 1 | data/config/event/5320604.json |

| 5320605 | 贵族珠宝订单的开始 | false | true | round_begin_ba | 1 | data/config/event/5320605.json |

| 5320606 | 接到订单 | false | false | round_begin_ba | 1 | data/config/event/5320606.json |

| 5320607 | 贵公子的订单 | false | true | round_begin_ba | 1 | data/config/event/5320607.json |

| 5320608 | 贵妇的订单 | false | true | round_begin_ba | 1 | data/config/event/5320608.json |

| 5320609 | 狗的订单 | false | true | round_begin_ba | 1 | data/config/event/5320609.json |

| 5320610 | 三个贵族订单完成后 | false | false | round_begin_ba | 1 | data/config/event/5320610.json |

| 5320611 | 热娜的宝石宣传串 | false | false | round_begin_ba | 1 | data/config/event/5320611.json |

| 5320612 | 给宠妃的珠宝 | false | true | round_begin_ba | 1 | data/config/event/5320612.json |

| 5320613 | 给女奴的珠宝 | false | true | round_begin_ba | 1 | data/config/event/5320613.json |

| 5320614 | 给苏丹的珠宝 | false | true | round_begin_ba | 1 | data/config/event/5320614.json |

| 5320615 | 废弃 | false | true | round_begin_ba | 1 | data/config/event/5320615.json |

| 5320616 | 废弃 | false | true | round_begin_ba | 1 | data/config/event/5320616.json |

| 5320617 | 废弃 | false | true | round_begin_ba | 1 | data/config/event/5320617.json |

| 5320618 | 女奴们的回礼紫水晶版 | false | true | round_begin_ba | 1 | data/config/event/5320618.json |

| 5320619 | 女奴们的回礼祖母绿版 | false | true | round_begin_ba | 1 | data/config/event/5320619.json |

| 5320620 | 一点回礼 | false | true | round_begin_ba | 1 | data/config/event/5320620.json |

| 5320621 | 废弃 | false | false | round_begin_ba | 1 | data/config/event/5320621.json |

| 5320622 | 热娜被带走了 | false | true | round_begin_ba | 1 | data/config/event/5320622.json |

| 5320623 | 品鉴王冠 | false | true | round_begin_ba | 1 | data/config/event/5320623.json |

| 5320624 | 帝国最好的珠宝匠 | false | true | round_begin_ba | 1 | data/config/event/5320624.json |

| 5320625 | 热娜的礼物-金色的旗帜 | false | true | round_begin_ba | 1 | data/config/event/5320625.json |

| 5320626 | 热娜的礼物-宝石之盾 | false | true | round_begin_ba | 1 | data/config/event/5320626.json |

| 5320627 | 热娜的礼物-思考者 | false | true | round_begin_ba | 1 | data/config/event/5320627.json |

| 5320628 | 给自己的珠宝 | false | true | round_begin_ba | 1 | data/config/event/5320628.json |

| 5320629 | 给爱人的珠宝 | false | true | round_begin_ba | 1 | data/config/event/5320629.json |

| 5320630 | 给孩子的珠宝 | false | true | round_begin_ba | 1 | data/config/event/5320630.json |

| 5320631 | 牛骨 | false | false | round_begin_ba | 1 | data/config/event/5320631.json |

| 5320637 | 小薇在找你 | false | true | round_begin_ba | 1 | data/config/event/5320637.json |

| 5320638 | 小薇的战斗判定 | false | false | round_begin_ba | 1 | data/config/event/5320638.json |

| 5320639 | 小安在找你 | false | true | round_begin_ba | 1 | data/config/event/5320639.json |

| 5320640 | 小安的倒计时自然消失时的触发幕后 | false | true | round_begin_ba | 1 | data/config/event/5320640.json |

| 5320641 | 小留在找你 | false | true | round_begin_ba | 1 | data/config/event/5320641.json |

| 5320642 | 小留的检查 | false | true | round_begin_ba | 1 | data/config/event/5320642.json |

| 5320643 | 小留的检查一 | false | true | round_begin_ba | 1 | data/config/event/5320643.json |

| 5320644 | 小留的检查二 | false | true | round_begin_ba | 1 | data/config/event/5320644.json |

| 5320645 | 小留的检查三 | false | true | round_begin_ba | 1 | data/config/event/5320645.json |

| 5320646 | 小薇监听心灵之战7 | false | true | round_begin_ba | 1 | data/config/event/5320646.json |

| 5320647 | 小安监听心灵之战8 | false | true | round_begin_ba | 1 | data/config/event/5320647.json |

| 5320648 | 小留监听心灵之战9 | false | true | round_begin_ba | 1 | data/config/event/5320648.json |

| 5320649 | 小薇召唤妖精女王 | false | true | round_begin_ba | 1 | data/config/event/5320649.json |

| 5320650 | 小安召唤妖精女王 | false | true | round_begin_ba | 1 | data/config/event/5320650.json |

| 5320651 | 小留召唤妖精女王 | false | true | round_begin_ba | 1 | data/config/event/5320651.json |

| 5320652 | 小薇为什么要这么做 | false | true | round_begin_ba | 1 | data/config/event/5320652.json |

| 5320653 | 小薇这么做我有什么好处 | false | true | round_begin_ba | 1 | data/config/event/5320653.json |

| 5320654 | 小安为什么要这么做 | false | true | round_begin_ba | 1 | data/config/event/5320654.json |

| 5320655 | 小安这么做阿尔图有什么好处 | false | true | round_begin_ba | 1 | data/config/event/5320655.json |

| 5320656 | 小留为什么要这么做 | false | true | round_begin_ba | 1 | data/config/event/5320656.json |

| 5320657 | 小留这么做阿尔图有什么好处 | false | true | round_begin_ba | 1 | data/config/event/5320657.json |

| 5320658 | 关妖精的笼子开启 | false | true | round_begin_ba | 1 | data/config/event/5320658.json |

| 5320659 | 关妖精的笼子开启 | false | true | round_begin_ba | 1 | data/config/event/5320659.json |

| 5320660 | 关妖精的笼子开启 | false | true | round_begin_ba | 1 | data/config/event/5320660.json |

| 5320661 | 生成金色的花 |  | false | round_begin_ba | 1 | data/config/event/5320661.json |

| 5320662 | 生成紫色的花 |  | false | round_begin_ba | 1 | data/config/event/5320662.json |

| 5320663 | 生成绿色的花 |  | false | round_begin_ba | 1 | data/config/event/5320663.json |

| 5320664 | 开启女王降临 | false | true | round_begin_ba | 1 | data/config/event/5320664.json |

| 5320665 | 开启女王的逃亡 | false | false | round_begin_ba | 1 | data/config/event/5320665.json |

| 5320666 | 魔物饭启动 | false | false | round_begin_ba | 1 | data/config/event/5320666.json |

| 5320680 | 启动午夜欢宴 | false | true | round_begin_ba | 1 | data/config/event/5320680.json |

| 5320681 | 启动归于木林 | false | true | round_begin_ba | 1 | data/config/event/5320681.json |

| 5321001 | 妻子的感激声望事件lv1 | false | false | rite_end | 1 | data/config/event/5321001.json |

| 5321002 | 妻子的警惕声望事件 | false | false | rite_end | 1 | data/config/event/5321002.json |

| 5321003 | 妻子的私房钱声望事件lv1 | false | false | rite_end | 1 | data/config/event/5321003.json |

| 5321004 | 妻子亲族的帮助声望事件lv2 | false | false | rite_end | 1 | data/config/event/5321004.json |

| 5321005 | 妻子的武装声望事件 | false | false | rite_end | 1 | data/config/event/5321005.json |

| 5321006 | 妻子特殊的枕头声望事件 | false | false | rite_end | 1 | data/config/event/5321006.json |

| 5321007 | 妻子为你辩解声望事件 | false | true | round_begin_ba | 1 | data/config/event/5321007.json |

| 5321008 | 妻子的茶会 |  | false | round_begin_ba | 1 | data/config/event/5321008.json |

| 5321009 | 法拉杰声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321009.json |

| 5321010 | 法拉杰声望事件-激励 | false | false | rite_end | 1 | data/config/event/5321010.json |

| 5321011 | 法拉杰声望事件-激励2 | false | false | rite_end | 1 | data/config/event/5321011.json |

| 5321012 | 法拉杰声望事件-不可饶恕的欲望 | false | true | round_begin_ba | 1 | data/config/event/5321012.json |

| 5321013 | 法拉杰声望刺杀事件邪恶lv2 |  | false | round_begin_ba | 1 | data/config/event/5321013.json |

| 5321014 | 法拉杰声望事件-侠名lv1 | false | false | rite_end | 1 | data/config/event/5321014.json |

| 5321015 | 法拉杰声望事件-侠名lv2 | false | false | rite_end | 1 | data/config/event/5321015.json |

| 5321016 | 法拉杰声望事件-侠名lv3 | false | false | rite_end | 1 | data/config/event/5321016.json |

| 5321017 | 盖斯声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321017.json |

| 5321018 | 盖斯声望事件-侠名lv1 | false | false | rite_end | 1 | data/config/event/5321018.json |

| 5321019 | 盖斯声望事件-待价而沽 | false | true | round_begin_ba | 1 | data/config/event/5321019.json |

| 5321020 | 收买头衔 | false | false | round_begin_ba | 1 | data/config/event/5321020.json |

| 5321021 | 盖斯声望事件-荣耀回归 | false | true | round_begin_ba | 1 | data/config/event/5321021.json |

| 5321022 | 盖斯声望事件-归还 | false | true | round_begin_ba | 1 | data/config/event/5321022.json |

| 5321023 | 法拉杰声望事件-您为什么不用我 | false | false | rite_end | 1 | data/config/event/5321023.json |

| 5321024 | 盖斯声望事件-意想不到的遗产 | false | true | round_begin_ba | 1 | data/config/event/5321024.json |

| 5321025 | 过时不候III | false | true | round_begin_ba | 1 | data/config/event/5321025.json |

| 5321026 | 穷酸的拍卖会 |  | false | round_begin_ba | 1 | data/config/event/5321026.json |

| 5321027 | 盖斯声望事件-荣耀回归2 | false | true | round_begin_ba | 1 | data/config/event/5321027.json |

| 5321028 | 盖斯声望事件-赎回幕后 | false | true | round_begin_ba | 1 | data/config/event/5321028.json |

| 5321029 | 盖斯声望事件-盖斯的礼物 | false | true | round_begin_ba | 1 | data/config/event/5321029.json |

| 5321030 | 盖斯声望事件-行脚商走了 | false | true | round_begin_ba | 1 | data/config/event/5321030.json |

| 5321031 | 《被遗忘的仪式》事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321031.json |

| 5321032 | 《丰产的仪式图纸》事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321032.json |

| 5321033 | 《内宅的仪式图纸》事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321033.json |

| 5321034 | 《剑盾的仪式图纸》事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321034.json |

| 5321035 | 丰产的仪式说明 | false | true | round_begin_ba | 1 | data/config/event/5321035.json |

| 5321036 | 内宅的仪式说明 | false | true | round_begin_ba | 1 | data/config/event/5321036.json |

| 5321037 | 剑盾的仪式说明 | false | true | round_begin_ba | 1 | data/config/event/5321037.json |

| 5321038 | 妻子的困惑 | false | true | round_begin_ba | 1 | data/config/event/5321038.json |

| 5321039 | 哲瓦德声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321039.json |

| 5321040 | 听说有位贵人…… | false | false | rite_end | 1 | data/config/event/5321040.json |

| 5321041 | 我自己可以做主 | false | true | round_begin_ba | 1 | data/config/event/5321041.json |

| 5321042 | 哲瓦德声望事件-决斗 | false | true | round_begin_ba | 1 | data/config/event/5321042.json |

| 5321043 | 哲瓦德声望事件-末路 | false | true | round_begin_ba | 1 | data/config/event/5321043.json |

| 5321044 | 我自己，可以……做主 | false | true | round_begin_ba | 1 | data/config/event/5321044.json |

| 5321045 | 哲瓦德的背叛 |  | false | round_begin_ba | 1 | data/config/event/5321045.json |

| 5321046 | 哲瓦德大敌事件 | false | false | round_begin_ba | 1 | data/config/event/5321046.json |

| 5321047 | 哲瓦德大敌事件再起 | false | false | card_clean | 1 | data/config/event/5321047.json |

| 5321048 | 哲瓦德大敌事件-重复阶段 | false | false | round_begin_ba | 1 | data/config/event/5321048.json |

| 5321049 | 对阿鲁米娜纵欲 | false | true | round_begin_ba | 1 | data/config/event/5321049.json |

| 5321050 | 阿鲁米娜出场幕后 |  | false | round_begin_ba | 1 | data/config/event/5321050.json |

| 5321051 | 哲瓦德死亡或对阿鲁米娜纵欲幕后 |  | false | round_begin_ba | 1 | data/config/event/5321051.json |

| 5321052 | 恋爱咨询 | false | true | round_begin_ba | 1 | data/config/event/5321052.json |

| 5321053 | 不会开花的花园 | false | true | round_begin_ba | 1 | data/config/event/5321053.json |

| 5321054 | 快脚的约会 |  | false | card_clean | 1 | data/config/event/5321054.json |

| 5321055 | 赎买的请求幕后 |  | false | round_begin_ba | 1 | data/config/event/5321055.json |

| 5321056 | 欢快的访客 | false | true | round_begin_ba | 1 | data/config/event/5321056.json |

| 5321057 | 胖囚犯死了快脚结局 |  | false | round_begin_ba | 1 | data/config/event/5321057.json |

| 5321058 | 回到上一回合结束触发事件的测试 |  | false | back_to_prev_round_end | 1 | data/config/event/5321058.json |

| 5321060 | 回到上一回合结束触发事件的测试3 |  | true | round_begin_ba | 1 | data/config/event/5321060.json |

| 5321061 | 应许时刻 |  | false | round_begin_ba | 1 | data/config/event/5321061.json |

| 5321062 | 一次逃亡 |  | false | round_begin_ba | 1 | data/config/event/5321062.json |

| 5321063 | 归乡之径 | false | false | rite_end | 1 | data/config/event/5321063.json |

| 5321064 | 证婚人 | false | false | rite_end | 1 | data/config/event/5321064.json |

| 5321065 | 证婚人再起 | false | false | round_begin_ba | 1 | data/config/event/5321065.json |

| 5321066 | 质子婚礼 |  | false | round_begin_ba | 1 | data/config/event/5321066.json |

| 5321067 | 送别 |  | false | round_begin_ba | 1 | data/config/event/5321067.json |

| 5321068 | 一次暗杀 | false | false | rite_end | 1 | data/config/event/5321068.json |

| 5321069 | 老乡见老乡 | false | false | round_begin_ba | 1 | data/config/event/5321069.json |

| 5321070 | 质子声望事件为您效劳 |  | false | round_begin_ba | 1 | data/config/event/5321070.json |

| 5321071 | 阿里木声望事件-抓贼（废弃） | false | false | round_begin_ba | 1 | data/config/event/5321071.json |

| 5321072 | 如何处置 | false | true | round_begin_ba | 1 | data/config/event/5321072.json |

| 5321073 | 道别幕后 | false | true | round_begin_ba | 1 | data/config/event/5321073.json |

| 5321074 | 黑街访客 | false | true | round_begin_ba | 1 | data/config/event/5321074.json |

| 5321075 | 失落小径 |  | false | round_begin_ba | 1 | data/config/event/5321075.json |

| 5321076 | 阿里木声望事件-抓贼循环 |  | false | card_clean | 1 | data/config/event/5321076.json |

| 5321077 | 夜盗 |  | false | round_begin_ba | 1 | data/config/event/5321077.json |

| 5321078 | 夜盗循环 |  | false | card_clean | 1 | data/config/event/5321078.json |

| 5321079 | 阿里木声望事件-走失的狗崽子 |  | false | card_clean | 1 | data/config/event/5321079.json |

| 5321080 | 道别幕后 | false | true | round_begin_ba | 1 | data/config/event/5321080.json |

| 5321081 | 拉磨幕后 | false | true | round_begin_ba | 1 | data/config/event/5321081.json |

| 5321082 | 我都知道了幕后 | false | true | round_begin_ba | 1 | data/config/event/5321082.json |

| 5321083 | 遥远的馈赠 | false | true | round_begin_ba | 1 | data/config/event/5321083.json |

| 5321084 | 第一眼幕后 | false | false | round_begin_ba | 1 | data/config/event/5321084.json |

| 5321085 | 贼的志愿生 |  | false | card_clean | 1 | data/config/event/5321085.json |

| 5321086 | 孩子们的胃口-循环 |  | false | round_begin_ba | 1 | data/config/event/5321086.json |

| 5321087 | 做人 | false | false | rite_end | 1 | data/config/event/5321087.json |

| 5321088 | 阿里木入队 |  | false | round_begin_ba | 1 | data/config/event/5321088.json |

| 5321089 | 废弃 |  | false | round_begin_ba | 1 | data/config/event/5321089.json |

| 5321090 | 邀请 | false | true | round_begin_ba | 1 | data/config/event/5321090.json |

| 5321091 | 阿里木声望事件激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321091.json |

| 5321092 | 合宜之人 |  | false | round_begin_ba | 1 | data/config/event/5321092.json |

| 5321093 | 哈比卜的拿手菜 | false | true | round_begin_ba | 1 | data/config/event/5321093.json |

| 5321094 | 哈比卜的拿手菜 | false | true | round_begin_ba | 1 | data/config/event/5321094.json |

| 5321095 | 妻子的偏好 | false | true | round_begin_ba | 1 | data/config/event/5321095.json |

| 5321096 | 疗愈的食物 |  | false | round_begin_ba | 1 | data/config/event/5321096.json |

| 5321097 | 边角料 |  | false | round_begin_ba | 1 | data/config/event/5321097.json |

| 5321098 | 后街的动静 |  | false | round_begin_ba | 1 | data/config/event/5321098.json |

| 5321099 | 舍馆关门 |  | false | round_begin_ba | 1 | data/config/event/5321099.json |

| 5321100 | 舍馆关门 | false | true | round_begin_ba | 1 | data/config/event/5321100.json |

| 5321101 | 老鼠的下场 | false | true | round_begin_ba | 1 | data/config/event/5321101.json |

| 5321102 | 原谅的价格 | false | true | round_begin_ba | 1 | data/config/event/5321102.json |

| 5321103 | 想做人 | false | true | round_begin_ba | 1 | data/config/event/5321103.json |

| 5321104 | 出轨的开端 |  | false | round_begin_ba | 1 | data/config/event/5321104.json |

| 5321105 | 和颜悦色的哈比卜 | false | true | round_begin_ba | 1 | data/config/event/5321105.json |

| 5321106 | 高端服务 |  | false | round_begin_ba | 1 | data/config/event/5321106.json |

| 5321107 | 哈比卜的宴会 | false | false | round_begin_ba | 1 | data/config/event/5321107.json |

| 5321108 | 羊排与羊肉 | false | true | round_begin_ba | 1 | data/config/event/5321108.json |

| 5321109 | 变换的行列 |  | false | round_begin_ba | 1 | data/config/event/5321109.json |

| 5321110 | 忠善之人 | false | true | round_begin_ba | 1 | data/config/event/5321110.json |

| 5321111 | 小小的快乐 | false | true | round_begin_ba | 1 | data/config/event/5321111.json |

| 5321112 | 舍馆的阁楼 |  | false | round_begin_ba | 1 | data/config/event/5321112.json |

| 5321113 | 阁楼里的笑声 | false | false | round_begin_ba | 1 | data/config/event/5321113.json |

| 5321114 | 布缇娜之怒 |  | false | round_begin_ba | 1 | data/config/event/5321114.json |

| 5321115 | 拜铃耶的掉落 | false | true | round_begin_ba | 1 | data/config/event/5321115.json |

| 5321116 | 布缇娜女士的管束 | false | false | round_begin_ba | 1 | data/config/event/5321116.json |

| 5321117 | 阁楼里的笑声 | false | false | round_begin_ba | 1 | data/config/event/5321117.json |

| 5321118 | 合伙生意 | false | false | round_begin_ba | 1 | data/config/event/5321118.json |

| 5321119 | 陌生的妓女来访 |  | false | round_begin_ba | 1 | data/config/event/5321119.json |

| 5321120 | 遥远的瘟疫 | false | false | round_begin_ba | 1 | data/config/event/5321120.json |

| 5321121 | 丝绒暗室 | false | false | round_begin_ba | 1 | data/config/event/5321121.json |

| 5321122 | 丝绒暗室的掉落 | false | true | round_begin_ba | 1 | data/config/event/5321122.json |

| 5321123 | 过于尊贵的客人 |  | false | round_begin_ba | 1 | data/config/event/5321123.json |

| 5321124 | 如何款待尊贵的客人幕后 |  | false | round_begin_ba | 1 | data/config/event/5321124.json |

| 5321125 | 盖斯-意想不到的遗产 |  | false | round_begin_ba | 1 | data/config/event/5321125.json |

| 5321126 | 御厨 |  | false | round_begin_ba | 1 | data/config/event/5321126.json |

| 5321127 | 苏丹的欢愉 |  | false | round_begin_ba | 1 | data/config/event/5321127.json |

| 5321128 | 冒险者酒吧谋反阶段 |  | true | round_begin_ba | 1 | data/config/event/5321128.json |

| 5321129 | 公主的滋味 |  | false | round_begin_ba | 1 | data/config/event/5321129.json |

| 5321130 | 第一个牺牲者 | false | false | round_begin_ba | 1 | data/config/event/5321130.json |

| 5321131 | 唯一的牺牲者 | false | false | round_begin_ba | 1 | data/config/event/5321131.json |

| 5321132 | 流浪剑客的复仇 | false | false | round_begin_ba | 1 | data/config/event/5321132.json |

| 5321133 | 妻子死亡后哈比卜事件 |  | false | round_begin_ba | 1 | data/config/event/5321133.json |

| 5321134 | 奈费勒的谎言 |  | false | round_begin_ba | 1 | data/config/event/5321134.json |

| 5321135 | 宰相的谎言 |  | false | round_begin_ba | 1 | data/config/event/5321135.json |

| 5321136 | 更刺激的比赛 |  | false | round_begin_ba | 1 | data/config/event/5321136.json |

| 5321137 | 法里斯的支持 |  | false | round_begin_ba | 1 | data/config/event/5321137.json |

| 5321138 | 法里斯的友谊 |  | false | round_begin_ba | 1 | data/config/event/5321138.json |

| 5321139 | 赛狗循环 | false | false | round_begin_ba | 1 | data/config/event/5321139.json |

| 5321140 | 更高端的比赛 |  | false | round_begin_ba | 1 | data/config/event/5321140.json |

| 5321141 | 自信的法里斯 |  | true | round_begin_ba | 1 | data/config/event/5321141.json |

| 5321142 | 幽怨的法里斯 | false | false | round_begin_ba | 1 | data/config/event/5321142.json |

| 5321143 | 复仇的请求 | false | true | round_begin_ba | 1 | data/config/event/5321143.json |

| 5321144 | 关闭拼凑真相 |  | true | round_begin_ba | 1 | data/config/event/5321144.json |

| 5321145 | 法德耶的愧疚故事线 |  | true | round_begin_ba | 1 | data/config/event/5321145.json |

| 5321146 | 第一次帮助 | false | false | round_begin_ba | 1 | data/config/event/5321146.json |

| 5321147 | 第二次帮助 | false | false | round_begin_ba | 1 | data/config/event/5321147.json |

| 5321148 | 第三次帮助 | false | false | round_begin_ba | 1 | data/config/event/5321148.json |

| 5321149 | 第四次帮助 | false | false | round_begin_ba | 1 | data/config/event/5321149.json |

| 5321150 | 遗忘的交易 | false | false | round_begin_ba | 1 | data/config/event/5321150.json |

| 5321151 | 女奴之死 | false | false | round_begin_ba | 1 | data/config/event/5321151.json |

| 5321152 | 新月升起 |  | true | round_begin_ba | 1 | data/config/event/5321152.json |

| 5321153 | 找人陪新月玩 |  | false | round_begin_ba | 1 | data/config/event/5321153.json |

| 5321154 | 新月长大了 |  | true | round_begin_ba | 1 | data/config/event/5321154.json |

| 5321155 | 破除洁净 |  | false | round_begin_ba | 1 | data/config/event/5321155.json |

| 5321156 | 伊曼出走 |  | false | round_begin_ba | 1 | data/config/event/5321156.json |

| 5321157 | 密教的援助故事线 |  | false | round_begin_ba | 1 | data/config/event/5321157.json |

| 5321158 | 拜铃耶声望激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321158.json |

| 5321159 | 不洁的援助 | false | false | rite_end | 1 | data/config/event/5321159.json |

| 5321160 | 废弃 |  | true | round_begin_ba | 1 | data/config/event/5321160.json |

| 5321161 | 荒诞之欢 | false | true | round_begin_ba | 1 | data/config/event/5321161.json |

| 5321162 | 法德耶之死 | false | false | round_begin_ba | 1 | data/config/event/5321162.json |

| 5321163 | 无妄之灾 | false | false | round_begin_ba | 1 | data/config/event/5321163.json |

| 5321164 | 拜铃耶刺青 | false | true | round_begin_ba | 1 | data/config/event/5321164.json |

| 5321165 | 拜铃耶营业无收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321165.json |

| 5321166 | 拜铃耶营业收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321166.json |

| 5321167 | 拜铃耶营业收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321167.json |

| 5321168 | 拜铃耶营业收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321168.json |

| 5321169 | 拜铃耶营业收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321169.json |

| 5321170 | 拜铃耶营业收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321170.json |

| 5321171 | 拜铃耶的技术精进了 |  | true | round_begin_ba | 1 | data/config/event/5321171.json |

| 5321172 | 清洗异端 |  | false | round_begin_ba | 1 | data/config/event/5321172.json |

| 5321173 | 祭品 | false | true | round_begin_ba | 1 | data/config/event/5321173.json |

| 5321174 | 重启拼凑真相 | false | true | round_begin_ba | 1 | data/config/event/5321174.json |

| 5321175 | 苏丹的女奴 | false | false | round_begin_ba | 1 | data/config/event/5321175.json |

| 5321176 | 辩经：拜铃耶 |  | false | round_begin_ba | 1 | data/config/event/5321176.json |

| 5321177 | 拜铃耶的降神仪式 | false | false | round_begin_ba | 1 | data/config/event/5321177.json |

| 5321178 | 拜铃耶的诅咒 | false | false | round_begin_ba | 1 | data/config/event/5321178.json |

| 5321179 | 废弃 |  | true | round_begin_ba | 1 | data/config/event/5321179.json |

| 5321180 | 拜铃耶的降神仪式 | false | false | round_begin_ba | 1 | data/config/event/5321180.json |

| 5321181 | 我们都是祭品 | false | true | round_begin_ba | 1 | data/config/event/5321181.json |

| 5321182 | 献给阿尔图的花束 |  | false | round_begin_ba | 1 | data/config/event/5321182.json |

| 5321183 | 密教的遗孤 | false | true | round_begin_ba | 1 | data/config/event/5321183.json |

| 5321184 | 拜铃耶的下落 |  | false | round_begin_ba | 1 | data/config/event/5321184.json |

| 5321185 | 消失的回响 |  | false | round_begin_ba | 1 | data/config/event/5321185.json |

| 5321186 | 密神的诅咒再次降临 | false | true | round_begin_ba | 1 | data/config/event/5321186.json |

| 5321187 | 清洗异端前置幕后 | false | false | round_begin_ba | 1 | data/config/event/5321187.json |

| 5321188 | 密神的诅咒使你受伤 | false | true | round_begin_ba | 1 | data/config/event/5321188.json |

| 5321189 | 做鸡 | false | true | round_begin_ba | 1 | data/config/event/5321189.json |

| 5321190 | 做牛马 | false | true | round_begin_ba | 1 | data/config/event/5321190.json |

| 5321191 | 做羔羊（正 | false | true | round_begin_ba | 1 | data/config/event/5321191.json |

| 5321192 | 做狗 | false | true | round_begin_ba | 1 | data/config/event/5321192.json |

| 5321193 | 做羔羊（密 | false | true | round_begin_ba | 1 | data/config/event/5321193.json |

| 5321194 | 做老鼠 | false | true | round_begin_ba | 1 | data/config/event/5321194.json |

| 5321195 | 做人 | false | true | round_begin_ba | 1 | data/config/event/5321195.json |

| 5321196 | 佣兵报恩 | false | true | round_begin_ba | 1 | data/config/event/5321196.json |

| 5321197 | 欲望之蛇 |  | false | round_begin_ba | 1 | data/config/event/5321197.json |

| 5321198 | 纯洁之纱 |  | false | round_begin_ba | 1 | data/config/event/5321198.json |

| 5321199 | 阿里木修建苗圃幕后 | false | true | round_begin_ba | 1 | data/config/event/5321199.json |

| 5321200 | 痛斥 | false | true | round_begin_ba | 1 | data/config/event/5321200.json |

| 5321201 | 拉伊德的逃跑 | false | false | round_begin_ba | 1 | data/config/event/5321201.json |

| 5321202 | 拉伊德声望激活提示 |  | false | round_begin_ba | 1 | data/config/event/5321202.json |

| 5321203 | 拉伊德的索要 | false | false | rite_end | 1 | data/config/event/5321203.json |

| 5321204 | 寻思流民的帮闲 | false | true | round_begin_ba | 1 | data/config/event/5321204.json |

| 5321205 | 流民的帮闲收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321205.json |

| 5321206 | 流民的帮闲收益提示 | false | true | round_begin_ba | 1 | data/config/event/5321206.json |

| 5321207 | 作废 | false | true | round_begin_ba | 1 | data/config/event/5321207.json |

| 5321208 | 拉伊德第二次索要 |  | false | round_begin_ba | 1 | data/config/event/5321208.json |

| 5321209 | 无赖租客 |  | false | round_begin_ba | 1 | data/config/event/5321209.json |

| 5321210 | 寻思强化流民的帮闲 | false | true | round_begin_ba | 1 | data/config/event/5321210.json |

| 5321211 | 拉伊德的请求 |  | false | round_begin_ba | 1 | data/config/event/5321211.json |

| 5321212 | 困顿的堡垒 |  | false | round_begin_ba | 1 | data/config/event/5321212.json |

| 5321213 | 忙碌的拉伊德 | false | false | round_begin_ba | 1 | data/config/event/5321213.json |

| 5321214 | 流民谋反阶段 |  | true | round_begin_ba | 1 | data/config/event/5321214.json |

| 5321215 | 伪造公主 | false | true | round_begin_ba | 1 | data/config/event/5321215.json |

| 5321216 | 重新开启【玩家名】堡 |  | false | round_begin_ba | 1 | data/config/event/5321216.json |

| 5321217 | 舞会的结束 |  | false | round_begin_ba | 1 | data/config/event/5321217.json |

| 5321218 | 伪造公主 | false | false | round_begin_ba | 1 | data/config/event/5321218.json |

| 5321219 | 拉伊德死亡 | false | false | round_begin_ba | 1 | data/config/event/5321219.json |

| 5321220 | 拉伊德赠礼 | false | false | round_begin_ba | 1 | data/config/event/5321220.json |

| 5321221 | 令人不快的刺探 | false | false | round_begin_ba | 1 | data/config/event/5321221.json |

| 5321222 | 死斗 | false | false | round_begin_ba | 1 | data/config/event/5321222.json |

| 5321223 | 杀戮与激情 |  | true | round_begin_ba | 1 | data/config/event/5321223.json |

| 5321224 | 令人不愉快的刺探-拉伊德入队 | false | true | round_begin_ba | 1 | data/config/event/5321224.json |

| 5321225 | 消除一个苏丹的猜忌 | false | false | round_begin_ba | 1 | data/config/event/5321225.json |

| 5321226 | 拉伊德离队 | false | true | round_begin_ba | 1 | data/config/event/5321226.json |

| 5321227 | 无赖租客-拉伊德入队 | false | false | round_begin_ba | 1 | data/config/event/5321227.json |

| 5321228 | 拉伊德查无此人 | false | false | round_begin_ba | 1 | data/config/event/5321228.json |

| 5321229 | 阿图娜尔的身世 |  | true | round_begin_ba | 1 | data/config/event/5321229.json |

| 5321230 | 稀疏的禁忌 |  | true | round_begin_ba | 1 | data/config/event/5321230.json |

| 5321231 | 石榴树的畸枝 |  | false | round_begin_ba | 1 | data/config/event/5321231.json |

| 5321232 | 阿图娜尔纵欲卡后续 | false | false | round_begin_ba | 1 | data/config/event/5321232.json |

| 5321233 | 你我之间 | false | false | round_begin_ba | 1 | data/config/event/5321233.json |

| 5321234 | 突然的坦白 |  | false | round_begin_ba | 1 | data/config/event/5321234.json |

| 5321235 | 链接你我之间 |  | false | round_begin_ba | 1 | data/config/event/5321235.json |

| 5321236 | 深沉的失望 |  | false | round_begin_ba | 1 | data/config/event/5321236.json |

| 5321237 | 无言的失望 |  | true | round_begin_ba | 1 | data/config/event/5321237.json |

| 5321238 | 妻子出走 |  | false | round_begin_ba | 1 | data/config/event/5321238.json |

| 5321239 | 舞姬添加tag |  | true | round_begin_ba | 1 | data/config/event/5321239.json |

| 5321240 | 关闭你值得更好的 | false | true | round_begin_ba | 1 | data/config/event/5321240.json |

| 5321241 | 关闭愧疚与宝石 | false | true | round_begin_ba | 1 | data/config/event/5321241.json |

| 5321242 | 树顶的月亮 |  | true | round_begin_ba | 1 | data/config/event/5321242.json |

| 5321243 | 贵族的邀请 | false | false | round_begin_ba | 1 | data/config/event/5321243.json |

| 5321244 | 梅姬的主意 | false | false | round_begin_ba | 1 | data/config/event/5321244.json |

| 5321245 | 求求你 | false | true | round_begin_ba | 1 | data/config/event/5321245.json |

| 5321246 | 苏丹的兴致 | false | false | round_begin_ba | 1 | data/config/event/5321246.json |

| 5321247 | 奇怪的舞蹈 | false | false | round_begin_ba | 1 | data/config/event/5321247.json |

| 5321248 | 一个奇怪的请求 | false | false | round_begin_ba | 1 | data/config/event/5321248.json |

| 5321249 | 一封信 | false | false | round_begin_ba | 1 | data/config/event/5321249.json |

| 5321250 | 旅行的妹妹 | false | true | round_begin_ba | 1 | data/config/event/5321250.json |

| 5321251 | 旅行的妹妹2 | false | false | round_begin_ba | 1 | data/config/event/5321251.json |

| 5321252 | 旅行的妹妹2 | false | false | round_begin_ba | 1 | data/config/event/5321252.json |

| 5321253 | 旅行的妹妹3 | false | false | round_begin_ba | 1 | data/config/event/5321253.json |

| 5321254 | 旅行的妹妹3 | false | false | round_begin_ba | 1 | data/config/event/5321254.json |

| 5321255 | 旅行的妹妹4 | false | false | round_begin_ba | 1 | data/config/event/5321255.json |

| 5321256 | 旅行的妹妹4 | false | false | round_begin_ba | 1 | data/config/event/5321256.json |

| 5321257 | 旅行的妹妹5 | false | false | round_begin_ba | 1 | data/config/event/5321257.json |

| 5321258 | 旅行的妹妹5 | false | false | round_begin_ba | 1 | data/config/event/5321258.json |

| 5321259 | 旅行的妹妹6 | false | false | round_begin_ba | 1 | data/config/event/5321259.json |

| 5321260 | 旅行的妹妹6 | false | false | round_begin_ba | 1 | data/config/event/5321260.json |

| 5321261 | 御医的诊治 | false | true | round_begin_ba | 1 | data/config/event/5321261.json |

| 5321262 | 贪婪的协助 | false | true | round_begin_ba | 1 | data/config/event/5321262.json |

| 5321263 | 密教的协助 | false | true | round_begin_ba | 1 | data/config/event/5321263.json |

| 5321264 | 正教的协助 | false | true | round_begin_ba | 1 | data/config/event/5321264.json |

| 5321265 | 妻子的协助 | false | true | round_begin_ba | 1 | data/config/event/5321265.json |

| 5321266 | 玛希尔的协助 | false | true | round_begin_ba | 1 | data/config/event/5321266.json |

| 5321267 | 剑客的协助 | false | true | round_begin_ba | 1 | data/config/event/5321267.json |

| 5321268 | 野心的果实 |  | true | round_begin_ba | 1 | data/config/event/5321268.json |

| 5321269 | 宫斗的妹妹 | false | false | round_begin_ba | 1 | data/config/event/5321269.json |

| 5321270 | 石宫斗触发 | false | true | round_begin_ba | 1 | data/config/event/5321270.json |

| 5321271 | 铜宫斗触发 | false | true | round_begin_ba | 1 | data/config/event/5321271.json |

| 5321272 | 银宫斗触发 | false | true | round_begin_ba | 1 | data/config/event/5321272.json |

| 5321273 | 妃子的礼物 | false | false | round_begin_ba | 1 | data/config/event/5321273.json |

| 5321274 | 金宫斗触发 | false | true | round_begin_ba | 1 | data/config/event/5321274.json |

| 5321275 | 金宫斗2 | false | true | round_begin_ba | 1 | data/config/event/5321275.json |

| 5321276 | 金宫斗3 | false | true | round_begin_ba | 1 | data/config/event/5321276.json |

| 5321277 | 金宫斗3王座 | false | true | round_begin_ba | 1 | data/config/event/5321277.json |

| 5321278 | 莎姬赢了 | false | false | round_begin_ba | 1 | data/config/event/5321278.json |

| 5321279 | 贬斥 | false | false | round_begin_ba | 1 | data/config/event/5321279.json |

| 5321280 | 死亡 | false | false | round_begin_ba | 1 | data/config/event/5321280.json |

| 5321281 | 无头之舞 | false | false | round_begin_ba | 1 | data/config/event/5321281.json |

| 5321282 | 舞姬赢了 | false | false | round_begin_ba | 1 | data/config/event/5321282.json |

| 5321283 | 流浪的果实 | false | false | round_begin_ba | 1 | data/config/event/5321283.json |

| 5321284 | 最终胜利 | false | false | round_begin_ba | 1 | data/config/event/5321284.json |

| 5321285 | 玫瑰的刺 | false | false | round_begin_ba | 1 | data/config/event/5321285.json |

| 5321286 | 玫瑰的提示 | false | false | round_begin_ba | 1 | data/config/event/5321286.json |

| 5321287 | 宫中支持者 | false | false | round_begin_ba | 1 | data/config/event/5321287.json |

| 5321288 | 舞姬的帮助——谋反阶段 |  | true | round_begin_ba | 1 | data/config/event/5321288.json |

| 5321289 | 舞姬的帮助——信物 |  | true | round_begin_ba | 1 | data/config/event/5321289.json |

| 5321290 | 判断舞姬品级 | false | true | round_begin_ba | 1 | data/config/event/5321290.json |

| 5321291 | 私自入宫 | false | false | round_begin_ba | 1 | data/config/event/5321291.json |

| 5321292 | 莎姬死了 |  | true | round_begin_ba | 1 | data/config/event/5321292.json |

| 5321293 | 沟渠的邀请 | false | false | round_begin_ba | 1 | data/config/event/5321293.json |

| 5321294 | 发放孩子们 | false | true | round_begin_ba | 1 | data/config/event/5321294.json |

| 5321295 | 发放所有书 | false | true | round_begin_ba | 1 | data/config/event/5321295.json |

| 5321296 | 羊肉炉臣服线结局 | false | true | round_begin_ba | 1 | data/config/event/5321296.json |

| 5321297 | 羊肉炉臣服线结局—百科全书 | false | true | round_begin_ba | 1 | data/config/event/5321297.json |

| 5360001 | 完成X局游戏次数（死亡也计数） |  | false | game_end | 1 | data/config/event/5360001.json |

| 5360002 | 活着/胜利X局游戏（死亡不计数） |  | false | game_end | 1 | data/config/event/5360002.json |

| 5360003 | 累计消除X张苏丹卡 |  | false | card_clean | 1 | data/config/event/5360003.json |

| 5360004 | 累计消除X张征服卡 |  | false | card_clean | 1 | data/config/event/5360004.json |

| 5360005 | 累计消除X张杀戮卡 |  | false | card_clean | 1 | data/config/event/5360005.json |

| 5360006 | 累计消除X张纵欲卡 |  | false | card_clean | 1 | data/config/event/5360006.json |

| 5360007 | 累计消除X张奢靡卡 |  | false | card_clean | 1 | data/config/event/5360007.json |

| 5360008 | 一局游戏内撑过7天 |  | false | game_end | 1 | data/config/event/5360008.json |

| 5360009 | 一局游戏内撑过30天 |  | false | game_end | 1 | data/config/event/5360009.json |

| 5360010 | 一局游戏内撑过50天 |  | false | game_end | 1 | data/config/event/5360010.json |

| 5360011 | 持有金币数量达到20 |  | false | card_born | 1 | data/config/event/5360011.json |

| 5360012 | 持有金币数量达到50 |  | false | card_born | 1 | data/config/event/5360012.json |

| 5360013 | 持有金币数量达到100 |  | false | card_born | 1 | data/config/event/5360013.json |

| 5360014 | 一局游戏内善名达到X点 |  | false | counter | 1 | data/config/event/5360014.json |

| 5360015 | 一局游戏内恶名达到X点 |  | false | counter | 1 | data/config/event/5360015.json |

| 5360016 | 一局游戏内权势达到X点 |  | false | counter | 1 | data/config/event/5360016.json |

| 5360017 | 一局游戏内侠名达到X点 |  | false | counter | 1 | data/config/event/5360017.json |

| 5360018 | 一局游戏内灵视达到X点 |  | false | counter | 1 | data/config/event/5360018.json |

| 5360019 | 一局游戏内拥有X位追随者 |  | false | round_begin_ba | 1 | data/config/event/5360019.json |

| 5360020 | 一局游戏内拥有X位追随者 |  | false | round_begin_ba | 1 | data/config/event/5360020.json |

| 5360021 | 一局游戏内拥有X位追随者 |  | false | round_begin_ba | 1 | data/config/event/5360021.json |

| 5360022 | 一局游戏内拥有X位追随者 |  | false | round_begin_ba | 1 | data/config/event/5360022.json |

| 5360023 | 完成所有结局（废弃） | false | false | game_end | 1 | data/config/event/5360023.json |

| 5360024 | 在30天内没有获得妻子的不满 |  | false | round_begin_ba | 1 | data/config/event/5360024.json |

| 5360025 | 获得妻子的不满时计数 |  | false | card_born | 1 | data/config/event/5360025.json |

| 5360026 | 没有及时消除苏丹卡而死亡 |  | false | game_end | 1 | data/config/event/5360026.json |

| 5360027 | 获得并装修1个奇珍 | false | false | round_begin_ba | 1 | data/config/event/5360027.json |

| 5360028 | 获得并装修5个奇珍（废弃） | false | false | round_begin_ba | 1 | data/config/event/5360028.json |

| 5360029 | 获得并装修10个奇珍（废弃） | false | false | round_begin_ba | 1 | data/config/event/5360029.json |

| 5360030 | 一局游戏内触发完洗澡的所有随机事件 |  | false | counter | 1 | data/config/event/5360030.json |

| 5360031 | 一局游戏内嫖过所有的妓女 |  | false | round_begin_ba | 1 | data/config/event/5360031.json |

| 5360032 | 一局游戏内达成连续七天都去上朝 |  | false | round_begin_ba | 1 | data/config/event/5360032.json |

| 5360033 | 一局游戏内达成7天不上朝 |  | false | round_begin_ba | 1 | data/config/event/5360033.json |

| 5360034 | 向苏丹索要过一次妃子 |  | false | round_begin_ba | 1 | data/config/event/5360034.json |

| 5360035 | 向苏丹索要过他所有的妃子 |  | false | round_begin_ba | 1 | data/config/event/5360035.json |

| 5360036 | 点燃寡妇的激情 |  | false | round_begin_ba | 1 | data/config/event/5360036.json |

| 5360037 | 掰断所有苏丹卡（废弃） | false | false | game_end | 1 | data/config/event/5360037.json |

| 5360038 | 天才少女看书 |  | false | round_begin_ba | 1 | data/config/event/5360038.json |

| 5360039 | 天才少女看书2 |  | false | round_begin_ba | 1 | data/config/event/5360039.json |

| 5360040 | 天才少女看书3 |  | false | round_begin_ba | 1 | data/config/event/5360040.json |

| 5360041 | 一局游戏内善名达到X点 |  | false | counter | 1 | data/config/event/5360041.json |

| 5360042 | 一局游戏内善名达到X点 |  | false | counter | 1 | data/config/event/5360042.json |

| 5360043 | 一局游戏内恶名达到X点 |  | false | counter | 1 | data/config/event/5360043.json |

| 5360044 | 一局游戏内恶名达到X点 |  | false | counter | 1 | data/config/event/5360044.json |

| 5360045 | 一局游戏内权势达到X点 |  | false | counter | 1 | data/config/event/5360045.json |

| 5360046 | 一局游戏内权势达到X点 |  | false | counter | 1 | data/config/event/5360046.json |

| 5360047 | 一局游戏内侠名达到X点 |  | false | counter | 1 | data/config/event/5360047.json |

| 5360048 | 一局游戏内侠名达到X点 |  | false | counter | 1 | data/config/event/5360048.json |

| 5360049 | 一局游戏内灵视达到X点 |  | false | counter | 1 | data/config/event/5360049.json |

| 5360050 | 一局游戏内灵视达到X点 |  | false | counter | 1 | data/config/event/5360050.json |

| 5360051 | steam结局成就 |  | false | game_end | 1 | data/config/event/5360051.json |

| 5360052 | 成就-死于刺杀 |  | false | game_end | 1 | data/config/event/5360052.json |

| 5360053 | 成就-暴君的末日 |  | false | round_begin_ba | 1 | data/config/event/5360053.json |

| 5360054 | 成就-新世界 |  | false | round_begin_ba | 1 | data/config/event/5360054.json |

| 5360055 | 成就-完美世界 |  | false | round_begin_ba | 1 | data/config/event/5360055.json |

| 5360056 | 成就-希望的园丁 |  | false | round_begin_ba | 1 | data/config/event/5360056.json |

| 5360057 | 成就-苏丹的近臣 |  | false | round_begin_ba | 1 | data/config/event/5360057.json |

| 5360058 | 成就-眠花宿柳 |  | false | round_begin_ba | 1 | data/config/event/5360058.json |

| 5360059 | 成就-无所不知-金秘密 |  | false | round_begin_ba | 1 | data/config/event/5360059.json |

| 5360060 | 成就-无所不知-金洞察 |  | false | round_begin_ba | 1 | data/config/event/5360060.json |

| 5360061 | 成就-无所不知-金机遇 |  | false | round_begin_ba | 1 | data/config/event/5360061.json |

| 5360062 | 成就-无所不知-金内幕 |  | false | round_begin_ba | 1 | data/config/event/5360062.json |

| 5360063 | 成就-无所不知-金预兆 |  | false | round_begin_ba | 1 | data/config/event/5360063.json |

| 5360064 | 成就-无所不知-金战术 |  | false | round_begin_ba | 1 | data/config/event/5360064.json |

| 5360065 | 成就-无所不知-金秘氛 |  | false | round_begin_ba | 1 | data/config/event/5360065.json |


</details>
