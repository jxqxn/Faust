# 基础循环双端对拍与原创阶段收尾

2026-09-14；起点 main / b5ca1f9ea1acab1bf99ce22ac3f145bcf618b1e0。全程本地，无联网、提交或推送。运行时 content/ 未改。

## 30 秒结论

**“治理家业 → 结算关闭 → 次日”已取得原作实机裁判并完成克隆重放，但结果等价验收未通过。** 本批修复了共享规则与跨日提示的一组确定性偏差；不得将这条实测完成写成完整复刻完成。

原创内容已从零散讨论整理为[下一阶段成果](../design/next-stage-handoff.md)，包含机制、美术、证据纠错和研究资料。正文区移除旧版平行结论，原字节归档可核验恢复。

## 原作裁判与实际操作

原作版本 1.0.2feaceb3，buildguid 2feaceb3d0bc4398a7a056d700aef121。裁判根目录：`C:/Users/User/Documents/Faust-dual-replay-20260914/`。原始文件保留在该目录，不复制完整原作存档进仓库。

起点 original-before.json 为第4天，SHA256 `258a3a8831a9b1c8727cc47a7504b0124047b61b77b40a81e86d8ba1aca7d2e6`。原作真实输入：继续游戏 → 打开空槽家业 → Escape 未关闭 → 准备面板取消 → 下一天 → 等待并关闭上朝结果 → 等待并关闭家业结果 → 关闭 TIME_OUT 与 BACK_ROUND 两个引导 → 保存退出 → 继续 → 保存退出并结束游戏。

原作家业文本为“人们仍然愿意来到你的屋檐下，分享言语、允诺，与机会。你没有派遣任何人治理家业。没人管理，当然就没有收入。”上朝消耗3谗言、权力−5钳零、苏丹倦怠+1；本次抽到仪式5001016及2001051苏丹的耐心一堆4张。期限4/7→3/7，苏丹卡life4→3。

original-pretransition.json、original-after.json、original-reloaded.json 分别记录跨日前、第5天就绪及原作重载。后两者只有 saveTime 不同。14张过程截图位于 original-captures/；文件名02-preparation-closed实际上未关闭，09-next-day-ready仍有第一引导，10-warning-dismissed仍有第二引导；11/12才是引导均关闭后的状态。动作表已经注明误命名。

**用户原作存档已恢复：原15文件逐个SHA256一致，现场15文件，无额外文件。** 凭证 original-restoration-receipt.json；测试新增数据另存 original-save-after/full/，未遗失。

## 克隆重放及失败差分

tests/test_household_dual_replay.gd 只导入 before，不注入 expected；真实 InputEventMouseButton 输入并断言命中，等待结果文本提交再关闭一次，在家业最终关闭前保存并重建场景，关闭两个引导，比较次日54字段，再落盘重建比较54字段。没有裁判路径时明确 pending。

最终专项日志 dual-final.log：1项测试失败，174/188断言通过，28.818秒，退出1。**次日47/54投影一致，重载后同样7项不一致。** 7项不是7个独立机制错误，其中包含比较器误报：

| 投影 | 原作 → 克隆 | 判断 |
|---|---|---|
| next_rite_uid | 28 → 27 | 仪式生命周期/生成链仍不同 |
| timing_rounds | 531080900：8 → 10 | 同一事件时序计数不同 |
| hand_membership | 原作独有34/42/46；克隆独有33/35/53/100 | 与吸附和仪式生成联动 |
| table_operation_root_membership | 同上 | 不是新增一组独立卡数量问题 |
| rites | 原作妓院5002004/uid26/s1=53，克隆缺失；上朝与淘书吸附对象不同 | 原作淘书uid27，克隆uid26；需追事件5300012、loot6000019及吸附顺序 |
| bag_positions | 克隆多UID221=[0,1] | 已移除墓碑仍被投影纳入，属比较器缺口，不是活卡位置差异 |
| gen_tags | ennui：4 → 3 | 生成历史计数仍不同，不能用当前标签总量代替 |

