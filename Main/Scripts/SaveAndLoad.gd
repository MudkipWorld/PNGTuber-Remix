extends Node


var save_dict : Dictionary = {}
var can_load_plus : bool = false
const YIELD_EVERY : int = 25

var import_trimmed : bool = false
var import_resized : bool = false
var import_percent : float = 50.0
@onready var dire = Settings.path_helper(OS.get_executable_path().get_base_dir(), "/ExportedAssets")

func save_file(path : String):
	save_model(path)

func save_data():
	var sprites = get_tree().get_nodes_in_group("Sprites")
	var inputs = get_tree().get_nodes_in_group("StateButtons")
	var sprites_array : Array = []
	var input_array : Array = []
	var image_array : Array = []
	var seen_image_ids : Dictionary = {}
	save_dict.clear()
	for i in Global.image_manager_data:
		if !Settings.theme_settings.save_unused_files:
			var used : bool = false
			for sp in sprites:
				if sp.used_image_id == i.id or sp.used_image_id_normal == i.id:
					used = true
					break
			if !used:
				continue
		if seen_image_ids.has(i.id):
			continue
		seen_image_ids[i.id] = true

		var dict : Dictionary = i.get_data()
		image_array.append(dict)

	for input in inputs:
		input_array.append({
			"state_name": input.state_name,
			"hot_key": input.saved_event,
		})
	for sprt in sprites:
		sprt.save_state(Global.current_state)
		var cleaned_array := []
		for st in sprt.states:
			if not st.is_empty():
				cleaned_array.append(st.duplicate(true))
		
		var saved_events : Array = []
		
		if InputMap.has_action(sprt.disappear_keys):
			for key in InputMap.action_get_events(sprt.disappear_keys):
				saved_events.append(key)
		
		
		var base = {}
		if sprt.sprite_type == "Mesh":
			var mesh : CustomMesh = sprt.get_node("%Sprite2D")
			var saved_layers : Array = []
			
			for layer in mesh.get_layers():
				var data : Dictionary = {
					top_left = layer.top_left,
					top_middle = layer.top_middle,
					top_right = layer.top_right,
					middle_left = layer.middle_left,
					center = layer.center,
					middle_right = layer.middle_right,
					bottom_left = layer.bottom_left,
					bottom_middle = layer.bottom_middle,
					bottom_right = layer.bottom_right,
					external_velocity = layer.external_velocity,
					stiffness = layer.stiffness,
					damping = layer.damping,
					mass = layer.mass,
					follow_lerp = layer.follow_lerp,
					noise_speed = layer.noise_speed,
					noise_scale = layer.noise_scale,
					sine_speed = layer.sine_speed,
					sine_amplitude = layer.sine_amplitude,
					target_strength = layer.target_strength,
					motion = layer.motion
				}
				saved_layers.append(data)
			
			base = {
			"original_vertices": PackedVector2Array(mesh.original_vertices),
			"internal_vertices": PackedVector2Array(mesh.internal_vertices),
			"base_vertices": PackedVector2Array(mesh.base_vertices),
			"triangles": mesh.triangles,
			"states": cleaned_array,
			"deform_layers" : saved_layers,
			"sprite_name": sprt.sprite_name,
			"sprite_id": sprt.sprite_id,
			"parent_id": sprt.parent_id,
			"sprite_type": sprt.sprite_type,
			"is_asset": sprt.is_asset,
			"saved_event": sprt.saved_event,
			"was_active_before": sprt.was_active_before,
			"should_disappear": sprt.should_disappear,
			"show_only": sprt.show_only,
			"saved_disappear": saved_events,
			"hold_to_show":sprt.hold_to_show,
			"is_collapsed": sprt.is_collapsed,
			"is_premultiplied": true,
			"layer_color": sprt.layer_color,
			"image_id": sprt.used_image_id,
			"normal_id": sprt.used_image_id_normal,
			"rotated":sprt.rotated,
			"flipped_h":sprt.flipped_h,
			"flipped_v":sprt.flipped_v,
			"rest_mode": sprt.rest_mode
			}

		else:
			base = {
				"states": cleaned_array,
				"sprite_name": sprt.sprite_name,
				"sprite_id": sprt.sprite_id,
				"parent_id": sprt.parent_id,
				"sprite_type": sprt.sprite_type,
				"is_asset": sprt.is_asset,
				"saved_event": sprt.saved_event,
				"was_active_before": sprt.was_active_before,
				"should_disappear": sprt.should_disappear,
				"show_only": sprt.show_only,
				"saved_disappear": saved_events,
				"hold_to_show":sprt.hold_to_show,
				"is_collapsed": sprt.is_collapsed,
				"is_premultiplied": true,
				"layer_color": sprt.layer_color,
				"image_id": sprt.used_image_id,
				"normal_id": sprt.used_image_id_normal,
				"rotated":sprt.rotated,
				"flipped_h":sprt.flipped_h,
				"flipped_v":sprt.flipped_v,
				"rest_mode": sprt.rest_mode
			}
		sprites_array.append(base)
	save_dict = {
		"version": Global.version,
		"sprites_array": sprites_array,
		"settings_dict": Global.settings_dict,
		"input_array": input_array,
		"image_manager_data": image_array,
	}

