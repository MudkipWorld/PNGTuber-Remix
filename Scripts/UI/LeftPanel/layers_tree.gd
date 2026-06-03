extends Tree

var held_item: Array[TreeItem] = []

func _get_drag_data(_at_position: Vector2) -> Variant:
	if held_item.is_empty():
		for entry in Global.held_sprites:
			if entry.treeitem:
				held_item.append(entry.treeitem)
	return held_item

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = 3
	if not (data is Array[TreeItem]):
		return false
	return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data and not data.is_empty():
		var other: TreeItem = get_item_at_position(at_position)
		for item in data:
			if valid_items(item, other):
				move_stuff(item, other, at_position)
	held_item.clear()

func move_stuff(item: TreeItem, other_item: TreeItem, at_position: Vector2) -> void:
	if item == other_item: return
	var children : Array = get_all_layeritems(item, true)
	if item in children: return

	var drop = get_drop_section_at_position(at_position)
	if item == null: return
	#data['sprite_object']
	var obj  : Node2D = null
	var obj_2 : Node2D = null
	
	var test : Variant = other_item.get_metadata(0)
	if test != null && test is Dictionary:
		var data : Dictionary = other_item.get_metadata(0)
		obj = data['sprite_object']
		
	var data_2 : Dictionary = item.get_metadata(0)
	obj_2 = data_2['sprite_object']

	var sprite = obj_2
	var og_pos: Vector2 = sprite.global_position
	
	if obj && obj_2:
		move_sprite_reparent(obj, obj_2, item, other_item, drop)

	elif obj_2 && obj == null:
		move_sprite_to_container(obj, obj_2, item, other_item, drop)

	finalize_move(obj_2, og_pos) 

	Global.reinfo.emit()

func move_sprite_reparent(obj, obj_2, item, other_item, drop):
	var other_parent = other_item.get_parent()
	var undo_data = {}
	
	if drop == 0:
		obj_2.get_parent().remove_child(obj_2)
		obj.sprite_object.add_child(obj_2)
		obj_2.parent_id = obj.sprite_id
		item.get_parent().remove_child(item)
		other_item.add_child(item)
		undo_data = add_to_undo_history(item, other_item)
	elif drop == 1:
		if item.get_parent() == other_item.get_parent():
			item.move_after(other_item)
			obj_2.get_parent().move_child(obj_2, obj.get_index())
			undo_data = add_to_undo_history( item, other_parent)
		else:
			obj_2.get_parent().remove_child(obj_2)
			obj.sprite_object.add_child(obj_2)
			obj_2.parent_id = obj.sprite_id
			item.get_parent().remove_child(item)
			other_item.add_child(item)
			item.move_after(other_item)
			undo_data = add_to_undo_history( item, other_parent)
		
	elif drop == -1:
		if other_item.get_parent() == item.get_parent():
			item.move_before(other_item)
			obj_2.get_parent().move_child(obj_2, obj.get_index())
			undo_data = add_to_undo_history(item, other_parent)
		else:
			obj_2.get_parent().remove_child(obj_2)
			obj.sprite_object.add_child(obj_2)
			obj_2.parent_id = obj.sprite_id
			item.get_parent().remove_child(item)
			other_item.add_child(item)
			item.move_before(other_item)
			undo_data = add_to_undo_history(item, other_parent)
			
	UndoRedoManager.push_data(undo_data)

func move_sprite_to_container(obj, obj_2, item, other_item, drop):
	var other_parent = other_item.get_parent()
	var undo_data = {}
	if drop == 0:
		obj_2.get_parent().remove_child(obj_2)
		Global.sprite_container.add_child(obj_2)
		obj_2.parent_id = 0
		item.get_parent().remove_child(item)
		other_item.add_child(item)
		undo_data = add_to_undo_history(item, other_item)
		
	elif drop == 1:
		if item.get_parent() == other_item.get_parent():
			item.move_after(other_item)
			obj_2.get_parent().move_child(obj_2, obj.get_index())
			undo_data = add_to_undo_history( item, other_parent)
		else:
			obj_2.get_parent().remove_child(obj_2)
			Global.sprite_container.add_child(obj_2)
			obj_2.parent_id = 0
			item.get_parent().remove_child(item)
			other_item.add_child(item)
			undo_data = add_to_undo_history( item, other_parent)
		
	elif drop == -1:
		if other_item.get_parent() == item.get_parent():
			item.move_before(other_item)
			obj_2.get_parent().move_child(obj_2, obj.get_index())
			undo_data = add_to_undo_history( item, other_parent)
		else:
			obj_2.get_parent().remove_child(obj_2)
			Global.sprite_container.add_child(obj_2)
			obj_2.parent_id = 0
			item.get_parent().remove_child(item)
			other_item.add_child(item)
			undo_data = add_to_undo_history( item, other_parent)

	UndoRedoManager.push_data(undo_data)

func valid_items(item: Variant, other: Variant) -> bool:
	return item != null and is_instance_valid(item) and other != null and is_instance_valid(other) and other is TreeItem

func finalize_move(sprite, og_pos: Vector2) -> void:
	sprite.global_position = og_pos
	sprite.sprite_data.position = sprite.position
	sprite.save_state(Global.current_state)
	await get_tree().physics_frame
	recolor_layer()

func add_to_undo_history(item, other_item) -> Dictionary:
	var old_parent = item.get_parent()
	var old_index = item.get_index()
	
	return {
		tree = self,
		item = item,
		old_parent = old_parent,
		new_parent = other_item,
		old_index = old_index,
		new_index = item.get_index()
	}

func recolor_layer() -> void:
	%LayersScripts.correct_recolor()

func get_all_layeritems(layeritem: TreeItem, recursive: bool) -> Array:
	var children: Array = []
	for child in layeritem.get_children():
		children.append(child)
		if recursive and child.get_child_count() > 0:
			children.append_array(get_all_layeritems(child, true))
	return children

func get_all_layeritems_with_parent(layeritem, recursive) -> Array:
	var children := []
	for child in layeritem.get_children():
		children.append({child = child, parent = layeritem})
		
		if recursive and child.get_child_count():
			children.append_array(get_all_layeritems_with_parent(child, true))
		
	return children
