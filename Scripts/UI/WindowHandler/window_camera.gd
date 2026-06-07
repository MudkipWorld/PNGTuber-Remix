extends Camera2D
class_name WindowCamera

var panning := false
var mouse_start_pos := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scrollup"):
		set_zoom_to(zoom * 1.1)
	elif event.is_action_pressed("scrolldown"):
		set_zoom_to(zoom / 1.1)
	
	if event.is_action_pressed("pan"):
		panning = true
		mouse_start_pos = get_global_mouse_position()
	elif event.is_action_released("pan"):
		panning = false

func _process(_delta: float) -> void:
	if !panning: return
	var change := get_global_mouse_position() - mouse_start_pos
	global_position -= change

func set_zoom_to(new_zoom: Vector2) -> void:
	var mouse_pos := get_global_mouse_position()
	var cam_pos := get_screen_center_position()
	var last_zoom: float = zoom.x
	
	zoom = new_zoom.clampf(0.01, 5.)
	
	var change: float = zoom.x / last_zoom
	global_position = (cam_pos - mouse_pos) / change + mouse_pos
	reset_smoothing()
