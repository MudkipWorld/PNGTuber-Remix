extends CustomMesh

@export var parent : Node

func _ready() -> void:
	actor = parent



func add_internal_point_gd(p: Vector2) -> void:
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

func remove_nearest_internal_point_gd(p: Vector2, max_dist := 12.0) -> bool:
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
