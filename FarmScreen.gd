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
@onready var containers_grid = get_node_or_null("UI/Content/Containers/ContainersGrid")
@onready var container_selected_label = get_node_or_null("UI/Content/Containers/ContainerSelectedLabel")
@onready var craft_option = get_node_or_null("UI/Content/Containers/CraftRow/CraftOption")
@onready var craft_button = get_node_or_null("UI/Content/Containers/CraftRow/CraftButton")
@onready var place_option = get_node_or_null("UI/Content/Containers/PlaceRow/PlaceOption")
@onready var place_button = get_node_or_null("UI/Content/Containers/PlaceRow/PlaceButton")
@onready var fill_button = get_node_or_null("UI/Content/Containers/FillButton")

var selected_index = -1
var selected_container_id = ""
var selected_container_position := Vector2i(-1, -1)
var pile_textures = {
	"dirt": preload("res://sprites/farm/pile_dirt.svg"),
	"sand": preload("res://sprites/farm/pile_sand.svg"),
	"gravel": preload("res://sprites/farm/pile_gravel.svg")
}
const CONTAINER_TYPES = ["clay_pot", "wood_planter"]
const CONTAINER_GRID_COLUMNS = 3
const CONTAINER_GRID_ROWS = 2

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
	if craft_button != null:
		craft_button.pressed.connect(_craft_container)
	if place_button != null:
		place_button.pressed.connect(_place_container)
	if fill_button != null:
		fill_button.pressed.connect(_fill_container)
	_refresh()

func _go_back() -> void:
	Router.goto_hub()

func _refresh() -> void:
	_refresh_piles()
	_refresh_seed_options()
	_refresh_details()
	_refresh_container_options()
	_refresh_containers()
	_refresh_container_details()

func _refresh_piles() -> void:
	for child in piles_grid.get_children():
		child.queue_free()
	var piles = Farm.get_piles()
	for i in range(piles.size()):
		var pile = piles[i]
		var pile_container = VBoxContainer.new()
		pile_container.alignment = BoxContainer.ALIGNMENT_CENTER
		var button = TextureButton.new()
		button.texture_normal = _pile_texture(pile)
		button.texture_hover = button.texture_normal
		button.texture_pressed = button.texture_normal
		button.expand = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(72, 72)
		button.tooltip_text = _pile_label(pile)
		button.pressed.connect(_on_pile_pressed.bind(i))
		var label = Label.new()
		label.text = _pile_label(pile)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pile_container.add_child(button)
		pile_container.add_child(label)
		piles_grid.add_child(pile_container)

func _pile_label(pile: Dictionary) -> String:
	var pile_type = str(pile.get("type", "dirt")).capitalize()
	var level = int(pile.get("level", 1))
	var seed = str(pile.get("seed", ""))
	var growth = float(pile.get("growth", 0.0))
	if seed != "":
		return "%s Lv %d\nSeeded %.0f%%" % [pile_type, level, growth]
	return "%s Lv %d\nDig" % [pile_type, level]

func _pile_texture(pile: Dictionary) -> Texture2D:
	var pile_type = str(pile.get("type", "dirt"))
	if pile_textures.has(pile_type):
		return pile_textures[pile_type]
	return pile_textures["dirt"]

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
	_refresh_container_details()

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
	_refresh_container_details()

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

func _refresh_container_options() -> void:
	var options = [craft_option, place_option]
	for option in options:
		if option == null:
			continue
		option.clear()
		option.add_item("Select container")
		option.set_item_metadata(0, "")
		for container_id in CONTAINER_TYPES:
			var name = Inventory.get_item_name(container_id)
			var qty = Inventory.get_quantity(container_id)
			option.add_item("%s (%d)" % [name, qty])
			option.set_item_metadata(option.item_count - 1, container_id)

func _refresh_containers() -> void:
	if containers_grid == null:
		return
	for child in containers_grid.get_children():
		child.queue_free()
	containers_grid.columns = CONTAINER_GRID_COLUMNS
	var containers = Farm.get_containers()
	var container_by_pos := {}
	for container in containers:
		if typeof(container) != TYPE_DICTIONARY:
			continue
		var pos = container.get("position", {})
		var key := Vector2i(int(pos.get("x", 0)), int(pos.get("y", 0)))
		container_by_pos[key] = container
	for y in range(CONTAINER_GRID_ROWS):
		for x in range(CONTAINER_GRID_COLUMNS):
			var button = Button.new()
			button.custom_minimum_size = Vector2(110, 72)
			var key := Vector2i(x, y)
			if container_by_pos.has(key):
				button.text = _container_label(container_by_pos[key])
			else:
				button.text = "Empty"
			button.pressed.connect(_on_container_cell_pressed.bind(x, y))
			containers_grid.add_child(button)

