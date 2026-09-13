# 2026-09-12 下一天后续提交复审

**后续黑条修复（2026-09-12）**：已定位并修正粒子 Renderer pivot 的符号误用：-0.05×60=-3，旧代码反取 +3，使镜像遮罩重叠 12 单位。改为负偏移后，两边恰好按原作 54 间距接合；夜幕/白昼 18 个时刻的 GPU 连续性检查通过。原先“硬斜接缝仍待定位”的记录是修复前状态，不能作为当前结论；其他特效缺口仍保留。详 [黑条根因、几何交叉证据与隔离对照](NightMaskPivotCorrection.md)。

## 最新验收增量：跨日保存与整场景重建（2026-09-12）

下面的历史审计按发现时间保留；当前状态以本节为准。仍为 🟡，未通过全过场视觉验收。

实际发现：原作结算效果与关闭结果页是两个独立的等待点。旧重建路径只恢复前者，会少一次仪式最终确认；仅断言回合数增长的测试发现不了此问题。[SRC: RiteResultPanelController.c OnClose RVA 0x5a3ae0; dump.cs:325466 finalPromise@0xD8。]

已修：在 round_transition.rite_display 保存已提交结果的展示快照，重建后恢复文本、结果页和关闭等待，不重放效果。已被结算移除的仪式也能恢复最终确认。嵌套事件提示恢复后保持在仪式之上参与鼠标命中；准备页装饰和卡槽按结果阶段隐藏。只在真实关闭结果页后清除此快照。

| 状态边界 | 操作与结果 | 证据 / 限制 |
|---|---|---|
| 原作 auto_save 起点 | 经导入桥保留真实仪式/事件，连续第 1→2→3 天 | tests/test_next_day_resume.gd |
| 初始结果、嵌套提示、效果执行完但未关闭 | 写真实磁盘存档，释放整个 main，创建新 main 并继续游戏 | 每天必须恰好两次最终仪式确认；检查计数器/笔记不重复 |
| 重建后的输入层级 | 注入鼠标移动、按下、释放；断言命中具体按钮 | 嵌套提示先于结果页接收输入 |
| 夜幕进入及白昼进入中途 | 保存并重建，继续等待过场；连续跨两天 | 调度隔离样例通过持久化 disable_event 关闭事件，不用清空 event_runtime 冒充 |
| 稳定白昼 | 重建后回合、队列、显示状态仍一致 | 同进程真实内容回放；独立进程调度边界回放见下文 |
| 视觉 | 检查 GPU 截图中的结果页/准备页显隐 | 夜幕仍有硬斜接缝；缺 glow/sweep；不能登记像素级一致 |

日志：[GPU 跨日回放](next_day_resume_gpu.log)：2/2 测试、135 断言，91.672 秒；[UI 回归](next_day_ui_regression.log)：81/81、1071 断言。后者在最终补充恢复页显隐调用前运行；该补充由最终 GPU 回放覆盖。两份日志无 SCRIPT ERROR、ERROR、ObjectDB/RID 泄漏或孤儿诊断。

截图：next_day_runtime/clone-day-{2,3}-{restored-prompt,restored-result,enter,ready}.png；原作对照同目录 original-night-*.jpg、original-day-*.jpg。源材质 _MASK_R_ON 对应 DXBC blob30 的 alpha 采样（不是 red）；FORWARDBASE 实际 ZWrite=0，材质序列化 _ZWrite=1 不能替代 pass 状态。负缩放 billboard 的几何转换仍待确认，不加自制渐变遮盖接缝。

独立进程补验：`tools/verify_next_day_restart.ps1` 启动六个不同 PID 的 Godot 4.7 GL 进程（8316、27424、25556、29840、27296、11672），依次验证 start/夜幕读档/白昼读档/第二次夜幕读档/第二次白昼读档/第三天稳定读档。合计 **62 项检查，零失败**，日志没有引擎错误或泄漏诊断。每次均从隔离磁盘存档加载，核对完整 transition 字段；两次跨日都由真实鼠标输入发起并检查控件命中，夜幕完成前不加天，日间完成后释放锁。脚本禁止默认玩家存档路径、禁止 start 覆盖旧夹具；日志和 GPU 截图在 [process_restart](next_day_runtime/process_restart/)。这是禁用事件/清空仪式的调度边界测试，不代替上面的原作内容回放，也不代表原作界面像素对拍通过。

贴图补验：从原作 `sharedassets3.assets` path_id 258 读取 ND_text_mask04，与克隆 PNG 的 RGBA 字节完全相等；垂直翻转后反而不等。原采样器为线性、Clamp，与现有 shader 相符。见 [texture-check.json](next_day_shader/texture-check.json)。不能把接缝归因于 PNG 翻转、错误纹理或采样器，也不能仅枚举看似顺眼的变换组合后将其登记为原作事实。需要进一步读取原作实际粒子顶点/UV，确认 billboard 缩放、旋转及负缩放如何生成最终四边形。

