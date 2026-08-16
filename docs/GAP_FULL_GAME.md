# 完全复刻差距清单（2026-08-15，审计修复收口后）

> 目标：完全复刻、完整可玩的原作级游戏（用户 2026-08-14/15 指令）。
> 本文档是 `AUDIT_2026-08-15.md` 修复收口后的剩余差距路线图。
> 状态标记：✅ 完成 / 🔨 进行中 / ⬜ 待做。

## 1. 规则引擎（DSL）

- ✅ **DSL 三类全支持归零**（result 2119、condition 3988、action 2285，`tmp/dsl_audit`）：引导键族（begin_guide/close/cues）、table/total 域 equip、scoped 改名/改文全部落地
- ✅ `rebirth.s1/s2`（8 处）——槽卡倒计时重置（RebirthSudanCard 0x519d60 + b__4_0 set_life(0)）
- （原 action 94 键条目已完成，见上）：新手引导 UI 演示族（hand_pop 60、rite_pop 8、focus 7、slide、begin_guide、
  close_* 族、hand_pop_gamepad/normal）、`difficulty`、`magic_sudan`、`change_desk_bg`、
  `change_location_icon`、`table.change_card_name.<rite>_<seq>.<id>`（报告五 A5）
- ✅ `difficulty`（中途难度切换：apply_difficulty）与 `magic_sudan`（引导演示指令，无向导宿主记 no-op）

## 2. 表现层

- ✅ 卡面：1190/1292 原作卡画接入（102 张原作无独立图，自制纸面回退）
- ✅ 桌面：原作双层底图（table.png + table-map.png）
- ✅ 音频：GameAudio（main/tutorial BGM + 下一日/确认/重抽/苏丹四族抽卡/骰子/金骰）
- ⬜ 仪式图钉与原作点位精确对位（MapController 布局参数，需实机对照微调）
- ⬜ 卡片拖放音（card-begin/end-drag、drop_card_copper/silver）、事件弹窗出现音
- ⬜ BGM 分层切换（main_game_level2/3 的切换条件）、结局 BGM
- ⬜ Live2D（原作卡面 Live2D 模型，语料库 live2d/ 目录已有提取；第一版静态图的既定策略）
- ⬜ 苏丹卡特殊视觉（稀有边框、倒计时红光等原作细节）

## 3. 系统

- ✅ 新手引导：BeginGuideBar（15 类指引文案+绑定键提示）、begin_guide/close_begin_guide/cue 键族、存档往返
- ⬜ 向导剧情流（WizardController 完整流程、魔法苏丹演示）
- ⬜ 难度"魔法苏丹"（difficulty、magic_sudan 键；原作高难度变体）
- ✅ 结局展示：over.json 159 结局表接入（名/副题/文本/后日谈标记），处刑与事件 over 值驱动 ending id
- ⬜ after_story 后日谈播放（StreamingAssets/config/after_story/ 配置已定位）
- ⬜ 笔记系统（原作 add_note.ogg 暗示；NoteController 类未审）
- ⬜ 图鉴/画廊（Gallery* 类族未审）
- ⬜ 成就面板（steam_achievement 保持空实现，面板可选）

## 4. 内容验收

- ⬜ 实机通关对照：首周完整链（上朝→权力的游戏→标签移除）、苏丹四族卡体验、
  回退/重抽/重掷/金骰的实机节奏
- ⬜ 长线内容抽查：随机事件链、淘书/家业/俺寻思的深度分支
- ⬜ 存档兼容回归（v5 边界不被新系统破坏）

## 执行顺序建议

1. rebirth 语义确认与实现（DSL result 归零）
2. 新手引导系统（解锁 action 60+ 键 + 新玩家体验闭环）
3. 难度魔法苏丹 + 结局展示（难度循环完整）
4. 图钉对位/拖放音/BGM 分层（实机反馈驱动）
5. 笔记/图鉴（外围系统）
6. 实机通关对照与内容抽查（持续）
