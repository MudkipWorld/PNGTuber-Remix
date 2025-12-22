extends Node
class_name StateUI

var state_button  = preload("res://UI/StateButton/state_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.delete_states.connect(delete_all_states)
	Global.remake_states.connect(update_states)
	Global.reset_states.connect(initial_state)
	Global.remake_for_plus.connect(plus_import)
	delete_all_states()
	initial_state()

func initial_state():
		
	add_state()

func _on_delete_state_pressed():
	if Global.settings_dict.states.size() > 1:
		
		var state_btn  = get_tree().get_nodes_in_group("StateButtons")
		
		InputMap.erase_action(state_btn[Global.current_state].input_key)
		
		
		state_btn[Global.current_state].queue_free()

		Global.settings_dict.states.remove_at(Global.current_state)
		Global.settings_dict.light_states.remove_at(Global.current_state)
		
		
		
		var sprites = get_tree().get_nodes_in_group("Sprites")
		for i in sprites:
			i.states.remove_at(Global.current_state)
		
		Global.current_state = 0
		get_tree().get_first_node_in_group("StateButtons").select_state()
		Global.load_sprite_states(Global.current_state)
		
	update_state_numbering()

func update_state_numbering():
	
	await get_tree().create_timer(0.08).timeout
	
	for i in get_tree().get_nodes_in_group("StateButtons"):
		if is_instance_valid(i):
			i.state = i.get_index()
		#	print(i.get_index())

func _on_add_state_pressed():
	add_state()
	Global.current_state = Global.settings_dict.states.size() - 1
	Global.load_sprite_states(Global.current_state)

func delete_all_states():
	Global.settings_dict.saved_inputs.clear()
	var state_btn  = get_tree().get_nodes_in_group("StateButtons")
		
	for i in state_btn:
		if InputMap.has_action(i.input_key):
			InputMap.erase_action(i.input_key)
		
	for i in state_btn:
		i.queue_free()
		
	Global.settings_dict.states = []
	Global.settings_dict.light_states = [{}]

func plus_import():
	for i in 9:
		add_state()

func add_state():
	var button = state_button.instantiate()
	var state_count = Global.settings_dict.states.size()
	button.state = state_count
	button.text = str(state_count + 1) 
	%StateButtons.add_child(button)
	InputMap.add_action(button.input_key)
	
	Global.settings_dict.states.append({
	mouth_closed = 0,
	mouth_open = 3,
	current_mc_anim = "Idle",
	current_mo_anim = "One Bounce",
	})
	
	Global.settings_dict.light_states.append({})
	
	state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			for l in abs(i.states.size() - state_count):
				i.states.append({})
	
	Global.settings_dict.saved_inputs.resize(Global.settings_dict.states.size())


func update_states(states):
	var states_size = states.size()
	for l in states_size:
		var button = state_button.instantiate()
		button.state = l 
		button.text = str(l + 1)
		%StateButtons.add_child(button)
		InputMap.add_action(button.input_key)
		var state_count = get_tree().get_nodes_in_group("StateButtons").size()
		for i in get_tree().get_nodes_in_group("Sprites"):
			if i.states.size() != state_count:
				for h in abs(i.states.size() - state_count):
					i.states.append({})

func _on_duplicate_state_pressed() -> void:
	var button = state_button.instantiate()
	var state_count = Global.settings_dict.states.size()
	button.state = state_count
	button.text = str(state_count + 1) 
	%StateButtons.add_child(button)
	InputMap.add_action(button.input_key)
	
	Global.settings_dict.states.append(Global.settings_dict.states[Global.current_state].duplicate(true))
	
	Global.settings_dict.light_states.append(Global.settings_dict.light_states[Global.current_state].duplicate(true))
	
	state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			for l in abs(i.states.size() - state_count):
				i.states.append(i.sprite_data.duplicate(true))
				
	
	Global.settings_dict.saved_inputs.resize(Global.settings_dict.states.size())

func _on_state_remap_pressed() -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		%StateName.text = StateButton.selected_state.state_name
	%StateButtonHbox.get_node("StateRemapButton").update_key_text()
	%StateRemapPopup.popup()

func _on_state_remap_popup_close_requested() -> void:
	%StateRemapPopup.hide()

func _on_state_name_text_submitted(new_text: String) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.state_name = new_text
		StateButton.selected_state.text = new_text
