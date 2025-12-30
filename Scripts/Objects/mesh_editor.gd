extends Node2D
class_name MeshEditor

@export var mesh : CustomMesh = null
@export var actor : SpriteObject
static var draw_internal_web : bool = true
static var influence_radius : float = 150.0
static var influence_strength : float = 1.0
static var ring_grid : bool = false
static var square_grid : bool = false
static var radial_hex : bool = false
static var tri_grid : bool = false
static var grid_size : float = 50
static var radial_spacing : float = 35
static var threshold = 0.1
static var internal_point_count : int = 50
static var eplision : float = 1
static var merge_close : float = 25
static var flip_x: bool = false
static var flip_y: bool = false
static var outer_padding: bool = false
static var padding : float = 4
var dragging : bool = false
var deformed_layer : PackedVector2Array = []


func regenerate_mesh():
	if mesh == null or not is_instance_valid(mesh):
		push_error("Mesh is null or invalid!")
		return

	if not mesh.texture:
		push_error("Please assign a texture!")
		return

	for i in mesh.get_layer_count():
		mesh.remove_deform_layer(i)
	_generate_mesh_from_texture(mesh.texture)
	mesh.deformed_vertices = mesh.original_vertices.duplicate()
	if mesh.get_layer_count() == 0:
		for i in 2:
			add_layer()
	queue_redraw()
	mesh.queue_redraw()

func add_layer():
	var new_layer = mesh.get_layer_count()
	mesh.add_deform_layer()
	var layer = mesh.get_layer(new_layer) 

	var zero := PackedVector2Array()
	zero.resize(mesh.original_vertices.size())
	for i in range(zero.size()):
		zero[i] = Vector2.ZERO

	layer.top_left = zero.duplicate()
	layer.top_middle = zero.duplicate()
	layer.top_right = zero.duplicate()
	layer.middle_left = zero.duplicate()
	layer.center = zero.duplicate()
	layer.middle_right = zero.duplicate()
	layer.bottom_left = zero.duplicate()
	layer.bottom_middle = zero.duplicate()
	layer.bottom_right = zero.duplicate()
	deformed_layer = zero.duplicate()
	mesh.sync_deformation_arrays()
	queue_redraw()
	mesh.queue_redraw()

func _draw():
	if !draw_internal_web or ! mesh.editable:
		return
	if mesh == null or not is_instance_valid(mesh):
		return

	if mesh.original_vertices.is_empty() or mesh.triangles.is_empty() or mesh.texture == null:
		return


	var vertices_to_draw: PackedVector2Array

	if mesh.show_deformed_mesh:
		vertices_to_draw =  mesh.interpolated_vertices
	else:
		vertices_to_draw = mesh.original_vertices

	var base_count = mesh.base_vertices.size()
	var offset = -mesh.texture.get_size() / 2.0

	if draw_internal_web:
		var drawn_edges = {}
		for t_idx in range(0, mesh.triangles.size(), 3):
			var a = mesh.triangles[t_idx]
			var b = mesh.triangles[t_idx + 1]
			var c = mesh.triangles[t_idx + 2]

			var edges = [[a, b], [b, c], [c, a]]
			for e in edges:
				var i = e[0]
				var j = e[1]

				if i < base_count and j < base_count:
					continue

				var low = min(i, j)
				var high = max(i, j)
				var key = str(low) + "_" + str(high)
				if drawn_edges.has(key):
					continue
				drawn_edges[key] = true
				draw_line(vertices_to_draw[i] + offset, vertices_to_draw[j] + offset, Color(0.7,0.7,0.7,0.8), 1.0)

	for i in range(base_count):
		var v = vertices_to_draw[i] + offset
		draw_circle(v, 2.0, Color(0, 0.8, 0))

	for i in range(base_count):
		var a = vertices_to_draw[i] + offset
		var b = vertices_to_draw[(i + 1) % base_count] + offset
		draw_line(a, b, Color(1,1,1,0.35), 2.0)

	for i in range(base_count, vertices_to_draw.size()):
		var v = vertices_to_draw[i] + offset
		draw_circle(v, 2.0, Color(1,0,0))

