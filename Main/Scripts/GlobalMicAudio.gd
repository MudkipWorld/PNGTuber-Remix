extends Node

var _capture: AudioEffectCapture = null
var _mic_bus_index: int = -1

var has_spoken : bool = true
var has_delayed : bool = true

var volume = 0.0
var delay = 0.0

var speech_value : float :
	set(value):
		if value >= Global.settings_dict.volume_limit:
			if not has_spoken:
				delay = 1
				Global.mouth = Global.Mouth.Open
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
				Global.mouth = Global.Mouth.Closed
				Global.not_speaking.emit()
				has_delayed = false

func _ready() -> void:
	_mic_bus_index = AudioServer.get_bus_index("Mic")
	if _mic_bus_index == -1:
		push_error("GlobalMicAudio: 'Mic' bus not found. Speaking detection will not work.")
		return
	_capture = AudioServer.get_bus_effect(_mic_bus_index, 1)

func _exit_tree() -> void:
	if _mic_bus_index != -1 and _capture != null:
		var effect_count := AudioServer.get_bus_effect_count(_mic_bus_index)
		for i in range(effect_count - 1, -1, -1):
			if AudioServer.get_bus_effect(_mic_bus_index, i) == _capture:
				AudioServer.remove_bus_effect(_mic_bus_index, i)
				break

func _process(delta: float) -> void:
	if _capture == null:
		return

	var available := _capture.get_frames_available()
	if available == 0:
		return

	var frames: PackedVector2Array = _capture.get_buffer(available)
	if frames.is_empty():
		return

	var peak := 0.0
	for f in frames:
		peak = max(peak, abs(f.x), abs(f.y))

	volume = lerp(volume, peak * Global.settings_dict.sensitivity_limit, 0.1)
	speech_value = volume
	speech_delay = delay

	if delay > Global.settings_dict.volume_limit and has_spoken:
		delay = 1
	elif volume < Global.settings_dict.volume_limit:
		delay = move_toward(delay, 0, 0.5 * delta)
