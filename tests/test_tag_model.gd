extends GutTest

## Card tag model: the definition row (CardNode.tag@0x58, Chinese names in
## config) plus the runtime delta (Card.tag@0x30, stable codes in saves), with
## the inheritable-equip recursion, the non-positive mask and the final
## × Card.count.
## [SRC: decompiled/CardExtensions.c @ GetTag (RVA 0x3814a0), GetTags
##       (0x381940), AddTag (0x37e6a0), RemoveTag (0x382e40);
##       dump.cs Card.tag@0x30 / CardNode.tag@0x58 / TagNode@0x42,@0x43;
##       save_samples/auto_save.json uid 29 = {"social":1,"charm":1}.]

const CORPUS_AUTO_SAVE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"
const CardInstanceData = preload("res://sim/card_instance.gd")


func _local_db() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	return local_db


func _state_with(card_id: int, delta: Dictionary = {}, count := 1) -> Array:
	var local_db := _local_db()
	var st := GameState.new()
	var instance = CardInstanceData.new(1, card_id, delta)
	instance.count = count
	st.card_instances[1] = instance
	st.next_card_uid = 2
	return [st, local_db]


# ---- Config key domain -----------------------------------------------------

func test_config_and_save_use_two_key_domains() -> void:
	var local_db := _local_db()
	assert_eq(int(local_db.get_card(2000001).get("tag", {}).get("体魄", 0)), 3,
		"cards.json carries the localized tag name as the CardNode.tag key")
	assert_eq(str(local_db.tag_name_to_code.get("体魄", "")), "physique")
	assert_eq(str(local_db.tag_code_to_name.get("social", "")), "社交",
		"the inverse map resolves a save's stable code back to the config name")


# ---- GetTag: base + delta + equip, × count ---------------------------------

func test_definition_row_participates_without_any_delta() -> void:
	var pair := _state_with(2000001)
	var tags: Dictionary = pair[0].effective_card_tags(1, pair[1])
	assert_eq(int(tags.get("体魄", 0)), 3, "no delta -> the definition row is the result")
	assert_eq(int(tags.get("社交", 0)), 1)
	assert_eq(int(tags.get("已拥有", 0)), 1)


func test_runtime_code_delta_adds_onto_the_definition_row() -> void:
	# Matches corpus auto_save.json uid 29 exactly.
	var pair := _state_with(2000001, {"social": 1, "charm": 1})
	var tags: Dictionary = pair[0].effective_card_tags(1, pair[1])
	assert_eq(int(tags.get("社交", 0)), 2, "source social = 1 base + 1 delta")
	assert_eq(int(tags.get("魅力", 0)), 3, "source charm = 2 base + 1 delta")
	assert_eq(int(tags.get("体魄", 0)), 3, "an untouched tag still reports its definition value")
	assert_false(tags.has("social"), "the code key must not leak into the config domain")


func test_count_multiplies_the_finished_sum() -> void:
	var pair := _state_with(2000001, {"social": 1}, 3)
	var tags: Dictionary = pair[0].effective_card_tags(1, pair[1])
	assert_eq(int(tags.get("社交", 0)), 6, "(1 base + 1 delta) x count 3")
	assert_eq(int(tags.get("体魄", 0)), 9, "base 3 x count 3")


func test_non_positive_sum_is_masked_unless_the_tag_allows_it() -> void:
	var masked := _state_with(2000001, {"support": -1})
	# 支持 can_nagative_and_zero=0 -> a masked zero, not the stored -1... base 1
	# plus delta -1 is 0, which fails the "<1" test and reports 0.
	assert_eq(int(masked[0].effective_card_tags(1, masked[1]).get("支持", 0)), 0,
		"支持 does not allow negative/zero reporting")
	var unmasked := _state_with(2000001, {"physique": -5})
	assert_eq(int(unmasked[0].effective_card_tags(1, unmasked[1]).get("体魄", 0)), -2,
		"体魄 has can_nagative_and_zero=1, so the negative sum survives")


