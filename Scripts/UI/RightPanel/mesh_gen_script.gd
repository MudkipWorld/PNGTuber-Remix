extends Node


var should_change : bool = false
var deform : bool = false
var held_image_data : ImageData = ImageData.new()
var mesh_obj = preload("res://Misc/MeshObject/mesh_object.tscn")

func _ready() -> void:
	held_image_data.runtime_texture = preload("res://PicklesIdle.png")
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()
	set_static_data()
	Global.mesh_text_node = self

func nullfy():
	%GenerateMesh.disabled = true
	%GenerateMesh3.disabled = true
	%GenerateMesh4.disabled = true
	%GenerateMesh6.disabled = true
	
		
	for i in Global.get_tree().get_nodes_in_group("Meshes"):
		i.get_node("%Sprite2D").editable = false
		i.get_node("%MeshEditor").queue_redraw()

func enable():
	var _disable : bool = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type != "Mesh":
				_disable = true
				nullfy()
				break
			%GenerateMesh.disabled = false
			%GenerateMesh3.disabled = false
			%GenerateMesh4.disabled = false
			%GenerateMesh6.disabled = false
			set_data()

func set_data():
	should_change = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				if deform:
					i.get_node("%Sprite2D").editable = true
					i.get_node("%MeshEditor").queue_redraw()
				%FollowWobble.button_pressed = i.get_value("move_with_wobble")
				%FollowMovements.button_pressed = i.get_value("move_with_follow")
					
	should_change = true

func _on_generate_mesh_pressed() -> void:
	for i in Global.held_sprites:
		if held_image_data not in Global.image_manager_data:
			Global.image_manager_data.append(held_image_data)
			Global.add_new_image.emit(held_image_data)
		i.get_node("%Sprite2D").texture = %MeshTexture.texture
		i.used_image_id = held_image_data.id
		i.referenced_data = held_image_data
		i.get_node("%MeshEditor").regenerate_mesh()

func set_static_data():
	%InfluRad.value = MeshEditor.influence_radius
	%InfluStrength.value = MeshEditor.influence_strength
	%SquareGrid.button_pressed = MeshEditor.square_grid
	%RingGrid.button_pressed = MeshEditor.ring_grid
	%GridSize.value = MeshEditor.grid_size
	%RingSpacing.value = MeshEditor.radial_spacing
	%Threshold.value = MeshEditor.threshold
	%InternalPoints.value = MeshEditor.internal_point_count
	%Eplision.value = MeshEditor.eplision
	%MergeClose.value = MeshEditor.merge_close

func _on_influ_rad_value_changed(value: float) -> void:
	MeshEditor.influence_radius = value

func _on_influ_strength_value_changed(value: float) -> void:
	MeshEditor.influence_strength = value

func _on_square_grid_toggled(toggled_on: bool) -> void:
	MeshEditor.square_grid = toggled_on

func _on_ring_grid_toggled(toggled_on: bool) -> void:
	MeshEditor.ring_grid = toggled_on

func _on_grid_size_value_changed(value: float) -> void:
	MeshEditor.grid_size = value

func _on_ring_spacing_value_changed(value: float) -> void:
	MeshEditor.radial_spacing = value

func _on_threshold_value_changed(value: float) -> void:
	MeshEditor.threshold = value

func _on_internal_points_value_changed(value: float) -> void:
	MeshEditor.internal_point_count = int(value)

func _on_eplision_value_changed(value: float) -> void:
	MeshEditor.eplision = value

func _on_merge_close_value_changed(value: float) -> void:
	MeshEditor.merge_close = value

func _on_deform_mode_toggled(toggled_on: bool) -> void:
	deform = toggled_on
	if !deform:
		for i in Global.get_tree().get_nodes_in_group("Meshes"):
			i.get_node("%Sprite2D").editable = false
			i.get_node("%MeshEditor").queue_redraw()
	elif deform:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "Mesh":
					i.get_node("%Sprite2D").editable = true
					i.get_node("%MeshEditor").queue_redraw()
	if Global.mesh_pointer != null && is_instance_valid(Global.mesh_pointer):
		Global.mesh_pointer.enabled = toggled_on

func _on_mesh_texture_mouse_entered() -> void:
	Global.over_mesh_tex = true

func _on_mesh_texture_mouse_exited() -> void:
	Global.over_mesh_tex = false

func _on_follow_wobble_toggled(toggled_on: bool) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				i.sprite_data.move_with_wobble = toggled_on
				i.save_state(Global.current_state)

func _on_follow_movements_toggled(toggled_on: bool) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				i.sprite_data.move_with_follow = toggled_on
				i.save_state(Global.current_state)

func _on_web_mode_toggled(toggled_on: bool) -> void:
	MeshEditor.draw_internal_web = toggled_on
	if deform:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "Mesh":
					i.get_node("%MeshEditor").queue_redraw()

func _on_add_mesh_pressed() -> void:
	if held_image_data not in Global.image_manager_data:
		Global.image_manager_data.append(held_image_data)
		Global.add_new_image.emit(held_image_data)
	var sprte_obj = mesh_obj.instantiate()
	Global.sprite_container.add_child(sprte_obj)
	sprte_obj.get_node("%Sprite2D").texture = %MeshTexture.texture
	sprte_obj.used_image_id = held_image_data.id
	sprte_obj.referenced_data = held_image_data
	sprte_obj.sprite_name = "(Mesh)" + held_image_data.image_name 
	sprte_obj.sprite_type = "Mesh"
	sprte_obj.get_node("%Sprite2D").set_mesh_id(sprte_obj.sprite_id)
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		sprte_obj.states.append({})
	Global.update_layers.emit(0, sprte_obj, "Mesh")
	sprte_obj.sprite_id = sprte_obj.get_instance_id()
	sprte_obj.get_node("%MeshEditor").regenerate_mesh()
	%MeshLayerManager.populate_targets()

func _on_tri_grid_toggled(toggled_on: bool) -> void:
	MeshEditor.tri_grid = toggled_on

func _on_tri_radial_toggled(toggled_on: bool) -> void:
	MeshEditor.radial_hex = toggled_on

func _on_flip_pressed() -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				i.get_node("%MeshEditor").create_mirrored_mesh()

func _on_outer_padding_toggled(toggled_on: bool) -> void:
	MeshEditor.outer_padding = toggled_on

func _on_padding_value_changed(value: float) -> void:
	MeshEditor.padding = value

func _on_generate_mesh_3_pressed() -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				i.get_node("%MeshEditor").auto_gen_corners()

func _on_generate_mesh_4_pressed() -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				i.get_node("%MeshEditor").flip_3x3_grid_horizontally()

func _on_generate_mesh_6_pressed() -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				i.get_node("%MeshEditor").reset_point()
