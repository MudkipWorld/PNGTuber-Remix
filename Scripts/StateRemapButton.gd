extends Button
class_name RemapButton

@export var action: String

func _init():
	toggle_mode = true
	theme_type_variation = "RemapButton"
	
	
func _ready():
	set_process_unhandled_input(false)
	update_key_text()


func _toggled(_button_pressed):
	set_process_unhandled_input(_button_pressed)
	if _button_pressed:
		text = "... Awaiting Input ..."
		release_focus()
	else:
		update_key_text()
		grab_focus()
		

func _unhandled_input(event):
	if not event is InputEventMouseMotion:
		if event.pressed:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
			button_pressed = false
	

func update_key_text():
	text = "%s" % InputMap.action_get_events(action)[0].as_text()

