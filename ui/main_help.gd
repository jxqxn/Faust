extends Control
class_name MainHelpView
## Source-backed desktop help overlay (GameScene MainUI/MainHelp).
## Geometry is a direct replay of the authored RectTransforms from the
## GameScene truth table docs/ui_layout/GameScene.md (MainUI/MainHelp rows),
## placed on the 3840x2160 MainUI design space with _unity_rect.
## [SRC: GameScene.unity MainUI/MainHelp + Sprite/main.asset +
## data/i18n/zhTW/ui.json MAIN_HELP_* (converted to simplified)]

signal closed

const DESIGN_SPACE := Vector2(3840, 2160)
const SOURCE_ART := "res://assets/original/ui/"
const BUBBLE_SIZE := Vector2(602, 200)
const BUBBLE_FONT_SIZE := 50


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_layout)
	_build()
	_apply_layout()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var source := Control.new()
	source.name = "MainHelpCanvas"
	source.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(source)

	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.color = Color(0.02, 0.015, 0.01, 0.82)
	mask.position = Vector2.ZERO
	mask.size = DESIGN_SPACE
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			closed.emit()
	)
	source.add_child(mask)

	# [SRC: MainHelp/Prompt — full-rect Image with Sprite/main.asset (2048x1092)]
	var prompt_art := TextureRect.new()
	prompt_art.name = "Prompt"
	if ResourceLoader.exists(SOURCE_ART + "main.png"):
		prompt_art.texture = load(SOURCE_ART + "main.png") as Texture2D
	prompt_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prompt_art.stretch_mode = TextureRect.STRETCH_SCALE
	prompt_art.position = Vector2.ZERO
	prompt_art.size = DESIGN_SPACE
	prompt_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source.add_child(prompt_art)

	# [SRC: MainUI/MainHelp/<Name>Prompt rows — 602x200 fs50 bubbles with the
	# authored anchors/anchoredPosition from the GameScene truth table.]
	_add_bubble(source, "SudanBoxPrompt", Vector2(0, 1), Vector2(388, -742), _help_text("SUDAN_BOX"))
	_add_bubble(source, "StoryPrompt", Vector2(0, 0), Vector2(927, 920), _help_text("STORY"))
	_add_bubble(source, "DeadLinePrompt", Vector2(0.5, 1), Vector2(-440, -542), _help_text("DEADLINE"))
	_add_bubble(source, "HandCardPrompt", Vector2(0.5, 0), Vector2(-45, 620), _help_text("HANDCARD"))
	_add_bubble(source, "MenuPrompt", Vector2(0.5, 1), Vector2(1025, -270), _help_text("MENU"))
	_add_bubble(source, "NextDayPrompt", Vector2(1, 0), Vector2(-611, 718), _help_text("NEXT_DAY"))
	_add_bubble(source, "OneTPrompt", Vector2(0, 1), Vector2(878, -568), _help_text("ONE_T"))
	_add_bubble(source, "InfoPrompt", Vector2(1, 0.5), Vector2(-522, 205), _help_text("INFO"))
	_add_bubble(source, "BagPrompt", Vector2(0, 0), Vector2(720.2, 520), _help_text("BAG"))
	_add_bubble(source, "GoldDicePrompt", Vector2(0.5, 1), Vector2(279, -568), _help_text("GOLD"))
	_add_bubble(source, "BackPrompt", Vector2(1, 0), Vector2(-955, 490), _help_text("BACK"))


func _add_bubble(parent: Control, node_name: String, anchor: Vector2, pos: Vector2, text: String) -> void:
	var rect := _unity_rect(DESIGN_SPACE, anchor, anchor, pos, BUBBLE_SIZE, Vector2(0.5, 0.5))
	var bubble := RichTextLabel.new()
	bubble.name = node_name
	bubble.position = rect.position
	bubble.size = rect.size
	bubble.bbcode_enabled = true
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.fit_content = false
	bubble.scroll_active = false
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	bubble.add_theme_font_size_override("normal_font_size", BUBBLE_FONT_SIZE)
	bubble.add_theme_color_override("default_color", Color("#f2e3c0"))
	bubble.text = _to_bbcode(text)
	parent.add_child(bubble)


