extends GutTest

const PointShopControllerScript = preload("res://ui/point_shop_controller.gd")
const GlobalExtensionsScript = preload("res://sim/global_extensions.gd")

var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_upgrade_config_is_raw_and_global_fields_round_trip() -> void:
	assert_eq(db.upgrades.size(), 50, "the raw upgrade.json contains 50 UpgradeNodes")
	assert_eq(str(db.get_upgrade(3300016).get("name", "")), "高门贵女")
	var raw_change: Array = db.get_upgrade(3300016).get("effect", {}).get("g.change", [])
	assert_eq([int(raw_change[0]), int(raw_change[1])], [2000006, 2000457])

	var global := GlobalState.new()
	global.total_point = 19
	global.used_point = 7
	global.upgrade_state = "source-state"
	global.upgrades = {3300002: 1, 3300016: 0}
	var restored := GlobalState.new()
	restored._apply_dict(global.to_dict())
	assert_eq(restored.total_point, 19)
	assert_eq(restored.used_point, 7)
	assert_eq(restored.upgrade_state, "source-state")
	assert_eq(restored.upgrades, {3300002: 1, 3300016: 0})


func test_unlock_and_red_dot_use_purchase_membership_not_activation_or_visibility() -> void:
	var global := GlobalState.new()
	global.total_point = 0
	global.upgrades = {3300016: 0}
	assert_true(ConditionEval.evaluate({"unlock_upgrade": 3300016}, {
		"db": db, "global_state": global,
	}), "a deactivated purchase still unlocks its successor")

	var hidden_affordable := db.get_upgrade(3300017)
	hidden_affordable["cost"] = 0
	assert_true(GlobalExtensionsScript.has_available_upgrade(global, db),
		"HasAvailableUpgrade deliberately ignores the UpgradeNode condition")


func test_point_shop_purchase_activate_and_deactivate_replay_source_balances() -> void:
	var global := GlobalState.new()
	global.total_point = 25
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var shop = PointShopControllerScript.new()
	shop.setup(db, global)
	stage.add_child(shop)
	await wait_process_frames(2)

	var row = shop._rows[3300002]
	assert_true(shop.on_buy(row))
	assert_eq(global.total_point, 5)
	assert_eq(global.used_point, 20)
	assert_eq(int(global.upgrades[3300002]), 1, "buying auto-activates")
	assert_false(shop.on_buy(row), "membership prevents a repeated purchase")

	row = shop._rows[3300002]
	assert_true(shop.on_deactivate(row))
	assert_eq(int(global.upgrades[3300002]), 0)
	assert_eq(global.total_point, 5, "deactivation never refunds")
	assert_eq(global.used_point, 20)
	row = shop._rows[3300002]
	assert_true(shop.on_activate(row))
	assert_eq(int(global.upgrades[3300002]), 1)


func test_init_player_executes_active_upgrades_in_raw_operation_shape() -> void:
	var state := GameState.new()
	state.global_state = GlobalState.new()
	state.global_counters = state.global_state.counters
	state.global_state.upgrades = {
		3300002: 1, # g.card + runtime tag + local counter
		3300016: 1, # g.change + global counter
		3300038: 1, # append four rock Sultan cards
		3300018: 0, # inactive: must not grant five coins
	}
	state.setup_new_run(db, 0, GameRNG.new(1234), false)

	assert_false(state.has_card_in_hand(2000006), "ChangeCard removes the old wife card")
	assert_true(state.has_card_in_hand(2000457))
	var changed = state.get_card_instance(state.card_uid_for(2000457, "hand"))
	assert_eq(changed.count, 1, "ChangeCard preserves the old stack count")
	var granted = state.get_card_instance(state.card_uid_for(2000019, "hand"))
	assert_not_null(granted)
	assert_eq(int(granted.tags.get("追随者", 0)), 1)
	assert_eq(state.get_counter(7000730), 1)
	assert_eq(state.get_global_counter(7200176), 1)
	assert_eq(state.gold_total(), 0, "inactive upgrades are skipped")
	assert_eq(state.sudan_deck.slice(-4), [2010001, 2010005, 2010009, 2010013],
		"AddSudanCard appends after the base pool shuffle")


func test_shop_replays_source_canvas_and_prefab_key_geometry() -> void:
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var shop = PointShopControllerScript.new()
	shop.setup(db, GlobalState.new())
	stage.add_child(shop)
	await wait_process_frames(2)

	assert_eq((shop.get_node("Shop/Close") as Control).position, Vector2(3717.4, 45.6))
	assert_eq((shop.get_node("Shop/Close") as Control).size, Vector2(80, 82))
	assert_eq((shop.get_node("Shop/DescGroup") as Control).position, Vector2(246, 230))
	assert_eq((shop.get_node("Shop/DescGroup") as Control).size, Vector2(996.78, 1700))
	assert_eq((shop.get_node("Shop/Scroll View") as Control).position, Vector2(1332.12, 127.6))
	assert_eq((shop.get_node("Shop/Scroll View") as Control).size, Vector2(2400, 1901.4))
	assert_eq((shop.get_node("Shop/DescGroup/Title") as Label).text, "命运商店")
	var first_row := shop.get_node("Shop/Scroll View/Content").get_child(0)
	assert_eq((first_row as Control).size, Vector2(2301, 400))
	assert_eq((first_row.get_node("Buy") as Control).position, Vector2(1888, 136.5))
	assert_eq((first_row.get_node("Buy") as Control).size, Vector2(325, 158))
