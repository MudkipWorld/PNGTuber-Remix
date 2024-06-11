extends AudioStreamPlayer

const MIN_DB: int = 80
var record_bus_index 
var record_effect : AudioEffectRecord

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance

const VU_COUNT = 4
const HEIGHT = 60
const  MAX_FREQ = 11050.0
var bar_stuff = []
var used_bar = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	record_bus_index = AudioServer.get_bus_index("Mic")
	record_effect = AudioServer.get_bus_effect(record_bus_index, 0)
	spectrum_analyzer = AudioServer.get_bus_effect_instance(record_bus_index, 2)


func _process(_delta):
	var prev_hz = 0
	bar_stuff = []
	for i in range(1, VU_COUNT + 1):
		var hz = i * MAX_FREQ/ VU_COUNT
		var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(prev_hz,hz)
		var energy = linear_to_db(magnitude.length())
		var height = clamp(energy + HEIGHT, 0, 1000)
		
		prev_hz = hz
		
		bar_stuff.append(height)
	used_bar = bar_stuff
#	print(bar_stuff)
	

func _on_mic_timer_timeout():
	playing = false
	await get_tree().create_timer(0.05).timeout
	playing = true
	$MicTimer.start()
