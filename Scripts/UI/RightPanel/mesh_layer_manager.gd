extends Node

var should_change : bool = false

func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()
	Global.mesh_text_node = self

func nullfy():
	%Stiffnessx.editable = false
	%Stiffnessy.editable = false
	%Dampingx.editable = false
	%Dampingy.editable = false
	%Massx.editable = false
	%Massy.editable = false
	%FollowSpeed.editable = false
	%NoiseSpeed.editable = false
	%NoiseScale.editable = false
	%SineSpeed.editable = false
	%SineAmp.editable = false
	%TargetStrength.editable = false
	%SelectedLayer.disabled = true
	%SelectedLayer.clear()
	%MotionType.disabled = true
	%AddLayer.disabled = true
	%DeleteLayer.disabled = true
	%SelectedGlue.disabled = true
	%SelectedWarp.disabled = true

func enable():
	var _disable : bool = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type != "Mesh":
				_disable = true
				nullfy()
				break

	if !_disable:
		%Stiffnessx.editable = true
		%Stiffnessy.editable = true
		%Dampingx.editable = true
		%Dampingy.editable = true
		%Massx.editable = true
		%Massy.editable = true
		%FollowSpeed.editable = true
		%NoiseSpeed.editable = true
		%NoiseScale.editable = true
		%SineSpeed.editable = true
		%SineAmp.editable = true
		%TargetStrength.editable = true
		%SelectedLayer.disabled = false
		%MotionType.disabled = false
		%AddLayer.disabled = false
		%DeleteLayer.disabled = false
		%SelectedGlue.disabled = false
		%SelectedWarp.disabled = false
		
		%SelectedLayer.clear()
		set_data()

func set_data():
	should_change = false
	%SelectedLayer.clear()
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Mesh":
				if i.mesh.get_layer_count() < Global.selected_mesh_inx:
					continue
				var layer = i.mesh.get_layer(Global.selected_mesh_inx)
				if layer != null:
					%Stiffnessx.value = layer.stiffness.x
					%Stiffnessy.value = layer.stiffness.x
					%Dampingx.value = layer.damping.x
					%Dampingy.value = layer.damping.x
					%Massx.value = layer.mass.x
					%Massy.value = layer.mass.x
					%FollowSpeed.value = layer.follow_lerp
					%NoiseSpeed.value = layer.noise_speed
					%NoiseScale.value = layer.noise_scale
					%SineSpeed.value = layer.sine_speed
					%SineAmp.value = layer.sine_amplitude * 100
					%TargetStrength.value = layer.target_strength
					%MotionType.select(layer.motion)
	if Global.held_sprites.size() > 0:
		for i in Global.held_sprites[0].mesh.get_layer_count():
			%SelectedLayer.add_item(str(i))
		
	%SelectedLayer.select(Global.selected_mesh_inx)
	if Global.held_sprites[0].mesh.glues.size() > 0:
		var selected_glue : GlueGroup = Global.held_sprites[0].mesh.glues[0]
		%SelectedGlue.select(%SelectedGlue.get_item_index(selected_glue.id))
	else:
		%SelectedGlue.select(-1)
		
	if Global.held_sprites[0].mesh.warps.size() > 0:
		var selected_warp : DeformLayer = Global.held_sprites[0].mesh.warps[0]
		%SelectedWarp.select(%SelectedWarp.get_item_index(selected_warp.id))
		MeshEditor.active_warp = selected_warp
	else:
		%SelectedWarp.select(-1)
	
	should_change = true

func _on_stiffnessx_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "stiffness",
						value = layer.stiffness,
						new_val = Vector2(value, layer.stiffness.y)
					}
				undo_redo_data.append(d)
				layer.stiffness.x = value
	submit_to_undo_redo(undo_redo_data)

func _on_stiffnessy_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "stiffness",
						value = layer.stiffness,
						new_val = Vector2(layer.stiffness.x, value)
					}
				undo_redo_data.append(d)
				layer.stiffness.y = value
	submit_to_undo_redo(undo_redo_data)

func _on_dampingx_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "damping",
						value = layer.damping,
						new_val = Vector2(value, layer.damping.y)
					}
				undo_redo_data.append(d)
				layer.damping.x = value
	submit_to_undo_redo(undo_redo_data)

func _on_dampingy_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "damping",
						value = layer.damping,
						new_val = Vector2(layer.damping.x, value)
					}
				undo_redo_data.append(d)
				layer.damping.y = value
	submit_to_undo_redo(undo_redo_data)

func _on_massx_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "mass",
						value = layer.damping,
						new_val = Vector2(value, layer.mass.y)
					}
				undo_redo_data.append(d)
				layer.mass.x = value
	submit_to_undo_redo(undo_redo_data)

func _on_massy_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "mass",
						value = layer.damping,
						new_val = Vector2(layer.mass.x, value)
					}
				undo_redo_data.append(d)
				layer.mass.y = value
	submit_to_undo_redo(undo_redo_data)

func _on_follow_speed_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "follow_lerp",
						value = layer.follow_lerp,
						new_val = value
					}
				undo_redo_data.append(d)
				layer.follow_lerp = value
	submit_to_undo_redo(undo_redo_data)

func _on_noise_speed_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "noise_speed",
						value = layer.noise_speed,
						new_val = value
					}
				undo_redo_data.append(d)
				layer.noise_speed = value
	submit_to_undo_redo(undo_redo_data)

