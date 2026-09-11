# 结局地图特效槽位与地点位置规则（第二十七批，2026-09-10）

本批处理 A16（`Eft_End_Map` 粒子层缺失）与 A18（`drawn_round` / shuffle 比较），并把 A15 的两条已确证事实落档。

## A16：`Eft_End_Map` 结局地图特效

### 原作事实

- `GameScene.unity` 有 GameObject **`Eft_End_Map`（fileID 2574，layer 6）**，挂 Transform 4141：`localPosition (0,0,0)`、`localScale (200,200,200)`，且 **`m_IsActive: 0`**（关键：**它在场景里就是一个空的、未激活的 Transform 容器**，粒子子物体是运行时实例化的）。
- 另有一个 GameObject `Eft_End_Start`（2656，layer 5，同样 inactive），由 MainUI 上同脚本持有。
- `MapController.ChangeBGToEnd 0x567b70` 的**最后一条语句**是 `GameObject.SetActive(param_1 + 0x78, true)`；字段身份由 dump.cs 独立确认（`MapController.bg@0x68 / bg_end@0x70 / EftEnd@0x78`）。
- 该方法前三步：① `bg` 的 Image 换成 `bg_end`（sprite 在 `+0x70`）；② 遍历 `locations@0x38` 的每个子 Image，取其名字到 `Datapool.GetEndMapSprite` 查表并替换；③ 激活 `EftEnd`。
- 调用点：`OnNextRound b__5 0x570850` 的终局分支（`+0x1f8` 为真时先 `SetActive(+0x1f0)` 再 `ChangeBGToEnd(map)`，然后清 `+0x1f8`）。

### 克隆偏差（已修）

克隆的 `change_bg_to_end()` 已实现前两步（`end_map.png` 图集 + 逐地点换帧），但**没有第三步**：既没有特效槽节点，也没有激活动作。

### 修复

- `MapController` 新增 `_eft_end_map: Control`，在 `_build_eft_end_map()` 里建为名为 `Eft_End_Map` 的节点，初始 `visible = false`，并留 `source_active_at_start=false` / `source_particle_children_unported=true` 两个元数据。
- `change_bg_to_end()` 末尾按原作补上激活。
- **不发明粒子层级**：导出包里这个槽位没有可直接搬运的 ParticleSystem 数据（场景里它本身就是空 Transform），所以克隆只承载"槽位 + 激活语义"，与 A16 原登记口径一致（"未用自制粒子冒充"）。

## A18：`drawn_round` 与 shuffle 比较

### 已确认

- `drawn_round` 全仓只有写点：`original_save_importer` 写导入值、`save_system` 序列化/反序列化、`RoundLoop.ActiveSudan` 字段本身。**没有任何读取方**，因此它不可能影响判定或抽取。
- 存档里也没有出生回合字段（`Player.sudan_card_pool` 的对象只存 uid/count/life/tag/bag/bagpos），所以"反推"本来就没有依据。

### 修复

1. 把报告文案改为如实说明：出生回合在存档里**没有承载字段**，故记为导入当刻 `round`，且该字段只随存读档往返、未参与判定。
2. **删除已过期的 "sudan_deck 顺序" 近似条目**：第二十批把池改成有序 `List<Card>` 之后，桥新增的 `sudan_pool_objects` 行是**按 uid 的精确逐对象比对**（card_id/count/life/tag 增量），顺序不再"无意义"。同时加断言禁止该近似条目复活（`assert_false(... contains("sudan_deck"))`）。
3. 在 diff 处补注：两侧都是有序 `List<Card>`，故池的比较是精确的，多重集行保留为第二重校验。

## A15：两条已确证事实（保持"部分已核"）

- **"特殊仪式位移"其实不是位置分支**：`RiteController.Init 0x58ae00` 用 `GameController.GetLocation(controller, rite+0x50)` 按**位置名**取 `RiteController.position@0x40`，再 `RitePosition.AddRite`。
- `RitePosition.AddRite 0x4636e0`：加入 list 后 `SetParentNormalize(rite.go@0x58, this, (count*100 − 100, 0, 0))`；`GetPosition(count) 0x463840` 返回 `(count*100, 0, 0)`。**同地点多仪式 = X 轴每 100 单位一档，与 `type` 无关。**
- `RiteNode.type@0x30 = RiteType{NORMAL=0, END=1, ENEMY=2, TREASURE=3}`（dump.cs 9597），配置分布 NORMAL 1394 / END 41 / ENEMY 44 / TREASURE 16；`RiteRender.Init 0x59a9e0` 按 1/2/其它分三支，那三支管的是**表现资源**（outline sprite、位置表选择、特效对象），不是位移算法。
- 克隆的 12 张地点表（Palace/Treasure/Enemy/Parish/Outside/Blackstreet/Skill/SelfHome/Harem/End/Uptown/Downtown）与此结构一致。

**未解（A15 仍未完成）**：各地点表的**基准坐标**在导出数据里找不到承载——GameScene 里没有带 `rites` 字段的 RitePosition 组件（字段未序列化），`Location.prefab` 是空壳，语料也未导出 .cs 源码。因此表内数值仍未对拍，保持可替换。

## 验证

- 新增/扩展 `tests/test_situation_desk_tabletop.gd`（14 测试 / 149 断言）：`test_change_bg_to_end_switches_the_eft_end_map_slot_on` 断言槽位存在、初始隐藏、无子节点、`end_open` 重放后被激活。
- `tests/test_save_import_bridge.gd` 6 测试 / 86 断言，含新增的"不再有 sudan_deck 序近似条目"断言。
- 全量 GUT 见收尾记录。
