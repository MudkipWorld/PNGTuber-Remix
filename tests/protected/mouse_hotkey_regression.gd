extends RefCounted
func run(check: Callable) -> void:
	var prefs = load("res://Protected/PlayerSettings.gd").new()
	var cleaned = prefs.clean({"hotkeys": {"0": KEY_UNKNOWN, "1": KEY_SPACE, "2": 0}})
	check.call(not cleaned.hotkeys.has("0") and not cleaned.hotkeys.has("2"), "unknown and empty overrides cannot erase author mouse binding")
	check.call(cleaned.hotkeys.get("1") == KEY_SPACE, "valid existing keyboard preference preserved")
	var mouse = {"type": "mouse", "button": MOUSE_BUTTON_RIGHT, "ctrl": false, "alt": false, "shift": false, "meta": false}
	cleaned = prefs.clean({"hotkeys": {"0": mouse}})
	check.call(cleaned.hotkeys.get("0") == mouse, "right mouse preference survives validation")

func integration(check: Callable) -> void:
	var ui = Engine.get_main_loop().root.get_node("ProtectedUI")
	var buttons = Engine.get_main_loop().get_nodes_in_group("StateButtons")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	buttons[0].saved_event = right
	ui.default_events.clear()
	ui.hotkeys = {str(buttons[0].state): KEY_UNKNOWN}
	ui.apply_hotkeys()
	check.call(InputMap.action_has_event(buttons[0].input_key, right), "invalid old override preserves original right mouse action")
	ui.states = OptionButton.new()
	ui.key_edit = LineEdit.new()
	ui.add_child(ui.states)
	ui.add_child(ui.key_edit)
	for button in buttons:
		ui.states.add_item(button.state_name)
	ui.states.select(0)
	ui.refresh_hotkey()
	check.call(ui.key_edit.text.contains("Right mouse"), "original mouse binding displayed")
	ui.states.select(1)
	right.pressed = true
	ui.bind_key(right)
	check.call(InputMap.action_has_event(buttons[1].input_key, right), "mouse capture installs selected state action")
	check.call(not InputMap.action_has_event(buttons[0].input_key, right), "mouse override removes duplicate default")
	var prefs = load("res://Protected/PlayerSettings.gd").new()
	check.call(prefs.save_preferences("mouse-regression", {"hotkeys": ui.hotkeys}) == OK, "mouse preferences saved")
	var restored = prefs.load_preferences("mouse-regression")
	check.call(restored.hotkeys == ui.hotkeys, "mouse preferences survive disk reload")
	ui.restore_binding()
	check.call(InputMap.action_has_event(buttons[0].input_key, right), "restore releases right mouse back to original state")
	ui.states.queue_free()
	ui.key_edit.queue_free()
	ui.states = null
	ui.key_edit = null
