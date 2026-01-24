extends Node

var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn")
var comment_obj = preload("res://Misc/CommentObject/comment_object.tscn")
var mesh_obj = preload("res://Misc/MeshObject/mesh_object.tscn")
var append_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn")

var has_folder : bool = false

func _ready() -> void:
	Settings.theme_changed.connect(change_theme)
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()

func change_theme(index):
	match index:
		0:
			%LayerPopup.theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
		1:
			%LayerPopup.theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
		2:
			%LayerPopup.theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
		3:
			%LayerPopup.theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
		4:
			%LayerPopup.theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
		5:
			%LayerPopup.theme = preload("res://Themes/GreenTheme/Green_theme.tres")
		6:
			%LayerPopup.theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")

func nullfy():
	%ReplaceButton.disabled = true
	%DuplicateButton.disabled = true
	%DeleteButton.disabled = true
	%AddNormalButton.disabled = true
	%DelNormalButton.disabled = true
	%RotateImage.disabled = false
	%FlipH.disabled = false
	%FlipV.disabled = false
	%RotateImage.disabled = true
	%FlipH.disabled = true
	%FlipV.disabled = true
	%UnlinkButton.disabled = true

func enable():
	%DuplicateButton.disabled = false
	%DeleteButton.disabled = false
	%UnlinkButton.disabled = false
	%RotateImage.disabled = true
	%FlipH.disabled = true
	%FlipV.disabled = true
	
	has_folder = false
	for i in Global.held_sprites:
		if i.get_value("folder") or Global.held_sprites.size() > 1:
			%AddNormalButton.disabled = true
			%DelNormalButton.disabled = true
			%ReplaceButton.disabled = true
			has_folder = true
		elif !i.get_value("folder") && !has_folder:
			%AddNormalButton.disabled = false
			%DelNormalButton.disabled = false
			%ReplaceButton.disabled = false
		else:
			%AddNormalButton.disabled = false
			%DelNormalButton.disabled = false
			%ReplaceButton.disabled = false
		
		if i.get_value("folder") or has_folder:
			%RotateImage.disabled = true
			%FlipH.disabled = true
			%FlipV.disabled = true
			continue
		else:
			if i.referenced_data != null:
				if (i.referenced_data.is_apng or i.referenced_data.img_animated):
					%RotateImage.disabled = true
					%FlipH.disabled = true
					%FlipV.disabled = true
				else:
					%RotateImage.disabled = false
					%FlipH.disabled = false
					%FlipV.disabled = false

func _on_delete_button_pressed():
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if InputMap.has_action(i.disappear_keys):
				InputMap.erase_action(i.disappear_keys)
			if InputMap.has_action(str(i.sprite_id)):
				InputMap.erase_action(str(i.sprite_id))
			i.treeitem.free()
			i.free()
	Global.deselect.emit()

func _on_duplicate_button_pressed():
	var sprites = []
	var id_map = {}
	for sprite in Global.held_sprites:
		if sprite != null and is_instance_valid(sprite):
			var base = _duplicate_single(sprite, id_map)
			sprites.append(base)
			var layers = %LayersTree.get_all_layeritems_with_parent(sprite.treeitem, true)
			for layer in layers:
				var t = layer.child.get_metadata(0).sprite_object
				var child = _duplicate_child(base, t, id_map)
				sprites.append(child)
	if sprites.is_empty():
		return
	Global.get_sprite_states(Global.current_state)
	Global.reparent_layers.emit(sprites)
	Global.reparent_objects.emit(sprites)

func _duplicate_single(sprite, id_map):
	var obj = _instantiate_by_type(sprite.sprite_type)
	_copy_transform(sprite, obj)
	_copy_images(sprite, obj)
	_copy_common(sprite, obj)
	_finalize_duplicate(sprite, obj, id_map)
	return obj

func _duplicate_child(parent, t, id_map):
	var obj = _instantiate_by_type(t.sprite_type)
	_copy_transform(t, obj)
	_copy_images(t, obj)
	_copy_common(t, obj)
	_finalize_child_duplicate(parent, t, obj, id_map)
	return obj

func _instantiate_by_type(type):
	if type == "WiggleApp":
		return append_obj.instantiate()
	if type == "Comment":
		return comment_obj.instantiate()
	if type == "Mesh":
		return mesh_obj.instantiate()
	return sprite_obj.instantiate()

