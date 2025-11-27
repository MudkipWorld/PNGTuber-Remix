extends Control

var sprite_paths : PackedStringArray
var sprite_path : String
var model_path : String

var filepath : Array = []
enum State {
	LoadFile,
	SaveFile,
	SaveFileAs,
	LoadSprites,
	ReplaceSprite,
	AddNormal,
	AddAppend,
	ImportPSD,
}
var current_state : State
var can_scroll : bool = false

var rec_inp : bool = false

@onready var origin = %SpritesContainer
var of := Vector2.ZERO
var cam_pos_before_pan := Vector2.ZERO

func _ready():
	Global.viewport = %SubViewportContainer
	Global.viewer = %Effects
	Global.main = self
	Global.sprite_container = %SpritesContainer
	Global.top_ui = %TopUI
	Global.light = %LightSource
	Global.camera = %Camera2D
	Global.camera_pos = %CamPos
	Global.mesh_pointer = %MeshPointer
	Global.update_camera_smoothing()
	
	Global.theme_update.connect(update_theme)
	Global.file_dialog = %FileDialog
	%FileDialog.use_native_dialog = true
	update_theme(Settings.current_theme)
	await get_tree().create_timer(0.1).timeout
	Global.update_ui_pieces.emit()
	Global.update_camera_smoothing()
	Global.project_updates.connect(update_text)
	Global.mode_changed.connect(mode_changed)
	Global.update_ui_pieces.connect(update_pieces)
	update_pieces()

func update_pieces():
	%ProjectNamePanel.visible = Settings.theme_settings.hide_bottom_bar

func mode_changed(mode : int):
	if Settings.theme_settings.hide_bottom_bar:
		if mode == 0:
			%ProjectNamePanel.show()
		else:
			%ProjectNamePanel.hide()

func update_theme(new_theme : Theme = preload("res://Themes/PurpleTheme/GUITheme.tres")):
	%UIHold.theme = new_theme
	%ConfirmTrim.theme = new_theme
	%ConfirmationDialog.theme = new_theme

func new_file():
	%ConfirmationDialog.popup()

func load_file():
	#%FileDialog.filters = ["*.pngRemix, *.save"]
	%FileDialog.filters = ["*.pngRemix, *.save"]
	$FileDialog.file_mode = 0
	current_state = State.LoadFile
	%FileDialog.show()

func save_as_file():
	%FileDialog.filters = ["*.pngRemix"]
	$FileDialog.file_mode = 4
	current_state = State.SaveFileAs
	%FileDialog.show()

func load_sprites():
	%FileDialog.filters = ["*.png, *.apng, *.gif", "*.png", "*.svg", "*.apng"]
	$FileDialog.file_mode = 1
	current_state = State.LoadSprites
	%FileDialog.show()

func import_psd():
	%FileDialog.filters = ["*.psd"]
	$FileDialog.file_mode = 0
	current_state = State.ImportPSD
	%FileDialog.show()

func load_append_sprites():
	%FileDialog.filters = ["*.png, *.apng, *.gif", "*.png", "*.svg", "*.apng"]
	$FileDialog.file_mode = 1
	current_state = State.AddAppend
	%FileDialog.show()

func replacing_sprite():
	if Global.held_sprites.size() == 1:
		if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
			if not Global.held_sprites[0].get_value("folder"):
				%FileDialog.filters = ["*.png, *.apng, *.gif", "*.svg", "*.apng"]
				$FileDialog.file_mode = 0
				current_state = State.ReplaceSprite
				%FileDialog.show()

func add_normal_sprite():
	if Global.held_sprites.size() == 1:
		if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
			if not Global.held_sprites[0].get_value("folder"):
				if Global.held_sprites[0].referenced_data.img_animated:
					%FileDialog.filters = ["*.gif"]
				elif Global.held_sprites[0].referenced_data.is_apng:
					%FileDialog.filters = ["*.png","*.apng"]
				else:
					%FileDialog.filters = ["*.png", "*.svg"]
				$FileDialog.file_mode = 0
				current_state = State.AddNormal
				%FileDialog.show()

func _on_file_dialog_file_selected(path): 
	match current_state:
		State.LoadFile:
			ImageTextureLoaderManager.trim = false
			SaveAndLoad.import_trimmed = false
			if path.get_extension().to_lower() == "save":
				if Settings.theme_settings.enable_trimmer:
					model_path = path
					%ConfirmTrim.popup_centered()
				else:
					SaveAndLoad.load_file(path, true)
			else:
				SaveAndLoad.load_file(path, true)
		State.SaveFileAs:
			SaveAndLoad.save_file(path)
		State.ReplaceSprite:
			if Settings.theme_settings.enable_trimmer:
				var apng_test = AImgIOAPNGImporter.load_from_file(path)
				if apng_test != ["No frames", null]:
					ImageTextureLoaderManager.trim = false
					%FileImporter.replace_texture(path)
				else:
					sprite_path = path
					%ConfirmTrim.popup_centered()
			else:
				ImageTextureLoaderManager.trim = false
				%FileImporter.replace_texture(path)
		State.AddNormal:
			if Settings.theme_settings.enable_trimmer:
				var apng_test = AImgIOAPNGImporter.load_from_file(path)
				if apng_test != ["No frames", null]:
					ImageTextureLoaderManager.trim = false
					%FileImporter.add_normal(path)
				else:
					sprite_path = path
					%ConfirmTrim.popup_centered()
			else:
				ImageTextureLoaderManager.trim = false
				%FileImporter.add_normal(path)
		State.ImportPSD:
			SaveAndLoad.load_images_from_psd(path)

