extends Node

@onready var files = %FilesButton
@onready var mode = %ModeButton
@onready var bgcolor = %BGButton
@onready var about = %AboutButton
var bg_color = Color.DIM_GRAY
var is_transparent : bool
var last_path : String = ""
var settings = preload("res://UI/EditorUI/TopUI/Components/Settings_popup.tscn")
var tutorial = preload("res://UI/EditorUI/TopUI/Components/tutorial_pop_up.tscn")

var file_submenu_item : PopupMenu = PopupMenu.new()

func _ready():
	get_viewport().transparent_bg = false
	RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
	files.get_popup().connect("id_pressed",choosing_files)
	var import_file_items = ["TR_ADD_IMAGE", "TR_ADD_APPENDAGE", "TR_PSD_IMPORT"]
	for i in import_file_items:
		file_submenu_item.add_item(i)
	files.get_popup().set_item_submenu_node(4, file_submenu_item)
	file_submenu_item.connect("id_pressed",choosing_file_import)
	mode.get_popup().connect("id_pressed",choosing_mode)
	bgcolor.get_popup().connect("id_pressed",choosing_bg_color)
	about.get_popup().connect("id_pressed",choosing_about)
	%WindowButton.get_popup().connect("id_pressed",choosing_window)
	%EditButton.get_popup().connect("id_pressed",choosing_edit)
	Global.mode_changed.connect(on_mode_changed)
	update_window_button()
	check_auto_saves()
		
	await get_tree().physics_frame
	choosing_mode(Settings.theme_settings.mode)

func update_window_button() -> void:
	var menu := %WindowButton.get_popup() as PopupMenu
	menu.set_item_checked(2, Settings.theme_settings.always_on_top)
	menu.set_item_checked(5, Settings.theme_settings.hide_mini_view)
	menu.set_item_checked(6, Settings.theme_settings.hide_sprite_view)
	menu.set_item_checked(7, Settings.theme_settings.hide_bottom_bar)
	var i := menu.get_item_index(100)
	if i >= 0: menu.remove_item(i)
	
	for window in WindowHandler.windows:
		if !window.borderless: continue
		menu.add_item("Edit Windows", 100)
		break

func check_auto_saves():
	if !DirAccess.dir_exists_absolute(Settings.autosave_location):
		DirAccess.make_dir_absolute(Settings.autosave_location)

func choosing_edit(_id : int):
	pass

func choosing_window(id):
	match id:
		0:
			Settings.toggle_borders()
		1:
			Settings.window_size_changed()
		2:
			%WindowButton.get_popup().toggle_item_checked(2)
			Settings.set_always_on_top(%WindowButton.get_popup().is_item_checked(2))
		3:
			Settings.center_window()
		4:
			Global.add_window.emit()
		5:
			%WindowButton.get_popup().toggle_item_checked(5)
			Settings.set_ui_pieces(%WindowButton.get_popup().is_item_checked(5), 5)
			Global.update_ui_pieces.emit()
		6:
			%WindowButton.get_popup().toggle_item_checked(6)
			Settings.set_ui_pieces(%WindowButton.get_popup().is_item_checked(6), 6)
			Global.update_ui_pieces.emit()
		7:
			%WindowButton.get_popup().toggle_item_checked(7)
			Settings.set_ui_pieces(%WindowButton.get_popup().is_item_checked(7), 7)
			Global.update_ui_pieces.emit()
		8:
			get_window().size = Vector2i(1152, 648)
			Settings.center_window()
			Settings.window_size_changed()
			
		100:
			Global.edit_windows.emit()

func choosing_files(id):
	var main = Global.main
	match id:
		0:
			main.new_file()
		1:
			main.load_file()
		3:
			main.save_as_file()
		5:
			%TempPopUp.popup()
		8:
			if Global.save_path:
				SaveAndLoad.save_file(Global.save_path)
			else:
				main.save_as_file()
		9:
			SaveAndLoad.export_images(get_tree().get_nodes_in_group("Sprites"))
		10:
			add_a_lipsync_config()
		11:
			if Global.swtich_session_popup != null && is_instance_valid(Global.swtich_session_popup):
				Global.swtich_session_popup.popup()
		12:
			SaveAndLoad.import_trimmed = false
			if Global.save_path == null or Global.save_path == "" :
				check_auto_saves()
				var save_location = Settings.autosave_location + "ReloadedFileBackup" + "/" + str(randi())
				SaveAndLoad.save_file(save_location)
				await get_tree().physics_frame
				SaveAndLoad.load_file(save_location)
			else:
				SaveAndLoad.save_file(Global.save_path)
				await get_tree().physics_frame
				SaveAndLoad.load_file(Global.save_path)
				
		13:
			%ModelOptimizer.show()

