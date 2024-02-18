extends AudioStreamPlayer

const MIN_DB: int = 80
var record_bus_index 
var record_effect : AudioEffectRecord

var sensitivity_limit = 1
var volume_limit = 1
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance

# Called when the node enters the scene tree for the first time.
func _ready():
	record_bus_index = AudioServer.get_bus_index("Mic")
	record_effect = AudioServer.get_bus_effect(record_bus_index, 0)
	spectrum_analyzer = AudioServer.get_bus_effect_instance(record_bus_index, 2)


'''
func _process(_delta):
	# Get the strength of the 0 - 200hz range of audio
	var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(
		0,
		200
	).length()

	# Boost the signal and normalize it
	var energy = clamp((MIN_DB + linear_to_db(magnitude))/MIN_DB, 0, 1)
'''
