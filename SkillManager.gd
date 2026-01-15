# File: res://scripts/SkillManager.gd
# Autoload as: Skills
extends Node
class_name SkillManager

var skills: Dictionary = {}

func _ready() -> void:
	if get_tree().root.has_node("State"):
		State.save_loaded.connect(_on_save_loaded)

func _on_save_loaded() -> void:
	_load_from_state()

func _load_from_state() -> void:
	if State.data.is_empty():
		return
	if not State.data.has("skills") or typeof(State.data["skills"]) != TYPE_DICTIONARY:
		State.data["skills"] = {}
	skills = State.data["skills"]
	_ensure_defaults()

func _ensure_defaults() -> void:
	var base_skills: Array[String] = ["combat"]
	for skill_id in Reg.SKILLS:
		base_skills.append(skill_id)
	for skill_id in base_skills:
		if not skills.has(skill_id):
			skills[skill_id] = {"level": 1, "xp": 0}

func _commit() -> void:
	if State.data.is_empty():
		return
	State.data["skills"] = skills
	State.write_now()

func add_xp(skill_id: String, amount: int) -> void:
	if amount <= 0:
		return
	if not skills.has(skill_id):
		skills[skill_id] = {"level": 1, "xp": 0}
	var entry: Dictionary = skills[skill_id]
	entry["xp"] = int(entry.get("xp", 0)) + amount
	var level := int(entry.get("level", 1))
	while entry["xp"] >= _xp_to_next_level(level):
		entry["xp"] = int(entry["xp"]) - _xp_to_next_level(level)
		level += 1
	entry["level"] = level
	skills[skill_id] = entry
	_commit()

func get_level(skill_id: String) -> int:
	if not skills.has(skill_id):
		return 1
	return int(skills[skill_id].get("level", 1))

func get_xp(skill_id: String) -> int:
	if not skills.has(skill_id):
		return 0
	return int(skills[skill_id].get("xp", 0))

func all_skills() -> Dictionary:
	return skills.duplicate()

func _xp_to_next_level(level: int) -> int:
	return 100 + (level - 1) * 50
