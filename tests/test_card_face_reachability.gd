extends GutTest

## Card face reachability: which cards have original art, and what the clone
## actually renders for the rest.
## [SRC: CardExtensions.GetPic 0x3803b0 / CardRender.InitImage 0x5390f0 for the
##       art lookup; Texture2D/card_type_{char,item,sudan}.png for the no-art
##       fallback; materials/card/{char,item,sudan}/{stone,copper,silver,gold}.mat
##       _MainTex for the rarity frame.]

const CardWidget = preload("res://ui/card_widget.gd")
const SOURCE_ART := "res://assets/original/"
const UI_ART := "res://assets/original/ui/"

const RARITY_FRAMES := ["card.png", "card_0.png", "card_1.png", "card_2.png", "card_3.png", "card_4.png"]
const TYPE_ICONS := ["card_type_char.png", "card_type_item.png", "card_type_sudan.png"]


var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_every_rarity_frame_texture_exists() -> void:
	for frame in RARITY_FRAMES:
		assert_true(ResourceLoader.exists(UI_ART + frame),
			"rarity frame %s is required by every card" % frame)


func test_every_type_icon_exists() -> void:
	for icon in TYPE_ICONS:
		assert_true(ResourceLoader.exists(UI_ART + icon),
			"no-art fallback icon %s must exist" % icon)


func test_every_card_has_a_renderable_surface() -> void:
	# A card is renderable when EITHER its original art exists OR the rarity
	# frame does. The frame set is complete, so this can only fail if a frame
	# asset disappears.
	var no_art := 0
	var no_surface: Array = []
	for card_id in db.cards:
		var card: Dictionary = db.cards[card_id]
		var resource = card.get("resource", "")
		if resource is Array:
			resource = resource[0] if not resource.is_empty() else ""
		var art_ok := not str(resource).is_empty() and ResourceLoader.exists(SOURCE_ART + str(resource) + ".png")
		if art_ok:
			continue
		no_art += 1
		var kind := str(card.get("type", "item"))
		if not ResourceLoader.exists(UI_ART + "card_type_%s.png" % kind):
			no_surface.append(int(card_id))
	assert_gt(no_art, 0, "the corpus really does ship cards without extracted art")
	assert_eq(no_surface, [],
		"every art-less card falls back to a type icon that exists")


func test_type_icon_covers_all_configured_card_types() -> void:
	var kinds: Dictionary = {}
	for card_id in db.cards:
		kinds[str(db.cards[card_id].get("type", ""))] = true
	assert_eq(kinds.keys().size(), 3, "the config uses exactly three card types")
	for kind in kinds:
		assert_true(ResourceLoader.exists(UI_ART + "card_type_%s.png" % kind),
			"card_type_%s.png covers the configured type" % kind)


func test_paper_chrome_style_branch_is_unreachable_for_configured_cards() -> void:
	# `_style_for_card` returns a transparent style whenever the original art OR
	# the rarity frame resolves, and the frame always resolves, so the
	# paper-chrome branch is a guard rather than a live path. This pins that
	# conclusion so it cannot silently become live without a failing test.
	var widget := CardWidget.new()
	add_child_autofree(widget)
	widget._card = {"id": 2000001, "type": "char", "rare": 3, "resource": "cards/2000001"}
	var styled: StyleBoxFlat = widget._style_for_card()
	assert_eq(styled.bg_color.a, 0.0, "an art-bearing card frames nothing")
	widget._card = {"id": 2000002, "type": "char", "rare": 1, "resource": "cards/2000002"}
	var frameless: StyleBoxFlat = widget._style_for_card()
	assert_eq(frameless.bg_color.a, 0.0,
		"an art-less card still gets the rarity frame, so no paper chrome is drawn")
	assert_not_null(widget._rarity_frame_texture(), "the frame lookup is what keeps it transparent")
