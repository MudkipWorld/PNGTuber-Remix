extends Button

@export var state : int 
@export var input_key : String = "Null"

func _ready():
	if get_tree().get_root().has_node("Main"):
		get_tree().get_root().get_node("Main").key_pressed.connect(bg_key_pressed)
	if get_tree().get_root().has_node("CollabMain"):
		get_tree().get_root().get_node("CollabMain").key_pressed.connect(bg_key_pressed)

func _on_pressed():
	Global.get_sprite_states(state)
#	print(state)


func _input(event):
	if input_key != "Null":
		if event.is_action_pressed(input_key):
			Global.get_sprite_states(state)

func bg_key_pressed(key):
	if key == state:
		Global.get_sprite_states(state)
