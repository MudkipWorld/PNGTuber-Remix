extends AcceptDialog

@export var container : Node

var editor_mode = preload("res://Main/main.tscn")
var streamer_mode = preload("res://Main/main_stream.tscn")
var current_mode : int = 0 

func _ready() -> void:
	Global.theme_update.connect(update_theme)
	close_requested.connect(close)
	confirmed.connect(close)

func _on_editor_mode_pressed() -> void:
	if current_mode != 0:
		save_between_sessions()
		await get_tree().physics_frame
		Global.delete_states.emit()
		if WebsocketHandler.is_working:
			WebsocketHandler.stop()
		for i in container.get_children():
			i.queue_free()
		
		container.add_child(editor_mode.instantiate())
		Themes.theme_settings.session = 0
		Themes.save()
		current_mode = 0
		auto_load_model()


func _on_steamer_mode_pressed() -> void:
	if current_mode != 1:
		save_between_sessions()
		await get_tree().physics_frame
		Global.delete_states.emit()
		for i in container.get_children():
			i.queue_free()
		container.add_child(streamer_mode.instantiate())
		Themes.theme_settings.session = 1
		Themes.save()
		current_mode = 1
		auto_load_model()


func auto_load_model():
	if Themes.theme_settings.auto_load:
		if FileAccess.file_exists(Themes.theme_settings.path):
			await get_tree().create_timer(0.15).timeout
			SaveAndLoad.load_file(Themes.theme_settings.path, false)


func save_between_sessions():
	if Themes.theme_settings.session == 0:
		if FileAccess.file_exists(Themes.theme_settings.path) && Global.top_ui.get_node("%TopBarInput").path == Themes.theme_settings.path:
			SaveAndLoad.save_file(Themes.theme_settings.path)
		else:
			DirAccess.make_dir_absolute(Themes.os_path + "/AutoSaves")
			SaveAndLoad.save_file(Global.save_dir + "/AutoSaves" + "/" + str(randi()))
	elif Themes.theme_settings.session == 1:
		if FileAccess.file_exists(Themes.theme_settings.path):
			SaveAndLoad.save_file(Themes.theme_settings.path)
		else:
			DirAccess.make_dir_absolute(Themes.os_path + "/AutoSaves")
			SaveAndLoad.save_file(Global.save_dir + "/AutoSaves" + "/" + str(randi()))



func update_theme(new_theme : Theme = preload("res://Themes/PurpleTheme/GUITheme.tres")):
	theme = new_theme

func close():
	hide()