func _copy_transform(src, dst):
	if src.sprite_type != "Comment" or src.sprite_type != "Mesh":
		dst.rotated = src.rotated
		dst.flipped_h = src.flipped_h
		dst.flipped_v = src.flipped_v
	if src.sprite_type == "Mesh":
		duplicate_mesh_data(src.get_node("%Sprite2D"), dst.get_node("%Sprite2D"))
	dst.position = src.position
	dst.scale = src.scale
	dst.sprite_data.scale = src.scale

func duplicate_mesh_data(src: CustomMesh, dst: CustomMesh) -> void:
	dst.original_vertices = src.original_vertices.duplicate()
	dst.base_vertices = src.base_vertices.duplicate()
	dst.deformed_vertices = src.deformed_vertices.duplicate()
	dst.internal_vertices = src.internal_vertices.duplicate()
	dst.triangles = src.triangles.duplicate()
	dst.deform_top_left = src.deform_top_left.duplicate()
	dst.deform_top_middle = src.deform_top_middle.duplicate()
	dst.deform_top_right = src.deform_top_right.duplicate()
	dst.deform_middle_left = src.deform_middle_left.duplicate()
	dst.deform_center = src.deform_center.duplicate()
	dst.deform_middle_right = src.deform_middle_right.duplicate()
	dst.deform_bottom_left = src.deform_bottom_left.duplicate()
	dst.deform_bottom_middle = src.deform_bottom_middle.duplicate()
	dst.deform_bottom_right = src.deform_bottom_right.duplicate()
	dst.texture = src.texture


func _copy_images(src, dst):
	dst.used_image_id = src.used_image_id
	dst.used_image_id_normal = src.used_image_id_normal
	dst.referenced_data = src.referenced_data
	dst.referenced_data_normal = src.referenced_data_normal
	if src.sprite_type != "Comment" or src.sprite_type != "Mesh":
		if !src.get_value("folder"):
			var canv = CanvasTexture.new()
			var diff = ImageTextureLoaderManager.check_flips(dst.referenced_data.runtime_texture, dst)
			canv.diffuse_texture = diff
			if dst.used_image_id_normal != 0:
				var norm = ImageTextureLoaderManager.check_flips(dst.referenced_data_normal.runtime_texture, dst)
				canv.normal_texture = norm
			dst.get_node("%Sprite2D").texture = canv
		else:
			var canv = CanvasTexture.new()
			canv.diffuse_texture = Global.folder_texture
			dst.get_node("%Sprite2D").texture = canv


func _copy_common(src, dst):
	dst.sprite_name = "Duplicate" + src.sprite_name
	if src.get_value("folder"):
		dst.sprite_data.folder = true
	dst.sprite_data = src.sprite_data.duplicate(true)
	dst.states = src.states.duplicate(true)
	dst.saved_keys = src.saved_keys.duplicate(true)
	dst.should_disappear = src.should_disappear
	dst.show_only = src.show_only
	dst.hold_to_show = src.hold_to_show
	dst.is_asset = src.is_asset
	dst.saved_event = src.saved_event
	dst.was_active_before = src.was_active_before
	dst.visible = dst.was_active_before
	dst.is_collapsed = src.is_collapsed
	dst.played_once = src.played_once
	dst.layer_color = src.layer_color
	Global.sprite_container.add_child(dst)
	dst.sprite_type = src.sprite_type
	if src.sprite_type != "Comment" or src.sprite_type != "Mesh":
		dst.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	Global.update_layers.emit(0, dst, dst.sprite_type)
	dst.get_state(Global.current_state)
	if dst.sprite_type == "WiggleApp":
		dst.update_wiggle_parts()
	if dst.sprite_type == "Mesh":
		dst.get_node("%Sprite2D").interpolated_vertices.clear()
		dst.get_node("%Sprite2D").sync_deformation_arrays() 
		dst.get_node("%MeshEditor").queue_redraw()
		dst.get_node("%Sprite2D").queue_redraw()

func _finalize_duplicate(src, obj, id_map):
	obj.sprite_id = randi()
	id_map[src.sprite_id] = obj.sprite_id
	obj.parent_id = src.parent_id


func _finalize_child_duplicate(parent, t, obj, id_map):
	obj.sprite_id = randi()
	id_map[t.sprite_id] = obj.sprite_id
	if t.parent_id in id_map:
		obj.parent_id = id_map[t.parent_id]
	else:
		obj.parent_id = parent.sprite_id
	obj.global_position = t.global_position


