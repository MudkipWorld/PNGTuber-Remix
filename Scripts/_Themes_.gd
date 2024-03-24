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
		
	%UIThemeButton.get_popup().connect("id_pressed",choosing_UI)

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

func choosing_UI(id):
	match id:
		0:
			%UIThemeButton.text = "Purple"
			theme_id = 0 
			purple_theme()
		1:
			theme_id = 1
			%UIThemeButton.text = "Blue"
			blue_theme()
		2:
			theme_id = 2
			%UIThemeButton.text = "Orange"
			orange_theme()
		3:
			theme_id = 3
			%UIThemeButton.text = "White"
			white_theme()
	save()

func blue_theme():
	get_parent().theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
	%Panelt.self_modulate = Color.LIGHT_BLUE
	%Paneln.self_modulate = Color.LIGHT_BLUE
	%Panel.self_modulate = Color.LIGHT_BLUE
	%Properties.self_modulate = Color.LIGHT_BLUE
	%LayersButtons.modulate = Color.AQUA
	%LayersButtons2.modulate = Color.AQUA
	%ViewportCam.modulate = Color.AQUA

func purple_theme():
	get_parent().theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
	%Panelt.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Paneln.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Panel.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Properties.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%LayersButtons.modulate = Color(0.898, 0.796, 0.996, 1 )
	%LayersButtons2.modulate = Color(0.898, 0.796, 0.996, 1 )
	%ViewportCam.modulate = Color(0.898, 0.796, 0.996, 1 )

func orange_theme():
	get_parent().theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
	%Panelt.self_modulate = Color.ORANGE
	%Paneln.self_modulate = Color.ORANGE
	%Panel.self_modulate = Color.ORANGE
	%Properties.self_modulate = Color.ORANGE
	%LayersButtons.modulate = Color.ORANGE
	%LayersButtons2.modulate = Color.ORANGE
	%ViewportCam.modulate = Color.ORANGE

func white_theme():
	get_parent().theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
	%Panelt.self_modulate = Color.WHITE
	%Paneln.self_modulate = Color.WHITE
	%Panel.self_modulate = Color.WHITE
	%Properties.self_modulate = Color.WHITE
	%LayersButtons.modulate = Color.WHITE
	%LayersButtons2.modulate = Color.WHITE
	%ViewportCam.modulate = Color.WHITE
