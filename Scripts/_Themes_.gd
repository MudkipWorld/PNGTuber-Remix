extends Node

var theme_id : int 

func save():
	var file = FileAccess
	var save_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.WRITE)
	save_file.store_var(theme_id)
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
	
	print(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat")
	var file = FileAccess
	if file.file_exists(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat"):
		var load_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.READ)
		theme_id = load_file.get_var()
		loaded_UI(theme_id)
		print(theme_id)
		load_file.close()
		
	else:
		var create_file = file.open(OS.get_executable_path().get_base_dir() + "/Preferences.pRDat", FileAccess.WRITE)
		theme_id = 0
		create_file.store_var(theme_id)
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
	theme_id = index
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
	get_parent().theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
	%Panelt.self_modulate = Color.WEB_GRAY
	%Paneln.self_modulate = Color.WEB_GRAY
	%Panel.self_modulate = Color.WEB_GRAY
	%Panel2.self_modulate = Color.WEB_GRAY
	%Properties.self_modulate = Color.WEB_GRAY
	%LayersButtons.modulate = Color.DIM_GRAY
	%LayersButtons2.modulate = Color.DIM_GRAY
	%ViewportCam.modulate = Color.DIM_GRAY
	%ResetMicButton.modulate = Color.DIM_GRAY
	%LeftPanel.self_modulate = Color.WEB_GRAY
	%RightPanel.self_modulate = Color.WEB_GRAY
	%TopBar.self_modulate = Color.WEB_GRAY

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
