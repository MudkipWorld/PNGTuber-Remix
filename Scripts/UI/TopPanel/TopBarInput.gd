extends Node

@onready var files = %FilesButton
@onready var mode = %ModeButton
@onready var bgcolor = %BGButton
@onready var about = %AboutButton
var bg_color = Color.DIM_GRAY
var is_transparent : bool
var is_editor : bool = true
var last_path : String = ""
var settings = preload("res://UI/EditorUI/TopUI/Components/Settings_popup.tscn")

var tutorial = preload("res://UI/EditorUI/TopUI/Components/tutorial_pop_up.tscn")

var path = ""

func _ready():
	get_viewport().transparent_bg = false
	RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
	files.get_popup().connect("id_pressed",choosing_files)
	mode.get_popup().connect("id_pressed",choosing_mode)
	bgcolor.get_popup().connect("id_pressed",choosing_bg_color)
	about.get_popup().connect("id_pressed",choosing_about)
	%WindowButton.get_popup().connect("id_pressed",choosing_window)

	ProjectSettings.set("audio/driver/mix_rate", AudioServer.get_mix_rate())
	
	%WindowButton.get_popup().set_item_checked(2, Themes.theme_settings.always_on_top)
	
	print(Global.save_dir + "/autosaves")
	if !DirAccess.dir_exists_absolute(Global.save_dir + "/autosaves"):
		DirAccess.make_dir_absolute(Global.save_dir + "/autosaves")
		

func choosing_window(id):
	match id:
		0:
			Themes.toggle_borders()
		1:
			Themes.window_size_changed()
		2:
			%WindowButton.get_popup().toggle_item_checked(2)
			Themes.set_always_on_top(%WindowButton.get_popup().is_item_checked(2))
		3:
			Themes.center_window()

func choosing_files(id):
	var main = Global.main
	match id:
		0:
			main.new_file()
		1:
			main.load_file()
		3:
			main.save_as_file()
		4:
			main.load_sprites()
		5:
			%TempPopUp.popup()
		6:
			main.load_append_sprites()
		8:
			if path != null:
				if !path.is_empty():
					SaveAndLoad.save_file(path)
				else:
					main.save_as_file()
			else:
				main.save_as_file()
		9:
			export_images(get_tree().get_nodes_in_group("Sprites"))
			
		10:
			add_a_lipsync_config()
		11:
			if Global.swtich_session_popup != null && is_instance_valid(Global.swtich_session_popup):
				Global.swtich_session_popup.popup()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		if path != null && path != "":
			SaveAndLoad.save_file(path)
		else:
			Global.main.save_as_file()
	if event.is_action_pressed("desel"):
		desel_everything()
		Global.deselect.emit()

func choosing_mode(id):
	var saved_id = 0
	match id:
		0:
	#		Global.main.get_node("SubViewportContainer").mouse_filter = 1
			get_viewport().transparent_bg = false
			RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
			Global.main.get_node("%Control").show()
			%HideUIButton.button_pressed = true
			%HideUIButton.show()
			is_editor = true
			%PreviewModeCheck.show()
			saved_id = 0
		
		1:
		#	Global.main.get_node("SubViewportContainer").mouse_filter = 1
			RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
			get_viewport().transparent_bg = Global.settings_dict.is_transparent
			Global.main.get_node("%Control").hide()
			is_editor = false
			if Global.light != null && is_instance_valid(Global.light):
				Global.light.get_node("Grab").hide()