func _input(event):
	if mesh == null or not is_instance_valid(mesh):
		return

	if mesh.editable:
		var mouse_pos = mesh.get_local_mouse_position()
		
		if Input.is_action_pressed("lmb"):
			mesh.selected_vertex = -1
			var closest_dist = influence_radius
			for i in range(mesh.interpolated_vertices.size()):
				var vert_pos = mesh.interpolated_vertices[i] - mesh.texture.get_size() / 2
				var d = vert_pos.distance_to(mouse_pos)
				if d < closest_dist:
					closest_dist = d
					mesh.selected_vertex = i

		elif Input.is_action_just_released("lmb") && dragging:
			save_deformation_3x3(deformed_layer.duplicate())
			mesh.selected_vertex = -1
			dragging = false

		if event is InputEventMouseMotion:
			if mesh.selected_vertex != -1 and Input.is_action_pressed("lmb"):
				dragging = true
				deform_vertex(mesh.selected_vertex, event.relative)

func toggle_mesh_view():
	if mesh == null  or !is_instance_valid(mesh):
		return
	mesh.show_deformed_mesh = !mesh.show_deformed_mesh
	queue_redraw()

func save_deformation_3x3(_delta):
	if mesh == null or !is_instance_valid(mesh):
		return

	if mesh.get_layer_count() < Global.selected_mesh_inx:
		return

	if mesh.get_layer_count() <= 0:
		add_layer() 
	
	var layer = mesh.get_layer(Global.selected_mesh_inx) 
	if mesh.deform_x == 0 && mesh.deform_y == 1:
		var delta = _make_delta(layer.top_left,_delta)
		layer.top_left = delta
	elif mesh.deform_x == 0.5 && mesh.deform_y == 1:
		var delta = _make_delta(layer.top_middle,_delta)
		layer.top_middle = delta
	elif mesh.deform_x == 1 && mesh.deform_y == 1:
		var delta = _make_delta(layer.top_right,_delta)
		layer.top_right = delta
	elif mesh.deform_x == 0 && mesh.deform_y == 0.5:
		var delta = _make_delta(layer.middle_left,_delta)
		layer.middle_left = delta
	elif mesh.deform_x == 0.5 && mesh.deform_y == 0.5:
		var delta = _make_delta(layer.center,_delta)
		layer.center = delta
	elif mesh.deform_x == 1 && mesh.deform_y == 0.5:
		var delta = _make_delta(layer.middle_right,_delta)
		layer.middle_right = delta
	elif mesh.deform_x == 0 && mesh.deform_y == 0:
		var delta = _make_delta(layer.bottom_left,_delta)
		layer.bottom_left = delta
	elif mesh.deform_x == 0.5 && mesh.deform_y == 0:
		var delta = _make_delta(layer.bottom_middle,_delta)
		layer.bottom_middle = delta
	elif mesh.deform_x == 1 && mesh.deform_y == 0:
		var delta = _make_delta(layer.bottom_right,_delta)
		layer.bottom_right = delta
		
	var zero := PackedVector2Array()
	zero.resize(mesh.original_vertices.size())
	for i in range(zero.size()):
		zero[i] = Vector2.ZERO
	deformed_layer = zero.duplicate()

func reset_point():
	if mesh == null  or !is_instance_valid(mesh):
		return
	
	var zero := PackedVector2Array()
	zero.resize(mesh.original_vertices.size())
	for i in range(zero.size()):
		zero[i] = Vector2.ZERO
	
	if mesh.get_layer_count() < Global.selected_mesh_inx:
		return
		
	var layer = mesh.get_layer(Global.selected_mesh_inx) 
	if mesh.deform_x == 0 && mesh.deform_y == 1:
		layer.top_left = zero.duplicate()
	elif mesh.deform_x == 0.5 && mesh.deform_y == 1:
		layer.top_middle = zero.duplicate()
	elif mesh.deform_x == 1 && mesh.deform_y == 1:
		layer.top_right = zero.duplicate()
	elif mesh.deform_x == 0 && mesh.deform_y == 0.5:
		layer.middle_left = zero.duplicate()
	elif mesh.deform_x == 0.5 && mesh.deform_y == 0.5:
		layer.center = zero.duplicate()
	elif mesh.deform_x == 1 && mesh.deform_y == 0.5:
		layer.middle_right = zero.duplicate()
	elif mesh.deform_x == 0 && mesh.deform_y == 0:
		layer.bottom_left = zero.duplicate()
	elif mesh.deform_x == 0.5 && mesh.deform_y == 0:
		layer.bottom_middle = zero.duplicate()
	elif mesh.deform_x == 1 && mesh.deform_y == 0:
		layer.bottom_right = zero.duplicate()
	mesh.sync_deformation_arrays()

	queue_redraw()