## The original marks keywords with Unity TMP tags
## (<b><color=white><size=86>…</size></color></b>); Godot 4 RichTextLabel only
## parses [b]/[color]/[font_size], so convert the token forms.
static func _to_bbcode(text_value: String) -> String:
	var out := text_value
	out = out.replace("<color=white>", "[color=white]")
	out = out.replace("</color>", "[/color]")
	# The corpus emphasis size is always 86 (Unity <size=86> -> [font_size=86]).
	out = out.replace("<size=86>", "[font_size=86]")
	out = out.replace("</size>", "[/font_size]")
	out = out.replace("<b>", "[b]")
	out = out.replace("</b>", "[/b]")
	return out


func _apply_layout() -> void:
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var parent_control := get_parent() as Control
		if parent_control != null:
			view_size = parent_control.size
	for child in get_children():
		if child.name == "MainHelpCanvas":
			child.position = Vector2.ZERO
			child.size = DESIGN_SPACE
			child.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


## Unity RectTransform -> Godot Rect2 (see ui/card_info_view.gd;_unity_rect).
static func _unity_rect(
	parent_size: Vector2,
	anchor_min: Vector2,
	anchor_max: Vector2,
	pos: Vector2,
	size_delta: Vector2,
	pivot: Vector2
) -> Rect2:
	var unity_min := Vector2(
		anchor_min.x * parent_size.x + pos.x - pivot.x * size_delta.x,
		anchor_min.y * parent_size.y + pos.y - pivot.y * size_delta.y
	)
	var unity_max := Vector2(
		anchor_max.x * parent_size.x + pos.x + (1.0 - pivot.x) * size_delta.x,
		anchor_max.y * parent_size.y + pos.y + (1.0 - pivot.y) * size_delta.y
	)
	return Rect2(unity_min.x, parent_size.y - unity_max.y, unity_max.x - unity_min.x, unity_max.y - unity_min.y)


## ui.json MAIN_HELP_* (zhTW; simplified for the clone's rendering).
## The original marks keywords with <b><color=white><size=86>…</size></color></b>;
## the simplified text keeps the emphasis markup for the RichTextLabel.
static func _help_text(kind: String) -> String:
	match kind:
		"SUDAN_BOX":
			return "点击可以叫出<b><color=white><size=86>女术士</size></color></b>，她会为你排疑解难。\n每7天你有一次机会可以通过这里<b><color=white><size=86>更换苏丹卡</size></color></b>。"
		"STORY":
			return "<b><color=white><size=86>俺寻思</size></color></b>，将卡牌拖入其中，可以触发对这张卡牌的思考。"
		"DEADLINE":
			return "你的<b><color=white><size=86>声望</size></color></b>，会影响事件的触发。"
		"HANDCARD":
			return "你可以支配的卡牌都会显示在这里。"
		"MENU":
			return "如果处刑倒计时<b><color=white><size=86>归0</size></color></b>，你的手牌区还持有苏丹卡的话，你就会被苏丹<b><color=white><size=86>处决</size></color></b>，游戏就会结束！"
		"NEXT_DAY":
			return "点击下一天推进游戏的时间。"
		"ONE_T":
			return "整理收集你的成就。"
		"INFO":
			return "今日所发生的事件通知。"
		"BAG":
			return "切换和使用卡牌栏位。"
		"GOLD":
			return "在检定时消耗一枚金骰子可以增加一点成功。"
		"BACK":
			return "次数足够时你可以随时选择回到<b><color=white><size=86>上一天</size></color></b>。"
	return ""


func close_view() -> void:
	for child in get_children():
		child.queue_free()
