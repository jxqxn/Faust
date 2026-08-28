## Source-shaped OverNewStep2StoryController presentation and pager.
## [SRC: OverNewStep2StoryController.c @ OnPrev/OnNext/EnableAfterStoryControl
##       (RVA 0x57bae0/0x57b860/0x57aaf0), _Init_d__27.c @ MoveNext
##       (RVA 0x5863e0), AfterStoryItem.prefab, Over.prefab/Step2-Story.]
class_name OverNewStep2StoryControllerView
extends Control

const AfterStoryItemViewScript = preload("res://ui/over_new_after_story_item.gd")
const DESIGN_SPACE := Vector2(3840, 2160)
const STORY_VIEW_RECT := Rect2(2640, 200, 1050, 1760)
const AFTER_STORY_RECT := Rect2(2790, 200, 1000, 1860)
const ITEM_WIDTH := 1000.0

var _entry: Dictionary = {}
var _state
var _db
var _over_data: Dictionary = {}
var _story_view: Control
var _story_text: RichTextLabel
var _story_blocker: Control
var _after_story: Control
var _after_viewport: Control
var _after_content: Control
var _prev: Button
var _next: Button
var _items: Array[OverNewAfterStoryItemView] = []
var after_story_item_index := 0


func setup(entry: Dictionary, state, db, over_data: Dictionary, story_text: String) -> void:
	_entry = entry
	_state = state
	_db = db
	_over_data = over_data
	set_meta("source_story_text", story_text)


func _ready() -> void:
	name = "Step2-Story"
	size = DESIGN_SPACE
	_build_surface()
	_init_after_story_items()
	show_story()


func _build_surface() -> void:
	var bg := TextureRect.new()
	bg.name = "BG"
	bg.position = Vector2(2133, 0)
	bg.size = Vector2(1707, 2160)
	bg.texture = _ui_texture("after_story_content_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_story_view = Control.new()
	_story_view.name = "Story View"
	_story_view.position = STORY_VIEW_RECT.position
	_story_view.size = STORY_VIEW_RECT.size
	add_child(_story_view)
	var scroll := ScrollContainer.new()
	scroll.name = "Viewport"
	scroll.size = STORY_VIEW_RECT.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_story_view.add_child(scroll)
	var content_root := VBoxContainer.new()
	content_root.name = "Content"
	content_root.custom_minimum_size = Vector2(1033, 520)
	scroll.add_child(content_root)
	var front := Control.new()
	front.name = "Front Spacer"
	front.custom_minimum_size = Vector2(893, 300)
	content_root.add_child(front)
	var title := Label.new()
	title.name = "Title"
	title.text = str(_entry.get("name", ""))
	title.custom_minimum_size = Vector2(893, 180)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	content_root.add_child(title)
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.custom_minimum_size = Vector2(893, 40)
	content_root.add_child(spacer)
	_story_text = RichTextLabel.new()
	_story_text.name = "Story"
	_story_text.text = str(get_meta("source_story_text", ""))
	_story_text.custom_minimum_size = Vector2(893, 0)
	_story_text.fit_content = true
	_story_text.add_theme_font_size_override("normal_font_size", 42)
	content_root.add_child(_story_text)
	_story_blocker = Control.new()
	_story_blocker.name = "Story View Blocker"
	_story_blocker.position = Vector2(2790, 200)
	_story_blocker.size = Vector2(1000, 1760)
	add_child(_story_blocker)
	_build_after_story_surface()


func _build_after_story_surface() -> void:
	_after_story = Control.new()
	_after_story.name = "After Story"
	_after_story.position = AFTER_STORY_RECT.position
	_after_story.size = AFTER_STORY_RECT.size
	add_child(_after_story)
	_after_viewport = Control.new()
	_after_viewport.name = "Viewport"
	_after_viewport.position = Vector2(0, 50)
	_after_viewport.size = Vector2(1000, 1760)
	_after_viewport.clip_contents = true
	_after_story.add_child(_after_viewport)
	_after_content = Control.new()
	_after_content.name = "Content"
	_after_content.size = Vector2.ZERO
	_after_viewport.add_child(_after_content)
	var ops := Control.new()
	ops.name = "Op Contents"
	ops.position = Vector2(0, 1660)
	ops.size = Vector2(1000, 200)
	_after_story.add_child(ops)
	_prev = _pager_button("Prev", Rect2(216, 31, 168, 156), "page_left_0.png")
	_prev.pressed.connect(on_prev)
	ops.add_child(_prev)
	_next = _pager_button("Next", Rect2(616, 31, 168, 156), "page_right.png")
	_next.pressed.connect(on_next)
	ops.add_child(_next)
	var confirm := _pager_button("Confirm", Rect2(936, 139, 44, 51), "jump.png")
	ops.add_child(confirm)
	var zoom := _pager_button("Zoom", Rect2(3647, 2007, 93, 93), "expand.png")
	zoom.pressed.connect(toggle_zoom)
	add_child(zoom)


func _init_after_story_items() -> void:
	var candidates: Array[Dictionary] = []
	var player_data = _over_data.get("player_data")
	if not _over_data.is_empty() and player_data == null:
		_collect_recorded_items(candidates)
	else:
		_collect_runtime_items(candidates)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary):
		var sort_a := int(a["settlement"].get("sort", 10))
		var sort_b := int(b["settlement"].get("sort", 10))
		if sort_a != sort_b:
			return sort_a < sort_b
		return int(a["card_id"]) < int(b["card_id"]))
	for candidate in candidates:
		var item := AfterStoryItemViewScript.new()
		item.setup(candidate["settlement"], str(candidate["pic"]), int(candidate["card_id"]))
		item.position = Vector2(_items.size() * ITEM_WIDTH, -70)
		_after_content.add_child(item)
		_items.append(item)
	_after_content.size = Vector2(_items.size() * ITEM_WIDTH, 1900)
	_refresh_pager()


