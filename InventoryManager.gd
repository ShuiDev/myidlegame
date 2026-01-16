# File: res://scripts/InventoryManager.gd
# Autoload as: Inventory
extends Node
class_name InventoryManager

var items: Array = []

func _ready() -> void:
	if get_tree().root.has_node("State"):
		State.save_loaded.connect(_on_save_loaded)

func _on_save_loaded() -> void:
	_load_from_state()

func _load_from_state() -> void:
	if State.data.is_empty():
		return
	if not State.data.has("inventory") or typeof(State.data["inventory"]) != TYPE_ARRAY:
		State.data["inventory"] = []
	items = State.data["inventory"]

func _commit() -> void:
	if State.data.is_empty():
		return
	State.data["inventory"] = items
	State.write_now()

func add_item(item_id: String, item_name: String, amount: int = 1) -> void:
	if item_id.strip_edges() == "" or amount <= 0:
		return
	for entry in items:
		if typeof(entry) == TYPE_DICTIONARY and entry.get("id", "") == item_id:
			entry["qty"] = int(entry.get("qty", 0)) + amount
			_commit()
			return
	items.append({"id": item_id, "name": item_name, "qty": amount})
	_commit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id.strip_edges() == "" or amount <= 0:
		return false
	for i in range(items.size()):
		var entry = items[i]
		if typeof(entry) == TYPE_DICTIONARY and entry.get("id", "") == item_id:
			var qty=int(entry.get("qty", 0))
			if qty < amount:
				return false
			qty -= amount
			if qty <= 0:
				items.remove_at(i)
			else:
				entry["qty"] = qty
				items[i] = entry
			_commit()
			return true
	return false

func get_quantity(item_id: String) -> int:
	for entry in items:
		if typeof(entry) == TYPE_DICTIONARY and entry.get("id", "") == item_id:
			return int(entry.get("qty", 0))
	return 0

func list_items() -> Array:
	return items.duplicate()
