extends Control

func _ready() -> void:
	Global.swtich_session_popup = %MenuScreenPopup
	await get_tree().create_timer(0.1).timeout
	#init_switch_session()
	auto_load_model()
	GlobInput.start_hook()
	Settings.update_tracking_backend()

func init_switch_session():
	if Settings.theme_settings.session == 1:
		Global.new_file.emit()
		for i in %Scene.get_children():
			i.queue_free()
		%Scene.add_child(%MenuScreenPopup.streamer_mode.instantiate())

func auto_load_model():
	if Settings.theme_settings.auto_load:
		if FileAccess.file_exists(Settings.theme_settings.path):
			await get_tree().create_timer(0.1).timeout
			SaveAndLoad.load_file(Settings.theme_settings.path)
		elif not Settings.theme_settings.path.is_empty():
			var warning := AcceptDialog.new()
			warning.theme = Settings.current_theme
			warning.title = tr("TR_AUTO_LOAD_MODEL")
			warning.dialog_text = tr("TR_AUTO_LOAD_MODEL_MISSING") % Settings.theme_settings.path
			warning.dialog_autowrap = true
			warning.confirmed.connect(warning.queue_free)
			warning.canceled.connect(warning.queue_free)
			add_child(warning)
			warning.popup_centered(Vector2i(540, 180))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GlobInput.stop_hook()
		get_tree().quit()
		OS.kill(OS.get_process_id())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		if Global.save_path:
			SaveAndLoad.save_file(Global.save_path)
		else:
			Global.main.save_as_file()
	if event.is_action_pressed("desel"):
		Global.deselect.emit()
