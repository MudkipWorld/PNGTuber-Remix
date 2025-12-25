extends VBoxContainer

var should_change : bool = false

func _ready() -> void:
	Global.reinfoanim.connect(set_data)
	await get_tree().current_scene.ready
	set_data()

func set_data():
	should_change = false
	if Global.sprite_container != null && is_instance_valid(Global.sprite_container):
		%EffectType.item_selected.emit(Global.sprite_container.model_effects.effect_type)
		%EffectType.select(Global.sprite_container.model_effects.effect_type)
		%EffectColor.color = Global.sprite_container.model_effects.effect_color
		%EffectColor2.color = Global.sprite_container.model_effects.effect_color
		%SizeSlider.value = Global.sprite_container.model_effects.effect_size
		%SizeSlider2.value = Global.sprite_container.model_effects.effect_size
		%RollSpeed.value = Global.sprite_container.model_effects.roll_speed
		%RollSize.value = Global.sprite_container.model_effects.roll_size
		%Aberration.value = Global.sprite_container.model_effects.aberration
	#	%RainbowCheck
	should_change = true

func _on_option_button_item_selected(index: int) -> void:
	Global.viewer.material.set_shader_parameter("effect", index)
	Global.sprite_container.model_effects.effect_type = index
	Global.sprite_container.save_state(Global.current_state)
	%PanelContainer.hide()
	match index:
		0:
			%PanelContainer.hide()
		1:
			%TabContainer.current_tab = 0
			%PanelContainer.show()
		2:
			%TabContainer.current_tab = 1
			%PanelContainer.show()
		4:
			%TabContainer.current_tab = 2
			%PanelContainer.show()
		3:
			%TabContainer.current_tab = 3
			%PanelContainer.show()

func _on_effect_color_color_changed(color: Color) -> void:
	if !should_change: return
	%EffectColor2.color = color
	Global.viewer.material.set_shader_parameter("line_color", color)
	Global.sprite_container.model_effects.effect_color = color
	Global.sprite_container.save_state(Global.current_state)

func _on_size_slider_value_changed(value: float) -> void:
	if !should_change: return
	%SizeSlider2.value = value
	Global.viewer.material.set_shader_parameter("line_scale", value)
	Global.sprite_container.model_effects.effect_size = value
	Global.sprite_container.save_state(Global.current_state)

func _on_rainbow_check_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.

func _on_color_blindness_helper_options_item_selected(index: int) -> void:
	if !should_change: return
	Global.sprite_container.model_effects.color_blindness_effect = index
	Global.viewport.material.set_shader_parameter("effect", index)
	Global.sprite_container.save_state(Global.current_state)

func _on_size_slider_2_value_changed(value: float) -> void:
	if !should_change: return
	%SizeSlider.value = value
	Global.viewer.material.set_shader_parameter("line_scale", value)
	Global.sprite_container.model_effects.effect_size = value
	Global.sprite_container.save_state(Global.current_state)

func _on_effect_color_2_color_changed(color: Color) -> void:
	if !should_change: return
	%EffectColor.color = color
	Global.viewer.material.set_shader_parameter("line_color", color)
	Global.sprite_container.model_effects.effect_color = color
	Global.sprite_container.save_state(Global.current_state)

func _on_roll_speed_value_changed(value: float) -> void:
	if !should_change: return
	Global.viewer.material.set_shader_parameter("roll_speed", value)
	Global.sprite_container.model_effects.roll_speed = value
	Global.sprite_container.save_state(Global.current_state)

func _on_roll_size_value_changed(value: float) -> void:
	if !should_change: return
	Global.viewer.material.set_shader_parameter("aberration", value)
	Global.sprite_container.model_effects.aberration = value
	Global.sprite_container.save_state(Global.current_state)
