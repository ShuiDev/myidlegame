# File: res://scripts/TutorialOverlay.gd
# Attach to TutorialOverlay (Control) node that sits ABOVE your hub UI/game
extends Control
class_name TutorialOverlay

signal tutorial_finished

@onready var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
@onready var dialogue_box: HBoxContainer = get_node_or_null("CanvasLayer/DialogueBox") as HBoxContainer
@onready var dialogue_label: RichTextLabel = get_node_or_null("CanvasLayer/DialogueBox/Panel/RichTextLabel") as RichTextLabel
@onready var next_button: Button = get_node_or_null("CanvasLayer/DialogueBox/Panel2/HBoxContainer/Next") as Button
@onready var skip_button: Button = get_node_or_null("CanvasLayer/DialogueBox/Panel2/HBoxContainer/Skip") as Button

var _steps: Array[String] = []
var _step_i: int = 0
var _chapters: Dictionary = {}
var _chapters_i: int = 0

func _ready() -> void:
	if not _ensure_nodes():
		return
	next_button.pressed.connect(_on_next)
	skip_button.pressed.connect(_on_skip)

func _ensure_nodes() -> bool:
	var missing: Array[String] = []
	if canvas_layer == null:
		missing.append("CanvasLayer")
	if dialogue_box == null:
		missing.append("CanvasLayer/DialogueBox")
	if dialogue_label == null:
		missing.append("CanvasLayer/DialogueBox/Panel/RichTextLabel")
	if next_button == null:
		missing.append("CanvasLayer/DialogueBox/Panel2/HBoxContainer/Next")
	if skip_button == null:
		missing.append("CanvasLayer/DialogueBox/Panel2/HBoxContainer/Skip")
	if missing.is_empty():
		return true
	push_warning("TutorialOverlay missing nodes: %s" % ", ".join(missing))
	return false

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

	if dialogue_label != null:
		dialogue_label.text = _steps[_step_i]

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
	if canvas_layer != null:
		canvas_layer.visible = false
	tutorial_finished.emit()
