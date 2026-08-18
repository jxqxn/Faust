extends SceneTree

## Unity UI layout manifest exporter — the "judge" for UI 位置/缩放 1:1 对拍.
## Parses AssetRipper YAML (scenes + prefabs) from the corpus and emits, per
## file, the full RectTransform truth table (anchors / anchoredPosition /
## sizeDelta / pivot / scale / rotation), canvas scaler settings, sprite
## references resolved to corpus paths, and geometry-relevant prefab-instance
## modifications. Output: docs/ui_layout/<name>.json + .md.
##
## Usage:
##   godot --headless --script tools/export_ui_layout.gd -- \
##     --input Resources/prefab/StartPanel.prefab [--input Scenes/StartScene.unity]
##     [--out docs/ui_layout] [--filter <substring>]
##
## Corpus is read-only; nothing under _unpack is ever modified.

const CORPUS_ASSETS := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/unity_export/ExportedProject/Assets"

# Well-known uGUI script guids (naming hints only — geometry does not depend on these).
const SCRIPT_GUID_NAMES := {
	"4e29b1a8efbd4b44bb3f3716e73f0727": "Button",
	"f70555f144d8491a825f0804e09b63a7": "Image",
	"5f7201a12d95ffc409449d95f23cf332": "Text",
	"f4688fdb7df04437aeb418b961361dc5": "TextMeshProUGUI",
	"e197570a3353d244e897db5fbfacc2ab": "Outline",
}

const GEOMETRY_PATHS := [
	"m_AnchoredPosition.x", "m_AnchoredPosition.y",
	"m_SizeDelta.x", "m_SizeDelta.y",
	"m_AnchorMin.x", "m_AnchorMin.y", "m_AnchorMax.x", "m_AnchorMax.y",
	"m_LocalScale.x", "m_LocalScale.y",
	"m_LocalPosition.x", "m_LocalPosition.y",
]

var _re_file_id: RegEx
var _re_vec2: RegEx
var _re_rot: RegEx
var _re_guid: RegEx
var _re_header: RegEx
var _re_stripped: RegEx
var _guid_to_path: Dictionary = {}
var _prefab_by_guid: Dictionary = {}

# per-document parse state (member vars: GDScript lambdas capture locals by value)
var _cur_class := ""
var _cur_fid := ""


func _init() -> void:
	_re_file_id = RegEx.create_from_string("fileID: (-?\\d+)")
	_re_vec2 = RegEx.create_from_string("x: (-?[0-9.eE+-]+), y: (-?[0-9.eE+-]+)")
	_re_rot = RegEx.create_from_string("x: ([-0-9.eE+]+), y: ([-0-9.eE+]+), z: ([-0-9.eE+]+), w: ([-0-9.eE+]+)")
	_re_guid = RegEx.create_from_string("guid: (\\w+)")
	_re_header = RegEx.create_from_string("^--- !u!(\\d+) &(-?\\d+)")
	_re_stripped = RegEx.create_from_string("^--- !u!(\\d+) &(-?\\d+) stripped")

	var args := OS.get_cmdline_user_args()
	var out_dir: String = _arg_value(args, "--out", "res://docs/ui_layout")
	var filter := _arg_value(args, "--filter", "")
	var inputs: Array = []
	for i in range(args.size()):
		if args[i] == "--input" and i + 1 < args.size():
			inputs.append(args[i + 1])
	if inputs.is_empty():
		inputs = ["Resources/prefab/StartPanel.prefab"]

	for rel: String in inputs:
		var full := "%s/%s" % [CORPUS_ASSETS, rel]
		if not FileAccess.file_exists(full):
			push_error("Missing corpus file: %s" % full)
			quit(1)
			return
		var doc := _export_file(rel, full, filter)
		var base_name := rel.get_file().get_basename()
		_write_json("%s/%s.json" % [out_dir, base_name], doc)
		_write_md("%s/%s.md" % [out_dir, base_name], doc)
		print("ui layout: %s -> %s/%s.{json,md} (%d nodes, %d instances)" % [
			rel, out_dir, base_name, doc["nodes"].size(), doc["prefab_instances"].size()])
	quit(0)


