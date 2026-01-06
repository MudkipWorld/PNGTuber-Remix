extends Node

var should_change : bool = false

func _ready():
	Global.light_info.connect(get_info)
	Global.mode_changed.connect(update_visib)
	%LightColor.get_picker().picker_shape = 1
	%LightColor.get_picker().presets_visible = false
	%LightColor.get_picker().color_modes_visible = false
	%LightEnergyBSlider.get_node("SliderValue").value_changed.connect(_on_light_energy_slider_value_changed)
	%LightSizeBSlider.get_node("SliderValue").value_changed.connect(_on_light_size_slider_value_changed)

func update_visib(id : int = 0):
	match id:
		1:
			%LSShapeVis.button_pressed = false

func _on_light_energy_slider_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		add_to_undo("energy", Global.light.energy , value)
		Global.light.energy = value
		Global.light.save_state(Global.current_state)


func _on_light_color_color_changed(color):
	if Global.light != null && is_instance_valid(Global.light):
		add_to_undo("color", Global.light.color , color)
		Global.light.color = color
		Global.light.get_node("LightTexture").self_modulate = color
		Global.light.save_state(Global.current_state)

func _on_light_source_vis_toggled(toggled_on):
	if Global.light != null && is_instance_valid(Global.light):
		add_to_undo("visible", Global.light.visible , toggled_on)
		Global.light.visible = toggled_on
		Global.light.save_state(Global.current_state)

func _on_ls_shape_vis_toggled(toggled_on):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.get_node("Grab").visible = toggled_on

func _on_light_size_slider_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		add_to_undo("scale", Global.light.scale , value)
		Global.light.scale = Vector2(value,value)
		Global.light.save_state(Global.current_state)

func get_info(state):
	should_change = false
	if not Global.settings_dict.light_states[state].is_empty():
		var dict = Global.settings_dict.light_states[state]
		%LightSourceVis.button_pressed = dict.visible
		%LightColor.color = dict.color
		%LightEnergyBSlider.get_node("SliderValue").value = dict.energy
		%LightSizeBSlider.get_node("SliderValue").value = dict.scale.x
		%LightPosXSpinBox.value = Global.light.global_position.x
		%LightPosYSpinBox.value = Global.light.global_position.y
	%DarkenCheck.button_pressed = Global.settings_dict.darken
	%DarkenColor.color = Global.sprite_container.dim_color
	should_change = true

func reset_info(light_source):
	should_change = false
	%LightSourceVis.button_pressed = light_source.visible
	%LSShapeVis.button_pressed = false
	%LightColor.color = light_source.color
	%LightEnergyBSlider.get_node("SliderValue").value = light_source.energy
	%LightSizeBSlider.get_node("SliderValue").value = light_source.scale.x
	%LightPosXSpinBox.value = light_source.global_position.x
	%LightPosYSpinBox.value = light_source.global_position.y
	should_change = true

func _on_darken_check_toggled(toggled_on):
	if Global.light != null && is_instance_valid(Global.light):
		Global.settings_dict.darken = toggled_on

func _on_light_pos_x_spin_box_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		add_to_undo("global_position", Global.light.global_position , Vector2(value, Global.light.global_position.y))
		Global.light.global_position.x = value
		Global.light.save_state(Global.current_state)

func _on_light_pos_y_spin_box_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		add_to_undo("global_position", Global.light.global_position , Vector2(Global.light.global_position.x, value))
		Global.light.global_position.y = value
		Global.light.save_state(Global.current_state)

func _on_darken_color_color_changed(color):
	if Global.light != null && is_instance_valid(Global.light):
		Global.sprite_container.dim_color = color
		Global.sprite_container.save_state(Global.current_state)


func _on_blend_mode_item_selected(index: int) -> void:
	if Global.light != null && is_instance_valid(Global.light):
		add_to_undo("blend_mode", Global.light.blend_mode , index)
		Global.light.blend_mode = index
		Global.light.save_state(Global.current_state)

func add_to_undo(action, value, new_value):
	if should_change:
		var d = {
		light = Global.light, 
		state = Global.current_state,
		action  = action,
		value = value,
		new_val = new_value
		}
		UndoRedoManager.push_data(d)
