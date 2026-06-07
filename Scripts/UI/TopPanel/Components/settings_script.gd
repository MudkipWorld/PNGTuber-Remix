extends Node

var devices : Array = []
var change_setting : bool = false
var counter : int = 0

func _ready() -> void:
	%UIThemeButton.item_selected.connect(Settings._on_ui_theme_button_item_selected)
	%UIThemeButton.select(Settings.theme_settings.theme_id)
	%MicroPhoneMenu.get_popup().connect("id_pressed",choosing_device)
	_populate_languages()
	LanguageManager.language_changed.connect(_on_language_changed)
	get_parent().close_requested.connect(close)
	sliders_revalue(Global.settings_dict)
	devices = GlobalMicAudio.mic_input.get_device_names()
	for i in devices:
		%MicroPhoneMenu.get_popup().add_item(i)
		if i == Settings.theme_settings.microphone:
			%MicroPhoneMenu.select(devices.find(i))
	%SelectedScreen.add_item("All Screens")
	for i in DisplayServer.get_screen_count():
		%SelectedScreen.add_item("Screen " + str(i))
	if Global.settings_dict.monitor == Monitor.ALL_SCREENS:
		%SelectedScreen.select(0)
	else:
		if %SelectedScreen.item_count > Global.settings_dict.monitor:
			%SelectedScreen.select(Global.settings_dict.monitor + 1)
		else:
			Global.settings_dict.monitor = Monitor.ALL_SCREENS
			%SelectedScreen.select(0)
	check_data()

func _populate_languages() -> void:
	%LanguageOptions.clear()
	var selected_index := 0
	for index in LanguageManager.available_languages.size():
		var locale_code: String = LanguageManager.available_languages[index]
		%LanguageOptions.add_item(LanguageManager.get_display_name(locale_code))
		if locale_code == LanguageManager.get_current_locale():
			selected_index = index
	%LanguageOptions.select(selected_index)

func _on_remix_language_set(index: int) -> void:
	if index < 0 or index >= LanguageManager.available_languages.size():
		return
	LanguageManager.set_language(LanguageManager.available_languages[index])
	
func _on_language_changed(_locale: String) -> void:
	_populate_languages()

func close():
	get_parent().queue_free()

func check_data():
	change_setting = false
	%AutoLoadCheck.button_pressed = Settings.theme_settings.auto_load
	%SaveOnExitCheck.button_pressed = Settings.theme_settings.save_on_exit
	%AutoSaveCheck.button_pressed = Global.settings_dict.auto_save
	%ImportTrim.button_pressed = Settings.theme_settings.enable_trimmer
	%UIScalingSpinBox.value = Settings.theme_settings.ui_scaling
	%CustomCursorEditor.button_pressed = Settings.theme_settings.custom_cursor_editor
	%CustomCursorPreview.button_pressed = Settings.theme_settings.custom_cursor_preview
	%FloatyPanning.button_pressed = Settings.theme_settings.floaty_panning
	#%UseThreads.button_pressed = Settings.theme_settings.use_threading
	%KeepOldTrimData.button_pressed = Settings.theme_settings.save_raw_sprite
	%SaveUnusedImages.button_pressed = Settings.theme_settings.save_unused_files
	%PhysicsTick.value = Settings.theme_settings.phys_tick_per_frame
	%PhysicsSteps.value = Settings.theme_settings.phys_steps
	%JitterFix.value = Settings.theme_settings.phys_jitter
	%DevMode.button_pressed = Settings.theme_settings.dev_mode
	%FollowMouseGlobalInput.button_pressed = Settings.theme_settings.use_glob_input

	if OS.has_feature("linux"):
		%BackendOption.set_item_disabled(1, false)
	else:
		%BackendOption.set_item_disabled(0, true)
		%BackendOption.select(2)

	if OS.has_feature("windows"):
		%BackendOption.set_item_disabled(0, false)
	else:
		%BackendOption.set_item_disabled(1, true)
		%BackendOption.select(2)

	match Settings.theme_settings.backend_type:
		"windows":
			if OS.has_feature("windows"):
				%BackendOption.select(0)
			else:
				%BackendOption.set_item_disabled(0, true)
				%BackendOption.select(2)
		"x11":
			if OS.has_feature("linux"):
				%BackendOption.select(1)
			else:
				%BackendOption.set_item_disabled(1, true)
				%BackendOption.select(2)
		"dummy":
			%BackendOption.select(2)
		_:
			%BackendOption.select(2)

	change_setting = true

