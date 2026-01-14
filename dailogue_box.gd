# File: res://scripts/DialogueBlipBox.gd
# This is your Banjo-style dialogue engine (the one you already have), BUT with a helper method
# so TutorialOverlay can restart it after changing label.text.
# Attach this to the DialogueBox HBoxContainer:
extends HBoxContainer

@onready var label: RichTextLabel = $Panel/RichTextLabel
@onready var base_player: AudioStreamPlayer = $Blip

@export var chars_per_sec: float = 40.0
@export var blip_every: int = 3
@export var voices_folder: String = "res://voices/big_dogs"
@export var pitch_min: float = 0.85
@export var pitch_max: float = 1.25
@export var max_polyphony: int = 6

var _rng := RandomNumberGenerator.new()
var _bank: Array[AudioStream] = []

var _full_text: String = ""
var _index: int = 0
var _timer: float = 0.0
var _typing: bool = true
var _blip_count: int = 0

var _pool: Array = []
var _pool_i: int = 0
var _bus_names: Array[String] = []

func _ready() -> void:
	_rng.randomize()
	_load_bank()
	_setup_audio_pool()

	_full_text = label.text
	label.text = ""
	_reset_typing()

func _exit_tree() -> void:
	for n in _bus_names:
		var idx := AudioServer.get_bus_index(n)
		if idx != -1:
			AudioServer.remove_bus(idx)
	_bus_names.clear()

func restart_from_label_text() -> void:
	_full_text = label.text
	label.text = ""
	_reset_typing()

func _reset_typing() -> void:
	_index = 0
	_timer = 0.0
	_typing = true
	_blip_count = 0

func _process(delta: float) -> void:
	if _typing:
		_timer += delta * chars_per_sec
		while _timer >= 1.0:
			_timer -= 1.0
			_step()

	if Input.is_action_just_pressed("ui_accept"):
		_finish()

func _step() -> void:
	if _index >= _full_text.length():
		_typing = false
		return

	var ch := _full_text[_index]
	_index += 1
	label.text += ch

	_blip_count += 1
	if blip_every > 1 and (_blip_count % blip_every) != 0:
		return

	_play_blip_no_timestretch()

func _finish() -> void:
	label.text = _full_text
	_typing = false

func _play_blip_no_timestretch() -> void:
	if _bank.is_empty() or _pool.is_empty():
		return

	var stream: AudioStream = _bank[_rng.randi_range(0, _bank.size() - 1)]
	var entry = _pool[_pool_i]
	print(entry)
	_pool_i = (_pool_i + 1) % _pool.size()

	var p: AudioStreamPlayer = entry["player"]
	var fx: AudioEffectPitchShift = entry["effect"]
	var limit: AudioEffectHardLimiter = entry["limiter"]

	p.stream = stream
	fx.pitch_scale = _rng.randf_range(pitch_min, pitch_max)
	limit.ceiling_db = -20
	p.play()

func _setup_audio_pool() -> void:
	_pool.clear()
	_pool_i = 0

	base_player.stop()

	var lanes = max(1, max_polyphony)
	for i in range(lanes):
		var bus_name := "dlg_voice_%s_%d" % [str(get_instance_id()), i]
		_bus_names.append(bus_name)

		AudioServer.add_bus(AudioServer.bus_count)
		var bus_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, bus_name)

		var fx := AudioEffectPitchShift.new()
		fx.pitch_scale = 1.0
		AudioServer.add_bus_effect(bus_idx, fx, 0)
		
		var limit = AudioEffectHardLimiter.new()
		limit.ceiling_db = 0
		AudioServer.add_bus_effect(bus_idx, limit, 0)

		var p: AudioStreamPlayer
		if i == 0:
			p = base_player
		else:
			p = AudioStreamPlayer.new()
			add_child(p)

		p.bus = bus_name
		p.autoplay = false
		_pool.append({"player": p, "effect": fx, "limiter": limit})

func _load_bank() -> void:
	_bank.clear()

	var dir := DirAccess.open(voices_folder)
	if dir == null:
		push_warning("Dialogue voices folder not found: " + voices_folder)
		return

	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f == "":
			break
		if dir.current_is_dir():
			continue

		var low := f.to_lower()
		if not (low.ends_with(".ogg") or low.ends_with(".wav") or low.ends_with(".mp3")):
			continue

		var p := voices_folder.path_join(f)
		var res := ResourceLoader.load(p)
		if res != null and res is AudioStream:
			_bank.append(res)

	dir.list_dir_end()

func _change_char(img:Texture2D,voice:String):
	$NinePatchRect/TextureRect.texture = img
	voices_folder = voice