func save_model(path):
	Global.save_path = path
	save_data()
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_var(save_dict, true)
	file.close()
	Global.project_updates.emit("Project Saved!")
	save_dict.clear()

func load_file(path: String, autoload : bool = false):
	if !FileAccess.file_exists(path):
		return
	if autoload:
		Settings.theme_settings.path = path
		Settings.save()
	Global.save_path = path
	can_load_plus = false
	if path.get_extension() == "save":
		can_load_plus = true
		load_pngplus_file(path)

	else:
		load_model(path)

func load_model(path: String) -> void:
	Global.delete_states.emit()
	Global.main.clear_sprites()
	Global.main.get_node("Timer").start()
	Global.delete_states.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: %s" % path)
		return
	var load_dict = file.get_var(true)
	file.close()

	if not load_dict.has("sprites_array"):
		return

	var file_version := ""
	if "version" in load_dict:
		file_version = load_dict.version

	if file_version != Global.version:
		if not path.begins_with("res://"):
			save_backup(load_dict, path)
			await get_tree().process_frame
		load_dict = VersionConverter.convert_save(load_dict, file_version)
		if OS.has_feature("editor") or not path.begins_with("res://"):
			var new_file := FileAccess.open(path, FileAccess.WRITE)
			new_file.store_var(load_dict, true)
			new_file.close()


	Global.settings_dict.merge(load_dict.settings_dict, true)
	if Global.settings_dict.monitor != Monitor.ALL_SCREENS:
		if Global.settings_dict.monitor >= DisplayServer.get_screen_count():
			Global.settings_dict.monitor = Monitor.ALL_SCREENS

	Global.remake_states.emit(load_dict.settings_dict.states)
	if not path.begins_with("res://"):
		Global.save_path = path
		
		
	load_objects(load_dict)

	if load_dict.input_array != null:
		var buttons = get_tree().get_nodes_in_group("StateButtons")
		var n = min(buttons.size(), load_dict.input_array.size())
		for i in range(n):
			var data = load_dict.input_array[i]
			var btn = buttons[i]
			if typeof(data) == TYPE_DICTIONARY:
				btn.saved_event = data.get("hot_key")
				btn.state_name = data.get("state_name", "")
				btn.text = data.get("state_name", "")
				btn.update_stuff()
			else:
				btn.saved_event = data
				btn.update_stuff()

	var state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			var to_add = state_count - i.states.size()
			for l in range(to_add):
				i.states.append(i.sprite_data.duplicate(true))

	Global.load_sprite_states(0)
	Global.remake_layers.emit()
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))

	if import_trimmed and !Global.settings_dict.trimmed:
		for i in get_tree().get_nodes_in_group("Sprites"):
			i.zazaza_reposition(get_tree().get_nodes_in_group("Sprites"))
		Global.settings_dict.trimmed = true
		import_trimmed = false

	for i in get_tree().get_nodes_in_group("Sprites"):
		i.old_reposition()

	Global.slider_values.emit(Global.settings_dict)
	if Global.main.has_node("%Control"):
		Global.reinfoanim.emit()
	if Global.settings_dict.anti_alias:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if Global.settings_dict.auto_save:
		Settings.save_timer.wait_time = Global.settings_dict.auto_save_timer * 60
		Settings.save_timer.start()
	else:
		Settings.save_timer.stop()

	Global.main.get_node("%Marker").current_screen = Global.settings_dict.monitor
	Global.project_updates.emit("Project Loaded!")
	Global.remake_image_manager.emit()
	Global.load_model.emit()
	Global.load_sprite_states(0)

