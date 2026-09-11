# 残留清单收敛（2026-09-11）

## 已修复

- **桌面操作族**：table/g 的标签、装备、装备槽、稀有度与清除统一遍历 Player.cards；不以 context.card_uid 或 rite_uid 改写目标域。total 标签操作使用 GetTotalCards，对桌面和仪式内根卡生效，排除嵌套装备。改名/正文之前已改用相应源域，本批复验保留。
- **清除数量**：DesktopCleanCard.DoTemplate 0x4f8250 / callback 0x5208b0 对正数使用堆叠单位预算，<=0为全量；部分扣除保留实例，完整扣除才移出并触发 card_clean。旧测试把 table.clean 当作上下文槽清除，已按原作纠正。
- **身份冲突**：原 GetNextCardUId 0x38da40 统一发号；原 AddCard 0x38b620 与 AddSudanCard 共用 Player.card_uid_index。本批池卡和普通卡使用同一计数器，原作样本 protagonist UID29 对拍通过。此前两套从1开始的发号会让抽卡覆盖普通实例，现增加防覆盖断言。
- **旧档兼容**：不重写磁盘旧档。加载时保留所有现存普通卡 UID，仅为冲突的未抽池对象分配新 UID。已经被历史错误覆盖的内容不伪造恢复。
- **成员顺序**：player_card_order 对应原 Player.cards 列表顺序，和手牌显示 rail/bag 排序分离。原作导入保存原 cards 数组顺序；桌面操作、total、支付候选及自动吸附读取统一列表。入槽移出该列表、回桌面尾插。hand/rail 保留为现有宿主视图，不再充当这些操作的成员顺序。
- **图鉴叠字**：GalleryCardInfo.prefab Confirm 为勾号图片；移除额外“确认”。
- **旧字段**：world_spawn_id / world_position_ratio 无运行时消费者，移除定义、重置、序列化及恢复；旧档附带这两键仍可加载。set_world_scene_blocker 当前承担模态输入屏蔽，保留。
- **过时记录**：METHOD_MAP 已明确改名框220固定高度、缓存Shaker近似属于被后续批次取代的历史记录；没有重复改写已经有原作证据的实现。

## 源证据入口

- DesktopModifyEquip.DoTemplate 0x50d820；DesktopModifyEquipSlot.Do 0x50d330；DesktopModifyRare.DoTemplate 0x50df50：读取 Player+0x88，交给 OperationFilter.Filter。
- TotalModifyTag.DoTemplate 0x51d6c0 → PlayerExtensions.GetTotalCards 0x38de90。
- DesktopCleanCard.DoTemplate 0x4f8250 与 DisplayClass5_0 callback 0x5208b0；dump.cs Desktop 操作族注册。
- PlayerExtensions.AddCard 0x38b620 的 Player+0x40 UID 递增、Player+0x88 列表 Add；GenSudanCard 0x54f6f0 搬移同一池对象。
- save_samples/auto_save.json 原始 cards 顺序、初始主人公UID29为独立信号。

## 原始配置基准已获授权并修复

**用户已明确批准“允许改用原始配置并升级校验”。**原版 StreamingAssets/config/event/5300066.json 同一 action 依次包含 rite=5001001、rite=5001501、event_on=5300029、rite=5000001。data/config 的普通JSON整理过程把重复键折叠，前两个仪式被丢弃，事件先后顺序也被改变。现有 3889 个 content 文件已逐字节换为同路径 StreamingAssets 原文件；没有添加默认仪式或手写剧情补丁。

原作 OperationJsonConverter.ReadInternal<object> 0x70d1d0（OperationJsonConverter.c）逐个读取属性，调用 OperationManager.GetOperation 后追加 List，明确不是先生成键唯一的 Dictionary。原存档第一天 notes 中四个仪式是独立信号。

工具 `tools/audit_source_duplicate_keys.py` 只读审计原始JSONC：当前已集成范围内842文件、2966组重复属性、0解析错误；全部位置在 `SourceDuplicateKeys.json`。属性类型不同，不能把每个重复键都武断当作可执行操作。

