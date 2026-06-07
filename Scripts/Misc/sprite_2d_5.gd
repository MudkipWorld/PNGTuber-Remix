@tool
## this component is meant to be used in a sprite that shall be used as a mask to carve holes out of anoter parent sprite2d

class_name Gnumarus2DMaskComponent extends Sprite2D


func _process(_delta: float) -> void:
	var v_masked_sprite:Node = get_parent()

	if not v_masked_sprite is Sprite2D:
		return


	'''
	# sets all parameters every frame
	if v_masked_sprite.material != null:
		material.set_shader_parameter('parent_color', v_masked_sprite.material.get_shader_parameter("current_color"))
		

	material.set_shader_parameter('m_mask_texture', texture)
	material.set_shader_parameter('m_viewport_size', get_viewport().size)
	material.set_shader_parameter('m_position', position)
	material.set_shader_parameter('m_mask_global', global_position)
	material.set_shader_parameter('m_parent_global', v_masked_sprite.global_position)
	material.set_shader_parameter('m_rotation', rotation)
	material.set_shader_parameter('m_scale', scale)'''
