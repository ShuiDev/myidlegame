extends Control

@onready var back_button: Button = $UI/BackButton
@onready var dungeon_option: OptionButton = $UI/DungeonRow/DungeonOption
@onready var party_one_option: OptionButton = $UI/PartyRow/PartyOneOption
@onready var party_two_option: OptionButton = $UI/PartyRow/PartyTwoOption
@onready var party_three_option: OptionButton = $UI/PartyRow/PartyThreeOption
@onready var speed_slider: HSlider = $UI/SpeedRow/SpeedSlider
@onready var speed_label: Label = $UI/SpeedRow/SpeedValue
@onready var start_button: Button = $UI/ControlsRow/StartButton
@onready var stop_button: Button = $UI/ControlsRow/StopButton
@onready var enemy_texture: TextureRect = $UI/StatusRow/EnemyTexture
@onready var enemy_label: Label = $UI/StatusRow/EnemyStatus
@onready var party_label: Label = $UI/StatusRow/PartyStatus
@onready var record_label: Label = $UI/StatusRow/RecordStatus

func _ready() -> void:
	back_button.pressed.connect(_go_back)
	start_button.pressed.connect(_start_battle)
	stop_button.pressed.connect(_stop_battle)
	speed_slider.value_changed.connect(_on_speed_changed)
	Battle.battle_updated.connect(_refresh_status)
	_populate_dungeons()
	_populate_party_options()
	_sync_speed()
	_refresh_status()

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
	var enemy := battle.get("enemy", {})
	var party := battle.get("party", {})
	var enemy_hp := float(enemy.get("hp", 0.0))
	var enemy_max := float(enemy.get("max_hp", 0.0))
	var party_hp := float(party.get("hp", 0.0))
	var party_max := float(party.get("max_hp", 0.0))
	var enemy_name := str(enemy.get("name", "Enemy"))
	var wins := int(battle.get("wins", 0))
	var losses := int(battle.get("losses", 0))
	enemy_label.text = "%s: %.0f / %.0f" % [enemy_name, enemy_hp, enemy_max]
	party_label.text = "Party HP: %.0f / %.0f" % [party_hp, party_max]
	record_label.text = "Record: %dW / %dL" % [wins, losses]
	var texture_path := str(enemy.get("texture_path", ""))
	if texture_path != "" and ResourceLoader.exists(texture_path):
		enemy_texture.texture = load(texture_path)
	else:
		enemy_texture.texture = null
