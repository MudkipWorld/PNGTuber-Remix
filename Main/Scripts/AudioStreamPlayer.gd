extends AudioStreamPlayer

const MIN_DB: int = 80
var record_bus_index 

const VU_COUNT = 4
const HEIGHT = 40
const  MAX_FREQ = 11050.0
const MIC_RESTART_TIME: float = 30
const MIC_RESTART_TIME_FIX: float = 15
var bar_stuff = []
var used_bar = 0

var t = {
	value = 0,
	actual_value = 0,
}

var actual_value : float = 0.0
var mic_restart_timer : Timer = Timer.new()
var _fingerprint := LipSyncFingerprint.new()
var _matches := []

func _ready():
	await get_tree().current_scene.ready
	global_lipsync()

func global_lipsync():
	_fingerprint.populate(LipSyncGlobals.speech_spectrum)
	if LipSyncGlobals.file_data:
		
		LipSyncGlobals.file_data.match_phonemes({description = _fingerprint.description, values = _fingerprint.values}, _matches)
	t = {
	value = 0,
	actual_value = 0,
	}
	for phoneme in Phonemes.PHONEME.COUNT:
		var deviation: float = _matches[phoneme]
		var value = 0.0
		if deviation > 0.0:
			value = 1.0 - deviation
		
		if get_tree().get_root().has_node("Main/LipsyncConfigurationPopup"):
			get_tree().get_root().get_node("Main/LipsyncConfigurationPopup/%PhBox").get_child(phoneme).value = value
			
			
		if value > t.value:
			t.value = value
			actual_value = phoneme
			t.actual_value = actual_value


	await get_tree().create_timer(0.1).timeout
	global_lipsync()
