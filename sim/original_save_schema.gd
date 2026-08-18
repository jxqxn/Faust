class_name OriginalSaveSchema
extends RefCounted

## Original-save schema and clone-v5 field mapping (clone methodology pillar 2:
## original artifacts as judge). Ground truth is the IL2CPP Player class
## (dump.cs:391488, JsonSerializable) cross-checked against the real saves in
## the corpus save_samples/ directory (auto_save.json, save_slot_000.json).
##
## Statuses:
##   mapped   - clone v5 has a counterpart with the same semantics
##   semantic - clone has a counterpart with structural/semantic drift
##   missing  - clone has no counterpart (tracked in METHOD_MAP section D)

const STATUS_MAPPED := "mapped"
const STATUS_SEMANTIC := "semantic"
const STATUS_MISSING := "missing"

## field -> {type, clone, status, note}. Insertion order mirrors dump.cs
## declaration order (Player field offsets 0x10..0x17C).
const ORIGINAL_FIELDS := {
	"configId": {"type": "int", "clone": "", "status": "missing", "note": "局内配置身份"},
	"configVersion": {"type": "long", "clone": "", "status": "missing", "note": "配置版本戳"},
	"name": {"type": "string", "clone": "", "status": "missing", "note": "玩家名（默认阿尔图）"},
	"difficulty": {"type": "int", "clone": "difficulty_index", "status": "semantic", "note": "已验证 1 基（样本 difficulty=1 + counter 7100006=3 + per_round=3 + global backToPrev=9999 四信号同指简单档）"},
	"round": {"type": "int", "clone": "round_number", "status": "semantic", "note": "原作 round 即日计数；克隆另有 day 字段（原作无）"},
	"min_round": {"type": "int", "clone": "min_round", "status": "mapped", "note": "player+0x30；2026-08-18 起克隆显式持久化并作回退门"},
	"saveTime": {"type": "DateTime", "clone": "", "status": "missing", "note": "存档时间戳"},
	"card_uid_index": {"type": "int", "clone": "next_card_uid", "status": "mapped", "note": ""},
	"rite_uid_index": {"type": "int", "clone": "next_rite_uid", "status": "mapped", "note": ""},
	"sudan_box_show": {"type": "bool", "clone": "", "status": "missing", "note": "苏丹卡盒首见 UI 标志"},
	"story_unshow": {"type": "bool", "clone": "", "status": "missing", "note": "剧情 UI 标志"},
	"prestige_unshow": {"type": "bool", "clone": "", "status": "missing", "note": "声望 UI 标志"},
	"deadline_unshow": {"type": "bool", "clone": "", "status": "missing", "note": "死线 UI 标志"},
	"helpbtn_unshow": {"type": "bool", "clone": "", "status": "missing", "note": "帮助按钮 UI 标志"},
	"location_icon_show": {"type": "int", "clone": "", "status": "missing", "note": "change_location_icon 持久化（DSL 键已支持）"},
	"change_desk_bg": {"type": "string", "clone": "", "status": "missing", "note": "change_desk_bg 持久化（DSL 键已支持）"},
	"after_round_auto_sort": {"type": "bool", "clone": "", "status": "missing", "note": "日终自动整理手牌开关"},
	"sudan_card_init_life": {"type": "int", "clone": "", "status": "missing", "note": "苏丹卡初始寿命；难度中途切换后按此值"},
	"sudan_redraw_count": {"type": "int", "clone": "sudan_redraw_count", "status": "mapped", "note": ""},
	"sudan_redraw_times_per_round": {"type": "int", "clone": "", "status": "missing", "note": "每回合苏丹重抽次数"},
	"sudan_redraw_times": {"type": "int", "clone": "redraws_left", "status": "semantic", "note": "原作记已用次数；克隆记剩余次数"},
	"sudan_redraw_times_recovery_round": {"type": "int", "clone": "", "status": "missing", "note": "重抽次数恢复回合"},
	"wizard_first_show": {"type": "bool", "clone": "begin_guide(部分)", "status": "semantic", "note": "原作仅存此布尔；克隆持久化全量引导队列"},
	"success": {"type": "bool", "clone": "", "status": "missing", "note": "通关标志"},
	"over_reason": {"type": "int", "clone": "", "status": "missing", "note": "结局原因（int.MinValue=未结局）"},
	"ithink_card": {"type": "Card?", "clone": "", "status": "missing", "note": "俺寻思卡实例；克隆思考状态未持久化为卡"},
	"cards": {"type": "List<Card>", "clone": "card_instances", "status": "semantic", "note": "原作平铺所有卡+bag/bagpos 手牌位，仪式槽位与装备内嵌嵌套；克隆扁平 zone/rite_uid/slot_key"},
	"rites": {"type": "List<Rite>", "clone": "rite_instances", "status": "semantic", "note": "原作 Rite.cards 为槽位下标数组（null=空槽）内嵌卡与装备"},
	"pins": {"type": "List<int>", "clone": "", "status": "missing", "note": "桌面图钉"},
	"sudan_pool_cards": {"type": "List<int>", "clone": "sudan_deck(部分)", "status": "semantic", "note": "苏丹池剩牌 id 列表"},
	"sudan_pool": {"type": "string", "clone": "", "status": "missing", "note": "池变体字符串"},
	"sudan_card_pool": {"type": "List<Card>", "clone": "sudan_deck(部分)", "status": "semantic", "note": "手边待选苏丹卡（带 uid/tag）"},
	"sudan_pool_pos": {"type": "Vector2", "clone": "", "status": "missing", "note": "苏丹池 UI 坐标"},
	"sudan_pool_init_count": {"type": "int", "clone": "", "status": "missing", "note": ""},
	"sudan_card_show_times": {"type": "Dictionary<int,int>", "clone": "", "status": "missing", "note": "苏丹卡展示计数"},
	"sudan_remove_count": {"type": "int", "clone": "", "status": "missing", "note": ""},
	"counter": {"type": "Dictionary<int,int>", "clone": "local_counters", "status": "mapped", "note": "资源类计数疑在此（骰子 counter id 待验证）"},
	"global_counter_cacher": {"type": "Dictionary<int,int>", "clone": "global_counters", "status": "semantic", "note": "原作是缓存器，全局真值在 global.json counter"},
	"random_cache": {"type": "Dictionary<string,int>", "clone": "", "status": "missing", "note": "RNG 续航缓存"},
	"only_cards": {"type": "HashSet<int>", "clone": "only_cards", "status": "mapped", "note": "已生成 is_only 卡的持久化登记；非当前持有表"},
	"only_rites": {"type": "HashSet<int>", "clone": "only_rites", "status": "mapped", "note": "成功初始化的仪式 id 持久化登记"},
	"event_status": {"type": "Dictionary<int,bool>", "clone": "event_status", "status": "mapped", "note": ""},
	"delay_ops": {"type": "List<DelayOp>", "clone": "delayed_operations", "status": "mapped", "note": "Player.DelayOp{id,round}"},
	"end_rites": {"type": "Dictionary<int,int>", "clone": "ended_rites", "status": "mapped", "note": ""},
	"gen_cards": {"type": "Dictionary<int,int>", "clone": "gen_cards", "status": "mapped", "note": "MarkCardGen：新建玩家卡 id 次数（166 键样本）"},
	"gen_tags": {"type": "Dictionary<string,int>", "clone": "gen_tags", "status": "mapped", "note": "MarkCardGen/MarkTagGen：稳定 tag code 次数"},
	"timing_rounds": {"type": "Dictionary<int,int>", "clone": "timing_rounds", "status": "mapped", "note": "player+0x128 周期事件重臂；键 = 事件 id×100（TimingRoundBase+0x20 int，2026-08-18 导入桥发现并修正克隆旧字符串键）"},
	"auto_result_rites": {"type": "HashSet<int>", "clone": "auto_result_rites", "status": "mapped", "note": ""},
	"notes": {"type": "List<List<Note>>", "clone": "", "status": "missing", "note": "笔记系统 Player.Note{type,id,uid,count}"},
	"once_new_rites_is_show": {"type": "Dictionary<int,bool>", "clone": "", "status": "missing", "note": "新仪式首见标志"},
	"cached_event": {"type": "List<int>", "clone": "", "status": "missing", "note": "事件缓存"},
	"BagIndex": {"type": "int", "clone": "", "status": "missing", "note": "背包索引（bag/bagpos 系统）"},
	"last_round_rite_data": {"type": "Dictionary<int,Dict>", "clone": "last_round_rite_data", "status": "mapped", "note": "按仪式配置 id + 手动槽 guid 保存 LastCardData{id,count}，用于仪式面板恢复上次投放（非回退快照）"},
	"rite_auto_result": {"type": "bool", "clone": "rite_auto_result", "status": "mapped", "note": ""},
	"disable_auto_gen_sudan_card": {"type": "bool", "clone": "auto_gen_sudan_card(取反)", "status": "mapped", "note": ""},
	"custom_rite_name": {"type": "Dictionary<int,string>", "clone": "custom_rite_names", "status": "mapped", "note": "玩家级仪式显示名覆盖（按配置 id）"},
	"player_card_name": {"type": "Dictionary<int,string>", "clone": "player_card_names", "status": "mapped", "note": "玩家级卡牌显示名覆盖（按配置 id，优先于 Card.custom_name）"},
	"end_open": {"type": "bool", "clone": "", "status": "missing", "note": "终局开启"},
	"is_armageddon": {"type": "bool", "clone": "", "status": "missing", "note": "末日决战态"},
	"armageddon_rite_id": {"type": "int", "clone": "", "status": "missing", "note": "末日仪式 id"},
}

