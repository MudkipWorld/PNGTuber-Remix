extends Node2D

var camera: Camera2D
var last_cam_pos: Vector2 = Vector2(-9999, -9999)
var last_cam_zoom: Vector2 = Vector2(-9999, -9999)
var last_grid_size: float = -1.0
var grid_color : Color = Color(0.85, 0.85, 0.95, 0.15)
var axis_x_color : Color = Color(0.9, 0.3, 0.3, 0.6)
var axis_y_color : Color = Color(0.3, 0.8, 0.3, 0.6)

func _ready() -> void:
	z_index = 3000
	visible = Global.grid_visible and Global.mode != 1
	camera = get_viewport().get_camera_2d()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _process(_delta: float) -> void:
	if !visible: return

	if camera == null:
		camera = get_viewport().get_camera_2d()
		if camera == null: return

	if camera.global_position != last_cam_pos or camera.zoom != last_cam_zoom or Global.grid_size != last_grid_size:
		last_cam_pos = camera.global_position
		last_cam_zoom = camera.zoom
		last_grid_size = Global.grid_size
		queue_redraw()

func _draw() -> void:
	if !is_visible_in_tree() or camera == null: return

	var zoom: Vector2 = camera.zoom
	var center: Vector2 = to_local(camera.get_screen_center_position())
	var viewport_size: Vector2 = get_viewport_rect().size / zoom
	var half_size: Vector2 = viewport_size * 0.5 + Vector2(50.0, 50.0)

	var step: float = max(Global.grid_size, 1.0)
	var estimated_lines: float = (viewport_size.x / step) + (viewport_size.y / step)

	while estimated_lines > 700.0:
		step *= 2.0
		estimated_lines = (viewport_size.x / step) + (viewport_size.y / step)

	var min_x : float = floor((center.x - half_size.x) / step) * step
	var max_x : float = ceil((center.x + half_size.x) / step) * step
	var min_y : float = floor((center.y - half_size.y) / step) * step
	var max_y : float = ceil((center.y + half_size.y) / step) * step
	var line_width: float = 1.0 / zoom.x

	var x: float = min_x
	while x <= max_x:
		var color := grid_color
		var width := line_width
		if is_zero_approx(x):
			color = axis_y_color
			width = line_width * 2.0
		draw_line(Vector2(x, min_y), Vector2(x, max_y), color, width, false)
		x += step

	var y: float = min_y
	while y <= max_y:
		var color : Color = grid_color
		var width : float = line_width
		if is_zero_approx(y):
			color = axis_x_color
			width = line_width * 2.0
		draw_line(Vector2(min_x, y), Vector2(max_x, y), color, width, false)
		y += step