func _resize_image_data(image_data: ImageData, sprite_node: Node2D, percent: float) -> void:
	if percent == 100.0 or image_data.runtime_texture == null:
		return
	var img: Image = image_data.runtime_texture.get_image().duplicate(true)
	var scale = percent / 100.0
	var new_w = max(int(img.get_width() * scale), 1)
	var new_h = max(int(img.get_height() * scale), 1)
	img.resize(new_w, new_h, Image.INTERPOLATE_LANCZOS)
	image_data.runtime_texture = ImageTexture.create_from_image(img)
	image_data.offset *= scale
	if sprite_node != null:
		sprite_node.position *= scale

func _resize_apng_frames(image_data: ImageData, percent: float) -> void:
	if percent == 100.0:
		return

	var scale = percent / 100.0
	for frame: AImgIOFrame in image_data.frames:
		var img := frame.content.duplicate(true)
		var new_w = max(int(img.get_width() * scale), 1)
		var new_h = max(int(img.get_height() * scale), 1)
		img.resize(new_w, new_h, Image.INTERPOLATE_LANCZOS)
		frame.content = img
	image_data.offset *= scale
	var first_frame: Image = image_data.frames[0].content
	image_data.runtime_texture = ImageTexture.create_from_image(first_frame)
	image_data.animated_frames.clear()
	for frame in image_data.frames:
		var af := AnimatedFrame.new()
		af.texture = ImageTexture.create_from_image(frame.content)
		af.duration = frame.duration
		image_data.animated_frames.append(af)
	var exporter := AImgIOAPNGExporter.new()
	var apng_bytes := exporter.export_animation(image_data.frames, 24, null, null, [])
	image_data.anim_texture = apng_bytes

func load_objects(load_dict: Dictionary) -> void:
	Global.image_manager_data.clear()
	var sheet_textures: Dictionary = {}

	if load_dict.has("sprites_array"):
		for sprite in load_dict.sprites_array:
			if typeof(sprite) != TYPE_DICTIONARY:
				continue
			if sprite.has("states"):
				for st in sprite.states:
					if typeof(st) != TYPE_DICTIONARY or st.is_empty():
						continue
					var hframes = st.get("hframes", 1)
					var vframes = st.get("vframes", 1)
					var non_animated_sheet = st.get("non_animated_sheet", false)
					var advanced_lipsync = st.get("advanced_lipsync", false)
					if hframes > 1 or vframes > 1 or non_animated_sheet or advanced_lipsync:
						var tex_name = sprite.get("image_id", 0)
						if tex_name != 0:
							sheet_textures[tex_name] = true

	var seen_ids: Dictionary = {}
	var arr = load_dict.get("image_manager_data", [])
	for i in arr:
		if typeof(i) != TYPE_DICTIONARY:
			continue
		var incoming_id = i.get("id", null)
		if incoming_id == null or seen_ids.has(incoming_id):
			continue
		seen_ids[incoming_id] = true

		var image_data: ImageData = ImageData.new()
		image_data.set_data(i)

		if import_trimmed and !Global.settings_dict.trimmed and !sheet_textures.has(image_data.id):
			image_data.trim_image()
		if import_resized and import_percent != 100.0:
			if image_data.is_apng:
				_resize_apng_frames(image_data, import_percent)
			else:
				_resize_image_data(image_data, null, import_percent)


		Global.image_manager_data.append(image_data)
	for sprite in load_dict.sprites_array:
		var sprite_obj
		if sprite.has("sprite_type") and sprite.sprite_type == "WiggleApp":
			sprite_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn").instantiate()
			set_common_data(sprite, sprite_obj)
			load_normal_objects(load_dict, sprite, sprite_obj)
		elif sprite.has("sprite_type") and sprite.sprite_type == "Comment":
			sprite_obj = preload("res://Misc/CommentObject/comment_object.tscn").instantiate()
			set_common_data(sprite, sprite_obj)
			load_comment_block_object(load_dict, sprite, sprite_obj)
		elif sprite.has("sprite_type") and sprite.sprite_type == "Mesh":
			sprite_obj = preload("res://Misc/MeshObject/mesh_object.tscn").instantiate()
			set_common_data(sprite, sprite_obj)
			load_mesh_object(load_dict, sprite, sprite_obj)
			
			
		else:
			sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			set_common_data(sprite, sprite_obj)
			load_normal_objects(load_dict, sprite, sprite_obj)