## v5-only fields: present in the clone save, no original counterpart.
## Envelope fields (version/save_kind/player_save) are fine; the rest are
## structural drift to eliminate or justify (METHOD_MAP sections B/C).
const CLONE_ONLY_FIELDS := {
	"day": "原作无 day——round 即日计数",
	"coin_count": "已修复（2026-08-17）：原作金币 = 手牌金币卡 2000029 多对象 count 之和（GenCoin.c Do 0x510b40 每次 AddCard 新建对象 + set_count(操作值，可为负) + bagpos=1 + card_born，cards.json 2000029 双信号）；克隆 coin_count 现为该求和的计算属性，v6 存档不再持久化标量",
	"gold_dice": "已修复（2026-08-17）：原作金骰 = counter COUNTER_GOLD_DICE 7100006（dump.cs:542529 常量 + PlayerExtensions Add/SubCounter + 存档样本 difficulty1→3 与 init gold_dice_count 吻合）；克隆 gold_dice 现为该 counter 的计算属性",
	"hand": "原作手牌=cards 中 bag=0 按 bagpos 排序，无独立数组",
	"rail_order": "克隆专属排序",
	"world_location_id": "横版世界探针遗留（METHOD_MAP C）",
	"world_spawn_id": "横版世界探针遗留（METHOD_MAP C）",
	"world_position_ratio": "横版世界探针遗留（METHOD_MAP C）",
	"visited_world_locations": "横版世界探针遗留（METHOD_MAP C）",
	"back_to_prev_left": "已修复（2026-08-18）：原作回退配额 = counter COUNTER_BACK_TO_PREV 7100007 存全局域 Global.backToPrevRound（PlayerExtensions GetCounter 0x38ce70 / SetCounter 0x38f2d0 专用分支；9999=UNLIMIT_BACK_TO_PREV_TIMES）；克隆配额已迁 global_state，v7 局内存档不再持久化该键",
	"available_rites": "原作 rites 自带 start 标志，无平行列表",
	"started_rites": "原作 rites 自带 start 标志，无平行列表",
	"active_rite_uid": "表现层字段",
	"pending_operations": "原作 UI 队列不持久化（Promise 运行时）；仅 delay_ops+cached_event 持久化",
	"event_done": "原作 event_status 单字典承载",
	"begin_guide": "原作仅 wizard_first_show 布尔",
	"guide_cues": "原作仅 wizard_first_show 布尔持久化，引导队列为运行时态",
	"event_init_profile_id": "克隆专属",
	"player_actor_uid": "克隆专属（行动主体模型）",
	"version": "存档信封（合理）",
	"save_kind": "存档信封（合理）",
	"player_save": "存档信封（合理）",
}

