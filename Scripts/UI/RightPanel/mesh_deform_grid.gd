extends Control


var enabled : bool = false
var dragging : bool = false
var deform_x = 0.0
var deform_y = 0.0


func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)


func enable():
	var _disable : bool = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type != "Mesh":
				_disable = true
				nullfy()
				break
			enabled = true
			update_all_meshes_points()


func nullfy():
	enabled = false
	dragging = false

func _physics_process(_delta: float) -> void:
	if dragging:
		var local_pos = %PointerHolder.get_local_mouse_position()
		var _size = %PointerHolder.size
		var pointer_offset = Vector2(20, 20)
		var snap_points = [
			Vector2(0, 0), Vector2(_size.x / 2, 0), Vector2(_size.x, 0),   
			Vector2(0, _size.y / 2), Vector2(_size.x / 2, _size.y / 2), Vector2(_size.x, _size.y / 2), 
			Vector2(0, _size.y), Vector2(_size.x / 2, _size.y), Vector2(_size.x, _size.y) 
		]
		var closest = snap_points[0]
		var min_dist = local_pos.distance_to(snap_points[0])
		for point in snap_points:
			var dist = local_pos.distance_to(point)
			if dist < min_dist:
				min_dist = dist
				closest = point
		%Pointer.position = closest - pointer_offset
		deform_x = clamp((closest.x) / _size.x, 0.0, 1.0)
		deform_y = clamp((closest.y) / _size.y, 0.0, 1.0)
		update_all_meshes_points()

func update_all_meshes_points():
	for i in Global.get_tree().get_nodes_in_group("Meshes"):
		i.get_node("%Sprite2D").deform_x = deform_x
		i.get_node("%Sprite2D").deform_y = deform_y
		i.get_node("%Sprite2D").deformations_3x3(deform_x, deform_y)
		i.get_node("%MeshEditor").queue_redraw()




func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if enabled:
		if event.is_action_pressed("lmb"):
			dragging = true


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("lmb"):
		dragging = false
