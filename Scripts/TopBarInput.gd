extends Node

@onready var files = %FilesButton
@onready var mode = %ModeButton
@onready var bgcolor = %BGButton
@onready var about = %AboutButton
var bg_color = Color.DIM_GRAY
var is_transparent : bool
var is_editor : bool = true
var last_path : String = ""
@onready var origin = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
@onready var light = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/LightSource")
var devices : Array = []
var path = null

func _ready():
	get_viewport().transparent_bg = false
	RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
	files.get_popup().connect("id_pressed",choosing_files)
	mode.get_popup().connect("id_pressed",choosing_mode)
	bgcolor.get_popup().connect("id_pressed",choosing_bg_color)
	about.get_popup().connect("id_pressed",choosing_about)
	%WindowButton.get_popup().connect("id_pressed",choosing_window)
	
	%BounceAmountSlider.get_node("%SliderValue").value_changed.connect(_on_bounce_amount_slider_value_changed)
	%GravityAmountSlider.get_node("%SliderValue").value_changed.connect(_on_gravity_amount_slider_value_changed)
	
	
	devices = AudioServer.get_input_device_list()
	for i in devices:
		%MicroPhoneMenu.get_popup().add_item(i)
	
	ProjectSettings.set("audio/driver/mix_rate", AudioServer.get_mix_rate())
	%MicroPhoneMenu.text = str(AudioServer.input_device)
	%MicroPhoneMenu.get_popup().connect("id_pressed",choosing_device)
	print(OS.get_executable_path().get_base_dir() + "/autosaves")
	if !DirAccess.dir_exists_absolute(OS.get_executable_path().get_base_dir() + "/autosaves"):
		DirAccess.make_dir_absolute(OS.get_executable_path().get_base_dir() + "/autosaves")
		


func choosing_window(id):
	match id:
		0:
			Themes.toggle_borders()
		1:
			Themes.window_size_changed()



func choosing_device(id):
	if id != null:
		if AudioServer.get_input_device_list().has(devices[id]):
			AudioServer.input_device = devices[id]
			ProjectSettings.set("audio/driver/mix_rate", AudioServer.get_mix_rate())
	else:
		reset_mic_list()


func choosing_files(id):
	var main = get_tree().get_root().get_node("Main")
	match id:
		0:
			main.new_file()
		1:
			main.load_file()
		2:
			main.save_file(last_path)
		3:
			main.save_as_file()
		4:
			main.load_sprites()
		5:
			%TempPopUp.popup()
		6:
			main.load_append_sprites()
		7:
			main.load_bg_sprites()
		8:
			if path != null:
				SaveAndLoad.save_file(path)
		9:
			export_images(get_tree().get_nodes_in_group("Sprites"))
			
		10:
			add_a_lipsync_config()
		

func choosing_mode(id):
	var saved_id = 0
	match id:
		0:
			get_parent().get_parent().get_parent().get_node("SubViewportContainer").mouse_filter = 1
			get_viewport().transparent_bg = false
			RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
			get_tree().get_root().get_node("Main/%Control").show()
			get_tree().get_root().get_node("Main/%VS").hide()
			%HideUIButton.button_pressed = true
			is_editor = true
			%PreviewModeCheck.show()
			saved_id = 0
			
			
				
		
		1:
			get_parent().get_parent().get_parent().get_node("SubViewportContainer").mouse_filter = 1
			RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
			get_viewport().transparent_bg = Global.settings_dict.is_transparent
			get_tree().get_root().get_node("Main/%Control").hide()
			get_tree().get_root().get_node("Main/%VS").hide()
			is_editor = false
			light.get_node("Grab").hide()
			get_tree().get_root().get_node("Main/%Control/%LSShapeVis").button_pressed = false
			%HideUIButton.hide()
			%HideUIButton.button_pressed = false
			Global.deselect.emit()
			%PreviewModeCheck.hide()
			Global.static_view = false
			%PreviewModeCheck.button_pressed = false
			saved_id = 1
		2:
			get_parent().get_parent().get_parent().get_node("SubViewportContainer").mouse_filter = 1
			get_viewport().transparent_bg = false
			RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
			get_tree().get_root().get_node("Main/%Control").hide()
			get_tree().get_root().get_node("Main/%VS").show()
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
			%TutorialPopUp.popup()

