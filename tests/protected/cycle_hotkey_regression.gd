extends RefCounted
func run(check: Callable) -> void:
	var prefs = load("res://Protected/PlayerSettings.gd").new()
	var clean = prefs.clean({"cycle_hotkeys": {"0:forward": KEY_F8, "0:toggle": {"type":"mouse", "button":MOUSE_BUTTON_RIGHT}, "0:sprites": KEY_F9, "1:backward": KEY_UNKNOWN}})
	check.call(clean.get("cycle_hotkeys", {}).get("0:forward") == KEY_F8, "cycle forward preference accepted")
	check.call(clean.get("cycle_hotkeys", {}).has("0:toggle"), "cycle mouse toggle preference accepted")
	check.call(not clean.get("cycle_hotkeys", {}).has("0:sprites") and not clean.get("cycle_hotkeys", {}).has("1:backward"), "invalid cycle preferences rejected")

func integration(check: Callable) -> void:
	var original_cycles = Global.settings_dict.cycles
	var original := InputEventKey.new()
	original.keycode = KEY_F6
	Global.settings_dict.cycles = [{"sprites": [101,102], "toggle": original, "forward": null, "backward": null, "active": false, "pos": 0, "last_sprite":101}]
	var panel = load("res://Protected/CycleBindings.gd").new()
	Engine.get_main_loop().root.add_child(panel)
	panel.refresh_model()
	check.call(panel.cycles.item_count == 1 and panel.actions.item_count == 3, "cycle picker includes three actions")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	panel.bind_input(right)
	check.call(panel.has_override(0, "toggle") and InputMap.action_has_event(panel.action_name("0:toggle"), right), "cycle mouse override installed")
	check.call(Global.settings_dict.cycles[0].toggle == original and Global.settings_dict.cycles[0].sprites == [101,102], "cycle override preserves author configuration")
	var prefs = load("res://Protected/PlayerSettings.gd").new()
	prefs.save_preferences("cycle-regression", {"cycle_hotkeys": panel.bindings})
	panel.bindings = prefs.load_preferences("cycle-regression").cycle_hotkeys
	panel.apply_bindings()
	check.call(panel.has_override(0, "toggle"), "cycle binding survives reload")
	panel.restore_binding()
	check.call(not panel.has_override(0, "toggle") and panel.binding_edit.text.contains("F6"), "restore falls back to original cycle binding")
	panel.actions.select(1)
	panel.bind_input(right)
	check.call(panel.has_override(0, "forward") and not panel.has_override(0, "toggle"), "cycle actions are independently configurable")
	var handler = Engine.get_main_loop().root.get_node("GlobInput/Cycle")
	var cycle = Global.settings_dict.cycles[0]
	handler.toggle_forward(cycle)
	check.call(cycle.pos == 1 and cycle.last_sprite == 102 and cycle.active, "forward keeps original order")
	handler.toggle_backward(cycle)
	check.call(cycle.pos == 0 and cycle.last_sprite == 101, "backward keeps original order")
	handler.toggle_cycle(cycle)
	check.call(not cycle.active, "toggle disables active cycle")
	Global.settings_dict.cycles = []
	panel.refresh_model()
	check.call(not InputMap.has_action(panel.action_name("0:forward")) and panel.bindings.is_empty(), "model switch removes old cycle overrides")
	panel.queue_free()
	Global.settings_dict.cycles = original_cycles
