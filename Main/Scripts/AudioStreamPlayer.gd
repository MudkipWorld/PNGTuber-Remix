extends AudioStreamPlayer

const MIN_DB: int = 80
var record_bus_index 
var record_effect : AudioEffectRecord

const VU_COUNT = 4
const HEIGHT = 60
const  MAX_FREQ = 11050.0
var bar_stuff = []
var used_bar = 0

var t = {
	value = 0,
	actual_value = 0,
}



var _fingerprint := LipSyncFingerprint.new()
var _matches := []
# Called when the node enters the scene tree for the first time.
func _ready():
	record_bus_index = AudioServer.get_bus_index("Mic")
	record_effect = AudioServer.get_bus_effect(record_bus_index, 0)
	await get_tree().create_timer(0.05).timeout
	global_lipsync()



func _on_mic_timer_timeout():
	playing = false
	await get_tree().create_timer(0.05).timeout
	playing = true
	$MicTimer.start()


func global_lipsync():
	_fingerprint.populate(LipSyncGlobals.speech_spectrum)

	# Calculate the matches
	LipSyncGlobals.file_data.match_phonemes(_fingerprint, _matches)

	# Populate the bars
	t = {
	value = 0,
	actual_value = 0,
	}
	
	for phoneme in Phonemes.PHONEME.COUNT:
		var deviation: float = _matches[phoneme]
		var value := 0.0 if deviation < 0.0 else 1.0 - deviation
		if get_tree().get_root().has_node("Main/LipsyncConfigurationPopup"):
			get_tree().get_root().get_node("Main/LipsyncConfigurationPopup/%PhBox").get_child(phoneme).value = value
		if value > t.value:
			t.value = value
			t.actual_value = phoneme
			
	await get_tree().create_timer(0.08).timeout
	global_lipsync()