func _notification(what):
	if not is_editor:
		if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			%TopBar.show()
		elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			%TopBar.hide()

func _on_inputs_button_pressed():
	%InputsPopup.popup()

func _on_bounce_control_button_pressed():
	%BounceControlPopup.popup()

func _on_bounce_amount_slider_value_changed(value):
	Global.settings_dict.bounceSlider = value
#	%BounceAmount.text = "Bounce Amount : " + str(value)

func _on_gravity_amount_slider_value_changed(value):
	Global.settings_dict.bounceGravity = value
#	%GravityAmount.text = "Bounce Gravity : " + str(value)

func _on_input_check_button_toggled(toggled_on):
	Global.settings_dict.checkinput = toggled_on

func _on_color_picker_color_changed(color):
	Global.settings_dict.bg_color = color
	if not is_editor:
		RenderingServer.set_default_clear_color(color)

func update_bg_color(color, transparency):
	Global.settings_dict.bg_color = color
	Global.settings_dict.is_transparent = transparency
	%BGColorPicker.color = color


'''
func _on_collab_button_pressed():
	pass # Replace with function body.
'''

func _on_anti_al_check_toggled(toggled_on):
	Global.settings_dict.anti_alias = toggled_on
	if toggled_on:
		origin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	else:
		origin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS



func origin_alias():
	if Global.settings_dict.anti_alias:
		origin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	else:
		origin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS


func _on_hide_ui_button_toggled(toggled_on):
	get_tree().get_root().get_node("Main/%Control").visible = toggled_on


func _on_basic_temp_button_pressed():
	SaveAndLoad.load_file("res://Template Model(s)/PickleModel.pngRemix")
	%TempPopUp.hide()


func _on_bg_temp_button_pressed():
	SaveAndLoad.load_file("res://Template Model(s)/PickleModelWithBackground.pngRemix")
	%TempPopUp.hide()


func _on_normalm_temp_button_pressed():
	SaveAndLoad.load_file("res://Template Model(s)/PickleModelWithNormalMap.pngRemix")
	%TempPopUp.hide()


func _on_follow_mouse_temp_button_pressed():
	SaveAndLoad.load_file("res://Template Model(s)/PickleModelFollowMouse.pngRemix")
	%TempPopUp.hide()

func _on_asset_temp_button_pressed():
	SaveAndLoad.load_file("res://Template Model(s)/PickleModelAssets.pngRemix")
	%TempPopUp.hide()



func _on_reset_mic_button_pressed():
	reset_mic_list()

func reset_mic_list():
	%MicroPhoneMenu.get_popup().clear()
	devices = AudioServer.get_input_device_list()
	devices.append_array(AudioServer.get_output_device_list())
	for i in devices:
		%MicroPhoneMenu.get_popup().add_item(i)


func _on_deselect_button_pressed():
	desel_everything()


func desel_everything():
	if Global.held_sprite != null:
		if Global.held_sprite.has_node("Pos//Wobble/Squish/Drag/Rotation/Origin"):
			Global.held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Origin").hide()
		#	%LayersTree.get_selected().deselect(0)
	if Global.held_bg_sprite != null:
		if Global.held_bg_sprite.has_node("Pos//Wobble/Squish/Drag/Sprite2D/Origin"):
			Global.held_bg_sprite.get_node("Pos//Wobble/Squish/Drag/Sprite2D/Origin").hide()
	Global.held_sprite = null
	Global.held_bg_sprite = null
	Global.deselect.emit()
	%DeselectButton.hide()

func _on_bounce_state_check_toggled(toggled_on):
	Global.settings_dict.bounce_state = toggled_on
	

func _on_x_freq_wobble_slider_value_changed(value):
	Global.settings_dict.xFrq = value
	%XFreqWobbleLabel.text = "X-Frequency Wobble : " + str(value)

func _on_x_amp_wobble_slider_value_changed(value):
	Global.settings_dict.xAmp = value
	%XAmpWobbleLabel.text = "X-Amplitude Wobble : " + str(value)