func is_triangle_valid(a: Vector2, b: Vector2, c: Vector2) -> bool:
	var area = (b - a).cross(c - a) * 0.5
	return abs(area) > 0.001

func deform_vertex(index: int, drag: Vector2):
	if mesh == null or index < 0:
		return
	var vertices_ref: PackedVector2Array
	if mesh.interpolated_vertices.is_empty():
		vertices_ref = mesh.deformed_vertices.duplicate()
	else:
		vertices_ref = mesh.interpolated_vertices.duplicate()

	if index >= vertices_ref.size():
		return
	var origin_pos = vertices_ref[index]
	for i in range(vertices_ref.size()):
		var dist = vertices_ref[i].distance_to(origin_pos)
		if dist > influence_radius:
			continue
		var influence = pow(1.0 - dist / influence_radius, 2.0) * influence_strength

		vertices_ref[i] += drag * influence
		deformed_layer[i] += drag * influence
	mesh.interpolated_vertices = vertices_ref.duplicate()
	mesh.deformed_vertices =  vertices_ref.duplicate()
	
	mesh.queue_redraw()
	queue_redraw()

func smooth_and_even_poly(poly: Array, iterations: int, spacing: float = 5) -> Array:
	if mesh == null  or !is_instance_valid(mesh):
		return []
	for i in range(iterations):
		var new_poly: Array = []
		for j in range(poly.size()):
			var p0 = poly[j]
			var p1 = poly[(j + 1) % poly.size()]
			new_poly.append(p0.lerp(p1, 0.25))
			new_poly.append(p0.lerp(p1, 0.75))
		poly = new_poly

	var evenly_spaced: Array = []
	for i in range(poly.size()):
		var start_point = poly[i]
		var end_point = poly[(i + 1) % poly.size()]
		var edge_vector = end_point - start_point
		var edge_length = edge_vector.length()
		if edge_length == 0:
			continue
		var segments = max(1, int(round(edge_length / spacing)))
		for s in range(segments):
			var t = float(s) / float(segments)
			evenly_spaced.append(start_point.lerp(end_point, t))
	return evenly_spaced

func merge_close_points(points: PackedVector2Array, min_dist: float = 10.0) -> PackedVector2Array:
	if mesh == null  or !is_instance_valid(mesh):
		return []
	if points.size() < 2:
		return points.duplicate()
	var merged := PackedVector2Array()
	merged.append(points[0])
	for i in range(1, points.size()):
		var prev = merged[merged.size() - 1]
		var curr = points[i]
		if prev.distance_to(curr) < min_dist:
			continue
		merged.append(curr)
	return merged

func generate_internal_points_grid(polygon: Array) -> Array:
	if mesh == null  or !is_instance_valid(mesh):
		return []
	var points = []
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for v in polygon:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)
	var x = min_x + grid_size * 0.5
	while x <= max_x:
		var y = min_y + grid_size * 0.5
		while y <= max_y:
			var p = Vector2(x, y)
			if Geometry2D.is_point_in_polygon(p, polygon):
				points.append(p)
			y += grid_size
		x += grid_size
	return points

func generate_internal_points_rings_grid(polygon: Array) -> Array:
	if mesh == null  or !is_instance_valid(mesh):
		return []
	var points = []
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for v in polygon:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)

	var center = Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	var max_radius = max(center.distance_to(Vector2(min_x, min_y)),
						 center.distance_to(Vector2(min_x, max_y)),
						 center.distance_to(Vector2(max_x, min_y)),
						 center.distance_to(Vector2(max_x, max_y)))
	var r = radial_spacing
	while r <= max_radius:
		for angle in range(0, 360, internal_point_count):
			var rad = deg_to_rad(angle)
			var p = center + Vector2(cos(rad), sin(rad)) * r
			if Geometry2D.is_point_in_polygon(p, polygon):
				points.append(p)
		r += radial_spacing
	if Geometry2D.is_point_in_polygon(center, polygon):
		points.append(center)
	return points

