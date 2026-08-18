class_name OriginalSaveImporter
extends RefCounted

## Phase-2 import bridge (methodology pillar 2: original artifacts as judge).
## Converts an original Player save (the corpus save_samples JSON, decoded by
## sim/original_save_schema.gd) into a clone v7 payload, loads it through the
## normal SaveSystem.deserialize path, and diffs the same-instant values back
## against the original. What the clone cannot represent is reported as
## dropped/approximated — never silently swallowed.
##
## Key conversions (dual-signal, see docs/ORIGINAL_SAVE_SCHEMA.md):
##   difficulty is 1-based in the original (sample difficulty=1 with counter
##   7100006=3, sudan_redraw_times_per_round=3 and global backToPrevRound=9999
##   all point at 梅姬/easy = clone index 0).
##   Original rite cards[i] is 0-based and maps to slot s{i+1}; the array
##   length matches the config's cards_slot count (5001001 = s1..s7).
##   Hand = top-level cards with bag=0; bagpos>=1 cards are hand-visible
##   (ordered by bagpos), bagpos=0 cards are bag storage the clone flattens
##   into the same hand zone (bag/bagpos system stays METHOD_MAP D).
##   Equipment travels as nested `equips` on the host card; the original does
##   not persist which equip slot each object occupies, so the slot is
##   inferred from the equipment definition's slot tag when unique.
## [SRC: save_samples/auto_save.json + dump.cs:391488 Player (JsonSerializable);
##       PlayerExtensions.c SetDifficulty 0x38f530 for the difficulty radix;
##       Rite.cards slot array dump.cs:392391 / rite configs cards_slot counts]

const SUDAN_ID_MIN := 2010001
const SUDAN_ID_MAX := 2010016
const GOLD_CARD_ID := 2000029
const EQUIP_SLOT_TAGS := ["weapon", "cloth", "accessory", "animal_handling"]

# Original fields the clone cannot represent today; each entry lists whether
# this save actually carries a non-default value (reported per import).
const DROPPED_FIELDS := {
	"configId": "局内配置身份",
	"configVersion": "配置版本戳",
	"name": "玩家名",
	"saveTime": "存档时间戳",
	"sudan_box_show": "UI 首见标志族",
	"story_unshow": "UI 首见标志族",
	"prestige_unshow": "UI 首见标志族",
	"deadline_unshow": "UI 首见标志族",
	"helpbtn_unshow": "UI 首见标志族",
	"location_icon_show": "change_location_icon 持久化",
	"change_desk_bg": "change_desk_bg 持久化",
	"after_round_auto_sort": "日终自动整理开关",
	"sudan_card_init_life": "难度中途切换后的苏丹初始寿命",
	"sudan_redraw_times_per_round": "克隆按难度配置重derive",
	"sudan_redraw_times_recovery_round": "重抽恢复模型未迁移（7100008 族）",
	"success": "通关标志",
	"over_reason": "结局原因持久化",
	"ithink_card": "思考卡实例",
	"pins": "桌面图钉",
	"sudan_pool": "池变体字符串",
	"sudan_pool_pos": "苏丹池 UI 坐标",
	"sudan_pool_init_count": "苏丹池初始计数",
	"sudan_card_show_times": "苏丹卡展示计数",
	"sudan_remove_count": "苏丹移除计数",
	"random_cache": "RNG 续航缓存",
	"only_cards": "唯一卡登记",
	"only_rites": "唯一仪式登记",
	"gen_cards": "卡生成计数",
	"gen_tags": "标签生成计数",
	"notes": "笔记系统",
	"once_new_rites_is_show": "新仪式首见标志",
	"cached_event": "事件缓存",
	"BagIndex": "背包索引",
	"last_round_rite_data": "按仪式的上回合卡数据（回退快照持久化）",
	"custom_rite_name": "仪式改名（按 id 映射到 RiteInstance.custom_name）",
	"player_card_name": "卡牌改名（按 id 映射到 CardInstance.custom_name）",
	"end_open": "终局开启",
	"is_armageddon": "末日决战态",
	"armageddon_rite_id": "末日仪式 id",
	"delay_ops": "原作 DelayOp 到期语义未逆向（样本为空则零损失）",
	"sudan_card_pool": "带 uid 的池对象：克隆牌堆为 id 多重集（见 approximated）",
	"wizard_first_show": "引导首见布尔（克隆 begin_guide 为指令字典）",
}


