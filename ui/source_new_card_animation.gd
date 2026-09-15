extends Control
## [SRC: OpCardNewController.Init 0x572f40 cases 0/1, Done 0x572dc0;
## OpCard.prefab NewGet + TextTranslate NEW_CARD; anims/opcard/new.anim.]
signal finished()
signal audio_requested(cue: String)
const Clip = preload("res://ui/source_float_clip.gd")
var clip := Clip.new()
var operation: Dictionary
var banner: TextureRect
var started := false
var completed := false
var _cue := ""

func setup(op: Dictionary, db: ConfigDB) -> void:
	operation = op
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.read("res://assets/original/anims/opcard/new.anim")
	# Parent cell 300x200, center anchor/pivot .5, authored size 200x60.
	position = Vector2(50, 70)
	banner = TextureRect.new()
	banner.texture = load("res://assets/original/ui/prompt_2_bg.png")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.size = Vector2(200, 60)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	var label := Label.new()
	label.position = Vector2(0, 5)
	label.size = Vector2(200, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = db.translate("NEW_CARD")
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.8941177, 0.8745099, 0.7176471))
	banner.add_child(label)
	_cue = GameAudio.settle_card_cue(db, int(op.get("card_id", 0)))
	hide()

func begin() -> void:
	started = true
	show()
	step(0.0)

func _process(delta: float) -> void:
	if started and is_visible_in_tree():
		step(delta)

func step(delta: float) -> void:
	var before := float(operation.get("presentation_elapsed", 0.0))
	var elapsed := minf(clip.duration, before + delta)
	operation["presentation_elapsed"] = elapsed
	for curve in clip.curves:
		var value := Clip.sample(curve, elapsed)
		match str(curve.attribute):
			"m_IsActive": banner.visible = value != 0.0
			"m_AnchoredPosition.y": banner.position.y = -value
	for event in clip.events:
		if float(event.time) > elapsed:
			continue
		if event.functionName == "PlaySFx" and not bool(operation.get("presentation_audio_played", false)):
			operation["presentation_audio_played"] = true
			audio_requested.emit(_cue)
			GameAudio.cue(_cue)
		elif event.functionName == "Done" and not completed:
			completed = true
			finished.emit()
	if elapsed >= clip.duration:
		set_process(false)