func _export_file(rel: String, full: String, filter: String) -> Dictionary:
	var parsed := _parse_yaml(full)
	var nodes: Array = []
	# emit in scene-tree DFS order — sibling order drives Unity layout groups
	var roots: Array = []
	for rect in parsed["rects"]:
		if rect["father"] == 0 and parsed["gameobjects"].has(rect["go"]):
			roots.append(rect["fid"])
	roots.sort()
	for root_fid in roots:
		_collect_subtree(parsed, root_fid, "", filter, nodes)

	var instances: Array = []
	for inst in parsed["instances"]:
		var mods: Dictionary = {}
		for m in inst["mods"]:
			var prop := str(m["propertyPath"])
			if GEOMETRY_PATHS.has(prop):
				mods[prop] = m["value"]
		instances.append({
			"source": _resolve_prefab_path(inst["source_guid"]),
			"source_guid": inst["source_guid"],
			"parent": _describe_target(parsed, inst["parent"]),
			"geometry_mods": mods,
		})

	return {
		"file": rel,
		"canvases": parsed["canvases"],
		"nodes": nodes,
		"prefab_instances": instances,
	}


func _collect_subtree(parsed: Dictionary, fid: int, prefix: String, filter: String, out: Array) -> void:
	var rect: Dictionary = parsed["rects_by_fid"][fid]
	var go: Dictionary = parsed["gameobjects"].get(rect["go"], {})
	var path := ("%s/%s" % [prefix, go.get("name", "?")]).substr(1 if prefix == "" else 0)
	if filter == "" or path.find(filter) != -1 or prefix == "":
		var entry: Dictionary = {
			"path": path,
			"anchor_min": rect["anchor_min"],
			"anchor_max": rect["anchor_max"],
			"anchored_position": rect["anchored_position"],
			"size_delta": rect["size_delta"],
			"pivot": rect["pivot"],
			"scale": rect["scale"],
			"rot_z": rect["rot_z"],
			"active": go.get("active", true),
			"components": go.get("components", []),
		}
		if go.has("sprite"):
			entry["sprite"] = _resolve_sprite(go["sprite"])
		if go.has("text"):
			entry["text"] = go["text"]
			entry["font_size"] = go.get("font_size", 0)
		if go.has("layout"):
			entry["layout"] = go["layout"]
		out.append(entry)
	for child_fid in rect["children"]:
		if parsed["rects_by_fid"].has(child_fid):
			_collect_subtree(parsed, child_fid, path, filter, out)


# --- YAML parsing (AssetRipper dialect, line-oriented) -----------------------

