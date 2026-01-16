extends Control

@onready var back_button = get_node_or_null("UI/BackButton")
@onready var piles_grid = get_node_or_null("UI/Content/PilesGrid")
@onready var selected_label = get_node_or_null("UI/Content/Details/SelectedLabel")
@onready var seed_option = get_node_or_null("UI/Content/Details/SeedRow/SeedOption")
@onready var dig_button = get_node_or_null("UI/Content/Details/ActionsRow/DigButton")
@onready var plant_button = get_node_or_null("UI/Content/Details/ActionsRow/PlantButton")
@onready var water_button = get_node_or_null("UI/Content/Details/ActionsRow/WaterButton")
@onready var fertilize_button = get_node_or_null("UI/Content/Details/ActionsRow/FertilizeButton")
@onready var harvest_button = get_node_or_null("UI/Content/Details/ActionsRow/HarvestButton")
@onready var upgrade_button = get_node_or_null("UI/Content/Details/ActionsRow/UpgradeButton")
@onready var status_label = get_node_or_null("UI/Content/Details/StatusLabel")

var selected_index = -1

func _ready() -> void:
	if back_button == null or piles_grid == null:
		push_warning("FarmScreen missing UI nodes.")
		return
	back_button.pressed.connect(_go_back)
	if dig_button != null:
		dig_button.pressed.connect(_dig_selected)
	if plant_button != null:
		plant_button.pressed.connect(_plant_selected)
	if water_button != null:
		water_button.pressed.connect(_water_selected)
	if fertilize_button != null:
		fertilize_button.pressed.connect(_fertilize_selected)
	if harvest_button != null:
		harvest_button.pressed.connect(_harvest_selected)
	if upgrade_button != null:
		upgrade_button.pressed.connect(_upgrade_selected)
	_refresh()

func _go_back() -> void:
	Router.goto_hub()

func _refresh() -> void:
	_refresh_piles()
	_refresh_seed_options()
	_refresh_details()

func _refresh_piles() -> void:
	for child in piles_grid.get_children():
		child.queue_free()
	var piles = Farm.get_piles()
	for i in range(piles.size()):
		var pile = piles[i]
		var button = Button.new()
		button.text = _pile_label(pile)
		button.pressed.connect(_on_pile_pressed.bind(i))
		piles_grid.add_child(button)

func _pile_label(pile: Dictionary) -> String:
	var pile_type = str(pile.get("type", "dirt")).capitalize()
	var level = int(pile.get("level", 1))
	var seed = str(pile.get("seed", ""))
	var growth = float(pile.get("growth", 0.0))
	if seed != "":
		return "%s Lv %d\nSeeded %.0f%%" % [pile_type, level, growth]
	return "%s Lv %d\nDig" % [pile_type, level]

func _refresh_seed_options() -> void:
	if seed_option == null:
		return
	seed_option.clear()
	seed_option.add_item("Select seed")
	seed_option.set_item_metadata(0, "")
	var items = Inventory.list_items()
	for entry in items:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item_id = str(entry.get("id", ""))
		if not item_id.begins_with("seed_"):
			continue
		var name = str(entry.get("name", item_id))
		seed_option.add_item(name)
		seed_option.set_item_metadata(seed_option.item_count - 1, item_id)

func _refresh_details() -> void:
	if selected_label == null:
		return
	var piles = Farm.get_piles()
	if selected_index < 0 or selected_index >= piles.size():
		selected_label.text = "Select a pile"
		return
	var pile = piles[selected_index]
	var seed = str(pile.get("seed", ""))
	var growth = float(pile.get("growth", 0.0))
	var watered = bool(pile.get("watered", false))
	var fertilized = bool(pile.get("fertilized", false))
	selected_label.text = "Pile: %s Lv %d\nSeed: %s\nGrowth: %.0f%%\nWatered: %s  Fertilized: %s" % [
		str(pile.get("type", "dirt")).capitalize(),
		int(pile.get("level", 1)),
		(seed if seed != "" else "None"),
		growth,
		str(watered),
		str(fertilized)
	]

func _on_pile_pressed(index: int) -> void:
	selected_index = index
	_refresh_details()

func _selected_seed_id() -> String:
	if seed_option == null:
		return ""
	var idx = seed_option.get_selected_id()
	var meta = seed_option.get_item_metadata(idx)
	if meta == null:
		return ""
	return str(meta)

func _dig_selected() -> void:
	if selected_index < 0:
		return
	var drops = Farm.dig_pile(selected_index)
	_refresh_piles()
	_refresh_details()
	_refresh_seed_options()
	_set_status(_drops_text(drops, "Dug pile!"))

func _plant_selected() -> void:
	if selected_index < 0:
		return
	var seed_id = _selected_seed_id()
	var ok = Farm.plant_seed(selected_index, seed_id)
	_refresh_piles()
	_refresh_details()
	_refresh_seed_options()
	_set_status("Planted." if ok else "Unable to plant.")

func _water_selected() -> void:
	if selected_index < 0:
		return
	var ok = Farm.water_pile(selected_index)
	_refresh_details()
	_set_status("Watered." if ok else "Unable to water.")

func _fertilize_selected() -> void:
	if selected_index < 0:
		return
	var ok = Farm.fertilize_pile(selected_index)
	_refresh_details()
	_set_status("Fertilized." if ok else "Unable to fertilize.")

func _harvest_selected() -> void:
	if selected_index < 0:
		return
	var drops = Farm.harvest_pile(selected_index)
	_refresh_piles()
	_refresh_details()
	_refresh_seed_options()
	_set_status(_drops_text(drops, "Harvested!"))

func _upgrade_selected() -> void:
	if selected_index < 0:
		return
	var ok = Farm.upgrade_pile(selected_index)
	_refresh_piles()
	_refresh_details()
	_set_status("Upgraded." if ok else "Max level.")

func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func _drops_text(drops: Array, fallback: String) -> String:
	if drops.is_empty():
		return fallback
	var parts = []
	for drop in drops:
		if typeof(drop) != TYPE_DICTIONARY:
			continue
		parts.append("%s x%d" % [str(drop.get("name", "Item")), int(drop.get("qty", 0))])
	if parts.is_empty():
		return fallback
	return "Drops: %s" % ", ".join(parts)