func _refresh_container_details() -> void:
	if container_selected_label == null:
		return
	if selected_container_position.x < 0:
		container_selected_label.text = "Select a container spot."
		return
	if selected_container_id == "":
		container_selected_label.text = "Open spot (%d, %d)" % [
			selected_container_position.x,
			selected_container_position.y
		]
		return
	var container = _get_container_by_id(selected_container_id)
	if container.is_empty():
		container_selected_label.text = "Select a container spot."
		return
	var container_type = str(container.get("type", ""))
	var filled = bool(container.get("filled", false))
	var filled_id = str(container.get("filled_id", ""))
	var name = Inventory.get_item_name(filled_id if filled and filled_id != "" else container_type)
	var soil = str(container.get("soil_type", ""))
	container_selected_label.text = "Container: %s\nStatus: %s\nSoil: %s\nPos: %d, %d" % [
		name,
		("Filled" if filled else "Empty"),
		(soil.capitalize() if soil != "" else "None"),
		selected_container_position.x,
		selected_container_position.y
	]

func _container_label(container: Dictionary) -> String:
	var container_type = str(container.get("type", ""))
	var filled = bool(container.get("filled", false))
	var filled_id = str(container.get("filled_id", ""))
	var name = Inventory.get_item_name(filled_id if filled and filled_id != "" else container_type)
	var soil = str(container.get("soil_type", ""))
	if filled:
		var soil_label = soil.capitalize() if soil != "" else "Soil"
		return "%s\nFilled %s" % [name, soil_label]
	return "%s\nEmpty" % name

func _on_container_cell_pressed(x: int, y: int) -> void:
	selected_container_position = Vector2i(x, y)
	var container = _get_container_by_position(selected_container_position)
	if container.is_empty():
		selected_container_id = ""
	else:
		selected_container_id = str(container.get("id", ""))
	_refresh_container_details()

func _selected_container_id_from(option: OptionButton) -> String:
	if option == null:
		return ""
	var idx = option.get_selected_id()
	var meta = option.get_item_metadata(idx)
	if meta == null:
		return ""
	return str(meta)

func _craft_container() -> void:
	var container_id = _selected_container_id_from(craft_option)
	if container_id == "":
		_set_status("Select a container to craft.")
		return
	var name = Inventory.get_item_name(container_id)
	Inventory.add_item(container_id, name, 1)
	_refresh_container_options()
	_set_status("Crafted %s." % name)

func _place_container() -> void:
	var container_id = _selected_container_id_from(place_option)
	if container_id == "":
		_set_status("Select a container to place.")
		return
	if selected_container_position.x < 0:
		_set_status("Select an open container spot.")
		return
	if not _get_container_by_position(selected_container_position).is_empty():
		_set_status("That spot is occupied.")
		return
	var available = Inventory.get_quantity(container_id)
	var placed_count = _count_placed_containers(container_id)
	if available <= placed_count:
		_set_status("Craft more %s first." % Inventory.get_item_name(container_id))
		return
	var container_data = {
		"id": _unique_container_id(container_id),
		"type": container_id,
		"filled": false,
		"soil_type": "",
		"seed": "",
		"growth": 0.0,
		"watered": false,
		"fertilized": false,
		"position": {"x": selected_container_position.x, "y": selected_container_position.y}
	}
	var placed = Farm.place_container(container_data)
	if placed.is_empty():
		_set_status("Unable to place container.")
		return
	_set_status("Placed %s." % Inventory.get_item_name(container_id))
	_refresh_containers()
	_refresh_container_details()

func _fill_container() -> void:
	if selected_index < 0:
		_set_status("Select a pile to fill from.")
		return
	if selected_container_id == "":
		_set_status("Select a container to fill.")
		return
	var container = _get_container_by_id(selected_container_id)
	if container.is_empty():
		_set_status("Select a container to fill.")
		return
	if bool(container.get("filled", false)):
		_set_status("That container is already filled.")
		return
	var container_type = str(container.get("type", ""))
	var result = Farm.fill_container_from_pile(selected_index, container_type)
	if result.is_empty():
		_set_status("Unable to fill container.")
		return
	var material_id = str(result.get("material", ""))
	var filled_id = str(result.get("id", ""))
	Farm.update_container(selected_container_id, {
		"filled": true,
		"soil_type": material_id,
		"filled_id": filled_id
	})
	_set_status("Filled container with %s." % (material_id.capitalize() if material_id != "" else "soil"))
	_refresh_containers()
	_refresh_container_details()

func _get_container_by_id(container_id: String) -> Dictionary:
	var containers = Farm.get_containers()
	for container in containers:
		if typeof(container) != TYPE_DICTIONARY:
			continue
		if str(container.get("id", "")) == container_id:
			return container
	return {}

func _get_container_by_position(position: Vector2i) -> Dictionary:
	var containers = Farm.get_containers()
	for container in containers:
		if typeof(container) != TYPE_DICTIONARY:
			continue
		var pos = container.get("position", {})
		if int(pos.get("x", 0)) == position.x and int(pos.get("y", 0)) == position.y:
			return container
	return {}

func _count_placed_containers(container_type: String) -> int:
	var containers = Farm.get_containers()
	var count = 0
	for container in containers:
		if typeof(container) != TYPE_DICTIONARY:
			continue
		if str(container.get("type", "")) == container_type:
			count += 1
	return count

func _unique_container_id(container_type: String) -> String:
	return "%s_%d_%d" % [
		container_type,
		Time.get_unix_time_from_system(),
		randi()
	]
