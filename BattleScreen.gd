extends Control

@onready var back_button = get_node_or_null("UI/BackButton")
@onready var dungeon_option = get_node_or_null("UI/DungeonRow/DungeonOption")
@onready var party_one_option = get_node_or_null("UI/PartyRow/PartyOneOption")
@onready var party_two_option = get_node_or_null("UI/PartyRow/PartyTwoOption")
@onready var party_three_option = get_node_or_null("UI/PartyRow/PartyThreeOption")
@onready var speed_slider = get_node_or_null("UI/SpeedRow/SpeedSlider")
@onready var speed_label = get_node_or_null("UI/SpeedRow/SpeedValue")
@onready var start_button = get_node_or_null("UI/ControlsRow/StartButton")
@onready var stop_button = get_node_or_null("UI/ControlsRow/StopButton")
@onready var enemy_texture = get_node_or_null("UI/StatusRow/EnemyTexture")
@onready var enemy_label = get_node_or_null("UI/StatusRow/EnemyStatus")
@onready var party_label = get_node_or_null("UI/StatusRow/PartyStatus")
@onready var record_label = get_node_or_null("UI/StatusRow/RecordStatus")

func _ready() -> void:
	if back_button == null or dungeon_option == null or party_one_option == null:
		push_warning("BattleScreen missing UI nodes.")
		return
	back_button.pressed.connect(_go_back)
	if start_button != null:
		start_button.pressed.connect(_start_battle)
	if stop_button != null:
		stop_button.pressed.connect(_stop_battle)
	if speed_slider != null:
		speed_slider.value_changed.connect(_on_speed_changed)
	Battle.battle_updated.connect(_refresh_status)
	_populate_dungeons()
	_populate_party_options()
	_sync_speed()
	_refresh_status()

func _go_back() -> void:
	Router.goto_hub()

func _populate_dungeons() -> void:
	if dungeon_option == null:
		return
	dungeon_option.clear()
	var dungeon_ids = Battle.DUNGEONS.keys()
	dungeon_ids.sort()
	for dungeon_id in dungeon_ids:
		var dungeon = Battle.DUNGEONS[dungeon_id]
		var name = str(dungeon.get("name", dungeon_id))
		dungeon_option.add_item(name)
		dungeon_option.set_item_metadata(dungeon_option.item_count - 1, dungeon_id)

func _populate_party_options() -> void:
	var options = [party_one_option, party_two_option, party_three_option]
	for option in options:
		if option == null:
			continue
		option.clear()
		option.add_item("None")
		option.set_item_metadata(0, "")
	var creatures = Ranch.get_creature_objects()
	for creature in creatures:
		for option in options:
			if option == null:
				continue
			option.add_item(creature.name)
			option.set_item_metadata(option.item_count - 1, creature.id)

func _selected_party_ids() -> Array[String]:
	var ids: Array[String] = []
	var options = [party_one_option, party_two_option, party_three_option]
	for option in options:
		if option == null:
			continue
		var idx = option.get_selected_id()
		var meta = option.get_item_metadata(idx)
		if meta != null and str(meta) != "":
			var id = str(meta)
			if not ids.has(id):
				ids.append(id)
	return ids

func _selected_dungeon_id() -> String:
	if dungeon_option == null:
		return ""
	var idx = dungeon_option.get_selected_id()
	var meta = dungeon_option.get_item_metadata(idx)
	if meta == null:
		return ""
	return str(meta)

func _start_battle() -> void:
	var dungeon_id = _selected_dungeon_id()
	if dungeon_id == "":
		return
	var party_ids = _selected_party_ids()
	if party_ids.is_empty():
		return
	Battle.start_battle(dungeon_id, party_ids, true)

func _stop_battle() -> void:
	Battle.stop_battle()

func _on_speed_changed(value: float) -> void:
	Battle.set_battle_speed(value)
	_sync_speed_label(value)

func _sync_speed() -> void:
	if speed_slider == null:
		return
	var speed = Battle.get_battle_speed()
	speed_slider.value = speed
	_sync_speed_label(speed)

func _sync_speed_label(speed: float) -> void:
	if speed_label == null:
		return
	speed_label.text = "x%.1f" % speed

func _refresh_status() -> void:
	var battle = Battle.battle
	if battle.is_empty():
		if enemy_label != null:
			enemy_label.text = "Enemy: --"
		if party_label != null:
			party_label.text = "Party HP: --"
		if record_label != null:
			record_label.text = "Record: 0W / 0L"
		if enemy_texture != null:
			enemy_texture.texture = null
		return
	var enemy = battle.get("enemy", {})
	var party = battle.get("party", {})
	var enemy_hp = float(enemy.get("hp", 0.0))
	var enemy_max = float(enemy.get("max_hp", 0.0))
	var party_hp = float(party.get("hp", 0.0))
	var party_max = float(party.get("max_hp", 0.0))
	var enemy_name = str(enemy.get("name", "Enemy"))
	var wins = int(battle.get("wins", 0))
	var losses = int(battle.get("losses", 0))
	if enemy_label != null:
		enemy_label.text = "%s: %.0f / %.0f" % [enemy_name, enemy_hp, enemy_max]
	if party_label != null:
		party_label.text = "Party HP: %.0f / %.0f" % [party_hp, party_max]
	if record_label != null:
		record_label.text = "Record: %dW / %dL" % [wins, losses]
	var texture_path = str(enemy.get("texture_path", ""))
	if texture_path != "" and ResourceLoader.exists(texture_path):
		if enemy_texture != null:
			enemy_texture.texture = load(texture_path)
	else:
		if enemy_texture != null:
			enemy_texture.texture = null