func _collect_recorded_items(out: Array[Dictionary]) -> void:
	# [SRC: InitAfterStoryItem(AfterStoryData, AfterStoryNode) 0x57b3c0]
	# replays the stored prior key and extra key set without re-evaluating the
	# old Player. This is the artifact-preserving record branch.
	for raw_data in _over_data.get("after_storys", []):
		if not (raw_data is Dictionary):
			continue
		var data := raw_data as Dictionary
		var card_id := int(data.get("card_id", 0))
		var node: Dictionary = _db.get_after_story(card_id) if _db != null else {}
		if node.is_empty():
			continue
		var prior_key := str(data.get("prior", ""))
		if not prior_key.is_empty():
			for raw in node.get("prior", []):
				if raw is Dictionary and str(raw.get("key", "")) == prior_key and _has_text(raw):
					out.append({"settlement": raw, "pic": str(data.get("pic", "")), "card_id": card_id})
					break
		var extra_keys := _string_set(data.get("extra", []))
		for raw in node.get("extra", []):
			if raw is Dictionary and extra_keys.has(str(raw.get("key", ""))) and _has_text(raw):
				out.append({"settlement": raw, "pic": str(data.get("pic", "")), "card_id": card_id})


func _collect_runtime_items(out: Array[Dictionary]) -> void:
	# [SRC: _Init_d__27 MoveNext 0x5863e0] iterates Datapool.after_story,
	# resolves the matching total-card instance when present, then emits the
	# first eligible prior settlement or every eligible extra settlement.
	if _db == null:
		return
	for raw_id in _db.after_stories.keys():
		var card_id := int(raw_id)
		var node: Dictionary = _db.get_after_story(card_id)
		if node.is_empty():
			continue
		var ctx := _runtime_condition_context(card_id)
		var close_condition = node.get("close_condition", {})
		if close_condition is Dictionary and not close_condition.is_empty() and ConditionEval.evaluate(close_condition, ctx):
			continue
		var pic := _runtime_pic(card_id, node)
		var prior_added := false
		for raw in node.get("prior", []):
			if raw is Dictionary and _settlement_matches(raw, ctx):
				out.append({"settlement": raw, "pic": pic, "card_id": card_id})
				prior_added = true
				break
		if prior_added:
			continue
		for raw in node.get("extra", []):
			if raw is Dictionary and _settlement_matches(raw, ctx):
				out.append({"settlement": raw, "pic": pic, "card_id": card_id})


