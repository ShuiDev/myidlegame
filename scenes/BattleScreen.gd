extends Control

@onready var dungeon_option: OptionButton = get_node_or_null("Layout/DungeonOption") as OptionButton
@onready var creature_option_one: OptionButton = get_node_or_null("Layout/PartyOptions/CreatureOption1") as OptionButton
@onready var creature_option_two: OptionButton = get_node_or_null("Layout/PartyOptions/CreatureOption2") as OptionButton
@onready var creature_option_three: OptionButton = get_node_or_null("Layout/PartyOptions/CreatureOption3") as OptionButton
@onready var start_button: Button = get_node_or_null("Layout/ActionButtons/StartButton") as Button
@onready var stop_button: Button = get_node_or_null("Layout/ActionButtons/StopButton") as Button
@onready var enemy_status_label: Label = get_node_or_null("Layout/EnemyStatusLabel") as Label
@onready var party_status_label: Label = get_node_or_null("Layout/PartyStatusLabel") as Label
@onready var record_status_label: Label = get_node_or_null("Layout/RecordStatusLabel") as Label

var _creature_options: Array[OptionButton] = []

func _ready() -> void:
	if not _ensure_nodes():
		return
	_creature_options = [creature_option_one, creature_option_two, creature_option_three]
	_populate_dungeons()
	_populate_creatures()
	start_button.pressed.connect(_on_start_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	Battle.battle_updated.connect(_on_battle_updated)
	_refresh_status()

func _ensure_nodes() -> bool:
	var missing: Array[String] = []
	if dungeon_option == null:
		missing.append("Layout/DungeonOption")
	if creature_option_one == null:
		missing.append("Layout/PartyOptions/CreatureOption1")
	if creature_option_two == null:
		missing.append("Layout/PartyOptions/CreatureOption2")
	if creature_option_three == null:
		missing.append("Layout/PartyOptions/CreatureOption3")
	if start_button == null:
		missing.append("Layout/ActionButtons/StartButton")
	if stop_button == null:
		missing.append("Layout/ActionButtons/StopButton")
	if enemy_status_label == null:
		missing.append("Layout/EnemyStatusLabel")
	if party_status_label == null:
		missing.append("Layout/PartyStatusLabel")
	if record_status_label == null:
		missing.append("Layout/RecordStatusLabel")
	if missing.is_empty():
		return true
	push_warning("BattleScreen (legacy) missing nodes: %s" % ", ".join(missing))
	return false

func _populate_dungeons() -> void:
	dungeon_option.clear()
	var dungeon_ids: Array = Battle.DUNGEONS.keys()
	dungeon_ids.sort()
	for dungeon_id in dungeon_ids:
		var dungeon := Battle.DUNGEONS[dungeon_id]
		var display_name := str(dungeon.get("name", dungeon_id))
		dungeon_option.add_item(display_name)
		var index := dungeon_option.item_count - 1
		dungeon_option.set_item_metadata(index, dungeon_id)

func _populate_creatures() -> void:
	var creatures := Ranch.get_creature_objects()
	for option in _creature_options:
		option.clear()
		option.add_item("-- Empty --")
		option.set_item_metadata(0, "")
		for creature in creatures:
			option.add_item(creature.name)
			var index := option.item_count - 1
			option.set_item_metadata(index, creature.id)

func _on_start_pressed() -> void:
	if dungeon_option.item_count == 0:
		return
	var dungeon_id := dungeon_option.get_item_metadata(dungeon_option.selected)
	if typeof(dungeon_id) != TYPE_STRING or dungeon_id == "":
		return
	var party_ids: Array[String] = []
	for option in _creature_options:
		if option.item_count == 0:
			continue
		var creature_id := option.get_item_metadata(option.selected)
		if typeof(creature_id) == TYPE_STRING and creature_id != "":
			party_ids.append(creature_id)
	Battle.start_battle(dungeon_id, party_ids, true)

func _on_stop_pressed() -> void:
	Battle.stop_battle()

func _on_battle_updated() -> void:
	_refresh_status()

func _refresh_status() -> void:
	if Battle.battle.is_empty():
		enemy_status_label.text = "Enemy HP: -"
		party_status_label.text = "Party HP: -"
		record_status_label.text = "Wins/Losses: -"
		return
	var enemy := Battle.battle.get("enemy", {})
	var enemy_name := str(enemy.get("name", "Enemy"))
	var enemy_hp := float(enemy.get("hp", 0.0))
	var enemy_max := float(enemy.get("max_hp", 0.0))
	enemy_status_label.text = "%s HP: %.0f/%.0f" % [enemy_name, enemy_hp, enemy_max]

	var party := Battle.battle.get("party", {})
	var party_hp := float(party.get("hp", 0.0))
	var party_max := float(party.get("max_hp", 0.0))
	party_status_label.text = "Party HP: %.0f/%.0f" % [party_hp, party_max]

	var wins := int(Battle.battle.get("wins", 0))
	var losses := int(Battle.battle.get("losses", 0))
	record_status_label.text = "Wins/Losses: %d/%d" % [wins, losses]
