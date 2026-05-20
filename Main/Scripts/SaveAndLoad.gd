extends Node

var save_dict: Dictionary = {}
var can_load_plus: bool = false
const YIELD_EVERY: int = 25

var import_trimmed: bool = false
var import_resized: bool = false
var import_percent: float = 50.0

@onready var dire: String = Settings.path_helper(OS.get_executable_path().get_base_dir(), "/ExportedAssets")
@onready var backs_dir: String = Settings.path_helper(OS.get_executable_path().get_base_dir(), "/Backups")

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
			for img in Global.throwable_spawner.selected_items:
				if img == i:
					used = true
					break
			
			for sp in sprites:
				if sp == null or !is_instance_valid(sp): continue
				if i == null or !is_instance_valid(i): 
					Global.image_manager_data.erase(i)
					continue
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
			"warps" : mesh.warps,
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
			"rest_mode": sprt.rest_mode,
			"ik_target" : -1,
			"updated_follow_movement" : true,
			}
			if sprt.target_ik != null && is_instance_valid(sprt.target_ik):
				base.set("ik_target", sprt.target_ik.sprite_id)
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
				"rest_mode": sprt.rest_mode,
				"ik_target" : -1,
				"updated_follow_movement" : true,
				
			}
			if sprt.target_ik != null && is_instance_valid(sprt.target_ik):
				base.set("ik_target", sprt.target_ik.sprite_id)
			
			
		sprites_array.append(base)
	
	
	var ids : Array = []
	for img in Global.throwable_spawner.selected_items:
		ids.append(img.id)
	
	save_dict = {
		"version": Global.version,
		"sprites_array": sprites_array,
		"settings_dict": Global.settings_dict,
		"input_array": input_array,
		"image_manager_data": image_array,
		"throwable" : {
			'position' : Global.throwable_spawner.position,
			'direction' :  Global.throwable_spawner.dir,
			'image_ids' : ids,
			'event' : InputMap.action_get_events('throwing')[0] if InputMap.action_get_events('throwing').size() > 0 else null,
			'throw_per_trigger' : Global.throwable_spawner.throw_per_trigger,
			'spawn_variance' : Global.throwable_spawner.spawn_variance,
			'both_sides' : Global.throwable_spawner.both_sides,
			'base_mass' : Global.throwable_spawner.base_mass
			
		}
	}

func save_model(path: String) -> void:
	Global.save_path = path
	save_data()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveAndLoad: failed to open for write '%s': %s" % [path, FileAccess.get_open_error()])
		Global.project_updates.emit("Save Failed!")
		return

	file.store_var(save_dict, true)
	file.close()
	
	if !path.begins_with("res://"):
		save_backup(save_dict, path)
		await get_tree().process_frame

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
	
	
	Global.camera_pos.global_position = Global.settings_dict.pan
	Global.camera.zoom = Global.settings_dict.zoom

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

	if !load_dict.has("sprites_array"):
		return

	var file_version := ""
	if "version" in load_dict:
		file_version = load_dict.version

	
	if file_version != Global.version:
		load_dict = VersionConverter.convert_save(load_dict, file_version)

	Global.settings_dict.merge(load_dict.settings_dict, true)
	if Global.settings_dict.monitor != Monitor.ALL_SCREENS:
		if Global.settings_dict.monitor >= DisplayServer.get_screen_count():
			Global.settings_dict.monitor = Monitor.ALL_SCREENS

	Global.remake_states.emit(load_dict.settings_dict.states)
	if !path.begins_with("res://"):
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
			i.reposition(get_tree().get_nodes_in_group("Sprites"))
		Global.settings_dict.trimmed = true
		import_trimmed = false

	for i in get_tree().get_nodes_in_group("Sprites"):
		i.old_reposition()
		i.reference_ik_target()
		

	Global.slider_values.emit(Global.settings_dict)
	if Global.main.has_node("%Control"):
		Global.update_anim.emit()
	if Global.settings_dict.anti_alias:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if Global.settings_dict.auto_save:
		Settings.save_timer.wait_time = Global.settings_dict.auto_save_timer * 60
		Settings.save_timer.start()
	else:
		Settings.save_timer.stop()

	if Global.throwable_spawner != null && is_instance_valid(Global.throwable_spawner):
		var throwable = load_dict.get("throwable", {})
		Global.throwable_spawner.position = throwable.get('position', Vector2.ZERO)
		Global.throwable_spawner.dir = throwable.get('direction', Vector2.ZERO)
		Global.throwable_spawner.throw_per_trigger = throwable.get('throw_per_trigger', 1)
		Global.throwable_spawner.spawn_variance = throwable.get('spawn_variance', 0)
		Global.throwable_spawner.both_sides = throwable.get('both_sides', false)
		Global.throwable_spawner.base_mass = throwable.get('base_mass', 1)
		
		InputMap.action_erase_events('throwing')
		var event = throwable.get('event', null)
		if event != null:
			InputMap.action_add_event('throwing', event)
		
		var ids : Array = throwable.get('image_ids', [])
		Global.throwable_spawner.selected_items.clear()
		for i in Global.image_manager_data:
			if i.id in ids:
				Global.throwable_spawner.selected_items.append(i)

	Global.main.get_node("%Marker").current_screen = Global.settings_dict.monitor
	Global.project_updates.emit("Project Loaded!")
	Global.remake_image_manager.emit()
	Global.load_model.emit()
	Global.load_sprite_states(0)

