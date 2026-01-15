extends Control

@onready var back_button: Button = get_node_or_null("UI/BackButton") as Button
@onready var dungeon_option: OptionButton = get_node_or_null("UI/DungeonRow/DungeonOption") as OptionButton
@onready var party_one_option: OptionButton = get_node_or_null("UI/PartyRow/PartyOneOption") as OptionButton
@onready var party_two_option: OptionButton = get_node_or_null("UI/PartyRow/PartyTwoOption") as OptionButton
@onready var party_three_option: OptionButton = get_node_or_null("UI/PartyRow/PartyThreeOption") as OptionButton
@onready var speed_slider: HSlider = get_node_or_null("UI/SpeedRow/SpeedSlider") as HSlider
@onready var speed_label: Label = get_node_or_null("UI/SpeedRow/SpeedValue") as Label
@onready var start_button: Button = get_node_or_null("UI/ControlsRow/StartButton") as Button
@onready var stop_button: Button = get_node_or_null("UI/ControlsRow/StopButton") as Button
@onready var enemy_texture: TextureRect = get_node_or_null("UI/StatusRow/EnemyTexture") as TextureRect
@onready var enemy_label: Label = get_node_or_null("UI/StatusRow/EnemyStatus") as Label
@onready var party_label: Label = get_node_or_null("UI/StatusRow/PartyStatus") as Label
@onready var record_label: Label = get_node_or_null("UI/StatusRow/RecordStatus") as Label

func _ready() -> void:
	if not _ensure_nodes():
		return
	back_button.pressed.connect(_go_back)
	start_button.pressed.connect(_start_battle)
	stop_button.pressed.connect(_stop_battle)
	speed_slider.value_changed.connect(_on_speed_changed)
	Battle.battle_updated.connect(_refresh_status)
	_populate_dungeons()
	_populate_party_options()
	_sync_speed()
	_refresh_status()

func _ensure_nodes() -> bool:
	var missing: Array[String] = []
	if back_button == null:
		missing.append("UI/BackButton")
	if dungeon_option == null:
		missing.append("UI/DungeonRow/DungeonOption")
	if party_one_option == null:
		missing.append("UI/PartyRow/PartyOneOption")
	if party_two_option == null:
		missing.append("UI/PartyRow/PartyTwoOption")
	if party_three_option == null:
		missing.append("UI/PartyRow/PartyThreeOption")
	if speed_slider == null:
		missing.append("UI/SpeedRow/SpeedSlider")
	if speed_label == null:
		missing.append("UI/SpeedRow/SpeedValue")
	if start_button == null:
		missing.append("UI/ControlsRow/StartButton")
	if stop_button == null:
		missing.append("UI/ControlsRow/StopButton")
	if enemy_texture == null:
		missing.append("UI/StatusRow/EnemyTexture")
	if enemy_label == null:
		missing.append("UI/StatusRow/EnemyStatus")
	if party_label == null:
		missing.append("UI/StatusRow/PartyStatus")
	if record_label == null:
		missing.append("UI/StatusRow/RecordStatus")
	if missing.is_empty():
		return true
	push_warning("BattleScreen missing nodes: %s" % ", ".join(missing))
	return false

func _go_back() -> void:
	Router.goto_hub()

func _populate_dungeons() -> void:
	dungeon_option.clear()
	var dungeon_ids := Battle.DUNGEONS.keys()
	dungeon_ids.sort()
	for dungeon_id in dungeon_ids:
		var dungeon := Battle.DUNGEONS[dungeon_id]
		var name := str(dungeon.get("name", dungeon_id))
		dungeon_option.add_item(name)
		dungeon_option.set_item_metadata(dungeon_option.item_count - 1, dungeon_id)

func _populate_party_options() -> void:
	var options := [party_one_option, party_two_option, party_three_option]
	for option in options:
		option.clear()
		option.add_item("None")
		option.set_item_metadata(0, "")
	var creatures := Ranch.get_creature_objects()
	for creature in creatures:
		for option in options:
			option.add_item(creature.name)
			option.set_item_metadata(option.item_count - 1, creature.id)

func _selected_party_ids() -> Array[String]:
	var ids: Array[String] = []
	var options := [party_one_option, party_two_option, party_three_option]
	for option in options:
		var idx := option.get_selected_id()
		var meta = option.get_item_metadata(idx)
		if meta != null and str(meta) != "":
			var id := str(meta)
			if not ids.has(id):
				ids.append(id)
	return ids

func _selected_dungeon_id() -> String:
	var idx := dungeon_option.get_selected_id()
	var meta = dungeon_option.get_item_metadata(idx)
	if meta == null:
		return ""
	return str(meta)

func _start_battle() -> void:
	var dungeon_id := _selected_dungeon_id()
	if dungeon_id == "":
		return
	var party_ids := _selected_party_ids()
	if party_ids.is_empty():
		return
	Battle.start_battle(dungeon_id, party_ids, true)

func _stop_battle() -> void:
	Battle.stop_battle()

func _on_speed_changed(value: float) -> void:
	Battle.set_battle_speed(value)
	_sync_speed_label(value)

func _sync_speed() -> void:
	var speed := Battle.get_battle_speed()
	speed_slider.value = speed
	_sync_speed_label(speed)

func _sync_speed_label(speed: float) -> void:
	speed_label.text = "x%.1f" % speed

func _refresh_status() -> void:
	var battle := Battle.battle
	if battle.is_empty():
		enemy_label.text = "Enemy: --"
		party_label.text = "Party HP: --"
		record_label.text = "Record: 0W / 0L"
		enemy_texture.texture = null
		return
	var enemies := battle.get("enemies", [])
	var party := battle.get("party", {})
	var enemy_summary := _summarize_enemies(enemies)
	var enemy_hp := float(enemy_summary.get("hp", 0.0))
	var enemy_max := float(enemy_summary.get("max_hp", 0.0))
	var party_hp := float(party.get("hp", 0.0))
	var party_max := float(party.get("max_hp", 0.0))
	var enemy_name := str(enemy_summary.get("name", "Enemy"))
	var enemy_count := int(enemy_summary.get("count", 0))
	var wins := int(battle.get("wins", 0))
	var losses := int(battle.get("losses", 0))
	if enemy_count > 1:
		enemy_label.text = "%s (x%d): %.0f / %.0f" % [enemy_name, enemy_count, enemy_hp, enemy_max]
	else:
		enemy_label.text = "%s: %.0f / %.0f" % [enemy_name, enemy_hp, enemy_max]
	party_label.text = "Party HP: %.0f / %.0f" % [party_hp, party_max]
	record_label.text = "Record: %dW / %dL" % [wins, losses]
	var texture_path := str(enemy_summary.get("texture_path", ""))
	if texture_path != "" and ResourceLoader.exists(texture_path):
		enemy_texture.texture = load(texture_path)
	else:
		enemy_texture.texture = null

func _summarize_enemies(enemies: Array) -> Dictionary:
	var total_hp: float = 0.0
	var total_max: float = 0.0
	var count := 0
	var name := "Enemy"
	var texture_path := ""
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		if count == 0:
			name = str(enemy.get("name", "Enemy"))
			texture_path = str(enemy.get("texture_path", ""))
		count += 1
		total_hp += float(enemy.get("hp", 0.0))
		total_max += float(enemy.get("max_hp", 0.0))
	return {
		"name": name,
		"texture_path": texture_path,
		"hp": total_hp,
		"max_hp": total_max,
		"count": count
	}