## Build a v7-shaped clone payload from an original Player save dict.
static func to_clone_payload(original: Dictionary, db) -> Dictionary:
	var approximated: Array = []
	var converted: Array = []

	# ---- Scalars ----
	var difficulty_index := int(original.get("difficulty", 1)) - 1
	var round_number := int(original.get("round", 1))
	var min_round := maxi(1, int(original.get("min_round", 1)))
	for scalar_field in ["difficulty(-1 基)", "round", "min_round", "card_uid_index",
			"rite_uid_index", "sudan_redraw_count"]:
		converted.append(scalar_field)

	# Original records used redraws; the clone keeps the remainder.
	var per_round := int(original.get("sudan_redraw_times_per_round",
		_original_difficulty_value(db, difficulty_index, "sudan_redraw_times_per_round", 1)))
	var redraws_left := maxi(0, per_round - int(original.get("sudan_redraw_times", 0)))
	converted.append("sudan_redraw_times(已用 -> 剩余)")

	# ---- Cards: top-level (hand/bag), nested equips, rite slots ----
	var card_rows: Array = []
	var hand_uids: Array[int] = []
	var sudan_uids: Array[int] = []
	var player_actor_uid := 0
	for card in original.get("cards", []):
		if not (card is Dictionary):
			continue
		var uid := int(card.get("uid", 0))
		var card_id := int(card.get("id", 0))
		var is_sudan := card_id >= SUDAN_ID_MIN and card_id <= SUDAN_ID_MAX
		# Drawn sudan cards live in the sudan zone like the clone's own
		# draw_weekly_sudan (they sit on the rail, not the hand array).
		_card_row(card, "sudan" if is_sudan else "hand", 0, "", card_rows, db)
		if is_sudan:
			sudan_uids.append(uid)
			continue
		hand_uids.append(uid)
		if player_actor_uid == 0 and _is_protagonist(card_id, db):
			player_actor_uid = uid
	# Hand order: hand-visible bagpos>=1 first (by bagpos), then bag storage
	# (bagpos=0) by uid. The clone has no bag pages, so storage flattens in.
	var by_uid := {}
	for row in card_rows:
		by_uid[int(row["uid"])] = row
	var visible: Array = []
	var stored: Array = []
	for card in original.get("cards", []):
		if not (card is Dictionary):
			continue
		var card_id := int(card.get("id", 0))
		if card_id >= SUDAN_ID_MIN and card_id <= SUDAN_ID_MAX:
			continue
		if int(card.get("bag", 0)) != 0:
			approximated.append("bag>0 卡片进入手牌区（背包分页未迁移）")
		var entry := {"uid": int(card.get("uid", 0)), "bagpos": int(card.get("bagpos", 0))}
		if entry["bagpos"] >= 1:
			visible.append(entry)
		else:
			stored.append(entry)
	visible.sort_custom(func(a, b): return _visible_before(a, b))
	stored.sort_custom(func(a, b): return int(a["uid"]) < int(b["uid"]))
	var ordered_hand: Array[int] = []
	for entry in visible:
		ordered_hand.append(int(entry["uid"]))
	for entry in stored:
		ordered_hand.append(int(entry["uid"]))

	# ---- Rites ----
	# The clone's legacy compat arrays (available_rites/started_rites) hold
	# config ids, one entry per instance — rite_instances stays authoritative.
	var rite_rows: Array = []
	var available_rites: Array[int] = []
	var started_rites: Array[int] = []
	for rite in original.get("rites", []):
		if not (rite is Dictionary):
			continue
		var rite_uid := int(rite.get("uid", 0))
		var rite_id := int(rite.get("id", 0))
		available_rites.append(rite_id)
		if bool(rite.get("start", false)):
			started_rites.append(rite_id)
		var slot_cards := {}
		var cards: Array = rite.get("cards", [])
		for index in cards.size():
			var slotted = cards[index]
			if slotted is Dictionary:
				var slot_key := "s%d" % (index + 1)
				slot_cards[slot_key] = int(slotted.get("uid", 0))
				_card_row(slotted, "slot", rite_uid, slot_key, card_rows, db)
		rite_rows.append({
			"uid": rite_uid,
			"id": int(rite.get("id", 0)),
			"new_born": bool(rite.get("new_born", true)),
			"is_show": bool(rite.get("is_show", false)),
			"start": bool(rite.get("start", false)),
			"start_round": int(rite.get("start_round", 0)),
			"start_life": int(rite.get("start_life", 0)),
			"life": int(rite.get("life", 0)),
			"slot_cards": slot_cards,
			"is_cleaned": false,
			"custom_name": _custom_rite_name(original, int(rite.get("id", 0))),
		})
	converted.append("rites(槽位下标数组 -> 扁平 zone/rite_uid/slot_key)")

	# ---- Sudan ----
	var sudan_deck: Array[int] = []
	for cid in original.get("sudan_pool_cards", []):
		sudan_deck.append(int(cid))
	var active_sudan: Array = []
	for uid in sudan_uids:
		var row = by_uid.get(uid)
		if row == null:
			continue
		# The deadline is the card-life model: remaining = template
		# card_vanishing − the persisted card.life (exact — GenSudanCard births
		# the card with the difficulty head start and the generic aging counts
		# up to the template).
		var lifetime := int(db.get_card(int(row["card_id"])).get("card_vanishing", 7)) if db != null else 7
		active_sudan.append({
			"card_id": int(row["card_id"]),
			"card_uid": uid,
			"days_left": lifetime - int(row["life"]),
			"drawn_round": round_number,
		})
	approximated.append("active_sudan drawn_round：期限可由 card_vanishing−life 精确恢复，但出生回合在难度中途切换后无法反推")
	approximated.append("sudan_deck 顺序：sudan_shuffle 开启时每次抽取先 Shuffle 再 RemoveLast，顺序无意义，仅多重集对拍")

	# ---- Rail: sudan at the front like draw_weekly_sudan, then hand ----
	var rail_order: Array[int] = []
	rail_order.append_array(sudan_uids)
	rail_order.append_array(ordered_hand)

	# ---- Custom card names ----
	var card_name_by_id: Dictionary = original.get("player_card_name", {})
	if card_name_by_id is Dictionary and not card_name_by_id.is_empty():
		for row in card_rows:
			var cid_key := str(row["card_id"])
			if card_name_by_id.has(cid_key):
				row["custom_name"] = str(card_name_by_id[cid_key])
		converted.append("player_card_name")

	# ---- Dropped-with-value scan ----
	var dropped := _scan_dropped(original)

	return {
		"version": SaveSystem.SAVE_VERSION,
		"save_kind": SaveSystem.SAVE_KIND_PLAYER,
		"player_save": true,
		"difficulty_index": difficulty_index,
		"round_number": round_number,
		"day": round_number,
		"min_round": min_round,
		"redraws_left": redraws_left,
		"sudan_redraw_count": int(original.get("sudan_redraw_count", 1)),
		"hand": ordered_hand,
		"rail_order": rail_order,
		"sudan_deck": sudan_deck,
		"sudan_pool_tags": {},
		"auto_gen_sudan_card": not bool(original.get("disable_auto_gen_sudan_card", false)),
		"active_sudan_cards": active_sudan,
		"card_instances": card_rows,
		"next_card_uid": int(original.get("card_uid_index", 1)),
		"player_actor_uid": player_actor_uid,
		"rite_instances": rite_rows,
		"next_rite_uid": int(original.get("rite_uid_index", 1)),
		"active_rite_uid": 0,
		"available_rites": available_rites,
		"started_rites": started_rites,
		"auto_result_rites": _int_list(original.get("auto_result_rites", [])),
		"rite_auto_result": bool(original.get("rite_auto_result", false)),
		"ended_rites": _int_keyed(original.get("end_rites", {})),
		"pending_operations": [],
		"delayed_operations": [],
		"event_status": _int_keyed(original.get("event_status", {})),
		"event_done": {},
		"timing_rounds": _int_keyed(original.get("timing_rounds", {})),
		"begin_guide": {},
		"guide_cues": [],
		"event_init_profile_id": int(original.get("configId", 1)),
		"local_counters": _int_keyed(original.get("counter", {})),
		"global_counters": _int_keyed(original.get("global_counter_cacher", {})),
		"_bridge_meta": {"converted": converted, "dropped": dropped, "approximated": approximated},
	}