func resize_image_data(image_data: ImageData, sprite_node: Node2D, percent: float) -> void:
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

func resize_apng_frames(image_data: ImageData, percent: float) -> void:
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
				resize_apng_frames(image_data, import_percent)
			else:
				resize_image_data(image_data, null, import_percent)

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
	sprite_obj.flipped_h = sprite.get("flipped_h", false)
	sprite_obj.flipped_v = sprite.get("flipped_v", false)
	sprite_obj.rotated = sprite.get("rotated", 0)
	sprite_obj.hidden_target_id_check = sprite.get("ik_target", -1)
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
		if sprite.is_asset:
			sprite_obj.get_node("%Sprite2D").visible = sprite.was_active_before
		else:
			sprite_obj.get_node("%Sprite2D").visible = true
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
		else:
			InputMap.erase_action(sprite_obj.disappear_keys)
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
		else:
			if InputMap.has_action(str(sprite.sprite_id)):
				InputMap.erase_action(str(sprite.sprite_id))
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
			st = updated_follow_check(sprite, st)
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
			st = updated_follow_check(sprite, st)
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
			mesh.get_layer(1).top_left = make_delta(d3[0].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).top_middle = make_delta(d3[1].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).top_right = make_delta(d3[2].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).middle_left = make_delta(d3[3].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).center = make_delta(d3[4].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).middle_right = make_delta(d3[5].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).bottom_left = make_delta(d3[6].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).bottom_middle = make_delta(d3[7].duplicate(), mesh.original_vertices)
			mesh.get_layer(1).bottom_right = make_delta(d3[8].duplicate(), mesh.original_vertices)
		
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
	sprite_obj.get_node("%Sprite2D").set_mesh_id(sprite.sprite_id)
	sprite_obj.get_node("%Sprite2D").warps = sprite.get("warps", [])

func load_normal_objects(load_dict : Dictionary, sprite, sprite_obj):
		var canv: CanvasTexture = CanvasTexture.new()
		canv.diffuse_texture = Global.folder_texture
		sprite_obj.get_node("%Sprite2D").texture = canv

		var image_data: ImageData = null
		var image_data_normal: ImageData = null

		var warn : bool = false
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
			if image_data.runtime_texture.get_size().x > 1280 or image_data.runtime_texture.get_size().y > 1280:
				warn = true 

			if image_data_normal != null:
				canv.normal_texture = image_data_normal.runtime_texture
				sprite_obj.referenced_data_normal = image_data_normal
				sprite_obj.used_image_id_normal = image_data_normal.id
				image_data_normal.image_name = sprite_obj.sprite_name + "(Normal)"
				Global.image_manager_data.append(image_data_normal)
			if import_resized and import_percent != 100.0:
				resize_image_data(image_data, sprite_obj.get_node("%Sprite2D"), import_percent)
				if image_data_normal != null:
					resize_image_data(image_data_normal, null, import_percent)

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
			if ! st.is_empty():
				if import_trimmed and !Global.settings_dict.trimmed and sprite_obj.referenced_data != null:
					st["offset"] += sprite_obj.referenced_data.offset
				if import_resized and import_percent != 100.0:
					var scale := import_percent / 100.0
					st["offset"] *= scale
					if st.has("position"):
						st["position"] *= scale
				st = updated_follow_check(sprite, st)
				cleaned_array.append(st)
		for st in cleaned_array:
			var new_dict = sprite_obj.sprite_data.duplicate(true)
			new_dict.merge(st, true)
		sprite_obj.states = cleaned_array
		Global.show_warning = warn

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

