## Source next-day overlay. State/timing is owned by the saved transition.
## [SRC: GameScene GO2638/2564, masks GO2637/944, Next Round/NextDay_Round.]
extends Control
const Clock = preload("res://ui/next_day_clock.gd")
var mask_root: Node2D
var rings: Array[TextureRect] = []
var clock_root: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask_root = Node2D.new()
	# [SRC: GameScene ParticleSystemRenderer sortingOrder=-1; original runtime
	# night-moving/day-enter: chrome and hand render above the night particles.]
	mask_root.z_as_relative = false
	mask_root.z_index = 20
	add_child(mask_root)
	# Two stationary particles per burst, ringBuffer keeps them alive; child
	# emitter y=54, scale.y=-1. Particle size=60 and rotation=-PI/2.
	for child_emitter in [false, true]:
		var emitter := Node2D.new()
		emitter.position = Vector2(0,-54) if child_emitter else Vector2.ZERO
		emitter.scale.y = -1 if child_emitter else 1
		mask_root.add_child(emitter)
		for index in range(2):
			var quad := TextureRect.new()
			quad.texture = preload("res://assets/original/ui/next_day/ND_text_mask04.png")
			quad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			quad.size = Vector2(60,60)
			# ParticleSystemRenderer pivot is a vertex offset in particle-size
			# units, not a RectTransform origin to subtract. Source: size=60,
			# pivot.x=-.05, mirrored emitter separation=54. The solid edges
			# meet at local y=-27: 60*(.5-.05)=27, 2*27=54.
			# The old +3 offset produced a 12-unit overlap and a dark stripe.
			quad.position = Vector2(-33,-30)
			quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var pivot := Node2D.new()
			pivot.rotation = -PI/2
			emitter.add_child(pivot)
			pivot.add_child(quad)
			var material := ShaderMaterial.new()
			material.shader = preload("res://ui/next_day_mask.gdshader")
			material.set_shader_parameter("mask_texture",quad.texture)
			quad.material = material
	clock_root = Control.new()
	clock_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clock_root)
	for art in ["ND_round01_1","ND_round06","ND_round01_2","ND_round02","ND_round03_2","ND_round03_1","ND_round04","ND_round05"]:
		var ring := TextureRect.new()
		ring.texture = load("res://assets/original/ui/next_day/%s.png" % art)
		ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ring.size = Vector2(512,512)
		ring.position = Vector2(-256,-256)
		ring.pivot_offset = Vector2(256,256)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clock_root.add_child(ring)
		rings.append(ring)

func present(progress: Dictionary, view_size: Vector2) -> void:
	visible = progress.has("animation")
	if not visible:
		return
	var clock: Dictionary = progress.animation
	var k := view_size / Vector2(3840,2160)
	var day := bool(clock["continue"])
	var pos := Clock.mask_position(clock, day)
	mask_root.position = view_size * 0.5 + Vector2(pos.x,-pos.y) * 100.0 * k
	mask_root.rotation_degrees = -50
	mask_root.scale = Vector2(120,150) * k
	mask_root.visible = float(clock.day_time) < 4.0
	clock_root.position = view_size + Vector2(-235,-277) * k
	clock_root.scale = k
	rings[2].rotation_degrees = Clock.ring_degrees(clock,0)
	rings[5].rotation_degrees = Clock.ring_degrees(clock,1)
	rings[6].rotation_degrees = Clock.ring_degrees(clock,2)