上朝槽：原作s2=41/s3=33/s4=100，克隆s2=41/s3=34/s4=42。淘书槽：原作s2=35/s5=67，克隆s2=46/s5=67。本次随机掉落碰巧相同，不证明随机流一致；此前GPU留档掉落不同，未搜索种子或回填结果。

独立工具 tools/compare_household_replay.py 输出 independent-card-comparison.json：双方215个卡对象，已承载字段没有数值差异；27张未用苏丹池对象合计162个字段未承载、无法比较。UID41的英文ennui与中文倦怠合并后等值（3+1=4），原始编码不同。这个规范化仅证明该字段有效合计，不能证明所有消费者均正确，也不消除 gen_tags 历史计数差异。

克隆多出 pop.5001001_result_05_1.s2、rite.5001016、card.2001051 三个提示，原作本次没有相应全屏确认。截图亦见字体粗细、项目符号、段落间距、手牌大小/顺序及背景尺度差异。原作2560×1440、克隆1920×1080，需归一化比较。未做音效和动画逐帧对拍，**不能签署表现1:1**。

## 本批共享规则修复与来源

以下为已实施范围，完整系统仍按 METHOD_MAP 保留🟡。引用均为只读语料 decompiled/ 与 il2cpp_dump/dump.cs；原始JSONC/真实存档为独立信号。

| 修复 | 原作方法与独立信号 | 边界 |
|---|---|---|
| 裸sN/!sN限定当前仪式 | SlotExists.IsSatisfied 0x408b70；ConditionContext.cards@0x28，dump383855 | 不读别的仪式同编号槽 |
| 裸标签在友方卡集合累加后比较 | HasTag.IsSatisfied 0x3fe5a0；ctor0x385d90、GetFriendCards0x392470/0x393840；friends@0x30 | 无仪式旧调用兼容路径仍待普查 |
| 非负计数器从原variable注册 | SetCounter0x38f2d0；DoInit闭包0x45c620；special_counters@0xC0/dump387317 | 新局、反序列化共用 |
| event_status仅保存覆盖值 | GameController.Start0x557e10；GetEventStatus0x38d1c0/dump388759；auto_start_init | 缺override按配置身份恢复默认事件 |
| timing标识使用所有on成员序号 | Timings.SetIdentify0x3a9520；dump395269及重复原JSONC | 保留重复成员与作者顺序 |
| InitRite首见/UID失败回退 | InitRite0x38e140；new_born@0x20/dump392398、once_new@0x50/dump393182；StartRite.Do0x51bcf0 | 只在新建时记StartRite笔记 |
| loot保留num与堆叠语义 | GenLoot.RealGenCard0x512260；Item.num@0x24/dump385930；loot6000051 | 可堆叠一实例N，否则N实例；其他生成族不自动获认证 |
| 引导关闭分发原timing | BeginGuideController.OnClose0x526040→OnCloseBeginGuide0x4f94d0；CloseBeginGuide.IsValid0x45eb80/context@0x38 | 布局与文案仍有近似 |
| CleanRite先返卡再移除 | 闭包0x506ed0/0x507290的ReturnCards调用 | 完整OnRiteClean异步回调未闭合；CleanSlot部分堆叠预算另待修 |
| 跨日恢复产生提示后刷新界面 | Prompt.Do0x519340→ShowPrompt；dump315672/320094；event5300097 round_begin_ba/success.prompt | 修复第3天有pending却无浮层导致停住 |
| 导入比较排除移除墓碑 | 原作cards/rites嵌套与原作存档独立对照 | 对象数与per_id_counts修正；bag_positions尚未修正 |

新增8项边界回归。旧合成测试明确清空无关默认事件；集成卡放入真实家业实例而非全局假槽。没有删掉实际裁判断言来制造通过。真实第1→2→3天、嵌套提示及磁盘重建专项2/2、129断言、退出0。

