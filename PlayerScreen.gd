extends Control

@onready var back_button: Button = get_node_or_null("UI/BackButton") as Button
@onready var inventory_list: ItemList = get_node_or_null("UI/InventoryColumn/Inv") as ItemList
@onready var equipment_list: ItemList = get_node_or_null("UI/EquipmentColumn/Equip") as ItemList
@onready var skills_list: ItemList = get_node_or_null("UI/SkillsColumn/Skills") as ItemList
@onready var creature_selector: OptionButton = get_node_or_null("UI/EquipmentColumn/CreatureSelectorRow/CreatureSelector") as OptionButton

var creature_ids: Array[String] = []
var selected_creature_id: String = ""

func _ready() -> void:
	if not _ensure_nodes():
		return
	back_button.pressed.connect(_go_back)
	creature_selector.item_selected.connect(_on_creature_selected)
	_refresh()

func _ensure_nodes() -> bool:
	var missing: Array[String] = []
	if back_button == null:
		missing.append("UI/BackButton")
	if inventory_list == null:
		missing.append("UI/InventoryColumn/Inv")
	if equipment_list == null:
		missing.append("UI/EquipmentColumn/Equip")
	if skills_list == null:
		missing.append("UI/SkillsColumn/Skills")
	if creature_selector == null:
		missing.append("UI/EquipmentColumn/CreatureSelectorRow/CreatureSelector")
	if missing.is_empty():
		return true
	push_warning("PlayerScreen missing nodes: %s" % ", ".join(missing))
	return false

func _go_back() -> void:
	Router.goto_hub()

func _refresh() -> void:
	_inventory_refresh()
	_creature_selector_refresh()
	_equipment_refresh()
	_skills_refresh()

func _inventory_refresh() -> void:
	inventory_list.clear()
	for entry in Inventory.list_items():
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var name := str(entry.get("name", entry.get("id", "Item")))
		var qty := int(entry.get("qty", 0))
		inventory_list.add_item("%s x%d" % [name, qty])

func _equipment_refresh() -> void:
	equipment_list.clear()
	if selected_creature_id == "":
		equipment_list.add_item("(no creature)")
		return
	for slot in Equipment.SLOTS:
		var item_id := Equipment.get_equipped(selected_creature_id, slot)
		var label := item_id if item_id != "" else "(empty)"
		equipment_list.add_item("%s: %s" % [slot.capitalize(), label])

func _creature_selector_refresh() -> void:
	creature_selector.clear()
	creature_ids.clear()
	var creatures := RanchManager.get_creature_objects()
	for creature in creatures:
		creature_ids.append(creature.id)
		var label := creature.name if creature.name != "" else creature.id
		creature_selector.add_item(label)
	if creature_ids.is_empty():
		selected_creature_id = ""
		return
	if not creature_ids.has(selected_creature_id):
		selected_creature_id = creature_ids[0]
	var selected_index := creature_ids.find(selected_creature_id)
	if selected_index >= 0:
		creature_selector.select(selected_index)

func _on_creature_selected(index: int) -> void:
	if index < 0 or index >= creature_ids.size():
		return
	selected_creature_id = creature_ids[index]
	_equipment_refresh()

func _skills_refresh() -> void:
	skills_list.clear()
	var skills := Skills.all_skills()
	var ids := skills.keys()
	ids.sort()
	for skill_id in ids:
		var entry = skills[skill_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var level := int(entry.get("level", 1))
		var xp := int(entry.get("xp", 0))
		skills_list.add_item("%s Lv %d (XP %d)" % [skill_id.capitalize(), level, xp])