func _physics_process(_delta):
	%VolumeBar.value = GlobalMicAudio.volume
	%DelayBar.value = GlobalMicAudio.delay

func sliders_revalue(settings_dict):
	%InputCheckButton.button_pressed = settings_dict.checkinput
	%VolumeSlider.value = settings_dict.volume_limit
	%SensitivitySlider.value = settings_dict.sensitivity_limit
	%AntiAlCheck.button_pressed = settings_dict.anti_alias
#	$TopBarInput.origin_alias()
	%AutoSaveCheck.button_pressed = settings_dict.auto_save
	%AutoSaveSpin.value = settings_dict.auto_save_timer
	%DelaySlider.value = settings_dict.volume_delay
	%DeltaTimeCheck.button_pressed = settings_dict.should_delta
	#%MaxFPSlider.value = settings_dict.max_fps
	match_fps(settings_dict.max_fps)
	
	%OutOfBounds.button_pressed = settings_dict.snap_out_of_bounds

func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Global.settings_dict.volume_limit = %VolumeSlider.value

func _on_delay_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Global.settings_dict.volume_delay = %DelaySlider.value

func _on_sensitivity_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Global.settings_dict.sensitivity_limit = %SensitivitySlider.value

func _on_sensitivity_slider_value_changed(value: float) -> void:
	%SensitivityBar.value = value

func _on_auto_load_check_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.auto_load = toggled_on
	Settings.save()

func _on_save_on_exit_check_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.save_on_exit = toggled_on
	Settings.save()

func _on_delta_time_check_toggled(toggled_on: bool) -> void:
	Global.settings_dict.should_delta = toggled_on

func _on_auto_save_spin_value_changed(value):
	Settings.save_timer.wait_time = value * 60
	Global.settings_dict.auto_save_timer = value

func choosing_device(id):
	if id != null:
		if GlobalMicAudio.mic_input.get_device_names().has(devices[id]):
			GlobalMicAudio.mic_input.set_microphone(id)
			GlobalMicAudio.mic_input.start_audio()
			Settings.theme_settings.microphone = devices[id]
			Settings.save()
	else:
		reset_mic_list()

func _on_reset_mic_button_pressed():
	reset_mic_list()

func reset_mic_list():
	%MicroPhoneMenu.get_popup().clear()
	devices = GlobalMicAudio.mic_input.get_device_names()
	for i in devices:
		%MicroPhoneMenu.get_popup().add_item(i)
	choosing_device(0)

func _on_anti_al_check_toggled(toggled_on):
	Global.settings_dict.anti_alias = toggled_on
	if toggled_on:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS

func _on_input_check_button_toggled(toggled_on):
	Global.settings_dict.checkinput = toggled_on

func _on_auto_save_check_toggled(toggled_on):
	Global.settings_dict.auto_save = toggled_on
	if toggled_on:
		Settings.save_timer.start()
	else:
		Settings.save_timer.stop()

func _on_import_trim_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.enable_trimmer = toggled_on
	Settings.save()

func _on_selected_screen_item_selected(index: int) -> void:
	if index == 0:
		Global.main.get_node("%Marker").current_screen = Monitor.ALL_SCREENS
	else:
		Global.main.get_node("%Marker").current_screen = index - 1
	Global.settings_dict.monitor = Global.main.get_node("%Marker").current_screen
	print(Global.settings_dict.monitor)

func _on_ui_scaling_slider_value_changed(value: float) -> void:
	if change_setting:
		Settings.theme_settings.ui_scaling = value
		Settings.scale_window()
		Settings.save()
		%UIScalingSpinBox.value = value
		get_parent().move_to_center()

func _on_ui_scaling_spin_box_value_changed(value: float) -> void:
	if change_setting:
		Settings.theme_settings.ui_scaling = value
		Settings.scale_window()
		Settings.save()
		get_parent().move_to_center()

func cursor_changed():
	Settings.change_cursor()
	Settings.save()

func _on_custom_cursor_editor_toggled(toggled_on: bool) -> void:
	if !change_setting: return
	Settings.theme_settings.custom_cursor_editor = toggled_on
	cursor_changed()
	Settings.save()

