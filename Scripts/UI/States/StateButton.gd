extends Button
class_name StateButton

@export var state : int 
@export var input_key : String = str(randi())
var saved_event : InputEvent
var state_name : String 
var state_hold_to_show : bool = false
var state_inclusive_key_check : bool = false
static var selected_state : StateButton = null
static var other_states : Array[StateButton] = []

func _ready():
	if state_name.is_empty():
		state_name = str(state+1)
	text = state_name
	if state == 0:
		select_state()
	
	self.process_physics_priority = -1

func _on_pressed():
	if Input.is_action_pressed("ctrl"):
		if selected_state == null && self not in other_states:
			select_state()
			Global.get_sprite_states(state)
			return
		elif selected_state != self && self not in other_states:
			other_states.append(self)
			%Selected.show()
			return
		elif selected_state == self && other_states.size() > 0:
			%Selected.hide()
			var placeholder = other_states[0]
			other_states.erase(placeholder)
			placeholder.get_node("%Selected").show()
			selected_state = placeholder
			Global.get_sprite_states(placeholder.state)
			return
		elif self in other_states:
			other_states.erase(self)
			%Selected.hide()
			return

	else:
		for i in other_states:
			i.get_node("%Selected").hide()
			
		other_states.clear()
		select_state()
		Global.get_sprite_states(state)

func initial_update():
	Global.get_sprite_states(state)

func select_state():
	if selected_state != null && is_instance_valid(selected_state):
		selected_state.get_node("%Selected").hide()
	selected_state = self
	%Selected.show()

func _physics_process(_delta: float) -> void:
	if Global.settings_dict.checkinput != true:
		return
		
	if StateUI.is_showing_state_remap_popup:
		return
	
	if input_key == "Null" or input_key == "":
		return
	
	if state_hold_to_show:
		var is_action_pressed = GlobInput.is_input_pressed(saved_event, state_inclusive_key_check)
		
		if is_action_pressed:
			if Global.current_state == state:
				pass
			elif GlobInput.is_input_pressed(selected_state.saved_event, state_inclusive_key_check):
				pass
			else:
				select_state()
				Global.get_sprite_states(state)
				#print("switch on")
		elif !is_action_pressed and Global.current_state == state:
			var target_btn : StateButton = (get_parent().get_child(0) as StateButton)
			
			for btn in get_parent().get_children():
				if btn.state_hold_to_show and GlobInput.is_input_pressed(btn.saved_event, state_inclusive_key_check):
					target_btn = btn
				
			target_btn.select_state()
			Global.get_sprite_states(target_btn.state)
			#print("switch off")
	elif GlobInput.is_input_just_pressed(saved_event, state_inclusive_key_check):
		select_state()
		Global.get_sprite_states(state)
		#print("switch normal")
	
func update_stuff():
	if saved_event != null && InputMap.has_action(input_key):
		InputMap.action_erase_events(input_key)
		InputMap.action_add_event(input_key, saved_event)

static func multi_edit(value, value_name, _obj : SpriteObject, states : Array, should_change : bool = false, type : String = "x"):
	if other_states.size() > 0:
		for i in other_states:
			if i == null or !is_instance_valid(i):
				other_states.erase(i)
				continue
			if i.state in range(states.size()):
				if should_change:
					if type == "x":
						states[i.state][value_name].x = value
					else:
						states[i.state][value_name].y = value
				else:
					states[i.state][value_name] = value
			
			#print(value_name)
	else:
		return
