extends Control

func _ready() -> void:
	Global.swtich_session_popup = %MenuScreenPopup
	await get_tree().create_timer(0.1).timeout
	init_switch_session()
	auto_load_model()

func init_switch_session():
	if Settings.theme_settings.session == 1:
		%MenuScreenPopup.current_mode = 1
		Global.delete_states.emit()
		for i in %Scene.get_children():
			i.queue_free()
		%Scene.add_child(%MenuScreenPopup.streamer_mode.instantiate())

func auto_load_model():
	if Settings.theme_settings.auto_load:
		if FileAccess.file_exists(Settings.theme_settings.path):
			await get_tree().create_timer(0.1).timeout
			SaveAndLoad.load_file(Settings.theme_settings.path)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		OS.kill(OS.get_process_id())
