# File: res://scripts/EquipmentManager.gd
# Autoload as: Equipment
extends Node
class_name EquipmentManager

const SLOTS: Array[String] = ["weapon", "armor", "accessory"]

var equipment: Dictionary = {}

func _ready() -> void:
	if get_tree().root.has_node("State"):
		State.save_loaded.connect(_on_save_loaded)

func _on_save_loaded() -> void:
	_load_from_state()

func _load_from_state() -> void:
	if State.data.is_empty():
		return
	if not State.data.has("equipment") or typeof(State.data["equipment"]) != TYPE_DICTIONARY:
		State.data["equipment"] = {}
	equipment = State.data["equipment"]
	for slot in SLOTS:
		if not equipment.has(slot):
			equipment[slot] = ""

func _commit() -> void:
	if State.data.is_empty():
		return
	State.data["equipment"] = equipment
	State.write_now()

func equip_item(slot: String, item_id: String) -> bool:
	if not SLOTS.has(slot):
		return false
	if item_id.strip_edges() == "":
		return false
	if Inventory.get_quantity(item_id) <= 0:
		return false
	equipment[slot] = item_id
	_commit()
	return true

func unequip_item(slot: String) -> void:
	if not SLOTS.has(slot):
		return
	equipment[slot] = ""
	_commit()

func get_equipped(slot: String) -> String:
	if not equipment.has(slot):
		return ""
	return str(equipment.get(slot, ""))

func all_equipped() -> Dictionary:
	return equipment.duplicate()
