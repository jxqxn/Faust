extends TextureRect

signal source_event(function_name: String)

## Sprite keys and timing are read from the unchanged Unity AnimationClips.
## [SRC: Resources/anims/ithink/{Idle,Open,Close,Thinking}.anim;
## ThinkController.OnPointerEnter 0x5c3330 / OnPointerExit 0x5c3440.]
const ASSETS := "res://assets/original/ithink/"
var clip_name := ""
var elapsed := 0.0
var _clips: Dictionary = {}
var _textures: Dictionary = {}
var _frame := -1
var _event_index := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	play("Idle")

func play(clip: String) -> void:
	if clip_name == clip:
		return
	if not _clips.has(clip):
		var source := FileAccess.get_file_as_string(ASSETS + clip + ".anim")
		var pattern := RegEx.new()
		pattern.compile("- time: ([0-9.]+)\\s+value: \\{fileID: 21300000, guid: ([a-f0-9]+)")
		var keys: Array = []
		for match in pattern.search_all(source):
			keys.append([float(match.get_string(1)), match.get_string(2)])
		pattern.compile("m_StopTime: ([0-9.]+)")
		var stop := pattern.search(source)
		assert(stop != null, "Animation has no stop time: " + clip)
		var events: Array = []
		pattern.compile("- time: ([0-9.]+)\\s+functionName: ([A-Za-z0-9_]+)")
		for event in pattern.search_all(source):
			events.append([float(event.get_string(1)), event.get_string(2)])
		_clips[clip] = {"keys": keys, "length": float(stop.get_string(1)), "loop": source.contains("m_LoopTime: 1"), "events": events}
	clip_name = clip
	elapsed = 0.0
	_frame = -1
	_event_index = 0
	advance(0)

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if clip_name.is_empty():
		return
	var clip: Dictionary = _clips[clip_name]
	elapsed += delta
	var time := fmod(elapsed, float(clip.length)) if clip.loop else elapsed
	var index := 0
	for i in clip.keys.size():
		if float(clip.keys[i][0]) <= time:
			index = i
	if not clip.keys.is_empty() and index != _frame:
		_frame = index
		var guid: String = clip.keys[index][1]
		if not _textures.has(guid):
			_textures[guid] = load(ASSETS + guid + ".png")
		texture = _textures[guid]
	while _event_index < clip.events.size() and float(clip.events[_event_index][0]) <= elapsed:
		var name: String = clip.events[_event_index][1]
		_event_index += 1
		source_event.emit(name)
	if clip_name == "Close" and elapsed >= float(clip.length):
		play("Idle")
