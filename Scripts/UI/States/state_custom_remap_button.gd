extends HBoxContainer
class_name RemapCustomButton

@export var key_type : String
var state_button: Node

func _ready():
	set_process_unhandled_input(false)
	update_key_text()
	match key_type:
		'key_up':
			%State.text = 'Key Up'
		'key_down':
			%State.text = 'Key Down'
		'key_left':
			%State.text = 'Key Left'
		'key_right':
			%State.text = 'Key Right'

func _on_state_remap_button_toggled(toggled_on: bool) -> void:
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		%StateRemapButton.text = tr("TR_AWAITING_INPUT")
		release_focus()
	else:
		update_key_text()
		grab_focus()

func _unhandled_input(event):
	if not event is InputEventMouseMotion:
		if event.is_released():
			if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
				check_key(StateButton.selected_state.input_key, event)
			%StateRemapButton.button_pressed = false

func check_key(action : String, event : InputEvent) -> void:
	var final_action : String = key_type + action
	if !InputMap.has_action(final_action):
		InputMap.add_action(final_action)
	
	InputMap.action_erase_events(final_action)
	InputMap.action_add_event(final_action, event)
	
	match key_type:
		'key_up':
			StateButton.selected_state.key_up = event
		'key_down':
			StateButton.selected_state.key_down = event
		'key_left':
			StateButton.selected_state.key_left = event
		'key_right':
			StateButton.selected_state.key_right = event

func update_key_text():
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		var action : String = StateButton.selected_state.input_key
		var final_action : String = key_type + action
		if InputMap.action_get_events(final_action).size() != 0:
			%StateRemapButton.text = "%s" % InputMap.action_get_events(final_action)[0].as_text()
		else:
			%StateRemapButton.text = "Null"

func _on_remove_pressed():
	if StateButton.selected_state == null or !is_instance_valid(StateButton.selected_state): return
	var action : String = StateButton.selected_state.input_key
	var final_action : String = key_type + action
	if InputMap.action_get_events(final_action).size() != 0:
		InputMap.action_erase_events(final_action)
		
		match key_type:
			'key_up':
				StateButton.selected_state.key_up = null
			'key_down':
				StateButton.selected_state.key_down = null
			'key_left':
				StateButton.selected_state.key_left = null
			'key_right':
				StateButton.selected_state.key_right = null
		update_key_text()
