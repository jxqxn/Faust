# 初始人物、可见手牌与自动吸附（2026-09-11）

**后续状态：** 原始 StreamingAssets/config 已成为运行与校验基准，重复操作/条件/时机完整保留。此前缺失的宫廷与浴场已由真实开局事件恢复，四个开局仪式及奖励手牌按原 auto_save notes 对拍通过。UID统一分配和旧池碰撞兼容见 [RemainingCloneConvergence](RemainingCloneConvergence.md)。

## 根因与本批范围

旧 ConfigDB 用四卡常量替代原作 init/1.json 的 default_cards，误把正式人物初始表
当作测试卡表。另一方面，hand 数组承载的是未占用仪式槽的 Player.cards，UI 和
hand_have 却未执行原作 IsHandCard：直接恢复初始表会把 NPC 全摆成手牌，甚至因为
未归属玩家的受伤 NPC 误生成医院。两层必须同时修正。

本批使用原始配置，创建全部初始条目（按原作规则合并可堆叠重复项），恢复四组初始装备，
按有效归属标签筛选普通手牌。自动吸附仍访问完整未占槽集合，保持人物 UID，
未归属玩家的人物返回该集合后仍不显示；“恢复上次投放”不能取走隐藏 NPC。

复核中还修正了装备继承的旧误读：GetTag 检查的是正在查询的 TagNode.can_inherit，
不是“装备有任一可继承标签就传递整行”。后者会让装备上的own/adherent/player泄漏到
隐藏NPC。GetTags的0x393980谓词独立确认逐标签筛选；递归raw=true仅跳过非正值屏蔽，
仍乘装备自身count，再乘宿主count。标签值、标签名并集和对应旧错误测试一起修正。

## 原作证据

| 边界 | 直接证据 | 独立信号 |
| --- | --- | --- |
| 初始卡牌 | Datapool.InitPlayer 0x413700，原二进制 0x413b65–0x413c24 | dump.cs:390539 default_cards@0x58；init/1.json |
| 重复条目 | 0x413b8a HasTag(stackable)，0x413b9c GetCardById，0x413bb1 count+1，否则0x413bd0 AddCard(false,false) | stringliteral 0x2593720=stackable；重复条目配置及卡片标签 |
| 初始装备 | Datapool.c 初始装备循环：0x413d53 AddCard(true,false)，0x413d69 AddEquip | dump.cs:390541 card_equips@0x60；auto_save 的嵌套装备 |
| 普通手牌 | CardExtensions.IsHandCard 0x3827c0，三个 GetTag>0 的 OR；二进制0x382802–0x382866复核 | dump.cs:388147；stringliteral 0x2580360=own / 0x258AC48=adherent / 0x25828F8=player；tag.json |
| 取手牌 | PlayerExtensions.GetHandCards 0x38d430，谓词0x3938f0调用IsHandCard | RitePanelController.OnLastState 0x58fdf0 调用 GetHandCards |
| 手牌条件 | HandHaveCardCount.IsSatisfied 0x3fd4f0枚举Player.cards再调用IsHandCard | 事件5300073使用hand_have.受伤/生病触发医院 |
| 桌面条件 | TableHaveCardCount.IsSatisfied 0x409b10只枚举Player.cards，无仪式遍历 | HaveCardCount 0x3fed80另行枚举Player.cards及每个Rite.cards |
| 分页位置 | GameController.UpdateHandCardPos 0x559a70过滤IsCurrentHandCard | IsCurrentHandCard 0x3826a0明确先比较BagIndex；原存档NPC bagpos=0 |
| 老板吸附 | RiteExtensions.AdsorbCards 0x38fca0读取Player.cards；InitRite 0x38e140创建时调用 | rite/5002006 s5强制吸附2000199；auto_save已有书店实例 |

注意：InitPlayer 的 `.c` 在 default_cards 循环中漏掉成功分支，看起来像无条件 LogError。
不能据此断言原作不创建卡片。本批只读原始 GameAssembly.dll，反汇编确认成功路径和堆叠分支，
未修改语料。初始装备的 no_add=true 不执行 MarkCardGen，不能用“先加入手牌再装备”替代。

## 验收边界

- tests/test_startup_card_population.gd：初始顺序/堆叠、隐藏老板吸附与返回、三类归属标签、
  跨页hand_have、table_have与have范围、原存档手牌筛选、初始装备、存读档和实际UI组件。
- tests/test_startup_rites.gd：真实开场选项链、首日书店、医院误触发反例、第二/三日家业后继、
  存读档保留合法重复仪式。
- 保留现有活动苏丹卡的独立手牌带呈现；原样本普通牌4张、活动苏丹牌1张。
  **三标签方法本身不包含苏丹卡特例。** 苏丹牌呈现与原版运行时重建之间的完整接线
  不在本批验收范围，不将保留的宿主路径冒充为IsHandCard原逻辑。

## 未完成

本批开场路径能自然生成家业、书店，仍未得到原存档中的宫廷5001001、浴场5001501。
它们不能凭“样本有”就变成默认常量；首次创建入口仍待对照原作启动/剧情链查清。
苏丹池与普通卡使用独立UID分配器，尚不能宣称新局UID和原作逐项相同。
本批不迁移旧局缺失人物，不删除旧局重复仪式，不修改content，不覆盖用户存档。

## 验证记录

日志在 `C:/Users/User/Documents/Faust-cleanup-20260911/`。

- `population-full-fixed.log`：全量64脚本、730测试，710通过、20失败。
  旧夹具仍把人物集合当成可见手牌、依赖四卡开局，旧table_have断言也错误包含仪式槽；
  其中手牌预览触发越界。逐项修复夹具/错误预期，而非恢复生产常量。
- 最终 `population-final-*.log`：17套件、307测试、2956断言全部通过，
  覆盖所有失败套件及新增的标签继承、原存档对照、装备、复制、槽位属性与投放边界。
  标签域补测还纠正了旧“独立重算”脚本里的同一整行继承误读；它独立读取存档与配置，
  不调用克隆标签助手，但旧解释仍可能错，因此始终必须回到.c原方法。
- 最终17份日志无SCRIPT ERROR、ERROR、失败断言、孤儿节点或资源泄漏诊断。
  这是全量发现后的相关套件复跑，**不称为一次新的全量全绿运行**。
- `population-slot-input.log`：1920×1080、Vulkan实际窗口输入PASS，
  家业/浴场悬停、点击、手牌投放、拖出、回手和运行锁沿共用入口验证。
  此工具显式建立仪式夹具，不能证明浴场首次生成已正确。
- `population-parity.log`：3889文件逐字节一致，零违规；git diff --check通过。
- 最终严格开场路径打印 `[5000001, 5002006]`，不再误生成医院，跨第2/3日保持单份家业后继。

未提交或推送；保留前批未提交改动与用户旧存档。