func updated_follow_check(sprite, st) -> Dictionary:
	if !sprite.get("updated_follow_movement", false):
		st["pos_x_min"] = -abs(st["look_at_mouse_pos"])
		st["pos_x_max"] = abs(st["look_at_mouse_pos"])
		st["pos_y_min"] = -abs(st["look_at_mouse_pos_y"])
		st["pos_y_max"] = abs(st["look_at_mouse_pos_y"])
		st["rot_min"] = st.get("mouse_rotation", 0.0)
		st["rot_max"] = st.get("mouse_rotation_max", 0.0)
		st["scale_x_min"] = -abs(st.get("mouse_scale_x", 0.0))
		st["scale_x_max"] = abs(st.get("mouse_scale_x", 0.0))
		st["scale_y_min"] = -abs(st.get("mouse_scale_y", 0.0))
		st["scale_y_max"] = abs(st.get("mouse_scale_y", 0.0))
		if signi(st["look_at_mouse_pos"]) < 0:
			st["pos_invert_x"] = true
		if signi(st["look_at_mouse_pos_y"]) < 0:
			st["pos_invert_y"] = true
	return st

func make_delta(verts: PackedVector2Array, original : PackedVector2Array) -> PackedVector2Array:
	var delta := PackedVector2Array()
	delta.resize(verts.size())
	for i in range(verts.size()):
		delta[i] = verts[i] - original[i]
	return delta

#----------------------------------------------------------------------------
# Global Backups
func save_backup(data: Dictionary, previous_path: String) -> void:
	if not DirAccess.dir_exists_absolute(backs_dir):
		DirAccess.make_dir_absolute(backs_dir)
	var extension := "." + previous_path.get_extension()
	var base_name := previous_path.get_file().get_basename()
	var backup_path := backs_dir.path_join(base_name + "_backup" + extension)
	var counter := 1
	while FileAccess.file_exists(backup_path):
		counter += 1
		backup_path = backs_dir.path_join(base_name + "_backup" + str(counter) + extension)
	var file := FileAccess.open(backup_path, FileAccess.WRITE)
	if not file:
		push_error("SaveAndLoad: failed to write backup: %s" % backup_path)
		return
	file.store_var(data, true)
	file.close()

func export_images(images : Array = []) -> void:
	if not DirAccess.dir_exists_absolute(dire):
		DirAccess.make_dir_absolute(dire)
		
	var seen : Array = []
	
	if !images.is_empty():
		for i in images :
			var ref_img = i.referenced_data
			var ref_normal = i.referenced_data_normal
			if ref_img not in seen && ref_img != null:
				seen.append(ref_img)
			if ref_normal not in seen && ref_normal != null:
				seen.append(ref_img)
	else:
		seen = Global.image_manager_data
		
	for image in seen:
		if image == null: continue
		var unique_name: String = image.image_name + str(randi())
		if image.img_animated:
			var file := FileAccess.open(dire.path_join(unique_name + ".gif"), FileAccess.WRITE)
			if not file: continue
			file.store_buffer(image.anim_texture)
			file.close()
		elif image.is_apng:
			var file := FileAccess.open(dire.path_join(unique_name + ".apng"), FileAccess.WRITE)
			if not file: continue
			file.store_buffer(AImgIOAPNGExporter.new().export_animation(image.frames, 10, self, "_progress_report", []))
			file.close()
		else:
			image.runtime_texture.get_image().save_png(dire.path_join(unique_name + ".png"))
			if image.image_data != null and not image.image_data.is_empty():
				var img_d := Image.new()
				img_d.load_png_from_buffer(image.image_data)
				img_d.save_png(dire.path_join(image.image_name + str(randi()) + ".png"))

#----------------------------------------------------------------------------
# Misc Data
func load_pngplus_file(_path):
	pass
	#LoadMisc.load_pngplus_file(path, can_load_plus)

func load_images_from_psd(path : String):
	LoadMisc.load_images_from_psd(path)

func add_object_to_scene(image_data, add_as_appendage : bool = false, folder : bool = false, force_offset : bool = false, custom_name : String = ""):
	LoadMisc.add_object_to_scene(image_data, add_as_appendage, folder, force_offset, custom_name)
