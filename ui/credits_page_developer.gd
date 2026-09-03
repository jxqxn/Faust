## Original single developer page. The scene-authored member transforms are
## retained and filled by dictionary key from the raw CreditsNode.developers.
## [SRC: CreditsPageDeveloper.c @ Show (RVA 0x3f7dc0);
##       Resources/prefab/Credits.prefab; dump.cs:418172-418236]
class_name CreditsPageDeveloper
extends "res://ui/credits_page.gd"

const MemberView = preload("res://ui/credits_member.gd")

const MEMBER_LAYOUT := [
	["小古", "小古", Vector2(-46, 468), -9.616951],
	["木难", "木难", Vector2(278, 426), 6.463211],
	["阿铁", "阿铁", Vector2(578, 350), -11.770662],
	["小阳", "小阳", Vector2(864, 476), -5.989317],
	["面面", "面面", Vector2(928, 94), 12.059637],
	["家瑞", "崔家瑞", Vector2(1168, 320), 2.018372],
	["ZETA", "ZETA", Vector2(919, -295), 27.202093],
	["TXT", "TXT", Vector2(1219, -340), 15.899176],
	["思洁", "思洁", Vector2(682, -492), 9.802511],
	["咕噜", "咕噜", Vector2(394, -370), 2.322964],
	["韶韶", "韶韶", Vector2(134, -501), 12.149757],
	["米米", "米米", Vector2(-167, -572), -12.111596],
	["阿哞", "阿哞", Vector2(-423, -430), -7.124217],
	["熊猫老师", "熊猫老师", Vector2(-694, -373), -5.909627],
	["SNOW2", "SNOW2", Vector2(-942, -223), 0.513610],
	["雨虹", "雨虹", Vector2(-1181, 112), -8.256573],
	["跑了猫", "跑了猫", Vector2(-904, 418), 4.086205],
	["小熊猫", "小熊猫", Vector2(-625, 303), -9.397576],
	["汝月", "汝月", Vector2(-338, 466), -5.296742],
]

var _built := false


func show_data(data: Variant, pos: int) -> void:
	super.show_data(data, pos)
	if _built:
		return
	_built = true
	setup_page("开发组", "developer")
	add_child(texture_rect("logo", Rect2(1430, 946, 980, 268), "logo.png"))
	var developers := data as Dictionary
	for row in MEMBER_LAYOUT:
		var member_key := str(row[0])
		var member = developers.get(member_key, {}) as Dictionary
		var view = MemberView.new()
		view.setup(member_key, member, str(row[1]), row[2], Vector2(0.95, 0.95), float(row[3]))
		add_child(view)
