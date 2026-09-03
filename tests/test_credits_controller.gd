extends GutTest

const CreditsControllerScript = preload("res://ui/credits_controller.gd")
const CreditsThanksScript = preload("res://ui/credits_page_thanks.gd")

var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_raw_credits_config_is_loaded_without_translation() -> void:
	assert_eq((db.credits.get("developers", {}) as Dictionary).size(), 19)
	assert_eq((db.credits.get("contributors", []) as Array).size(), 3)
	assert_eq((db.credits.get("thanks", []) as Array).size(), 12)
	var supporter_count := 0
	for item in db.credits.get("thanks", []):
		supporter_count += (item.get("members", []) as Array).size()
	assert_eq(supporter_count, 11006,
		"the runtime view must consume every member in the original credits.json")


func test_thanks_get_names_replays_source_utf16_page_boundaries() -> void:
	# [SRC: CreditsPageThanks.c GetNames @ RVA 0x3f8070]
	var thanks: Array = db.credits.get("thanks", [])
	var test_players: Array[String] = CreditsThanksScript.build_name_pages(thanks[2])
	assert_eq(test_players.size(), 3)
	assert_true(test_players[0].contains("AAA前排兜售双头龙·3M"))
	assert_true(test_players[0].contains("太阳鲸"))
	assert_false(test_players[0].contains("笑匠"),
		"笑匠 is the first member of the third source-derived page")
	assert_true(test_players[2].contains("笑匠"))
	assert_true(test_players[2].contains("艾米莉莉子"))

	var large_supporter_list: Array[String] = CreditsThanksScript.build_name_pages(thanks[4])
	assert_eq(large_supporter_list.size(), 39,
		"the first large crowdfunding record has 39 pages under the source algorithm")


func test_controller_replays_source_page_order_navigation_and_geometry() -> void:
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var credits = CreditsControllerScript.new()
	credits.setup(db)
	stage.add_child(credits)
	await wait_process_frames(2)

	assert_eq(credits._page_data.size(), 16,
		"developer + 3 contributor records + 12 thanks records")
	assert_eq(credits.data_index, 0)
	assert_true(credits._developer_page.visible)
	assert_true(credits._prev.disabled)
	assert_almost_eq(credits.get_node("Credits/Close").position, Vector2(3717.4, 45.6), Vector2(0.01, 0.01))
	assert_eq(credits.get_node("Credits/Close").size, Vector2(80, 82))
	assert_eq(credits.get_node("Credits/PageLeft").position, Vector2(1636, 1862))
	assert_eq(credits.get_node("Credits/PageRight").position, Vector2(2036, 1862))
	assert_eq(credits._developer_page.get_node("logo").position, Vector2(1430, 946))
	assert_almost_eq(credits._developer_page.get_node("TitleText").size.x, 420.01, 0.01)
	assert_almost_eq(credits._developer_page.get_node("Title").size.x, 828.01, 0.01,
		"full-stretch Title resolves to TitleText width plus the authored 408 sizeDelta")

	var xiaogu: Control = credits._developer_page.get_node("小古")
	assert_eq(xiaogu.position, Vector2(1738, 434))
	assert_eq(xiaogu.size, Vector2(272, 356))
	assert_eq(xiaogu.scale, Vector2(0.95, 0.95))
	assert_almost_eq(xiaogu.rotation_degrees, 9.616951, 0.0001)

	for expected_index in range(1, 7):
		credits.do_next()
		assert_eq(credits.data_index, expected_index)
	assert_eq(credits._thanks_page.page_position, 0)
	credits.do_next()
	assert_eq(credits.data_index, 6,
		"thanks internal navigation must run before advancing the outer CreditsNode list")
	assert_eq(credits._thanks_page.page_position, 1)
	credits.do_prev()
	assert_eq(credits.data_index, 6)
	assert_eq(credits._thanks_page.page_position, 0)
