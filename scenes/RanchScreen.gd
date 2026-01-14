extends Control

@onready var back_button: Button = $BackButton
@onready var add_button: Button = $AddCreatureButton
@onready var list: ItemList = $CreatureList
var t: Texture2D

func _ready() -> void:
	back_button.pressed.connect(_go_back)
	add_button.pressed.connect(_add_creature)
	t = load("res://sprites/wolf_smith.png")
	_refresh()

func _go_back() -> void:
	Router.goto_hub()

func _add_creature() -> void:
	Ranch.add_creature("Critter")
	_refresh()

func _refresh() -> void:
	list.clear()
	var cs := Ranch.get_creature_objects()
	for c in cs:
		# show a few core stats; everything else is still in c.stats dictionary
		var s := "STR %s  DEX %s  MAG %s" % [
			str(c.stats.get("strength", 0)),
			str(c.stats.get("dexterity", 0)),
			str(c.stats.get("magic", 0))
		]
		list.add_item("%s (%s)  |  %s" % [c.name, c.id, s], t)
