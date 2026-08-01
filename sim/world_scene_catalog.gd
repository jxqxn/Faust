## Data boundary for the lateral exploration presentation.
##
## Locations, exits, NPCs and short prototype conversations live here so the
## scene controller does not hard-code one backdrop. The legacy location and
## spawn IDs remain stable because player saves already persist them; only the
## non-canonical presentation has moved from a modern campus to a neutral
## hand-painted fantasy road.
class_name WorldSceneCatalog
extends RefCounted

const DEFAULT_LOCATION_ID := "school_rooftop"

const LOCATIONS := {
	"school_rooftop": {
		"title": "高地驿台 · 暮光",
		"background": "res://assets/original/thought_world/hilltop_waystation_stage.png",
		"foreground": "res://assets/original/thought_world/hilltop_waystation_foreground.png",
		"ambient": "highland",
		"world_width_ratio": 1.32,
		"ground_ratio": 0.82,
		"ground_curve": 0.018,
		"ground_slope": -0.012,
		"crop_anchor": 0.50,
		"spawn_points": {
			"default": 0.50,
			"from_riverbank": 0.12,
		},
		"exits": [
			{
				"id": "to_riverbank",
				"x_ratio": 0.055,
				"radius": 0.075,
				"target": "riverbank",
				"target_spawn": "from_rooftop",
				"label": "下行河岸古道",
				"direction": "←",
			},
		],
		"npcs": [
			{
				"id": "heroine",
				"name": "同行者",
				"x_ratio": 0.80,
				"radius": 0.14,
				"talk_x_ratio": 0.68,
				"sprite": "res://assets/original/thought_world/traveling_companion.png",
				"dialogue": "heroine.rooftop",
				"prompt": "与同行者交谈",
			},
		],
	},
	"riverbank": {
		"title": "河岸古道 · 暮光",
		"background": "res://assets/original/thought_world/river_road_stage.png",
		"foreground": "res://assets/original/thought_world/river_road_foreground.png",
		"ambient": "river",
		"world_width_ratio": 1.32,
		"ground_ratio": 0.82,
		"ground_curve": 0.014,
		"ground_slope": 0.008,
		"crop_anchor": 0.50,
		"spawn_points": {
			"default": 0.50,
			"from_rooftop": 0.14,
		},
		"exits": [
			{
				"id": "to_rooftop",
				"x_ratio": 0.055,
				"radius": 0.075,
				"target": "school_rooftop",
				"target_spawn": "from_riverbank",
				"label": "返回高地驿台",
				"direction": "←",
			},
		],
		"npcs": [],
	},
}

const DIALOGUES := {
	"heroine.rooftop": [
		{
			"speaker": "同行者",
			"actor_id": "heroine",
			"text": "你也还没有回去？",
		},
		{
			"speaker": "主角",
			"actor_id": "protagonist",
			"text": "只是想再待一会儿。",
		},
		{
			"speaker": "同行者",
			"actor_id": "heroine",
			"text": "那就一起看看天黑吧。",
		},
	],
}


static func location(location_id: String) -> Dictionary:
	var resolved_id := location_id if LOCATIONS.has(location_id) else DEFAULT_LOCATION_ID
	return LOCATIONS[resolved_id].duplicate(true)


static func dialogue(dialogue_id: String) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for raw_line in DIALOGUES.get(dialogue_id, []):
		if raw_line is Dictionary:
			lines.append(raw_line.duplicate(true))
	return lines


static func spawn_ratio(location_id: String, spawn_id: String = "default") -> float:
	var location_data := location(location_id)
	var spawn_points: Dictionary = location_data.get("spawn_points", {})
	return clampf(
		float(spawn_points.get(spawn_id, spawn_points.get("default", 0.5))),
		0.04,
		0.96
	)


static func validate_graph() -> PackedStringArray:
	var errors := PackedStringArray()
	for location_id in LOCATIONS:
		var location_data: Dictionary = LOCATIONS[location_id]
		if not ResourceLoader.exists(str(location_data.get("background", ""))):
			errors.append("%s 缺少背景资源" % location_id)
		if not ResourceLoader.exists(str(location_data.get("foreground", ""))):
			errors.append("%s 缺少前景遮挡资源" % location_id)
		if float(location_data.get("world_width_ratio", 1.0)) <= 1.0:
			errors.append("%s 缺少可供摄像机移动的横向舞台宽度" % location_id)
		var spawn_points: Dictionary = location_data.get("spawn_points", {})
		if not spawn_points.has("default"):
			errors.append("%s 缺少 default 出生点" % location_id)
		for exit_data in location_data.get("exits", []):
			if not (exit_data is Dictionary):
				errors.append("%s 含有无效出口" % location_id)
				continue
			var target := str(exit_data.get("target", ""))
			if not LOCATIONS.has(target):
				errors.append("%s 的出口指向不存在的地图 %s" % [location_id, target])
				continue
			var target_spawns: Dictionary = LOCATIONS[target].get("spawn_points", {})
			var target_spawn := str(exit_data.get("target_spawn", "default"))
			if not target_spawns.has(target_spawn):
				errors.append("%s 的出口指向不存在的出生点 %s" % [location_id, target_spawn])
		for npc_data in location_data.get("npcs", []):
			if not (npc_data is Dictionary):
				errors.append("%s 含有无效 NPC" % location_id)
				continue
			if not ResourceLoader.exists(str(npc_data.get("sprite", ""))):
				errors.append("%s 的 NPC %s 缺少立绘" % [location_id, npc_data.get("id", "")])
			if not DIALOGUES.has(str(npc_data.get("dialogue", ""))):
				errors.append("%s 的 NPC %s 缺少对白" % [location_id, npc_data.get("id", "")])
			var npc_x := float(npc_data.get("x_ratio", 0.5))
			var talk_x := float(npc_data.get("talk_x_ratio", npc_x))
			if talk_x < 0.04 or talk_x > 0.96:
				errors.append("%s 的 NPC %s 交谈站位越界" % [location_id, npc_data.get("id", "")])
			if absf(talk_x - npc_x) > float(npc_data.get("radius", 0.08)):
				errors.append("%s 的 NPC %s 无法从交谈站位触发交互" % [location_id, npc_data.get("id", "")])
	return errors
