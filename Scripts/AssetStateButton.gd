extends Button

@export var action: String


func _init():
	toggle_mode = true
	theme_type_variation = "RemapButton"
	
	
func _ready():
	set_process_unhandled_input(false)
	update_key_text()


func _toggled(_button_pressed):
	if %IsAssetCheck.button_pressed:
		set_process_unhandled_input(_button_pressed)
		if _button_pressed:
			text = "... Awaiting Input ..."
			release_focus()
		else:
			update_key_text()
			grab_focus()
			

func _unhandled_input(event):
	if not event is InputEventMouseMotion:
		if event.is_released():
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
			Global.held_sprite.saved_event = event
			
			button_pressed = false
	

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
	else:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
			Global.held_sprite.saved_event = null
			update_key_text()
	
	Global.held_sprite.is_asset = toggled_on
