extends Window

enum FileType {
	
	Load,
	Save,
	
}

var current : FileType = FileType.Load

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	theme = get_parent().get_node("UIHolder").theme
	close_requested.connect(close)
	%Shapes.stop()
	%Shapes.frame = 13
	%FilesButton.get_popup().id_pressed.connect(item_selected)

func item_selected(id : int):
	print(id)
	match id:
		0:
			LipSyncGlobals.new_file()
		1:
			%FileDialog.file_mode = 0
			%FileDialog.ok_button_text = "Load"
			%FileDialog.title = "Load LipSync File"
			current = FileType.Load
			%FileDialog.show()
		2:
			%FileDialog.file_mode = 4
			%FileDialog.ok_button_text = "Save"
			%FileDialog.title = "Save LipSync File"
			current = FileType.Save
			%FileDialog.show()


func close():
	queue_free()


func _on_file_dialog_file_selected(path: String) -> void:
	if current == FileType.Load:
		LipSyncGlobals.load_file(path)
	elif current == FileType.Save:
		LipSyncGlobals.save_file_as(path)


func _on_file_dialog_confirmed() -> void:
	if current == FileType.Save:
		LipSyncGlobals.save_file_as(%FileDialog.current_path)
	