func test_equipment_term_filters_each_requested_tag() -> void:
	var local_db := _local_db()
	var st := GameState.new()
	var host = CardInstanceData.new(1, 2000001, {})
	# 2000006 (梅姬) has inheritable tags (体魄/魅力/智慧/贵族/支持) and
	# non-inheritable ones (女性 / 妻子 / lock_friendship).
	var mixed = CardInstanceData.new(2, 2000006, {})
	mixed.zone = "equipped"
	st.card_instances[1] = host
	st.card_instances[2] = mixed
	host.equipped_uids.append(2)
	var mixed_row: Dictionary = st.effective_card_tags(1, local_db)
	assert_eq(int(mixed_row.get("体魄", 0)), 5, "host 3 + 梅姬 2")
	assert_eq(int(mixed_row.get("女性", 0)), 0,
		"GetTag gates each requested tag; physique does not grant inheritance of female")
	assert_false(st.effective_card_tag_names(1, local_db).has("女性"), "GetTags uses the same per-tag filter")
	# 2000380 (星光之源) carries exactly one tag (消耗品) and it is
	# can_inherit=0, so the gate blocks the whole term.
	var blocked = CardInstanceData.new(3, 2000380, {})
	blocked.zone = "equipped"
	st.card_instances[3] = blocked
	host.equipped_uids.append(3)
	var blocked_row: Dictionary = st.effective_card_tags(1, local_db)
	assert_eq(int(blocked_row.get("消耗品", 0)), 0,
		"no tag in 星光之源 is can_inherit=1, so none of its row may leak")
	assert_eq(int(blocked_row.get("体魄", 0)), 5, "the inheritable equip still applies")
	# Only Card.equips@0x40 feeds the recursion; a non-equipment zone does not.
	st.card_instances[2].zone = "slot"
	st.card_instances[3].zone = "slot"
	var detached: Dictionary = st.effective_card_tags(1, local_db)
	assert_eq(int(detached.get("体魄", 0)), 3)
	assert_eq(int(detached.get("智慧", 0)), 1)


func test_equipment_term_multiplies_equip_count_before_host_count() -> void:
	var local_db := _local_db()
	var st := GameState.new()
	var host = CardInstanceData.new(1, 2000001, {})
	host.count = 2
	var equips = CardInstanceData.new(2, 2000006, {})
	equips.zone = "equipped"
	equips.count = 5
	st.card_instances[1] = host
	st.card_instances[2] = equips
	host.equipped_uids.append(2)
	var tags: Dictionary = st.effective_card_tags(1, local_db)
	# GetTag(equip, raw=true) still returns value * equip.count.
	assert_eq(int(tags.get("体魄", 0)), 26, "(host 3 + equip 2 * 5) * host count 2")


func test_tag_name_union_covers_definition_and_delta() -> void:
	var pair := _state_with(2000001, {"social": 1})
	var names: Array = pair[0].effective_card_tag_names(1, pair[1])
	assert_true(names.has("体魄"), "GetTags includes definition keys")
	assert_true(names.has("社交"), "GetTags includes delta keys")


# ---- TagSystem gate --------------------------------------------------------

func test_add_gate_reads_the_effective_row_not_the_delta() -> void:
	var delta := {}
	# 已拥有 is can_add=0. Definition already carries it, so a stackable ADD is
	# a no-op even though the delta is empty.
	assert_false(TagSystem.apply(delta, "已拥有", TagSystem.Op.ADD, 1, false, 1),
		"a blocked add reports no change")
	assert_false(delta.has("已拥有"), "the definition value alone blocks the add")
	assert_true(TagSystem.apply(delta, "已拥有", TagSystem.Op.ADD, 1, false, 0),
		"absent from the whole row -> the add lands and reports a change")
	assert_eq(int(delta.get("已拥有", 0)), 1)


func test_apply_reports_change_for_every_op_form() -> void:
	var delta := {}
	assert_true(TagSystem.apply(delta, "隐匿", TagSystem.Op.ADD, 2), "ADD changes the stored value")
	assert_eq(int(delta.get("隐匿", 0)), 2)
	assert_true(TagSystem.apply(delta, "隐匿", TagSystem.Op.SUB, 1), "SUB changes it too")
	assert_eq(int(delta.get("隐匿", 0)), 1)
	assert_false(TagSystem.apply(delta, "隐匿", TagSystem.Op.SET, 1), "an identical SET is not a change")
	assert_true(TagSystem.apply(delta, "隐匿", TagSystem.Op.SET, 7), "a different SET is")
	assert_eq(int(delta.get("隐匿", 0)), 7)


# ---- Save payload boundary -------------------------------------------------

func test_v9_payload_round_trips_the_delta() -> void:
	var pair := _state_with(2000001, {"social": 1})
	var payload: Dictionary = pair[0].card_instances[1].to_save_dict()
	assert_eq(payload.get("tags_are_delta"), true)
	assert_eq(payload.get("tags"), {"social": 1}, "the save keeps the raw delta")
	var restored = CardInstanceData.from_save_dict(payload)
	assert_eq(restored.tags, {"social": 1})
	assert_true(restored.tag_delta_loaded)


