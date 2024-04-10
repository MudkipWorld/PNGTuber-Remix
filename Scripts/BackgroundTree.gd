extends Tree

signal update_tree
signal sprite_bg_info 

var dragging : bool = false
var item

func _ready():
	pass

func _input(event):
	if Input.is_action_just_pressed("lmb"):
		dragging = true
		item = get_item_at_position(get_local_mouse_position())
		
	if Input.is_action_just_released("lmb") && dragging:
		_drop_data(get_local_mouse_position(), item)
		dragging = false

func _drop_data(at_position, _data):
	# The item it was dropped on
	if get_parent().visible:
		var other_item = get_item_at_position(at_position)
		# -1 if its dropped above the item, 0 if its dropped on the item and 1 if its below the item
		# -100 if you didnt drop it on an item
		var drop_offset = get_drop_section_at_position(at_position)
		if is_instance_valid(other_item) && item != other_item:
			if other_item:
				if drop_offset == -100:
			#		other_item = other_item.get_parent()
					drop_offset = 0
				
				if drop_offset == -1:
					item.move_before(other_item)
					
				elif drop_offset == 1:
					item.move_after(other_item)
					
				else:
					item.move_before(other_item)

func _on_item_selected():
	if get_selected() != get_root():
		if Global.held_bg_sprite != null:
			if Global.held_bg_sprite.has_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin"):
				Global.held_bg_sprite.get_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin").hide()
		Global.held_bg_sprite = get_selected().get_metadata(0).sprite_object
		if Global.held_bg_sprite.has_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin"):
			Global.held_bg_sprite.get_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin").show()
		emit_signal("sprite_bg_info")
