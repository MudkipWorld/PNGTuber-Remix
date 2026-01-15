extends AudioStreamPlayer


var audio = AudioServer
var sample 
var linear_sampler


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


func _process(_delta):
	sample = audio.get_bus_peak_volume_left_db(2, 0)
	linear_sampler = db_to_linear(sample) 
	volume = lerp(volume, linear_sampler * Global.settings_dict.sensitivity_limit, 0.1)
	speech_value = volume
	speech_delay = delay
	
	if delay > Global.settings_dict.volume_limit && has_spoken:
		delay = 1
	elif volume < Global.settings_dict.volume_limit:
		delay = move_toward(delay, 0, 0.5*_delta)