## Import an original save into a live GameState through the normal
## deserialize path. Returns {state, payload, report} — or {error} on failure.
static func import_save(original: Dictionary, db) -> Dictionary:
	var payload := to_clone_payload(original, db)
	var state = preload("res://sim/game_state.gd").new()
	SaveSystem.deserialize(payload, state, db)
	var report := {
		"converted": payload["_bridge_meta"]["converted"],
		"dropped": payload["_bridge_meta"]["dropped"],
		"approximated": payload["_bridge_meta"]["approximated"],
		"diff": diff_against_original(original, state),
	}
	payload.erase("_bridge_meta")
	return {"state": state, "payload": payload, "report": report}


## Same-instant value comparison: original save vs imported clone state.
## Every row is {check, original, clone, pass}.
static func diff_against_original(original: Dictionary, state) -> Array:
	var rows: Array = []
	var original_cards := _collect_original_cards(original)
	rows.append(_row("round", int(original.get("round", 1)), int(state.round_number)))
	rows.append(_row("difficulty_index", int(original.get("difficulty", 1)) - 1, int(state.difficulty_index)))
	rows.append(_row("min_round", maxi(1, int(original.get("min_round", 1))), int(state.min_round)))
	rows.append(_row("next_card_uid", int(original.get("card_uid_index", 1)), int(state.next_card_uid)))
	rows.append(_row("next_rite_uid", int(original.get("rite_uid_index", 1)), int(state.next_rite_uid)))
	rows.append(_row("sudan_redraw_count", int(original.get("sudan_redraw_count", 1)), int(state.sudan_redraw_count)))
	var per_round := int(original.get("sudan_redraw_times_per_round", 1))
	rows.append(_row("redraws_left", maxi(0, per_round - int(original.get("sudan_redraw_times", 0))), int(state.redraws_left)))
	rows.append(_row("card_object_count", original_cards.size(), state.card_instances.size()))
	rows.append(_row("per_id_counts", _per_id_counts(original_cards), _clone_per_id_counts(state)))
	rows.append(_row("gold_total_7000105", _original_gold_total(original), state.gold_total()))
	rows.append(_row("counter", _norm_int_dict(original.get("counter", {})), _norm_int_dict(state.local_counters)))
	rows.append(_row("event_status", _int_keyed(original.get("event_status", {})), _norm_bool_dict(state.event_status)))
	rows.append(_row("timing_rounds", _norm_int_dict(original.get("timing_rounds", {})), _norm_int_dict(state.timing_rounds)))
	rows.append(_row("end_rites", _int_keyed(original.get("end_rites", {})), _norm_int_dict(state.ended_rites)))
	rows.append(_row("auto_result_rites", _int_list(original.get("auto_result_rites", [])), _sorted_int_list(state.auto_result_rites)))
	rows.append(_row("rite_auto_result", bool(original.get("rite_auto_result", false)), bool(state.rite_auto_result)))
	rows.append(_row("auto_gen_sudan_card", not bool(original.get("disable_auto_gen_sudan_card", false)), bool(state.auto_gen_sudan_card)))
	rows.append(_row("hand_membership", _original_hand_uids(original), _sorted_int_list(state.hand)))
	rows.append(_row("active_sudan_ids", _original_active_sudan_ids(original), _sorted_int_list(state.active_sudan_cards.map(func(asc): return asc.card_id))))
	rows.append(_row("sudan_deck_multiset", _sorted_int_list(original.get("sudan_pool_cards", [])), _sorted_int_list(state.sudan_deck)))
	rows.append(_row("player_actor_uid", _original_protagonist_uid(original_cards), int(state.player_actor_uid)))
	rows.append(_row("rites", _original_rites_summary(original), _clone_rites_summary(state)))
	rows.append(_row("equipment_links", _original_equipment_links(original_cards), _clone_equipment_links(state)))
	return rows