const ENVELOPE_FIELDS := ["version", "save_kind", "player_save"]


static func status_counts() -> Dictionary:
	var counts := {STATUS_MAPPED: 0, STATUS_SEMANTIC: 0, STATUS_MISSING: 0}
	for field in ORIGINAL_FIELDS:
		counts[ORIGINAL_FIELDS[field]["status"]] += 1
	return counts


## Analyze a parsed original save: every field must be known to the schema
## (unknown = the corpus save drifted from the decoded schema) and have a
## plausible JSON type for the declared model type.
static func analyze_save(save: Dictionary) -> Dictionary:
	var unknown: Array = []
	var type_mismatches: Array = []
	for field in save:
		if not ORIGINAL_FIELDS.has(field):
			unknown.append(field)
			continue
		if not _json_type_matches(save[field], String(ORIGINAL_FIELDS[field]["type"])):
			type_mismatches.append({"field": field, "expected": ORIGINAL_FIELDS[field]["type"], "got": typeof(save[field])})
	return {
		"fields_present": save.size(),
		"unknown_fields": unknown,
		"type_mismatches": type_mismatches,
	}


static func _json_type_matches(value, model_type: String) -> bool:
	if value == null:
		return true
	match model_type:
		"int", "long":
			return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT
		"bool":
			return typeof(value) == TYPE_BOOL
		"string", "DateTime":
			return typeof(value) == TYPE_STRING
		"Vector2":
			return typeof(value) == TYPE_ARRAY
	return typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_DICTIONARY


