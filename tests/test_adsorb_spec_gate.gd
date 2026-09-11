extends GutTest

const View = preload("res://ui/rite_view.gd")
const ORIGINAL_SAVE = "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"
var db: ConfigDB
var state: GameState

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ORIGINAL_SAVE))
	state = OriginalSaveImporter.import_save(source, db).state

func after_each() -> void:
	await wait_process_frames(2)

func _context() -> Dictionary:
	# Original auto_save uid120 = 2000346 哲瓦德, persisted adsorb_spec=1;
	# original card config has 囚徒=1, whose TagNode.attributes marks the gate.
	return {"state": state, "db": db, "acting_card": state.card_data_for(120, db),
		"acting_card_uid": 120, "acting_card_only": true}

func test_original_saved_marker_rejects_generic_slot_but_allows_explicit_tag() -> void:
	var ctx := _context()
	assert_eq(int(ctx.acting_card.tag.get("adsorb_spec", 0)), 1)
	assert_false(ConditionEval.can_put_card({}, ctx))
	assert_true(ConditionEval.can_put_card({"囚徒": 1}, _context()))
	assert_false(ConditionEval.can_put_card({"囚徒>": 1}, _context()))

func test_failed_executed_tag_can_enable_later_any_branch() -> void:
	var ctx := _context()
	# HasTag sets the flag BEFORE comparing, not only on a successful match.
	assert_true(ConditionEval.can_put_card({"any": {"囚徒>": 1, "is": 2000346}}, ctx))
	assert_true(bool(ctx.get("is_adsorb_spec", false)))

func test_unexecuted_any_branch_does_not_grant_permission() -> void:
	var ctx := _context()
	assert_false(ConditionEval.can_put_card({"any": {"is": 2000346, "囚徒": 1}}, ctx))
	assert_false(bool(ctx.get("is_adsorb_spec", false)))
	assert_false(ConditionEval.can_put_card({}, _context()), "New probe does not inherit another probe's flag")

func test_production_view_and_candidate_scan_use_same_gate() -> void:
	var rite = state.create_rite_instance(5000005)
	var view = View.new()
	view.setup(state, db, GameRNG.new(42), 5000005, rite.uid)
	add_child_autofree(view)
	await wait_process_frames(2)
	view._rite = view._rite.duplicate(true)
	view._rite.cards_slot.s1.condition = {}
	var data := {"type": "card", "card_uid": 120, "source": "hand"}
	assert_false(view.can_drop_card_on_slot("s1", data))
	view.drop_card_on_slot("s1", data)
	assert_false(view._placed.has("s1"))
	assert_true(state.has_card_in_hand(120))
	assert_false(state._can_adsorb_card({"condition": {}}, state.card_data_for(120, db), rite, view._rite, db, GameRNG.new(42)))
	view._rite.cards_slot.s1.condition = {"囚徒": 1}
	assert_true(view.can_drop_card_on_slot("s1", data))
	assert_true(state._can_adsorb_card(view._rite.cards_slot.s1, state.card_data_for(120, db), rite, view._rite, db, GameRNG.new(42)))
	view.drop_card_on_slot("s1", data)
	assert_eq(int(view._placed.get("s1", 0)), 120)
	view._return_slot_to_hand("s1")
	state.rite_instances.erase(rite.uid)