func set_common_data(sprite, sprite_obj):
	sprite_obj.layer_color = sprite.get("layer_color", Color.BLACK)
	sprite_obj.used_image_id = sprite.get("image_id", 0)
	sprite_obj.used_image_id_normal = sprite.get("normal_id", 0)
	sprite_obj.sprite_id = sprite.sprite_id
	sprite_obj.rest_mode = sprite.get("rest_mode", 1)
	if sprite.has("parent_id") and sprite.parent_id != null:
		sprite_obj.parent_id = sprite.parent_id

	if sprite.has("is_asset"):
		sprite_obj.is_asset = sprite.is_asset
		sprite_obj.saved_event = sprite.saved_event
		sprite_obj.should_disappear = sprite.should_disappear
		if sprite.has("show_only"):
			sprite_obj.show_only = sprite.show_only
		if sprite.has("hold_to_show"):
			sprite_obj.hold_to_show = sprite.hold_to_show
		sprite_obj.get_node("%Sprite2D").visible = sprite.was_active_before
		sprite_obj.was_active_before = sprite.was_active_before

		sprite_obj.disappear_keys = str(sprite.sprite_id) + "Disappear"
		if !InputMap.has_action(sprite_obj.disappear_keys):
			InputMap.add_action(sprite_obj.disappear_keys)
			for keys in sprite.get("saved_keys", []):
				var event = InputEventKey.new()
				event.keycode = OS.find_keycode_from_string(keys)
				InputMap.action_add_event(sprite_obj.disappear_keys, event)
			for keys in sprite.get("saved_disappear", []):
				InputMap.action_add_event(sprite_obj.disappear_keys, keys)

		if !InputMap.has_action(str(sprite.sprite_id)):
			InputMap.add_action(str(sprite.sprite_id))
			if sprite_obj.saved_event != null:
				InputMap.action_add_event(str(sprite.sprite_id), sprite_obj.saved_event)
	sprite_obj.sprite_name = sprite.sprite_name

func load_comment_block_object(_load_dict : Dictionary, sprite, sprite_obj):
	var cleaned_array := []
	for st in sprite.states:
		if not st.is_empty():
			if import_trimmed and !Global.settings_dict.trimmed and sprite_obj.referenced_data != null:
				st["offset"] += sprite_obj.referenced_data.offset
			if import_resized and import_percent != 100.0:
				var scale := import_percent / 100.0
				st["offset"] *= scale
				if st.has("position"):
					st["position"] *= scale
			cleaned_array.append(st)
	for st in cleaned_array:
		var new_dict = sprite_obj.sprite_data.duplicate()
		new_dict.merge(st, true)
		st = new_dict
	sprite_obj.states = cleaned_array
	if sprite.has("is_collapsed"):
		sprite_obj.is_collapsed = sprite.is_collapsed
	Global.sprite_container.add_child(sprite_obj)
	sprite_obj.sprite_type = "Comment"

