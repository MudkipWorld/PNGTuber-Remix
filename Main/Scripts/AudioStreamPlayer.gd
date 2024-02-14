extends AudioStreamPlayer

var record_bus_index 
var record_effect : AudioEffectRecord

var sensitivity_limit = 1
var volume_limit = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	record_bus_index = AudioServer.get_bus_index("Mic")
	record_effect = AudioServer.get_bus_effect(record_bus_index, 0)
	
