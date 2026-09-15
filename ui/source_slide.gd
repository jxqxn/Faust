extends Control
## [SRC: SlideController.Show 0x5ab9c0 / OnNext 0x5ab900 / OnPrev
## 0x5ab960 / OnClose 0x5ab890; Slide.prefab and SlideItem.prefab.]
signal closed()
var payload: Dictionary
var canvas: Control
var pages: Control
var previous: TextureButton
var next: TextureButton
var close_button: TextureButton
var _closed := false
const PAGE_SIZE := Vector2(2048, 1068) * (100.0 / 75.65571)
# UIImageExtensions.LoadSprite(nativeSize=true) -> Image.SetNativeSize;
# source slide/1-*.asset PPU75.65571, GameScene Canvas referencePPU100.

func setup(data: Dictionary, db: ConfigDB) -> void:
	payload = data
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas = Control.new()
	canvas.size = Vector2(3840, 2150)
	add_child(canvas)
	_picture(canvas, "Background", "slide_bg_0", Rect2(0, 0, 3840, 2150))
	var clip := Control.new()
	clip.name = "Viewport"
	clip.position = Vector2(576.205, 311)
	clip.size = Vector2(2707.59, 1408)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(clip)
	pages = Control.new()
	pages.name = "Content"
	pages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(pages)
	var images: Array = payload.get("images", [])
	for index in images.size():
		var resource := str(db.variable_config.get(str(images[index]), str(images[index])))
		# Source UIImageExtensions.LoadSprite resolves image/<resource>.
		var item := _picture(pages, "SlideItem%d" % index, resource, Rect2(Vector2(index * PAGE_SIZE.x, 0), PAGE_SIZE))
		item.set_meta("source_resource", resource)
	_picture(canvas, "Title", "slide_title", Rect2(1712, 156, 436, 110))
	previous = _button("Prev", "slide_prev", Rect2(488.705, 935, 87, 160), -1)
	next = _button("Next", "slide_next", Rect2(3283.795, 937, 90, 156), 1)
	previous.visible = images.size() > 1
	next.visible = images.size() > 1
	close_button = _button("Close", "checkbox_bg", Rect2(3303.795, 251, 80, 82), 0)
	_picture(close_button, "Image", "close_2", Rect2(18.5, 17.5, 43, 47))
	close_button.pressed.connect(_close)
	resized.connect(_layout)
	_layout()
	_apply_scroll()

func _picture(parent: Node, title: String, resource: String, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.name = title
	image.position = rect.position
	image.size = rect.size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := "res://assets/original/ui/" + resource + ".png"
	if ResourceLoader.exists(path):
		image.texture = load(path)
	else:
		push_error("Missing original slide image: " + resource)
	parent.add_child(image)
	return image

func _close() -> void:
	# OnClose clears the source promise before resolving it. Reentrant input
	# must not resolve or close the next queued slide (0x5ab890).
	if _closed:
		return
	_closed = true
	hide()
	closed.emit()

func _button(title: String, resource: String, rect: Rect2, direction: int) -> TextureButton:
	var button := TextureButton.new()
	button.name = title
	button.texture_normal = load("res://assets/original/ui/" + resource + ".png")
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = rect.position
	button.size = rect.size
	canvas.add_child(button)
	if direction != 0:
		button.pressed.connect(func():
			payload["index"] = clampi(int(payload.get("index", 0)) + direction, 0, payload.images.size() - 1)
			payload["targeted"] = true)
	return button

func _layout() -> void:
	var factor := minf(size.x / 3840.0, size.y / 2160.0)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - canvas.size * factor) * 0.5

func _process(delta: float) -> void:
	if payload.is_empty():
		return
	var count: int = payload.images.size()
	var position_value := float(payload.get("position", 0.0))
	var index := int(payload.get("index", 0))
	if not bool(payload.get("targeted", false)):
		index = maxi(0, ceili(count * position_value) - 1)
	var target := float(index) / (count - 1) if count > 1 else 0.0
	# SlideController.Update delegates to Mathf.SmoothDamp with prefab
	# smoothTime=.03, threshold=.001. Preserve velocity across save/reload.
	if absf(target - position_value) <= 0.001:
		payload["position"] = target
		payload["velocity"] = 0.0
		payload["targeted"] = false
	else:
		var omega := 2.0 / 0.03
		var x := omega * delta
		var decay := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
		var change := position_value - target
		var velocity := float(payload.get("velocity", 0.0))
		var temp := (velocity + omega * change) * delta
		payload["velocity"] = (velocity - omega * temp) * decay
		var output := target + (change + temp) * decay
		if (target - position_value > 0.0) == (output > target):
			output = target
			payload["velocity"] = 0.0
		payload["position"] = output
	payload["index"] = index
	_apply_scroll()

func _apply_scroll() -> void:
	pages.position.x = -maxf(0.0, payload.images.size() * PAGE_SIZE.x - 2707.59) * float(payload.get("position", 0.0))
