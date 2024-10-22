extends TabBar



var _fingerprint := LipSyncFingerprint.new()

var hist_max := 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	# Populate the fingerprint
	_fingerprint.populate(LipSyncGlobals.speech_spectrum)

	# Get scale to normalize volume
	var max_value: float = _fingerprint.values.max()
	hist_max *= 1 - delta
	hist_max = max(hist_max, max_value)
	
	var max_scale = 1.0 / hist_max
	#var max_scale = 0.1

	for i in LipSyncFingerprint.BANDS_COUNT:
		var bar: ProgressBar = %SpecBars.get_child(i)
		bar.value = _fingerprint.values[i] * max_scale
