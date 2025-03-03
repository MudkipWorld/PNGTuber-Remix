extends Node

@onready var top_bar = get_tree().get_root().get_node("Main/%TopUI")
var ui_theme
var popup = preload("res://UI/TopUI/popup_panel.tscn").instantiate()
var save_timer : Timer = Timer.new()

@warning_ignore("integer_division")
@onready var theme_settings : Dictionary = {
	theme_id = 0,
	auto_load = false,
	save_on_exit = false,
	path = "",
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
	lipsync_file_path = OS.get_executable_path().get_base_dir() + "/DefaultTraining.tres",
}
@onready var os_path = OS.get_executable_path().get_base_dir()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		popup.popup_centered()


func save_before_closing():
	if theme_settings.save_on_exit:
		if FileAccess.file_exists(theme_settings.path) && get_tree().get_root().get_node("Main/%TopUI/TopBarInput").path == theme_settings.path:
			SaveAndLoad.save_file(theme_settings.path)
		else:
			DirAccess.make_dir_absolute(os_path + "/AutoSaves")
			SaveAndLoad.save_file(OS.get_executable_path().get_base_dir() + "/AutoSaves" + "/" + str(randi()))
		window_size_changed()
		save()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()


func save():
	var file = FileAccess
	var save_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.WRITE)
	save_file.store_var(theme_settings)
	save_file.close()

func auto_save():
	if FileAccess.file_exists(theme_settings.path) && get_tree().get_root().get_node("Main/%TopUI/TopBarInput").path == theme_settings.path:
		SaveAndLoad.save_file(theme_settings.path)
	else:
		DirAccess.make_dir_absolute(os_path + "/AutoSaves")
		SaveAndLoad.save_file(OS.get_executable_path().get_base_dir() + "/AutoSaves" + "/" + str(randi()))
	window_size_changed()
	save()
	if Global.settings_dict.auto_save:
		save_timer.start()
	

func _ready():
	save_timer.timeout.connect(auto_save)
	save_timer.one_shot = true
	add_child(save_timer)
	if !FileAccess.file_exists(OS.get_executable_path().get_base_dir() + "/DefaultTraining.tres"):
		ResourceSaver.save(preload("res://UI/Lipsync stuff/PrebuildFile/DefaultTraining.tres"),OS.get_executable_path().get_base_dir() + "/DefaultTraining.tres")
		LipSyncGlobals.file_data = ResourceLoader.load(OS.get_executable_path().get_base_dir() + "/DefaultTraining.tres")
	await  get_tree().create_timer(0.1).timeout
	top_bar = get_tree().get_root().get_node("Main/%TopUI")
	
	var file = FileAccess
	if file.file_exists(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat"):
		var load_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.READ)
		var info = load_file.get_var()
		if info is Dictionary:
			theme_settings.merge(info, true)
			
			theme_settings.theme_id = info.theme_id
			loaded_UI(theme_settings.theme_id)
			
		#	top_bar.get_node("%AutoLoadCheck").button_pressed = theme_settings.auto_load
		#	top_bar.get_node("%FpsSping").value = theme_settings.fps
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
			
			get_tree().get_root().get_node("Main/%Control/%HSplitContainer").split_offset = theme_settings.left
			get_tree().get_root().get_node("Main/%Control/%HSplit").split_offset = theme_settings.right
			get_tree().get_root().get_node("Main/%Control/%VSplitContainer").split_offset = theme_settings.properties
			
			get_window().position = theme_settings.screen_pos
			
			if theme_settings.auto_load:
				if FileAccess.file_exists(theme_settings.path):
					await get_tree().create_timer(0.1).timeout
					SaveAndLoad.load_file(theme_settings.path, true)
					
			if FileAccess.file_exists(theme_settings.lipsync_file_path):
				LipSyncGlobals.file_data = ResourceLoader.load(theme_settings.lipsync_file_path)
			else:
				LipSyncGlobals.file_data = ResourceLoader.load(OS.get_executable_path().get_base_dir() + "/DefaultTraining.tres")
			
		load_file.close()
		
	else:
		var create_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.WRITE)
		theme_settings.theme_id = 0
		create_file.store_var(theme_settings)
		create_file.close()
		get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
	get_window().size_changed.connect(window_size_changed)
	
	
	get_tree().get_root().get_node("Main/%Control/%HSplitContainer").dragged.connect(_on_h_split_container_dragged)
	get_tree().get_root().get_node("Main/%Control/%HSplit").dragged.connect(_on_h_split_dragged)
	get_tree().get_root().get_node("Main/%Control/%VSplitContainer").dragged.connect(_on_v_split_container_dragged)
	
	await get_tree().create_timer(0.05).timeout
	get_window().size = theme_settings.screen_size
	check_ui()
