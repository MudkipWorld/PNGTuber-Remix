extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().current_scene.ready
	sliders_revalue(Global.settings_dict)
	Global.reinfo.connect(info_held)
	Global.slider_values.connect(sliders_revalue)
	Global.deselect.connect(info_desel)
	%CreditLabel.text = "PNGTuber Remix by TheMime (MudkipWorld). Better UI by LeoRson. Websocket code by vj4. V" + Global.version
	get_window().size_changed.connect(update_size_label)

func info_held():
	%DeselectButton.show()

func info_desel():
	%DeselectButton.hide()

func sliders_revalue(settings_dict):
	%BGColorPicker.color = settings_dict.bg_color
	$TopBarInput.origin_alias()
	if Global.camera != null && is_instance_valid(Global.camera):
		Global.camera.zoom = settings_dict.zoom
		Global.camera.get_parent().global_position = settings_dict.pan
	update_fps(settings_dict.max_fps)
	if Global.settings_dict.auto_save:
		Settings.save_timer.start()

func update_fps(value):
	if value == 241:
		Engine.max_fps = 0
		return
	Engine.max_fps = value

func update_size_label():
	%WindowSize.text = "Window Size " + str(get_window().size)
