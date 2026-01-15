# File: res://scripts/BattleManager.gd
# Autoload as: Battle
# Handles idle combat loops similar to Melvor-style auto battling.
extends Node
class_name BattleManager

signal battle_updated

const MIN_ATTACK_INTERVAL: float = 0.8
const BASE_HP: float = 20.0
const HP_PER_VITALITY: float = 5.0
const BASE_ATTACK: float = 3.0
const STRENGTH_WEIGHT: float = 1.4
const DEXTERITY_WEIGHT: float = 0.6
const MAGIC_WEIGHT: float = 0.8
const DEFENCE_WEIGHT: float = 1.0
const MAGIC_DEFENCE_WEIGHT: float = 0.5
const DEFENCE_REDUCTION: float = 0.3
const VICTORY_HEAL_PERCENT: float = 0.2
const COMMIT_INTERVAL_SEC: int = 10
const DEFAULT_SPEED_MULTIPLIER: float = 0.6
const MIN_SPEED_MULTIPLIER: float = 0.2
const MAX_SPEED_MULTIPLIER: float = 3.0

const DUNGEONS: Dictionary = {
	"slime_pit": {
		"name": "Slime Pit",
		"enemy_id": "slime",
		"enemy_name": "Gel Slime",
		"texture_path": "res://sprites/shui.png",
		"max_hp": 45.0,
		"attack": 5.0,
		"attack_interval": 2.4,
		"defence": 1.0
	},
	"wolf_den": {
		"name": "Wolf Den",
		"enemy_id": "wolf",
		"enemy_name": "Ravenous Wolf",
		"texture_path": "res://sprites/wolf_smith.png",
		"max_hp": 85.0,
		"attack": 9.0,
		"attack_interval": 2.0,
		"defence": 3.0
	},
	"ember_ruins": {
		"name": "Ember Ruins",
		"enemy_id": "ember_golem",
		"enemy_name": "Ember Golem",
		"texture_path": "res://sprites/Maneater.png",
		"max_hp": 140.0,
		"attack": 14.0,
		"attack_interval": 2.3,
		"defence": 5.0
	}
}

var battle: Dictionary = {}
var _last_commit_unix: int = 0

func _ready() -> void:
	if get_tree().root.has_node("State"):
		State.save_loaded.connect(_on_save_loaded)
	set_process(true)

func _process(_delta: float) -> void:
	if battle.is_empty() or not bool(battle.get("active", false)):
		return
	if State.data.is_empty():
		return
	var now=Time.get_unix_time_from_system()
	var last_tick=int(battle.get("last_tick_unix", now))
	var elapsed=now - last_tick
	if elapsed <= 0:
		return
	_simulate_time(float(elapsed) * _current_speed_multiplier())
	battle["last_tick_unix"] = now
	_commit_if_needed(now)

func _on_save_loaded() -> void:
	_load_from_state()
	if battle.is_empty():
		return
	var now=Time.get_unix_time_from_system()
	var last_tick=int(battle.get("last_tick_unix", now))
	var elapsed=now - last_tick
	if elapsed > 0 and bool(battle.get("active", false)):
		_simulate_time(float(elapsed) * _current_speed_multiplier())
		battle["last_tick_unix"] = now
		_commit(true)

func start_battle(dungeon_id: String, party_ids: Array[String], auto_repeat: bool = true) -> bool:
	if not DUNGEONS.has(dungeon_id):
		push_warning("[Battle] Unknown dungeon: %s" % dungeon_id)
		return false
	var party=_build_party_state(party_ids)
	if party.is_empty():
		push_warning("[Battle] No valid party members.")
		return false
	var enemy=_build_enemy_state(DUNGEONS[dungeon_id])
	battle = {
		"active": true,
		"auto_repeat": auto_repeat,
		"speed_multiplier": DEFAULT_SPEED_MULTIPLIER,
		"dungeon_id": dungeon_id,
		"party": party,
		"enemy": enemy,
		"wins": 0,
		"losses": 0,
		"last_tick_unix": Time.get_unix_time_from_system()
	}
	_commit(true)
	battle_updated.emit()
	return true

