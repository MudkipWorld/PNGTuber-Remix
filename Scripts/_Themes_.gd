extends Node

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
	%UIThemeButton.add_item("Purple", 0)
	%UIThemeButton.add_item("Blue", 1)
	%UIThemeButton.add_item("Orange", 2)
	%UIThemeButton.add_item("White", 3)
	%UIThemeButton.add_item("Dark", 4)
	%UIThemeButton.add_item("Green", 5)
	%UIThemeButton.add_item("Funky", 6)
	
	var file = FileAccess
	if file.file_exists(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat"):
		var load_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.READ)
		var info = load_file.get_var()
		if info is Dictionary:
			theme_settings.merge(info, true)
			theme_settings.theme_id = info.theme_id
			loaded_UI(theme_settings.theme_id)
			
			%AutoLoadCheck.button_pressed = theme_settings.auto_load
			%FpsSping.value = theme_settings.fps
			if theme_settings.as_apng:
				%TopBarInput._on_file_type_item_selected(1)
				%FileType.select(1)
			else:
				%TopBarInput._on_file_type_item_selected(0)
				%FileType.select(0)
			
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
			
			get_window().position = theme_settings.screen_pos
			get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").frames_per_second = theme_settings.fps
			
			if theme_settings.auto_load:
				if FileAccess.file_exists(theme_settings.path):
					await get_tree().create_timer(0.02).timeout
					SaveAndLoad.load_file(theme_settings.path)
			
		load_file.close()
		
	else:
		var create_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.WRITE)
		theme_settings.theme_id = 0
		create_file.store_var(theme_settings)
		create_file.close()
		purple_theme()
	%SaveOnExitCheck.button_pressed = theme_settings.save_on_exit
	
	
	get_window().size_changed.connect(window_size_changed)
	await get_tree().create_timer(0.05).timeout
	get_window().size = theme_settings.screen_size
	check_ui()

func window_size_changed():
	theme_settings.screen_size = get_window().size
	theme_settings.screen_pos = get_window().position
	if get_window().mode == get_window().MODE_MAXIMIZED:
		theme_settings.screen_window = 1
	elif get_window().mode == get_window().MODE_MINIMIZED:
		theme_settings.screen_window = 2
	else:
		theme_settings.screen_window = 0
	save()

func check_ui():
	if theme_settings.mode == 0:
		%TopBarInput.choosing_mode(0)
	else:
		%TopBarInput.choosing_mode(1)

func loaded_UI(id):
	match id:
		0:
			%UIThemeButton.text = "Purple"
			purple_theme()
		1:
			%UIThemeButton.text = "Blue"
			blue_theme()
		2:
			%UIThemeButton.text = "Orange"
			orange_theme()
		3:
			%UIThemeButton.text = "White"
			white_theme()
		4:
			%UIThemeButton.text = "Dark"
			dark_theme()
		5:
			%UIThemeButton.text = "Green"
			green_theme()
		6:
			%UIThemeButton.text = "Funky"
			funky_theme()
	%UIThemeButton.select(id)

func _on_ui_theme_button_item_selected(index):
	match index:
		0:
			%UIThemeButton.text = "Purple"
			purple_theme()
		1:
			%UIThemeButton.text = "Blue"
			blue_theme()
		2:
			%UIThemeButton.text = "Orange"
			orange_theme()
		3:
			%UIThemeButton.text = "White"
			white_theme()
		4:
			%UIThemeButton.text = "Dark"
			dark_theme()
		5:
			%UIThemeButton.text = "Green"
			green_theme()
		6:
			%UIThemeButton.text = "Funky"
			funky_theme()
	theme_settings.theme_id = index
	%UIThemeButton.select(index)
	save()

func blue_theme():
	get_parent().theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
	%Panelt.self_modulate = Color.LIGHT_BLUE
	%Paneln.self_modulate = Color.LIGHT_BLUE
	%PanelL1_2.self_modulate = Color.LIGHT_BLUE
	%PanelL2_2.self_modulate = Color.LIGHT_BLUE
	%Properties.self_modulate = Color.LIGHT_BLUE
	%LayersButtons.modulate = Color.AQUA
	%LayersButtons2.modulate = Color.AQUA
	%ViewportCam.modulate = Color.AQUA
	%ResetMicButton.modulate = Color.AQUA
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	%TopBar.self_modulate = Color.WHITE