static func summary_markdown(report: Dictionary, original_path: String) -> String:
	var lines: Array = []
	lines.append("# 原作存档导入桥报告（阶段二）\n")
	lines.append("- 原作存档：`%s`\n" % original_path)
	var passed := 0
	var failed := 0
	for row in report["diff"]:
		if bool(row["pass"]):
			passed += 1
		else:
			failed += 1
	lines.append("- 同刻对拍：%d 通过 / %d 失败（共 %d 项）\n" % [passed, failed, report["diff"].size()])
	lines.append("\n## 对拍明细\n")
	lines.append("| 检查 | 原作 | 克隆 | 结果 |")
	lines.append("| --- | --- | --- | --- |")
	for row in report["diff"]:
		lines.append("| %s | %s | %s | %s |" % [
			row["check"], _short(row["original"]), _short(row["clone"]),
			"✅" if bool(row["pass"]) else "❌",
		])
	lines.append("\n## 转换（%d 项）\n" % report["converted"].size())
	for field in report["converted"]:
		lines.append("- %s" % str(field))
	lines.append("\n## 近似（%d 项，防静默）\n" % report["approximated"].size())
	for field in report["approximated"]:
		lines.append("- %s" % str(field))
	lines.append("\n## 丢弃（本存档携带非默认值）\n")
	var any_dropped := false
	for entry in report["dropped"]:
		if bool(entry["has_value"]):
			any_dropped = true
			lines.append("- **%s**：%s（值：`%s`）" % [entry["field"], entry["note"], _short(entry["value"])])
	if not any_dropped:
		lines.append("- （无——所有克隆无法承载的字段在本存档中均为默认值）")
	return "\n".join(lines)


