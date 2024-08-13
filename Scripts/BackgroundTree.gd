extends Tree

signal update_tree
signal sprite_bg_info 

@onready var bg_popup: PopupMenu = $PopupMenuBG
@onready var bgedit: = get_tree().get_root().get_node("Main/Control/BackgroundEdit")
@onready var topbarinput: = get_tree().get_root().get_node("Main/Control/TopBarInput")

func _ready():
	Global.reinfo.connect(update_visib_buttons)
	set_drop_mode_flags(3)
	bg_popup.connect("id_pressed",choosing_bg_popup)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var item = get_item_at_position(event.position)
			if item != null:
				item.select(0)
				bg_popup.popup_on_parent(Rect2(event.global_position, Vector2.ZERO))
	else: 
		pass
		

func choosing_bg_popup(id):
	var main = get_tree().get_root().get_node("Main")
	match id:
		0: #add bg
			main.load_bg_sprites()
		1:  #duplicate
			bgedit._on_bg_duplicate_button_pressed()
		2:#delete
			bgedit._on_bg_delete_button_pressed()
		3:#deselect
			topbarinput.desel_everything()


func _get_drag_data(at_position):
	return get_item_at_position(at_position)

func _can_drop_data(_at_position, data):
	return data is TreeItem && is_instance_valid(data) && _at_position

func _drop_data(at_position, data):
	# The item it was dropped on
	if get_parent().visible:
		var other_item = get_item_at_position(at_position)
		# -1 if its dropped above the item, 0 if its dropped on the item and 1 if its below the item
		# -100 if you didnt drop it on an item
		var drop_offset = get_drop_section_at_position(at_position)
		if is_instance_valid(other_item) && data != other_item:
			if other_item:
				if drop_offset == -100:
			#		other_item = other_item.get_parent()
					drop_offset = 0
				
				if drop_offset == -1:
					data.move_before(other_item)
					
				elif drop_offset == 1:
					data.move_after(other_item)
					
				else:
					data.move_before(other_item)

func _on_item_selected():
	if get_selected() != get_root():
		if Global.held_bg_sprite != null:
			if Global.held_bg_sprite.has_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin"):
				Global.held_bg_sprite.get_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin").hide()
		Global.held_bg_sprite = get_selected().get_metadata(0).sprite_object
		if Global.held_bg_sprite.has_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin"):
			Global.held_bg_sprite.get_node("Pos/Wobble/Squish/Drag/Sprite2D/Origin").show()
		emit_signal("sprite_bg_info")

func update_visib_buttons():
	for i in get_tree().get_nodes_in_group("BackgroundStuff"):
		if i.dictmain.visible:
			i.treeitem.set_button(0, 0, preload("res://UI/EyeButton.png"))
		elif not i.dictmain.visible:
			i.treeitem.set_button(0, 0, preload("res://UI/EyeButton2.png"))
