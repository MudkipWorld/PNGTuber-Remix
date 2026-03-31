extends Node

var mic_input : MiniAudio = MiniAudio.new()

static var has_spoken : bool = true
static var has_delayed : bool = true

static var volume = 0.0
static var delay = 0.0

var speech_value : float :
	set(value):
		if value >= Global.settings_dict.volume_limit:
			if not has_spoken:
				delay = 100.0
				Global.speaking.emit()
				has_delayed = true
				has_spoken = true

		if value < Global.settings_dict.volume_limit:
			if has_spoken:
				has_spoken = false

var speech_delay : float :
	set(value):
		if value < Global.settings_dict.volume_delay:
			if has_delayed:
				Global.not_speaking.emit()
				has_delayed = false

func _ready() -> void:
	pass

func _exit_tree() -> void:
	mic_input.stop_audio()

func _physics_process(delta: float) -> void:
	Global.tick += delta
	var peak : float = (mic_input.get_sample()) * Global.settings_dict.sensitivity_limit
	volume = lerp(volume, peak, 0.1)
	speech_value = volume
	speech_delay = delay

	if delay > Global.settings_dict.volume_limit and has_spoken:
		delay = 1
	elif volume < Global.settings_dict.volume_limit:
		delay = move_toward(delay, 0, 0.5 * delta)
