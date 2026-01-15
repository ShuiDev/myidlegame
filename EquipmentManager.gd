# File: res://scripts/EquipmentManager.gd
extends Node
class_name EquipmentManager

const SLOTS: Array[String] = ["weapon", "armor", "accessory"]

func equip_item(creature_id: String, slot: String, item_id: String) -> bool:
	if not SLOTS.has(slot):
		return false
	if item_id.strip_edges() == "":
		return false
	if Inventory.get_quantity(item_id) <= 0:
		return false
	var creature := RanchManager.get_creature(creature_id)
	if creature == null:
		return false
	var updated_equipment := creature.equipment.duplicate()
	updated_equipment[slot] = item_id
	creature.equipment = updated_equipment
	RanchManager.update_creature(creature)
	return true

func unequip_item(creature_id: String, slot: String) -> void:
	if not SLOTS.has(slot):
		return
	var creature := RanchManager.get_creature(creature_id)
	if creature == null:
		return
	var updated_equipment := creature.equipment.duplicate()
	updated_equipment[slot] = ""
	creature.equipment = updated_equipment
	RanchManager.update_creature(creature)

func get_equipped(creature_id: String, slot: String) -> String:
	if not SLOTS.has(slot):
		return ""
	var creature := RanchManager.get_creature(creature_id)
	if creature == null:
		return ""
	return str(creature.equipment.get(slot, ""))

func all_equipped(creature_id: String) -> Dictionary:
	var creature := RanchManager.get_creature(creature_id)
	if creature == null:
		return {}
	return creature.equipment.duplicate()
