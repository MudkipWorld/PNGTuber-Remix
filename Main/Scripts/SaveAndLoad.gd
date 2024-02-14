extends Node


var save_dict : Dictionary = {}

func save_file(path):
	var sprites = get_tree().get_nodes_in_group("Sprites")
	var inputs = get_tree().get_nodes_in_group("StateButtons")
	var bounce = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
	var blink = Global.blink_speed
	var check_input = Global.checkinput
	var mic = GlobalAudioStreamPlayer
	
	var sprites_array : Array = []
	var input_array : Array = []
	
	for sprt in sprites:
		var img = Marshalls.raw_to_base64(sprt.get_node("Wobble/Squish/Drag/Sprite2D").texture.get_image().save_png_to_buffer())
		var sprt_dict = {
			img = img,
			states = sprt.states,
			sprite_name = sprt.sprite_name
		}
		sprites_array.append(sprt_dict)
	
	for input in inputs:
		input_array.append(input.input_key)
	
	save_dict = {
		sprites_array = sprites_array,
		input_array = input_array,
		blink = blink,
		bounce = bounce.bounceSlider,
		gravity = bounce.bounceGravity,
		volume_limit = mic.volume_limit,
		sens_limit = mic.sensitivity_limit,
		check_input = check_input
	}
	
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_var(save_dict)
		file.close()
	else:
		var file = FileAccess.open(path + ".pngRemix", FileAccess.WRITE)
		file.store_var(save_dict)
		file.close()

func load_file(path):
	var bounce = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
	var blink = Global.blink_speed
	var mic = GlobalAudioStreamPlayer
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = file.get_var()
	
	blink = load_dict.blink
	mic.volume_limit = load_dict.volume_limit
	mic.sensitivity_limit = load_dict.sens_limit
	bounce.bounceSlider = load_dict.bounce
	bounce.bounceGravity = load_dict.gravity
	Global.checkinput = load_dict.check_input
	
	for sprite in load_dict.sprites_array:
		var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		
		var img_data = Marshalls.base64_to_raw(sprite.img)
		var img = Image.new()
		img.load_png_from_buffer(img_data)
		var img_tex = ImageTexture.new()
		img_tex.set_image(img)
		sprite_obj.get_node("Wobble/Squish/Drag/Sprite2D").texture = img_tex
		sprite_obj.states = sprite.states
		
		sprite_obj.sprite_name = sprite.sprite_name
		
		bounce.add_child(sprite_obj)

	for input in len(load_dict.input_array):
		get_tree().get_nodes_in_group("StateButtons")[input].input_key = load_dict.input_array[input]
		get_tree().get_nodes_in_group("StareRemapButton")[input].text = load_dict.input_array[input]
	
	Global.get_sprite_states(0)
	get_tree().get_root().get_node("Main/Control")._tree(get_tree().get_nodes_in_group("Sprites"))
	get_tree().get_root().get_node("Main/Control").sliders_revalue(mic.volume_limit, mic.sensitivity_limit, bounce.bounceSlider, bounce.bounceGravity, Global.checkinput)
	
	file.close()
