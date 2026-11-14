extends Node

# Only the services referenced by the production scripts under test.
signal reinfo
signal update_layer_visib

var current_state := 0
var settings_dict := {"states": [{}, {}, {}], "checkinput": false}
var loaded_states: Array[int] = []
var throwable_spawner
var image_manager_data: Array = []

func load_sprite_states(state: int) -> void:
	current_state = state
	loaded_states.append(state)

func get_sprite_states(state: int) -> void:
	load_sprite_states(state)

func load_file(_path: String) -> void:
	pass

func is_action_just_pressed(_action: String) -> bool:
	return false
