extends Tree

signal update_tree
signal sprite_info 

@onready var cont = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")


func _ready():
	set_drop_mode_flags(3)


func _get_drag_data(at_position):
	return get_item_at_position(at_position)

func _can_drop_data(_at_position, data):
	return data is TreeItem && is_instance_valid(data)


func _drop_data(at_position, data):
	# The item it was dropped on
	var other_item = get_item_at_position(at_position)
	# -1 if its dropped above the item, 0 if its dropped on the item and 1 if its below the item
	# -100 if you didnt drop it on an item
	var drop_offset = get_drop_section_at_position(at_position)
	if is_instance_valid(other_item) && data != other_item:
		if drop_offset == -100:
	#		other_item = other_item.get_parent()
			drop_offset = 0
		
		var boolean
		if drop_offset == -1:
			if other_item != data.get_parent():
				if other_item == get_root():
					data.get_metadata(0).sprite_object.reparent(cont)
				else:
					data.get_metadata(0).sprite_object.reparent(other_item.get_metadata(0).sprite_object.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D"))
			data.move_before(other_item)
			
		
		elif drop_offset == 1:
			if other_item != data.get_parent():
				if other_item == get_root():
					data.get_metadata(0).sprite_object.reparent(cont)
				else:
					data.get_metadata(0).sprite_object.reparent(other_item.get_metadata(0).sprite_object.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D"))
				data.move_after(other_item)
				
			
			
		
		else:
			var par = data.get_parent()
			par.remove_child(data)
			other_item.add_child(data)
			
			
			if other_item == get_root():
				boolean = false
			else:
				boolean = true
		
			var parent = data.get_parent()
			update_tree.emit(data, parent, boolean)
			
			




func _on_item_selected():
	if get_selected() != get_root():
		if Global.held_sprite != null:
			if Global.held_sprite.has_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D/Origin"):
				Global.held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D/Origin").hide()
		Global.held_sprite = get_selected().get_metadata(0).sprite_object
		if Global.held_sprite.has_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D/Origin"):
			Global.held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D/Origin").show()
		emit_signal("sprite_info")
