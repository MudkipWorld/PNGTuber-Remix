extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	delete_all_states()
	initial_state()

func initial_state():
		
	add_state()

func _on_delete_state_pressed():
	if Global.current_state != 0:
		
		var state_remap = get_tree().get_nodes_in_group("StateRemapButton")
		var state_btn  = get_tree().get_nodes_in_group("StateButtons")
		
		for i in state_remap:
			InputMap.erase_action(i.action)
		
		for i in state_btn:
			i.input_key = "Null"
		
		state_remap[Global.current_state].get_parent().queue_free()
		
		
		state_btn[Global.current_state].queue_free()
		
		Global.settings_dict.saved_inputs.remove_at(Global.current_state)
		Global.settings_dict.states.remove_at(Global.current_state)
		Global.settings_dict.light_states.remove_at(Global.current_state)
		
		
		
		var sprites = get_tree().get_nodes_in_group("Sprites")
		for i in sprites:
			i.states.remove_at(Global.current_state)
		
		Global.current_state = 0
		Global.load_sprite_states(Global.current_state)
		
	update_state_numbering()

func update_state_numbering():
	
	await get_tree().create_timer(0.08).timeout
	
	var id = 0

	id = 0
	for i in get_tree().get_nodes_in_group("StateRemapButton"):
		if is_instance_valid(i):
			i.get_parent().get_node("State").text = "State " + str(id + 1)
			i.action = "State " + str(id)
			InputMap.add_action(i.action)
			print(i.action)
			i.update_stuff()
			id += 1
			
			
	for i in get_tree().get_nodes_in_group("StateButtons"):
		if is_instance_valid(i):
			i.text = str(i.get_index() + 1)
			i.state = i.get_index()
			i.input_key = get_tree().get_nodes_in_group("StateRemapButton")[i.get_index()].action
			print(i.get_index())

func _on_add_state_pressed():
	add_state()
	Global.current_state = Global.settings_dict.states.size() - 1
	Global.load_sprite_states(Global.current_state)

func delete_all_states():
	Global.settings_dict.saved_inputs.clear()
	var state_remap = get_tree().get_nodes_in_group("StateRemapButton")
	var state_btn  = get_tree().get_nodes_in_group("StateButtons")
		
	for i in state_remap:
		if InputMap.has_action(i.action):
			InputMap.erase_action(i.action)
		i.get_parent().queue_free()
		
	for i in state_btn:
		i.queue_free()
		
	Global.settings_dict.states = []
	Global.settings_dict.light_states = [{}]

func add_state():
	if get_tree().get_nodes_in_group("StateButtons").size() < 200:
		var button = preload("res://UI/StateButton/state_button.tscn").instantiate()
		var state_count = Global.settings_dict.states.size()
		button.state = clamp(state_count, 0, 200)
		button.input_key = "State " + str(button.state)
		button.text = str(clamp(state_count + 1, 0, 200))
		%StateButtons.add_child(button)
		
		
		var remap_btn = preload("res://UI/StateButton/state_remap_button.tscn").instantiate()
		remap_btn.get_node("State").text = "State " + button.text
		remap_btn.get_node("StateRemapButton").action = "State " + str(button.state)
		%Grid.add_child(remap_btn)
		InputMap.add_action(remap_btn.get_node("StateRemapButton").action)
		
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
					




func update_states(states):
	var states_size = states.size()
	for l in states_size:
		var button = preload("res://UI/StateButton/state_button.tscn").instantiate()
		button.state = l 
		button.input_key = "State " + str(button.state)
		button.text = str(l + 1)
		%StateButtons.add_child(button)
		
		
		var remap_btn = preload("res://UI/StateButton/state_remap_button.tscn").instantiate()
		remap_btn.get_node("State").text = "State " + button.text
		remap_btn.get_node("StateRemapButton").action = "State " + str(button.state)
		InputMap.add_action("State " + str(button.state), 0.5)
		
		%Grid.add_child(remap_btn)
		var state_count = get_tree().get_nodes_in_group("StateButtons").size()
		for i in get_tree().get_nodes_in_group("Sprites"):
			if i.states.size() != state_count:
				for h in abs(i.states.size() - state_count):
					i.states.append({})