func _parse_yaml(full: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(full)
	var parsed := {
		"gameobjects": {},  # go_fid -> {name, active, sprite?, text?, font_size?, components}
		"rects": [],        # rect list (document order) with go/father/children + geometry
		"rects_by_fid": {},
		"canvases": [],
		"instances": [],
	}
	var ctx := {
		"raw_gos": {},
		"go_by_rect": {},
		"comp_hints": {},   # comp_fid -> signature-derived class hint
		"go_sprites": {},   # go_fid -> sprite guid
		"go_texts": {},
		"go_fonts": {},
		"go_layouts": {},
		"canvas_gos": [],
		"scalers_by_go": {},
	}

	var lines := text.split("\n")
	var body: Array = []
	_cur_class = ""
	_cur_fid = ""
	for line in lines:
		if line.begins_with("--- !u!"):
			_flush_doc(parsed, ctx, body)
			if _re_stripped.search(line) != null:
				_cur_class = ""
				continue  # stripped components carry no geometry of their own
			var hm := _re_header.search(line)
			if hm == null:
				_cur_class = ""
				continue
			_cur_class = hm.get_string(1)
			_cur_fid = hm.get_string(2)
			body = []
		elif _cur_class != "":
			body.append(line)
	_flush_doc(parsed, ctx, body)

	# second pass: GameObjects serialize before their components, so sprite/text
	# hints are only complete after every document has been staged.
	for go_fid in ctx["raw_gos"]:
		var raw: Dictionary = ctx["raw_gos"][go_fid]
		var labels: Array = []
		for comp_fid in raw["comps"]:
			labels.append(_component_label(str(ctx["comp_hints"].get(comp_fid, ""))))
		if labels.is_empty():
			labels = ["RectTransform"]
		var entry := {"name": raw["name"], "active": raw["active"], "components": labels}
		if ctx["go_sprites"].has(int(go_fid)):
			entry["sprite"] = ctx["go_sprites"][int(go_fid)]
		if ctx["go_texts"].has(int(go_fid)):
			entry["text"] = ctx["go_texts"][int(go_fid)]
			entry["font_size"] = ctx["go_fonts"].get(int(go_fid), 0)
		if ctx["go_layouts"].has(int(go_fid)):
			entry["layout"] = ctx["go_layouts"][int(go_fid)]
		parsed["gameobjects"][int(go_fid)] = entry

	# canvases: resolve their RectTransform fids via the go->rect map
	var canvases: Array = []
	for go_fid in ctx["canvas_gos"]:
		canvases.append({
			"name": parsed["gameobjects"].get(int(go_fid), {}).get("name", "?"),
			"rect": ctx["go_by_rect"].get(int(go_fid), 0),
			"scaler": ctx["scalers_by_go"].get(int(go_fid), {}),
		})
	parsed["canvases"] = canvases
	return parsed


func _flush_doc(parsed: Dictionary, ctx: Dictionary, body: Array) -> void:
	if _cur_class == "1":
		_flush_gameobject(parsed, ctx, _cur_fid, body)
	elif _cur_class == "224":
		_flush_recttransform(parsed, ctx, _cur_fid, body)
	elif _cur_class == "114":
		_flush_mono(ctx, _cur_fid, body)
	elif _cur_class == "223":
		_flush_canvas(ctx, _cur_fid, body)
	elif _cur_class == "1001":
		_flush_instance(parsed, _cur_fid, body)


func _flush_gameobject(parsed: Dictionary, ctx: Dictionary, fid: String, body: Array) -> void:
	var name := ""
	var active := true
	var comps: Array = []
	for line in body:
		var t: String = line.strip_edges()
		if t.begins_with("m_Name:"):
			name = t.substr(t.find(":") + 1).strip_edges()
		elif t.begins_with("m_IsActive:"):
			active = int(t.get_slice(":", 1).strip_edges()) != 0
		elif t.begins_with("- component:"):
			var fm := _re_file_id.search(t)
			if fm != null:
				comps.append(int(fm.get_string(1)))
	if name == "":
		return
	ctx["raw_gos"][int(fid)] = {"name": name, "active": active, "comps": comps}


func _component_label(hint: String) -> String:
	return hint if hint != "" else "?"


func _flush_recttransform(parsed: Dictionary, ctx: Dictionary, fid: String, body: Array) -> void:
	var go := 0
	var father := 0
	var children: Array = []
	var anchor_min := [0.5, 0.5]
	var anchor_max := [0.5, 0.5]
	var anchored := [0.0, 0.0]
	var size := [0.0, 0.0]
	var pivot := [0.5, 0.5]
	var scale := [1.0, 1.0]
	var rot_z := 0.0
	for line in body:
		var t: String = line.strip_edges()
		if t.begins_with("m_GameObject:"):
			var v := _re_file_id.search(t)
			if v != null:
				go = int(v.get_string(1))
		elif t.begins_with("m_Father:"):
			var v := _re_file_id.search(t)
			if v != null:
				father = int(v.get_string(1))
		elif t.begins_with("- {fileID:"):
			var v := _re_file_id.search(t)
			if v != null:
				children.append(int(v.get_string(1)))
		elif t.begins_with("m_AnchorMin:"):
			anchor_min = _vec2(t)
		elif t.begins_with("m_AnchorMax:"):
			anchor_max = _vec2(t)
		elif t.begins_with("m_AnchoredPosition:"):
			anchored = _vec2(t)
		elif t.begins_with("m_SizeDelta:"):
			size = _vec2(t)
		elif t.begins_with("m_Pivot:"):
			pivot = _vec2(t)
		elif t.begins_with("m_LocalScale:"):
			scale = _vec2(t)
		elif t.begins_with("m_LocalRotation:"):
			rot_z = _rot_z(t)
	var rect := {
		"fid": int(fid), "go": go, "father": father, "children": children,
		"anchor_min": anchor_min, "anchor_max": anchor_max,
		"anchored_position": anchored, "size_delta": size,
		"pivot": pivot, "scale": scale, "rot_z": rot_z,
	}
	parsed["rects"].append(rect)
	parsed["rects_by_fid"][int(fid)] = rect
	ctx["go_by_rect"][go] = int(fid)


func _flush_mono(ctx: Dictionary, fid: String, body: Array) -> void:
	# AssetRipper emits UnityEngine.UI classes as MonoBehaviours sharing one
	# assembly guid; identify them by field fingerprints instead of script ids.
	var go := 0
	var sprite_guid := ""
	var text_value := ""
	var font_size := 0
	var ref_res := [0, 0]
	var scale_mode := -1
	var screen_match := -1
	var match_wh := -1.0
	var has_interactable := false
	var has_spacing := false
	var spacing := 0.0
	var has_on_click := false
	var child_alignment := -1
	var pad_left := 0
	var pad_right := 0
	var pad_top := 0
	var pad_bottom := 0
	var child_control_w := 0
	var child_control_h := 0
	var force_expand_w := 0
	var force_expand_h := 0
	var reverse_arrange := 0
	var h_fit := -1
	var v_fit := -1
	var in_padding := false
	for line in body:
		var t: String = line.strip_edges()
		if t.begins_with("m_GameObject:"):
			var v := _re_file_id.search(t)
			if v != null:
				go = int(v.get_string(1))
		elif t.begins_with("m_Sprite:"):
			var g := _re_guid.search(t)
			if g != null:
				sprite_guid = g.get_string(1)
		elif t.begins_with("m_Text:"):
			text_value = t.substr(t.find(":") + 1).strip_edges()
		elif t.begins_with("m_text:"):
			if text_value == "":
				text_value = t.substr(t.find(":") + 1).strip_edges()
		elif t.begins_with("m_FontSize:"):
			font_size = int(t.get_slice(":", 1).strip_edges())
		elif t.begins_with("m_fontSize:"):
			if font_size == 0:
				font_size = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif t.begins_with("m_ReferenceResolution:"):
			ref_res = _vec2(t)
		elif t.begins_with("m_UiScaleMode:"):
			scale_mode = _int_or(t.get_slice(":", 1).strip_edges(), -1)
		elif t.begins_with("m_ScreenMatchMode:"):
			screen_match = _int_or(t.get_slice(":", 1).strip_edges(), -1)
		elif t.begins_with("m_MatchWidthOrHeight:"):
			match_wh = _float_or(t.get_slice(":", 1).strip_edges(), -1.0)
		elif t.begins_with("m_Interactable:"):
			has_interactable = true
		elif t.begins_with("m_Spacing:"):
			has_spacing = true
			spacing = _float_or(t.get_slice(":", 1).strip_edges(), 0.0)
		elif t.begins_with("m_OnClick:"):
			has_on_click = true
		elif t.begins_with("m_ChildAlignment:"):
			child_alignment = _int_or(t.get_slice(":", 1).strip_edges(), -1)
		elif t.begins_with("m_Padding:"):
			in_padding = true
		elif in_padding and t.begins_with("m_Left:"):
			pad_left = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif in_padding and t.begins_with("m_Right:"):
			pad_right = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif in_padding and t.begins_with("m_Top:"):
			pad_top = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif in_padding and t.begins_with("m_Bottom:"):
			pad_bottom = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif t.begins_with("m_ChildControlWidth:"):
			child_control_w = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif t.begins_with("m_ChildControlHeight:"):
			child_control_h = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif t.begins_with("m_ChildForceExpandWidth:"):
			force_expand_w = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif t.begins_with("m_ChildForceExpandHeight:"):
			force_expand_h = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif t.begins_with("m_ReverseArrangement:"):
			reverse_arrange = _int_or(t.get_slice(":", 1).strip_edges(), 0)
		elif t.begins_with("m_HorizontalFit:"):
			h_fit = _int_or(t.get_slice(":", 1).strip_edges(), -1)
		elif t.begins_with("m_VerticalFit:"):
			v_fit = _int_or(t.get_slice(":", 1).strip_edges(), -1)
		elif in_padding and not t.begins_with("m_"):
			in_padding = false
	var hint := "Mono"
	if sprite_guid != "":
		hint = "Image"
	elif text_value != "" or font_size > 0:
		hint = "Text"
	elif has_interactable and has_on_click:
		hint = "Button"
	elif child_alignment >= 0:
		hint = "LayoutGroup"
	elif h_fit >= 0:
		hint = "ContentSizeFitter"
	elif scale_mode >= 0:
		hint = "CanvasScaler"
	ctx["comp_hints"][int(fid)] = hint
	if go != 0:
		if sprite_guid != "":
			ctx["go_sprites"][go] = sprite_guid
		if text_value != "":
			ctx["go_texts"][go] = text_value
			ctx["go_fonts"][go] = font_size
		if child_alignment >= 0:
			ctx["go_layouts"][go] = {
				"kind": "layout_group",
				"child_alignment": child_alignment,
				"spacing": spacing,
				"padding": [pad_left, pad_right, pad_top, pad_bottom],
				"child_control": [child_control_w, child_control_h],
				"force_expand": [force_expand_w, force_expand_h],
				"reverse": reverse_arrange,
			}
		elif h_fit >= 0:
			ctx["go_layouts"][go] = {"kind": "content_size_fitter", "h_fit": h_fit, "v_fit": v_fit}
		if ref_res != [0, 0]:
			ctx["scalers_by_go"][go] = {
				"ui_scale_mode": scale_mode,
				"reference_resolution": ref_res,
				"screen_match_mode": screen_match,
				"match_width_or_height": match_wh,
			}


func _flush_canvas(ctx: Dictionary, fid: String, body: Array) -> void:
	for line in body:
		if line.strip_edges().begins_with("m_GameObject:"):
			var v := _re_file_id.search(line.strip_edges())
			if v != null:
				ctx["canvas_gos"].append(int(v.get_string(1)))
				return


func _flush_instance(parsed: Dictionary, fid: String, body: Array) -> void:
	var source_guid := ""
	var parent := 0
	var mods: Array = []
	var cur_guid := ""
	var cur_file := ""
	var cur_prop := ""
	for line in body:
		var t: String = line.strip_edges()
		if t.begins_with("m_SourcePrefab:"):
			var g := _re_guid.search(t)
			if g != null:
				source_guid = g.get_string(1)
		elif t.begins_with("m_TransformParent:"):
			var v := _re_file_id.search(t)
			if v != null:
				parent = int(v.get_string(1))
		elif t.begins_with("- target:"):
			var g := _re_guid.search(t)
			var f := _re_file_id.search(t)
			cur_guid = g.get_string(1) if g != null else ""
			cur_file = f.get_string(1) if f != null else ""
			cur_prop = ""
		elif t.begins_with("propertyPath:"):
			cur_prop = t.get_slice(":", 1).strip_edges()
		elif t.begins_with("value:"):
			if cur_guid != "" and cur_prop != "":
				mods.append({
					"guid": cur_guid, "file_id": cur_file,
					"propertyPath": cur_prop,
					"value": t.substr(t.find(":") + 1).strip_edges(),
				})
	parsed["instances"].append({
		"fid": int(fid), "source_guid": source_guid,
		"parent": parent, "mods": mods,
	})


# --- helpers -----------------------------------------------------------------

func _vec2(t: String) -> Array:
	var m := _re_vec2.search(t)
	if m == null:
		return [0.0, 0.0]
	return [_float_or(m.get_string(1), 0.0), _float_or(m.get_string(2), 0.0)]


func _rot_z(t: String) -> float:
	var m := _re_rot.search(t)
	if m == null:
		return 0.0
	var z := _float_or(m.get_string(3), 0.0)
	var w := _float_or(m.get_string(4), 1.0)
	return 2.0 * atan2(z, w) * 180.0 / PI


func _float_or(s: String, fallback: float) -> float:
	if s.is_valid_float():
		return float(s)
	return fallback


func _int_or(s: String, fallback: int) -> int:
	if s.is_valid_int():
		return int(s)
	return fallback


func _node_path(parsed: Dictionary, fid: int) -> String:
	var names: Array = []
	var cursor := fid
	var guard := 0
	while cursor != 0 and parsed["rects_by_fid"].has(cursor) and guard < 64:
		var rect: Dictionary = parsed["rects_by_fid"][cursor]
		var go: Dictionary = parsed["gameobjects"].get(rect["go"], {})
		names.push_front(go.get("name", "?"))
		cursor = rect["father"]
		guard += 1
	if cursor != 0:
		return ""  # root chain broken (instance-stripped parent) — skip
	return "/".join(names)


func _describe_target(parsed: Dictionary, fid: int) -> String:
	if fid == 0:
		return "(scene root)"
	var path := _node_path(parsed, fid)
	return path if path != "" else "fid:%d" % fid


func _resolve_sprite(guid: String) -> String:
	if _guid_to_path.is_empty():
		_index_guids()
	return _guid_to_path.get(guid, "guid:%s" % guid)


func _resolve_prefab_path(guid: String) -> String:
	if _prefab_by_guid.is_empty():
		_index_guids()
	return _prefab_by_guid.get(guid, "guid:%s" % guid)


func _index_guids() -> void:
	_index_guids_dir(CORPUS_ASSETS)
	print("ui layout: indexed %d asset guids (%d prefabs)" % [_guid_to_path.size(), _prefab_by_guid.size()])


func _index_guids_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := "%s/%s" % [dir_path, name]
		if dir.current_is_dir():
			if not name.begins_with("."):
				_index_guids_dir(full)
		elif name.ends_with(".meta"):
			var guid := _read_guid(full)
			if guid != "":
				_guid_to_path[guid] = full.substr(0, full.length() - 5)
				if full.ends_with(".prefab.meta"):
					_prefab_by_guid[guid] = full.substr(0, full.length() - 5)
		name = dir.get_next()
	dir.list_dir_end()


func _read_guid(meta_path: String) -> String:
	var f := FileAccess.open(meta_path, FileAccess.READ)
	if f == null:
		return ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("guid:"):
			f.close()
			return line.get_slice(":", 1).strip_edges()
	f.close()
	return ""


# --- output ------------------------------------------------------------------

func _write_json(path: String, doc: Dictionary) -> void:
	_ensure_dir(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s" % path)
		return
	f.store_string(JSON.stringify(doc, "  ", true))
	f.close()


func _write_md(path: String, doc: Dictionary) -> void:
	var lines: Array = []
	lines.append("# UI layout manifest: %s" % doc["file"])
	lines.append("")
	lines.append("Corpus truth table (RectTransform, authored values). Regenerate with `tools/export_ui_layout.gd`.")
	lines.append("")
	if not doc["canvases"].is_empty():
		lines.append("## Canvases")
		lines.append("")
		lines.append("| name | scaler |")
		lines.append("| --- | --- |")
		for c in doc["canvases"]:
			lines.append("| %s | %s |" % [c["name"], _fmt_scaler(c["scaler"])])
		lines.append("")
	lines.append("## Nodes")
	lines.append("")
	lines.append("| path | anchors | pos | size | pivot | scale | rotZ | extras |")
	lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
	for n in doc["nodes"]:
		var extras: Array = []
		if n.has("sprite"):
			var sp := str(n["sprite"]).replace(CORPUS_ASSETS + "/", "")
			extras.append("sprite=" + sp)
		if n.has("text"):
			var t := str(n["text"])
			if t.length() > 24:
				t = t.substr(0, 24) + "…"
			extras.append("text=\"%s\"" % t.replace("|", "\\|"))
			if int(n.get("font_size", 0)) > 0:
				extras.append("fs=%d" % int(n["font_size"]))
		if n.has("layout"):
			var lay: Dictionary = n["layout"]
			if str(lay["kind"]) == "layout_group":
				extras.append("layout(align=%d spacing=%.1f pad=%s cc=%d/%d fe=%d/%d rev=%d)" % [
					lay["child_alignment"], lay["spacing"], str(lay["padding"]),
					lay["child_control"][0], lay["child_control"][1],
					lay["force_expand"][0], lay["force_expand"][1], lay["reverse"]])
			else:
				extras.append("fitter(h=%d v=%d)" % [lay["h_fit"], lay["v_fit"]])
		lines.append("| %s | %s | %s | %s | %s | %s | %.1f | %s |" % [
			str(n["path"]).replace("|", "\\|"),
			_fmt_vec(n["anchor_min"]) + "–" + _fmt_vec(n["anchor_max"]),
			_fmt_vec(n["anchored_position"]),
			_fmt_vec(n["size_delta"]),
			_fmt_vec(n["pivot"]),
			_fmt_vec(n["scale"]),
			n["rot_z"],
			" ".join(PackedStringArray(extras)),
		])
	if not doc["prefab_instances"].is_empty():
		lines.append("")
		lines.append("## Prefab instances (geometry mods only)")
		lines.append("")
		for inst in doc["prefab_instances"]:
			var src := str(inst["source"]).replace(CORPUS_ASSETS + "/", "")
			lines.append("- **%s** parent=%s mods=%s" % [src, inst["parent"], _fmt_mods(inst["geometry_mods"])])
	_ensure_dir(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s" % path)
		return
	f.store_string("\n".join(lines) + "\n")
	f.close()


func _fmt_vec(v: Array) -> String:
	return "(%.2f, %.2f)" % [float(v[0]), float(v[1])]


func _fmt_scaler(s: Dictionary) -> String:
	if s.is_empty():
		return "constant-pixel-size"
	return "ref=%s mode=%s screenMatch=%s matchW/H=%s" % [
		_fmt_vec(s["reference_resolution"]), s["ui_scale_mode"],
		s["screen_match_mode"], s["match_width_or_height"]]


func _fmt_mods(m: Dictionary) -> String:
	if m.is_empty():
		return "—"
	var parts: Array = []
	for key in m:
		parts.append("%s=%s" % [key, str(m[key])])
	return ", ".join(PackedStringArray(parts))


func _ensure_dir(dir_path: String) -> void:
	if dir_path == "" or dir_path.begins_with("res://"):
		return  # inside the project — git-tracked dirs already exist or use mkdir manually
	var abs := ProjectSettings.globalize_path(dir_path)
	if not DirAccess.dir_exists_absolute(abs):
		DirAccess.make_dir_recursive_absolute(abs)


func _arg_value(args: Array, flag: String, fallback: String) -> String:
	for i in range(args.size()):
		if args[i] == flag and i + 1 < args.size():
			return args[i + 1]
	return fallback
