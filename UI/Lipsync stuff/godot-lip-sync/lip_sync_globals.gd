extends Node


## Signal emitted when the file state changes (update main window)
signal file_state_changed()

## Signal emitted when the file data changes (update controls
signal file_data_changed(cause)


## Training file name
var file_name := ""

## Training file modified
var file_modified := false

## Training file data
var file_data := LipSyncTraining.new()

## Speech audio bus
var speech_bus : int

## Speech spectrum analyzer
var speech_spectrum: AudioEffectSpectrumAnalyzerInstance

func _ready() -> void:
	speech_spectrum = AudioServer.get_bus_effect_instance(2, 2)

## Report the training data has been modified
func set_modified(cause):
	# Report the data changed
	emit_signal("file_data_changed", cause)

	# Report the state changed (to modified)
	if not file_modified:
		file_modified = true
		emit_signal("file_state_changed")


## Switch to a new training file
func new_file():
	# Clear the data
	file_name = ""
	file_data = LipSyncTraining.new()
	file_modified = false

	# Report changes
	emit_signal("file_state_changed")
	emit_signal("file_data_changed", "new")


## Load a training data file
func load_file(path: String):
	# Load the data
	file_name = path
	file_data = ResourceLoader.load(path)
	file_modified = false

	# Report file changed
	emit_signal("file_state_changed")
	emit_signal("file_data_changed", "load")


## Save the training data file to the current file-name
func save_file():
	# Save the resource
	ResourceSaver.save(file_data, file_name)
	
	file_modified = false

	# Report file changed
	emit_signal("file_state_changed")


## Save the training data file to a new file-name
func save_file_as(path: String):
	# Set the file name and save
	file_name = path
	save_file()


## Get the user display name for the training data
func file_display_name() -> String:
		# Pick a display name
	var display_name := "unnamed" if file_name == "" else file_name

	# Add modified flag
	if file_modified:
		display_name = "*" + display_name

	# Return the display name
	return display_name
