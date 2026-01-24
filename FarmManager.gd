# File: res://scripts/FarmManager.gd
# Autoload as: Farm
extends Node
class_name FarmManager

const MAX_LEVEL = 5
const PILE_TYPES = ["dirt", "sand", "gravel"]

var farm = {}

func _ready() -> void:
	if get_tree().root.has_node("State"):
		State.save_loaded.connect(_on_save_loaded)

func _on_save_loaded() -> void:
	_load_from_state()
	_apply_offline_growth()

func _load_from_state() -> void:
	if State.data.is_empty():
		return
	if not State.data.has("farm") or typeof(State.data["farm"]) != TYPE_DICTIONARY:
		State.data["farm"] = {}
	farm = State.data["farm"]
	_ensure_defaults()

func _ensure_defaults() -> void:
	if not farm.has("containers") or typeof(farm["containers"]) != TYPE_ARRAY:
		farm["containers"] = []
	if not farm.has("piles") or typeof(farm["piles"]) != TYPE_ARRAY or farm["piles"].is_empty():
		farm["piles"] = _default_piles()
	if not farm.has("last_tick_unix"):
		farm["last_tick_unix"] = Time.get_unix_time_from_system()

func _default_piles() -> Array:
	var piles = []
	for i in range(6):
		var pile_type = PILE_TYPES[i % PILE_TYPES.size()]
		piles.append(_new_pile(pile_type))
	return piles

func _new_pile(pile_type: String) -> Dictionary:
	return {
		"type": pile_type,
		"level": 1,
		"seed": "",
		"growth": 0.0,
		"watered": false,
		"fertilized": false
	}

func _commit() -> void:
	if State.data.is_empty():
		return
	State.data["farm"] = farm
	State.write_now()

func get_piles() -> Array:
	if farm.is_empty():
		return []
	return farm.get("piles", [])

func get_containers() -> Array:
	if farm.is_empty():
		return []
	return farm.get("containers", [])

func place_container(container_data: Dictionary) -> Dictionary:
	if farm.is_empty():
		return {}
	var container = _new_container(container_data)
	if str(container.get("id", "")).strip_edges() == "":
		return {}
	if str(container.get("type", "")).strip_edges() == "":
		return {}
	var containers = get_containers()
	containers.append(container)
	farm["containers"] = containers
	_commit()
	return container

func remove_container(container_id: String) -> Dictionary:
	if farm.is_empty():
		return {}
	if container_id.strip_edges() == "":
		return {}
	var containers = get_containers()
	for i in range(containers.size()):
		var container = containers[i]
		if str(container.get("id", "")) == container_id:
			containers.remove_at(i)
			farm["containers"] = containers
			_commit()
			return container
	return {}

func update_container(container_id: String, updates: Dictionary) -> Dictionary:
	if farm.is_empty():
		return {}
	if container_id.strip_edges() == "":
		return {}
	if typeof(updates) != TYPE_DICTIONARY:
		return {}
	var containers = get_containers()
	for i in range(containers.size()):
		var container = containers[i]
		if str(container.get("id", "")) == container_id:
			for key in updates.keys():
				container[key] = updates[key]
			containers[i] = container
			farm["containers"] = containers
			_commit()
			return container
	return {}

func dig_pile(index: int) -> Array:
	var piles = get_piles()
	if index < 0 or index >= piles.size():
		return []
	var pile = piles[index]
	if pile.get("seed", "") != "":
		return []
	var drops = _generate_drops(pile)
	_add_drops_to_inventory(drops)
	piles[index] = pile
	farm["piles"] = piles
	_commit()
	return drops

func upgrade_pile(index: int) -> bool:
	var piles = get_piles()
	if index < 0 or index >= piles.size():
		return false
	var pile = piles[index]
	var level = int(pile.get("level", 1))
	if level >= MAX_LEVEL:
		return false
	pile["level"] = level + 1
	piles[index] = pile
	farm["piles"] = piles
	_commit()
	return true

func plant_seed_in_container(container_id: String, seed_id: String) -> bool:
	if container_id.strip_edges() == "":
		return false
	if seed_id.strip_edges() == "":
		return false
	var containers = get_containers()
	for i in range(containers.size()):
		var container = containers[i]
		if str(container.get("id", "")) != container_id:
			continue
		if not bool(container.get("filled", false)):
			return false
		if str(container.get("seed", "")) != "":
			return false
		if Inventory.get_quantity(seed_id) <= 0:
			return false
		if not Inventory.remove_item(seed_id, 1):
			return false
		container["seed"] = seed_id
		container["growth"] = 0.0
		container["watered"] = false
		container["fertilized"] = false
		containers[i] = container
		farm["containers"] = containers
		_commit()
		return true
	return false

