extends Node


var should_change : bool = false
var deform : bool = false

func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()
	set_static_data()

func nullfy():
	%GenerateMesh.disabled = true
	if Global.mesh_pointer != null && is_instance_valid(Global.mesh_pointer):
		Global.mesh_pointer.enabled = false

func enable():
	var _disable : bool = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type != "Mesh":
				_disable = true
				nullfy()
				break
			%GenerateMesh.disabled = false
			if Global.mesh_pointer != null && is_instance_valid(Global.mesh_pointer):
				Global.mesh_pointer.enabled = true
			set_data()

func set_data():
	should_change = false
	if deform:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "Mesh":
					i.get_node("%Sprite2D").editable = true
					i.get_node("%MeshEditor").queue_redraw()
	should_change = true

func _on_generate_mesh_pressed() -> void:
	for i in Global.held_sprites:
		i.get_node("%Sprite2D").texture = %MeshTexture.texture
		i.get_node("%MeshEditor").regenerate_mesh()

func set_static_data():
	%InfluRad.value = MeshEditor.influence_radius
	%InfluStrength.value = MeshEditor.influence_strength
	%SquareGrid.button_pressed = MeshEditor.square_grid
	%RingGrid.button_pressed = MeshEditor.ring_grid
	%GridSize.value = MeshEditor.grid_size
	%RingSpacing.value = MeshEditor.ring_spacing
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
	MeshEditor.ring_spacing = value

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
