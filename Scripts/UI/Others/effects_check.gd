extends CheckBox
class_name EffectsButton

@export var effect_name : String

func _ready() -> void:
	pass

func _toggled(toggled_on: bool) -> void:
	if Global.viewer != null && is_instance_valid(Global.viewer):
		Global.viewer.material.set_shader_parameter(effect_name, toggled_on)
