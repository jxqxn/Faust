extends GutTest

## SourceTips: the original Tips tooltip panel.
##
## Every expectation here is either a value authored in `Tips.prefab` or a branch
## of `SlotTipsController.SetPositionInternal` / `set_Width`. Fixtures therefore
## assert against the artifact, not against a previous clone run.
##
## [SRC: _unpack/unity_export/ExportedProject/Assets/Resources/prefab/Tips.prefab;
##       _unpack/engine_spec/decompiled/SlotTipsController.c (0x5ac340 / 0x5aca50);
##       _unpack/engine_spec/decompiled/TipsHolder.c (0x5c4400 / 0x5c53a0).]

const RNG = preload("res://core/rng.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const SourceTips = preload("res://ui/source_tips.gd")
const TipsView = preload("res://ui/tips_view.gd")

const DESIGN := Vector2(3840, 2160)

var db: ConfigDB


func before_all():
	db = ConfigDB.new()
	db.load_all()


func after_all():
	db = null


func _stage() -> Node2D:
	var stage := Node2D.new()
	add_child_autofree(stage)
	return stage


func test_translate_reproduces_the_source_text_tables():
	# data/config/ui.json is the game's default-language caption table: flat
	# KEY -> {zhCN, comment} with simplified Chinese values. The i18n/<locale>
	# folders hold its translations (zhTW = traditional, en = English) and are
	# deliberately not the source of the clone's display language.
	assert_true(db.ui_translations.size() > 300, "the source caption table loaded")
	for tips_id in [
		"BAG_POS_1_TIPS",
		"BAG_POS_2_TIPS",
		"BAG_POS_3_TIPS",
		"BAG_POS_4_TIPS",
		"SORT_HAND_CARD_TIPS",
		"ITHINK_TIPS",
		"EXECUTION_DAY_TIPS",
		"BACK_TO_LAST_ROUND_BEGIN_TIPS",
		"BACK_TO_ROUND_BEGIN_TIPS",
		"RITE_STOP_TIPS",
		"RITE_AUTO_FILL_TIPS",
	]:
		assert_true(db.has_translation(tips_id), "%s resolves from the source table" % tips_id)
	assert_eq(db.translate("BAG_POS_1_TIPS"), "按1选中", "bag position caption")
	assert_eq(db.translate("SORT_HAND_CARD_TIPS"), "点击手牌进行排序", "sort caption")
	assert_eq(db.translate("ITHINK_TIPS"), "俺寻思：将卡牌移至这里，可以触发思考", "iThink caption")
	assert_eq(db.translate("EXECUTION_DAY_TIPS"), "请在处刑日前完成苏丹卡的任务", "execution-day caption")
	assert_eq(db.translate("BACK_TO_LAST_ROUND_BEGIN_TIPS"), "回到上一回合结束", "prev-round caption")
	# [SRC: Datapool.c @ Translate 0x422740 returns the key when both tables miss.]
	assert_eq(db.translate("__no_such_key__"), "__no_such_key__", "unknown keys fall through unchanged")
	assert_false(db.has_translation("__no_such_key__"))


func test_prefab_layout_and_width():
	var view = TipsView.new()
	_stage().add_child(view)
	view.apply_source_layout(DESIGN, Vector2(1920, 1080))
	view.show_for(db, "SORT_HAND_CARD_TIPS", Vector2(1000, 1000), "", 1000)
	assert_eq(view.right.size.x, 500.0, "set_Width = 1920 * 1000 / 3840")
	assert_eq(view.panel.scale, Vector2.ONE, "Godot canvas transform already handles window scaling")
	assert_eq(view.right.position.x, 450.0, "Right pivot is on its left edge")
	assert_eq(view.text_label.position, Vector2(60, 60))
	assert_gte(view.right.size.y, view.text_label.get_minimum_size().y + 120.0)
	assert_eq(view.border.position.x, -17.0, "pivot(1,.5), x=-4, width=13")
	assert_eq(view.border.size.y, view.right.size.y, "stretch anchors drive border height")
	assert_eq(view.border.patch_margin_top, 23)
	assert_eq(view.border.patch_margin_bottom, 26)
	view.move_to(Vector2(3600, 1000))
	assert_eq(view.right.position.x, -50.0, "Left is mirrored about root centre")
	assert_true(view._background.flip_h)
	view.show_for(db, "ITHINK_TIPS", Vector2(1000, 1000))
	assert_eq(view.right.size.x, 800.0)
	assert_not_null(view._background.texture)
	assert_not_null(view.border.texture)


func test_source_clamp_flip_and_world_offsets():
	# DLL RVA->raw constants + SetPositionInternal branch boundaries.
	assert_eq(SourceTips.HORIZONTAL_FLIP_THRESHOLD, 0.8)
	assert_eq(SourceTips.PANEL_WIDTH_REFERENCE, 3840.0)
	var band := Vector2(800, 164)
	var p := SourceTips.panel_origin(Vector2(1000, 1000), DESIGN, band)
	assert_almost_eq(p.x, 590.0, 0.001)
	assert_almost_eq(p.y, 1040.0, 0.001)
	p = SourceTips.panel_origin(Vector2(0, 2160), DESIGN, band)
	assert_almost_eq(p.x, -360.0, 0.001, "pointer clamps to 50 before world offset")
	assert_almost_eq(p.y, 1968.0, 0.001)
	p = SourceTips.panel_origin(Vector2(3800, 2100), DESIGN, band)
	assert_almost_eq(p.x, 3280.0, 0.001, "right-bottom world offset projects to -60")
	assert_almost_eq(p.y, 1978.0, 0.001, "right-bottom projects upward 100")
	p = SourceTips.panel_origin(Vector2(3800, 100), DESIGN, band)
	assert_almost_eq(p.x, 3320.0, 0.001, "right-top projects to -20")
	assert_almost_eq(p.y, 140.0, 0.001)
	assert_eq(SourceTips.band_width(1000, 3840), 1000.0)
	assert_eq(SourceTips.band_width(1000, 1920), 500.0)


func test_holder_input_lifecycle_and_literal_precedence():
	var stage := _stage()
	var target := Button.new()
	stage.add_child(target)
	var view = TipsView.new()
	stage.add_child(view)
	view.attach(db, target, "ITHINK_TIPS")
	view.attach(db, target, "ITHINK_TIPS")
	assert_eq(target.mouse_entered.get_connections().size(), 1, "reattach does not duplicate callbacks")
	target.mouse_entered.emit()
	assert_true(view.visible)
	target.hide()
	assert_false(view.visible, "OnDisable hides the tip")
	target.show()
	target.mouse_entered.emit()
	target.mouse_exited.emit()
	assert_false(view.visible)
	assert_eq(view.resolve_text(db, "ITHINK_TIPS", "literal"), db.translate("ITHINK_TIPS"))
	assert_eq(view.resolve_text(db, "", "literal"), "literal")
	assert_eq(view.resolve_text(db, "missing"), "missing", "Translate miss echoes key")


func test_show_and_hide_resolve_text_and_emit_signals():
	var stage := _stage()
	var view = TipsView.new()
	stage.add_child(view)
	await wait_process_frames(1)

	var seen: Array = []
	view.tips_shown.connect(func(id): seen.append("show:" + id))
	view.tips_hidden.connect(func(id): seen.append("hide:" + id))

	view.show_for(db, "ITHINK_TIPS", Vector2(1000, 1500))
	assert_true(view.visible, "a resolved tip becomes visible")
	assert_eq(view.text_label.text, "俺寻思：将卡牌移至这里，可以触发思考")
	assert_eq(view.source_id(), "ITHINK_TIPS")
	assert_eq(seen, ["show:ITHINK_TIPS"])

	view.hide_tips()
	assert_false(view.visible)
	assert_eq(view.text_label.text, "", "hiding resets the reusable panel")
	assert_eq(seen, ["show:ITHINK_TIPS", "hide:ITHINK_TIPS"])

	# TipsHolder only bails out on empty text; missing keys echo.
	view.show_for(db, "", Vector2(1000, 1500))
	assert_false(view.visible, "empty text shows nothing")


func test_game_screen_wires_the_source_tips_holders():
	var rng := RNG.new(91)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(3)

	var tips = screen._tips
	assert_not_null(tips, "the screen owns one Tips panel")
	if tips == null:
		return

	# MainUI/Next Round/PrevRound and /Sort both author TipsHolder in the scene.
	var prev := screen._back_to_prev_button as Control
	var sort := screen._sort_button as Control
	assert_not_null(prev)
	assert_not_null(sort)
	if prev != null:
		assert_eq(str(prev.get_meta("source_tips_id", "")), "BACK_TO_LAST_ROUND_BEGIN_TIPS")
		assert_eq(float(prev.get_meta("source_tips_need_width", 0.0)), 1000.0)
	if sort != null:
		assert_eq(str(sort.get_meta("source_tips_id", "")), "SORT_HAND_CARD_TIPS")
		assert_eq(float(sort.get_meta("source_tips_need_width", 0.0)), 1000.0)
	# MainUI/RoundNumber BG.
	assert_eq(str(screen._deadline_strip.get_meta("source_tips_id", "")), "EXECUTION_DAY_TIPS")
	# MainUI/BagBtnGroup/BagGroup/{0..3}.
	for index in range(4):
		var button := screen._bag_tabs.buttons[index] as Control
		assert_eq(str(button.get_meta("source_tips_id", "")), "BAG_POS_%d_TIPS" % (index + 1))
	# MainUI/IThink.
	var think := screen._find_node_by_name(screen, "ThinkDropZone") as Control
	assert_not_null(think)
	if think != null:
		assert_eq(str(think.get_meta("source_tips_id", "")), "ITHINK_TIPS")


func test_sort_hand_button_replays_the_source_rect_and_runs_hand_card_sort():
	var rng := RNG.new(92)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(3)

	var sort := screen._sort_button as Button
	assert_not_null(sort, "Next Round/Sort is built")
	if sort == null:
		return
	# [SRC: Next Round/Sort anchors (0,0) pivot (0,0) pos (1,300) sizeDelta 93x93
	#       inside the 596x634 Next Round cluster.]
	assert_eq(sort.position, Vector2(1, 241), "source rect folded into the cluster's top-left origin")
	assert_eq(sort.size, Vector2(93, 93))
	assert_not_null(sort.get_node_or_null("hand_sort"), "the source hand_sort stamp is the button art")

	# HandCardSort 0x5523e0 re-runs HandCardArrange per page; the clone's single
	# page equivalent is sort_current_hand_by_condition with no qualification.
	var rail_before: Array = state.rail_order.duplicate()
	for index in range(rail_before.size()):
		state.get_card_instance(rail_before[index]).bag_pos = rail_before.size() - index
	sort.pressed.emit()
	await wait_process_frames(2)
	for index in range(state.visible_rail_card_uids().size()):
		var uid: int = state.visible_rail_card_uids()[index]
		assert_eq(state.get_card_instance(uid).bag_pos, index + 1, "every card gets a fresh 1..N bagpos")



func test_real_viewport_hover_at_two_resolutions():
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = resolution
		viewport.handle_input_locally = true
		add_child_autofree(viewport)
		var state := GameState.new()
		var rng := RNG.new(93)
		state.setup_new_run(db, 1, rng)
		state.deadline_unshow = false
		var screen = GameScreen.new()
		screen.setup(state, db, rng)
		viewport.add_child(screen)
		await wait_process_frames(3)
		# Isolate input routing: setup_new_run alone has not run the intro Sudan draw.
		screen._deadline_strip.show()
		viewport.notify_mouse_entered()
		var targets: Array = [screen._sort_button, screen._back_to_prev_button,
			screen._deadline_strip, screen._bag_tabs.buttons[0],
			screen._find_node_by_name(screen, "ThinkDropZone")]
		for target in targets:
			var motion := InputEventMouseMotion.new()
			motion.position = target.get_global_rect().get_center()
			viewport.push_input(motion, true)
			await wait_process_frames(2)
			assert_true(screen._tips.visible, "%s at %s opens through input" % [target.name, resolution])
			assert_eq(screen._tips.source_id(), str(target.get_meta("source_tips_id")))
			var expected := SourceTips.panel_origin(motion.position, Vector2(resolution), screen._tips.right.size)
			assert_almost_eq(screen._tips.panel.position, expected, Vector2.ONE * 0.01, "position follows delivered input, not stale OS pointer")
			var rect: Rect2 = screen._tips.right.get_global_rect()
			assert_true(Rect2(Vector2.ZERO, Vector2(resolution)).intersects(rect), "tip is on screen")
			motion = InputEventMouseMotion.new()
			motion.position = Vector2(resolution) * 0.5
			viewport.push_input(motion, true)
			await wait_process_frames(1)
			assert_false(screen._tips.visible, "leaving target hides panel")
		# The same routing fix must restore clicks, and Tips must not consume them.
		var tab: BaseButton = screen._bag_tabs.buttons[1]
		var tab_motion := InputEventMouseMotion.new()
		tab_motion.position = tab.get_global_rect().get_center()
		viewport.push_input(tab_motion, true)
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.position = tab_motion.position
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			viewport.push_input(click, true)
		await wait_process_frames(2)
		assert_eq(state.current_bag_index, 1, "hover panel does not intercept bag-page clicks")
		viewport.notify_mouse_exited()
		viewport.queue_free()
		await wait_process_frames(2)
