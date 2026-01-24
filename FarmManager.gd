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

func dig_pile(index: int) -> Array:
	var piles = get_piles()
	if index < 0 or index >= piles.size():
		return []
	var pile = piles[index]
	if pile.get("seed", "") != "":
		return []
	var drops = _roll_drops(pile)
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

func plant_seed(index: int, seed_id: String) -> bool:
	var piles = get_piles()
	if index < 0 or index >= piles.size():
		return false
	if seed_id.strip_edges() == "":
		return false
	var pile = piles[index]
	if pile.get("seed", "") != "":
		return false
	if Inventory.get_quantity(seed_id) <= 0:
		return false
	if not Inventory.remove_item(seed_id, 1):
		return false
	pile["seed"] = seed_id
	pile["growth"] = 0.0
	pile["watered"] = false
	pile["fertilized"] = false
	piles[index] = pile
	farm["piles"] = piles
	_commit()
	return true

func water_pile(index: int) -> bool:
	var piles = get_piles()
	if index < 0 or index >= piles.size():
		return false
	var pile = piles[index]
	if pile.get("seed", "") == "":
		return false
	pile["watered"] = true
	piles[index] = pile
	farm["piles"] = piles
	_commit()
	return true

func fertilize_pile(index: int) -> bool:
	var piles = get_piles()
	if index < 0 or index >= piles.size():
		return false
	var pile = piles[index]
	if pile.get("seed", "") == "":
		return false
	pile["fertilized"] = true
	piles[index] = pile
	farm["piles"] = piles
	_commit()
	return true

func harvest_pile(index: int) -> Array:
	var piles = get_piles()
	if index < 0 or index >= piles.size():
		return []
	var pile = piles[index]
	var seed_id = str(pile.get("seed", ""))
	if seed_id == "":
		return []
	if float(pile.get("growth", 0.0)) < 100.0:
		return []
	var crop_id = _seed_to_crop(seed_id)
	var crop_name = crop_id.replace("_", " ").capitalize()
	Inventory.add_item(crop_id, crop_name, 1)
	pile["seed"] = ""
	pile["growth"] = 0.0
	pile["watered"] = false
	pile["fertilized"] = false
	piles[index] = pile
	farm["piles"] = piles
	_commit()
	return [{"id": crop_id, "name": crop_name, "qty": 1}]

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
	var piles = get_piles()
	for i in range(piles.size()):
		var pile = piles[i]
		if pile.get("seed", "") == "":
			continue
		var growth = float(pile.get("growth", 0.0))
		if growth >= 100.0:
			continue
		var multiplier = 1.0
		if bool(pile.get("watered", false)):
			multiplier *= 1.5
		if bool(pile.get("fertilized", false)):
			multiplier *= 2.0
		growth += seconds * 0.4 * multiplier
		pile["growth"] = clampf(growth, 0.0, 100.0)
		piles[i] = pile
	farm["piles"] = piles

func _roll_drops(pile: Dictionary) -> Array:
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
	for drop in drops:
		Inventory.add_item(drop.id, drop.name, drop.qty)
	return drops

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
