extends Control

signal key_pressed


var filepath : Array = []
enum State {
	LoadFile,
	SaveFile,
	SaveFileAs,
	LoadSprites,
	ReplaceSprite,
	AddNormal,
	AddAppend,
	AddBgSprite
}
var current_state : State
var can_scroll : bool = false

var rec_inp : bool = false

@onready var origin = %SpritesContainer
var of


func _ready():
	%FileDialog.use_native_dialog = true

func new_file():
	%ConfirmationDialog.popup()

func load_file():
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
	%FileDialog.filters = ["*.png, *.gif, *.apng", "*.png", "*.jpeg", "*.jpg", "*.svg", "*.gif", "*.apng"]
	$FileDialog.file_mode = 1
	current_state = State.LoadSprites
	%FileDialog.show()


func load_append_sprites():
	%FileDialog.filters = ["*.png, *.gif, *.apng", "*.png", "*.jpeg", "*.jpg", "*.svg", "*.gif", "*.apng"]
	$FileDialog.file_mode = 1
	current_state = State.AddAppend
	%FileDialog.show()


func replacing_sprite():
	if Global.held_sprite != null:
		if not Global.held_sprite.dictmain.folder:
			%FileDialog.filters = ["*.png, *.gif, *.apng", "*.jpeg", "*.jpg", "*.svg", "*.gif", "*.apng"]
			$FileDialog.file_mode = 0
			current_state = State.ReplaceSprite
			%FileDialog.show()

func add_normal_sprite():
	if Global.held_sprite != null:
		if not Global.held_sprite.dictmain.folder:
			if Global.held_sprite.img_animated:
				%FileDialog.filters = ["*.gif"]
			elif Global.held_sprite.is_apng:
				%FileDialog.filters = ["*.png","*.apng"]
			else:
				%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg"]
			$FileDialog.file_mode = 0
			current_state = State.AddNormal
			%FileDialog.show()

func load_bg_sprites():
	%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg"]
	$FileDialog.file_mode = 1
	current_state = State.AddBgSprite
	%FileDialog.show()

func _on_file_dialog_file_selected(path): 
	match current_state:
		State.LoadFile:
			SaveAndLoad.load_file(path)
		State.SaveFileAs:
			SaveAndLoad.save_file(path)
			
		State.ReplaceSprite:
			
			if path.get_extension() == "gif":
				var g_file = FileAccess.get_file_as_bytes(path)
				var gif_tex = GifManager.animated_texture_from_buffer(g_file)
				var img_can = CanvasTexture.new()
				img_can.diffuse_texture = gif_tex
				Global.held_sprite.anim_texture = g_file
				Global.held_sprite.anim_texture_normal = null
				Global.held_sprite.texture = img_can
				Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can
				Global.held_sprite.img_animated = true
				Global.held_sprite.is_apng = false
				Global.held_sprite.save_state(Global.current_state)
				Global.held_sprite.treeitem.set_icon(0, gif_tex)
				
				
				

			else:
				var apng_test = AImgIOAPNGImporter.load_from_file(path)
				if apng_test != ["No frames", null]:
					var img = AImgIOAPNGImporter.load_from_file(path)
					var tex = img[1] as Array[AImgIOFrame]
					Global.held_sprite.frames = tex
					var cframe: AImgIOFrame = Global.held_sprite.frames[0]
					var text = ImageTexture.create_from_image(cframe.content)
					var img_can = CanvasTexture.new()
					img_can.diffuse_texture = text
					Global.held_sprite.texture = img_can
					Global.held_sprite.treeitem.set_icon(0, text)
					Global.held_sprite.is_apng = true
					Global.held_sprite.img_animated = false
				else:
					var img = Image.load_from_file(path)
					var texture = ImageTexture.create_from_image(img)
					var img_can = CanvasTexture.new()
					Global.held_sprite.img_animated = false
					Global.held_sprite.is_apng = false
					img_can.diffuse_texture = texture
					Global.held_sprite.texture = img_can
					Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can
					Global.held_sprite.save_state(Global.current_state)
					Global.held_sprite.treeitem.set_icon(0, texture)
			Global.get_sprite_states(Global.current_state)
			
			
		State.AddNormal:
			
			if path.get_extension() == "gif":
				var g_file = FileAccess.get_file_as_bytes(path)
				var gif_tex = GifManager.animated_texture_from_buffer(g_file)
				Global.held_sprite.anim_texture_normal = g_file
				Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture.normal_texture = gif_tex
			else:
				var apng_test = AImgIOAPNGImporter.load_from_file(path)
				if apng_test != ["No frames", null]:
					var img = AImgIOAPNGImporter.load_from_file(path)
					var tex = img[1] as Array[AImgIOFrame]
					Global.held_sprite.frames2 = tex
					var cframe: AImgIOFrame = Global.held_sprite.frames2[0]
					var text = ImageTexture.create_from_image(cframe.content)
					Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture.normal_texture = text

				else:
					var img = Image.load_from_file(path)
					var texture = ImageTexture.create_from_image(img)
					Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture.normal_texture = texture
			Global.get_sprite_states(Global.current_state)

