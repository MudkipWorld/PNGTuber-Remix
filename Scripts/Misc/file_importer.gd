extends Node

var sprite = preload("res://Misc/SpriteObject/sprite_object.tscn")
var appendage = preload("res://Misc/AppendageObject/Appendage_object.tscn")


func import_sprite(path : String):
	var image_data :ImageData = ImageData.new()
	var spawn = sprite.instantiate()
	check_type(path, image_data, spawn)
	var img_tex : CanvasTexture = CanvasTexture.new()
	img_tex.diffuse_texture = image_data.runtime_texture
	spawn.get_node("%Sprite2D").texture = img_tex
	spawn.sprite_name = image_data.image_name
	spawn.referenced_data = image_data
	spawn.used_image_id = image_data.id
	return spawn

func import_appendage(path : String):
	var image_data :ImageData = ImageData.new()
	var spawn = appendage.instantiate()
	var img_tex : CanvasTexture = CanvasTexture.new()
	check_type(path, image_data, spawn)
	img_tex.diffuse_texture = image_data.runtime_texture
	spawn.get_node("%Sprite2D").texture = img_tex
	spawn.sprite_name = image_data.image_name
	spawn.referenced_data = image_data
	spawn.used_image_id = image_data.id
	return spawn

func check_type(path, image_data, spawn):
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	if path.get_extension() == "gif":
		ImageTextureLoaderManager.import_gif(path, image_data)
	elif apng_test != ["No frames", null]:
		ImageTextureLoaderManager.import_apng_sprite(path, image_data)
	else:
		var warn : bool = false
		ImageTextureLoaderManager.import_png_from_file(path,spawn,image_data)
		if image_data.runtime_texture.get_size().x > 1280 or image_data.runtime_texture.get_size().y > 1280:
			warn = true 
		if warn:
			Global.show_warning = warn
	
	Global.image_manager_data.append(image_data)
	Global.add_new_image.emit(image_data)

func add_normal(path):
	var image_data :ImageData = ImageData.new()
	if path.get_extension() == "gif":
		ImageTextureLoaderManager.import_gif(path , image_data)
	else:
		var apng_test = AImgIOAPNGImporter.load_from_file(path)
		if apng_test != ["No frames", null]:
			ImageTextureLoaderManager.import_apng_sprite(path , image_data)
		else:
			var img = Image.load_from_file(path)
			if ImageTextureLoaderManager.trim:
				if !Global.held_sprites[0].referenced_data.image_data.is_empty():
					var og_image = Image.new()
					og_image.load_png_from_buffer(Global.held_sprites[0].referenced_data.image_data)
					img = ImageTrimmer.trim_normal(og_image, img)
					
			if ImageTextureLoaderManager.trim:
				if Settings.theme_settings.save_raw_sprite:
					var buffer = FileAccess.get_file_as_bytes(path)
					image_data.image_data = buffer
				else:
					image_data.image_data = []
			else:
				image_data.image_data = []
			img.fix_alpha_edges()
			var texture = ImageTexture.create_from_image(img)
			image_data.runtime_texture = texture
	
	var normal = image_data.runtime_texture
	if ImageTextureLoaderManager.check_valid(Global.held_sprites[0], image_data):
		normal = ImageTextureLoaderManager.check_flips(image_data.runtime_texture, Global.held_sprites[0])
	Global.held_sprites[0].referenced_data_normal = image_data
	Global.held_sprites[0].used_image_id_normal = image_data.id
	Global.image_manager_data.append(image_data)
	Global.add_new_image.emit(image_data)
	Global.held_sprites[0].get_node("%Sprite2D").texture.normal_texture = normal

	Global.get_sprite_states(Global.current_state)

