extends Node

var should_change : bool = false

func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()
	Global.mesh_text_node = self

func nullfy():
	%Velx.editable = false
	%Vely.editable = false
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

func enable():
	var _disable : bool = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type != "Mesh":
				_disable = true
				nullfy()
				break

	if !_disable:
		%Velx.editable = true
		%Vely.editable = true
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
				%Velx.value = layer.external_velocity.x
				%Vely.value = layer.external_velocity.y
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
	should_change = true

func _on_velx_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.external_velocity.x = value

func _on_vely_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.external_velocity.y = value

func _on_stiffnessx_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.stiffness.x = value

func _on_stiffnessy_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.stiffness.y = value

func _on_dampingx_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.damping.x = value

func _on_dampingy_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.damping.y = value

func _on_massx_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.mass.x = value

func _on_massy_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.mass.y = value

func _on_follow_speed_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.follow_lerp = value

func _on_noise_speed_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.noise_speed = value

func _on_noise_scale_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.noise_scale = value

func _on_sine_speed_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.sine_speed = value

func _on_sine_amp_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.sine_amplitude = value * 0.01

func _on_motion_type_item_selected(index: int) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.motion = index

func _on_selected_layer_item_selected(index: int) -> void:
	if !should_change : return
	Global.selected_mesh_inx = index
	set_data()

func _on_target_strength_value_changed(value: float) -> void:
	if !should_change : return
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.mesh.get_layer_count() < Global.selected_mesh_inx:
				continue
			var layer : DeformLayer = i.mesh.get_layer(Global.selected_mesh_inx)
			layer.target_strength = value

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
