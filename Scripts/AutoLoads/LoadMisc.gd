extends Node


func load_pngplus_file(path, can_load_plus):
	if not can_load_plus:
		return
	Global.delete_states.emit()
	Global.main.clear_sprites()
	Global.main.get_node("Timer").start()
	await Global.main.get_node("Timer").timeout
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = JSON.parse_string(file.get_as_text())
	file.close()
	file = null
	if load_dict == null or load_dict.size() < 1:
		return
	if not load_dict["0"].has("identification"):
		print("Failed to load PNGTuber Plus file: Missing identification.")
		return
	Global.image_manager_data = []
	Global.save_path = path
	var entries : Array = []
	var idx : int = 0
	for k in load_dict.keys():
		var d = load_dict[k]
		var z : int = 0
		if d.has("zindex"):
			if typeof(d.zindex) == TYPE_INT:
				z = d.zindex
			elif typeof(d.zindex) == TYPE_FLOAT:
				z = int(d.zindex)
			elif typeof(d.zindex) == TYPE_STRING and d.zindex.is_valid_integer():
				z = int(d.zindex)

		var ident := 0
		if d.has("identification"):
			ident = int(d.identification)
		entries.append({
			"key": k,
			"data": d,
			"zindex": z,
			"ident": ident,
			"orig_index": idx
		})
		idx += 1

	entries.sort_custom(func(a, b):
		if a.ident + a.zindex < b.orig_index:
			return 1
		return 0
	)
	var warn : bool = false
	for i in entries:
		var data = i.data
		var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		sprite_obj.sprite_type = "Sprite2D"
		var img_data = Marshalls.base64_to_raw(data["imageData"])
		var image_data = ImageData.new()
		var img = Image.new()
		img.load_png_from_buffer(img_data)
		var animSpeed = data["animSpeed"]
		if animSpeed != 0.0:
			image_data.image_data = []
			image_data.trimmed = false
			image_data.sprite_sheet = true
		else:
			if ImageTextureLoaderManager.trim:
				var og_image = img.duplicate(true)
				img = ImageTrimmer.trim_image(img)
				var original_width = og_image.get_width()
				var original_height = og_image.get_height()
				var trimmed_width = img.get_width()
				var trimmed_height = img.get_height()
				var trim_info = ImageTrimmer.calculate_trim_info(og_image)
				if !trim_info.is_empty():
					var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
					var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
					sprite_obj.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
					sprite_obj.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
					image_data.offset += Vector2(center_shift_x, center_shift_y)
					if Settings.theme_settings.save_raw_sprite:
						image_data.image_data = img_data
						image_data.trimmed = true
					else:
						image_data.image_data = []
						image_data.trimmed = false
				else:
					img.resize(32,32, Image.INTERPOLATE_BILINEAR)
					image_data.image_data = []
					image_data.trimmed = true
			else:
				image_data.image_data = []
				image_data.trimmed = false
		img.fix_alpha_edges()
		var tex = ImageTexture.create_from_image(img)
		image_data.runtime_texture = tex
		image_data.img_animated = false
		image_data.is_apng = false
		image_data.image_name = data["path"].get_file().trim_suffix(".png")
		Global.image_manager_data.append(image_data)

		var canv = CanvasTexture.new()
		canv.diffuse_texture = image_data.runtime_texture
		sprite_obj.get_node("%Sprite2D").texture = canv
		if image_data.runtime_texture.get_size().x > 1280 or image_data.runtime_texture.get_size().y > 1280:
			warn = true 
		

		sprite_obj.referenced_data = image_data
		sprite_obj.used_image_id = image_data.id
		sprite_obj.is_plus_first_import = true
		sprite_obj.sprite_id = data["identification"]

		var id = data.get("parentId", 0)
		if id == null:
			id = 0
		sprite_obj.parent_id = id

		sprite_obj.sprite_name = data["path"].get_file().trim_suffix(".png")

		# Apply all physics/motion data
		sprite_obj.sprite_data.xFrq = data["xFrq"]
		sprite_obj.sprite_data.xAmp = float(data["xAmp"])
		sprite_obj.sprite_data.yFrq = data["yFrq"]
		sprite_obj.sprite_data.yAmp = float(data["yAmp"])
		sprite_obj.sprite_data.dragSpeed = data["drag"]
		sprite_obj.sprite_data.rdragStr = data["rotDrag"]
		sprite_obj.sprite_data.stretchAmount = data["stretchAmount"]
		sprite_obj.sprite_data.ignore_bounce = data["ignoreBounce"]
		sprite_obj.sprite_data.hframes = data["frames"]

		if animSpeed != 0.0:
			sprite_obj.sprite_data.animation_speed = 60 / int(360.0 / max(float(animSpeed), 1.0))

		sprite_obj.sprite_data.clip = 2 if data["clipped"] else 0

		sprite_obj.sprite_data.rLimitMin = data["rLimitMin"]
		sprite_obj.sprite_data.rLimitMax = data["rLimitMax"]
		sprite_obj.sprite_data.z_index = data["zindex"]
		sprite_obj.sprite_data.position = str_to_var(data["pos"])
		sprite_obj.sprite_data.offset += str_to_var(data["offset"])

		# --- Blink and Talk ---
		var blink_mode = data["showBlink"]
		if blink_mode == 0:
			sprite_obj.sprite_data.should_blink = false
			sprite_obj.sprite_data.open_eyes = false
		elif blink_mode == 1:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = true
		elif blink_mode == 2:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = false

		var talk_mode = data["showTalk"]
		if talk_mode == 0:
			sprite_obj.sprite_data.should_talk = false
			sprite_obj.sprite_data.open_mouth = false
		elif talk_mode == 1:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = false
		elif talk_mode == 2:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = true

		# --- States ---
		sprite_obj.states = [{}]
		sprite_obj.states[0].merge(sprite_obj.sprite_data, true)
		var costume = str_to_var(data["costumeLayers"])
		sprite_obj.states.resize(10)
		for l in range(costume.size()):
			var ndict = sprite_obj.sprite_data.duplicate()
			ndict.visible = costume[l] != 0
			sprite_obj.states[l] = ndict

		Global.sprite_container.add_child(sprite_obj)
		sprite_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		sprite_obj.get_state(0)

	Global.show_warning = warn
	Global.remake_for_plus.emit()
	Global.load_sprite_states(0)
	Global.remake_layers.emit()
	Global.slider_values.emit(Global.settings_dict)
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))

	for spr in get_tree().get_nodes_in_group("Sprites"):
		spr.reposition_plus(get_tree().get_nodes_in_group("Sprites"))

	Global.settings_dict.should_delta = false
	Global.reinfoanim.emit()
	Global.remake_image_manager.emit()
	Global.main.get_node("%Marker").current_screen = Monitor.ALL_SCREENS
	Global.load_model.emit()
	Global.load_sprite_states(0)
	Global.project_updates.emit("Plus Project Loaded!")