func generate_internal_points_triangular_grid(polygon: Array) -> Array:
	var points = []
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for v in polygon:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)
	var row_offset = 0.0
	var y = min_y + grid_size * 0.5
	while y <= max_y:
		var x = min_x + row_offset
		while x <= max_x:
			var p = Vector2(x, y)
			if Geometry2D.is_point_in_polygon(p, polygon):
				points.append(p)
			x += grid_size
		row_offset = grid_size * 0.5 - row_offset 
		y += grid_size * 0.866 
	return points

func generate_internal_points_radial_hex(polygon: Array) -> Array:
	if mesh == null or !is_instance_valid(mesh):
		return []
	var points: Array = []
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for v in polygon:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)
	var center = Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	var hex_radius = radial_spacing
	var sqrt3 = sqrt(3)
	var r = 0.0

	while r <= max(max_x - min_x, max_y - min_y):
		var ring_count = int(round(2.0 * PI * r / (hex_radius * sqrt3)))
		if ring_count == 0:
			if Geometry2D.is_point_in_polygon(center, polygon):
				points.append(center)
			r += hex_radius
			continue

		for i in range(ring_count):
			var angle = i * 2.0 * PI / ring_count
			var p = center + Vector2(cos(angle), sin(angle)) * r
			if Geometry2D.is_point_in_polygon(p, polygon):
				points.append(p)
		r += hex_radius * 0.866 
	
	return points

func add_outer_padding(poly: Array) -> Array:
	if padding <= 0:
		return poly.duplicate()

	var padded_poly = []
	var n = poly.size()
	for i in range(n):
		var prev = poly[(i - 1 + n) % n]
		var curr = poly[i]
		var next = poly[(i + 1) % n]

		# Edge directions
		var dir1 = (curr - prev).normalized()
		var dir2 = (next - curr).normalized()

		# Normals (perpendicular vectors)
		var n1 = Vector2(-dir1.y, dir1.x)
		var n2 = Vector2(-dir2.y, dir2.x)

		# Average normal
		var normal = (n1 + n2).normalized()
		padded_poly.append(curr + normal * padding)
	
	return padded_poly

func _generate_mesh_from_texture(tex: Texture2D) -> void:
	if mesh == null  or !is_instance_valid(mesh):
		return
	var img: Image = tex.get_image()
	var w = img.get_width()
	var h = img.get_height()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(img, threshold)
	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, Vector2(w, h)), eplision)
	if polys.is_empty():
		push_error("No polygons generated!")
		return
	var base_vertices: Array = []
	for poly in polys:
		var smoothed = smooth_and_even_poly(poly, 2)
		smoothed = merge_close_points(smoothed, merge_close)
		if outer_padding:
			smoothed = add_outer_padding(smoothed)
		base_vertices.append_array(smoothed)
	if polys.size() > 1:
		for i in range(polys.size()):
			for j in range(i + 1, polys.size()):
				var poly_a = polys[i]
				var poly_b = polys[j]
				var min_dist = INF
				var _closest_pair = null
				for va in poly_a:
					for vb in poly_b:
						var d = va.distance_to(vb)
						if d < min_dist:
							min_dist = d
							_closest_pair = [va, vb]
	mesh.base_vertices = base_vertices.duplicate()
	mesh.internal_vertices = []
	if ring_grid:
		var arr = mesh.internal_vertices.duplicate()
		arr.append_array(generate_internal_points_rings_grid(mesh.base_vertices))
		mesh.internal_vertices = arr 
	if square_grid:
		var arr = mesh.internal_vertices.duplicate() 
		arr.append_array(generate_internal_points_grid(mesh.base_vertices))
		mesh.internal_vertices = arr 
	if tri_grid:
		var arr = mesh.internal_vertices.duplicate() 
		arr.append_array(generate_internal_points_triangular_grid(mesh.base_vertices))
		mesh.internal_vertices = arr 
		
	if radial_hex:
		var arr = mesh.internal_vertices.duplicate() 
		arr.append_array(generate_internal_points_radial_hex(mesh.base_vertices))
		mesh.internal_vertices = arr 
	
	var all_vertices = mesh.base_vertices.duplicate()
	all_vertices += mesh.internal_vertices.duplicate()
	mesh.original_vertices = all_vertices
	mesh.deformed_vertices = []
	mesh.triangles = Geometry2D.triangulate_delaunay(mesh.original_vertices)

