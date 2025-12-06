extends Node

var devices : Array = []
var change_setting : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%UIThemeButton.item_selected.connect(Settings._on_ui_theme_button_item_selected)
	%UIThemeButton.select(Settings.theme_settings.theme_id)
	%MicroPhoneMenu.get_popup().connect("id_pressed",choosing_device)
	for i in %LanguageOptions.item_count:
		if %LanguageOptions.get_item_text(i) == Settings.theme_settings.language:
			%LanguageOptions.select(i)
			break
			

	get_parent().close_requested.connect(close)
	sliders_revalue(Global.settings_dict)
	devices = AudioServer.get_input_device_list()
	
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

func close():
	get_parent().queue_free()

func check_data():
	change_setting = false
	%AutoLoadCheck.button_pressed = Settings.theme_settings.auto_load
	%SaveOnExitCheck.button_pressed = Settings.theme_settings.save_on_exit
	%AutoSaveCheck.button_pressed = Global.settings_dict.auto_save
	%ImportTrim.button_pressed = Settings.theme_settings.enable_trimmer
	
	%UIScalingSpinBox.value = Settings.theme_settings.ui_scaling
	%UIScalingSlider.value = Settings.theme_settings.ui_scaling
	%CustomCursorEditor.button_pressed = Settings.theme_settings.custom_cursor_editor
	%CustomCursorPreview.button_pressed = Settings.theme_settings.custom_cursor_preview
	%FloatyPanning.button_pressed = Settings.theme_settings.floaty_panning
	#%UseThreads.button_pressed = Settings.theme_settings.use_threading
	%KeepOldTrimData.button_pressed = Settings.theme_settings.save_raw_sprite
	%SaveUnusedImages.button_pressed = Settings.theme_settings.save_unused_files
	
	match Settings.theme_settings.audio_capturer:
		0:
			%AudioBackendOption.select(0)
		2:
			%AudioBackendOption.select(1)
	
	
	if OS.has_feature("linux"):
		%BackendOption.set_item_disabled(3, false)
	else:
		%BackendOption.set_item_disabled(3, true)
		%BackendOption.select(0)
	
	if OS.has_feature("windows"):
		%BackendOption.set_item_disabled(2, false)
	else:
		%BackendOption.set_item_disabled(2, true)
		%BackendOption.select(0)
		
		
	match Settings.theme_settings.backend_type:
		"default":
			%BackendOption.select(0)
		"uiohook":
			%BackendOption.select(1)
		"windows":
			if OS.has_feature("windows"):
				%BackendOption.select(2)
			else:
				%BackendOption.set_item_disabled(2, true)
				%BackendOption.select(0)
		"x11":
			if OS.has_feature("linux"):
				%BackendOption.select(3)
			else:
				%BackendOption.set_item_disabled(3, true)
				%BackendOption.select(0)
	
	
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
	%MaxFPSlider.value = settings_dict.max_fps
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
		if AudioServer.get_input_device_list().has(devices[id]):
			AudioServer.input_device = devices[id]
			Settings.theme_settings.microphone = devices[id]
			Settings.save()
	else:
		reset_mic_list()

func _on_reset_mic_button_pressed():
	reset_mic_list()

func reset_mic_list():
	%MicroPhoneMenu.get_popup().clear()
	devices = AudioServer.get_input_device_list()
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

func _on_max_fp_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		%MaxFPSLabel.text = "Max FPS : " + str(%MaxFPSlider.value)
		Global.settings_dict.max_fps = %MaxFPSlider.value
		Global.top_ui.update_fps(%MaxFPSlider.value)

func _on_max_fp_slider_value_changed(value: float) -> void:
	%MaxFPSLabel.text = "Max FPS : " + str(value)

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
		%UIScalingSlider.value = value
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

func _on_fix_mic_delay_toggled(toggled_on: bool) -> void:
	GlobalAudioStreamPlayer.change_mic_restart_time(toggled_on)

func _on_use_threads_toggled(_toggled_on: bool) -> void:
	if !change_setting: return
	Settings.theme_settings.use_threading = false
	Settings.save()

func _on_keep_old_trim_data_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.save_raw_sprite = toggled_on
	Settings.save()

func _on_remix_language_set(index: int) -> void:
	Global.set_language(%LanguageOptions.get_item_text(index))

func _on_out_of_bounds_toggled(toggled_on: bool) -> void:
	Global.settings_dict.snap_out_of_bounds = toggled_on

func _on_fix_mic_delay_pressed() -> void:
	GlobalAudioStreamPlayer.mic_restart_timer_timeout()

func _on_save_unused_images_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.save_unused_files = toggled_on
	Settings.save()

func _on_backend_option_item_selected(index: int) -> void:
	match index:
		0:
			Settings.theme_settings.backend_type = "default"
		1:
			Settings.theme_settings.backend_type = "uiohook"
		2:
			Settings.theme_settings.backend_type = "windows"
		3:
			Settings.theme_settings.backend_type = "x11"
			
			
	Settings.save()
	Settings.update_tracking_backend()

func _on_audio_backend_option_item_selected(index: int) -> void:
	match index:
		0:
			await GlobalAudioStreamPlayer.mic_restart_timer_timeout()
			Settings.theme_settings.audio_capturer = 0
			GlobalAudioStreamPlayer.record_effect = AudioServer.get_bus_effect(GlobalAudioStreamPlayer.record_bus_index, Settings.theme_settings.get("audio_capturer", 0))
			AudioServer.set_bus_effect_enabled(GlobalAudioStreamPlayer.record_bus_index, 0, true)
			AudioServer.set_bus_effect_enabled(GlobalAudioStreamPlayer.record_bus_index, 2, false)
			await GlobalAudioStreamPlayer.mic_restart_timer_timeout()
			Settings.save()
		1:
			await GlobalAudioStreamPlayer.mic_restart_timer_timeout()
			Settings.theme_settings.audio_capturer = 2
			GlobalAudioStreamPlayer.record_effect = AudioServer.get_bus_effect(GlobalAudioStreamPlayer.record_bus_index, Settings.theme_settings.get("audio_capturer", 2))
			AudioServer.set_bus_effect_enabled(GlobalAudioStreamPlayer.record_bus_index, 0, false)
			AudioServer.set_bus_effect_enabled(GlobalAudioStreamPlayer.record_bus_index, 2, true)
			await GlobalAudioStreamPlayer.mic_restart_timer_timeout()
			Settings.save()
