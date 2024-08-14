extends Button

@export var action: String

enum Remap {
	
	Asset,
	Keys,
	
}

var current_remap : Remap
var selected_item = null
var id

func _init():
	toggle_mode = true
	theme_type_variation = "RemapButton"
	
	
func _ready():
	set_process_unhandled_input(false)
	update_key_text()


func _toggled(_button_pressed):
	current_remap = Remap.Asset
	if %IsAssetCheck.button_pressed:
		set_process_unhandled_input(_button_pressed)
		if _button_pressed:
			text = "... Awaiting Input ..."
			release_focus()
		else:
			update_key_text()
			grab_focus()
			

func _unhandled_input(event):
	if current_remap == Remap.Asset:
		if not event is InputEventMouseMotion:
			if event.is_released():
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, event)
				Global.held_sprite.saved_event = event
				
				button_pressed = false
	elif current_remap == Remap.Keys:
		if not event is InputEventMouseMotion:
			if event.is_released():
				if id in range(Global.held_sprite.saved_keys.size() -1):
					Global.held_sprite.saved_keys.remove_at(id)
				Global.held_sprite.saved_keys.append(event.as_text())
				%ShouldDisList.set_item_text(id, event.as_text())
				
				%ShouldDisRemapButton.button_pressed = false
	

func update_key_text():
	if InputMap.action_get_events(action).size() != 0:
		text = "%s" % InputMap.action_get_events(action)[0].as_text()
	else:
		text = "Null"

func update_stuff():
	if Global.held_sprite.saved_event != null:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, Global.held_sprite.saved_event)
		
		update_key_text()

func _on_remove_asset_button_pressed():
	if InputMap.action_get_events(action).size() != 0:
		InputMap.action_erase_events(action)
		update_key_text()


func _on_is_asset_check_toggled(toggled_on):
	if toggled_on:
		if !InputMap.has_action(action):
			InputMap.add_action(action)
			Global.held_sprite.get_node("%Drag").visible = true
	else:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
			Global.held_sprite.saved_event = null
			Global.held_sprite.get_node("%Drag").visible = true
			update_key_text()
	
	Global.held_sprite.is_asset = toggled_on


func _on_should_disappear_check_toggled(toggled_on):
	Global.held_sprite.should_disappear = toggled_on
	if toggled_on:
		%ShouldDisListContainer.show()
	else:
		%ShouldDisListContainer.hide()



func _on_should_dis_add_button_pressed():
	%ShouldDisList.add_item("Null")


func _on_should_dis_del_button_pressed():
	%ShouldDisList.remove_item(id)
	Global.held_sprite.saved_keys.remove_at(id)
	%ShouldDisRemapButton.disabled = false
	%ShouldDisDelButton.disabled = false

func _on_should_dis_list_item_selected(index):
	id = index
	%ShouldDisRemapButton.disabled = false
	%ShouldDisDelButton.disabled = false
	




func _on_should_dis_remap_button_toggled(toggled_on):
	current_remap = Remap.Keys
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		%ShouldDisList.set_item_text(id, "... Awaiting Input ...")
		%ShouldDisRemapButton.release_focus()
	else:
		%ShouldDisRemapButton.grab_focus()

func _on_should_dis_list_empty_clicked(_at_position, _mouse_button_index):
	selected_item = null
	id = null
	%ShouldDisRemapButton.disabled = true
	%ShouldDisDelButton.disabled = true
