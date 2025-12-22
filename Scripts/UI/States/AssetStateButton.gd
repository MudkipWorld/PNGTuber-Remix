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
				if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
					InputMap.action_erase_events(action)
					InputMap.action_add_event(action, event)
					Global.held_sprites[0].saved_event = event
				update_other_assets()

				
				
				button_pressed = false
	elif current_remap == Remap.Keys:
		if not event is InputEventMouseMotion:
			if event.is_released():
				if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
					if InputMap.has_action(Global.held_sprites[0].disappear_keys):
						if id in range(InputMap.action_get_events(Global.held_sprites[0].disappear_keys).size()):
							InputMap.action_get_events(Global.held_sprites[0].disappear_keys).set(id, event)
						else:
							InputMap.action_add_event(Global.held_sprites[0].disappear_keys,event)
					else:
						InputMap.add_action(Global.held_sprites[0].disappear_keys)
						InputMap.action_add_event(Global.held_sprites[0].disappear_keys,event)
				%ShouldDisList.set_item_text(id, event.as_text())
				
				%ShouldDisRemapButton.button_pressed = false


func update_other_assets():
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i != Global.held_sprites[0]:
			if i.saved_event != null:
				if Global.held_sprites[0].saved_event.as_text() == i.saved_event.as_text():
					i.get_node("%Drag").visible = Global.held_sprites[0].get_node("%Drag").visible
					i.was_active_before = Global.held_sprites[0].get_node("%Drag").visible

func update_key_text():
	if InputMap.action_get_events(action).size() != 0:
		text = "%s" % InputMap.action_get_events(action)[0].as_text()
	else:
		text = "Bind Key"

func update_stuff():
	if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
		if Global.held_sprites[0].saved_event != null:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, Global.held_sprites[0].saved_event)
			
			update_key_text()

func _on_remove_asset_button_pressed():
	if InputMap.action_get_events(action).size() != 0:
		InputMap.action_erase_events(action)
		update_key_text()

func _on_is_asset_check_toggled(toggled_on):
	if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
		if toggled_on:
			if !InputMap.has_action(action):
				InputMap.add_action(action)
				Global.held_sprites[0].get_node("%Sprite2D").visible = true
		else:
			if InputMap.has_action(action):
				InputMap.erase_action(action)
				Global.held_sprites[0].saved_event = null
				Global.held_sprites[0].get_node("%Sprite2D").visible = true
				update_key_text()
		
		Global.held_sprites[0].is_asset = toggled_on

func _on_should_disappear_check_toggled(toggled_on):
	if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
		Global.held_sprites[0].should_disappear = toggled_on
	if toggled_on:
		%ShouldDisListContainer.show()
	else:
		%ShouldDisListContainer.hide()

func _on_should_dis_add_button_pressed():
	%ShouldDisList.add_item("Null")

func _on_should_dis_del_button_pressed():
	%ShouldDisList.remove_item(id)
	
	var held = Global.held_sprites[0]
	if held != null && is_instance_valid(held):
		var action_name = held.disappear_keys
		if InputMap.has_action(action_name):
			var events = InputMap.action_get_events(action_name)
			if id >= 0 && id < events.size():
				var ev = events[id]
				InputMap.action_erase_event(action_name, ev)

		
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
		%ShouldDisList.set_item_text(id, "Awaiting Input.")

func _on_should_dis_list_empty_clicked(_at_position, _mouse_button_index):
	selected_item = null
	id = null
	%ShouldDisRemapButton.disabled = true
	%ShouldDisDelButton.disabled = true


func _on_should_dis_list_focus_exited():
	selected_item = null
	id = null
	%ShouldDisRemapButton.disabled = true
	%ShouldDisDelButton.disabled = true


func _on_dont_hide_on_toggle_check_toggled(toggled_on: bool) -> void:
	if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
		Global.held_sprites[0].show_only = toggled_on


func _on_hold_to_show_on_toggle_check_toggled(toggled_on: bool) -> void:
	if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
		Global.held_sprites[0].hold_to_show = toggled_on
