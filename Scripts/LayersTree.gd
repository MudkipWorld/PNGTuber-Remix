extends Tree

signal update_tree
signal sprite_info 

@onready var cont = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
@onready var layers_popup: PopupMenu = $LayersPopup
@onready var uiinput: = get_tree().get_root().get_node("Main/Control/UIInput")
@onready var topbarinput: = get_tree().get_root().get_node("Main/Control/TopBarInput")


func _ready():
	set_drop_mode_flags(3)
	var root = create_item()
	root.set_text(0, "Sprites")
	
	layers_popup.connect("id_pressed",choosing_layers_popup)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var item = get_item_at_position(event.position)
			if item != null:
				item.select(0)
				layers_popup.popup_on_parent(Rect2(event.global_position, Vector2.ZERO))
	else: 
			pass

func choosing_layers_popup(id):
	var main = get_tree().get_root().get_node("Main")
	match id:
		0:
			main.load_sprites()
		1:  
			uiinput._on_folder_button_pressed()
		2:#replace
			get_tree().get_root().get_node("Main").replacing_sprite()
		3:#duplicate
			uiinput._on_duplicate_button_pressed()
		4:#Delete
			uiinput._on_delete_button_pressed()
		5:#add normal
			get_tree().get_root().get_node("Main").add_normal_sprite()
		6: #delete normal
			uiinput._on_del_normal_button_pressed()
		7: #Deselect
			topbarinput.desel_everything()

func _get_drag_data(at_position):
	return get_item_at_position(at_position)


func _can_drop_data(_at_position, data):
	return data is TreeItem && is_instance_valid(data) && _at_position


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
			if other_item is TreeItem:
				if other_item != data.get_parent():
					if other_item == get_root():
						data.get_metadata(0).sprite_object.reparent(cont)
					else:
						data.get_metadata(0).sprite_object.reparent(other_item.get_metadata(0).sprite_object.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D"))
					
					data.move_before(other_item)
			else:
				return
			
		
		elif drop_offset == 1:
			if other_item is TreeItem:
				if other_item != data.get_parent():
					if other_item == get_root():
						data.get_metadata(0).sprite_object.reparent(cont)
					else:
						data.get_metadata(0).sprite_object.reparent(other_item.get_metadata(0).sprite_object.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D"))
					data.move_after(other_item)
			else:
				return
			
			
		
		else:
			
			for i in get_all_treeitems(data, true):
				if i == other_item:
					return
			
			
			var par = data.get_parent()
			par.remove_child(data)
			other_item.add_child(data)
			
			
			if other_item == get_root():
				boolean = false
			else:
				boolean = true
		
			var parent = data.get_parent()
			update_tree.emit(data, parent, boolean)
			
	

static func get_all_treeitems(treeitem, recursive) -> Array:
	var children := []
	for child in treeitem.get_children():
		children.append(child)
		
		if recursive and child.get_child_count():
			children.append_array(get_all_treeitems(child, true))
		
	return children



func _on_item_selected():
	if get_selected() != get_root():
		if Global.held_sprite != null:
			if Global.held_sprite.has_node("Pos//Wobble/Squish/Drag/Rotation/Origin"):
				Global.held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Origin").hide()
		Global.held_sprite = get_selected().get_metadata(0).sprite_object
		if Global.held_sprite.has_node("Pos//Wobble/Squish/Drag/Rotation/Origin"):
			Global.held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Origin").show()
		emit_signal("sprite_info")