func reinforce_mesh_from_existing(_mesh: CustomMesh = mesh) -> void:
	if mesh == null or !is_instance_valid(mesh):
		push_error("Mesh is null or invalid!")
		return
	if mesh.original_vertices.is_empty():
		push_error("Mesh has no original vertices!")
		return

	# Ensure base_vertices exist
	if mesh.base_vertices.is_empty():
		mesh.base_vertices = mesh.original_vertices.duplicate()

	# Internal vertices
	if mesh.internal_vertices.is_empty():
		if ring_grid:
			mesh.internal_vertices.append_array(generate_internal_points_rings_grid(mesh.base_vertices))
		if square_grid:
			mesh.internal_vertices.append_array(generate_internal_points_grid(mesh.base_vertices))

	# Rebuild all_vertices
	var all_vertices = mesh.base_vertices.duplicate()
	all_vertices += mesh.internal_vertices.duplicate()
	# Also include original vertices if somehow missing
	for v in mesh.original_vertices:
		if v not in all_vertices:
			all_vertices.append(v)

	mesh.original_vertices = all_vertices
	mesh.deformed_vertices = all_vertices.duplicate()
	mesh.interpolated_vertices.clear()

	# Rebuild triangles
	if mesh.triangles.is_empty():
		mesh.triangles = Geometry2D.triangulate_delaunay(mesh.original_vertices)
	else:
		# Filter out invalid triangles
		var valid_tris: PackedInt32Array = PackedInt32Array()
		for i in range(0, mesh.triangles.size(), 3):
			var a = mesh.triangles[i]
			var b = mesh.triangles[i+1]
			var c = mesh.triangles[i+2]
			if a < mesh.original_vertices.size() and b < mesh.original_vertices.size() and c < mesh.original_vertices.size():
				valid_tris.append_array([a, b, c])
		mesh.triangles = valid_tris

	# Rebuild 3x3 deformation grids if missing
	if mesh.deform_top_left.is_empty(): mesh.deform_top_left = mesh.deformed_vertices.duplicate()
	if mesh.deform_top_middle.is_empty(): mesh.deform_top_middle = mesh.deformed_vertices.duplicate()
	if mesh.deform_top_right.is_empty(): mesh.deform_top_right = mesh.deformed_vertices.duplicate()
	if mesh.deform_middle_left.is_empty(): mesh.deform_middle_left = mesh.deformed_vertices.duplicate()
	if mesh.deform_center.is_empty(): mesh.deform_center = mesh.deformed_vertices.duplicate()
	if mesh.deform_middle_right.is_empty(): mesh.deform_middle_right = mesh.deformed_vertices.duplicate()
	if mesh.deform_bottom_left.is_empty(): mesh.deform_bottom_left = mesh.deformed_vertices.duplicate()
	if mesh.deform_bottom_middle.is_empty(): mesh.deform_bottom_middle = mesh.deformed_vertices.duplicate()
	if mesh.deform_bottom_right.is_empty(): mesh.deform_bottom_right = mesh.deformed_vertices.duplicate()

	mesh.sync_deformation_arrays()
	mesh.queue_redraw()