#	top_bar.check_data()
	top_bar.sliders_revalue(Global.settings_dict)
	add_child(popup)
	popup.hide()
	

func window_size_changed():
	theme_settings.screen_size = get_window().size
	theme_settings.screen_pos = get_window().position
	if get_window().mode == get_window().MODE_MAXIMIZED:
		theme_settings.screen_window = 1
	elif get_window().mode == get_window().MODE_MINIMIZED:
		theme_settings.screen_window = 2
	else:
		theme_settings.screen_window = 0
	
	top_bar.get_node("%WindowSize").text = "Window Size " + str(theme_settings.screen_size)
	save()

func check_ui():
	if theme_settings.mode == 0:
		top_bar.get_node("%TopBarInput").choosing_mode(0)
	else:
		top_bar.get_node("%TopBarInput").choosing_mode(1)

func loaded_UI(id):
	_on_ui_theme_button_item_selected(id)


func _on_ui_theme_button_item_selected(index):
	match index:
		0:
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
			popup.theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
			get_tree().get_root().get_node("Main/%ConfirmationDialog").theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
		1:
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
			popup.theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
			get_tree().get_root().get_node("Main/%ConfirmationDialog").theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
		2:
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
			popup.theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
			get_tree().get_root().get_node("Main/%ConfirmationDialog").theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
		3:
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
			popup.theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
			get_tree().get_root().get_node("Main/%ConfirmationDialog").theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
		4:
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
			popup.theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
			get_tree().get_root().get_node("Main/%ConfirmationDialog").theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
		5:
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/GreenTheme/Green_theme.tres")
			popup.theme = preload("res://Themes/GreenTheme/Green_theme.tres")
			get_tree().get_root().get_node("Main/%ConfirmationDialog").theme = preload("res://Themes/GreenTheme/Green_theme.tres")
		6:
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")
			popup.theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")
			get_tree().get_root().get_node("Main/%ConfirmationDialog").theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")
	theme_settings.theme_id = index
	Global.theme_update.emit(index)
	save()


func _on_auto_load_check_toggled(toggled_on):
	theme_settings.auto_load = toggled_on
	save()

func _on_save_on_exit_check_toggled(toggled_on):
	theme_settings.save_on_exit = toggled_on
	save()

func toggle_borders():
	theme_settings.borders = !theme_settings.borders
	var s = theme_settings.screen_size
	if theme_settings.borders:
		get_window().borderless = false
		get_window().size = s
	elif !theme_settings.borders:
		get_window().borderless = true
		get_window().size = s
	save()


@warning_ignore("integer_division")
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_borders"):
		toggle_borders()
	
	if Input.is_action_just_pressed("center_screen"):
		var i = DisplayServer.window_get_current_screen()
		var ds = DisplayServer.screen_get_size(i)
		get_window().position = DisplayServer.screen_get_position(i) + Vector2i(ds.x/2- get_window().size.x/2,ds.y/2- get_window().size.y/2)
		window_size_changed()


func _on_h_split_container_dragged(offset: int) -> void:
	theme_settings.left = offset
	save()


func _on_h_split_dragged(offset: int) -> void:
	theme_settings.right = offset
	save()


func _on_v_split_container_dragged(offset: int) -> void:
	theme_settings.properties = offset
	save()
