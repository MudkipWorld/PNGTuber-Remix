extends ScrollContainer

var should_change : bool = false
var selected_items : Array = []
var selected_items_to_add : Array = []
var current_binding_action : String = ""
var selected : ThrowableResource

func _ready() -> void:
	set_process_unhandled_input(false)
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	Global.load_model.connect(update_ui)
	nullfy()
	
	%PositionX.min_value = 0.0
	%PositionX.max_value = 10000.0
	%PositionX.step = 1.0
	
	%PositionY.min_value = -359.0
	%PositionY.max_value = 359.0
	%PositionY.step = 1.0
	
	%PositionYSpin.value_changed.connect(_on_position_y_spin_value_changed)

	var distance_label = %Distance
	distance_label.text = tr("TR_DISTANCE")
	if distance_label.text == "TR_DISTANCE":
		distance_label.text = "Distance"
		
	var degree_label = %LabelDegree
	degree_label.text = tr("TR_DEGREE")
	if degree_label.text == "TR_DEGREE":
		degree_label.text = "Degree"
		
	var throw_force_label = %ForceX
	throw_force_label.text = tr("TR_THROW_FORCE")
	if throw_force_label.text == "TR_THROW_FORCE":
		throw_force_label.text = "Throw Force"

func nullfy():
	%HasCollision.disabled = true
	%Physics.disabled = true

func enable():
	%HasCollision.disabled = false
	%Physics.disabled = false
	set_data()

func set_data():
	should_change = false
	if Global.held_sprites.size() < 1 : return
	var i = Global.held_sprites[0]
	if i == null or !is_instance_valid(i): return
	%HasCollision.button_pressed = i.get_value('can_be_hit')
	%Physics.button_pressed = i.get_value('hit_physics')
	should_change = true

func _on_has_collision_toggled(toggled_on: bool) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "can_be_hit", Global.current_state, i.sprite_data.can_be_hit , toggled_on)
		i.sprite_data.can_be_hit = toggled_on
		i.static_collision.disabled = !toggled_on
		i.get_node('%HitDetection').set_collision_layer_value(2, toggled_on)
		
		StateButton.multi_edit(toggled_on, "can_be_hit", i, i.states)
		i.save_state(Global.current_state)
		undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func submit_to_undo_redo_manager(node, action, state, value, new_value) -> Dictionary:
	var d = {
				node = node,
				action = action,
				state = state,
				value = value, 
				new_val =new_value
			}
	return d

func _on_position_x_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.spawn_distance = value

func _on_position_y_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	
	var snapped_value = value
	var snap_threshold = 5.0
	for snap_target in [0.0, 90.0, 180.0, -90.0, -180.0, 270.0, -270.0]:
		if abs(value - snap_target) < snap_threshold:
			snapped_value = snap_target
			break
			
	if snapped_value != value:
		%PositionY.value = snapped_value
		return
		
	if %PositionYSpin.value != snapped_value:
		%PositionYSpin.value = snapped_value
		
	Global.throwable_spawner.spawn_degree = snapped_value

func _on_position_y_spin_value_changed(value: float) -> void:
	if %PositionY.value != value:
		%PositionY.value = value

func _on_dir_x_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.throw_force = value

func _on_time_variance_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.time_variance = value

func update_ui():
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	%PositionX.value = Global.throwable_spawner.spawn_distance
	%PositionY.value = Global.throwable_spawner.spawn_degree
	%PositionYSpin.value = Global.throwable_spawner.spawn_degree
	%DirX.value = Global.throwable_spawner.throw_force
	%SpawnPerTrigger.value = float(Global.throwable_spawner.throw_per_trigger)
	%SpawnVariance.value = Global.throwable_spawner.spawn_variance
	%BothSides.button_pressed = Global.throwable_spawner.both_sides
	%BaseMass.value = Global.throwable_spawner.base_mass
	%TimeVariance.value = Global.throwable_spawner.time_variance
	if has_node("%SpawnVariance"):
		%SpawnVariance.value = float(Global.throwable_spawner.spawn_variance)
	if has_node("%BothSides"):
		%BothSides.button_pressed = Global.throwable_spawner.both_sides
	%ItemList.clear()
	var index : int = 0
	for i in Global.throwable_spawner.selected_items:
		if i.image_data == null : 
			continue
		%ItemList.add_item(i.image_data.image_name, i.image_data.runtime_texture, true)
		%ItemList.set_item_metadata(index, i)
		index += 1
	
	update_key_text()