#			Global.main.get_node("%Control/%LSShapeVis").button_pressed = false
			%HideUIButton.hide()
			%HideUIButton.button_pressed = false
			Global.deselect.emit()
			%PreviewModeCheck.hide()
			Global.static_view = false
			%PreviewModeCheck.button_pressed = false
			saved_id = 1
		2:
		#	Global.main.get_node("SubViewportContainer").mouse_filter = 1
			get_viewport().transparent_bg = false
			RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
			Global.main.get_node("%Control").hide()
			%HideUIButton.button_pressed = true
			is_editor = true
			%PreviewModeCheck.hide()
			saved_id = 0
		

	Themes.theme_settings.mode = saved_id
	Global.mode = id
	Themes.save()
	desel_everything()

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
	if not is_editor:
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
	if not is_editor:
		if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			%TopBar.show()
		elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			%TopBar.hide()

func _on_inputs_button_pressed():
	Global.top_ui.add_child(settings.instantiate())


func _on_color_picker_color_changed(color):
	Global.settings_dict.bg_color = color
	if not is_editor:
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

func export_images(images = get_tree().get_nodes_in_group("Sprites")):
	#Global.save_dir + "/ExportedAssets" + "/" + str(randi())
	var dire = Global.save_dir + "/ExportedAssets"
	if !DirAccess.dir_exists_absolute(dire):
		DirAccess.make_dir_absolute(dire)
		
	for sprite in images:
		if !sprite.sprite_data.folder:
			if sprite.img_animated:
				var file = FileAccess.open(dire +"/" + sprite.sprite_name + str(randi()) + ".gif", FileAccess.WRITE)
				file.store_buffer(sprite.anim_texture)
				file.close()
				file = null
				if sprite.anim_texture_normal != null:
					var filenormal = FileAccess.open(dire +"/" + sprite.sprite_name + str(randi()) + "Normal" + ".gif", FileAccess.WRITE)
					filenormal.store_buffer(sprite.anim_texture_normal)
					filenormal.close()
					filenormal = null
					
			elif sprite.is_apng:
				var file = FileAccess.open(dire +"/" + sprite.sprite_name + str(randi()) + ".apng", FileAccess.WRITE)
				var exp_image = AImgIOAPNGExporter.new().export_animation(sprite.frames, 10, self, "_progress_report", [])
				file.store_buffer(exp_image)
				file.close()
				file = null
				if !sprite.frames2.is_empty():
					var filenormal = FileAccess.open(dire +"/" + sprite.sprite_name + "Normal" + str(randi()) + ".apng", FileAccess.WRITE)
					var exp2 = AImgIOAPNGExporter.new().export_animation(sprite.frames2, 10, self, "_progress_report", [])
					filenormal.store_buffer(exp2)
					filenormal.close()
					filenormal = null
				
			elif !sprite.img_animated && !sprite.is_apng:
				var img = Image.new()
				img = sprite.get_node("%Sprite2D").texture.diffuse_texture.get_image()
				img.save_png(dire +"/" + sprite.sprite_name + str(randi()) + ".png")
				img = null
				
				if sprite.get_node("%Sprite2D").texture.normal_texture != null:
					var normimg = Image.new()
					normimg = sprite.get_node("%Sprite2D").texture.normal_texture.get_image()
					normimg.save_png(dire +"/" + sprite.sprite_name + "Normal" + str(randi()) + ".png")
					normimg = null
				
				if !sprite.image_data.is_empty():
					var img_d = Image.new()
					img_d.load_png_from_buffer(sprite.image_data)
					img_d.save_png(dire +"/" + sprite.sprite_name + str(randi()) + ".png")
					img_d = null
				if !sprite.normal_data.is_empty():
					var img_d = Image.new()
					img_d.load_png_from_buffer(sprite.normal_data)
					img_d.save_png(dire +"/" + sprite.sprite_name + str(randi()) + ".png")
					img_d = null

func _on_background_focus_entered() -> void:
	Global.spinbox_held = true

func _on_background_focus_exited() -> void:
	Global.spinbox_held = false


func add_a_lipsync_config():
	var lipsync = preload("res://UI/Lipsync stuff/lipsync_configuration_popup.tscn").instantiate()
	lipsync.name = "LipsyncConfigurationPopup"
	Global.main.add_child(lipsync)
