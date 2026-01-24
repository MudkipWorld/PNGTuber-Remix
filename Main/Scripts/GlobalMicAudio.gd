extends AudioStreamPlayer


var audio = AudioServer
var sample 
var linear_sampler


var has_spoken : bool = true
var has_delayed : bool = true

var volume = 0.0
var delay = 0.0

var input_mix_rate := AudioServer.get_input_mix_rate()
var chunk_size := int(input_mix_rate * 0.02)

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




func _process(delta):
	if AudioServer.get_input_frames_available() < chunk_size:
		return
	var frames: PackedVector2Array = AudioServer.get_input_frames(chunk_size)
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
