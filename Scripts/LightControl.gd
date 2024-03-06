extends Node

@onready var light = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/LightSource")
#@onready var contain = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")

func _ready():
	Global.light_info.connect(get_info)


func _on_light_energy_slider_value_changed(value):
	light.energy = value
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
	light.save_state(Global.current_state)


func get_info(state):
	if not Global.settings_dict.light_states[state].is_empty():
		var dict = Global.settings_dict.light_states[state]
		%LightSourceVis.button_pressed = dict.visible
		%LightColor.color = dict.color
		%LightEnergySlider.value = dict.energy
		%LightSizeSlider.value = dict.scale.x
	%DarkenCheck.button_pressed = Global.settings_dict.darken



func _on_darken_check_toggled(toggled_on):
	Global.settings_dict.darken = toggled_on
