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



func _on_mic_timer_timeout():
	playing = false
	await get_tree().create_timer(0.05).timeout
	playing = true
	$MicTimer.start()
