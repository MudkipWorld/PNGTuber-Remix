class_name CalibrationTree
extends Tree


# Button IDs
const BUTTON_ADD := 1
const BUTTON_RECORD := 2
const BUTTON_DELETE := 3



# Viseme descriptions
const viseme_descriptions = {
	Visemes.VISEME.VISEME_TH: "Viseme TH",
	Visemes.VISEME.VISEME_DD: "Viseme DD",
	Visemes.VISEME.VISEME_E: "Viseme E",
	Visemes.VISEME.VISEME_FF: "Viseme FF",
	Visemes.VISEME.VISEME_I: "Viseme I",
	Visemes.VISEME.VISEME_O: "Viseme O",
	Visemes.VISEME.VISEME_PP: "Viseme PP",
	Visemes.VISEME.VISEME_RR: "Viseme RR",
	Visemes.VISEME.VISEME_SS: "Viseme SS",
	Visemes.VISEME.VISEME_U: "Viseme U",
	Visemes.VISEME.VISEME_AA: "Viseme AA",
	Visemes.VISEME.VISEME_G: "Viseme G",
	Visemes.VISEME.VISEME_L: "Viseme L",
}

# Phoneme descriptions
const phoneme_descriptions = {
	Phonemes.PHONEME.PHONEME_TS: "Phoneme [tS] (CHeck, CHoose)",
	Phonemes.PHONEME.PHONEME_S:  "Phoneme [s] (Sir, See, Seem)",
	Phonemes.PHONEME.PHONEME_T:  "Phoneme [t] (Take, haT)",

	Phonemes.PHONEME.PHONEME_E:  "Phoneme [e] (Ever, bEd)",

	Phonemes.PHONEME.PHONEME_V:  "Phoneme [v] (Van, Vest)",
	Phonemes.PHONEME.PHONEME_I:  "Phoneme [I] (fIx, offIce, kIt)",
	Phonemes.PHONEME.PHONEME_O:  "Phoneme [O] (Otter, stOp, nOt)",

	Phonemes.PHONEME.PHONEME_B:  "Phoneme [b] (Bat, tuBe, Bed)",

	Phonemes.PHONEME.PHONEME_R:  "Phoneme [r] (Red, fRom, Ram)",


	Phonemes.PHONEME.PHONEME_OU: "Phoneme [u] (tOO, feW, bOOm)",
	Phonemes.PHONEME.PHONEME_A:  "Phoneme [A] (cAr, Art, fAther)",

	Phonemes.PHONEME.PHONEME_G:  "Phoneme [g] (Gas, aGo, Game)",

	Phonemes.PHONEME.PHONEME_L:  "Phoneme [l] (Lot, chiLd, Lay)",
}


# Icons for buttons
@onready var delete_icon = load("res://UI/Lipsync stuff/Icons/delete.png")
@onready var microphone_icon = load("res://UI/Lipsync stuff/Icons/microphone.png")
@onready var plus_icon = load("res://UI/Lipsync stuff/Icons/plus.png")


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the file data changed event
	LipSyncGlobals.connect("file_data_changed", Callable(self, "_on_file_data_changed"))
	
	# Connect the button-pressed event
	button_clicked.connect(_on_button_pressed)
	item_edited.connect(_on_item_edited)

	# Configure the columns
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_custom_minimum_width(1, 60)

	# Populate the tree
	_populate_tree()


## Handle button presses
func _on_button_pressed(item: TreeItem, _column: int, id: int, _mouse):
	match id:
		BUTTON_ADD:
			_on_add_fingerprint(item)
		
		BUTTON_RECORD:
			_on_record_fingerprint(item)
			
		BUTTON_DELETE:
			_on_delete_fingerprint(item)


## Handle item edited
func _on_item_edited():
	_on_fingerprint_edited(get_edited())


## Handle add button pressed on phoneme node
func _on_add_fingerprint(phoneme_node: TreeItem):
	# Get the viseme/phoneme
	var viseme: int = phoneme_node.get_metadata(0)[0]
	var phoneme: int = phoneme_node.get_metadata(0)[1]

	# Construct the fingerprint from the current audio spectrum
	var fingerprint := LipSyncFingerprint.new()
	fingerprint.description = "unnamed"
	fingerprint.populate(LipSyncGlobals.speech_spectrum)

	# If necessary, construct phoneme entry in training data
	if not phoneme in LipSyncGlobals.file_data.training:
		LipSyncGlobals.file_data.training[phoneme] = []

	# Add fingerprint to training data
	LipSyncGlobals.file_data.training[phoneme].push_back(fingerprint)

	# Create the new node
	var fingerprint_node = create_item(phoneme_node)
	fingerprint_node.set_text(0, fingerprint.description)
	fingerprint_node.add_button(1, microphone_icon, BUTTON_RECORD)
	fingerprint_node.add_button(1, delete_icon, BUTTON_DELETE)
	fingerprint_node.set_editable(0, true)
	fingerprint_node.set_metadata(0, [viseme, phoneme])
	fingerprint_node.set_metadata(1, fingerprint)

	# Report modified by tree manipulation
	LipSyncGlobals.set_modified("tree")

	# Select the new fingerprint
	fingerprint_node.select(0)


