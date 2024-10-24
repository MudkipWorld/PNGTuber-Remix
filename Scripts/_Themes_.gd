extends Node

@onready var top_bar = get_tree().get_root().get_node("Main/%TopUI")
var ui_theme


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

func _exit_tree():
	if theme_settings.save_on_exit:
		if FileAccess.file_exists(theme_settings.path):
			SaveAndLoad.save_file(theme_settings.path)
		else:
			DirAccess.make_dir_absolute(os_path + "/AutoSaves")
			
			SaveAndLoad.save_file(OS.get_executable_path().get_base_dir() + "/AutoSaves" + "/" + str(randi()))
		window_size_changed()
		save()

func save():
	var file = FileAccess
	var save_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.WRITE)
	save_file.store_var(theme_settings)
	save_file.close()

func _ready():
	if !FileAccess.file_exists(OS.get_executable_path().get_base_dir() + "/DefaultTraining.tres"):
		ResourceSaver.save(preload("res://UI/Lipsync stuff/DefaultLipsync.tres"),OS.get_executable_path().get_base_dir() + "/DefaultTraining.tres")
	await  get_tree().create_timer(0.1).timeout
	ui_theme = get_tree().get_root().get_node("Main/%TopUI/%UIThemeButton")
	top_bar = get_tree().get_root().get_node("Main/%TopUI")
	
	ui_theme.item_selected.connect(_on_ui_theme_button_item_selected)
	var file = FileAccess
	if file.file_exists(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat"):
		var load_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.READ)
		var info = load_file.get_var()
		if info is Dictionary:
			theme_settings.merge(info, true)
			
			theme_settings.theme_id = info.theme_id
			loaded_UI(theme_settings.theme_id)
			
			top_bar.get_node("%AutoLoadCheck").button_pressed = theme_settings.auto_load
			top_bar.get_node("%FpsSping").value = theme_settings.fps
			if theme_settings.as_apng:
				top_bar.get_node("%TopBarInput")._on_file_type_item_selected(1)
				top_bar.get_node("%FileType").select(1)
			else:
				top_bar.get_node("%TopBarInput")._on_file_type_item_selected(0)
				top_bar.get_node("%FileType").select(0)
			
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
			get_tree().get_root().get_node("Main/%Control/%LayersViewSplit").split_offset = theme_settings.layers
			
			get_window().position = theme_settings.screen_pos
			get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").frames_per_second = theme_settings.fps
			
			if theme_settings.auto_load:
				if FileAccess.file_exists(theme_settings.path):
					await get_tree().create_timer(0.02).timeout
					SaveAndLoad.load_file(theme_settings.path)
					
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
	top_bar.get_node("%SaveOnExitCheck").button_pressed = theme_settings.save_on_exit
	
	
	get_window().size_changed.connect(window_size_changed)
	
	
	get_tree().get_root().get_node("Main/%Control/%HSplitContainer").dragged.connect(_on_h_split_container_dragged)
	get_tree().get_root().get_node("Main/%Control/%HSplit").dragged.connect(_on_h_split_dragged)
	get_tree().get_root().get_node("Main/%Control/%VSplitContainer").dragged.connect(_on_v_split_container_dragged)
	get_tree().get_root().get_node("Main/%Control/%LayersViewSplit").dragged.connect(_on_layers_view_split_dragged)
	
	
	
	await get_tree().create_timer(0.05).timeout
	get_window().size = theme_settings.screen_size
	check_ui()
	top_bar.get_node("%WindowSize").text = "Window Size " + str(theme_settings.screen_size)


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
	match id:
		0:
			ui_theme.text = "Purple"
		1:
			ui_theme.text = "Blue"
		2:
			ui_theme.text = "Orange"
		3:
			ui_theme.text = "White"
		4:
			ui_theme.text = "Dark"
		5:
			ui_theme.text = "Green"
		6:
			ui_theme.text = "Funky"
	_on_ui_theme_button_item_selected(id)
	

func _on_ui_theme_button_item_selected(index):
	match index:
		0:
			ui_theme.text = "Purple"
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
		1:
			ui_theme.text = "Blue"
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
		2:
			ui_theme.text = "Orange"
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
		3:
			ui_theme.text = "White"
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
		4:
			ui_theme.text = "Dark"
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
		5:
			ui_theme.text = "Green"
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/GreenTheme/Green_theme.tres")
		6:
			ui_theme.text = "Funky"
			get_tree().get_root().get_node("Main/UIHolder").theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")
	theme_settings.theme_id = index
	ui_theme.select(index)
	Global.theme_update.emit(index)
	save()


func _on_auto_load_check_toggled(toggled_on):
	theme_settings.auto_load = toggled_on
	save()

func _on_save_on_exit_check_toggled(toggled_on):
	theme_settings.save_on_exit = toggled_on
	save()

func _on_fps_sping_value_changed(value):
	theme_settings.fps = value
	get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").frames_per_second = value
	top_bar.get_node("%FpsSping").release_focus()
	top_bar.get_node("%FpsSping").get_line_edit().release_focus()
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
		var ds = DisplayServer.screen_get_size(0)
		get_window().position = Vector2i(ds.x/2- get_window().size.x/2,ds.y/2- get_window().size.y/2)
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


func _on_layers_view_split_dragged(offset: int) -> void:
	theme_settings.layers = offset
	save()
