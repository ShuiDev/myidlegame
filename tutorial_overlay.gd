# File: res://scripts/TutorialOverlay.gd
# Attach to TutorialOverlay (Control) node that sits ABOVE your hub UI/game
extends Control
class_name TutorialOverlay

signal tutorial_finished

@onready var dialogue_box: HBoxContainer = $CanvasLayer/DialogueBox
@onready var next_button: Button = $CanvasLayer/DialogueBox/Panel2/HBoxContainer/Next
@onready var skip_button: Button = $CanvasLayer/DialogueBox/Panel2/HBoxContainer/Skip

var _steps: Array[String] = []
var _step_i: int = 0
var _chapters: Dictionary = {}
var _chapters_i: int = 0

func _ready() -> void:
	next_button.pressed.connect(_on_next)
	skip_button.pressed.connect(_on_skip)

func start_tutorial(chapters: Dictionary) -> void:
	_chapters = chapters
	_step_i = 0
	_chapters_i = 1
	_steps = _chapters[_chapters_i]
	visible = true
	_show_chapter()
	
func _show_chapter() -> void:
	if _chapters.is_empty():
		_finish()
		return
	
	if _chapters_i < 0:
		_chapters_i = 0
	if _chapters_i > _chapters.size():
		_finish()
		return
		
	_show_step()

func _show_step() -> void:
	if _steps.is_empty():
		_next_chapter()

	if _step_i < 0:
		_step_i = 0
	if _step_i >= _steps.size():
		_next_chapter()

	# Your dialogue engine is the script on the DialogueBox HBoxContainer.
	# It must provide a method named restart_from_label_text() OR you can just set text and rely on _ready.
	# We'll set label.text and call restart_from_label_text if it exists.

	var rtl=$CanvasLayer/DialogueBox/Panel/RichTextLabel
	if rtl != null and rtl is RichTextLabel:
		(rtl as RichTextLabel).text = _steps[_step_i]

	if dialogue_box.has_method("restart_from_label_text"):
		dialogue_box.call("restart_from_label_text")

func _next_chapter():
	_chapters_i += 1
	_step_i = 0
	_show_chapter()

func _on_next() -> void:
	_step_i += 1
	_show_step()

func _on_skip() -> void:
	_finish()

func _finish() -> void:
	print('tut done')
	$CanvasLayer.visible = false
	tutorial_finished.emit()
