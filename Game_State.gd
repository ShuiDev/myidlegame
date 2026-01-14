# File: res://scripts/GameState.gd
extends Node
class_name GameState

var save_file: String = ""
var data: Dictionary = {}

signal save_loaded
signal save_written

func start_new(file_name: String) -> void:
	save_file = Save.normalize_file_name(file_name)
	data = SaveManager.new_save_data()
	SaveManager.write_save(save_file, data)
	save_loaded.emit()

func load_existing(file_name: String) -> bool:
	save_file = Save.normalize_file_name(file_name)
	var loaded := SaveManager.load_save(save_file)
	if loaded.is_empty():
		return false
	data = loaded
	# Ensure new fields exist if you add them later
	_ensure_defaults()
	save_loaded.emit()
	return true

func write_now() -> bool:
	if save_file == "":
		return false
	var ok := SaveManager.write_save(save_file, data)
	if ok:
		save_written.emit()
	return ok

func tutorial_complete() -> bool:
	return bool(data.get("flags", {}).get("tutorial_complete", false))

func mark_tutorial_complete() -> void:
	if not data.has("flags") or typeof(data["flags"]) != TYPE_DICTIONARY:
		data["flags"] = {}
	data["flags"]["tutorial_complete"] = true
	write_now()

func _ensure_defaults() -> void:
	# Add missing structures safely for old saves
	if not data.has("flags") or typeof(data["flags"]) != TYPE_DICTIONARY:
		data["flags"] = {}
	if not data["flags"].has("tutorial_complete"):
		data["flags"]["tutorial_complete"] = false

	if not data.has("ranch") or typeof(data["ranch"]) != TYPE_DICTIONARY:
		data["ranch"] = {}
	if not data["ranch"].has("creatures") or typeof(data["ranch"]["creatures"]) != TYPE_ARRAY:
		data["ranch"]["creatures"] = []

	if not data.has("battle") or typeof(data["battle"]) != TYPE_DICTIONARY:
		data["battle"] = {}
	var battle: Dictionary = data["battle"]
	if not battle.has("active"):
		battle["active"] = false
	if not battle.has("auto_repeat"):
		battle["auto_repeat"] = true
	if not battle.has("dungeon_id"):
		battle["dungeon_id"] = ""
	if not battle.has("party") or typeof(battle["party"]) != TYPE_DICTIONARY:
		battle["party"] = {}
	if not battle.has("enemy") or typeof(battle["enemy"]) != TYPE_DICTIONARY:
		battle["enemy"] = {}
	if not battle.has("wins"):
		battle["wins"] = 0
	if not battle.has("losses"):
		battle["losses"] = 0
	if not battle.has("last_tick_unix"):
		battle["last_tick_unix"] = Time.get_unix_time_from_system()