func purple_theme():
	get_parent().theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
	%Panelt.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Paneln.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%PanelL1_2.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%PanelL2_2.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Properties.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%LayersButtons.modulate = Color(0.898, 0.796, 0.996, 1 )
	%LayersButtons2.modulate = Color(0.898, 0.796, 0.996, 1 )
	%ViewportCam.modulate = Color(0.898, 0.796, 0.996, 1 )
	%ResetMicButton.modulate = Color(0.898, 0.796, 0.996, 1 )
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	%TopBar.self_modulate = Color.WHITE

func orange_theme():
	get_parent().theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
	%Panelt.self_modulate = Color.ORANGE
	%Paneln.self_modulate = Color.ORANGE
	%PanelL1_2.self_modulate = Color.ORANGE
	%PanelL2_2.self_modulate = Color.ORANGE
	%Properties.self_modulate = Color.ORANGE
	%LayersButtons.modulate = Color.ORANGE
	%LayersButtons2.modulate = Color.ORANGE
	%ViewportCam.modulate = Color.ORANGE
	%ResetMicButton.modulate = Color.ORANGE
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	%TopBar.self_modulate = Color.WHITE

func white_theme():
	get_parent().theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
	%Panelt.self_modulate = Color.WHITE
	%Paneln.self_modulate = Color.WHITE
	%PanelL1_2.self_modulate = Color.WHITE
	%PanelL2_2.self_modulate = Color.WHITE
	%Properties.self_modulate = Color.WHITE
	%LayersButtons.modulate = Color.WHITE
	%LayersButtons2.modulate = Color.WHITE
	%ViewportCam.modulate = Color.WHITE
	%ResetMicButton.modulate = Color.WHITE
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	%TopBar.self_modulate = Color.WHITE

func dark_theme():
	get_parent().theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
	%Panelt.self_modulate = Color.WEB_GRAY
	%Paneln.self_modulate = Color.WEB_GRAY
	%PanelL1_2.self_modulate = Color.WEB_GRAY
	%PanelL2_2.self_modulate = Color.WEB_GRAY
	%Properties.self_modulate = Color.WEB_GRAY
	%LayersButtons.modulate = Color.DIM_GRAY
	%LayersButtons2.modulate = Color.DIM_GRAY
	%ViewportCam.modulate = Color.DIM_GRAY
	%ResetMicButton.modulate = Color.DIM_GRAY
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	%TopBar.self_modulate = Color.WHITE

func green_theme():
	get_parent().theme = preload("res://Themes/GreenTheme/Green_theme.tres")
	%Panelt.self_modulate = Color.LIGHT_GREEN
	%Paneln.self_modulate = Color.LIGHT_GREEN
	%PanelL1_2.self_modulate = Color.LIGHT_GREEN
	%PanelL2_2.self_modulate = Color.LIGHT_GREEN
	%Properties.self_modulate = Color.LIGHT_GREEN
	%LayersButtons.modulate = Color.LIGHT_GREEN
	%LayersButtons2.modulate = Color.LIGHT_GREEN
	%ViewportCam.modulate = Color.LIGHT_GREEN
	%ResetMicButton.modulate = Color.LIGHT_GREEN
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	%TopBar.self_modulate = Color.WHITE

func funky_theme():
	get_parent().theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")
	%Panelt.self_modulate = Color.SKY_BLUE
	%Paneln.self_modulate = Color.SKY_BLUE
	%PanelL1_2.self_modulate = Color.SKY_BLUE
	%PanelL2_2.self_modulate = Color.SKY_BLUE
	%Properties.self_modulate = Color.MEDIUM_SEA_GREEN
	%LayersButtons.modulate = Color.SKY_BLUE
	%LayersButtons2.modulate = Color.SKY_BLUE
	%ViewportCam.modulate = Color.SKY_BLUE
	%ResetMicButton.modulate = Color.SKY_BLUE
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	%TopBar.self_modulate = Color.WHITE

func _on_auto_load_check_toggled(toggled_on):
	theme_settings.auto_load = toggled_on
	save()

func _on_save_on_exit_check_toggled(toggled_on):
	theme_settings.save_on_exit = toggled_on
	save()

func _on_fps_sping_value_changed(value):
	theme_settings.fps = value
	get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").frames_per_second = value
	%FpsSping.release_focus()
	%FpsSping.get_line_edit().release_focus()
	save()

func toggle_borders():
	theme_settings.borders = !theme_settings.borders
	if theme_settings.borders:
		get_window().borderless = false
	elif !theme_settings.borders:
		get_window().borderless = true
	save()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_borders"):
		toggle_borders()
