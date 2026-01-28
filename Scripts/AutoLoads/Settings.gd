extends Node

signal theme_changed
signal file_error

var top_bar = null
var ui_theme
var save_timer : Timer = Timer.new()
var current_theme : Theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
const SAVED_LAYOUT_PATH := "user://layout.tres"

@warning_ignore("integer_division")
@onready var theme_settings : Dictionary = {
	theme_id = 0,
	auto_load = false,
	path = "",
	save_on_exit = false,
	fps = 24,
	as_apng = false,
	screen_size = Vector2(1152, 648),
	screen_pos = Vector2i(DisplayServer.screen_get_size(0).x/2- get_window().size.x/2,DisplayServer.screen_get_size(0).y/2- get_window().size.y/2),
	screen_window = 0,
	mode = 0,
	borders = true,
	
	right = 2500,
	left = -2000,
	properties = 0,
	layers = -100,
	file_manager = 0,
	lipsync_file_path = path_helper(OS.get_executable_path().get_base_dir(), "/DefaultTraining.tres"),
	microphone = null,
	enable_trimmer = false,
	save_raw_sprite = true, #save the original sprite even when trimmed
	always_on_top = false,
	menu_popup = true,
	software_mode = 0,
	ui_scaling = 1.0,
	session = 0,
	auto_activate_websocket = false,
	websocket_id = 9321,
	custom_cursor_editor = true,
	custom_cursor_preview = true,
	custom_cursor_path = "",
	floaty_panning = true,
	hide_mini_view = false,
	hide_sprite_view = true,
	hide_bottom_bar = true,
	use_threading = false,
	language = "automatic",
	save_unused_files = false,
	backend_type = "default",
	audio_capturer = 2,
	osf_pos_stren = 10,
	osf_mouth_strength = -0.05,
	phys_tick_per_frame = 60,
	phys_steps = 10,
	phys_jitter = 0.5,
	dev_mode = false,
}
var save_location = ""
var autosave_location = ""
var websocket_api = ""

func _enter_tree() -> void:
	save_location = path_helper(OS.get_executable_path().get_base_dir(), "/Preferences.pRDat")
	autosave_location = path_helper(OS.get_executable_path().get_base_dir(), "/autosaves")
	websocket_api = path_helper(OS.get_executable_path().get_base_dir(), "/WebsocketDocumentation.txt")

func save_before_closing():
	if theme_settings.save_on_exit:
		if FileAccess.file_exists(Global.save_path):
			SaveAndLoad.save_file(Global.save_path)
		else:
			DirAccess.make_dir_absolute(autosave_location)
			SaveAndLoad.save_file(autosave_location + "/" + str(randi()))
		window_size_changed()
	await save()
	get_tree().quit()

func save():
	var save_file = FileAccess.open(save_location, FileAccess.WRITE)
	save_file.store_var(theme_settings.duplicate(true))
	save_file.close()

func auto_save():
	if FileAccess.file_exists(Global.save_path):
		SaveAndLoad.save_file(Global.save_path)
	else:
		DirAccess.make_dir_absolute(autosave_location)
		SaveAndLoad.save_file(autosave_location + "/" + str(randi()))
	window_size_changed()
	save()
	if Global.settings_dict.auto_save:
		save_timer.start()

