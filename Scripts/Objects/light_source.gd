extends PointLight2D

var of = 0
var dragging
var light_controls = null
var light_control_node = null


func _ready():
	if get_tree().get_root().has_node("Main"):
		light_controls = get_tree().get_root().get_node("Main/%Control/%HBox25")
		light_control_node = get_tree().get_root().get_node("Main/%Control/LightControl")
	Global.light_info.connect(get_state)

func _process(_delta):
	if dragging && $Grab.visible:
		global_position = get_global_mouse_position() - of
		if light_controls != null && is_instance_valid(light_controls):
			light_controls.get_node("LightPosXSpinBox").value = global_position.x
			light_controls.get_node("LightPosYSpinBox").value = global_position.y

func save_state(id):
	var dict = {
		visible = visible,
		energy = energy,
		color = color,
		global_position = global_position,
		scale = scale,
		blend = blend_mode,
	}
	Global.settings_dict.light_states[id] = dict

func get_state(state):
	if not Global.settings_dict.light_states[state].is_empty():
		var dict: Dictionary = Global.settings_dict.light_states[state]
		energy = dict.energy
		color = dict.color
		%LightTexture.self_modulate = color
		global_position = dict.global_position
		scale = dict.scale
		visible = dict.visible
		$Grab.modulate = color
		blend_mode = dict.get("blend", 0)
	else:
		energy = 2
		color = Color.WHITE
		global_position = Vector2(0,0)
		scale = Vector2(1,1)
		visible = false
		$Grab.modulate = color
		$Grab.hide()
		blend_mode = Light2D.BLEND_MODE_ADD
		
		if light_control_node != null && is_instance_valid(light_control_node):
			light_control_node.reset_info(self)

func _on_grab_button_down():
	if $Grab.visible:
		of = get_global_mouse_position() - global_position
		dragging = true

func _on_grab_button_up():
	dragging = false
	save_state(Global.current_state)