func choosing_file_import(id):
	var main = Global.main
	match id:
		0:
			main.load_sprites()
		1:
			main.load_append_sprites()
		2:
			main.import_psd()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		if Global.save_path:
			SaveAndLoad.save_file(Global.save_path)
		else:
			Global.main.save_as_file()
	if event.is_action_pressed("desel"):
		desel_everything()
		Global.deselect.emit()

func on_mode_changed(new_mode) -> void:
	desel_everything()
	match new_mode:
		0:
			%PreviewModeCheck.show()
			%HideUIButton.button_pressed = true
			%HideUIButton.show()
		1:
			%HideUIButton.hide()
			%HideUIButton.button_pressed = false
			%PreviewModeCheck.hide()
			%PreviewModeCheck.button_pressed = false

func choosing_mode(id):
	Global.mode = id

func choosing_bg_color(id):
	Global.settings_dict.is_transparent = false
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", false)
	ProjectSettings.set_setting("display/window/size/transparent", false)
	match id:
		0:
			Global.settings_dict.bg_color = Color.RED
		1:
			Global.settings_dict.bg_color =  Color.BLUE
		2:
			Global.settings_dict.bg_color = Color.GREEN
		3:
			Global.settings_dict.bg_color = Color.MAGENTA
		4:
			Global.settings_dict.bg_color = Color.DIM_GRAY
			ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", true)
			ProjectSettings.set_setting("display/window/size/transparent", true)
			Global.settings_dict.is_transparent  = true
		5:
			Global.settings_dict.bg_color = Color.SLATE_GRAY
			
		6:
			%Background.popup()
	if not Global.is_editor:
		RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
		get_viewport().transparent_bg = Global.settings_dict.is_transparent

func choosing_about(id):
	match id:
		0:
			%AboutPopUp.popup()
		1:
			%CreditPopUp.popup()
		2:
			get_parent().add_child(tutorial.instantiate())

func _notification(what):
	if not Global.is_editor:
		if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			%TopBar.show()
		elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			%TopBar.hide()

func _on_inputs_button_pressed():
	Global.top_ui.add_child(settings.instantiate())

func _on_color_picker_color_changed(color):
	Global.settings_dict.bg_color = color
	if not Global.is_editor:
		RenderingServer.set_default_clear_color(color)

func update_bg_color(color, transparency):
	Global.settings_dict.bg_color = color
	Global.settings_dict.is_transparent = transparency
	%BGColorPicker.color = color

func origin_alias():
	if Global.settings_dict.anti_alias:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS

func _on_hide_ui_button_toggled(toggled_on):
	Global.main.get_node("%Control").visible = toggled_on

func _on_basic_temp_button_pressed():
	SaveAndLoad.load_file("res://DemoModels/PickleModel.pngRemix")
	%TempPopUp.hide()

func _on_bg_temp_button_pressed():
	SaveAndLoad.load_file("res://DemoModels/PickleModelWithBackground.pngRemix")
	%TempPopUp.hide()

func _on_normalm_temp_button_pressed():
	SaveAndLoad.load_file("res://DemoModels/PickleModelWithNormalMap.pngRemix")
	%TempPopUp.hide()

func _on_follow_mouse_temp_button_pressed():
	SaveAndLoad.load_file("res://DemoModels/PickleModelFollowMouse.pngRemix")
	%TempPopUp.hide()

func _on_asset_temp_button_pressed():
	SaveAndLoad.load_file("res://DemoModels/PickleModelAssets.pngRemix")
	%TempPopUp.hide()

func _on_deselect_button_pressed():
	desel_everything()

func desel_everything():
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.has_node("%Origin"):
			Global.held_sprite.get_node("%Origin").hide()
		#	%LayersTree.get_selected().deselect(0)
	Global.held_sprite = null
	Global.deselect.emit()

func _on_preview_mode_check_toggled(toggled_on: bool) -> void:
	Global.static_view = toggled_on

func _on_background_focus_entered() -> void:
	Global.spinbox_held = true

func _on_background_focus_exited() -> void:
	Global.spinbox_held = false

func add_a_lipsync_config():
	var lipsync = preload("res://UI/Lipsync stuff/lipsync_configuration_popup.tscn").instantiate()
	lipsync.name = "LipsyncConfigurationPopup"
	get_parent().add_child(lipsync)

func _on_window_button_about_to_popup() -> void:
	update_window_button()
