#region Header
#01. tool

#02. class_name

#03. extends
extends Node
#endregion

#region Documentation
#-----------------------------------------------------------
#04. # docstring
## hoge
#-----------------------------------------------------------
#endregion

#region Body
#05. signals
#-----------------------------------------------------------

#-----------------------------------------------------------
#06. enums
#-----------------------------------------------------------

#-----------------------------------------------------------
#08. variables
#-----------------------------------------------------------
var global_input_csharp_packed_scene: PackedScene = preload("res://addons/global_input/autoload/global_input_csharp/GlobalInputCSharp.tscn")
@onready var global_input_csharp: Node = global_input_csharp_packed_scene.instantiate()
#-----------------------------------------------------------
#09. methods
#-----------------------------------------------------------

func _ready() -> void:
	add_child(global_input_csharp)

func is_action_just_pressed(action: StringName) -> bool:
	return global_input_csharp.IsActionJustPressed(action)

func is_action_pressed(action: StringName) -> bool:
	return global_input_csharp.IsActionPressed(action)

func is_action_just_released(action: StringName) -> bool:
	return global_input_csharp.IsActionJustReleased(action)

func is_key_pressed(key: int) -> bool:
	return global_input_csharp.IsKeyPressed(key)

func get_vector(negative_x, positive_x, negative_y, positive_y) -> Vector2:
	return global_input_csharp.GetVector(negative_x, positive_x, negative_y, positive_y)

func get_mouse_position() -> Vector2:
	return global_input_csharp.GetMousePosition()
#-----------------------------------------------------------
#10. signal methods
#-----------------------------------------------------------
