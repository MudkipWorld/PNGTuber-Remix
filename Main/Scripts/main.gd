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
	%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg"]
	$FileDialog.file_mode = 1
	current_state = State.LoadSprites
	%FileDialog.show()


func load_append_sprites():
	%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg"]
	$FileDialog.file_mode = 1
	current_state = State.AddAppend
	%FileDialog.show()


func replacing_sprite():
	if Global.held_sprite != null:
		if not Global.held_sprite.dictmain.folder:
			%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg"]
			$FileDialog.file_mode = 0
			current_state = State.ReplaceSprite
			%FileDialog.show()

func add_normal_sprite():
	if Global.held_sprite != null:
		if not Global.held_sprite.dictmain.folder:
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
			var img = Image.load_from_file(path)
			var texture = ImageTexture.create_from_image(img)
			var img_can = CanvasTexture.new()
			img_can.diffuse_texture = texture
			Global.held_sprite.texture = img_can
			Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture = img_can
			Global.held_sprite.save_state(current_state)
			Global.held_sprite.treeitem.set_icon(0, texture)
			Global.get_sprite_states(Global.current_state)
			
		State.AddNormal:
			var img = Image.load_from_file(path)
			var texture = ImageTexture.create_from_image(img)
			Global.held_sprite.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture.normal_texture = texture
			Global.get_sprite_states(Global.current_state)

func _on_file_dialog_files_selected(paths):
	if current_state == State.LoadSprites or current_state == State.AddAppend:
		var sprite_nodes = []
		for path in paths:
			var img = Image.load_from_file(path)
			var texture = ImageTexture.create_from_image(img)
			var img_can = CanvasTexture.new()
			img_can.diffuse_texture = texture
			var sprte_obj
			if current_state == State.LoadSprites:
				sprte_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			elif current_state == State.AddAppend:
				sprte_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn").instantiate()
			%SpritesContainer.add_child(sprte_obj)
			sprte_obj.texture = img_can
			sprte_obj.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture = img_can
			if current_state == State.AddAppend:
				var size_ratio = sprte_obj.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture.diffuse_texture.get_image().get_size()/100
			#	print(size_ratio)
				sprte_obj.scale = Vector2(size_ratio.x, size_ratio.y *12)
				sprte_obj.dictmain.scale = Vector2(size_ratio.x, size_ratio.y *12)
			
			sprte_obj.sprite_id = sprte_obj.get_instance_id()
			sprte_obj.sprite_name = path.get_file()
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