func _on_custom_cursor_preview_toggled(toggled_on: bool) -> void:
	if !change_setting: return
	Settings.theme_settings.custom_cursor_preview = toggled_on
	cursor_changed()
	Settings.save()

func _on_select_cursor_file_selected(path: String) -> void:
	if !change_setting: return
	Settings.theme_settings.custom_cursor_path = path
	cursor_changed()
	Settings.save()

func _on_remove_custom_cursor_pressed() -> void:
	if !change_setting: return
	Settings.theme_settings.custom_cursor_path = ""
	cursor_changed()
	Settings.save()

func _on_floaty_panning_toggled(toggled_on: bool) -> void:
	if !change_setting: return
	Settings.theme_settings.floaty_panning = toggled_on
	Settings.save()
	Global.update_camera_smoothing()

func _on_use_threads_toggled(_toggled_on: bool) -> void:
	if !change_setting: return
	Settings.theme_settings.use_threading = false
	Settings.save()

func _on_keep_old_trim_data_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.save_raw_sprite = toggled_on
	Settings.save()

func _on_out_of_bounds_toggled(toggled_on: bool) -> void:
	Global.settings_dict.snap_out_of_bounds = toggled_on

func _on_save_unused_images_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.save_unused_files = toggled_on
	Settings.save()

func _on_backend_option_item_selected(index: int) -> void:
	match index:
		0:
			Settings.theme_settings.backend_type = "windows"
		1:
			Settings.theme_settings.backend_type = "x11"
		2:
			Settings.theme_settings.backend_type = "dummy"
	Settings.save()
	Settings.update_tracking_backend()

func _on_physics_tick_value_changed(value: float) -> void:
	if !change_setting: return
	Settings.theme_settings.phys_tick_per_frame = value
	Engine.physics_ticks_per_second = int(value)
	Settings.save()

func _on_physics_steps_value_changed(value: float) -> void:
	if !change_setting: return
	Settings.theme_settings.phys_steps = value
	Engine.max_physics_steps_per_frame = int(value)
	Settings.save()

func _on_jitter_fix_drag_ended(value_changed: bool) -> void:
	if !change_setting: return
	if !value_changed: return
	Settings.theme_settings.phys_jitter = %JitterFix.value
	Engine.physics_jitter_fix = %JitterFix.value
	Settings.save()

func _on_pickles_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb"):
		counter += 1
		check_dev_mode()

func check_dev_mode():
	if counter >= 10:
		%DevMode.show()
		%DevWarning.show()

func _on_dev_mode_toggled(toggled_on: bool) -> void:
	if change_setting:
		Settings.theme_settings.dev_mode = toggled_on
		Global.dev_mode.emit(Settings.theme_settings.dev_mode)
		Settings.save()

func _on_follow_mouse_global_input_toggled(toggled_on: bool) -> void:
	if change_setting:
		Settings.theme_settings.use_glob_input = toggled_on
		Settings.save()

func _on_max_fps_item_selected(index: int) -> void:
	match index:
		0:
			Global.settings_dict.max_fps = 8
		1:
			Global.settings_dict.max_fps = 10
		2:
			Global.settings_dict.max_fps = 12
		3:
			Global.settings_dict.max_fps = 15
		4:
			Global.settings_dict.max_fps = 30
		5:
			Global.settings_dict.max_fps = 60
		6:
			Global.settings_dict.max_fps = 90
		7:
			Global.settings_dict.max_fps = 120
		8:
			Global.settings_dict.max_fps = 240
	
	Engine.max_fps = Global.settings_dict.max_fps

func match_fps(fps):
	match fps:
		8:
			%MaxFPS.select(0)
		10:
			%MaxFPS.select(1)
		12:
			%MaxFPS.select(2)
		15:
			%MaxFPS.select(3)
		30:
			%MaxFPS.select(4)
		60:
			%MaxFPS.select(5)
		90:
			%MaxFPS.select(6)
		120:
			%MaxFPS.select(7)
		240:
			%MaxFPS.select(8)
		0:
			Global.settings_dict.max_fps = 240
			Engine.max_fps = Global.settings_dict.max_fps
			%MaxFPS.select(8)
		_:
			Global.settings_dict.max_fps = 60
			Engine.max_fps = Global.settings_dict.max_fps
			%MaxFPS.select(5)
