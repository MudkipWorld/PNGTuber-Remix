extends Node


var theme_settings : Dictionary = {
	theme_id = 0,
	auto_load = false,
	path = "",
	
	
}

func save():
	var file = FileAccess
	var save_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.WRITE)
	save_file.store_var(theme_settings)
	save_file.close()
	print("saved")

# Called when the node enters the scene tree for the first time.
func _ready():
	%UIThemeButton.add_item("Purple", 0)
	%UIThemeButton.add_item("Blue", 1)
	%UIThemeButton.add_item("Orange", 2)
	%UIThemeButton.add_item("White", 3)
	%UIThemeButton.add_item("Dark (Wip)", 4)
	%UIThemeButton.add_item("Green", 5)
	%UIThemeButton.add_item("Funky", 6)
	
	print(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat")
	var file = FileAccess
	if file.file_exists(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat"):
		var load_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.READ)
		var info = load_file.get_var()
		if info is Dictionary:
			theme_settings.merge(info, true)
			print(theme_settings)
			theme_settings.theme_id = info.theme_id
			loaded_UI(theme_settings.theme_id)
			
			%AutoLoadCheck.button_pressed = theme_settings.auto_load
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
			%UIThemeButton.text = "Dark (Wip)"
			dark_theme()
		5:
			%UIThemeButton.text = "Green"
			green_theme()
		6:
			%UIThemeButton.text = "Funky"
			funky_theme()

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
			%UIThemeButton.text = "Dark (Wip)"
			dark_theme()
		5:
			%UIThemeButton.text = "Green"
			green_theme()
		6:
			%UIThemeButton.text = "Funky"
			funky_theme()
	theme_settings.theme_id = index
	save()

func blue_theme():
	get_parent().theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
	%Panelt.self_modulate = Color.LIGHT_BLUE
	%Paneln.self_modulate = Color.LIGHT_BLUE
	%Panel.self_modulate = Color.LIGHT_BLUE
	%Panel2.self_modulate = Color.LIGHT_BLUE
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
	%Panel.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Panel2.self_modulate = Color(0.898, 0.796, 0.996, 1 )
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
	%Panel.self_modulate = Color.ORANGE
	%Panel2.self_modulate = Color.ORANGE
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
	%Panel.self_modulate = Color.WHITE
	%Panel2.self_modulate = Color.WHITE
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
	%Panel.self_modulate = Color.WEB_GRAY
	%Panel2.self_modulate = Color.WEB_GRAY
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
	%Panel.self_modulate = Color.LIGHT_GREEN
	%Panel2.self_modulate = Color.LIGHT_GREEN
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
	%Panel.self_modulate = Color.SKY_BLUE
	%Panel2.self_modulate = Color.SKY_BLUE
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
