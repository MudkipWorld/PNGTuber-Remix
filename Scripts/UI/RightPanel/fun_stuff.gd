extends ScrollContainer

var should_change : bool = false
var selected_items : Array = []

var selected_items_to_add : Array = []

func _ready() -> void:
	set_process_unhandled_input(false)
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	Global.load_model.connect(update_ui)
	nullfy()

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
	Global.throwable_spawner.position.x = value

func _on_position_y_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.position.y = value

func _on_dir_x_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.dir.x = value

func _on_dir_y_value_changed(value: float) -> void:
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.dir.y = value

func update_ui():
	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	%PositionX.value = Global.throwable_spawner.position.x
	%PositionY.value = Global.throwable_spawner.position.y
	%DirX.value = Global.throwable_spawner.dir.x
	%DirY.value = Global.throwable_spawner.dir.y
	%SpawnPerTrigger.value = float(Global.throwable_spawner.throw_per_trigger)
	%SpawnVariance.value = Global.throwable_spawner.spawn_variance
	%BothSides.button_pressed = Global.throwable_spawner.both_sides
	%BaseMass.value = Global.throwable_spawner.base_mass
	if has_node("%SpawnVariance"):
		%SpawnVariance.value = float(Global.throwable_spawner.spawn_variance)
	if has_node("%BothSides"):
		%BothSides.button_pressed = Global.throwable_spawner.both_sides
	%ItemList.clear()
	var index : int = 0
	for i in Global.throwable_spawner.selected_items:
		%ItemList.add_item(i.image_name, i.runtime_texture, true)
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
	var index : int = 0
	for i in selected_items_to_add:
		%ItemList.add_item(i.image_name, i.runtime_texture, true)
		%ItemList.set_item_metadata(index, i)
		index += 1

	if Global.throwable_spawner == null or !is_instance_valid(Global.throwable_spawner) : return
	Global.throwable_spawner.selected_items.append_array(selected_items_to_add.duplicate())
	
	selected_items_to_add.clear()

func _on_selection_list_multi_selected(_index: int, _selected: bool) -> void:
	selected_items_to_add.clear()
	for i in %SelectionList.item_count:
		if %SelectionList.is_selected(i):
			selected_items_to_add.append(%SelectionList.get_item_metadata(i))

func _on_throw_key_toggled(toggled_on: bool) -> void:
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		%ThrowKey.text = tr("TR_AWAITING_INPUT")
		release_focus()
	else:
		update_key_text()
		grab_focus()

func _unhandled_input(event):
	if !event is InputEventMouseMotion:
		if event.is_released():
			InputMap.action_erase_events('throwing')
			InputMap.action_add_event('throwing', event)
			%ThrowKey.button_pressed = false
			update_key_text()

func update_key_text():
	if InputMap.action_get_events('throwing').size() != 0:
		%ThrowKey.text = "%s" % InputMap.action_get_events('throwing')[0].as_text()
	else:
		%ThrowKey.text = tr("TR_BIND_KEY")

func _on_remove_asset_button_pressed() -> void:
	if InputMap.action_get_events('throwing').size() != 0:
		InputMap.action_erase_events('throwing')
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
