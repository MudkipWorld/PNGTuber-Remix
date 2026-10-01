extends PointLight2D

var of = 0
var dragging


func _ready():
	# 灯光设置面板（LightControl）已自监听 Global.light_info 刷新控件，
	# 不再需要本节点直接寻址 UI（旧路径 Main/%Control/%HBox25 与 /LightControl 在重构后已失效）。
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

func _on_grab_button_down():
	if $Grab.visible:
		of = get_global_mouse_position() - global_position
		dragging = true

func _on_grab_button_up():
	dragging = false
	save_state(Global.current_state)
