# File: res://scripts/SaveManager.gd
extends Node
class_name SaveManager

const SAVE_DIR: String = "res://saves"
const FILE_EXT: String = ".json"

static func ensure_save_dir() -> void:
	print('making dir')
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

static func list_save_files() -> Array[String]:
	ensure_save_dir()
	var out: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out

	dir.list_dir_begin()
	while true:
		var n = dir.get_next()
		if n == "":
			break
		if dir.current_is_dir():
			continue
		if n.to_lower().ends_with(FILE_EXT):
			out.append(n)
	dir.list_dir_end()

	out.sort()
	return out

static func save_path(file_name: String) -> String:
	return SAVE_DIR.path_join(file_name)

static func normalize_file_name(file_name: String) -> String:
	var n := file_name.strip_edges()
	if n == "":
		n = "save_1" + FILE_EXT
	if not n.to_lower().ends_with(FILE_EXT):
		n += FILE_EXT
	return n

static func new_save_data() -> Dictionary:
	# Add whatever you want later. Keep it stable.
	return {
		"version": 1,
		"created_unix": Time.get_unix_time_from_system(),
		"updated_unix": Time.get_unix_time_from_system(),
		"flags": {
			"tutorial_complete": false
		},
		"player": {
			"hub_spawn_id": "default"
		},
		"battle": {
			"active": false,
			"auto_repeat": true,
			"dungeon_id": "",
			"party": {},
			"enemy": {},
			"wins": 0,
			"losses": 0,
			"last_tick_unix": Time.get_unix_time_from_system()
		}
	}

static func load_save(file_name: String) -> Dictionary:
	ensure_save_dir()
	var n := normalize_file_name(file_name)
	var path := save_path(n)

	if not FileAccess.file_exists(path):
		return {}

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}

	var txt := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed as Dictionary

static func write_save(file_name: String, data: Dictionary) -> bool:
	ensure_save_dir()
	var n := normalize_file_name(file_name)
	var path := save_path(n)

	data["updated_unix"] = Time.get_unix_time_from_system()

	var txt := JSON.stringify(data, "\t")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false

	f.store_string(txt)
	f.close()
	return true

static func has_tutorial_complete(data: Dictionary) -> bool:
	if not data.has("flags"):
		return false
	var flags = data["flags"]
	if typeof(flags) != TYPE_DICTIONARY:
		return false
	if not flags.has("tutorial_complete"):
		return false
	return bool(flags["tutorial_complete"])

static func set_tutorial_complete(data: Dictionary, value: bool) -> void:
	if not data.has("flags") or typeof(data["flags"]) != TYPE_DICTIONARY:
		data["flags"] = {}
	data["flags"]["tutorial_complete"] = value