func water_container(container_id: String) -> bool:
	if container_id.strip_edges() == "":
		return false
	var containers = get_containers()
	for i in range(containers.size()):
		var container = containers[i]
		if str(container.get("id", "")) != container_id:
			continue
		if str(container.get("seed", "")) == "":
			return false
		container["watered"] = true
		containers[i] = container
		farm["containers"] = containers
		_commit()
		return true
	return false

func fertilize_container(container_id: String) -> bool:
	if container_id.strip_edges() == "":
		return false
	var containers = get_containers()
	for i in range(containers.size()):
		var container = containers[i]
		if str(container.get("id", "")) != container_id:
			continue
		if str(container.get("seed", "")) == "":
			return false
		container["fertilized"] = true
		containers[i] = container
		farm["containers"] = containers
		_commit()
		return true
	return false

func harvest_container(container_id: String) -> Array:
	if container_id.strip_edges() == "":
		return []
	var containers = get_containers()
	for i in range(containers.size()):
		var container = containers[i]
		if str(container.get("id", "")) != container_id:
			continue
		var seed_id = str(container.get("seed", ""))
		if seed_id == "":
			return []
		if float(container.get("growth", 0.0)) < 100.0:
			return []
		var crop_id = _seed_to_crop(seed_id)
		var crop_name = crop_id.replace("_", " ").capitalize()
		Inventory.add_item(crop_id, crop_name, 1)
		container["seed"] = ""
		container["growth"] = 0.0
		container["watered"] = false
		container["fertilized"] = false
		containers[i] = container
		farm["containers"] = containers
		_commit()
		return [{"id": crop_id, "name": crop_name, "qty": 1}]
	return []

func fill_container_from_pile(pile_index: int, container_id: String) -> Dictionary:
	if container_id.strip_edges() == "":
		return {}
	if not Inventory.is_container(container_id):
		return {}
	if Inventory.is_container_filled(container_id):
		return {}
	if Inventory.get_quantity(container_id) <= 0:
		return {}
	var material_id = ""
	var material_name = ""
	var piles = get_piles()
	if pile_index >= 0 and pile_index < piles.size():
		var pile = piles[pile_index]
		if pile.get("seed", "") != "":
			return {}
		var drops = _generate_drops(pile)
		var base_material = _base_material(str(pile.get("type", "dirt")))
		material_id = str(base_material.get("id", ""))
		material_name = str(base_material.get("name", material_id))
		if material_id == "":
			return {}
		_add_drops_to_inventory(drops, material_id, 1)
		piles[pile_index] = pile
		farm["piles"] = piles
		_commit()
	else:
		var material_candidates = ["dirt", "sand", "gravel"]
		for candidate in material_candidates:
			if Inventory.get_quantity(candidate) > 0:
				material_id = candidate
				break
		if material_id == "":
			return {}
		if not Inventory.remove_item(material_id, 1):
			return {}
		material_name = Inventory.get_item_name(material_id)
	if not Inventory.remove_item(container_id, 1):
		return {}
	var filled_id = Inventory.get_filled_container_id(container_id)
	if filled_id == "":
		return {}
	var filled_name = Inventory.get_item_name(filled_id)
	Inventory.add_item(filled_id, filled_name, 1)
	return {
		"id": filled_id,
		"name": filled_name,
		"material": material_id,
		"material_name": material_name
	}

func _new_container(container_data: Dictionary) -> Dictionary:
	return {
		"id": str(container_data.get("id", "")),
		"type": str(container_data.get("type", "")),
		"filled": bool(container_data.get("filled", false)),
		"filled_id": str(container_data.get("filled_id", "")),
		"soil_type": str(container_data.get("soil_type", "")),
		"seed": str(container_data.get("seed", "")),
		"growth": float(container_data.get("growth", 0.0)),
		"watered": bool(container_data.get("watered", false)),
		"fertilized": bool(container_data.get("fertilized", false)),
		"position": _normalize_position(container_data.get("position", {}))
	}

