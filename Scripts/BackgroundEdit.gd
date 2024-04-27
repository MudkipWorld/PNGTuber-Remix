extends Node

@onready var tree = %BackgroundTree

func _ready():
	held_sprite_is_null()
	%BackgroundTree.connect("sprite_bg_info", reinfo)
	var sprite_nodes = get_tree().get_nodes_in_group("BackgroundStuff")
	_tree(sprite_nodes)

func _tree(sprites):
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Sprites")
	for i in sprites:
		var new_item
		new_item = tree.create_item(root)
		new_item.set_text(0, str(i.sprite_name))
		new_item.set_icon(0, i.get_node("Pos//Wobble/Squish/Drag/Sprite2D").texture)
		new_item.set_icon_max_width(0, 20)
		var dic : Dictionary = {
			sprite_object = i,
		#	parent = new_item.get_parent()
		}
		new_item.set_metadata(0, dic)
		i.treeitem = new_item
		new_item.get_next()

func _added_tree(sprites):
	for i in sprites:
		var new_item
		new_item = tree.create_item(tree.get_root())
		new_item.set_text(0, str(i.sprite_name))
		new_item.set_icon(0, i.get_node("Pos//Wobble/Squish/Drag/Sprite2D").texture)
		new_item.set_icon_max_width(0, 20)
		var dic : Dictionary = {
			sprite_object = i,
		#	parent = new_item.get_parent()
		}
		new_item.set_metadata(0, dic)
		i.treeitem = new_item
		new_item.get_next()

func new_tree():
	var root = tree.create_item()
	root.set_text(0, "Sprites")

func loaded_tree(sprites):
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Sprites")
	_tree(sprites)

func add_item(sprite):
	var root = tree.get_root()
	var new_item
	new_item = tree.create_item(root)
	new_item.set_text(0, str(sprite.sprite_name))
	new_item.set_icon(0, sprite.get_node("Pos//Wobble/Squish/Drag/Sprite2D").texture)
	new_item.set_icon_max_width(0, 20)
	var dic : Dictionary = {
		sprite_object = sprite,
#		parent = new_item.get_parent()
	}
	new_item.set_metadata(0, dic)
	sprite.treeitem = new_item
	new_item.get_next()

func _on_bg_duplicate_button_pressed():
	if  Global.held_bg_sprite != null:
		var obj = preload("res://Misc/BackgroundObject/background_object.tscn").instantiate()
		get_parent().get_parent().get_node("SubViewportContainer2/SubViewport/BackgroundStuff/BGContainer").add_child(obj)
		obj.texture = Global.held_bg_sprite.get_node("Pos//Wobble/Squish/Drag/Sprite2D").texture
		obj.get_node("Pos//Wobble/Squish/Drag/Sprite2D").texture = Global.held_bg_sprite.get_node("Pos//Wobble/Squish/Drag/Sprite2D").texture
		obj.sprite_name = "Duplicate" + Global.held_bg_sprite.sprite_name 
		add_item(obj)

func _on_bg_delete_button_pressed():
	if Global.held_bg_sprite != null:
		Global.held_bg_sprite.treeitem.free()
		Global.held_bg_sprite.queue_free()
		Global.held_bg_sprite = null



# Buttons Stuff

func held_sprite_is_null():
	%BGColorPickerButton.disabled = true
	%BGPosXSpinBox.editable = false
	%BGPosYSpinBox.editable = false
	%BGRotSpinBox.editable = false
	%BGSizeSpinBox.editable = false
	%BGSizeSpinYBox.editable = false
	%BGVisible.disabled = true
	%BGZOrderSpinbox.editable = false
	%BGReacttoLight.disabled = true

func held_sprite_is_true():
	%DeselectButton.show()
	%BGColorPickerButton.disabled = false
	%BGPosXSpinBox.editable = true
	%BGPosYSpinBox.editable = true
	%BGRotSpinBox.editable = true
	%BGSizeSpinBox.editable = true
	%BGSizeSpinYBox.editable = true
	%BGVisible.disabled = false
	%BGZOrderSpinbox.editable = true
	%BGReacttoLight.disabled = false

func reinfo():
	
	%BGColorPickerButton.color = Global.held_bg_sprite.modulate
	%BGPosXSpinBox.value = Global.held_bg_sprite.global_position.x
	%BGPosYSpinBox.value = Global.held_bg_sprite.global_position.y
	%BGRotSpinBox.value = Global.held_bg_sprite.rotation
	%BGSizeSpinBox.value = Global.held_bg_sprite.scale.x
	%BGSizeSpinYBox.value = Global.held_bg_sprite.scale.y
	%BGVisible.button_pressed = Global.held_bg_sprite.visible
	%BGZOrderSpinbox.value = Global.held_bg_sprite.z_index
	if Global.held_bg_sprite.light_mask == 1:
		%BGReacttoLight.button_pressed = true
	else:
		%BGReacttoLight.button_pressed = false
	
	held_sprite_is_true()

func update_pos_spins():
	%BGPosXSpinBox.value = Global.held_bg_sprite.global_position.x
	%BGPosYSpinBox.value = Global.held_bg_sprite.global_position.y
	%BGRotSpinBox.value = Global.held_bg_sprite.rotation

func _on_bg_color_picker_button_color_changed(color):
	Global.held_bg_sprite.modulate = color
	Global.held_bg_sprite.save_state(Global.current_state)

func _on_bg_pos_x_spin_box_value_changed(value):
	Global.held_bg_sprite.global_position.x = value
	Global.held_bg_sprite.save_state(Global.current_state)

func _on_bg_pos_y_spin_box_value_changed(value):
	Global.held_bg_sprite.global_position.y = value
	Global.held_bg_sprite.save_state(Global.current_state)

func _on_bg_rot_spin_box_value_changed(value):
	Global.held_bg_sprite.rotation = value
	Global.held_bg_sprite.save_state(Global.current_state)

func _on_bg_size_spin_box_value_changed(value):
	Global.held_bg_sprite.scale.x = value
	Global.held_bg_sprite.dictmain.scale.x = value
	Global.held_bg_sprite.save_state(Global.current_state)

func _on_bg_size_spin_y_box_value_changed(value):
	Global.held_bg_sprite.scale.y = value
	Global.held_bg_sprite.dictmain.scale.y = value
	Global.held_bg_sprite.save_state(Global.current_state)

func _on_bg_visible_toggled(toggled_on):
	Global.held_bg_sprite.visible = toggled_on
	Global.held_bg_sprite.save_state(Global.current_state)

func _on_bgz_order_spinbox_value_changed(value):
	Global.held_bg_sprite.z_index = value
	Global.held_bg_sprite.save_state(Global.current_state)


func _on_bg_reactto_light_toggled(toggled_on):
	if toggled_on:
		Global.held_bg_sprite.light_mask = 1
	else:
		Global.held_bg_sprite.light_mask = 2
	
	Global.held_bg_sprite.save_state(Global.current_state)