gen_tags 后续已有源码入口但本批未擅自扩大实现：CardExtensions.AddTag0x37e6a0经ValidateTagAttributes后调用CommonFunction.MarkTagGen@0x48；dump383591/383603；GameApplication.DoInit闭包0x45c500→PlayerExtensions.MarkTagGen0x38e6e0。应核实 ResultExec._mutate_tag 的ADD/SET及转换门，再接共享规则，不硬改本次计数。

## 测试与证据等级

最终全量console GUT：**74脚本、774项，772通过、2 pending，7444断言，703.114秒，退出0**；log与console均未发现SCRIPT ERROR、ERROR、泄漏或非零orphan诊断。两项pending分别为本轮未传外部裁判的双端测试和headless不运行的GPU夜幕。独立GPU专项通过，独立双端专项失败；不能把772通过与两项补测合并写成774通过。最终运行时代码在全量启动前已固定，未混用早先失败轮总数。

| 其他检查 | 结果及范围 |
|---|---|
| content字节对拍 | 3889文件，0违规 |
| 独立JSONC成员树 | 3889文件，0差异；842文件含2966组重复成员；解析错误0 |
| 静态DSL | condition/result/action未识别各0；候选744仪式/1026事件/73loot/871卡；不是运行可达证明 |
| 原第1天两份样本 | 各54项同刻导入与JSON往返零差异；不能证明未来结算 |
| GPU夜幕专项 | 1/1、18断言、退出0；只证明克隆连续性 |
| 修复后专项 | boundaries8/8；next_day_resume2/2；integration14/14；其余见日志 |

静态审计与早期日志根：`C:/Users/User/Documents/Faust-phase-close-20260914/`；实际双端及最终回归根：`C:/Users/User/Documents/Faust-dual-replay-20260914/`。精简字段、哈希与最终计数见[机器报告](phase-close-20260914.json)。早期765测试结果仅作历史记录，不是当前代码最终验收。

## 状态矩阵与下一验收门

| 边界 | 本次证据 | 状态 |
|---|---|---|
| 原作第4天正常准备 | 实机空槽、取消、前态存档 | 已采集 |
| 结果关闭/阻塞/引导 | 双端实际输入，克隆文本提交后关闭，额外提示已记录 | 差异未闭合 |
| 次日正常可操作 | 双方第5天；47/54一致 | 未通过 |
| 磁盘保存/场景重建 | 克隆中断重建及次日重建；原作退出继续 | 差异稳定复现 |
| 新局完整原作轨迹 | 仅历史样本和克隆专项 | 未覆盖 |
| 动画/音效/布局 | 过程截图及克隆夜幕专项 | 原作全过程未认证 |
| RNG | 原random_cache为空不等于完整Unity RNG状态 | 未同步 |

下一批继续本表中的仪式生成/吸附、标签历史计数及提示上下文链；以现有失败裁判为基线，并取得随机调用序列或隔离随机输入。相同整数seed不能保证Godot与Unity输出相同。不得换seed挑中结果，也不得用克隆结果生成expected。修复后重放同起点、真实输入和读档，再扩展其他家业分支/上朝/俺寻思/淘书及失败终局。

## 原创材料收尾范围

已检索58条Faust Codex与8条ZCode任务元数据，提取18条相关本地会话正文；旧材料35文件含29份实质来源和6个生成侧文件、483个标题，逐字节ZIP归档并登记去向。正式阅读面为4份设计正文、1份详细研究总报告和1份研究入口。92条主张/92条来源保留可追溯编号；已否决方案、AI自行追加的约束、未实测参数均纠正强度。

可访问本地会话与现存导入材料已整合；未取得全部平台网页原始对话，不能宣称全平台全量穷尽。正文记录已确认、建议、未决和反例，归档不再具有当前指令效力。没有把复刻参考证据当零碎创新文件删除。
