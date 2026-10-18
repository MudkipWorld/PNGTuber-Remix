extends RefCounted
func run(check: Callable) -> void:
	var prefs = load("res://Protected/PlayerSettings.gd").new()
	var values = {"asset_hotkeys": {"123": KEY_F8, "124": {"type": "mouse", "button": MOUSE_BUTTON_RIGHT}, "125": KEY_UNKNOWN}}
	var clean = prefs.clean(values)
	check.call(clean.get("asset_hotkeys", {}).get("123") == KEY_F8, "asset key preference accepted")
	check.call(clean.get("asset_hotkeys", {}).get("124") == values.asset_hotkeys["124"], "asset mouse preference accepted")
	check.call(not clean.get("asset_hotkeys", {}).has("125"), "invalid asset override rejected")

func integration(check: Callable) -> void:
	var tree = Engine.get_main_loop()
	var sprites = tree.get_nodes_in_group("Sprites")
	var actor = sprites[0]
	var old_asset = actor.is_asset
	var old_event = actor.saved_event
	var old_hold = actor.hold_to_show
	var old_show = actor.show_only
	var action = str(actor.sprite_id)
	var old_events = InputMap.action_get_events(action).duplicate(true)
	actor.is_asset = true
	actor.hold_to_show = true
	var original := InputEventKey.new()
	original.keycode = KEY_F7
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, original)
	var panel = load("res://Protected/AssetBindings.gd").new()
	tree.root.add_child(panel)
	panel.refresh_model()
	var id := str(int(actor.sprite_id))
	check.call(panel.actors.has(id), "switchable asset listed by stable id")
	panel.resources.select(0)
	for index in panel.resources.item_count:
		if panel.resources.get_item_metadata(index) == id: panel.resources.select(index)
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	panel.bind_input(right)
	check.call(InputMap.action_has_event(action, right), "resource mouse binding updates runtime action")
	check.call(actor.saved_event == old_event and actor.hold_to_show and actor.show_only == old_show, "resource rebinding preserves author data and behavior")
	var prefs = load("res://Protected/PlayerSettings.gd").new()
	prefs.save_preferences("asset-regression", {"asset_hotkeys": panel.bindings})
	panel.bindings = prefs.load_preferences("asset-regression").asset_hotkeys
	panel.apply_bindings()
	check.call(InputMap.action_has_event(action, right), "resource binding survives disk reload")
	panel.restore_binding()
	check.call(InputMap.action_has_event(action, original) and not InputMap.action_has_event(action, right), "resource restore recovers original action")
	panel.bindings = {id: KEY_F8}
	panel.refresh_model()
	check.call(panel.bindings.is_empty(), "loading another model clears cached overrides")
	panel.queue_free()
	actor.is_asset = old_asset
	actor.hold_to_show = old_hold
	InputMap.action_erase_events(action)
	for event in old_events: InputMap.action_add_event(action, event)