func _on_add_pressed() -> void:
	populate_popup()
	%PopupChoice.popup()

func _on_remove_pressed() -> void:
	for i in selected_items:
		for l in %ItemList.item_count:
			if %ItemList.get_item_metadata(l) == i:
				%ItemList.remove_item(l)
	
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	for i in selected_items:
		Global.throwable_spawner.selected_items.erase(i)

func _on_item_list_multi_selected(_index: int, _selected: bool) -> void:
	selected_items.clear()
	for i in %ItemList.item_count:
		if %ItemList.is_selected(i):
			selected_items.append(%ItemList.get_item_metadata(i))

func populate_popup():
	var index : int = 0
	%SelectionList.clear()
	for i in Global.image_manager_data:
		%SelectionList.add_item(i.image_name, i.runtime_texture, true)
		%SelectionList.set_item_metadata(index, i)
		index += 1

func _on_popup_choice_close_requested() -> void:
	%PopupChoice.hide()

func _on_confirm_pressed() -> void:
	var index : int = %ItemList.item_count
	var to_be_added : Array = []
	for i in selected_items_to_add:
		var throw_res : ThrowableResource = ThrowableResource.new()
		throw_res.image_data = i
		throw_res.set_initial_data()
		%ItemList.add_item(i.image_name, i.runtime_texture, true)
		%ItemList.set_item_metadata(index, throw_res)
		to_be_added.append(throw_res)
		index += 1

	if Global.throwable_spawner != null and is_instance_valid(Global.throwable_spawner):
		Global.throwable_spawner.selected_items.append_array(to_be_added.duplicate())
	
	selected_items_to_add.clear()
	%PopupChoice.hide()

func _on_selection_list_multi_selected(_index: int, _selected: bool) -> void:
	selected_items_to_add.clear()
	for i in %SelectionList.item_count:
		if %SelectionList.is_selected(i):
			selected_items_to_add.append(%SelectionList.get_item_metadata(i))

func _on_throw_key_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if has_node("%ThrowPauseKey"): %ThrowPauseKey.button_pressed = false
		current_binding_action = "throwing"
		set_process_unhandled_input(true)
		%ThrowKey.text = tr("TR_AWAITING_INPUT")
		release_focus()
	else:
		if current_binding_action == "throwing":
			set_process_unhandled_input(false)
			current_binding_action = ""
		update_key_text()
		grab_focus()

func _on_throw_pause_key_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%ThrowKey.button_pressed = false
		current_binding_action = "throwing_pause"
		set_process_unhandled_input(true)
		%ThrowPauseKey.text = tr("TR_AWAITING_INPUT")
		release_focus()
	else:
		if current_binding_action == "throwing_pause":
			set_process_unhandled_input(false)
			current_binding_action = ""
		update_key_text()
		grab_focus()

func _unhandled_input(event):
	if !event is InputEventMouseMotion and current_binding_action != "":
		if event.is_released():
			if !InputMap.has_action(current_binding_action):
				InputMap.add_action(current_binding_action)
			InputMap.action_erase_events(current_binding_action)
			InputMap.action_add_event(current_binding_action, event)
			if current_binding_action == "throwing":
				%ThrowKey.button_pressed = false
			elif current_binding_action == "throwing_pause":
				%ThrowPauseKey.button_pressed = false
			
			current_binding_action = ""
			set_process_unhandled_input(false)
			update_key_text()