#----------------------------------------------------------------------------
# Global Image loading from PSD
func load_images_from_psd(path : String):
	var loaded_layers : Array = []
	loaded_layers = PSDParser.open_photoshop_file(path)
	
	ImageTextureLoaderManager.trim = false
	ImageTextureLoaderManager.should_offset = false
	for layer in loaded_layers:
		#print(layer)
		if layer["type"] == "layer":
			var image_data : ImageData = ImageData.new()
			ImageTextureLoaderManager.import_png(layer["image"], null, image_data, false, false)
			image_data.image_name = layer["name"]
			image_data.offset = layer["offset"]
			image_data.trimmed = true
			Global.image_manager_data.append(image_data)
			Global.add_new_image.emit(image_data)
			add_objects_from_psd_data(layer, image_data)
		else:
			add_objects_from_psd_data(layer, null)
	Global.remake_layers.emit()
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))

func add_objects_from_psd_data(layer, image_data = null):
	var spawn
	if layer["type"] == "layer" && image_data != null:
		spawn = add_object_to_scene(image_data, false, false, true)
	else:
		spawn = add_object_to_scene(null, false, true, false, layer["name"])
	fix_ids(spawn, layer)

static func fix_ids(spawn, fixed_ids):
	spawn.sprite_id = fixed_ids["id"]
	spawn.parent_id = fixed_ids["parent_id"]

#----------------------------------------------------------------------------
# Global Simple Object addition
func add_object_to_scene(image_data, add_as_appendage : bool = false, folder : bool = false, force_offset : bool = false, custom_name : String = ""):
	var spawn 
	if add_as_appendage:
		spawn = ImageTextureLoaderManager.appendage_scene.instantiate()
	else:
		spawn = ImageTextureLoaderManager.sprite_scene.instantiate()
	if (ImageTextureLoaderManager.should_offset or force_offset) && !folder:
		spawn.sprite_data.offset += image_data.offset
		spawn.get_node("%Sprite2D").position += image_data.offset
	if !folder:
		var img_tex : CanvasTexture = CanvasTexture.new()
		img_tex.diffuse_texture = image_data.runtime_texture
		spawn.get_node("%Sprite2D").texture = img_tex
		spawn.sprite_name = image_data.image_name
		spawn.referenced_data = image_data
		spawn.used_image_id = image_data.id
	else:
		var canv = CanvasTexture.new()
		spawn.get_node("%Sprite2D").texture = canv
		spawn.sprite_name = custom_name
		spawn.sprite_data.folder = true
		
	spawn.sprite_id = spawn.get_instance_id()
	spawn.disappear_keys = str(spawn.sprite_id) + "Disappear"
	if add_as_appendage:
		spawn.correct_sprite_size()
	Global.sprite_container.add_child(spawn)
	if !force_offset && !folder:
		Global.update_layers.emit(0, spawn, "Sprite")
		ImageTrimmer.set_thumbnail(spawn.treeitem)
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		spawn.states.append(spawn.sprite_data.duplicate(true))
	 
	return spawn
