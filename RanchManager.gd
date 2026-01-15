# File: res://scripts/RanchManager.gd
# Autoload as: RanchManager
# Holds ranch state and creature roster, writes into State.save data.
extends Node
class_name RanchManager

# Creature roster stored as dictionaries for save-friendliness.
var creatures: Array = [] # each entry is Creature.to_dict()

func _ready() -> void:
	# Load from save whenever a save is loaded
	if get_tree().root.has_node("State"):
		State.save_loaded.connect(_on_save_loaded)

func _on_save_loaded() -> void:
	_load_from_State()

func _load_from_State() -> void:
	if State.data.is_empty():
		return

	if not State.data.has("ranch") or typeof(State.data["ranch"]) != TYPE_DICTIONARY:
		State.data["ranch"] = {}

	var ranch: Dictionary = State.data["ranch"]

	if ranch.has("creatures") and typeof(ranch["creatures"]) == TYPE_ARRAY:
		creatures = ranch["creatures"]
	else:
		creatures = []
		ranch["creatures"] = creatures
		State.write_now()

func _commit() -> void:
	if State.data.is_empty():
		return
	if not State.data.has("ranch") or typeof(State.data["ranch"]) != TYPE_DICTIONARY:
		State.data["ranch"] = {}
	State.data["ranch"]["creatures"] = creatures
	State.write_now()

func add_creature(n: String = "Creature") -> void:
	var id := "c_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var c := Creature.new(id, n)
	creatures.append(c.to_dict())
	_commit()

func remove_creature(creature_id: String) -> void:
	for i in range(creatures.size()):
		if creatures[i].get("id", "") == creature_id:
			creatures.remove_at(i)
			_commit()
			return

func get_creature_objects() -> Array[Creature]:
	var out: Array[Creature] = []
	for d in creatures:
		if typeof(d) == TYPE_DICTIONARY:
			out.append(Creature.from_dict(d))
	return out

func update_creature(creature: Creature) -> void:
	for i in range(creatures.size()):
		if creatures[i].get("id", "") == creature.id:
			creatures[i] = creature.to_dict()
			_commit()
			return

# --- Framework hooks you’ll flesh out later ---
func feed(creature_id: String, food_id: String, amount: int = 1) -> void:
	# You can implement food effects as data tables later.
	# For now, we just bump age-related growth example.
	for i in range(creatures.size()):
		if creatures[i].get("id", "") == creature_id:
			var c := Creature.from_dict(creatures[i])
			# placeholder: small generic boost
			c.growth["strength"] = float(c.growth.get("strength", 1.0)) + 0.01 * float(amount)
			creatures[i] = c.to_dict()
			_commit()
			return

func assign_gather(creature_id: String, skill_id: String) -> void:
	# Later: start a job/expedition.
	pass

func assign_dungeon(creature_id: String, dungeon_id: String) -> void:
	# Later: autobattle party assignment.
	var party: Array[String] = [creature_id]
	Battle.start_battle(dungeon_id, party, true)