# ---- Internal helpers ----

static func _card_row(card: Dictionary, zone: String, rite_uid: int, slot_key: String, out_rows: Array, db) -> void:
	var uid := int(card.get("uid", 0))
	var card_id := int(card.get("id", 0))
	var tags: Dictionary = card.get("tag", {}) if card.get("tag", {}) is Dictionary else {}
	var equip_uids: Array[int] = []
	for equip in card.get("equips", []):
		if not (equip is Dictionary):
			continue
		var equip_uid := int(equip.get("uid", 0))
		equip_uids.append(equip_uid)
		var equip_row_zone := "equipped"
		var row := _base_card_row(equip, equip_row_zone, 0, "")
		row["equipped_to_uid"] = uid
		row["equipped_slot"] = _infer_equip_slot(int(equip.get("id", 0)), db)
		out_rows.append(row)
	var row := _base_card_row(card, zone, rite_uid, slot_key)
	row["equipped_uids"] = equip_uids
	out_rows.append(row)


static func _base_card_row(card: Dictionary, zone: String, rite_uid: int, slot_key: String) -> Dictionary:
	var equip_slots: Array[String] = []
	for slot in card.get("equip_slots", []):
		equip_slots.append(str(slot))
	return {
		"uid": int(card.get("uid", 0)),
		"card_id": int(card.get("id", 0)),
		"tags": (card.get("tag", {}) if card.get("tag", {}) is Dictionary else {}).duplicate(true),
		"count": maxi(int(card.get("count", 1)), 1),
		"life": int(card.get("life", 0)),
		"is_lost": false,
		"zone": zone,
		"rite_uid": rite_uid,
		"slot_key": slot_key,
		"rare_up": int(card.get("rareup", 0)),
		"custom_name": str(card.get("custom_name", "")),
		"custom_text": str(card.get("custom_text", "")),
		"equip_slots": equip_slots,
		"removed_equip_slots": [],
		"equipped_uids": [],
		"equipped_to_uid": 0,
		"equipped_slot": "",
	}


