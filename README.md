# Faust

在《苏丹的游戏》规则复刻底座上，创作魔力之都的校园自走棋，让具名人物的养成、关系、行动与后果进入同一核心循环。

## 当前状态

复刻工作已解冻，目标为完整还原；目前可玩，但**尚未证明基础循环结算等价**。2026-09-14 已实际采集原作“治理家业→结算关闭→次日”并在克隆中重放，修复多项确定性偏差，仍有随机轨迹、状态与表现差异。不要用外观接近或 GUT 通过代替原作验收。

- [全部知识与材料入口](docs/README.md)
- [对拍证据、测试与缺口](docs/replica/verification.md)
- [原作方法映射与复刻 TODO](docs/METHOD_MAP.md)
- [原创阶段成果入口](docs/design/next-stage-handoff.md)
- [研究数据与来源](docs/research/README.md)

旧横版场景、独立校园菜单、小丑牌式动效和冻结期计划是历史探索，不是当前正式产品约束。原始创新资料已整合，旧副本仅在 Git 历史保留，正式决定集中维护，避免旧结论反复误导。

## 运行与验证

Godot 4.7，GDScript，GUT。运行时内容直接读取 content/ 中原始 JSONC，保留重复操作及顺序；配置字节和原作 StreamingAssets 对齐。源码语料位于相邻 Faust-local-source 工程，只读。

```powershell
# 本机引擎路径可通过 -GodotPath 显式指定
& tools/run_gut.ps1 -GodotPath "C:/Tools/Godot/4.7-stable/Godot_v4.7-stable_win64_console.exe"
& tools/check_content_parity.ps1
& tools/check_design_research.ps1
py -3.12 -X utf8 tools/check_innovation_archive.py
```

双端对拍还需要审计文档列出的外部原作证据目录；缺少裁判的 pending 不是通过。严格检查日志中的 SCRIPT ERROR、ERROR、orphans 与泄漏及进程退出码。

CardInstance 以 UID 维护实例标签、数量、装备和位置，RiteInstance 保存具体槽位归属。Queue/Save 保存未完成操作及过渡，实际兼容版本以 sim/save_system.gd 和测试为准，不沿用旧 README 的 v5 断言。

## 资料与资产

原作及其资产权利属于原权利人。本仓库的复刻研究素材不自动成为原创发行可用资产；原创资产生产与许可另行记录。