func load_mesh_object(_load_dict: Dictionary, sprite, sprite_obj):
	var cleaned_array := []
	if !sprite.states[0].get("folder"):
		for i in Global.image_manager_data:
			if i.id == sprite_obj.used_image_id:
				sprite_obj.referenced_data = i
				sprite_obj.get_node("%Sprite2D").texture = ImageTextureLoaderManager.check_flips(i.runtime_texture, sprite_obj)
	for st in sprite.states:
		if not st.is_empty():
			if import_trimmed and !Global.settings_dict.trimmed and sprite_obj.referenced_data != null:
				st["offset"] += sprite_obj.referenced_data.offset
			if import_resized and import_percent != 100.0:
				var scale := import_percent / 100.0
				st["offset"] *= scale
				if st.has("position"):
					st["position"] *= scale
			cleaned_array.append(st)
	for st in cleaned_array:
		var new_dict = sprite_obj.sprite_data.duplicate()
		new_dict.merge(st, true)
		st = new_dict
	sprite_obj.states = cleaned_array
	if sprite.has("is_collapsed"):
		sprite_obj.is_collapsed = sprite.is_collapsed
	
	if sprite.has("original_vertices"):
		var mesh = sprite_obj.get_node("%Sprite2D")
		
		# 1. Load main geometry
		mesh.original_vertices = sprite.original_vertices.duplicate()
		mesh.base_vertices = sprite.base_vertices.duplicate()
		mesh.triangles = sprite.triangles.duplicate()
		mesh.internal_vertices = sprite.internal_vertices.duplicate()
		if sprite.has("deformation_3x3"):
			var d3 = sprite["deformation_3x3"]
			sprite_obj.get_node("%MeshEditor").add_layer()
			sprite_obj.get_node("%MeshEditor").add_layer()
			mesh.get_layer(1).top_left = _make_delta(d3[0].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).top_middle = _make_delta(d3[1].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).top_right = _make_delta(d3[2].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).middle_left = _make_delta(d3[3].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).center = _make_delta(d3[4].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).middle_right = _make_delta(d3[5].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).bottom_left = _make_delta(d3[6].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).bottom_middle =_make_delta(d3[7].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).bottom_right = _make_delta(d3[8].duplicate(), mesh.original_vertices)
		
		elif sprite.has("deform_layers"):
			var layers = sprite["deform_layers"]
			for idx in layers.size():
				sprite_obj.get_node("%MeshEditor").add_layer()
				mesh.get_layer(idx).top_left = layers[idx].top_left
				mesh.get_layer(idx).top_middle = layers[idx].top_middle
				mesh.get_layer(idx).top_right = layers[idx].top_right
				mesh.get_layer(idx).middle_left = layers[idx].middle_left
				mesh.get_layer(idx).center = layers[idx].center
				mesh.get_layer(idx).middle_right = layers[idx].middle_right
				mesh.get_layer(idx).bottom_left = layers[idx].bottom_left
				mesh.get_layer(idx).bottom_middle = layers[idx].bottom_middle
				mesh.get_layer(idx).bottom_right = layers[idx].bottom_right
				mesh.get_layer(idx).external_velocity = layers[idx].external_velocity
				mesh.get_layer(idx).stiffness = layers[idx].stiffness
				mesh.get_layer(idx).damping = layers[idx].damping
				mesh.get_layer(idx).mass = layers[idx].mass
				mesh.get_layer(idx).damping = layers[idx].damping
				mesh.get_layer(idx).mass = layers[idx].mass
				mesh.get_layer(idx).follow_lerp = layers[idx].follow_lerp
				mesh.get_layer(idx).noise_speed = layers[idx].noise_speed
				mesh.get_layer(idx).noise_scale = layers[idx].noise_scale
				mesh.get_layer(idx).sine_speed = layers[idx].sine_speed
				mesh.get_layer(idx).sine_amplitude = layers[idx].sine_amplitude
				mesh.get_layer(idx).target_strength = layers[idx].target_strength
				mesh.get_layer(idx).motion = layers[idx].motion
				
		mesh.deform_x = 0.5
		mesh.deform_y = 0.5
		

		mesh.interpolated_vertices.clear()
		mesh.deformed_vertices = mesh.original_vertices.duplicate()
		mesh.sync_deformation_arrays()

	Global.sprite_container.add_child(sprite_obj)
	sprite_obj.sprite_type = "Mesh"

