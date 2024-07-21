extends Button

@export var state : int 
@export var input_key : String = "Null"

func _ready():
	pass

func _on_pressed():
	Global.get_sprite_states(state)
#	print(state)

func initial_update():
	Global.get_sprite_states(state)

func _physics_process(delta):
	if input_key != "Null" && InputMap.has_action(input_key):
		if GlobalInput.is_action_just_pressed(input_key):
			Global.get_sprite_states(state)