func create_mirrored_mesh(to_right: bool = true) -> void:
	if mesh == null or !is_instance_valid(mesh):
		return
	if mesh.original_vertices.is_empty():
		return

	var mesh_obj = load("res://Misc/MeshObject/mesh_object.tscn") as PackedScene
	var sprte_obj = mesh_obj.instantiate()
	Global.sprite_container.add_child(sprte_obj)
	sprte_obj.sprite_type = "Mesh"
	sprte_obj.sprite_name = str("Mesh")

	# Duplicate states
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		sprte_obj.states.append({})

	# Compute bounding box for mirroring
	var min_x = INF
	var max_x = -INF
	for v in sprte_obj.mesh.original_vertices:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
	var mirror_x = (min_x + max_x) * 0.5

	sprte_obj.mesh.original_vertices = flip_side(mesh.original_vertices, mirror_x)
	sprte_obj.mesh.deformed_vertices = flip_side(mesh.deformed_vertices, mirror_x)
	sprte_obj.mesh.base_vertices = flip_side(mesh.base_vertices, mirror_x)
	sprte_obj.mesh.internal_vertices = flip_side(mesh.internal_vertices, mirror_x)

	sprte_obj.mesh.deform_top_left = flip_side(mesh.deform_top_left, mirror_x)
	sprte_obj.mesh.deform_top_middle = flip_side(mesh.deform_top_middle, mirror_x)
	sprte_obj.mesh.deform_top_right = flip_side(mesh.deform_top_right, mirror_x)
	sprte_obj.mesh.deform_middle_left = flip_side(mesh.deform_middle_left, mirror_x)
	sprte_obj.mesh.deform_center = flip_side(mesh.deform_center, mirror_x)
	sprte_obj.mesh.deform_middle_right = flip_side(mesh.deform_middle_right, mirror_x)
	sprte_obj.mesh.deform_bottom_left = flip_side(mesh.deform_bottom_left, mirror_x)
	sprte_obj.mesh.deform_bottom_middle = flip_side(mesh.deform_bottom_middle, mirror_x)
	sprte_obj.mesh.deform_bottom_right = flip_side(mesh.deform_bottom_right, mirror_x)

	sprte_obj.mesh.interpolated_vertices = flip_side(mesh.interpolated_vertices, mirror_x)

	sprte_obj.sprite_id = sprte_obj.get_instance_id()
	sprte_obj.parent_id = mesh.actor.parent_id
	Global.update_layers.emit(0, sprte_obj, "Mesh")
	
	sprte_obj.flipped_h = to_right
	sprte_obj.mesh.texture = ImageTextureLoaderManager.check_flips(mesh.actor.referenced_data.runtime_texture, sprte_obj)
	sprte_obj.mesh.sync_deformation_arrays()
	sprte_obj.mesh.queue_redraw()

func flip_side(arr: PackedVector2Array, mirror_x: float) -> PackedVector2Array:
	var flipped := PackedVector2Array()
	for v in arr:
		flipped.append(Vector2(mirror_x + (mirror_x - v.x), v.y))
	return flipped

func regenerate_preserve_deformation():
	if mesh == null or !is_instance_valid(mesh):
		return
	if mesh.texture == null:
		return
	if mesh.original_vertices.is_empty():
		return

	var old_original = mesh.original_vertices.duplicate()
	var old_deformed = mesh.deformed_vertices.duplicate()
	var old_triangles = mesh.triangles.duplicate()

	var base_vertices = mesh.base_vertices.duplicate()

	var new_internal := PackedVector2Array()
	if ring_grid:
		new_internal.append_array(generate_internal_points_rings_grid(base_vertices))
	if square_grid:
		new_internal.append_array(generate_internal_points_grid(base_vertices))
	if tri_grid:
		new_internal.append_array(generate_internal_points_triangular_grid(base_vertices))
	if radial_hex:
		new_internal.append_array(generate_internal_points_radial_hex(base_vertices))

	var padding_vertices := PackedVector2Array()
	if outer_padding and padding > 0:
		padding_vertices = add_outer_padding(base_vertices)

	var new_all := base_vertices.duplicate()
	new_all += new_internal.duplicate()
	new_all += padding_vertices.duplicate()
	new_all = _unique_vector2_array(new_all, padding * 0.5)

	var new_deformed := PackedVector2Array()
	for p in new_all:
		var mapped := false
		var idx = _find_vector_index_approx(old_original, p, padding * 0.25)
		if idx >= 0:
			new_deformed.append(old_deformed[idx])
			continue
		for i in range(0, old_triangles.size(), 3):
			var a_i = old_triangles[i]; var b_i = old_triangles[i+1]; var c_i = old_triangles[i+2]
			if a_i >= old_original.size() or b_i >= old_original.size() or c_i >= old_original.size():
				continue
			var a = old_original[a_i]; var b = old_original[b_i]; var c = old_original[c_i]
			if _point_in_triangle(p, a, b, c):
				var w = _barycentric_weights(p, a, b, c)
				w.x = clamp(w.x, 0, 1); w.y = clamp(w.y, 0, 1); w.z = clamp(w.z, 0, 1)
				var da = old_deformed[a_i]; var db = old_deformed[b_i]; var dc = old_deformed[c_i]
				new_deformed.append(da * w.x + db * w.y + dc * w.z)
				mapped = true
				break
		if mapped:
			continue
		var nearest_idx = _find_nearest_index(old_original, p)
		if nearest_idx >= 0:
			new_deformed.append(old_deformed[nearest_idx] * 0.9 + p * 0.1)
		else:
			new_deformed.append(p)

	mesh.base_vertices = base_vertices
	mesh.internal_vertices = new_internal.duplicate()
	mesh.original_vertices = new_all
	mesh.deformed_vertices = new_deformed
	mesh.interpolated_vertices.clear()
	mesh.triangles = Geometry2D.triangulate_delaunay(mesh.original_vertices)

	var deform_names = [
		"deform_top_left","deform_top_middle","deform_top_right",
		"deform_middle_left","deform_center","deform_middle_right",
		"deform_bottom_left","deform_bottom_middle","deform_bottom_right"
	]
	for def_name in deform_names:
		if not mesh.get(def_name):
			continue
		var arr = mesh.get(def_name)
		if arr is Array or arr is PackedVector2Array:
			var padded_arr = arr.duplicate()
			if outer_padding and padding > 0:
				padded_arr += PackedVector2Array(add_outer_padding(arr) )
			mesh.set(def_name, _remap_deformation_array(
				padded_arr,
				old_original,
				old_deformed,
				old_triangles,
				mesh.original_vertices,
				padding
			))

	mesh.sync_deformation_arrays()
	mesh.queue_redraw()
	queue_redraw()

