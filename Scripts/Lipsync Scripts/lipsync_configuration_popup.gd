extends Window

enum FileType {
	Load,
	Save,
}

var current: FileType = FileType.Load


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	theme = Global.main.get_node("%UIHolder").theme
	close_requested.connect(close)
	%Shapes.stop()
	%Shapes.frame = 13
	%FilesButton.get_popup().id_pressed.connect(item_selected)


func item_selected(id: int):
	match id:
		0:
			LipSyncGlobals.new_file()
		1:
			%FileDialog.file_mode = 0
			%FileDialog.ok_button_text = "TR_LOAD"
			%FileDialog.title = "TR_LOAD_LIPSYNC_FILE"
			current = FileType.Load
			%FileDialog.show()
		2:
			%FileDialog.file_mode = 4
			%FileDialog.ok_button_text = "TR_SAVE"
			%FileDialog.title = "TR_SAVE_LIPSYNC_FILE"
			current = FileType.Save
			%FileDialog.show()


func close():
	queue_free()


func _on_file_dialog_file_selected(path: String) -> void:
	if current == FileType.Load:
		LipSyncGlobals.load_file(path)
		Settings.theme_settings.lipsync_file_path = path
		Settings.save()
	elif current == FileType.Save:
		LipSyncGlobals.save_file_as(path)
		Settings.theme_settings.lipsync_file_path = path
		Settings.save()


func _on_file_dialog_confirmed() -> void:
	if current == FileType.Save:
		LipSyncGlobals.save_file_as(%FileDialog.current_path)
		Settings.theme_settings.lipsync_file_path = %FileDialog.current_path
		Settings.save()