func _normalize_position(position: Variant) -> Dictionary:
	if typeof(position) == TYPE_VECTOR2:
		return {"x": position.x, "y": position.y}
	if typeof(position) == TYPE_DICTIONARY:
		return {
			"x": float(position.get("x", 0.0)),
			"y": float(position.get("y", 0.0))
		}
	return {"x": 0.0, "y": 0.0}

func _apply_offline_growth() -> void:
	if farm.is_empty():
		return
	var now = Time.get_unix_time_from_system()
	var last_tick = int(farm.get("last_tick_unix", now))
	var elapsed = now - last_tick
	if elapsed <= 0:
		return
	_apply_growth(float(elapsed))
	farm["last_tick_unix"] = now
	_commit()

func _apply_growth(seconds: float) -> void:
	var containers = get_containers()
	for i in range(containers.size()):
		var container = containers[i]
		if str(container.get("seed", "")) == "":
			continue
		var growth = float(container.get("growth", 0.0))
		if growth >= 100.0:
			continue
		var multiplier = 1.0
		if bool(container.get("watered", false)):
			multiplier *= 1.5
		if bool(container.get("fertilized", false)):
			multiplier *= 2.0
		growth += seconds * 0.4 * multiplier
		container["growth"] = clampf(growth, 0.0, 100.0)
		containers[i] = container
	farm["containers"] = containers

func _generate_drops(pile: Dictionary) -> Array:
	var drops = []
	var pile_type = str(pile.get("type", "dirt"))
	var level = int(pile.get("level", 1))
	var base_item = _base_material(pile_type)
	var base_qty = randi_range(1, 2 + level)
	drops.append({"id": base_item.id, "name": base_item.name, "qty": base_qty})
	if randf() < 0.2:
		var ore = _random_ore()
		drops.append({"id": ore.id, "name": ore.name, "qty": 1})
	if randf() < 0.08:
		var gem = _random_gem()
		drops.append({"id": gem.id, "name": gem.name, "qty": 1})
	if randf() < 0.05:
		var fossil = _random_fossil()
		drops.append({"id": fossil.id, "name": fossil.name, "qty": 1})
	if randf() < 0.15:
		var seed = _random_seed()
		drops.append({"id": seed.id, "name": seed.name, "qty": 1})
	return drops

func _add_drops_to_inventory(drops: Array, skip_id: String = "", skip_qty: int = 0) -> void:
	var remaining_skip = max(skip_qty, 0)
	for drop in drops:
		if typeof(drop) != TYPE_DICTIONARY:
			continue
		var drop_id = str(drop.get("id", ""))
		var drop_name = str(drop.get("name", drop_id))
		var drop_qty = int(drop.get("qty", 0))
		if drop_qty <= 0:
			continue
		if drop_id == skip_id and remaining_skip > 0:
			var usable_qty = drop_qty - remaining_skip
			remaining_skip = max(remaining_skip - drop_qty, 0)
			if usable_qty <= 0:
				continue
			Inventory.add_item(drop_id, drop_name, usable_qty)
		else:
			Inventory.add_item(drop_id, drop_name, drop_qty)

func _base_material(pile_type: String) -> Dictionary:
	match pile_type:
		"sand":
			return {"id": "sand", "name": "Sand"}
		"gravel":
			return {"id": "gravel", "name": "Gravel"}
		_:
			return {"id": "dirt", "name": "Dirt"}

func _random_ore() -> Dictionary:
	var ores = [
		{"id": "ore_copper", "name": "Copper Ore"},
		{"id": "ore_iron", "name": "Iron Ore"}
	]
	return ores[randi() % ores.size()]

func _random_gem() -> Dictionary:
	var gems = [
		{"id": "gem_quartz", "name": "Quartz"},
		{"id": "gem_amber", "name": "Amber"}
	]
	return gems[randi() % gems.size()]

func _random_fossil() -> Dictionary:
	var fossils = [
		{"id": "fossil_small", "name": "Small Fossil"},
		{"id": "fossil_ancient", "name": "Ancient Fossil"}
	]
	return fossils[randi() % fossils.size()]

func _random_seed() -> Dictionary:
	var seeds = [
		{"id": "seed_turnip", "name": "Turnip Seed"},
		{"id": "seed_berry", "name": "Berry Seed"}
	]
	return seeds[randi() % seeds.size()]

func _seed_to_crop(seed_id: String) -> String:
	return seed_id.replace("seed_", "crop_")