func replace_texture(path : String):
	var image_data :ImageData = ImageData.new()
	if path.get_extension().to_lower() == "gif":
		ImageTextureLoaderManager.import_gif(path, image_data)
		Global.held_sprites[0].referenced_data_normal = null
		Global.held_sprites[0].used_image_id_normal = 0
		
	else:
		var apng_test = AImgIOAPNGImporter.load_from_file(path)
		if apng_test != ["No frames", null]:
			ImageTextureLoaderManager.import_apng_sprite(path, image_data)
			Global.held_sprites[0].referenced_data_normal = null
			Global.held_sprites[0].used_image_id_normal = 0
		else:
			var img = Image.load_from_file(path)
			var og_image = img.duplicate(true)
			image_data.trimmed = true
			if ImageTextureLoaderManager.trim:
				img = ImageTrimmer.trim_image(img)
				if ImageTextureLoaderManager.should_offset:
					var original_width = og_image.get_width()
					var original_height = og_image.get_height()
					var trimmed_width = img.get_width()
					var trimmed_height = img.get_height()
					# Calculate offset to maintain visual position
					var trim_info = ImageTrimmer.calculate_trim_info(og_image)
					var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
					var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
					image_data.offset = Vector2(center_shift_x, center_shift_y)
					# Adjust position to keep image visually stable
					var glob_pos : Array = []
					for i in Global.held_sprites[0].get_node("%Sprite2D").get_children():
						if i is SpriteObject:
							glob_pos.append({obj = i,
							og_pos = i.global_position})
					Global.held_sprites[0].sprite_data.offset += Vector2(center_shift_x, center_shift_y)
					Global.held_sprites[0].get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
					for i in glob_pos:
						i.obj.global_position = i.og_pos
						i.obj.sprite_data.position = i.obj.position
						i.obj.save_state(Global.current_state)
					
				Global.update_offset_spins.emit()
			if ImageTextureLoaderManager.trim:
				if Settings.theme_settings.save_raw_sprite:
					var buffer = FileAccess.get_file_as_bytes(path)
					image_data.image_data = buffer
				else:
					image_data.image_data = []
			else:
				image_data.image_data = []
				
			
			img.fix_alpha_edges()
			var texture = ImageTexture.create_from_image(img)
			image_data.runtime_texture = texture
			
	image_data.image_name = path.get_file().get_basename()
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = image_data.runtime_texture
	Global.held_sprites[0].get_node("%Sprite2D").texture = img_can
	Global.held_sprites[0].save_state(Global.current_state)
	ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
	Global.image_manager_data.append(image_data)
	if Global.held_sprites[0].sprite_type == "WiggleApp":
		Global.held_sprites[0].correct_sprite_size()
		Global.held_sprites[0].update_wiggle_parts()
		
	Global.held_sprites[0].used_image_id = image_data.id
	Global.held_sprites[0].referenced_data = image_data
	Global.held_sprites[0].rotated = 0
	Global.held_sprites[0].flipped_h = false
	Global.held_sprites[0].flipped_v = false
	Global.held_sprites[0].get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
	Global.get_sprite_states(Global.current_state)
	Global.reinfo.emit()
	Global.add_new_image.emit(image_data)

func _on_confirm_trim_confirmed() -> void:
	if get_parent().current_state == get_parent().State.AddNormal:
		ImageTextureLoaderManager.trim = true
		add_normal(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.ReplaceSprite:
		ImageTextureLoaderManager.trim = true
		replace_texture(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.LoadFile:
		ImageTextureLoaderManager.trim = true
		SaveAndLoad.load_file(get_parent().model_path)
	else:
		ImageTextureLoaderManager.trim = true
		get_parent().import_objects()

func _on_confirm_trim_canceled() -> void:
	if get_parent().current_state == get_parent().State.AddNormal:
		ImageTextureLoaderManager.trim = false
		add_normal(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.ReplaceSprite:
		ImageTextureLoaderManager.trim = false
		replace_texture(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.LoadFile:
		ImageTextureLoaderManager.trim = false
		SaveAndLoad.load_file(get_parent().model_path)
	else:
		ImageTextureLoaderManager.trim = false
		get_parent().import_objects()

func import_png_from_buffer(buffer, spawn) -> CanvasTexture:
	var img = Image.new()
	img.load_png_from_buffer(buffer)
	var og_image = img.duplicate(true)
	if ImageTextureLoaderManager.trim:
		img = ImageTrimmer.trim_image(img)
		var original_width = og_image.get_width()
		var original_height = og_image.get_height()
		var trimmed_width = img.get_width()
		var trimmed_height = img.get_height()
		# Calculate offset to maintain visual position
		var trim_info = ImageTrimmer.calculate_trim_info(og_image)
		var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
		var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
		# Adjust position to keep image visually stable
		spawn.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
		spawn.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
	img.fix_alpha_edges()
	var texture = ImageTexture.create_from_image(img)
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = texture
	return img_can

func _on_offset_sprite_toggled(toggled_on: bool) -> void:
	ImageTextureLoaderManager.should_offset = toggled_on