func stop_battle() -> void:
	if battle.is_empty():
		return
	battle["active"] = false
	battle["last_tick_unix"] = Time.get_unix_time_from_system()
	_commit(true)
	battle_updated.emit()

func _load_from_state() -> void:
	if State.data.is_empty():
		return
	if not State.data.has("battle") or typeof(State.data["battle"]) != TYPE_DICTIONARY:
		State.data["battle"] = {}
	battle = State.data["battle"]
	_ensure_defaults()

func _ensure_defaults() -> void:
	if not battle.has("active"):
		battle["active"] = false
	if not battle.has("auto_repeat"):
		battle["auto_repeat"] = true
	if not battle.has("speed_multiplier"):
		battle["speed_multiplier"] = DEFAULT_SPEED_MULTIPLIER
	if not battle.has("dungeon_id"):
		battle["dungeon_id"] = ""
	if not battle.has("party") or typeof(battle["party"]) != TYPE_DICTIONARY:
		battle["party"] = {}
	if not battle.has("enemy") or typeof(battle["enemy"]) != TYPE_DICTIONARY:
		battle["enemy"] = {}
	if not battle.has("wins"):
		battle["wins"] = 0
	if not battle.has("losses"):
		battle["losses"] = 0
	if not battle.has("last_tick_unix"):
		battle["last_tick_unix"] = Time.get_unix_time_from_system()

func _build_party_state(party_ids: Array[String]) -> Dictionary:
	var members: Array = []
	var total_hp: float = 0.0
	var total_defence: float = 0.0
	var ids: Array[String] = []
	var roster=Ranch.get_creature_objects()
	var roster_by_id: Dictionary = {}
	for creature in roster:
		roster_by_id[creature.id] = creature
	for id in party_ids:
		if not roster_by_id.has(id):
			continue
		var creature: Creature = roster_by_id[id]
		var stats=creature.stats
		var vitality=float(stats.get("vitality", 0))
		var strength=float(stats.get("strength", 0))
		var dexterity=float(stats.get("dexterity", 0))
		var magic=float(stats.get("magic", 0))
		var defence=float(stats.get("defence", 0))
		var magic_defence=float(stats.get("magic_defence", 0))
		var max_hp=BASE_HP + vitality * HP_PER_VITALITY
		var attack=BASE_ATTACK + strength * STRENGTH_WEIGHT + dexterity * DEXTERITY_WEIGHT + magic * MAGIC_WEIGHT
		var attack_interval=max(MIN_ATTACK_INTERVAL, 2.6 - dexterity * 0.02)
		var total_member_defence=defence * DEFENCE_WEIGHT + magic_defence * MAGIC_DEFENCE_WEIGHT
		members.append({
			"id": creature.id,
			"name": creature.name,
			"attack": attack,
			"attack_interval": attack_interval,
			"max_hp": max_hp
		})
		ids.append(creature.id)
		total_hp += max_hp
		total_defence += total_member_defence
	if members.is_empty():
		return {}
	var avg_defence=total_defence / float(members.size())
	return {
		"creature_ids": ids,
		"members": members,
		"max_hp": total_hp,
		"hp": total_hp,
		"defence": avg_defence
	}

func _build_enemy_state(dungeon: Dictionary) -> Dictionary:
	return {
		"id": dungeon.get("enemy_id", "enemy"),
		"name": dungeon.get("enemy_name", "Enemy"),
		"texture_path": dungeon.get("texture_path", ""),
		"max_hp": float(dungeon.get("max_hp", 10.0)),
		"hp": float(dungeon.get("max_hp", 10.0)),
		"attack": float(dungeon.get("attack", 1.0)),
		"attack_interval": float(dungeon.get("attack_interval", 2.5)),
		"defence": float(dungeon.get("defence", 0.0))
	}

func set_battle_speed(multiplier: float) -> void:
	if battle.is_empty():
		return
	var clamped=clampf(multiplier, MIN_SPEED_MULTIPLIER, MAX_SPEED_MULTIPLIER)
	battle["speed_multiplier"] = clamped
	_commit(true)
	battle_updated.emit()

