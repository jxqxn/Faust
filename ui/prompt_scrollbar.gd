extends Control

## PromptNew Scrollbar Vertical / Sliding Area / Handle RectTransforms.
## Track: width6 at ScrollView.right+4; area: (-10,5), (27,H-10);
## handle: stretch anchors controlled by Scrollbar.size/value, sizeDelta(0,20).
## [SRC: PromptNew.prefab 224806657225351454 / 224194081240383615 /
## 224354824845356902; ScrollViewTextController.LateUpdate 0x5a8de0]
## Range is supplied by the text viewport; this control owns only presentation
## and pointer translation. Scroll physics remain with the text viewport.
signal scroll_requested(value: float)

var content_height := 0.0
var viewport_height := 0.0
var scroll_value := 0.0
var handle_rect := Rect2()
var track_rect := Rect2()
var _track: StyleBoxTexture
var _thumb: StyleBoxTexture
var _dragging := false
var _drag_offset := 0.0
var _hovered := false
var _tint := Color.WHITE
var _tween: Tween

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_track = _style("scroll_bar", Vector4(0, 212, 0, 171))
	_thumb = _style("scroll_thumb", Vector4(9, 58, 9, 77))
	mouse_entered.connect(func(): _hovered = true; _update_tint())
	mouse_exited.connect(func(): _hovered = false; _update_tint())
	visibility_changed.connect(func():
		if not is_visible_in_tree():
			_dragging = false
			_hovered = false
			_update_tint())

func configure(body_rect: Rect2, content: float, value: float) -> void:
	content_height = content
	viewport_height = body_rect.size.y
	scroll_value = clampf(value, 0.0, maxf(0.0, content - viewport_height))
	# Body is the source Viewport (ScrollView width minus30). Include the
	# handle's ten-pixel overflow beyond both ends in this input control.
	position = body_rect.position + Vector2(body_rect.size.x + 24.0, -5.0)
	size = Vector2(27, viewport_height + 10.0)
	track_rect = Rect2(10, 5, 6, viewport_height)
	var fraction := clampf(viewport_height / maxf(content, 1.0), 0.0, 1.0)
	var sliding_height := maxf(0.0, viewport_height - 10.0)
	var travel := sliding_height * (1.0 - fraction)
	var normalized := scroll_value / maxf(content - viewport_height, 1.0)
	handle_rect = Rect2(0, travel * normalized, 27, sliding_height * fraction + 20.0)
	visible = content > viewport_height + 0.5
	queue_redraw()

func _has_point(point: Vector2) -> bool:
	return track_rect.has_point(point) or handle_rect.has_point(point)

func _draw() -> void:
	if _track == null:
		return
	_track.draw(get_canvas_item(), track_rect)
	_thumb.modulate_color = _tint
	_thumb.draw(get_canvas_item(), handle_rect)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if handle_rect.has_point(event.position):
				_dragging = true
				_drag_offset = event.position.y - handle_rect.position.y
			else:
				var direction := -1.0 if event.position.y < handle_rect.position.y else 1.0
				scroll_requested.emit(clampf(scroll_value + direction * viewport_height,
					0.0, maxf(0.0, content_height - viewport_height)))
		else:
			_dragging = false
		_update_tint()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var travel := maxf(0.0, size.y - handle_rect.size.y)
		if travel > 0.0:
			var fraction := clampf((event.position.y - _drag_offset) / travel, 0.0, 1.0)
			scroll_requested.emit(fraction * maxf(0.0, content_height - viewport_height))
		accept_event()

func _update_tint() -> void:
	if _tween != null:
		_tween.kill()
	# Source Selectable.ColorBlock: normal1, highlighted245/255,
	# pressed200/255, fadeDuration0.1. Only TargetGraphic (Handle) is tinted.
	var level := 200.0 / 255.0 if _dragging else (245.0 / 255.0 if _hovered else 1.0)
	if not is_inside_tree():
		return
	_tween = create_tween()
	_tween.tween_method(_set_tint, _tint, Color(level, level, level), 0.1)

func _set_tint(value: Color) -> void:
	_tint = value
	queue_redraw()

static func _style(asset: String, border: Vector4) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/original/ui/%s.png" % asset)
	style.texture_margin_left = border.x
	style.texture_margin_top = border.y
	style.texture_margin_right = border.z
	style.texture_margin_bottom = border.w
	return style
