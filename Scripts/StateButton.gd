extends Button

@export var state : int 
@export var input_key : String = "Null"

func _ready():
	get_tree().get_root().get_node("Main").key_pressed.connect(bg_key_pressed)

func _on_pressed():
	Global.get_sprite_states(state)
#	print(state)

func initial_update():
	Global.get_sprite_states(state)


func _input(event):
	if input_key != "Null":
		if event.is_action_pressed(input_key):
			Global.get_sprite_states(state)

func bg_key_pressed(key):
	if InputMap.action_get_events(input_key).size() > 0:
		var inputs = InputMap.action_get_events(input_key)[0]
		if key == inputs.as_text():
			Global.get_sprite_states(state)
