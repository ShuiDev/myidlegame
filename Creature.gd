# File: res://scripts/Creature.gd
# Pure-data creature object. You can serialize it into your save easily.
extends RefCounted
class_name Creature

var id: String = ""
var name: String = ""
var species: String = "default"

var age_days: int = 0

# Stats live in a Dictionary so adding new stats is trivial.
# Keys come from Reg.all_stat_ids().
var stats: Dictionary = {}

# Optional: growth multipliers that feeding can tweak (again dictionary-driven)
var growth: Dictionary = {}

# Simple inventory/meters you may want later
var hunger: float = 0.0
var happiness: float = 0.0
var equipment: Dictionary = {}

func _init(new_id: String = "", new_name: String = "Creature") -> void:
	id = new_id
	name = new_name
	stats = Reg.default_stats()
	growth = Reg.default_growth_rates()
	equipment = {
		"weapon": "",
		"armor": "",
		"accessory": ""
	}

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"species": species,
		"age_days": age_days,
		"stats": stats,
		"growth": growth,
		"hunger": hunger,
		"happiness": happiness,
		"equipment": equipment
	}

static func from_dict(d: Dictionary) -> Creature:
	var c := Creature.new(d.get("id", ""), d.get("name", "Creature"))
	c.species = d.get("species", "default")
	c.age_days = int(d.get("age_days", 0))

	# Merge to support new stats added later without breaking old saves
	var base_stats := Reg.default_stats()
	var loaded_stats = d.get("stats", {})
	if typeof(loaded_stats) == TYPE_DICTIONARY:
		for k in loaded_stats.keys():
			base_stats[k] = loaded_stats[k]
	c.stats = base_stats

	var base_growth := Reg.default_growth_rates()
	var loaded_growth = d.get("growth", {})
	if typeof(loaded_growth) == TYPE_DICTIONARY:
		for k in loaded_growth.keys():
			base_growth[k] = loaded_growth[k]
	c.growth = base_growth

	c.hunger = float(d.get("hunger", 0.0))
	c.happiness = float(d.get("happiness", 0.0))
	var base_equipment := {
		"weapon": "",
		"armor": "",
		"accessory": ""
	}
	var loaded_equipment = d.get("equipment", {})
	if typeof(loaded_equipment) == TYPE_DICTIONARY:
		for k in loaded_equipment.keys():
			base_equipment[k] = loaded_equipment[k]
	c.equipment = base_equipment
	return c
