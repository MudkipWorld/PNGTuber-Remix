extends Node


var save_dict : Dictionary = {}


func save_file(path):
	var sprites = get_tree().get_nodes_in_group("Sprites")
	var bg_sprites = get_tree().get_nodes_in_group("BackgroundStuff")
	var inputs = get_tree().get_nodes_in_group("StateRemapButton")
	
	var sprites_array : Array = []
	var bg_sprites_array : Array = []
	var input_array : Array = []
	
	for sprt in sprites:
		sprt.save_state(Global.current_state)
		var img = Marshalls.raw_to_base64(sprt.get_node("Wobble/Squish/Drag/Sprite2D").texture.diffuse_texture.get_image().save_png_to_buffer())
		var normal_img
		if sprt.get_node("Wobble/Squish/Drag/Sprite2D").texture.normal_texture:
			normal_img = Marshalls.raw_to_base64(sprt.get_node("Wobble/Squish/Drag/Sprite2D").texture.normal_texture.get_image().save_png_to_buffer())
		else:
			normal_img = null
		var sprt_dict = {
			img = img,
			normal = normal_img,
			states = sprt.states,
			sprite_name = sprt.sprite_name,
			sprite_id = sprt.sprite_id,
			parent_id = sprt.parent_id,
			sprite_type = sprt.sprite_type
		}
		sprites_array.append(sprt_dict)
	
	for sprt in bg_sprites:
		sprt.save_state(Global.current_state)
		var img = Marshalls.raw_to_base64(sprt.get_node("Wobble/Squish/Drag/Sprite2D").texture.diffuse_texture.get_image().save_png_to_buffer())
		var normal_img
		if sprt.get_node("Wobble/Squish/Drag/Sprite2D").texture.normal_texture:
			normal_img = Marshalls.raw_to_base64(sprt.get_node("Wobble/Squish/Drag/Sprite2D").texture.normal_texture.get_image().save_png_to_buffer())
		else:
			normal_img = null
		var sprt_dict = {
			img = img,
			normal = normal_img,
			states = sprt.states,
			sprite_name = sprt.sprite_name,
			sprite_id = sprt.sprite_id,
		}
		bg_sprites_array.append(sprt_dict)
	
	for input in inputs:
		input_array.append(input.saved_event)
	
	
	save_dict = {
		sprites_array = sprites_array,
		settings_dict = Global.settings_dict,
		input_array = input_array,
		bg_sprites_array = bg_sprites_array
	}
	
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_var(save_dict, true)
		file.close()
	else:
		var file = FileAccess.open(path + ".pngRemix", FileAccess.WRITE)
		file.store_var(save_dict, true)
		file.close()


func load_file(path):
	get_tree().get_root().get_node("Main").clear_sprites()
	
	get_tree().get_root().get_node("Main/Timer").start()
	await get_tree().get_root().get_node("Main/Timer").timeout
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = file.get_var(true)
	
	Global.settings_dict.merge(load_dict.settings_dict, true)
	if load_dict.has("bg_sprites_array"):
		for sprite in load_dict.bg_sprites_array:
			var sprite_obj = preload("res://Misc/BackgroundObject/background_object.tscn").instantiate()
			var img_data = Marshalls.base64_to_raw(sprite.img)
			var img = Image.new()
			img.load_png_from_buffer(img_data)
			var img_tex = ImageTexture.new()
			img_tex.set_image(img)
			var img_can = CanvasTexture.new()
			img_can.diffuse_texture = img_tex
			sprite_obj.get_node("Wobble/Squish/Drag/Sprite2D").texture = img_can
			sprite_obj.states = sprite.states
			sprite_obj.sprite_name = sprite.sprite_name
			
			get_tree().get_root().get_node("Main/SubViewportContainer2/SubViewport/BackgroundStuff/BGContainer").add_child(sprite_obj)
			sprite_obj.get_state(0)
	
	for sprite in load_dict.sprites_array:
		var sprite_obj
		if sprite.has("sprite_type"):
			if sprite.sprite_type == "Sprite2D":
				sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			elif sprite.sprite_type == "WiggleApp":
				sprite_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn").instantiate()
		else:
			sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		
		var img_data = Marshalls.base64_to_raw(sprite.img)
		var img = Image.new()
		img.load_png_from_buffer(img_data)
		var img_tex = ImageTexture.new()
		img_tex.set_image(img)
		var img_can = CanvasTexture.new()
		img_can.diffuse_texture = img_tex
		if sprite.has("normal"):
			if sprite.normal != null:
				var img_normal = Marshalls.base64_to_raw(sprite.normal)
				var nimg = Image.new()
				nimg.load_png_from_buffer(img_normal)
				var nimg_tex = ImageTexture.new()
				nimg_tex.set_image(nimg)
				img_can.normal_texture = nimg_tex
		sprite_obj.get_node("Wobble/Squish/Drag/Sprite2D").texture = img_can
#		sprite_obj.get_node("Wobble/Squish/Drag/Sprite2D").texture.normal_texture = img_tex
		sprite_obj.states = sprite.states
		sprite_obj.sprite_id = sprite.sprite_id
		sprite_obj.parent_id = sprite.parent_id
		sprite_obj.sprite_name = sprite.sprite_name

		
		get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer").add_child(sprite_obj)
		

#	'''
	for input in len(load_dict.input_array):
		get_tree().get_nodes_in_group("StateRemapButton")[input].saved_event = load_dict.input_array[input]
		
		get_tree().get_nodes_in_group("StateRemapButton")[input].update_stuff()
#	'''
	
	Global.load_sprite_states(0)
	get_tree().get_root().get_node("Main/Control").loaded_tree(get_tree().get_nodes_in_group("Sprites"))
	get_tree().get_root().get_node("Main/Control/BackgroundEdit").loaded_tree(get_tree().get_nodes_in_group("BackgroundStuff"))
	get_tree().get_root().get_node("Main/Control").sliders_revalue(Global.settings_dict)
	Global.load_sprite_states(0)
	get_tree().get_root().get_node("Main/Control/UIInput").reinfoanim()
	
	file.close()