func _make_delta(verts: PackedVector2Array, original : PackedVector2Array) -> PackedVector2Array:
	var delta := PackedVector2Array()
	delta.resize(verts.size())
	for i in range(verts.size()):
		delta[i] = verts[i] - original[i]
	return delta


func load_normal_objects(load_dict : Dictionary, sprite, sprite_obj):
		var canv: CanvasTexture = CanvasTexture.new()
		canv.diffuse_texture = Global.folder_texture
		sprite_obj.get_node("%Sprite2D").texture = canv

		var image_data: ImageData = null
		var image_data_normal: ImageData = null

		if load_dict.get("image_manager_data", []) == [] and !sprite.states[0].get("folder"):
			image_data = ImageData.new()
			if sprite.has("normal") and sprite.normal != null:
				image_data_normal = ImageData.new()

			if sprite.has("is_apng"):
				ImageTextureLoaderManager.load_apng(sprite, image_data)
				if image_data_normal != null:
					ImageTextureLoaderManager.load_apng(sprite, image_data_normal, true)
			elif sprite.has("img_animated") and sprite.img_animated:
				ImageTextureLoaderManager.load_gif(sprite_obj, sprite, image_data)
				if image_data_normal != null:
					ImageTextureLoaderManager.load_gif(sprite, image_data_normal, true)
			else:
				load_sprite(sprite, image_data)
				if image_data_normal != null:
					load_sprite(sprite, image_data_normal, true)
			canv.diffuse_texture = image_data.runtime_texture
			sprite_obj.referenced_data = image_data
			sprite_obj.used_image_id = image_data.id
			image_data.image_name = sprite_obj.sprite_name
			Global.image_manager_data.append(image_data)

			if image_data_normal != null:
				canv.normal_texture = image_data_normal.runtime_texture
				sprite_obj.referenced_data_normal = image_data_normal
				sprite_obj.used_image_id_normal = image_data_normal.id
				image_data_normal.image_name = sprite_obj.sprite_name + "(Normal)"
				Global.image_manager_data.append(image_data_normal)
			if import_resized and import_percent != 100.0:
				_resize_image_data(image_data, sprite_obj.get_node("%Sprite2D"), import_percent)
				if image_data_normal != null:
					_resize_image_data(image_data_normal, null, import_percent)

		else:
			if !sprite.states[0].get("folder"):
				sprite_obj.rotated = sprite.get("rotated", 0)
				sprite_obj.flipped_h = sprite.get("flipped_h", false)
				sprite_obj.flipped_v = sprite.get("flipped_v", false)
				for i in Global.image_manager_data:
					if i.id == sprite_obj.used_image_id:
						sprite_obj.referenced_data = i
						sprite_obj.get_node("%Sprite2D").texture.diffuse_texture = ImageTextureLoaderManager.check_flips(i.runtime_texture, sprite_obj)
					if i.id == sprite_obj.used_image_id_normal:
						sprite_obj.referenced_data_normal = i
						sprite_obj.get_node("%Sprite2D").texture.normal_texture = ImageTextureLoaderManager.check_flips(i.runtime_texture, sprite_obj)

		var cleaned_array := []
		for st in sprite.states:
			if not st.is_empty():
				if import_trimmed and !Global.settings_dict.trimmed and sprite_obj.referenced_data != null:
					st["offset"] += sprite_obj.referenced_data.offset
				if import_resized and import_percent != 100.0:
					var scale := import_percent / 100.0
					st["offset"] *= scale
					if st.has("position"):
						st["position"] *= scale
				cleaned_array.append(st)
		for st in cleaned_array:
			var new_dict = sprite_obj.sprite_data.duplicate()
			new_dict.merge(st, true)
			st = new_dict
		sprite_obj.states = cleaned_array

		if sprite.has("is_collapsed"):
			sprite_obj.is_collapsed = sprite.is_collapsed
			
		sprite_obj.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		Global.sprite_container.add_child(sprite_obj)

