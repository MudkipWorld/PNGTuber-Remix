extends Node2D
class_name MeshGroupsPreview

@export var show_warp_points : bool = true
@export var show_glue_points : bool = true
@export var show_glue_lines : bool = true
@export var warp_point_radius : float = 6.0
@export var glue_point_radius : float = 4.0
@export var glue_line_width : float = 2.0
@export var warp_color : Color = Color(1.0, 0.6, 0.2, 1.0)
@export var glue_color : Color = Color(0.2, 0.8, 1.0, 1.0)

var dragging_warp : DeformLayer = null
var drag_offset : Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	queue_redraw()

var last_drag_pos : Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if MeshEditor.editor_mode != MeshEditor.EditorMode.WARP:
		return

	var mouse_pos = get_local_mouse_position()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				for warp in CustomMesh.get_warp_groups():
					if is_mouse_over_warp(mouse_pos, warp):
						dragging_warp = warp
						drag_offset =  mouse_pos
						break
			else:
				dragging_warp = null

	elif event is InputEventMouseMotion and dragging_warp != null:
		deform_global_layer(dragging_warp, event.relative)


func deform_global_layer(layer: DeformLayer, drag: Vector2):
	if layer == null:
		return

	var all_grids = [
		"top_left", "top_middle", "top_right",
		"middle_left", "center", "middle_right",
		"bottom_left", "bottom_middle", "bottom_right"
	]
	for grid_name in all_grids:
		var points = layer.get(grid_name)
		if points.is_empty():
			continue
		var origin_pos = points[0]
		for i in range(points.size()):
			var dist = points[i].distance_to(origin_pos)
			if dist > MeshEditor.influence_radius:
				continue
			var influence = pow(1.0 - dist / MeshEditor.influence_radius, 2.0) * MeshEditor.influence_strength
			match MeshEditor.brush_type:
				0:
					points[i] += drag * influence
				1:
					var offset = points[i] - origin_pos
					offset = offset.rotated(drag.length() * 0.005 * influence)
					points[i] += offset - (points[i] - origin_pos)
				2:
					var offset = points[i] - origin_pos
					offset = offset.rotated(-drag.length() * 0.005 * influence)
					points[i] += offset - (points[i] - origin_pos)
				3:
					var dir = (points[i] - origin_pos).normalized()
					points[i] += dir * influence
				4:
					var dir = (points[i] - origin_pos).normalized()
					points[i] += -dir * influence
				5:
					points[i] += (layer.origin - points[i]) * influence * 0.25
		layer.set(grid_name, points)



func is_mouse_over_warp(mouse_pos: Vector2, warp: DeformLayer) -> bool:
	var meshes := []
	for sprite in Global.held_sprites:
		if sprite != null and is_instance_valid(sprite) and sprite.sprite_type == "Mesh":
			var mesh: CustomMesh = sprite.mesh
			if mesh != null and is_instance_valid(mesh):
				if warp.id in mesh.warps:
					meshes.append(mesh)
	if meshes.is_empty():
		return false

	var combined_min := Vector2(INF, INF)
	var combined_max := Vector2(-INF, -INF)
	for mesh in meshes:
		if mesh.interpolated_vertices.is_empty():
			continue
		var offset = -mesh.texture.get_size() * 0.5 if mesh.texture else Vector2.ZERO
		for v in mesh.interpolated_vertices:
			var vv = v + offset
			combined_min.x = min(combined_min.x, vv.x)
			combined_min.y = min(combined_min.y, vv.y)
			combined_max.x = max(combined_max.x, vv.x)
			combined_max.y = max(combined_max.y, vv.y)

	var rect_size = combined_max - combined_min
	var top_left = combined_min
	return Rect2(top_left, rect_size).has_point(mouse_pos)


func warp_rect( warp: DeformLayer) -> Rect2:
	var meshes := []
	for sprite in Global.held_sprites:
		if sprite != null and is_instance_valid(sprite) and sprite.sprite_type == "Mesh":
			var mesh: CustomMesh = sprite.mesh
			if mesh != null and is_instance_valid(mesh):
				if warp.id in mesh.warps:
					meshes.append(mesh)
	if meshes.is_empty():
		Rect2(Vector2.ZERO, Vector2.ONE)

	var combined_min := Vector2(INF, INF)
	var combined_max := Vector2(-INF, -INF)
	for mesh in meshes:
		if mesh.interpolated_vertices.is_empty():
			continue
		var offset = -mesh.texture.get_size() * 0.5 if mesh.texture else Vector2.ZERO
		for v in mesh.interpolated_vertices:
			var vv = v + offset
			combined_min.x = min(combined_min.x, vv.x)
			combined_min.y = min(combined_min.y, vv.y)
			combined_max.x = max(combined_max.x, vv.x)
			combined_max.y = max(combined_max.y, vv.y)

	var rect_size = combined_max - combined_min
	var top_left = combined_min
	return Rect2(top_left, rect_size)


func _process(_delta: float) -> void:
	if Global.held_sprites.is_empty():
		return
	queue_redraw()


func _draw() -> void:
	if MeshEditor.editor_mode != MeshEditor.EditorMode.WARP:
		return
	if MeshEditor.active_warp == null:
		return

	var layer = MeshEditor.active_warp
	var color = warp_color

	# Draw bounding rect
	draw_rect(warp_rect(layer), color, false, 2.0)

	# Prepare row-major grid points
	var rows = [
		["top_left", "top_middle", "top_right"],
		["middle_left", "center", "middle_right"],
		["bottom_left", "bottom_middle", "bottom_right"]
	]

	# Flatten points
	var points := []
	for row in rows:
		var row_points := []
		for _name in row:
			var arr = layer.get(_name)
			if arr.is_empty():
				# Fallback: use center
				arr = PackedVector2Array([Vector2.ZERO])
			row_points.append(arr[0])
		points.append(row_points)

	# Draw points
	for row in points:
		for p in row:
			draw_circle(p, warp_point_radius, color)

	# Draw lines between points in the grid
	for i in range(3):
		for j in range(3):
			var p = points[i][j]
			# Horizontal
			if j < 2:
				draw_line(p, points[i][j + 1], color, 1.0)
			# Vertical
			if i < 2:
				draw_line(p, points[i + 1][j], color, 1.0)