## Handle record button pressed on fingerprint node
func _on_record_fingerprint(fingerprint_node: TreeItem):
	# Get the phoneme and fingerprint
#	var phoneme: int = fingerprint_node.get_metadata(0)[1]
	var fingerprint: LipSyncFingerprint = fingerprint_node.get_metadata(1)

	# Update the fingerprint from the current audio spectrum
	fingerprint.populate(LipSyncGlobals.speech_spectrum)

	# Report modified by tree manipulation
	LipSyncGlobals.set_modified("tree")

	# Select the updated fingerprint
	fingerprint_node.select(0)


## Handle delete button pressed on fingerprint node
func _on_delete_fingerprint(fingerprint_node: TreeItem):
	# Get the phoneme and fingerprint
	var phoneme: int = fingerprint_node.get_metadata(0)[1]
	var fingerprint: LipSyncFingerprint = fingerprint_node.get_metadata(1)

	# Get the array of fingerprints in the training data
	var fingerprints: Array = LipSyncGlobals.file_data.training[phoneme]

	# Erase the fingerprint (and possibly the entire phoneme)
	fingerprints.erase(fingerprint)
	if fingerprints.size() == 0:
		LipSyncGlobals.file_data.training.erase(phoneme)

	# Delete the node
	fingerprint_node.free()

	# Report modified by tree manipulation
	LipSyncGlobals.set_modified("tree")


func _on_fingerprint_edited(fingerprint_node: TreeItem):
	# Get the fingerprint
	var fingerprint: LipSyncFingerprint = fingerprint_node.get_metadata(1)

	# Get the description
	var description = fingerprint_node.get_text(0)
	if description == "":
		# Fix empty descriptions
		description = "unnamed"
		fingerprint_node.set_text(0, description)

	# Save the description
	fingerprint.description = description

	# Report modified by tree manipulation
	LipSyncGlobals.set_modified("tree")


## Handle changes to the file data
func _on_file_data_changed(cause):
	# Skip if change came from us or the inspector
	if cause == "tree" or cause == "inspector":
		return

	# Update the tree to show the change
	_populate_tree()


## Populate the tree
func _populate_tree():
	# Clear the tree
	clear()

	# Create the root item
	var root = create_item()

	# Iterate over all possible visemes:
	for viseme in Visemes.VISEME.COUNT:
		# Skip visemes without descriptions
		if not viseme in viseme_descriptions:
			continue

		# Construct the viseme node
		var viseme_node = create_item(root, viseme)
		viseme_node.set_text(0, viseme_descriptions[viseme])
		viseme_node.set_metadata(0, [viseme, -1])

		# Iterate over phonemes in viseme
		for phoneme in Visemes.VISEME_PHONEME_MAP[viseme]:
			# Skip undocumented phonemes
			if not phoneme in phoneme_descriptions:
				continue

			# Construct the phoneme node
			var phoneme_node = create_item(viseme_node, phoneme)
			phoneme_node.set_text(0, phoneme_descriptions[phoneme])
			phoneme_node.add_button(1, plus_icon, BUTTON_ADD)
			phoneme_node.set_metadata(0, [viseme, phoneme])

			# Skip if no fingerprints in training data
			if not phoneme in LipSyncGlobals.file_data.training:
				continue

			# Add all fingerprints
			for fingerprint in LipSyncGlobals.file_data.training[phoneme]:
				var fingerprint_node = create_item(phoneme_node)
				fingerprint_node.set_text(0, fingerprint.description)
				fingerprint_node.add_button(1, microphone_icon, BUTTON_RECORD)
				fingerprint_node.add_button(1, delete_icon, BUTTON_DELETE)
				fingerprint_node.set_editable(0, true)
				fingerprint_node.set_metadata(0, [viseme, phoneme])
				fingerprint_node.set_metadata(1, fingerprint)
