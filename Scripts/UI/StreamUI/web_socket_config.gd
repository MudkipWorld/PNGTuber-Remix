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
	%OSFPosStrength.value = Settings.theme_settings.osf_pos_stren
	%OSFPosMouth.value = Settings.theme_settings.osf_mouth_strength
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

func _on_udp_port_value_value_changed(value: float) -> void:
	Tracker.listen_port = int(value)

func _on_udp_start_button_pressed() -> void:
	Tracker.start_backend()
	disable_udp_spinbox(true)

func _on_udp_stop_button_pressed() -> void:
	Tracker.stop_backend()
	disable_udp_spinbox(false)

func disable_udp_spinbox(toggle : bool):
	%UDPPortValue.editable = !toggle
	%UDPStartButton.disabled = toggle
	%UDPStopButton.disabled = !toggle


func _on_spin_box_value_changed(value: float) -> void:
	TrackingBackend.osf_pos_strength = value
	if can_change:
		Settings.theme_settings.osf_pos_stren = value
		Settings.save()


func _on_osf_pos_mouth_value_changed(value: float) -> void:
	TrackingBackend.osf_mouth_strength = value
	if can_change:
		Settings.theme_settings.osf_mouth_strength = value
		Settings.save()
