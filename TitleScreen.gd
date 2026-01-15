# File: res://scripts/TitleScreen.gd
# Attach to your TitleScreen root Control node
extends Control

@export var default_new_save_name: String = "save_1"

@onready var new_game_button: Button = get_node_or_null("VBox/NewGameButton") as Button
@onready var load_game_button: Button = get_node_or_null("VBox/LoadGameButton") as Button
@onready var saves_list: ItemList = get_node_or_null("VBox/SavesList") as ItemList
@onready var status_label: Label = get_node_or_null("VBox/StatusLabel") as Label

func _ready() -> void:
	if not _ensure_nodes():
		return
	new_game_button.pressed.connect(_on_new_game)
	load_game_button.pressed.connect(_on_load_game)

	_refresh_saves()

func _ensure_nodes() -> bool:
	var missing: Array[String] = []
	if new_game_button == null:
		missing.append("VBox/NewGameButton")
	if load_game_button == null:
		missing.append("VBox/LoadGameButton")
	if saves_list == null:
		missing.append("VBox/SavesList")
	if status_label == null:
		missing.append("VBox/StatusLabel")
	if missing.is_empty():
		return true
	push_warning("TitleScreen missing nodes: %s" % ", ".join(missing))
	return false

func _refresh_saves() -> void:
	saves_list.clear()
	var files = Save.list_save_files()
	for f in files:
		saves_list.add_item(f)
	print(saves_list.item_count)

	if files.size() == 0:
		status_label.text = "No saves yet."
	else:
		status_label.text = "Select a save, then Load Game."

func _on_new_game() -> void:
	# If save_1 exists, auto-increment to save_2, save_3, ...
	print('test')
	var base := default_new_save_name
	var idx := 1
	var n = "%s_%d" % [base, idx]
	while FileAccess.file_exists(Save.save_path(Save.normalize_file_name(n))):
		idx += 1
		name = "%s_%d" % [base, idx]

	var gs := _require_game_state()
	if gs == null:
		return

	gs.start_new(name)
	_require_router().goto_hub()

func _on_load_game() -> void:
	var sel := saves_list.get_selected_items()
	if sel.size() == 0:
		status_label.text = "Pick a save first."
		return

	var file_name := saves_list.get_item_text(sel[0])

	var gs := _require_game_state()
	if gs == null:
		return

	var ok := gs.load_existing(file_name)
	if not ok:
		status_label.text = "Failed to load save."
		_refresh_saves()
		return

	_require_router().goto_hub()

func _require_game_state() -> State:
	var gs := get_tree().root.get_node_or_null("State")
	if gs == null:
		status_label.text = "Missing autoload: GameState"
		return null
	return gs as State

func _require_router() -> Router:
	var r := get_tree().root.get_node_or_null("Router")
	if r == null:
		status_label.text = "Missing autoload: SceneRouter"
		return null
	return r as Router