func test_legacy_flattened_row_is_rebased_on_load() -> void:
	var local_db := _local_db()
	# An older clone wrote the whole effective row under `tags` with no marker.
	var payload := {
		"difficulty_index": 1,
		"round_number": 1,
		"card_instances": [{
			"uid": 1, "card_id": 2000001,
			"tags": {"体魄": 5, "魅力": 3, "社交": 1, "遗世": 1},
			"count": 1, "zone": "hand",
		}],
		"next_card_uid": 2,
	}
	var st := GameState.new()
	SaveSystem.deserialize(payload, st, local_db)
	var instance = st.get_card_instance(1)
	assert_eq(int(instance.tags.get("体魄", 0)), 2, "5 stored − 3 definition")
	assert_eq(int(instance.tags.get("魅力", 0)), 1, "3 stored − 2 definition")
	assert_false(instance.tags.has("社交"), "a value equal to the definition becomes no delta")
	assert_eq(int(instance.tags.get("遗世", 0)), 1, "a runtime-only tag is kept verbatim")
	var tags: Dictionary = st.effective_card_tags(1, local_db)
	assert_eq(int(tags.get("体魄", 0)), 5, "the effective row is unchanged by the migration")
	assert_eq(int(tags.get("社交", 0)), 1)


# ---- Original save corpus --------------------------------------------------

func test_corpus_auto_save_tag_rows_match_the_source_gettag() -> void:
	if not FileAccess.file_exists(CORPUS_AUTO_SAVE):
		pending("corpus save sample not available; skipping")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CORPUS_AUTO_SAVE))
	if not (parsed is Dictionary):
		pending("corpus save sample unreadable; skipping")
		return
	var local_db := _local_db()
	var imported: Dictionary = OriginalSaveImporter.import_save(parsed, local_db)
	var state = imported["state"]
	var source := _source_expectation(parsed, local_db)
	assert_gt(source.size(), 100, "the sample carries a full card list")
	var checked := 0
	var mismatches: Array = []
	for raw_uid in source:
		var uid := int(raw_uid)
		var got: Dictionary = state.effective_card_tags(uid, local_db)
		var want: Dictionary = source[raw_uid]
		for raw_name in want:
			var name := str(raw_name)
			if int(got.get(name, 0)) != int(want[name]):
				mismatches.append("%d/%s got=%d want=%d" % [uid, name, int(got.get(name, 0)), int(want[name])])
		if want.is_empty() and not got.is_empty():
			# Every definition tag was driven to zero by a delta.
			for name in got:
				if int(got[name]) != 0:
					mismatches.append("%d/%s got=%d want=absent" % [uid, name, int(got[name])])
		checked += 1
	assert_eq(mismatches, [], "every imported card reproduces the source GetTag row")
	assert_eq(checked, source.size())


## Independent expectations built straight from the save JSON plus config: the
## definition row, the stored delta and the inheritable equips, times count.
## Deliberately does not call the clone's tag helpers.
func _source_expectation(original: Dictionary, local_db) -> Dictionary:
	var out: Dictionary = {}
	var cards: Array = _source_cards(original)
	for card in cards:
		var per_unit: Dictionary = {}
		var card_id := int(card.get("id", 0))
		var definition: Dictionary = local_db.get_card(card_id)
		var base: Variant = definition.get("tag", {})
		if base is Dictionary:
			for name in base:
				per_unit[str(name)] = int(per_unit.get(str(name), 0)) + int(base[name])
		var delta: Variant = card.get("tag", {})
		if delta is Dictionary:
			for raw_name in delta:
				var name := str(local_db.tag_code_to_name.get(str(raw_name), raw_name))
				if name == "sudan_pool_index":
					continue
				per_unit[name] = int(per_unit.get(name, 0)) + int(delta[raw_name])
		for equip in card.get("equips", []):
			if not (equip is Dictionary):
				continue
			var equip_id := int(equip.get("id", 0))
			var equip_definition: Dictionary = local_db.get_card(equip_id)
			var equip_tags: Variant = equip_definition.get("tag", {})
			# Source GetTag's gate belongs to the requested tag (not the gear).
			for term in [equip_tags, equip.get("tag", {})]:
				for raw_name in term:
					var name := str(local_db.tag_code_to_name.get(str(raw_name), raw_name))
					var code := str(local_db.tag_name_to_code.get(name, name))
					if int(local_db.tags_by_code.get(code, {}).get("can_inherit", 0)) != 0:
						per_unit[name] = int(per_unit.get(name, 0)) + int(term[raw_name]) * int(equip.get("count", 1))
		var count := int(card.get("count", 1))
		var row: Dictionary = {}
		for name in per_unit:
			var value := int(per_unit[name])
			if value < 1:
				var code := str(local_db.tag_name_to_code.get(str(name), str(name)))
				var allows := false
				if not code.is_empty() and local_db.tags_by_code.has(code):
					allows = int(local_db.tags_by_code[code].get("can_nagative_and_zero", 0)) != 0
				if not allows:
					value = 0
			row[str(name)] = value * count
		out[int(card.get("uid", 0))] = row
	return out


func _source_cards(original: Dictionary) -> Array:
	var out: Array = []
	for card in original.get("cards", []):
		if card is Dictionary:
			out.append(card)
			for equip in card.get("equips", []):
				if equip is Dictionary:
					out.append(equip)
	return out
