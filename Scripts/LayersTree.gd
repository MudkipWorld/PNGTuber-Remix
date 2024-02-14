extends Tree

signal update_tree
signal sprite_info 

var dragging : bool = false
var item

func _ready():
	set_drop_mode_flags(3)

func _input(event):
	if event.is_action_pressed("lmb"):
		dragging = true
		item = get_item_at_position(get_local_mouse_position())
		
	if event.is_action_released("lmb") && dragging:
		_drop_data(get_local_mouse_position(), item)
		dragging = false



func _drop_data(at_position, _data):
	# The item it was dropped on
	var other_item = get_item_at_position(at_position)
	# -1 if its dropped above the item, 0 if its dropped on the item and 1 if its below the item
	# -100 if you didnt drop it on an item
	var drop_offset = get_drop_section_at_position(at_position)
	if is_instance_valid(other_item) && item != other_item:
		if drop_offset == -100:
	#		other_item = other_item.get_parent()
			drop_offset = 0
		
		var boolean
		if drop_offset == -1:
			item.move_before(other_item)
			
		elif drop_offset == 1:
			item.move_after(other_item)
		
		else:
			var par = item.get_parent()
			par.remove_child(item)
			other_item.add_child(item)
			
			
			if other_item == get_root():
				boolean = false
			else:
				boolean = true
		
			var parent = item.get_parent()
			update_tree.emit(item, parent, boolean)
			
func _on_item_selected():
	if get_selected() != get_root():
		if Global.held_sprite != null:
			Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").hide()
		Global.held_sprite = get_selected().get_metadata(0).sprite_object
		Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").show()
		emit_signal("sprite_info")
		
