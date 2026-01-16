extends Control

@onready var back_button = get_node_or_null("UI/BackButton")
@onready var inventory_list = get_node_or_null("UI/Columns/InventoryColumn/InventoryList")
@onready var equipment_list = get_node_or_null("UI/Columns/EquipmentColumn/EquipmentList")
@onready var skills_list = get_node_or_null("UI/Columns/SkillsColumn/SkillsList")

func _ready() -> void:
	if back_button == null or inventory_list == null or equipment_list == null or skills_list == null:
		push_warning("PlayerScreen missing UI nodes.")
		return
	back_button.pressed.connect(_go_back)
	_refresh()

func _go_back() -> void:
	Router.goto_hub()

func _refresh() -> void:
	_inventory_refresh()
	_equipment_refresh()
	_skills_refresh()

func _inventory_refresh() -> void:
	if inventory_list == null:
		return
	inventory_list.clear()
	for entry in Inventory.list_items():
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var name=str(entry.get("name", entry.get("id", "Item")))
		var qty=int(entry.get("qty", 0))
		inventory_list.add_item("%s x%d" % [name, qty])

func _equipment_refresh() -> void:
	if equipment_list == null:
		return
	equipment_list.clear()
	for slot in Equipment.SLOTS:
		var item_id=Equipment.get_equipped(slot)
		var label=item_id if item_id != "" else "(empty)"
		equipment_list.add_item("%s: %s" % [slot.capitalize(), label])

func _skills_refresh() -> void:
	if skills_list == null:
		return
	skills_list.clear()
	var skills=Skills.all_skills()
	var ids=skills.keys()
	ids.sort()
	for skill_id in ids:
		var entry = skills[skill_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var level=int(entry.get("level", 1))
		var xp=int(entry.get("xp", 0))
		skills_list.add_item("%s Lv %d (XP %d)" % [skill_id.capitalize(), level, xp])
