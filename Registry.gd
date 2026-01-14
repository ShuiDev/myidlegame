# File: res://scripts/Registry.gd
# Autoload as: Registry
# Purpose: central place to define stats/skills so adding new ones is one line.
extends Node
class_name Registry

# --- Core combat stats (add/remove freely) ---
const COMBAT_STATS: Array[String] = [
	"height",
	"weight",
	"strength",
	"vitality",
	"defence",
	"dexterity",
	"magic",
	"magic_defence"
]

# --- Skills (gathering/processing). Add new skills by adding a string here. ---
# Examples: "mining", "woodcutting", "fishing", "cooking", "smithing", "alchemy", etc.
var SKILLS: Array[String] = [
	"mining",
	"woodcutting",
	"fishing",
	"cooking",
	"smithing"
]

func all_stat_ids() -> Array[String]:
	var out: Array[String] = []
	out.append_array(COMBAT_STATS)
	for s in SKILLS:
		out.append("skill_" + s)
	return out

func default_stats() -> Dictionary:
	var d: Dictionary = {}
	for id in all_stat_ids():
		d[id] = 0
	return d

func default_growth_rates() -> Dictionary:
	# Growth rates are per-day (or per-tick) multipliers; tune later.
	# Add new stats automatically: default 1.0 (no change).
	var d: Dictionary = {}
	for id in all_stat_ids():
		d[id] = 1.0
	return d

func add_skill(skill_id: String) -> void:
	if skill_id.strip_edges() == "":
		return
	if SKILLS.has(skill_id):
		return
	SKILLS.append(skill_id)
