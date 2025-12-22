extends VBoxContainer

var can_change : bool = false

func _ready() -> void:
	WebsocketHandler.port_state.connect(disable_spinbox)
	await get_tree().current_scene.ready
	await get_tree().create_timer(0.1).timeout
	check_websocket()

func disable_spinbox(toggle : bool):
	%PortValue.editable = !toggle
	%StartButton.disabled = toggle
	%StopButton.disabled = !toggle

func _on_start_button_pressed() -> void:
	WebsocketHandler.start_websocket_server()
	disable_spinbox(true)

func _on_stop_button_pressed() -> void:
	WebsocketHandler.stop()
	disable_spinbox(false)

func _on_port_value_value_changed(value: float) -> void:
	WebsocketHandler.port = int(value)
	Settings.theme_settings.websocket_id = int(value)
	if can_change:
		Settings.save()

func check_websocket():
	%PortValue.value = int(Settings.theme_settings.websocket_id)
	WebsocketHandler.port = int(Settings.theme_settings.websocket_id)
	%AutoStartWebsocket.button_pressed = Settings.theme_settings.auto_activate_websocket
	if Settings.theme_settings.auto_activate_websocket:
		WebsocketHandler.start_websocket_server()
		disable_spinbox(true)
	else:
		disable_spinbox(false)
	can_change = true

func _on_auto_start_websocket_toggled(toggled_on: bool) -> void:
	Settings.theme_settings.auto_activate_websocket = toggled_on
	if can_change:
		Settings.save()
