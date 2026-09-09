## Native Screen API adapter. The helper owns temporary mode changes until
## this Godot process exits; its watcher restores the original desktop mode.
extends RefCounted

const SOURCE := "res://platform/windows/DisplayHost.cs"
var _executable := ""
var _active := false
static var _guard_pid := -1

func _prepare() -> String:
	if _executable != "":
		return ""
	if OS.get_name() != "Windows":
		return "当前平台尚未提供显示模式适配。"
	var code := FileAccess.get_file_as_string(SOURCE)
	if code.is_empty():
		return "缺少显示模式适配源文件。"
	var cache := OS.get_user_data_dir().path_join("display_host")
	DirAccess.make_dir_recursive_absolute(cache)
	var target := cache.path_join("DisplayHost-" + code.sha256_text().substr(0, 16) + ".exe")
	if not FileAccess.file_exists(target):
		var source_path := cache.path_join("DisplayHost.cs")
		var source_file := FileAccess.open(source_path, FileAccess.WRITE)
		if source_file == null:
			return "无法创建显示模式适配缓存。"
		source_file.store_string(code)
		source_file.close()
		var compiler := OS.get_environment("WINDIR").path_join("Microsoft.NET/Framework64/v4.0.30319/csc.exe")
		var output: Array = []
		# Framework csc treats forward-slash path segments as command options.
		var status := OS.execute(compiler, ["/nologo", "/target:exe", "/out:" + target.replace("/", "\\"), "/reference:System.Web.Extensions.dll", source_path.replace("/", "\\")], output, true, false)
		if status != 0:
			return "显示模式适配编译失败：" + str(output)
	_executable = target
	return ""

func _call(arguments: PackedStringArray) -> Dictionary:
	var error := _prepare()
	if error != "":
		return {"ok": false, "error": error}
	var output: Array = []
	var status := OS.execute(_executable, arguments, output, true, false)
	var result = JSON.parse_string("\n".join(output).strip_edges())
	if status != 0 or not result is Dictionary:
		return {"ok": false, "error": "显示模式调用失败：" + str(output)}
	return result

func _handle(window: Window) -> String:
	return str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, window.get_window_id()))

func query(window: Window) -> Dictionary:
	return _call(["query", _handle(window)])

func apply(window: Window, resolution: Vector2i) -> Dictionary:
	var error := _prepare()
	if error != "":
		return {"ok": false, "error": error}
	if _guard_pid <= 0 or not OS.is_process_running(_guard_pid):
		_guard_pid = OS.create_process(_executable, ["serve", str(OS.get_process_id())], false)
		if _guard_pid <= 0:
			return {"ok": false, "error": "无法启动显示模式恢复服务。"}
	var result := _call(["apply", str(OS.get_process_id()), _handle(window), str(resolution.x), str(resolution.y)])
	if bool(result.get("ok", false)):
		_active = true
	return result

func restore(window: Window) -> Dictionary:
	if not _active:
		return query(window)
	var result := _call(["restore", str(OS.get_process_id()), _handle(window)])
	if bool(result.get("ok", false)):
		_active = false
	return result
