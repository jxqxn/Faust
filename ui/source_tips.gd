extends RefCounted

## [SRC: SlotTipsController.c @ SetPositionInternal 0x5ac340 / set_Width
## 0x5aca50 / .cctor 0x5ac920; dump.cs:326121; Tips.prefab.]
## DLL constants were read through PE section RVA -> raw file offset mapping.
const DESIGN := Vector2(3840, 2160)
const PANEL_SIZE := Vector2(900, 164)
const RIGHT_SIZE := Vector2(800, 164)
const PADDING := 60.0
const BORDER_SIZE := Vector2(13, 75) # sprite; the rect stretches to band height
const BORDER_MARGIN_TOP := 23.0
const BORDER_MARGIN_BOTTOM := 26.0
const TEXT_COLOR := Color(0.8666667, 0.8352941, 0.76862746, 1.0)
const TEXT_STYLE_KEY := "@TIPS_FORMAT"
const HORIZONTAL_FLIP_THRESHOLD := 0.8 # RVA 0x1c9e564
const VERTICAL_FLIP_THRESHOLD := 0.2 # RVA 0x1c92b48
const PANEL_WIDTH_REFERENCE := 3840.0 # RVA 0x1c9e7d0
const OFFSET_WORLD := Vector2(0.18518517911434174, -0.18518517911434174)
const OFFSET_RIGHT_BOTTOM_WORLD := Vector2(-0.2777777910232544, 0.46296295523643494)
const OFFSET_RIGHT_TOP_WORLD := Vector2(-0.09259258955717087, -0.18518517911434174)

static func band_width(need_width: float, screen_width: float) -> float:
	return screen_width * need_width / PANEL_WIDTH_REFERENCE if need_width > 0 else RIGHT_SIZE.x

## Input/output in viewport pixels, Godot Y-down. The source clamps the pointer
## BEFORE projecting it; it does not clamp the final panel rectangle.
## World offsets use the current flat UI camera (GameScene Camera4416 size=5).
static func panel_origin(pointer: Vector2, viewport: Vector2, band: Vector2) -> Vector2:
	var k := viewport / DESIGN
	var unity_y := viewport.y - pointer.y
	var x_ratio := pointer.x / viewport.x
	var y_ratio := unity_y / viewport.y
	var left := x_ratio > HORIZONTAL_FLIP_THRESHOLD
	var x := clampf(pointer.x, 50.0 * k.x, viewport.x - ((0.0 if left else band.x) + 50.0) * k.x)
	var lift := 0.0 if left and y_ratio < VERTICAL_FLIP_THRESHOLD else 150.0
	var y := clampf(unity_y, (band.y * 0.5 + lift) * k.y, viewport.y - band.y * 0.25 * k.y)
	var offset := OFFSET_WORLD
	if left:
		if y_ratio > HORIZONTAL_FLIP_THRESHOLD:
			offset = OFFSET_RIGHT_TOP_WORLD
		elif y_ratio < VERTICAL_FLIP_THRESHOLD:
			offset = OFFSET_RIGHT_BOTTOM_WORLD
	var projected := Vector2(offset.x, -offset.y) * viewport.y / 10.0
	return Vector2(x, viewport.y - y) + projected - Vector2(PANEL_SIZE.x * 0.5 * k.x, 0)