## The original does not persist which equip slot an object occupies; infer it
## from the definition's slot tag when exactly one matches.
static func _infer_equip_slot(card_id: int, db) -> String:
	if db == null:
		return ""
	var definition: Dictionary = db.get_card(card_id)
	if definition.is_empty():
		return ""
	var tags: Dictionary = definition.get("tag", {})
	var matches: Array = []
	for slot in EQUIP_SLOT_TAGS:
		if int(tags.get(slot, 0)) > 0:
			matches.append(slot)
	return matches[0] if matches.size() == 1 else ""


static func _visible_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a["bagpos"]) != int(b["bagpos"]):
		return int(a["bagpos"]) < int(b["bagpos"])
	return int(a["uid"]) < int(b["uid"])


static func _is_protagonist(card_id: int, db) -> bool:
	if db == null:
		return card_id == 2000001
	return int(db.get_card(card_id).get("tag", {}).get("主角", 0)) > 0


static func _original_difficulty_value(db, difficulty_index: int, key: String, fallback: int) -> int:
	if db == null:
		return fallback
	var config: Dictionary = db.get_difficulty(difficulty_index)
	return int(config.get(key, fallback))


static func _custom_rite_name(original: Dictionary, rite_id: int) -> String:
	var names: Dictionary = original.get("custom_rite_name", {})
	return str(names.get(str(rite_id), ""))


static func _scan_dropped(original: Dictionary) -> Array:
	var dropped: Array = []
	for field in DROPPED_FIELDS:
		var value = original.get(field, null)
		var has_value := _has_non_default(value)
		dropped.append({
			"field": field,
			"note": DROPPED_FIELDS[field],
			"has_value": has_value,
			"value": value if has_value else null,
		})
	return dropped


static func _has_non_default(value) -> bool:
	if value == null:
		return false
	if value is bool:
		return bool(value)
	if value is int or value is float:
		return int(value) != 0 and int(value) != -2147483648
	if value is String:
		return str(value) != ""
	if value is Array:
		return not (value as Array).is_empty()
	if value is Dictionary:
		return not (value as Dictionary).is_empty()
	return true


static func _collect_original_cards(original: Dictionary) -> Array:
	var cards: Array = []
	for card in original.get("cards", []):
		if card is Dictionary:
			cards.append(card)
			for equip in card.get("equips", []):
				if equip is Dictionary:
					cards.append(equip)
	for rite in original.get("rites", []):
		if rite is Dictionary:
			for slotted in rite.get("cards", []):
				if slotted is Dictionary:
					cards.append(slotted)
					for equip in slotted.get("equips", []):
						if equip is Dictionary:
							cards.append(equip)
	return cards


static func _per_id_counts(cards: Array) -> Dictionary:
	var counts := {}
	for card in cards:
		var card_id := int(card.get("id", 0))
		counts[card_id] = int(counts.get(card_id, 0)) + int(card.get("count", 1))
	return counts


static func _clone_per_id_counts(state) -> Dictionary:
	var counts := {}
	for instance in state.card_instances.values():
		counts[instance.card_id] = int(counts.get(instance.card_id, 0)) + int(instance.count)
	return counts


static func _original_gold_total(original: Dictionary) -> int:
	# GetCounter 7000105 derived read: gold cards across player cards + rite slots.
	var total := 0
	for card in _collect_original_cards(original):
		if int(card.get("id", 0)) == GOLD_CARD_ID:
			total += int(card.get("count", 1))
	return total


static func _original_hand_uids(original: Dictionary) -> Array:
	var uids: Array = []
	for card in original.get("cards", []):
		if card is Dictionary and int(card.get("bag", 0)) == 0:
			var card_id := int(card.get("id", 0))
			if card_id < SUDAN_ID_MIN or card_id > SUDAN_ID_MAX:
				uids.append(int(card.get("uid", 0)))
	uids.sort()
	return uids


static func _original_active_sudan_ids(original: Dictionary) -> Array:
	var ids: Array = []
	for card in original.get("cards", []):
		if card is Dictionary:
			var card_id := int(card.get("id", 0))
			if card_id >= SUDAN_ID_MIN and card_id <= SUDAN_ID_MAX:
				ids.append(card_id)
	ids.sort()
	return ids


static func _original_protagonist_uid(cards: Array) -> int:
	for card in cards:
		if int(card.get("id", 0)) == 2000001:
			return int(card.get("uid", 0))
	return 0


