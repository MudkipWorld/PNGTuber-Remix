extends Node2D

func _ready() -> void:
	z_index = 3000
	visible = Global.grid_visible and Global.mode != 1
	queue_redraw()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	var zoom: Vector2 = camera.zoom
	var center: Vector2 = to_local(camera.get_screen_center_position())
	var viewport_size: Vector2 = get_viewport_rect().size / zoom
	var half_size: Vector2 = viewport_size * 0.5 + Vector2(40.0, 40.0)

	var step: float = max(Global.grid_size, 1.0)
	var estimated_lines: float = (viewport_size.x / step) + (viewport_size.y / step)

	while estimated_lines > 700.0:
		step *= 2.0
		estimated_lines = (viewport_size.x / step) + (viewport_size.y / step)

	var min_x: float = floor((center.x - half_size.x) / step) * step
	var max_x: float = ceil((center.x + half_size.x) / step) * step
	var min_y: float = floor((center.y - half_size.y) / step) * step
	var max_y: float = ceil((center.y + half_size.y) / step) * step

	var minor_color := Color(0.7, 0.7, 0.7, 0.16)
	var major_color := Color(0.7, 0.7, 0.7, 0.32)

	var x: float = min_x
	while x <= max_x:
		var is_major: bool = is_zero_approx(fposmod(abs(x), step * 10.0))
		draw_line(Vector2(x, min_y), Vector2(x, max_y), major_color if is_major else minor_color, 1.0)
		x += step

	var y: float = min_y
	while y <= max_y:
		var is_major: bool = is_zero_approx(fposmod(abs(y), step * 10.0))
		draw_line(Vector2(min_x, y), Vector2(max_x, y), major_color if is_major else minor_color, 1.0)
		y += step