func _unique_vector2_array(arr: Array, tol: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in arr:
		if _find_vector_index_approx(out, v, tol) == -1:
			out.append(v)
	return out

func _find_vector_index_approx(arr, vec: Vector2, tol: float) -> int:
	for i in range(arr.size()):
		if arr[i].distance_to(vec) <= tol:
			return i
	return -1

func _find_nearest_index(arr, vec: Vector2) -> int:
	var best = -1
	var bestd = INF
	for i in range(arr.size()):
		var d = arr[i].distance_to(vec)
		if d < bestd:
			bestd = d
			best = i
	return best

func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 = c - a
	var v1 = b - a
	var v2 = p - a
	var dot00 = v0.dot(v0)
	var dot01 = v0.dot(v1)
	var dot02 = v0.dot(v2)
	var dot11 = v1.dot(v1)
	var dot12 = v1.dot(v2)
	var denom = dot00 * dot11 - dot01 * dot01
	if abs(denom) < 0.0000001:
		return false
	var u = (dot11 * dot02 - dot01 * dot12) / denom
	var v = (dot00 * dot12 - dot01 * dot02) / denom
	return u >= -0.000001 and v >= -0.000001 and (u + v) <= 1.000001

func _barycentric_weights(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> Vector3:
	var v0 = b - a
	var v1 = c - a
	var v2 = p - a
	var d00 = v0.dot(v0)
	var d01 = v0.dot(v1)
	var d11 = v1.dot(v1)
	var d20 = v2.dot(v0)
	var d21 = v2.dot(v1)
	var denom = d00 * d11 - d01 * d01
	if abs(denom) < 1e-12:
		return Vector3(1, 0, 0)
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	return Vector3(u, v, w)

func _remap_deformation_array(deform_arr, old_orig, _old_deformed, old_triangles, new_originals, tol):
	var new_out : PackedVector2Array = PackedVector2Array()
	for p in new_originals:
		var exact_idx = _find_vector_index_approx(old_orig, p, tol)
		if exact_idx >= 0:
			new_out.append(deform_arr[exact_idx])
			continue
		var mapped = false
		for i in range(0, old_triangles.size(), 3):
			var a_i = old_triangles[i]; var b_i = old_triangles[i+1]; var c_i = old_triangles[i+2]
			if a_i >= old_orig.size() or b_i >= old_orig.size() or c_i >= old_orig.size():
				continue
			var a = old_orig[a_i]; var b = old_orig[b_i]; var c = old_orig[c_i]
			if _point_in_triangle(p, a, b, c):
				var w = _barycentric_weights(p, a, b, c)
				var da = deform_arr[a_i]; var db = deform_arr[b_i]; var dc = deform_arr[c_i]
				new_out.append(da * w.x + db * w.y + dc * w.z)
				mapped = true
				break
		if mapped:
			continue
		var nearest_idx = _find_nearest_index(old_orig, p)
		if nearest_idx >= 0:
			new_out.append(deform_arr[nearest_idx])
		else:
			new_out.append(p)
	return new_out

func generate_corner(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var result : PackedVector2Array = PackedVector2Array()
	var size_a : int = a.size()
	result.resize(size_a)
	for i in size_a:
		result[i] = (a[i] + b[i]) * 0.5
	return result

func auto_gen_corners():
	if mesh.get_layer_count() < Global.selected_mesh_inx:
		return

	var layer : DeformLayer = mesh.get_layer(Global.selected_mesh_inx)
	if layer != null && is_instance_valid(layer):
		var top_left_corner = generate_corner(layer.top_middle, layer.middle_left)
		var top_right_corner = generate_corner(layer.top_middle, layer.middle_right)
		var bottom_left_corner = generate_corner(layer.bottom_middle, layer.middle_left)
		var bottom_right_corner = generate_corner(layer.bottom_middle, layer.middle_right)

		layer.top_left = top_left_corner.duplicate()
		layer.top_right = top_right_corner.duplicate() 
		layer.bottom_left = bottom_left_corner.duplicate() 
		layer.bottom_right = bottom_right_corner.duplicate() 

func flip_3x3_grid_horizontally():
	if mesh == null:
		return
	var min_x = INF
	var max_x = -INF
	for v in mesh.original_vertices:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
	var center_x = (min_x + max_x) * 0.5
	
	var layer : DeformLayer = mesh.get_layer(Global.selected_mesh_inx)
	if layer != null && is_instance_valid(layer):

		var top_left_flipped = flip_deformation_horizontally(layer.top_left, center_x)
		var top_middle_flipped = flip_deformation_horizontally(layer.top_middle, center_x)
		var top_right_flipped = flip_deformation_horizontally(layer.top_right, center_x)
		var middle_left_flipped = flip_deformation_horizontally(layer.middle_left, center_x)
		var center_flipped = flip_deformation_horizontally(layer.center, center_x)
		var middle_right_flipped = flip_deformation_horizontally(layer.middle_right, center_x)
		var bottom_left_flipped = flip_deformation_horizontally(layer.bottom_left, center_x)
		var bottom_middle_flipped = flip_deformation_horizontally(layer.bottom_middle, center_x)
		var bottom_right_flipped = flip_deformation_horizontally(layer.bottom_right, center_x)
		layer.top_left = top_right_flipped
		layer.top_middle = top_middle_flipped
		layer.top_right = top_left_flipped
		layer.middle_left = middle_right_flipped
		layer.center = center_flipped
		layer.middle_right = middle_left_flipped
		layer.bottom_left = bottom_right_flipped
		layer.bottom_middle = bottom_middle_flipped
		layer.bottom_right = bottom_left_flipped
		mesh.sync_deformation_arrays()


func mirror_left_to_right_ear():
	if mesh == null:
		return
	mirror_corner(mesh.deform_top_left, mesh.deform_top_right)
	mesh.sync_deformation_arrays()
	mesh.queue_redraw()

func mirror_corner(left_corner: PackedVector2Array, right_corner_ref: PackedVector2Array):
	if mesh == null:
		return
	var min_x = INF
	var max_x = -INF
	for v in mesh.original_vertices:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
	var center_x = (min_x + max_x) * 0.5
	
	var mirrored = flip_deformation_horizontally(left_corner, center_x)
	for i in range(min(mirrored.size(), right_corner_ref.size())):
		right_corner_ref[i] = mirrored[i]
	mesh.queue_redraw()

func flip_deformation_horizontally(src: PackedVector2Array, axis_x: float) -> PackedVector2Array:
	var flipped := PackedVector2Array()
	for v in src:
		flipped.append(Vector2(axis_x + (axis_x - v.x), v.y))
	return flipped

func mirror_right_to_left():
	if mesh == null:
		return

	var original = mesh.original_vertices
	var left = mesh.deform_middle_left
	var right = mesh.deform_middle_right

	var count = min(left.size(), right.size(), original.size())
	for i in range(count):
		var offset_y = left[i].y - original[i].y
		right[i].x = original[i].x - (left[i].x - original[i].x)
		right[i].y = original[i].y + offset_y

	mesh.deform_middle_right = right
	mesh.queue_redraw()

func _make_delta(verts: PackedVector2Array, add : PackedVector2Array) -> PackedVector2Array:
	var delta := PackedVector2Array()
	delta.resize(verts.size())
	for i in range(verts.size()):
		delta[i] = verts[i] + add[i]
	return delta