剩余：投骰/选择尚未提交阶段的完整恢复、原作同状态逐帧/声音对拍、真实内容在独立进程中断结算、新局及所有覆盖层输入矩阵、女术士重抽替换。原作女术士的交换页关闭返回默认菜单已实机确认；尚未实机完成拖入交换，不能将现存桌面 RedrawSudanButton 算成原作入口。

范围：截图中 09:43 的反馈对应 3eb6e6cb（09:54）开始，复审至 0f96e6e0，并核对当前未提交修正。8b9f588a 作为前置对照。按 git show 实际内容审查，不信任提交标题的完成度。

| 批次 | 确认的问题 | 本次处理 / 剩余状态 |
|---|---|---|
| 3eb6e6cb | 自制 _unhandled_input 以全局矩形在按下时推进；无可见性门。测试直接调用未连接处理器却叫 real mouse | 删除该入口、两个失效转发方法及按帧去重；只保留 Button 输入；用视口输入测试替代 |
| 12813f38 | Label 输入与额外兜底进一步叠加；详情层只测可见性不代表点击正确 | 删除遗留输入方法；详情层级规则保留为待原作完整复验，不能反向猜改 |
| 6770055b | 0.18/0.28 秒、alpha 0.72 的黑幕无背书；未等待夜幕便执行 RoundLoop；用继续点击推动已有过渡 | 黑幕已在 d2835911 删除；本批修正文档。Promise 时序仍缺失，不继续编造参数 |
| ef3a05ef | “前两日端到端”实际仅直接调用处理器、round==2、内存序列化；遮罩存在或队列为空的 OR 可空通过 | 测试改名并注入视口按下/释放、断言目标命中，比较 round_transition 序列化；明确不是第二天结算/重建验收 |
| 74bf3530 | 只断开父级连接，未删除仍执行的全局兜底；文档已撤回但测试仍造假覆盖 | 本次清理所有三条遗留入口，移除伪真实输入测试 |
| ca07d54e | 文字 hover 用了罗盘内盘矩形；隐藏按钮后无恢复路径 | 上批已修正独立文字图。本批 refresh 从 round_transition 恢复可见性，测试过渡期间刷新仍隐藏、结束恢复 |
| d2835911 | 删黑幕但仍函数名 play_next_day_transition，只有 hide | 标为占位表现，不能当动画验收；不是完整过场 |
| 0f96e6e0 | 未看 next_day_0 图像就称它有文字；错误解释隐藏 Label | 上批直接查看确认是罗盘内盘，普通文字来自 main/next_day.png |
| 917064d9（已回退） | Unity (1,0) 错认右上，没有运行截图就提交；diff --check 失败仍接着提交 | 当前仍基于 0f96e6e0，右下不再移动；AGENTS 已补坐标与资产核验 |

原作顺序证据：GameController.__c__DisplayClass142_0.c b__0 0x5705b0 显示 OperationMask，b__1 0x570700 返回 controller+0x1A0；dump.cs GameController 确认 0x1A0 是 NextDay_NightEnterPromise，不是无名“round_transition”。b__2 0x570720 触发 OnRoundEnd，b__3 0x570790 增加 round；b__9 0x571000 在 SaveRoundBegin 后释放 OperationMask 并置 UserStage。完整动画/等待链未移植。

新的显示恢复只是克隆稳定态修复，并非原作动画重启机制的完整映射。未建立的运行时证据保持缺口，不能用这条修复推导原作何时重显所有视觉对象。

仍待修正：夜幕/白昼/旋转的真实动画与 Promise 门；原作钟面点击区裁剪（Image 11619 raycast padding）；详情/仪式覆盖完整点击矩阵；桌面自制 RedrawSudanButton；连续第二、第三日及重建场景后的原作存档对拍。卡槽候选顺序问题不在这批提交中得到证明，不应声称已经修完。性能反馈本批未量测。

流程教训：提交标题、函数名、测试名都不是证据。删除补丁必须追踪对称的恢复路径、遗留处理器、测试和文档；局部读档字段相等不能替代重新创建 UI。检查命令失败要停止，不能用分号继续提交。

扩展 UI 回归又发现：test_game_screen_can_open_card_detail_overlay 仍断言已禁用的 NextDayLabel 可见；test_game_screen_right_actions_do_not_duplicate_rite_entry 的 SRC 注释伪称 RedrawSudanButton 来自 Next Round。已改测图像文字并纠正来源说明。这里的详情可见性测试依旧仅是布局测试，不能宣称详情输入已验收。

前置 8b9f588a 的 JSONC accessor 修复确实避免对重复成员 Array 调用 Dictionary.get；但是 `_successes_for_result` 仍取第一个 r 条件阈值、缺省 5，配套测试只证明不崩溃及旧聚合规则。没有双信号证明其适用于所有骰子结果显示，本次不把这个异常修复升级为完整骰子 UI 正确性。

本批验证：UI 布局 81/81、1071 断言；开局及视口点击 2/2、41 断言；文字/隐藏点击/恢复显示 1/1、20 断言。三份日志保存于本目录 next_day_*_regression.log，无引擎错误、泄漏或孤儿诊断。总计 84 测试、1132 断言；不是原作前两日完整验收。当前改动保留在工作区，未推送。
