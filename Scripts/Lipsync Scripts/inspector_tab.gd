extends HBoxContainer

const VISEME_DESCRIPTIONS := {
Visemes.VISEME.VISEME_DD: "Viseme DD",
Visemes.VISEME.VISEME_E: "Viseme E",
Visemes.VISEME.VISEME_FF: "Viseme FF",
Visemes.VISEME.VISEME_I: "Viseme I",
Visemes.VISEME.VISEME_O: "Viseme O",
Visemes.VISEME.VISEME_PP: "Viseme PP",
Visemes.VISEME.VISEME_RR: "Viseme RR",
Visemes.VISEME.VISEME_SS: "Viseme SS",
Visemes.VISEME.VISEME_TH: "Viseme TH",
Visemes.VISEME.VISEME_U: "Viseme U",
Visemes.VISEME.VISEME_AA: "Viseme aa",
Visemes.VISEME.VISEME_G: "Viseme kk",
Visemes.VISEME.VISEME_L: "Viseme nn",
}

## Description of phonemes
const PHONEME_DESCRIPTIONS := {
## Description of the [tS] phoneme.
Phonemes.PHONEME.PHONEME_TS: 
"""Voiceless postalveolar affricate [tS]

This phoneme is the CH sound in CHeck, CHoose, beaCH, and marCH.""",


## Description of the [t] phoneme.
Phonemes.PHONEME.PHONEME_T:
"""Voiceless alveolar plosive [t]

This phoneme is the T sound in Take, haT, and sTew.

Note: Plosive (stop) phonemes are difficult to record.""",

## Description of the [e] phoneme.
Phonemes.PHONEME.PHONEME_E:
"""Close-mid front unrounded vowel [e]

This phoneme is the E sound in Ever and bEd.""",

## Description of the [v] phoneme.
Phonemes.PHONEME.PHONEME_V:
"""Voiced labiodental fricative [v]

This phoneme is the V sound in Van and Vest.""",

## Description of the [I] phoneme.
Phonemes.PHONEME.PHONEME_I:
"""Near-close front unrounded vowel [I]

This phoneme is the I sound in fIx, offIce, and kIt.""",

## Description of the [O] phoneme.
Phonemes.PHONEME.PHONEME_O:
"""Open-mid back rounded vowel [O]

This phoneme is the O sound in Otter, stOp, and nOt.""",


## Description of the [b] phoneme.
Phonemes.PHONEME.PHONEME_B:
"""Voiced bilabial plosive [b]

This phoneme is the B sound in Bat, tuBe, and Bed.

Note: Plosive (stop) phonemes are difficult to record.""",

## Description of the [r] phoneme.
Phonemes.PHONEME.PHONEME_R:
"""Alveolar trill [r]

This phoneme is the R sound in Red, fRom, and Ram.""",

## Description of the [s] phoneme.
Phonemes.PHONEME.PHONEME_S:
"""Voiceless alveolar fricative [s]

This phoneme is the S sound in Sir, See, and Seem.""",


## Description of the [u] phoneme.
Phonemes.PHONEME.PHONEME_OU:
"""Close back rounded vowel [u]

This phoneme is the OU sound in tOO, feW, and bOOm.""",

## Description of the [A] phoneme.
Phonemes.PHONEME.PHONEME_A:
"""Open back unrounded vowel [A]

This phoneme is the A sound in cAr, Art, and fAther.""",


## Description of the [g] phoneme.
Phonemes.PHONEME.PHONEME_G:
"""Voiced velar plosive [g]

This phoneme is the G sound in Gas, aGo, and Game.

Note: Plosive (stop) phonemes are difficult to record.""",


## Description of the [l] phoneme.
Phonemes.PHONEME.PHONEME_L:
"""Alveolar lateral approximant [l]

This phoneme is the L sound in Lot, chiLd, and Lay.""",
}


## Calibration tree path
@export var calibration_tree: NodePath


## Currently selected viseme
var _selected_viseme: int

## Calibration tree node
@onready var _calibration_tree: CalibrationTree = get_node(calibration_tree)


# Called when the node enters the scene tree for the first time.
func _ready():
	_calibration_tree.connect("item_selected", Callable(self, "_on_CalibrationTree_item_selected"))
	LipSyncGlobals.connect("file_data_changed", Callable(self, "_on_file_data_changed"))



func _on_CalibrationTree_item_selected():
	_update_inspector()


func _on_file_data_changed(_cause):
	if _cause != "inspector":
		_update_inspector()


func _on_weight_slider_value_changed(value: float):
	LipSyncGlobals.file_data.weights[_selected_viseme] = value
	LipSyncGlobals.set_modified("inspector")


func _update_inspector():
	# Get the selected item
	var item: TreeItem = _calibration_tree.get_selected()
	if not item:
		return

	# Get the phoneme and possibly fingerprint
#	var viseme: int = item.get_metadata(0)[0]
#	var phoneme: int = item.get_metadata(0)[1]
	var fingerprint: LipSyncFingerprint = item.get_metadata(1)

	# Ensure the description is hidden

	# Populate selected item
	if fingerprint:
		# Hide other inspectors

		# Get scale to normalize volume
		var max_value: float = fingerprint.values.max()
		var max_scale = 0.0 if max_value <= 0.0 else 1.0 / max_value

		# Populate bars
		for i in LipSyncFingerprint.BANDS_COUNT:
			var bar: ProgressBar = get_child(i)
			bar.value = fingerprint.values[i] * max_scale


'''
		# Show fingerprint bars
		$FingerprintBars.visible = true
	elif phoneme >= 0:
		# Hide other inspectors
		$VisemeContainer.visible = false
		$FingerprintBars.visible = false

		# Set the text
		$PhonemeDescription.text = PHONEME_DESCRIPTIONS[phoneme]

		# Show phoneme description
		$PhonemeDescription.visible = true
	else:
		# Hide other inspectors
		$PhonemeDescription.visible = false
		$FingerprintBars.visible = false

		# Set the text and weight
		$VisemeContainer/VisemeDescription.text = VISEME_DESCRIPTIONS[viseme]

		# Set the selected viseme weight
		_selected_viseme = viseme
		var value := 0.0
		if viseme in LipSyncGlobals.file_data.weights:
			value = LipSyncGlobals.file_data.weights[viseme]
		$VisemeContainer/HBoxContainer/WeightSlider.value = value

		# Show viseme description
		$VisemeContainer.visible = true
'''
