extends Tree

var held_item : Array[TreeItem]
var hovered = false
var add_as_appendage = false
var should_offset = false
var has_offsetting = false

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb"):
		held_item.clear()
		has_offsetting = false
		drop_mode_flags = 0
		await get_tree().physics_frame
		for item in get_root().get_child(0).get_children():
			if item.is_selected(0):
				if item.get_metadata(0).trimmed:
					has_offsetting = true
				
				
				held_item.append(item)
		set_physics_process(true)
	if !Input.is_action_pressed("ctrl") or !Input.is_action_pressed("shift") or !Input.is_action_pressed("alt"):
		if event.is_action_released("lmb"):
			if held_item.size() > 0:
				drop_all_data()

func _physics_process(_delta: float) -> void:
	hovered = Global.main.can_scroll
	if hovered or Global.over_tex or Global.over_normal_tex:
		Input.set_default_cursor_shape(Input.CURSOR_CAN_DROP)

func drop_all_data():
	set_physics_process(false)
	if !held_item.is_empty():
		if hovered:
			%AsAppednage.popup()
			
		elif Global.over_tex:
			replace_texture_image()
			
		elif Global.over_normal_tex:
			replace_texture_image(true)
		elif Global.over_mesh_tex:
			var meta : ImageData = held_item[0].get_metadata(0)
			Global.mesh_text_node.held_image_data = meta
			Global.mesh_text_node.get_node("%MeshTexture").texture = meta.runtime_texture
			
	drop_mode_flags = 0
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	hovered = false

func loop_to_all():
	for i in held_item:
		if i.get_metadata(0) is ImageData:
			SaveAndLoad.add_object_to_scene(i.get_metadata(0), add_as_appendage)

func _on_as_appednage_confirmed() -> void:
	add_as_appendage = true
	%AsAppednage.hide()
	if has_offsetting:
		%RememberOffset.popup()
	else:
		loop_to_all()

func _on_as_appednage_close_requested() -> void:
	add_as_appendage = false
	%AsAppednage.hide()
	if has_offsetting:
		%RememberOffset.popup()
	else:
		loop_to_all()

func _on_remember_offset_confirmed() -> void:
	%RememberOffset.hide()
	should_offset = true
	loop_to_all()

func _on_remember_offset_canceled() -> void:
	%RememberOffset.hide()
	should_offset = false
	loop_to_all()

func replace_texture_image(normal : bool = false):
	if Global.held_sprites.size() > 0:
		var meta : ImageData = held_item[0].get_metadata(0)
		if normal:
			for i in Global.held_sprites:
				if !i.get_value("folder"):
					i.used_image_id_normal = meta.id
					i.referenced_data_normal = meta
					var norm = ImageTextureLoaderManager.check_flips(meta.runtime_texture, i)
					if i.get_node("%Sprite2D") is CustomMesh:
						pass
					else:
						i.get_node("%Sprite2D").texture.normal_texture = norm
					
					ImageTrimmer.set_thumbnail(i.treeitem)
		else:
			for i in Global.held_sprites:
				if !i.get_value("folder"):
					i.used_image_id = meta.id
					i.referenced_data = meta
					var diff = ImageTextureLoaderManager.check_flips(meta.runtime_texture, i)
					if i.get_node("%Sprite2D") is CustomMesh:
						i.get_node("%Sprite2D").texture = diff
					else:
						i.get_node("%Sprite2D").texture.diffuse_texture = diff
					
					
					ImageTrimmer.set_thumbnail(i.treeitem)
		Global.reinfo.emit()
