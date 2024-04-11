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

@onready var origin = %SpritesContainer

func _ready():
	%FileDialog.use_native_dialog = true

func new_file():
	%ConfirmationDialog.popup()

func load_file():
	%FileDialog.filters = ["*.pngRemix"]
	$FileDialog.file_mode = 0
	current_state = State.LoadFile
	%FileDialog.show()

func save_as_file():
	%FileDialog.filters = ["*.pngRemix"]
	$FileDialog.file_mode = 4
	current_state = State.SaveFileAs
	%FileDialog.show()

func load_sprites():
	%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg", "*.gif"]
	$FileDialog.file_mode = 1
	current_state = State.LoadSprites
	%FileDialog.show()


func load_append_sprites():
	%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg", "*.gif"]
	$FileDialog.file_mode = 1
	current_state = State.AddAppend
	%FileDialog.show()


func replacing_sprite():
	if Global.held_sprite != null:
		if not Global.held_sprite.dictmain.folder:
			%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg", "*.gif"]
			$FileDialog.file_mode = 0
			current_state = State.ReplaceSprite
			%FileDialog.show()

func add_normal_sprite():
	if Global.held_sprite != null:
		if not Global.held_sprite.dictmain.folder:
			if Global.held_sprite.img_animated:
				%FileDialog.filters = ["*.gif"]
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
				Global.held_sprite.save_state(Global.current_state)
				Global.held_sprite.treeitem.set_icon(0, gif_tex)
				var g_sp = Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture
				

			else:
				var img = Image.load_from_file(path)
				var texture = ImageTexture.create_from_image(img)
				var img_can = CanvasTexture.new()
				Global.held_sprite.img_animated = false
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
				var img = Image.load_from_file(path)
				var texture = ImageTexture.create_from_image(img)
				var img_can = CanvasTexture.new()
				img_can.diffuse_texture = texture
				sprte_obj.texture = img_can
				sprte_obj.img_animated = false
				sprte_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can


			sprte_obj.sprite_id = sprte_obj.get_instance_id()
			sprte_obj.sprite_name = path.get_file()
			sprte_obj.states = []
			for i in Global.settings_dict.states.size():
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
			%BGContainer.add_child(bg_sprte_obj)
			bg_sprte_obj.texture = img_can
			bg_sprte_obj.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture = img_can
			bg_sprte_obj.sprite_name = path.get_file()
		
			bg_sprite_nodes.append(bg_sprte_obj)
			
		#	bg_sprte_obj.global_position = Vector2(640, 360)
		$Control/BackgroundEdit._added_tree(bg_sprite_nodes)


func _on_confirmation_dialog_confirmed():
	clear_sprites()

func clear_sprites():
	Global.held_sprite = null
	$Control/UIInput.held_sprite_is_null()
	$Control/LeftPanel/VBox/Panel/LayersTree.clear()
	$Control/LeftPanel/VBox/Panel2/BackgroundTree.clear()
	for i in get_tree().get_nodes_in_group("Sprites"):
		i.queue_free()
	for i in get_tree().get_nodes_in_group("BackgroundStuff"):
		i.queue_free()
	
	$Control.new_tree()
	$Control/BackgroundEdit.new_tree()
	$Control/StatesStuff.delete_all_states()
	$Control/StatesStuff.initial_state()

func _input(event):
	if can_scroll && not Input.is_action_pressed("ctrl"):
		if event.is_action_pressed("scrollup"):
			if %Camera2D.zoom != Vector2(4,4):
				%Camera2D.zoom += Vector2(0.1,0.1)
		elif event.is_action_pressed("scrolldown"):
			if %Camera2D.zoom > Vector2(0.1,0.1):
				%Camera2D.zoom -= Vector2(0.1,0.1)

func _on_sub_viewport_container_mouse_entered():
	can_scroll = true

func _on_sub_viewport_container_mouse_exited():
	can_scroll = false

func _on_background_input_capture_bg_key_pressed(_node, keys_pressed):
	if Global.settings_dict.checkinput:
		var keyStrings = []
		var costumeKeys = []
		for l in get_tree().get_nodes_in_group("StateButtons"):
			if InputMap.action_get_events(l.input_key).size() != 0:
				costumeKeys.append(InputMap.action_get_events(l.input_key)[0].as_text())
		
		
		for i in keys_pressed:
			if keys_pressed[i]:
				
				keyStrings.append(OS.get_keycode_string(i))
		
		if %FileDialog.visible:
			return
			
		
		for key in keyStrings:
			var i = costumeKeys.find(key)
			if i >= 0:
				print(i)
				key_pressed.emit(i)
