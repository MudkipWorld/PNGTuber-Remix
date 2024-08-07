extends Node

@onready var light = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/LightSource")
#@onready var contain = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")

func _ready():
	Global.light_info.connect(get_info)
	%LightEnergyBSlider.get_node("SliderValue").value_changed.connect(_on_light_energy_slider_value_changed)
	%LightSizeBSlider.get_node("SliderValue").value_changed.connect(_on_light_size_slider_value_changed)

func _on_light_energy_slider_value_changed(value):
	light.energy = value
	%LightEnergyLabel.text = "Light Energy :  " + str(snappedf(value, 0.1))
	light.save_state(Global.current_state)


func _on_light_color_color_changed(color):
	light.color = color
	light.save_state(Global.current_state)


func _on_light_source_vis_toggled(toggled_on):
	light.visible = toggled_on
	light.save_state(Global.current_state)


func _on_ls_shape_vis_toggled(toggled_on):
	light.get_node("Grab").visible = toggled_on


func _on_light_size_slider_value_changed(value):
	light.scale = Vector2(value,value)
	%LightSizeLabel.text = "Light Size : " + str(snappedf(value, 0.1))
	light.save_state(Global.current_state)


func get_info(state):
	if not Global.settings_dict.light_states[state].is_empty():
		var dict = Global.settings_dict.light_states[state]
		%LightSourceVis.button_pressed = dict.visible
		%LightColor.color = dict.color
		%LightEnergyBSlider.get_node("SliderValue").value = dict.energy
		%LightSizeBSlider.get_node("SliderValue").value = dict.scale.x
		%LightPosXSpinBox.value = light.global_position.x
		%LightPosYSpinBox.value = light.global_position.y
	%DarkenCheck.button_pressed = Global.settings_dict.darken
	%DarkenColor.color = Global.settings_dict.dim_color


func reset_info(light_source):
		%LightSourceVis.button_pressed = light_source.visible
		%LSShapeVis.button_pressed = false
		%LightColor.color = light_source.color
		%LightEnergyBSlider.get_node("SliderValue").value = light_source.energy
		%LightSizeBSlider.get_node("SliderValue").value = light_source.scale.x
		%LightPosXSpinBox.value = light_source.global_position.x
		%LightPosYSpinBox.value = light_source.global_position.y


func _on_darken_check_toggled(toggled_on):
	Global.settings_dict.darken = toggled_on


func _on_light_pos_x_spin_box_value_changed(value):
	light.global_position.x = value
	light.save_state(Global.current_state)


func _on_light_pos_y_spin_box_value_changed(value):
	light.global_position.y = value
	light.save_state(Global.current_state)


func _on_darken_color_color_changed(color):
	Global.settings_dict.dim_color = color