func get_battle_speed() -> float:
	if battle.is_empty():
		return DEFAULT_SPEED_MULTIPLIER
	return float(battle.get("speed_multiplier", DEFAULT_SPEED_MULTIPLIER))

func _simulate_time(seconds: float) -> void:
	if battle.is_empty() or not bool(battle.get("active", false)):
		return
	var remaining=seconds
	var party: Dictionary = battle.get("party", {})
	var enemy: Dictionary = battle.get("enemy", {})
	if party.is_empty() or enemy.is_empty():
		return
	while remaining > 0.0 and bool(battle.get("active", false)):
		var party_dps=_party_dps(party, float(enemy.get("defence", 0.0)))
		var enemy_dps=_enemy_dps(enemy, float(party.get("defence", 0.0)))
		if party_dps <= 0.0 and enemy_dps <= 0.0:
			break
		var time_to_enemy=INF
		var time_to_party=INF
		if party_dps > 0.0:
			time_to_enemy = float(enemy.get("hp", 0.0)) / party_dps
		if enemy_dps > 0.0:
			time_to_party = float(party.get("hp", 0.0)) / enemy_dps
		var step=min(remaining, time_to_enemy, time_to_party)
		if step == INF or step <= 0.0:
			break
		enemy["hp"] = float(enemy.get("hp", 0.0)) - party_dps * step
		party["hp"] = float(party.get("hp", 0.0)) - enemy_dps * step
		remaining -= step
		if float(enemy.get("hp", 0.0)) <= 0.0:
			battle["wins"] = int(battle.get("wins", 0)) + 1
			if bool(battle.get("auto_repeat", true)):
				var dungeon_id=str(battle.get("dungeon_id", ""))
				if DUNGEONS.has(dungeon_id):
					enemy = _build_enemy_state(DUNGEONS[dungeon_id])
				else:
					battle["active"] = false
					break
				party["hp"] = min(float(party.get("max_hp", 0.0)), float(party.get("hp", 0.0)) + float(party.get("max_hp", 0.0)) * VICTORY_HEAL_PERCENT)
				battle["enemy"] = enemy
				if float(party.get("hp", 0.0)) <= 0.0:
					party["hp"] = 1.0
				continue
			else:
				battle["active"] = false
		if float(party.get("hp", 0.0)) <= 0.0:
			battle["losses"] = int(battle.get("losses", 0)) + 1
			battle["active"] = false
	battle["party"] = party
	battle["enemy"] = enemy
	battle_updated.emit()

func _current_speed_multiplier() -> float:
	if battle.is_empty():
		return DEFAULT_SPEED_MULTIPLIER
	return clampf(float(battle.get("speed_multiplier", DEFAULT_SPEED_MULTIPLIER)), MIN_SPEED_MULTIPLIER, MAX_SPEED_MULTIPLIER)

func _party_dps(party: Dictionary, enemy_defence: float) -> float:
	var members = party.get("members", [])
	if typeof(members) != TYPE_ARRAY:
		return 0.0
	var total: float = 0.0
	for member in members:
		if typeof(member) != TYPE_DICTIONARY:
			continue
		var attack=float(member.get("attack", 0.0))
		var interval=float(member.get("attack_interval", 1.0))
		if interval <= 0.0:
			continue
		var hit=max(1.0, attack - enemy_defence * DEFENCE_REDUCTION)
		total += hit / interval
	return total

func _enemy_dps(enemy: Dictionary, party_defence: float) -> float:
	var attack=float(enemy.get("attack", 0.0))
	var interval=float(enemy.get("attack_interval", 1.0))
	if interval <= 0.0:
		return 0.0
	var hit=max(1.0, attack - party_defence * DEFENCE_REDUCTION)
	return hit / interval

func _commit(force: bool = false) -> void:
	if State.data.is_empty():
		return
	State.data["battle"] = battle
	if force:
		State.write_now()
		_last_commit_unix = Time.get_unix_time_from_system()

func _commit_if_needed(now_unix: int) -> void:
	if _last_commit_unix == 0:
		_last_commit_unix = now_unix
		return
	if now_unix - _last_commit_unix >= COMMIT_INTERVAL_SEC:
		_commit(true)
