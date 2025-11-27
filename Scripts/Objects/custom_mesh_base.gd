extends Node2D
class_name CustomMesh

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


func deformations_3x3(u: float, v: float) -> void:
	sync_deformation_arrays()
	if deform_top_left.is_empty():
		return
	var n = deform_top_left.size()
	interpolated_vertices.resize(n)
	u = clamp(u, 0.0, 1.0)
	var vf = 1.0 - clamp(v, 0.0, 1.0)
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
		var top_row = tl.lerp(tm, u * 2.0) if u <= 0.5 else tm.lerp(tr, (u - 0.5) * 2.0)
		var mid_row = ml.lerp(mc, u * 2.0) if u <= 0.5 else mc.lerp(mr, (u - 0.5) * 2.0)
		var bot_row = bl.lerp(bm, u * 2.0) if u <= 0.5 else bm.lerp(br, (u - 0.5) * 2.0)
		var final_pos = top_row.lerp(mid_row, vf * 2.0) if vf <= 0.5 else mid_row.lerp(bot_row, (vf - 0.5) * 2.0)
		interpolated_vertices[i] = final_pos
	last_u = u
	last_v = v
	deform_x = u
	deform_y = v
	queue_redraw()

func seg_lerp(a, b, c, t):
	return a.lerp(b, t * 2.0) if t <= 0.5 else b.lerp(c, (t - 0.5) * 2.0)

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

func _draw() -> void:
	if original_vertices.is_empty() or triangles.is_empty() or not texture:
		return
	var vertices_to_draw: Array
	if !interpolated_vertices.is_empty():
		vertices_to_draw = interpolated_vertices
	else:
		if show_deformed_mesh:
			vertices_to_draw = deformed_vertices
		else:
			vertices_to_draw = original_vertices
	var tex_size = texture.get_size()
	var offset = -tex_size / 2.0
	for t_idx in range(0, triangles.size(), 3):
		var ai = triangles[t_idx]
		var bi = triangles[t_idx + 1]
		var ci = triangles[t_idx + 2]
		var a = vertices_to_draw[ai] + offset
		var b = vertices_to_draw[bi] + offset
		var c = vertices_to_draw[ci] + offset

		if not is_triangle_valid(a, b, c):
			draw_polygon(PackedVector2Array([a, b, c]), [Color(1, 0, 0, 0.5)])
			continue
		var tri_uvs = PackedVector2Array([
			original_vertices[ai] / tex_size,
			original_vertices[bi] / tex_size,
			original_vertices[ci] / tex_size
		])
		draw_colored_polygon(PackedVector2Array([a, b, c]), Color.WHITE, tri_uvs, texture)

func is_triangle_valid(a: Vector2, b: Vector2, c: Vector2) -> bool:
	var area = (b - a).cross(c - a) * 0.5
	return abs(area) > 0.001

func is_inside_base(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, base_vertices)


func apply_wobble_to_deformer(deform_pos: Vector2, wobble: Vector2, max_offset: Vector2) -> Vector2:
	var u_min = max(deform_pos.x - max_offset.x, 0.0)
	var u_max = min(deform_pos.x + max_offset.x, 1.0)
	var v_min = max(deform_pos.y - max_offset.y, 0.0)
	var v_max = min(deform_pos.y + max_offset.y, 1.0)

	var new_u = clamp(deform_pos.x + wobble.x, u_min, u_max)
	var new_v = clamp(deform_pos.y + wobble.y, v_min, v_max)
	return Vector2(new_u, new_v)