func load_sprite(sprite, image_data = null, normal = false):
	var img_data
	var img = Image.new()
	var type
	if normal:
		if sprite.normal == null:
			return
		type = sprite.normal
	else:
		if sprite.img == null:
			return
		type = sprite.img
		
	if type is not PackedByteArray:
		img_data = Marshalls.base64_to_raw(type)
		img.load_png_from_buffer(img_data)
	else:
		img.load_png_from_buffer(type)
		
	if sprite.has("is_premultiplied") == false:
		img.fix_alpha_edges()
	var img_tex = ImageTexture.create_from_image(img)
	if img_tex == null:
		image_data.runtime_texture = ImageTexture.create_from_image(Image.create_empty(32,32,false, Image.FORMAT_ETC2_RGBA8))
	else:
		image_data.runtime_texture = img_tex
	image_data.has_data = true

func load_pngplus_file(path):
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

	Global.remake_for_plus.emit()
	Global.load_sprite_states(0)
	Global.remake_layers.emit()
	Global.slider_values.emit(Global.settings_dict)
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))

	for spr in get_tree().get_nodes_in_group("Sprites"):
		spr.zazaza(get_tree().get_nodes_in_group("Sprites"))

	Global.settings_dict.should_delta = false
	Global.reinfoanim.emit()
	Global.remake_image_manager.emit()
	Global.main.get_node("%Marker").current_screen = Monitor.ALL_SCREENS
	Global.load_model.emit()
	Global.load_sprite_states(0)
	Global.project_updates.emit("Plus Project Loaded!")

#----------------------------------------------------------------------------
# Global Backups
func save_backup(data: Dictionary, previous_path: String) -> void:
	var base_path := previous_path.get_basename()
	var extension := "." + previous_path.get_extension()
	base_path += "_backup"
	
	var counter: int = 1
	var path := base_path + extension
	while FileAccess.file_exists(path):
		counter += 1
		path = base_path + str(counter) + extension
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data, true)

func export_images(_images = get_tree().get_nodes_in_group("Sprites")):
	if !DirAccess.dir_exists_absolute(dire):
		DirAccess.make_dir_absolute(dire)
		
	for image in Global.image_manager_data:
		if image != null:
			if image.img_animated:
				var file = FileAccess.open(dire +"/" + image.image_name + str(randi()) + ".gif", FileAccess.WRITE)
				file.store_buffer(image.anim_texture)
				file.close()
				file = null
			elif image.is_apng:
				var file = FileAccess.open(dire +"/" + image.image_name + str(randi()) + ".apng", FileAccess.WRITE)
				var exp_image = AImgIOAPNGExporter.new().export_animation(image.frames, 10, self, "_progress_report", [])
				file.store_buffer(exp_image)
				file.close()
				file = null
			elif !image.img_animated && !image.is_apng:
				var img = Image.new()
				img = image.runtime_texture.get_image()
				img.save_png(dire +"/" + image.image_name + str(randi()) + ".png")
				img = null
				if image.image_data != null:
					if !image.image_data.is_empty():
						var img_d = Image.new()
						img_d.load_png_from_buffer(image.image_data)
						img_d.save_png(dire +"/" + image.image_name + str(randi()) + ".png")
						img_d = null

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

static func fix_ids(spawn, fixed_ids):
	spawn.sprite_id = fixed_ids["id"]
	spawn.parent_id = fixed_ids["parent_id"]
