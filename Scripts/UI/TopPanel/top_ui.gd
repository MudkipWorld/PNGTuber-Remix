extends Control

signal settings_applied(settings_dict: Dictionary)

@onready var bg_color_picker: ColorPicker = %BGColorPicker
@onready var credit_label: Label = %CreditLabel
@onready var window_size_label: Label = %WindowSize
@onready var top_bar_input: Node = $TopBarInput
@onready var deselect_button: Button = %DeselectButton


func _ready() -> void:
	await get_tree().current_scene.ready
	_apply_settings_to_ui(Global.settings_dict)

	Global.reinfo.connect(_on_info_held)
	Global.slider_values.connect(_on_slider_values)
	Global.deselect.connect(_on_info_deselected)

	credit_label.text = tr("TR_CREDITS") + Global.version
	get_window().size_changed.connect(_on_window_size_changed)


func _on_info_held() -> void:
	deselect_button.show()


func _on_info_deselected() -> void:
	deselect_button.hide()


func _on_slider_values(settings_dict: Dictionary) -> void:
	_apply_settings_to_ui(settings_dict)
	settings_applied.emit(settings_dict)


func _apply_settings_to_ui(settings_dict: Dictionary) -> void:
	bg_color_picker.color = settings_dict.bg_color
	if top_bar_input != null and is_instance_valid(top_bar_input):
		(top_bar_input as Node).call("origin_alias")
	if Global.camera != null and is_instance_valid(Global.camera):
		Global.camera.zoom = settings_dict.zoom
		if Global.camera.get_parent() != null:
			Global.camera.get_parent().global_position = settings_dict.pan
	_update_fps(settings_dict.max_fps)
	if Global.settings_dict.auto_save:
		Settings.save_timer.start()


func _update_fps(value: int) -> void:
	if value == 241:
		Engine.max_fps = 0
	else:
		Engine.max_fps = value


func _on_window_size_changed() -> void:
	window_size_label.text = "Window Size " + str(get_window().size)


func _unhandled_input(event: InputEvent) -> void:
	if Global.mode != 0:
		return
	if event.is_action_pressed("ui_undo"):
		UndoRedoManager.undo()
	elif event.is_action_pressed("ui_redo"):
		UndoRedoManager.redo()
