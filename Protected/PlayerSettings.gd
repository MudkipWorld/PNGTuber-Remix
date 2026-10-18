extends RefCounted

const ALLOWED := {"microphone": TYPE_STRING, "volume_limit": TYPE_FLOAT, "sensitivity_limit": TYPE_FLOAT, "zoom": TYPE_FLOAT, "pan_x": TYPE_FLOAT, "pan_y": TYPE_FLOAT, "transparent": TYPE_BOOL, "hotkeys": TYPE_DICTIONARY, "asset_hotkeys": TYPE_DICTIONARY, "cycle_hotkeys": TYPE_DICTIONARY}

func clean(values: Dictionary) -> Dictionary:
	var result := {}
	for key in ALLOWED:
		if not values.has(key) or typeof(values[key]) != ALLOWED[key]:
			continue
		if values[key] is float and not is_finite(values[key]):
			continue
		result[key] = values[key]
	if result.has("zoom"):
		result.zoom = clampf(result.zoom, 0.01, 15.0)
	if result.has("volume_limit"):
		result.volume_limit = clampf(result.volume_limit, 0.0, 1.0)
	if result.has("sensitivity_limit"):
		result.sensitivity_limit = clampf(result.sensitivity_limit, 0.0, 10.0)
	for group in ["hotkeys", "asset_hotkeys"]:
		if result.has(group):
			var safe := {}
			for state in result[group]:
				var key = result[group][state]
				if state is String and state.is_valid_int() and int(state) >= 0 and binding_event(key) != null:
					safe[state] = key
			result[group] = safe
	if result.has("cycle_hotkeys"):
		var safe := {}
		for key in result.cycle_hotkeys:
			if not key is String: continue
			var parts = key.split(":")
			if parts.size() == 2 and parts[0].is_valid_int() and int(parts[0]) >= 0 and parts[1] in ["toggle", "forward", "backward"] and binding_event(result.cycle_hotkeys[key]) != null:
				safe[key] = result.cycle_hotkeys[key]
		result.cycle_hotkeys = safe
	return result

func location(model_id: String) -> String:
	return "user://player-" + model_id.sha256_text() + ".dat"

func load_preferences(model_id: String) -> Dictionary:
	var file := FileAccess.open(location(model_id), FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return {}
	var data = file.get_var(false)
	return clean(data) if data is Dictionary else {}

func save_preferences(model_id: String, values: Dictionary) -> Error:
	var file := FileAccess.open(location(model_id), FileAccess.WRITE)
	if file == null:
		return ERR_CANT_CREATE
	file.store_var(clean(values), false)
	return file.get_error()

static func binding_event(binding: Variant) -> InputEvent:
	if binding is int:
		var code: int = binding & KEY_CODE_MASK
		if binding < 0 or binding >= 0x80000000 or code == KEY_NONE or code == KEY_UNKNOWN:
			return null
		var event := InputEventKey.new()
		event.keycode = code
		event.ctrl_pressed = bool(binding & KEY_MASK_CTRL)
		event.alt_pressed = bool(binding & KEY_MASK_ALT)
		event.shift_pressed = bool(binding & KEY_MASK_SHIFT)
		event.meta_pressed = bool(binding & KEY_MASK_META)
		return event
	if binding is Dictionary and binding.get("type") == "mouse":
		if not binding.get("button") is int or binding.button < MOUSE_BUTTON_LEFT or binding.button > MOUSE_BUTTON_XBUTTON2:
			return null
		for key in binding:
			if key not in ["type", "button", "ctrl", "alt", "shift", "meta"]:
				return null
		for key in ["ctrl", "alt", "shift", "meta"]:
			if not binding.get(key, false) is bool:
				return null
		var event := InputEventMouseButton.new()
		event.button_index = binding.button
		event.ctrl_pressed = binding.get("ctrl", false)
		event.alt_pressed = binding.get("alt", false)
		event.shift_pressed = binding.get("shift", false)
		event.meta_pressed = binding.get("meta", false)
		return event
	return null

static func event_binding(event: InputEvent) -> Variant:
	if event is InputEventKey:
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return null
		var code: int = event.get_keycode_with_modifiers()
		return code if binding_event(code) != null else null
	if event is InputEventMouseButton:
		var binding := {"type": "mouse", "button": event.button_index, "ctrl": event.ctrl_pressed, "alt": event.alt_pressed, "shift": event.shift_pressed, "meta": event.meta_pressed}
		return binding if binding_event(binding) != null else null
	return null