func _on_replace_button_pressed():
	Global.main.replacing_sprite()

func _on_add_sprite_button_pressed():
	Global.main.load_sprites()

func _on_folder_button_pressed():
	var sprte_obj = sprite_obj.instantiate()
	Global.sprite_container.add_child(sprte_obj)
	var canv = CanvasTexture.new()
	canv.diffuse_texture = Global.folder_texture
	sprte_obj.get_node("%Sprite2D").texture =  canv
	sprte_obj.sprite_name = str("Folder")
	sprte_obj.sprite_data.folder = true
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		sprte_obj.states.append({})
	Global.update_layers.emit(0, sprte_obj, "Sprite2D")
	sprte_obj.sprite_id = sprte_obj.get_instance_id()

func _on_add_normal_button_pressed():
	Global.main.add_normal_sprite()

func _on_del_normal_button_pressed():
	for sprite in Global.held_sprites:
		if sprite != null && is_instance_valid(sprite):
			if not sprite.get_value("folder"):
				sprite.used_image_id_normal = 0
				sprite.referenced_data_normal = null
				sprite.get_node("%Sprite2D").texture.normal_texture = null
				Global.reinfo.emit()

func _on_add_appendage_pressed() -> void:
	Global.main.load_append_sprites()

func _on_flip_h_pressed() -> void:
	var obj = Global.held_sprites[0]
	if ImageTextureLoaderManager.check_valid(obj, obj.referenced_data):
		print("d")
		obj.flipped_h = !obj.flipped_h
		print(obj.flipped_h)
		check_flips(obj)
		ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
		Global.reinfo.emit()
	else:
		return

func _on_flip_v_pressed() -> void:
	var obj = Global.held_sprites[0]
	if ImageTextureLoaderManager.check_valid(obj, obj.referenced_data):
		obj.flipped_v = !obj.flipped_v
		check_flips(obj)
		ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
		Global.reinfo.emit()
	else:
		return

func _on_rotate_image_pressed() -> void:
	var obj = Global.held_sprites[0]
	if ImageTextureLoaderManager.check_valid(obj, obj.referenced_data):
		obj.rotated = wrap(obj.rotated + 1, 0, 4)
		check_flips(obj)
		ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
		Global.reinfo.emit()
	else:
		return

func _on_unlink_button_pressed() -> void:
	var has_unlinked : bool = false
	for sprite in Global.held_sprites:
		if sprite != null and is_instance_valid(sprite):
			if sprite.get_parent() == Global.sprite_container or sprite.parent_id == 0:
				continue
			else:
				has_unlinked = true
				var og_pos = sprite.global_position
				sprite.get_parent().remove_child(sprite)
				sprite.parent_id = 0
				Global.sprite_container.add_child(sprite)
				await get_tree().physics_frame
				sprite.global_position = og_pos
				sprite.sprite_data.position = sprite.position
				sprite.save_state(Global.current_state)
	if has_unlinked:
		Global.remake_layers.emit()

func check_flips(obj):
	var sprite = obj.get_node("%Sprite2D")
	var diffused = ImageTextureLoaderManager.check_flips(obj.referenced_data.runtime_texture,obj )
	if sprite is CustomMesh:
		sprite.texture = diffused
	else:
		sprite.texture.diffuse_texture = diffused
	if obj.used_image_id_normal != 0:
		var normal = ImageTextureLoaderManager.check_flips(obj.referenced_data_normal.runtime_texture, obj)
		sprite.texture.normal_texture = normal


func _on_comments_button_pressed() -> void:
	var sprte_obj = comment_obj.instantiate()
	Global.sprite_container.add_child(sprte_obj)
	sprte_obj.sprite_type = "Comment"
	sprte_obj.sprite_name = str("CommentBlock")
	sprte_obj.sprite_data.folder = true
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		sprte_obj.states.append({})
	Global.update_layers.emit(0, sprte_obj, "Comment")
	sprte_obj.sprite_id = sprte_obj.get_instance_id()


func _on_mesh_button_pressed() -> void:
	var sprte_obj = mesh_obj.instantiate()
	Global.sprite_container.add_child(sprte_obj)
	sprte_obj.sprite_type = "Mesh"
	sprte_obj.sprite_name = str("Mesh")
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		sprte_obj.states.append({})
	Global.update_layers.emit(0, sprte_obj, "Mesh")
	sprte_obj.sprite_id = sprte_obj.get_instance_id()