func _on_file_dialog_files_selected(paths):
	if current_state == State.LoadSprites or current_state == State.AddAppend:
		var sprite_nodes = []
		for path in paths:
			
			var sprte_obj

			if current_state == State.LoadSprites:
				sprte_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			elif current_state == State.AddAppend:
				sprte_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn").instantiate()
			%SpritesContainer.add_child(sprte_obj)

			if path.get_extension() == "gif":
				var g_file = FileAccess.get_file_as_bytes(path)
				var gif_tex = GifManager.animated_texture_from_buffer(g_file)
				var img_can = CanvasTexture.new()
				img_can.diffuse_texture = gif_tex
				sprte_obj.anim_texture = g_file
				sprte_obj.img_animated = true
				sprte_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can


			
			
			else:
				var apng_test = AImgIOAPNGImporter.load_from_file(path)
				if apng_test != ["No frames", null]:
					var img = AImgIOAPNGImporter.load_from_file(path)
					var tex = img[1] as Array[AImgIOFrame]
					sprte_obj.frames = tex
					var cframe: AImgIOFrame = sprte_obj.frames[0]
					var text = ImageTexture.create_from_image(cframe.content)
					var img_can = CanvasTexture.new()
					img_can.diffuse_texture = text
					sprte_obj.texture = img_can
					sprte_obj.is_apng = true
					sprte_obj.sprite_name = "(Apng) " + path.get_file().get_basename() 
					
				else:
					var img = Image.load_from_file(path)
					var texture = ImageTexture.create_from_image(img)
					var img_can = CanvasTexture.new()
					img_can.diffuse_texture = texture
					sprte_obj.texture = img_can
					sprte_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can
					sprte_obj.sprite_name = path.get_file().get_basename()
			
				sprte_obj.img_animated = false


			sprte_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT


			sprte_obj.sprite_id = sprte_obj.get_instance_id()
			if sprte_obj.img_animated:
				sprte_obj.sprite_name = "(Gif) " + path.get_file().get_basename() 
				
			sprte_obj.states = []
			var states = get_tree().get_nodes_in_group("StateButtons").size()
			for i in states:
				sprte_obj.states.append({})
				
			sprite_nodes.append(sprte_obj)
			

		$Control._added_tree(sprite_nodes)
	if current_state == State.AddBgSprite:
		var bg_sprite_nodes = []
		for path in paths:
			var img = Image.load_from_file(path)
			var texture = ImageTexture.create_from_image(img)
			var img_can = CanvasTexture.new()
			img_can.diffuse_texture = texture
			var bg_sprte_obj = preload("res://Misc/BackgroundObject/background_object.tscn").instantiate()
			bg_sprte_obj.texture = img_can
			bg_sprte_obj.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture = img_can
			bg_sprte_obj.sprite_name = path.get_file().get_basename()
			%BGContainer.add_child(bg_sprte_obj)
		
			bg_sprite_nodes.append(bg_sprte_obj)
			
		#	bg_sprte_obj.global_position = Vector2(640, 360)
		$Control/BackgroundEdit._added_tree(bg_sprite_nodes)


func _on_confirmation_dialog_confirmed():
	$Control/_Themes_.theme_settings.path = null
	$Control/TopBarInput.path = null
	$Control/TopBarInput.last_path = ""
	clear_sprites()

func clear_sprites():
	Global.held_sprite = null
	$Control/UIInput.held_sprite_is_null()
	$Control/HSplitContainer/LeftPanel/VBox/PanelL/PanelL1_2/LayersTree.clear()
	$Control/HSplitContainer/LeftPanel/VBox/PanelL2/PanelL2_2/BackgroundTree.clear()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if InputMap.has_action(str(i.sprite_id)):
			InputMap.erase_action(str(i.sprite_id))
		i.queue_free()
	for i in get_tree().get_nodes_in_group("BackgroundStuff"):
		i.queue_free()
	
	$Control.new_tree()
	$Control/BackgroundEdit.new_tree()
	$Control/StatesStuff.delete_all_states()
	$Control/StatesStuff.initial_state()
	%Camera2D.zoom = Vector2(1,1)


func _input(event):
	if can_scroll && not Input.is_action_pressed("ctrl"):
		if event.is_action_pressed("scrollup"):
				%Camera2D.zoom = clamp(%Camera2D.zoom*Vector2(1.1,1.1) , Vector2(0.01,0.01), Vector2(5,5))
				Global.settings_dict.zoom = %Camera2D.zoom
		elif event.is_action_pressed("scrolldown"):
				%Camera2D.zoom = clamp(%Camera2D.zoom/Vector2(1.1,1.1) , Vector2(0.01,0.01), Vector2(5,5))
				Global.settings_dict.zoom = %Camera2D.zoom
		
		if Input.is_action_just_pressed("pan"):
			of = get_global_mouse_position() + %CamPos.global_position
		
		elif Input.is_action_pressed("pan"):
			%CamPos.global_position = -get_global_mouse_position() + of
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


func _on_background_input_capture_bg_key_pressed(_node, keys_pressed):
	if Global.settings_dict.checkinput:
		var keyStrings = []
		var costumeKeys = []
		
		for l in get_tree().get_nodes_in_group("StateButtons"):
			if InputMap.action_get_events(l.input_key).size() > 0:
				costumeKeys.append(InputMap.action_get_events(l.input_key)[0].as_text())
				
		for l in get_tree().get_nodes_in_group("Sprites"):
			if InputMap.action_get_events(str(l.sprite_id)).size() > 0:
				costumeKeys.append(InputMap.action_get_events(str(l.sprite_id))[0].as_text())
		
		for i in keys_pressed:
			if keys_pressed[i]:
				
				keyStrings.append(OS.get_keycode_string(i))
		
		if %FileDialog.visible:
			return
			
		
		for key in keyStrings:
			var i = costumeKeys.find(key)
			if i >= 0:
				key_pressed.emit(costumeKeys[i])
