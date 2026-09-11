extends Node

## ConfirmNew Confirm/Cancel Selectable ColorBlock (prefab m_Transition=1).
## Engine API adapter; not a recovered native Selectable method body.
## [SRC: ConfirmNew.prefab m_Colors/m_TargetGraphic/m_Navigation;
## ConfirmController.Show 0x53fc30 / Done 0x53fb70.]
const HIGHLIGHT := Color(0.9607843, 0.9607843, 0.9607843, 1)
const PRESSED := Color(0.78431374, 0.78431374, 0.78431374, 1)
const DISABLED := Color(0.78431374, 0.78431374, 0.78431374, 0.5019608)
const FADE_SECONDS := 0.1
var button: Button
var graphic: CanvasItem
var disabled_color := DISABLED
var _target := Color.WHITE
var _from := Color.WHITE
var _started := 0

func _process(_delta: float) -> void:
	var next := Color.WHITE
	if button.disabled:
		next = disabled_color
	elif button.is_pressed():
		next = PRESSED
	elif button.has_focus() or button.is_hovered():
		next = HIGHLIGHT
	if next != _target:
		_from = graphic.modulate
		_target = next
		_started = Time.get_ticks_usec()
	var elapsed := float(Time.get_ticks_usec() - _started) / 1000000.0
	graphic.modulate = _from.lerp(_target, clampf(elapsed / FADE_SECONDS, 0.0, 1.0))