## Field-by-field lookup of clone values for mapped/semantic fields.
## Only meaningful when both saves describe the same game moment (post import
## bridge); absent clone keys are reported so coverage gaps are visible.
static func compare_clone(original: Dictionary, clone: Dictionary) -> Array:
	var rows: Array = []
	for field in ORIGINAL_FIELDS:
		var meta: Dictionary = ORIGINAL_FIELDS[field]
		if meta["status"] == STATUS_MISSING or String(meta["clone"]).is_empty():
			continue
		var clone_key := _clone_key(String(meta["clone"]))
		var clone_value = clone.get(clone_key, "<absent>") if clone_key != "" else "<unmapped>"
		var original_value = _summarize(original.get(field, "<absent>"))
		var verdict := "present" if clone_key != "" and clone.has(clone_key) else "absent"
		if verdict == "present" and typeof(clone[clone_key]) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING] and typeof(original.get(field)) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING]:
			verdict = "equal" if _loose_equal(original[field], clone[clone_key]) else "differs"
		rows.append({
			"field": field,
			"status": meta["status"],
			"clone_key": clone_key,
			"original": original_value,
			"clone": _summarize(clone_value),
			"verdict": verdict,
		})
	return rows


static func _clone_key(mapped_name: String) -> String:
	if "(" in mapped_name:
		return ""
	return mapped_name


static func _loose_equal(a, b) -> bool:
	if typeof(a) == TYPE_STRING or typeof(b) == TYPE_STRING:
		return str(a) == str(b)
	return float(a) == float(b)


static func _summarize(value) -> String:
	match typeof(value):
		TYPE_ARRAY:
			return "array[%d]" % value.size()
		TYPE_DICTIONARY:
			return "dict{%d}" % value.size()
		TYPE_STRING:
			return "\"%s\"" % str(value).substr(0, 40)
		TYPE_NIL:
			return "null"
		_:
			return str(value)


static func to_markdown(analysis: Dictionary, compare_rows: Array = []) -> String:
	var counts := status_counts()
	var lines: Array = []
	lines.append("# 原作存档对拍报告（save diff harness）\n")
	lines.append("- 原作字段总数： %d（mapped %d / semantic %d / missing %d）" % [ORIGINAL_FIELDS.size(), counts[STATUS_MAPPED], counts[STATUS_SEMANTIC], counts[STATUS_MISSING]])
	lines.append("- 样本字段： %d，未知字段： %s，类型不符： %d" % [analysis.get("fields_present", 0), str(analysis.get("unknown_fields", [])), analysis.get("type_mismatches", []).size()])
	if not compare_rows.is_empty():
		lines.append("\n## 克隆对照（同刻存档才有意义）\n")
		lines.append("| 原作字段 | 状态 | 克隆键 | 原作值 | 克隆值 | 判定 |")
		lines.append("| --- | --- | --- | --- | --- | --- |")
		for row in compare_rows:
			lines.append("| %s | %s | %s | %s | %s | %s |" % [row["field"], row["status"], row["clone_key"], row["original"], row["clone"], row["verdict"]])
	lines.append("")
	return "\n".join(lines)
