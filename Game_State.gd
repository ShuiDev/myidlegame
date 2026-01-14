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