func update_key_text():
	if InputMap.has_action('throwing') and InputMap.action_get_events('throwing').size() != 0:
		%ThrowKey.text = "%s" % InputMap.action_get_events('throwing')[0].as_text()
	else:
		%ThrowKey.text = tr("TR_BIND_KEY")
		
	if not InputMap.has_action('throwing_pause'):
		InputMap.add_action('throwing_pause')
		
	if has_node("%ThrowPauseKey"):
		if InputMap.action_get_events('throwing_pause').size() != 0:
			%ThrowPauseKey.text = "%s" % InputMap.action_get_events('throwing_pause')[0].as_text()
		else:
			%ThrowPauseKey.text = tr("TR_BIND_KEY")

func _on_remove_asset_button_pressed() -> void:
	if InputMap.has_action('throwing') and InputMap.action_get_events('throwing').size() != 0:
		InputMap.action_erase_events('throwing')
		update_key_text()

func _on_remove_throw_pause_button_pressed() -> void:
	if InputMap.has_action('throwing_pause') and InputMap.action_get_events('throwing_pause').size() != 0:
		InputMap.action_erase_events('throwing_pause')
		update_key_text()

func _on_physics_toggled(toggled_on: bool) -> void:
	if !should_change : return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "hit_physics", Global.current_state, i.sprite_data.hit_physics , toggled_on)
		i.sprite_data.hit_physics = toggled_on
		StateButton.multi_edit(toggled_on, "hit_physics", i, i.states)
		i.save_state(Global.current_state)
		undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_spawn_per_trigger_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.throw_per_trigger = int(value)

func _on_spawn_variance_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.spawn_variance = value

func _on_both_sides_toggled(toggled_on: bool) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.both_sides = toggled_on

func _on_throw_test_pressed() -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.throw_item()

func _on_base_mass_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.base_mass = value

func _on_stop_test_pressed() -> void:
	Global.throwable_spawner.toggle_pause()

func _on_edit_pressed() -> void:
	if selected_items.size() < 1: return
	selected = selected_items[0]
	if selected == null : return
	
	%Preview.texture = selected.image_data.runtime_texture
	%ObjMass.value = selected.mass
	%Friction.value = selected.friction
	%Bounce.value = selected.bounce
	%Gravity.value = selected.gravity_scale
	%Interia.value = selected.inertia
	%Rough.button_pressed = selected.rough
	%Absorbent.button_pressed = selected.absorb
	
	
	%ObjectEditor.popup()

func _on_object_editor_close_requested() -> void:
	%ObjectEditor.hide()

func _on_load_audio_pressed() -> void:
	%FileDialog.popup()

func _on_remove_audio_pressed() -> void:
	selected.audio_buffer.clear()
	selected.audio_data = null

func _on_play_audio_pressed() -> void:
	%TestPlayer.stream = selected.audio_data
	%TestPlayer.play()

func _on_stop_audio_pressed() -> void:
	%TestPlayer.stop()

func _on_file_dialog_file_selected(path: String) -> void:
	if !FileAccess.file_exists(path) : return
	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_buffer(file.get_length())
	selected.audio_buffer = data
	selected.recreate_audio()

func _on_obj_mass_value_changed(value: float) -> void:
	if selected == null : return
	selected.mass = value

func _on_friction_value_changed(value: float) -> void:
	if selected == null : return
	selected.friction = value

func _on_bounce_value_changed(value: float) -> void:
	if selected == null : return
	selected.bounce = value

func _on_gravity_value_changed(value: float) -> void:
	if selected == null : return
	selected.gravity_scale = value

func _on_interia_value_changed(value: float) -> void:
	if selected == null : return
	selected.inertia = value

func _on_rough_toggled(toggled_on: bool) -> void:
	if selected == null : return
	selected.rough = toggled_on

func _on_absorbent_toggled(toggled_on: bool) -> void:
	if selected == null : return
	selected.absorb = toggled_on

func _on_spawn_radius_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.spawn_radius = value