func _settlement_matches(settlement: Dictionary, ctx: Dictionary) -> bool:
	if not _has_text(settlement):
		return false
	var condition = settlement.get("condition", {})
	return not (condition is Dictionary) or condition.is_empty() or ConditionEval.evaluate(condition, ctx)


func _has_text(settlement: Dictionary) -> bool:
	return not str(settlement.get("result_title", "")).is_empty() or not str(settlement.get("result_text", "")).is_empty()


func _runtime_pic(card_id: int, node: Dictionary) -> String:
	var card_uid := _runtime_card_uid(card_id)
	if card_uid > 0:
		var card: Dictionary = _db.get_card(card_id)
		var resource = card.get("resource", "cards/%d" % card_id)
		if resource is Array:
			return str(resource[0]) if not resource.is_empty() else "cards/%d" % card_id
		return str(resource)
	var configured := str(node.get("pic", ""))
	return configured if not configured.is_empty() else "cards/%d" % card_id


func _runtime_condition_context(card_id: int) -> Dictionary:
	# [SRC: _Init_d__27 MoveNext 0x5863e0] constructs the ConditionContext
	# around the matching total-card entry before evaluating close/prior/extra.
	# Keep the definition as the acting card when the ending snapshot no longer
	# contains a live instance; bind the UID whenever the runtime card survives.
	var card_uid := _runtime_card_uid(card_id)
	var acting_card: Dictionary = _db.get_card(card_id)
	if card_uid > 0 and _state != null and _state.has_method("card_data_for"):
		acting_card = _state.card_data_for(card_uid, _db)
	return {
		"db": _db,
		"state": _state,
		"card_uid": card_uid,
		"acting_card_id": card_id,
		"acting_card": acting_card,
		"acting_card_only": true,
	}


func _runtime_card_uid(card_id: int) -> int:
	if _state == null:
		return 0
	if _state.has_method("card_uid_for"):
		return int(_state.card_uid_for(card_id))
	for instance in _state.card_instances.values():
		if int(instance.card_id) == card_id:
			return int(instance.uid)
	return 0


func show_story() -> void:
	_story_view.visible = true
	_story_blocker.visible = true
	_after_story.visible = false


func show_after_story() -> void:
	_story_view.visible = false
	_story_blocker.visible = false
	_after_story.visible = true
	if not _items.is_empty():
		_items[after_story_item_index].bind()


func has_after_story_items() -> bool:
	return not _items.is_empty()


func item_count() -> int:
	return _items.size()


func on_prev() -> void:
	if after_story_item_index < 1:
		return
	_items[after_story_item_index].unbind()
	after_story_item_index -= 1
	_after_content.position.x = -after_story_item_index * ITEM_WIDTH
	_items[after_story_item_index].bind()
	_refresh_pager()


func on_next() -> void:
	if after_story_item_index >= _items.size() - 1:
		return
	_items[after_story_item_index].unbind()
	after_story_item_index += 1
	_after_content.position.x = -after_story_item_index * ITEM_WIDTH
	_items[after_story_item_index].bind()
	_refresh_pager()


func toggle_zoom() -> void:
	# The source tween expands/collapses the right panel. Keep the same binary
	# control boundary; exact zoom interpolation remains a visual-only gap.
	var expanded := bool(get_meta("zoom", false))
	set_meta("zoom", not expanded)
	position.x = 0 if expanded else -1707


func _refresh_pager() -> void:
	if _prev == null or _next == null:
		return
	_prev.visible = _items.size() > 1
	_next.visible = _items.size() > 1
	_prev.disabled = after_story_item_index <= 0
	_next.disabled = after_story_item_index >= _items.size() - 1


func _pager_button(node_name: String, rect: Rect2, texture_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.icon = _ui_texture(texture_name)
	button.expand_icon = true
	button.flat = true
	return button


func _ui_texture(file_name: String) -> Texture2D:
	var path := "res://assets/original/ui/%s" % file_name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _string_set(raw: Variant) -> Dictionary:
	var out := {}
	if raw is Array:
		for value in raw:
			out[str(value)] = true
	elif raw is Dictionary:
		for value in raw.keys():
			out[str(value)] = true
	return out
