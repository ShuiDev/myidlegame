extends Control

@onready var back_button: Button = $BackButton
@onready var add_button: Button = $AddCreatureButton
@onready var dungeon_option: OptionButton = $DungeonOption
@onready var list: ItemList = $CreatureList
@onready var start_button: Button = $StartBattleButton
@onready var feedback_label: Label = $FeedbackLabel

const MAX_PARTY_SIZE := 3

var t: Texture2D

func _ready() -> void:
	back_button.pressed.connect(_go_back)
	add_button.pressed.connect(_add_creature)
	dungeon_option.item_selected.connect(_on_dungeon_selected)
	list.multi_selected.connect(_on_creature_multi_selected)
	start_button.pressed.connect(_on_start_pressed)
	t = load("res://sprites/wolf_smith.png")
	_populate_dungeons()
	_refresh()
	_update_start_state()

func _go_back() -> void:
	Router.goto_hub()

func _add_creature() -> void:
	Ranch.add_creature("Critter")
	_refresh()

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

func _refresh() -> void:
	list.clear()
	var cs=Ranch.get_creature_objects()
	for c in cs:
		# show a few core stats; everything else is still in c.stats dictionary
		var s="STR %s  DEX %s  MAG %s" % [
			str(c.stats.get("strength", 0)),
			str(c.stats.get("dexterity", 0)),
			str(c.stats.get("magic", 0))
		]
		list.add_item("%s (%s)  |  %s" % [c.name, c.id, s], t)
		var index := list.item_count - 1
		list.set_item_metadata(index, c.id)
	_update_start_state()

func _on_creature_multi_selected(index: int, selected: bool) -> void:
	if selected and list.get_selected_items().size() > MAX_PARTY_SIZE:
		list.deselect(index)
		feedback_label.text = "Pick up to %d creatures." % MAX_PARTY_SIZE
	else:
		feedback_label.text = ""
	_update_start_state()

func _on_dungeon_selected(_index: int) -> void:
	feedback_label.text = ""
	_update_start_state()

func _get_selected_dungeon_id() -> String:
	if dungeon_option.item_count == 0:
		return ""
	var dungeon_id := dungeon_option.get_item_metadata(dungeon_option.selected)
	if typeof(dungeon_id) != TYPE_STRING:
		return ""
	return dungeon_id

func _get_selected_party_ids() -> Array[String]:
	var party_ids: Array[String] = []
	for index in list.get_selected_items():
		var creature_id := list.get_item_metadata(index)
		if typeof(creature_id) == TYPE_STRING and creature_id != "":
			party_ids.append(creature_id)
	return party_ids

func _update_start_state() -> void:
	var dungeon_id := _get_selected_dungeon_id()
	var party_ids := _get_selected_party_ids()
	start_button.disabled = dungeon_id == "" or party_ids.is_empty()

func _on_start_pressed() -> void:
	var dungeon_id := _get_selected_dungeon_id()
	var party_ids := _get_selected_party_ids()
	if dungeon_id == "" or party_ids.is_empty():
		feedback_label.text = "Select a dungeon and at least one creature."
		_update_start_state()
		return
	var started := Battle.start_battle(dungeon_id, party_ids, true)
	if not started:
		feedback_label.text = "Unable to start battle."
	else:
		feedback_label.text = ""
	_update_start_state()