static func _original_rites_summary(original: Dictionary) -> Array:
	var summary: Array = []
	for rite in original.get("rites", []):
		if not (rite is Dictionary):
			continue
		var slots := {}
		var cards: Array = rite.get("cards", [])
		for index in cards.size():
			if cards[index] is Dictionary:
				slots["s%d" % (index + 1)] = int(cards[index].get("uid", 0))
		summary.append({
			"uid": int(rite.get("uid", 0)),
			"id": int(rite.get("id", 0)),
			"start": bool(rite.get("start", false)),
			"start_round": int(rite.get("start_round", 0)),
			"start_life": int(rite.get("start_life", 0)),
			"life": int(rite.get("life", 0)),
			"slots": slots,
		})
	return summary


static func _clone_rites_summary(state) -> Array:
	var summary: Array = []
	for instance in state.rite_instances.values():
		var slots := {}
		for slot_key in instance.slot_cards:
			slots[str(slot_key)] = int(instance.slot_cards[slot_key])
		summary.append({
			"uid": int(instance.uid),
			"id": int(instance.id),
			"start": bool(instance.start),
			"start_round": int(instance.start_round),
			"start_life": int(instance.start_life),
			"life": int(instance.life),
			"slots": slots,
		})
	return summary


static func _original_equipment_links(cards: Array) -> Array:
	var links: Array = []
	for card in cards:
		for equip in card.get("equips", []):
			if equip is Dictionary:
				links.append([int(card.get("uid", 0)), int(equip.get("uid", 0))])
	links.sort()
	return links


static func _clone_equipment_links(state) -> Array:
	var links: Array = []
	for instance in state.card_instances.values():
		for uid in instance.equipped_uids:
			links.append([int(instance.uid), int(uid)])
	links.sort()
	return links


static func _row(check: String, original_value, clone_value) -> Dictionary:
	var passed := false
	if original_value is Dictionary and clone_value is Dictionary:
		passed = _dict_equals(original_value, clone_value)
	elif original_value is Array and clone_value is Array:
		passed = _list_equals(original_value, clone_value)
	else:
		passed = original_value == clone_value
	return {"check": check, "original": original_value, "clone": clone_value, "pass": passed}


static func _dict_equals(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key in a:
		if not b.has(key):
			return false
		if not _value_equals(a[key], b[key]):
			return false
	return true


static func _list_equals(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for index in a.size():
		if not _value_equals(a[index], b[index]):
			return false
	return true


## Order-insensitive for dictionaries, numeric for numbers (the original JSON
## parses every number as float while the clone stores ints).
static func _value_equals(av, bv) -> bool:
	if av is Dictionary and bv is Dictionary:
		return _dict_equals(av, bv)
	if av is Array and bv is Array:
		return _list_equals(av, bv)
	if (av is int or av is float) and (bv is int or bv is float):
		return float(av) == float(bv)
	return str(av) == str(bv)


static func _int_keyed(value) -> Dictionary:
	var restored := {}
	if not (value is Dictionary):
		return restored
	for key in value:
		restored[int(key)] = value[key]
	return restored


static func _int_list(value) -> Array:
	var listed: Array = []
	if not (value is Array):
		return listed
	for entry in value:
		listed.append(int(entry))
	return listed


static func _sorted_int_list(value) -> Array:
	var listed: Array = _int_list(value)
	listed.sort()
	return listed


static func _norm_bool_dict(value: Dictionary) -> Dictionary:
	var normalized := {}
	for key in value:
		normalized[int(key)] = bool(value[key])
	return normalized


static func _norm_int_dict(value: Dictionary) -> Dictionary:
	var normalized := {}
	for key in value:
		normalized[int(key)] = int(value[key])
	return normalized


static func _short(value) -> String:
	var text := str(value)
	if text.length() > 80:
		return "%s…（%d 项）" % [text.substr(0, 72), _count_items(value)]
	return text


static func _count_items(value) -> int:
	if value is Dictionary:
		return (value as Dictionary).size()
	if value is Array:
		return (value as Array).size()
	return 1
