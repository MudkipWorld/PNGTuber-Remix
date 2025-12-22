extends Node2D
class_name CustomMeshOld

@export var texture : Texture2D
@export var actor : Node


@export var editable : bool = false
var selected_vertex : int = -1
var original_vertices : Array = []
var base_vertices : Array = []
var deformed_vertices : Array = []
var triangles : PackedInt32Array = []
var internal_vertices : Array = []

var show_deformed_mesh : bool = true
var deform_top_left: Array = []
var deform_top_middle: Array = []
var deform_top_right: Array = []
var deform_middle_left: Array = []
var deform_center: Array = []
var deform_middle_right: Array = []
var deform_bottom_left: Array = []
var deform_bottom_middle: Array = []
var deform_bottom_right: Array = []
var interpolated_vertices: Array = []

var deform_x : float = 0
var deform_y : float = 0.5

var last_u : float = 0.0
var last_v : float = 0.0
var final : Vector2 = Vector2.ZERO

var _cached_tri_points := PackedVector2Array()
var _cached_tri_uvs := PackedVector2Array()
var _last_vertices_used: Array = []
var _last_tex_size: Vector2 = Vector2.ZERO

func deformations_3x3(u: float, v: float) -> void:
	if deform_top_left.is_empty():
		return
	var n = deform_top_left.size()
	interpolated_vertices.resize(n)
	u = clamp(u, 0.0, 1.0)
	v = clamp(v, 0.0, 1.0)
	var vf = 1.0 - v
	var u_left = clamp(u * 2.0, 0.0, 1.0)
	var u_right = clamp((u - 0.5) * 2.0, 0.0, 1.0)
	var vf_top = clamp(vf * 2.0, 0.0, 1.0)
	var vf_bottom = clamp((vf - 0.5) * 2.0, 0.0, 1.0)
	for i in range(n):
		var tl = deform_top_left[i]
		var tm = deform_top_middle[i]
		var tr = deform_top_right[i]
		var ml = deform_middle_left[i]
		var mc = deform_center[i]
		var mr = deform_middle_right[i]
		var bl = deform_bottom_left[i]
		var bm = deform_bottom_middle[i]
		var br = deform_bottom_right[i]
		var top_row: Vector2
		var mid_row: Vector2
		var bot_row: Vector2
		if u <= 0.5:
			top_row = tl.lerp(tm, u_left)
			mid_row = ml.lerp(mc, u_left)
			bot_row = bl.lerp(bm, u_left)
		else:
			top_row = tm.lerp(tr, u_right)
			mid_row = mc.lerp(mr, u_right)
			bot_row = bm.lerp(br, u_right)
		var final_pos: Vector2
		if vf <= 0.5:
			final_pos = top_row.lerp(mid_row, vf_top)
		else:
			final_pos = mid_row.lerp(bot_row, vf_bottom)
		interpolated_vertices[i] = final_pos
	last_u = u
	last_v = v
	deform_x = u
	deform_y = v
	queue_redraw()

func _draw() -> void:
	if original_vertices.is_empty() or triangles.is_empty() or texture == null:
		return
	var vertices_to_draw: Array
	if not interpolated_vertices.is_empty():
		vertices_to_draw = interpolated_vertices
	elif show_deformed_mesh:
		vertices_to_draw = deformed_vertices
	else:
		vertices_to_draw = original_vertices
	var tex_size = texture.get_size()
	var offset = -tex_size / 2.0
	if vertices_to_draw != _last_vertices_used or tex_size != _last_tex_size:
		_last_vertices_used = vertices_to_draw.duplicate()
		_last_tex_size = tex_size
		_cached_tri_uvs.resize(triangles.size())
		for t_idx in range(triangles.size()):
			var vi = triangles[t_idx]
			_cached_tri_uvs[t_idx] = original_vertices[vi] / tex_size
	_cached_tri_points.resize(3)
	for t_idx in range(0, triangles.size(), 3):
		var ai = triangles[t_idx]
		var bi = triangles[t_idx + 1]
		var ci = triangles[t_idx + 2]
		var a = vertices_to_draw[ai] + offset
		var b = vertices_to_draw[bi] + offset
		var c = vertices_to_draw[ci] + offset
		if not is_triangle_valid(a, b, c):
			continue
		_cached_tri_points[0] = a
		_cached_tri_points[1] = b
		_cached_tri_points[2] = c
		draw_colored_polygon(_cached_tri_points, Color.WHITE, PackedVector2Array([_cached_tri_uvs[t_idx], _cached_tri_uvs[t_idx + 1], _cached_tri_uvs[t_idx + 2]]), texture)

func sync_deformation_arrays() -> void:
	var n = original_vertices.size()
	var deform_arrays = [
		deform_top_left, deform_top_middle, deform_top_right,
		deform_middle_left, deform_center, deform_middle_right,
		deform_bottom_left, deform_bottom_middle, deform_bottom_right
	]

	for arr in deform_arrays:
		while arr.size() < n:
			arr.append(original_vertices[arr.size()])
		while arr.size() > n:
			arr.pop_back()

	if interpolated_vertices.size() != n:
		interpolated_vertices.resize(n)
		for i in range(interpolated_vertices.size()):
			if interpolated_vertices[i] == null:
				interpolated_vertices[i] = original_vertices[i]

func toggle_mesh_view():
	show_deformed_mesh = !show_deformed_mesh
	queue_redraw()

func add_internal_point(p: Vector2) -> void:
	if not is_inside_base(p):
		return
	for v in internal_vertices:
		if v.distance_to(p) < 1.0:
			return

	internal_vertices.append(p)
	original_vertices.append(p)
	deformed_vertices.append(p)
	sync_deformation_arrays()
	triangles = Geometry2D.triangulate_delaunay(original_vertices)
	queue_redraw()

func remove_nearest_internal_point(p: Vector2, max_dist := 12.0) -> bool:
	var best_i := -1
	var best_d := max_dist
	for i in range(internal_vertices.size()):
		var d = internal_vertices[i].distance_to(p)
		if d < best_d:
			best_d = d
			best_i = i
	if best_i == -1:
		return false
	internal_vertices.remove_at(best_i)
	var idx = base_vertices.size() + best_i
	original_vertices.remove_at(idx)
	deformed_vertices.remove_at(idx)
	sync_deformation_arrays()
	triangles = Geometry2D.triangulate_delaunay(original_vertices)
	queue_redraw()
	return true

func is_triangle_valid(a: Vector2, b: Vector2, c: Vector2) -> bool:
	var area = (b - a).cross(c - a) * 0.5
	return abs(area) > 0.001

func is_inside_base(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, base_vertices)

var last_deform_pos := Vector2.ZERO

func apply_wobble_to_deformer(wobble: Vector2, delta: float, amp: Vector2, lerp_speed: float = 0.08) -> Vector2:
	if amp.x == 0 && amp.y == 0:
		return Vector2(0.5, 0.5) 
	var target_pos = Vector2(
		(wobble.x / (2.0 * amp.x)) + 0.5,
		(wobble.y / (2.0 * amp.y)) + 0.5
	)
	last_deform_pos.x = move_toward(last_deform_pos.x, target_pos.x, lerp_speed * delta * 60)
	last_deform_pos.y = move_toward(last_deform_pos.y, target_pos.y, lerp_speed * delta * 60)
	last_deform_pos.x = clamp(last_deform_pos.x, 0.0, 1.0)
	last_deform_pos.y = clamp(last_deform_pos.y, 0.0, 1.0)
	return last_deform_pos
