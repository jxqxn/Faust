extends "res://ui/source_new_card_animation.gd"
## Ordinary equipment-tag branch and unconditional NORMAL recovery branch.
## Destructive unequip uses BROKER; its RiftGenerator layer is still unported.
## [SRC: OpCardNewController.Init 0x572f40 case3, equip.anim;
## OpCard.prefab Equip RectTransform224998874197659892.]
var equipment: CardWidget
var source_position := Vector2.ZERO
var source_distance := 0.0
var surface: Control
var special_active := false
var special_enabled := false
var special_progress := 0.0

static func supports(op: Dictionary, db: ConfigDB) -> bool:
	if int(op.get("op", -1)) == 5:
		return true
	if int(op.get("op", -1)) not in [3, 4]:
		return false
	var definition := db.get_card(int(op.get("card_id", 0)))
	for tag in definition.get("tag", {}):
		if db.tag_code_for(tag) == "equipment" and int(definition.tag[tag]) > 0:
			return true
	return false

func setup(op: Dictionary, db: ConfigDB) -> void:
	operation = op
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip_name := "unequip_recovery" if int(op.get("op", -1)) == 5 else "equip"
	if int(op.get("op", -1)) == 4:
		clip_name = "unequip"
	clip.read("res://assets/original/anims/opcard/%s.anim" % clip_name)
	# Source Equip's center in a 300x200 grid cell; CardWidget remains the
	# existing renderer adapter. RawImage 256x512 projection is still open.
	position = Vector2(150, 100)
	equipment = CardWidget.new()
	equipment.name = "Equip"
	add_child(equipment)
	equipment.set_card(db.get_card(int(op.get("card_id", 0))))
	equipment.pivot_offset = equipment.size * 0.5
	equipment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equipment.set_process(false)
	equipment.set_process_input(false)
	equipment.set_process_unhandled_input(false)
	surface = equipment
	if int(op.get("op", -1)) == 4:
		# [SRC: OpCardNewController.Init0x572f40 case4 ordinary branch:
		# Equip.Type=BROKER; host.Type=NORMAL; play unequip.]
		var broker := preload("res://ui/source_opcard_broker.gd").new()
		broker.name = "Broker"
		add_child(broker)
		broker.setup(equipment)
		surface = broker
	hide()

func step(delta: float) -> void:
	var elapsed := minf(clip.duration, float(operation.get("presentation_elapsed", 0.0)) + delta)
	operation["presentation_elapsed"] = elapsed
	for curve in clip.curves:
		if curve.path == "Equip/Special":
			# Source RiftGenerator (dump.cs:420474) is a separate procedural
			# texture layer, NOT opacity on Equip. Retain bindings for auditing
			# without inventing a substitute visual or random draw.
			match str(curve.attribute):
				"m_IsActive": special_active = Clip.sample(curve, elapsed) != 0.0
				"m_Enabled": special_enabled = Clip.sample(curve, elapsed) != 0.0
				"progress": special_progress = Clip.sample(curve, elapsed)
			continue
		assert(curve.path == "Equip", "equip.anim node bindings must remain source-reviewed")
		var value := Clip.sample(curve, elapsed)
		match str(curve.attribute):
			"m_IsActive": surface.visible = value != 0.0
			"m_AnchoredPosition.x": source_position.x = value
			"m_AnchoredPosition.y": source_position.y = value
			"distance":
				# Case5 selects NORMAL, so LateUpdate's _BrokerDist write has no
				# consumer. Preserve the curve but do not invent fade/displacement.
				# [SRC: Init0x572f40 case5; set_Type0x576790; OpCard.mat;
				# original DXBC OpCardShow/Default182_7..10: no cb0[7].w read.]
				source_distance = value
	if int(operation.get("op", -1)) == 4:
		surface.set_distance(source_distance)
	surface.position = Vector2(source_position.x, -source_position.y) - surface.size * 0.5
	for curve in clip.rotation_curves:
		assert(curve.path == "Equip")
		var q := Clip.sample_rotation(curve, elapsed)
		assert(is_zero_approx(q.x) and is_zero_approx(q.y), "Non-planar source rotation needs projection")
		surface.rotation = -2.0 * atan2(q.z, q.w)
	for event in clip.events:
		if event.functionName == "Done" and float(event.time) <= elapsed and not completed:
			completed = true
			finished.emit()
	if elapsed >= clip.duration:
		set_process(false)
