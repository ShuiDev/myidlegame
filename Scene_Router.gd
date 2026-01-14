# File: res://scripts/SceneRouter.gd
# Autoload as: SceneRouter
# Expand router with ranch/smith/build scenes.
extends Node
class_name SceneRouter

const TITLE_SCENE_PATH: String = "res://scenes/TitleScreen.tscn"
const HUB_SCENE_PATH: String = "res://scenes/HubScreen.tscn"
const RANCH_SCENE_PATH: String = "res://scenes/RanchScreen.tscn"
const SMITH_SCENE_PATH: String = "res://scenes/SmithScreen.tscn"
const BUILD_SCENE_PATH: String = "res://scenes/BuildScreen.tscn"
const BATTLE_SCENE_PATH: String = "res://scenes/BattleScreen.tscn"

func goto_title() -> void:
	_change_to(TITLE_SCENE_PATH)

func goto_hub() -> void:
	_change_to(HUB_SCENE_PATH)

func goto_ranch() -> void:
	_change_to(RANCH_SCENE_PATH)

func goto_smith() -> void:
	_change_to(SMITH_SCENE_PATH)

func goto_build() -> void:
	_change_to(BUILD_SCENE_PATH)

func goto_battle() -> void:
	_change_to(BATTLE_SCENE_PATH)

func _change_to(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		push_error("[SceneRouter] Scene path missing/invalid: " + path)
		return
	call_deferred("_do_change", path)

func _do_change(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[SceneRouter] change_scene_to_file failed (%d) for %s" % [err, path])