func _on_y_freq_wobble_slider_value_changed(value):
	Global.settings_dict.yFrq = value
	%YFreqWobbleLabel.text = "Y-Frequency Wobble : " + str(value)

func _on_y_amp_wobble_slider_value_changed(value):
	Global.settings_dict.yAmp = value
	%YAmpWobbleLabel.text = "Y-Amplitude Wobble : " + str(value)

func _on_auto_save_check_toggled(toggled_on):
	Global.settings_dict.auto_save = toggled_on
	if toggled_on:
		%AutoSaveTimer.start()
	else:
		%AutoSaveTimer.stop()

func _on_auto_save_spin_value_changed(value):
	%AutoSaveTimer.wait_time = value * 60
	Global.settings_dict.auto_save_timer = %AutoSaveTimer.wait_time

func _on_auto_save_timer_timeout():
	if Global.settings_dict.auto_save:
		if path:
			SaveAndLoad.save_file(path)
		else:
			if !DirAccess.dir_exists_absolute(OS.get_executable_path().get_base_dir() + "/autosaves"):
				DirAccess.make_dir_absolute(OS.get_executable_path().get_base_dir() + "/autosaves")
			
			var items = DirAccess.get_files_at(OS.get_executable_path().get_base_dir() + "/autosaves").size()
			path = OS.get_executable_path().get_base_dir() + "/autosaves" + "/autosave_file" + str(items) 
			SaveAndLoad.save_file(path)
			
			
		%AutoSaveTimer.start()

func _on_record_button_toggled(toggled_on):
	if toggled_on:
		%RecordButton.text = "Recording..."
		get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").record()
	else:
		%FileDialog.popup()
		%RecordButton.text = "Record"

func _on_file_dialog_canceled():
	get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").cancelled()

func _on_file_dialog_close_requested():
	get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").cancelled()
	get_window().unresizable = false

func _on_file_dialog_confirmed() -> void:
	get_window().unresizable = false

func _on_file_dialog_file_selected(savpath):
	
	get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").output_folder = savpath
	if Themes.theme_settings.as_apng:
		get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").savea()
	else:
		get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/RecorderLayer/Recorder").save()

func _on_file_type_item_selected(index):
	match index:
		0:
			Themes.theme_settings.as_apng = false
			%FileDialog.filters = ["*.png"]
			
		1:
			Themes.theme_settings.as_apng = true
			%FileDialog.filters = ["*.apng"]
	Themes.save()
	

func _on_delta_time_check_toggled(toggled_on: bool) -> void:
	Global.settings_dict.should_delta = toggled_on

func _on_preview_mode_check_toggled(toggled_on: bool) -> void:
	Global.static_view = toggled_on

func export_images(images = get_tree().get_nodes_in_group("Sprites")):
	#OS.get_executable_path().get_base_dir() + "/ExportedAssets" + "/" + str(randi())
	var dire = OS.get_executable_path().get_base_dir() + "/ExportedAssets"
	if !DirAccess.dir_exists_absolute(dire):
		DirAccess.make_dir_absolute(dire)
		
	for sprite in images:
		if !sprite.dictmain.folder:
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
				var exp = AImgIOAPNGExporter.new().export_animation(sprite.frames, 10, self, "_progress_report", [])
				file.store_buffer(exp)
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


func _on_background_focus_entered() -> void:
	Global.spinbox_held = true


func _on_background_focus_exited() -> void:
	Global.spinbox_held = false


func _on_max_fp_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		%MaxFPSLabel.text = "Max FPS : " + str(%MaxFPSlider.value)
		Global.settings_dict.max_fps = %MaxFPSlider.value
		get_parent().update_fps(%MaxFPSlider.value)
		


func _on_max_fp_slider_value_changed(value: float) -> void:
	%MaxFPSLabel.text = "Max FPS : " + str(value)


func add_a_lipsync_config():
	var lipsync = preload("res://UI/Lipsync stuff/lipsync_configuration_popup.tscn").instantiate()
	lipsync.name = "LipsyncConfigurationPopup"
	get_tree().get_root().get_node("Main").add_child(lipsync)
