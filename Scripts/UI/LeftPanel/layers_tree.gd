extends Tree

var held_item: Array[TreeItem] = []


func _get_drag_data(_at_position: Vector2) -> Variant:
	drop_mode_flags = 3
	if held_item.is_empty():
		for entry in Global.held_sprites:
			if entry.treeitem:
				held_item.append(entry.treeitem)
	return held_item


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Array[TreeItem]):
		return false
	drop_mode_flags = 3
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data and not data.is_empty():
		var other: TreeItem = get_item_at_position(at_position)
		for item in data:
			if _valid_items(item, other):
				move_stuff(item, other, at_position)
	held_item.clear()
	drop_mode_flags = 3


func move_stuff(item: TreeItem, other_item: TreeItem, at_position: Vector2) -> void:
	var true_pos = get_drop_section_at_position(at_position)
	var all_children := get_all_layeritems(item, true)

	if other_item in all_children or other_item == item:
		print("can't drop")
		return

	var meta = item.get_metadata(0)
	if meta == null or meta.sprite_object == null:
		push_error("move_stuff: missing metadata or sprite_object")
		return

	var sprite = meta.sprite_object
	var og_pos: Vector2 = sprite.global_position

	match true_pos:
		0:
			_move_into(item, other_item, sprite, og_pos)
		-1:
			_move_above(item, other_item, sprite, og_pos)
		1:
			_move_below(item, other_item, sprite, og_pos)

	Global.reinfo.emit()


func _move_into(item: TreeItem, other_item: TreeItem, sprite, og_pos: Vector2) -> void:
	item.get_parent().remove_child(item)
	other_item.add_child(item)

	if other_item == get_root():
		_move_sprite_to_root(sprite)
	else:
		_attach_sprite_to_parent(sprite, other_item)

	await _finalize_move(sprite, og_pos)
	recolor_layer()


func _move_above(item: TreeItem, other_item: TreeItem, sprite, og_pos: Vector2) -> void:
	var other_parent = other_item.get_parent()
	var old_parent = item.get_parent()
	if other_item == get_root():
		old_parent.remove_child(item)
		get_root().add_child(item)
		item.move_before(other_item.get_child(0))
		sprite.parent_id = 0
		if sprite.get_parent() != Global.sprite_container:
			sprite.get_parent().remove_child(sprite)
			Global.sprite_container.add_child(sprite)
			Global.sprite_container.move_child(sprite, item.get_index())
	
	elif other_parent != old_parent:
		old_parent.remove_child(item)
		other_parent.add_child(item)
		item.move_before(other_item)
		var new_sprite_parent = other_item.get_metadata(0).sprite_object.get_parent()
		if sprite.get_parent() != new_sprite_parent:
			sprite.get_parent().remove_child(sprite)
			new_sprite_parent.add_child(sprite)
			new_sprite_parent.move_child(sprite, item.get_index())
		sprite.parent_id = other_item.get_metadata(0).sprite_object.parent_id
	else:
		item.move_before(other_item)
		sprite.get_parent().move_child(sprite, item.get_index())

	await _finalize_move(sprite, og_pos)
	recolor_layer()

func _move_below(item: TreeItem, other_item: TreeItem, sprite, og_pos: Vector2) -> void:
	var other_parent = other_item.get_parent()
	var old_parent = item.get_parent()
	if other_item == get_root():
		old_parent.remove_child(item)
		get_root().add_child(item)
		item.move_after(other_item.get_child(0))
		sprite.parent_id = 0
		if sprite.get_parent() != Global.sprite_container:
			sprite.get_parent().remove_child(sprite)
			Global.sprite_container.add_child(sprite)
			Global.sprite_container.move_child(sprite, item.get_index())
	elif other_parent != old_parent:
		old_parent.remove_child(item)
		other_parent.add_child(item)
		item.move_after(other_item)
		var new_sprite_parent = other_item.get_metadata(0).sprite_object.get_parent()
		if sprite.get_parent() != new_sprite_parent:
			sprite.get_parent().remove_child(sprite)
			new_sprite_parent.add_child(sprite)
			new_sprite_parent.move_child(sprite, item.get_index())
		sprite.parent_id = other_item.get_metadata(0).sprite_object.parent_id
	else:
		item.move_after(other_item)
		sprite.get_parent().move_child(sprite, item.get_index())
	await _finalize_move(sprite, og_pos)
	recolor_layer()

func _valid_items(item: Variant, other: Variant) -> bool:
	return item != null and is_instance_valid(item) and other != null and is_instance_valid(other) and other is TreeItem

func _move_sprite_to_root(sprite) -> void:
	if sprite.get_parent():
		sprite.get_parent().remove_child(sprite)
	sprite.parent_id = 0
	Global.sprite_container.add_child(sprite)


func _attach_sprite_to_parent(sprite, other_item: TreeItem) -> void:
	var other_sprite = other_item.get_metadata(0).sprite_object
	var container = other_sprite.get_node("%Sprite2D")
	if sprite.get_parent():
		sprite.get_parent().remove_child(sprite)
	container.add_child(sprite)
	sprite.parent_id = other_sprite.sprite_id


func _finalize_move(sprite, og_pos: Vector2) -> void:
	sprite.global_position = og_pos
	sprite.sprite_data.position = sprite.position
	sprite.save_state(Global.current_state)
	await get_tree().physics_frame
	recolor_layer()

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
