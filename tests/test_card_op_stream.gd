extends GutTest

## CardOpContext stream: ResultExec records the card operation log, and the
## result surface renders the real stream instead of leaving its authored
## destinations empty.
## [SRC: RiteResultPanelController.c @ AddCardOp (RVA 0x5a0e60) queues
##       CardOpContext; dump.cs:394326 CardOpType NEW0 COPY1 DELETE2 EQUIP3
##       UNEQUIP4 UNEQUIP_RECOVERY5 ADD_TAG6 REMOVE_TAG7 UPRARE8.]

const RNG = preload("res://core/rng.gd")
const ResultExecScript = preload("res://sim/result.gd")
const RiteViewScript = preload("res://ui/rite_view.gd")


var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func _ops_of(res: Dictionary) -> Array:
	# RiteResolver/ResultExec return the deferred struct itself, so the recorded
	# CardOpContext stream is a top-level key.
	return res.get("card_ops", [])


func test_log_is_passive_until_recording_begins() -> void:
	var state := GameState.new()
	state.create_card_instance(2000001, db, "hand")
	assert_eq(state.card_op_log.size(), 0, "mutations outside a settlement are not logged")
	assert_false(state.is_recording_result_ops())


func test_generating_a_card_records_a_new_operation() -> void:
	var state := GameState.new()
	var res: Dictionary = ResultExecScript.execute({"card": 2000001}, state, db, {})
	var ops := _ops_of(res)
	assert_eq(ops.size(), 1, "one generated card yields one operation row")
	assert_eq(int(ops[0]["op"]), GameState.CARD_OP_NEW, "and it is CardOpType.NEW")
	assert_eq(int(ops[0]["card_id"]), 2000001)
	assert_gt(int(ops[0]["card_uid"]), 0, "the row carries the runtime uid")


func test_copy_operator_records_a_copy_operation_with_its_source() -> void:
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var source_uid := state.card_uid_for(2000001)
	state.add_card_to_slot(source_uid, 1, db, 0)
	var res: Dictionary = ResultExecScript.execute({"copy.s1": 1}, state, db, {})
	var ops := _ops_of(res)
	assert_eq(ops.size(), 1)
	assert_eq(int(ops[0]["op"]), GameState.CARD_OP_COPY)
	assert_eq(int(ops[0]["source_uid"]), source_uid, "the copy names the card it came from")


func test_uprare_records_the_rarity_transition() -> void:
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var uid := state.card_uid_for(2000001)
	state.add_card_to_slot(uid, 1, db, 0)
	var before: int = int(state.card_data_for(uid, db).get("rare", 1))
	var res: Dictionary = ResultExecScript.execute({"s1.uprare": 1}, state, db, {})
	var ops := _ops_of(res)
	assert_eq(ops.size(), 1, "one uprare yields one row")
	assert_eq(int(ops[0]["op"]), GameState.CARD_OP_UPRARE)
	assert_eq(int(ops[0]["rare_before"]), before)
	assert_eq(int(ops[0]["rare_after"]), before + 1)


func test_clean_records_a_delete_operation() -> void:
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var uid := state.card_uid_for(2000001)
	state.add_card_to_slot(uid, 1, db, 0)
	var res: Dictionary = ResultExecScript.execute({"clean.s1": 1}, state, db, {})
	var ops := _ops_of(res)
	assert_true(ops.any(func(o): return int(o["op"]) == GameState.CARD_OP_DELETE),
		"cleaning a slot records CardOpType.DELETE for the removed card")


func test_equip_operations_are_recorded_with_their_host() -> void:
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var host_uid := state.card_uid_for(2000001)
	state.add_card_to_slot(host_uid, 1, db, 0)
	var res: Dictionary = ResultExecScript.execute({"s1+equip": 2000156}, state, db, {})
	var ops := _ops_of(res)
	assert_true(ops.any(func(o): return int(o["op"]) == GameState.CARD_OP_EQUIP),
		"equipping records CardOpType.EQUIP")
	var equip_row: Dictionary = {}
	for op in ops:
		if int(op["op"]) == GameState.CARD_OP_EQUIP:
			equip_row = op
			break
	assert_eq(int(equip_row.get("host_uid", 0)), host_uid, "the row names the host")


func test_no_operations_yields_an_empty_stream() -> void:
	var state := GameState.new()
	var res: Dictionary = ResultExecScript.execute({"coin": 3}, state, db, {})
	var ops := _ops_of(res)
	for op in ops:
		assert_ne(int(op["op"]), GameState.CARD_OP_UPRARE, "a coin grant is not a card mutation")