func _ready():
	save_timer.timeout.connect(auto_save)
	save_timer.one_shot = true
	add_child(save_timer)
	await  get_tree().create_timer(0.1).timeout
	if get_tree().get_root().has_node("Main/%TopUI"):
		top_bar = get_tree().get_root().get_node("Main/%TopUI")
	if !FileAccess.file_exists(websocket_api):
		var save_data = FileAccess.open(websocket_api, FileAccess.WRITE)
		save_data.store_string(WebsocketDoc.doc)
		save_data.close()

	if FileAccess.file_exists(save_location):
		var load_file = FileAccess.open(save_location, FileAccess.READ)
		var info = load_file.get_var()
		if info is Dictionary:
			theme_settings.merge(info, true)
			
			theme_settings.theme_id = info.theme_id
			loaded_UI(theme_settings.theme_id)
			
			if theme_settings.screen_window == 0:
				get_window().mode = get_window().MODE_WINDOWED
			elif theme_settings.screen_window == 1:
				get_window().mode = get_window().MODE_MAXIMIZED
			elif theme_settings.screen_window == 2:
				get_window().mode = get_window().MODE_MINIMIZED
			
			
			if theme_settings.borders:
				get_window().borderless = false
			elif !theme_settings.borders:
				get_window().borderless = true
			get_window().always_on_top = theme_settings.always_on_top
			
			get_window().position = theme_settings.screen_pos
			
			
		load_file.close()
		
	else:
		var create_file = FileAccess.open(save_location, FileAccess.WRITE)
		theme_settings.theme_id = 0
		if (create_file):
			create_file.store_var(theme_settings)
			create_file.close()
		else:
			push_error(FileAccess.get_open_error())
			file_error.emit("INITIAL_SAVE_ERROR", FileAccess.get_open_error())
		loaded_UI(theme_settings.theme_id)
	
	get_window().size_changed.connect(window_size_changed)
	
	await get_tree().create_timer(0.05).timeout
	get_window().size = Settings.theme_settings.screen_size
	check_ui()
#	top_bar.check_data()

	if top_bar != null && is_instance_valid(top_bar):
		top_bar.sliders_revalue(Global.settings_dict)
	scale_window()
	lipsync_set_up()
	if theme_settings.microphone != null:
		if AudioServer.get_input_device_list().has(theme_settings.microphone):
			AudioServer.input_device = theme_settings.microphone
	
	change_cursor()
	# Load language
	var locale = Util.get_locale(theme_settings.language)
	if locale == "automatic":
		TranslationServer.set_locale(OS.get_locale_language())
	else:
		TranslationServer.set_locale(locale)
	Engine.physics_jitter_fix = theme_settings.phys_jitter
	Engine.physics_ticks_per_second = theme_settings.phys_tick_per_frame
	Engine.max_physics_steps_per_frame = theme_settings.phys_steps
	Global.dev_mode.emit(theme_settings.dev_mode)


func update_tracking_backend():
	match theme_settings.backend_type:
		"default":
			set_backed_default()
		"uiohook":
			GlobInput.backend = "uiohook"
		"windows":
			if OS.has_feature("windows"):
				GlobInput.backend = "windows"
			else:
				set_backed_default()
		"x11":
			if OS.has_feature("linux"):
				GlobInput.backend = "x11"
			else:
				set_backed_default()

func set_backed_default():
	if OS.has_feature("windows"):
		GlobInput.backend = "windows"
	elif OS.has_feature("linux"):
		GlobInput.backend = "x11"
	else:
		GlobInput.backend = "uiohook"

func lipsync_set_up():
	var parent_path = Util.get_parent_path(save_location);
	if parent_path != save_location:
		theme_settings.lipsync_file_path = parent_path + "/DefaultTraining.tres"
	else:
		file_error.emit("INVALID_LIP_SYNC_PATH")
	if !FileAccess.file_exists(theme_settings.lipsync_file_path):
		LipSyncGlobals.file_data = preload("res://UI/Lipsync stuff/DefaultTraining.tres")
		LipSyncGlobals.save_file_as(theme_settings.lipsync_file_path)
		
		save()
	else:
		LipSyncGlobals.load_file(theme_settings.lipsync_file_path)

func scale_window():
	get_tree().root.content_scale_factor = theme_settings.ui_scaling