func _on_noise_scale_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "noise_scale",
						value = layer.noise_scale,
						new_val = value
					}
				undo_redo_data.append(d)
				layer.noise_scale = value
	submit_to_undo_redo(undo_redo_data)

func _on_sine_speed_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "sine_speed",
						value = layer.sine_speed,
						new_val = value
					}
				undo_redo_data.append(d)
				layer.sine_speed = value
	submit_to_undo_redo(undo_redo_data)

func _on_sine_amp_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "sine_amp",
						value = layer.sine_amplitude,
						new_val = value * 0.1
					}
				undo_redo_data.append(d)
				layer.sine_amplitude = value * 0.1
	submit_to_undo_redo(undo_redo_data)

func _on_motion_type_item_selected(index: int) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "motion",
						value = layer.motion,
						new_val = index
					}
				undo_redo_data.append(d)
				layer.motion = index
	submit_to_undo_redo(undo_redo_data)

func _on_selected_layer_item_selected(index: int) -> void:
	if !should_change : return
	Global.selected_mesh_inx = index
	set_data()

func _on_target_strength_value_changed(value: float) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue

			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			if layer != null && is_instance_valid(layer):
				var d = {
						layer = layer,
						action = "target_strength",
						value = layer.target_strength,
						new_val = value
					}
				undo_redo_data.append(d)
				layer.target_strength = value
	submit_to_undo_redo(undo_redo_data)

func _on_delete_layer_pressed() -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() == 1:
				continue
			i.mesh.remove_deform_layer(Global.selected_mesh_inx)
			Global.selected_mesh_inx = 0

func _on_add_layer_pressed() -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.get_node("%MeshEditor").add_layer()
			%SelectedLayer.add_item(str(max(1, i.mesh.get_layer_count() - 1)))

func submit_to_undo_redo(data):
	UndoRedoManager.push_data(data)

func _on_brush_type_item_selected(index: int) -> void:
	MeshEditor.brush_type = index

func _on_add_glue_pressed() -> void:
	CustomMesh.add_glue_group()
	var gg = CustomMesh.get_glue_groups()
	var g : GlueGroup = gg[-1]
	g.id = randi()
	%SelectedGlue.clear()
	%SelectedGlue.add_item("None")
	var index : int = 1
	for i in CustomMesh.get_glue_groups():
		%SelectedGlue.add_item(i.glue_name)
		%SelectedGlue.set_item_id(index, i.id)
		index += 1

func _on_add_warp_pressed() -> void:
	CustomMesh.add_warp_group()
	var wg = CustomMesh.get_warp_groups()
	var w : DeformLayer = wg[-1]
	%SelectedWarp.add_item("None")
	var index : int = 1
	w.id = randi()
	initialize_deform_layer_grid(w, Vector2.ZERO, 3)
	for i in CustomMesh.get_warp_groups():
		%SelectedWarp.add_item("New Warp")
		%SelectedWarp.set_item_id(index, i.id)
		index += 1

func _on_delete_glue_pressed() -> void:
	pass

func _on_delete_warp_pressed() -> void:
	pass # Replace with function body.

func _on_selected_glue_item_selected(index: int) -> void:
	var glues = CustomMesh.get_glue_groups()
	var true_index = max(0, index -1)
	if true_index > glues.size(): return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var mesh : CustomMesh = i.mesh
			if mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var glue_group : GlueGroup = glues[true_index]
			mesh.glues = [glue_group.id]

func _on_selected_warp_item_selected(index: int) -> void:
	var warps = CustomMesh.get_warp_groups()
	var true_index = max(0, index -1)
	if true_index > warps.size(): return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var mesh : CustomMesh = i.mesh
			if mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var warp : DeformLayer = warps[true_index]
			mesh.warps = [warp.id]
			MeshEditor.active_warp = warp

func _on_edit_type_item_selected(index: int) -> void:
	match index:
		0:
			MeshEditor.editor_mode = MeshEditor.EditorMode.DEFORM
		1:
			MeshEditor.editor_mode = MeshEditor.EditorMode.GLUE
		2:
			MeshEditor.editor_mode = MeshEditor.EditorMode.WARP

func initialize_deform_layer_grid(layer: DeformLayer, center_pos: Vector2, grid_size: float = 1.0):
	layer.top_left = []
	layer.top_middle = []
	layer.top_right = []
	layer.middle_left = []
	layer.center = []
	layer.middle_right = []
	layer.bottom_left = []
	layer.bottom_middle = []
	layer.bottom_right = []

	var offsets = [
		["top_left", Vector2(-grid_size, -grid_size)],
		["top_middle", Vector2(0, -grid_size)],
		["top_right", Vector2(grid_size, -grid_size)],
		["middle_left", Vector2(-grid_size, 0)],
		["center", Vector2(0, 0)],
		["middle_right", Vector2(grid_size, 0)],
		["bottom_left", Vector2(-grid_size, grid_size)],
		["bottom_middle", Vector2(0, grid_size)],
		["bottom_right", Vector2(grid_size, grid_size)],
	]

	for name_offset in offsets:
		var arr_name = name_offset[0]
		var offset = name_offset[1]
		var arr = PackedVector2Array()
		arr.append(center_pos + offset)
		layer.set(arr_name, arr)