func test_add_tag_records_the_tag_row() -> void:
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var uid := state.card_uid_for(2000001)
	state.add_card_to_slot(uid, 1, db, 0)
	var res: Dictionary = ResultExecScript.execute({"self+隐匿": 2}, state, db, {"card_uid": uid})
	var ops := _ops_of(res)
	assert_eq(ops.size(), 1, "one visible tag write yields one row")
	assert_eq(int(ops[0]["op"]), GameState.CARD_OP_ADD_TAG)
	assert_eq(str(ops[0]["tag"]), "隐匿", "the row names the tag, not just the card")
	assert_eq(int(ops[0]["amount"]), 2)
	assert_eq(int(ops[0]["card_uid"]), uid)


func test_remove_tag_records_a_distinct_operation_type() -> void:
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var uid := state.card_uid_for(2000001)
	state.add_card_to_slot(uid, 1, db, 0)
	var res: Dictionary = ResultExecScript.execute({"self-隐匿": 1}, state, db, {"card_uid": uid})
	var ops := _ops_of(res)
	assert_eq(ops.size(), 1)
	assert_eq(int(ops[0]["op"]), GameState.CARD_OP_REMOVE_TAG, "a subtraction is CardOpType.REMOVE_TAG")


func test_invisible_tags_mutate_without_entering_the_stream() -> void:
	# TagNode.can_visible == 0 (262 of 442 configured tags: 影响力 / 污名 /
	# 耐心 / 专属 ...) is internal state: the original's AddCardOp returns
	# before the list push, so no result row is ever produced for it.
	# [SRC: RiteResultPanelController.c @ AddCardOp 0x5a0e60 lines 0x3335-0x3343]
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var uid := state.card_uid_for(2000001)
	state.add_card_to_slot(uid, 1, db, 0)
	assert_eq(int(db.tags_by_code["influence"].get("can_visible", -1)), 0,
		"fixture guard: 影响力 is configured can_visible=0")
	var res: Dictionary = ResultExecScript.execute({"self+影响力": 2}, state, db, {"card_uid": uid})
	assert_eq(_ops_of(res).size(), 0, "an invisible tag never reaches the result list")
	# ...but the card still really gained the tag.
	var instance = state.get_card_instance(uid)
	assert_eq(int(instance.tags.get("影响力", 0)), 2, "the mutation itself still happened")


func test_blocked_tag_write_still_reports_the_invoked_operation() -> void:
	# 已拥有 is can_add=0 and 阿尔图's definition row already carries it, so
	# CardExtensions.AddTag leaves the card unchanged. The row is still reported:
	# the original builds it in the operation's PreDo phase, before Do() runs the
	# can_add gate, and the result panel filters only on can_visible.
	# [SRC: DesktopModifyTag.__c__DisplayClass7_1.c @ <PreDo>b__2 0x521f60;
	#       CardExtensions.c @ ConvertToAddOrSub 0x37f1c0 can_add branch]
	var state := GameState.new()
	state.add_card_to_hand(2000001, db)
	var uid := state.card_uid_for(2000001)
	state.add_card_to_slot(uid, 1, db, 0)
	var res: Dictionary = ResultExecScript.execute({"self+已拥有": 1}, state, db, {"card_uid": uid})
	var ops := _ops_of(res)
	assert_eq(ops.size(), 1, "an invoked ModifyTag is reported even when can_add blocks it")
	assert_eq(int(ops[0]["op"]), GameState.CARD_OP_ADD_TAG)
	var instance = state.get_card_instance(uid)
	assert_false(instance.tags.has("已拥有"), "the can_add gate kept the card unchanged")


func test_result_surface_renders_the_recorded_stream() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(4401))
	var view = RiteViewScript.new()
	add_child_autofree(view)
	view.setup(state, db, RNG.new(4402), 5000001)
	# Feed the surface the same shape _display_result receives.
	var res: Dictionary = ResultExecScript.execute({"card": 2000001}, state, db, {})
	view._rebuild_result_lists(res)
	var rows := 0
	for layer in [view._result_cards_layer, view._result_ops_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			if str(child.name).begins_with("CardOp"):
				rows += 1
				assert_eq(int(child.get_meta("source_card_op")), GameState.CARD_OP_NEW,
					"the rendered row keeps the CardOpType value")
	assert_eq(rows, _ops_of(res).size(), "one rendered row per recorded operation")
	assert_gt(rows, 0, "the authored destinations are no longer empty")


func test_rebuild_clears_previous_rows() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(4403))
	var view = RiteViewScript.new()
	add_child_autofree(view)
	view.setup(state, db, RNG.new(4404), 5000001)
	var first: Dictionary = ResultExecScript.execute({"card": 2000001}, state, db, {})
	view._rebuild_result_lists(first)
	var second: Dictionary = ResultExecScript.execute({}, state, db, {})
	view._rebuild_result_lists(second)
	for layer in [view._result_cards_layer, view._result_ops_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			assert_false(str(child.name).begins_with("CardOp"),
				"an empty operation stream leaves no stale rows")