func window_size_changed():
	Settings.theme_settings.screen_size = get_window().size
	Settings.theme_settings.screen_pos = get_window().position
	if get_window().mode == get_window().MODE_MAXIMIZED:
		Settings.theme_settings.screen_window = 1
	elif get_window().mode == get_window().MODE_MINIMIZED:
		Settings.theme_settings.screen_window = 2
	else:
		Settings.theme_settings.screen_window = 0
		
	if Global.main != null && is_instance_valid(Global.main):
		if Global.main.has_node("%WindowSize"):
			Global.main.get_node("%WindowSize").text = "Window Size " + str(Settings.theme_settings.screen_size)
	save()

func check_ui():
	if top_bar != null && is_instance_valid(top_bar):
		if Settings.theme_settings.mode == 0:
			top_bar.get_node("%TopBarInput").choosing_mode(0)
		else:
			top_bar.get_node("%TopBarInput").choosing_mode(1)

func loaded_UI(id):
	_on_ui_theme_button_item_selected(id)

func _on_ui_theme_button_item_selected(index):
	match index:
		0:
			current_theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
		1:
			current_theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
		2:
			current_theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
		3:
			current_theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
		4:
			current_theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
		5:
			current_theme = preload("res://Themes/GreenTheme/Green_theme.tres")
		6:
			current_theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")
		7:
			current_theme = preload("res://Themes/FrutigerAeroTheme/FrutigerAero.tres")
	
	Settings.theme_settings.theme_id = index
	Global.theme_update.emit(current_theme)
	save()

func _on_auto_load_check_toggled(toggled_on):
	Settings.theme_settings.auto_load = toggled_on
	save()

func _on_save_on_exit_check_toggled(toggled_on):
	Settings.theme_settings.save_on_exit = toggled_on
	save()

func toggle_borders():
	Settings.theme_settings.borders = !Settings.theme_settings.borders
	var s = Settings.theme_settings.screen_size
	if Settings.theme_settings.borders:
		get_window().borderless = false
		get_window().size = s
	elif !Settings.theme_settings.borders:
		get_window().borderless = true
		get_window().size = s
	save()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_borders"):
		toggle_borders()
	
	if Input.is_action_just_pressed("center_screen"):
		center_window()

@warning_ignore("integer_division")
func center_window():
	var i = DisplayServer.window_get_current_screen()
	var ds = DisplayServer.screen_get_size(i)
	get_window().position = DisplayServer.screen_get_position(i) + Vector2i(ds.x/2- get_window().size.x/2,ds.y/2- get_window().size.y/2)
	window_size_changed()

func set_always_on_top(toggle):
	Settings.theme_settings.always_on_top = toggle
	get_window().always_on_top = Settings.theme_settings.always_on_top
	save()

func get_custom_cursor() -> Image:
	var cursor := (preload("res://Misc/TestAssets/PicklesCursor.png") as Texture2D).get_image()
	if theme_settings.custom_cursor_path.is_empty(): return cursor
	if !FileAccess.file_exists(theme_settings.custom_cursor_path): return cursor
	var loaded := Image.load_from_file(theme_settings.custom_cursor_path)
	if loaded.get_height() > 256: return cursor
	if loaded.get_width() > 256: return cursor
	if !is_instance_valid(loaded): return cursor
	return loaded

func should_use_custom_cursor() -> bool:
	if Global.is_editor:
		return theme_settings.custom_cursor_editor
	else:
		return theme_settings.custom_cursor_preview

func change_cursor():
	if should_use_custom_cursor():
		Input.set_custom_mouse_cursor(get_custom_cursor())
	else:
		Input.set_custom_mouse_cursor(null)

func set_ui_pieces(val : int, id : int):
	if id == 5:
		theme_settings.hide_mini_view = val
	elif id == 6:
		theme_settings.hide_sprite_view = val
	elif 7:
		theme_settings.hide_bottom_bar = val
	save()

func path_helper(path, dir: String = "") -> String:
	var target = ""
	var current = DirAccess.open(path)
	if current == null:
		target = OS.get_user_data_dir() + dir
	else:
		target = path + dir
	
	return target
