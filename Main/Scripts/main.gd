extends Control

signal key_pressed

var filepath : Array = []
enum State {
	LoadFile,
	SaveFile,
	SaveFileAs,
	LoadSprites,
	ReplaceSprite
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

func replacing_sprite():
	if Global.held_sprite != null:
		if not Global.held_sprite.folder:
			%FileDialog.filters = ["*.png", "*.jpeg", "*.jpg", "*.svg"]
			$FileDialog.file_mode = 0
			current_state = State.ReplaceSprite
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
			Global.held_sprite.texture = texture
			Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D").texture = texture
			Global.held_sprite.save_state(current_state)
			$Control._tree(get_tree().get_nodes_in_group("Sprites"))

func _on_file_dialog_files_selected(paths):
	for path in paths:
		var img = Image.load_from_file(path)
		var texture = ImageTexture.create_from_image(img)
		
		var sprte_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		%SpritesContainer.add_child(sprte_obj)
		sprte_obj.texture = texture
		sprte_obj.get_node("Wobble/Squish/Drag/Sprite2D").texture = texture
		sprte_obj.sprite_name = str(path)
		
	var sprite_nodes = get_tree().get_nodes_in_group("Sprites")
	$Control._tree(sprite_nodes)

func _on_confirmation_dialog_confirmed():
	Global.held_sprite = null
	$Control/UIInput.held_sprite_is_null()
	$Control/LeftPanel/VBox/Panel/LayersTree.clear()
	for i in %SpritesContainer.get_children():
		i.queue_free()

func _input(event):
	if can_scroll:
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
	if Global.checkinput:
		var keyStrings = []
		var costumeKeys = []
		for l in get_tree().get_nodes_in_group("StateButtons"):
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