AGENTS.md 与 check_content_parity.ps1 已改为原始 StreamingAssets 基准。SourceJSON 直接读取 JSONC，操作/条件/时机中的重复成员保留为有序运行时列表；普通数据节点仍是 Dictionary，未分类的重复节点字段报错。两处重复 settlement.action 按原 reader 的既有 Operations 追加：DataNode.Json.RiteNode_Settlement_JsonHandler.__c b__0_6 0x3ee140（先取 +0x38，传入 OperationJsonConverter.Read，再写回）；不是覆盖旧 action。

- 条件：ConditionJsonConverter.Read 0x386350 逐项追加 List<ICondition>；AND/OR 逐项短路，重复 any/all 不丢弃。
- 原始槽支付条件：Python object_pairs_hook 独立扫描确认1495个仪式定义中665个包含 cost 条件；旧归一化字典统计653个，漏掉12个仪式的支付分支。测试辅助遍历同步支持重复条件列表，没有把旧统计值继续当作裁判。
- 时机：TimingJsonConverter.Read 0x3a7bc0 逐项追加；7 个原始事件里的重复 rite_end/card_clean 现在保留所有候选。
- 操作：OperationsSequence 用操作条目游标而非键名游标；choose 按条目选取；选项、分支和嵌套事件暂停后仍按原序继续。
- 存档：序列帧的 operations_json 与延迟的 payload_json 保留嵌套顺序，不受外层 JSON 键排序影响；兼容旧 source_json/keys 帧和无 payload_json 的延迟条目。
- DSL 审计：按所有重复项计数，继续递归 all/no_show/no_prompt/success/failed/case/choose/delay，不再跳过列表。
- 配置校验：SHA256 字节对拍后，再用 Python object_pairs_hook 的独立完整成员树对拍 Godot 读取结果。两层均检查 3889 文件、零差异。缺语料、缺校验运行时、解析报错或未完成输出均判失败。
- Git：content/** 禁用换行转换并保留原有尾部空格，确保后续 checkout 仍保持原文件字节。

## 验证

新增 tests/test_desktop_operation_domains.gd 覆盖跨域装备/装备槽/稀有度、total不递归装备、堆叠清除、UID不覆盖、旧池碰撞兼容和排序分离。test_source_json 覆盖重复条件、JSONC 字符串、重复操作的两次暂停存读档、choose/延迟顺序、原始多时机和配置缓存隔离。test_opening_ui 从真实新游戏入口操作，按原 auto_save notes 对拍奖励卡和四个开局仪式；test_startup_rites 覆盖至第三日。最终回归数字见 METHOD_MAP。

本批修复与之前批次的相关改动一并纳入本地提交。测试日志在 C:/Users/User/Documents/Faust-cleanup-20260911/converge-*.log。

### 最终验收（原始配置迁移）

- 首轮全量 raw-full.log：746项中742通过；4项失败分别是旧音乐表顺序、两项测试成本遍历/计数、仍引用旧归一化文件的quest字节检查。修正基准与遍历，保留失败日志供追溯。
- raw-full-final.log：67脚本、747/747测试、7042断言，603.854秒。无 ERROR / SCRIPT ERROR、孤儿节点及退出泄漏。
- raw-reader-final.log：追加旧同步适配器读取列表的兼容修正后，8/8测试、28断言。包含重复成员、两次选项/提示暂停存读档、延迟内的唯一键顺序、原始多时机、缓存隔离与旧 source_json/keys 帧兼容。此组复验与全量有重叠，不能把测试数直接相加。
- raw-opening-rendered.log：真实1920×1080 Vulkan渲染，新游戏入口与选择/确认链1/1测试、34断言；奖励卡与四个仪式按原auto_save notes对拍。截图 opening_wife_confirm.png / opening_reward_hand.png 已更新并目视检查。
- raw-parity-final.log：3889文件SHA256零违规；Python独立完整成员树与Godot运行读取3889文件零差异；原始842文件的2966组重复属性均保留。raw-parity-missing.log证明缺少裁判语料会失败。
- git diff --check 通过；原配置的混合缩进、尾部空格与换行保留，不为消除Git格式提示而改写原作文件。

配置无损与这些边界通过，不等于全部未知DSL、所有页面和动画已完成像素级验收；余项继续以METHOD_MAP登记为准。
