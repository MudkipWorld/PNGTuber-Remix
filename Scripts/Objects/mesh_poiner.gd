extends Node2D

var enabled : bool = false


func _physics_process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if enabled:
		draw_circle(get_global_mouse_position(), MeshEditor.influence_radius/2.0, Color(1,0,0), false)