func _on_file_dialog_files_selected(paths):
	if current_state == State.LoadSprites or current_state == State.AddAppend:
		sprite_paths = paths
		if Settings.theme_settings.enable_trimmer:
			%ConfirmTrim.popup_centered()
		else:
			ImageTextureLoaderManager.trim = false
			import_objects()

func import_objects():
		for path in sprite_paths:
			var sprte_obj
			if current_state == State.LoadSprites:
				sprte_obj = %FileImporter.import_sprite(path)
			elif current_state == State.AddAppend:
				sprte_obj = %FileImporter.import_appendage(path)
			%SpritesContainer.add_child(sprte_obj)
			sprte_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT

			sprte_obj.sprite_id = sprte_obj.get_instance_id()
			sprte_obj.disappear_keys = str(sprte_obj.sprite_id) + "Disappear"
			
			sprte_obj.states = []
			var states = get_tree().get_nodes_in_group("StateButtons").size()
			for i in states:
				sprte_obj.states.append({})
				
			if current_state == State.AddAppend:
				sprte_obj.correct_sprite_size()
				sprte_obj.update_wiggle_parts()
				Global.update_layers.emit(0, sprte_obj, "WiggleApp")
			else:
				Global.update_layers.emit(0, sprte_obj, "Sprite2D")

func _on_confirmation_dialog_confirmed():
	Global.image_manager_data.clear()
	Global.remake_image_manager.emit()
	Global.save_path = ""
	Global.new_file.emit()
	clear_sprites()
	Global.settings_dict.max_fps = 241
	Global.settings_dict.should_delta = true
	%TopUI.update_fps(241)
	Global.main.get_node("%Marker").current_screen = Monitor.ALL_SCREENS
	Global.settings_dict.monitor = Monitor.ALL_SCREENS
	%ConfirmationDialog.hide()
	Global.project_updates.emit("New Project!")

func clear_sprites():
	Global.held_sprite = null
	Global.deselect.emit()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if InputMap.has_action(str(i.sprite_id)):
			InputMap.erase_action(str(i.sprite_id))
		if InputMap.has_action(i.disappear_keys):
			InputMap.erase_action(i.disappear_keys)

	for i in Global.sprite_container.get_children():
		i.queue_free()
	
	Global.delete_states.emit()
	Global.reset_states.emit()
	Global.camera.zoom = Vector2(1,1)
	%CamPos.global_position = Vector2(0, 0)
	Global.settings_dict.zoom = Vector2(1,1)
	Global.settings_dict.pan = Vector2(0, 0)

func set_zoom(new_zoom: Vector2) -> void:
	var mouse_pos := %Node2D.get_local_mouse_position() as Vector2
	var cam_pos := %Node2D.to_local(%Camera2D.get_screen_center_position()) as Vector2
	var last_zoom: float = %Camera2D.zoom.x
	
	%Camera2D.zoom = new_zoom.clampf(0.01, 5.)
	Global.settings_dict.zoom = %Camera2D.zoom
	
	var change: float = %Camera2D.zoom.x / last_zoom
	%CamPos.position = (cam_pos - mouse_pos) / change + mouse_pos
	%Camera2D.reset_smoothing()
	Global.settings_dict.pan = %CamPos.global_position

func _input(event):
	if can_scroll && not Input.is_action_pressed("ctrl"):
		if event.is_action_pressed("scrollup"):
			if Input.is_action_pressed("alt"):
				set_zoom(%Camera2D.zoom*1.1)
			else:
				var val = min(%Camera2D.zoom.x*1.1, 5.0)
				%Camera2D.zoom = Vector2(val, val)
				Global.settings_dict.zoom = %Camera2D.zoom

				
		elif event.is_action_pressed("scrolldown"):
			if Input.is_action_pressed("alt"):
				set_zoom(%Camera2D.zoom/1.1)
			else:
				var val = max(%Camera2D.zoom.x/1.1, 0.01)
				%Camera2D.zoom = Vector2(val, val)
				Global.settings_dict.zoom = %Camera2D.zoom
				
				
		if Input.is_action_just_pressed("pan"):
			cam_pos_before_pan = %CamPos.global_position
			of = get_global_mouse_position()
		
		elif Input.is_action_pressed("pan"):
			var offset: Vector2 = of - get_global_mouse_position()
			offset /= %Camera2D.zoom
			%CamPos.global_position = cam_pos_before_pan + offset
			Global.settings_dict.pan = %CamPos.global_position

func _on_sub_viewport_container_mouse_entered():
	can_scroll = true

func _on_sub_viewport_container_mouse_exited():
	can_scroll = false

func _notification(what):
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		rec_inp = false
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		rec_inp = true

func _on_confirmation_dialog_canceled() -> void:
	%ConfirmationDialog.hide()

func update_text(arg):
	if arg is String:
		if arg == "New Project!":
			%ProjectNameLabel.text = "No Path"
		else:
			%ProjectNameLabel.text = Global.save_path
