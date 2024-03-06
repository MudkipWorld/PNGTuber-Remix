extends PointLight2D

var of = 0
var dragging

func _ready():
	Global.light_info.connect(get_state)


func _process(_delta):
	if dragging && $Grab.visible:
		global_position = get_global_mouse_position() - of

func save_state(id):
	var dict = {
		visible = visible,
		energy = energy,
		color = color,
		global_position = global_position,
		scale = scale,
	}
	Global.settings_dict.light_states[id] = dict

func get_state(state):
	if not Global.settings_dict.light_states[state].is_empty():
		var dict = Global.settings_dict.light_states[state]
		energy = dict.energy
		color = dict.color
		global_position = dict.global_position
		scale = dict.scale
		visible = dict.visible
		$Grab.modulate = color

func _on_grab_button_down():
	if $Grab.visible:
		of = get_global_mouse_position() - global_position
		dragging = true

func _on_grab_button_up():
	dragging = false
	save_state(Global.current_state)
