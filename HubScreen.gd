# File: res://scripts/HubScreen.gd
# Attach to your Hub root node (Control or Node2D, whatever your hub is)
extends Control

@onready var tutorial: TutorialOverlay = get_node_or_null("TutorialOverlay") as TutorialOverlay
@onready var ranch_button: Button = get_node_or_null("UI/RanchButton") as Button
@onready var smith_button: Button = get_node_or_null("UI/SmithButton") as Button
@onready var build_button: Button = get_node_or_null("UI/BuildButton") as Button
@onready var battle_button: Button = get_node_or_null("UI/BattleButton") as Button
@onready var player_button: Button = get_node_or_null("UI/PlayerButton") as Button

func _ready() -> void:
	if not _ensure_nodes():
		return
	ranch_button.pressed.connect(_go_ranch)
	smith_button.pressed.connect(_go_smith)
	build_button.pressed.connect(_go_build)
	battle_button.pressed.connect(_go_battle)
	player_button.pressed.connect(_go_player)
	tutorial.visible = false
	tutorial.tutorial_finished.connect(_on_tutorial_finished)

	var gs := _require_game_state()
	if gs == null:
		return

	if not gs.tutorial_complete():
		_start_tutorial()

func _ensure_nodes() -> bool:
	var missing: Array[String] = []
	if tutorial == null:
		missing.append("TutorialOverlay")
	if ranch_button == null:
		missing.append("UI/RanchButton")
	if smith_button == null:
		missing.append("UI/SmithButton")
	if build_button == null:
		missing.append("UI/BuildButton")
	if battle_button == null:
		missing.append("UI/BattleButton")
	if player_button == null:
		missing.append("UI/PlayerButton")
	if missing.is_empty():
		return true
	push_warning("HubScreen missing nodes: %s" % ", ".join(missing))
	return false

func _start_tutorial() -> void:
	# You said you'll handle specifics; here are placeholder steps.
	var steps: Array[String] = []
	steps.append("Welcome! This is the hub.")
	steps.append("For now I'll show you around. There are many ways to go about playing this game. But I am here to show you the basics.")
	steps.append("For now the tutorial will be a long winded reddit post style explanation of the game because the guy making this is busy doing other stuff, like making the game.")
	steps.append("You must raise creatures to do your bidding. For now your town has a ranch and a smithy. That's me by the way; the smithy, And no, I don't take treats as payment.")
	steps.append("Your creatures are yours to design for the most part. Some creatures may be innately better than others but you will eventually be able to make any creature excel at any task.")
	steps.append("There are two main types of creatures, those good at labor and those good at combat. Before you go whining, yes there are creatures that are good at both.")
	steps.append("Well to begin let's get you a little freak of your own.")
	
	var chapters = {1:steps}
	tutorial.start_tutorial(chapters)

func _on_tutorial_finished() -> void:
	var gs := _require_game_state()
	if gs == null:
		return
	gs.mark_tutorial_complete()

func _require_game_state() -> State:
	var gs := get_tree().root.get_node_or_null("State")
	if gs == null:
		push_warning("Missing autoload: GameState")
		return null
	return gs as State
	

func _go_ranch() -> void:
	Router.goto_ranch()

func _go_smith() -> void:
	Router.goto_smith()

func _go_build() -> void:
	Router.goto_build()

func _go_battle() -> void:
	Router.goto_battle()

func _go_player() -> void:
	Router.goto_player()
