extends RefCounted

const EVENTS := {
	"InputEventKey": ["device", "keycode", "physical_keycode", "key_label", "unicode", "location", "ctrl_pressed", "alt_pressed", "shift_pressed", "meta_pressed", "pressed", "echo"],
	"InputEventMouseButton": ["device", "button_index", "pressed", "double_click", "ctrl_pressed", "alt_pressed", "shift_pressed", "meta_pressed", "factor", "position", "global_position", "button_mask"],
	"InputEventJoypadButton": ["device", "button_index", "pressed", "pressure"],
	"InputEventJoypadMotion": ["device", "axis", "axis_value"]
}
var error := ""
var budget := 0

func result(value: Variant) -> Dictionary:
	return {"ok": error.is_empty(), "value": value if error.is_empty() else null, "error": error}

func transform_value(value: Variant, decoding: bool, depth: int = 0) -> Variant:
	budget += 1
	if depth > 64 or budget > 2000000:
		error = "Model nesting or element limit exceeded"
		return null
	if value is Object:
		if decoding or not value is InputEvent or value.get_script() != null or not EVENTS.has(value.get_class()):
			error = "Unsupported object in model"
			return null
		var fields := {}
		for field in EVENTS[value.get_class()]:
			fields[field] = value.get(field)
		return {"__protected_event__": value.get_class(), "fields": fields}
	if value is Dictionary:
		if value.has("__protected_event__"):
			if not decoding or value.size() != 2 or not value.get("fields") is Dictionary or not EVENTS.has(value["__protected_event__"]):
				error = "Invalid input event"
				return null
			var event: InputEvent
			match value["__protected_event__"]:
				"InputEventKey": event = InputEventKey.new()
				"InputEventMouseButton": event = InputEventMouseButton.new()
				"InputEventJoypadButton": event = InputEventJoypadButton.new()
				"InputEventJoypadMotion": event = InputEventJoypadMotion.new()
			for field in value.fields:
				if not EVENTS[value["__protected_event__"]].has(field) or typeof(event.get(field)) != typeof(value.fields[field]):
					error = "Invalid input event field"
					return null
				event.set(field, value.fields[field])
			return event
		var out := {}
		for key in value:
			if not (key is String or key is StringName or key is int):
				error = "Unsupported dictionary key"
				return null
			out[key] = transform_value(value[key], decoding, depth + 1)
		return out
	if value is Array:
		var out := []
		for item in value:
			out.append(transform_value(item, decoding, depth + 1))
		return out
	if typeof(value) in [TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID]:
		error = "Unsupported runtime value"
		return null
	return value

func valid_id(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value) and absf(value) < 9007199254740992.0 and value == floor(value))

func compatible(value: Variant, default: Variant) -> bool:
	if default == null:
		return value == null or value is InputEvent or (value is Dictionary and value.has("__protected_event__"))
	if default is float or default is int:
		return (value is float or value is int) and is_finite(float(value))
	return typeof(value) == typeof(default)

func valid_fields(values: Dictionary, defaults: Dictionary) -> bool:
	for key in values:
		if defaults.has(key) and not compatible(values[key], defaults[key]):
			return false
	return true

func valid_event(value: Variant) -> bool:
	if value == null:
		return true
	if value is InputEvent:
		return value.get_script() == null and EVENTS.has(value.get_class())
	return value is Dictionary and value.size() == 2 and value.get("__protected_event__") is String and EVENTS.has(value["__protected_event__"]) and value.get("fields") is Dictionary

func valid_model(model: Variant) -> bool:
	if not model is Dictionary or model.get("version") != "1.4.5":
		return false
	for key in ["sprites_array", "input_array", "image_manager_data"]:
		if not model.get(key) is Array:
			return false
	if not model.get("settings_dict") is Dictionary or not model.settings_dict.get("states") is Array or model.settings_dict.states.is_empty():
		return false
	var global = Engine.get_main_loop().root.get_node_or_null("Global")
	if global != null and not valid_fields(model.settings_dict, global.settings_dict):
		return false
	if model.settings_dict.get("blink_chance", 1) < 1 or model.settings_dict.get("blink_speed", 1) <= 0:
		return false
	for state in model.settings_dict.states:
		if not state is Dictionary:
			return false
	for input in model.input_array:
		if input is Dictionary and not input.has("__protected_event__"):
			if not input.get("state_name", "") is String or not valid_event(input.get("hot_key")):
				return false
		elif not valid_event(input):
			return false
	for cycle in model.settings_dict.get("cycles", []):
		if not cycle is Dictionary or not cycle.get("sprites") is Array or not valid_id(cycle.get("pos")) or not valid_id(cycle.get("last_sprite")) or not cycle.get("active") is bool:
			return false
		for id in cycle.sprites:
			if not valid_id(id): return false
		for key in ["toggle", "forward", "backward"]:
			if not valid_event(cycle.get(key)): return false
	var sprite_defaults: Dictionary = load("res://Scripts/Objects/SpriteObjectClass.gd").DEFAULT_DATA
	var ids := {}
	var parents := {}
	var images := {}
	for image in model.image_manager_data:
		if not image is Dictionary or not image.get("id") is int or images.has(image.id):
			return false
		var png = image.get("runtime_texture")
		if not valid_fields(image, {"img_animated":false, "is_apng":false, "offset":Vector2.ZERO, "image_name":"", "trimmed":false, "sprite_sheet":false}):
			return false
		if not png is PackedByteArray or png.size() < 24 or png.slice(0,8).hex_encode() != "89504e470d0a1a0a":
			return false
		var dimensions := StreamPeerBuffer.new()
		dimensions.big_endian = true
		dimensions.data_array = png.slice(16,24)
		var width := dimensions.get_u32()
		var height := dimensions.get_u32()
		if width < 1 or height < 1 or width > 16384 or height > 16384 or width * height > 67108864:
			return false
		var probe := Image.new()
		if probe.load_png_from_buffer(png) != OK:
			return false
		images[image.id] = true
	for sprite in model.sprites_array:
		if not sprite is Dictionary or not sprite.get("states") is Array or sprite.states.is_empty() or not sprite.has("sprite_id") or ids.has(sprite.sprite_id):
			return false
		ids[sprite.sprite_id] = true
		if not valid_id(sprite.sprite_id) or not valid_id(sprite.get("parent_id")) or not sprite.get("sprite_name") is String:
			return false
		parents[int(sprite.sprite_id)] = int(sprite.parent_id)
		if not valid_fields(sprite, {"is_asset":false, "was_active_before":false, "should_disappear":false, "hold_to_show":false, "is_collapsed":false, "flipped_h":false, "flipped_v":false, "layer_color":Color.WHITE, "saved_event":null, "saved_disappear":[], "sprite_type":"", "rest_mode":1, "rotated":0}):
			return false
		if not valid_event(sprite.get("saved_event")):
			return false
		for event in sprite.get("saved_disappear", []):
			if event == null or not valid_event(event): return false
		if sprite.states.size() != model.settings_dict.states.size():
			return false
		for state in sprite.states:
			if not state is Dictionary or not valid_fields(state, sprite_defaults):
				return false
		if not sprite.states[0].get("folder", false) and sprite.get("sprite_type") != "Comment" and not images.has(sprite.get("image_id")):
			return false
		if sprite.get("sprite_type") == "Mesh":
			for key in ["original_vertices", "internal_vertices", "base_vertices"]:
				if not sprite.get(key) is PackedVector2Array:
					return false
			if not sprite.get("triangles") is PackedInt32Array or not sprite.get("deform_layers") is Array:
				return false
	for id in parents:
		var seen := {}
		var cursor: int = id
		while parents.has(cursor):
			if seen.has(cursor):
				return false
			seen[cursor] = true
			cursor = parents[cursor]
	return true

func encode_model(model: Dictionary) -> Dictionary:
	error = ""
	budget = 0
	if not valid_model(model):
		error = "Invalid model structure or version (requires 1.4.5)"
		return result(null)
	var safe = transform_value(model, false)
	return result(var_to_bytes(safe) if error.is_empty() else null)

func decode_model(payload: PackedByteArray) -> Dictionary:
	error = ""
	budget = 0
	var safe = bytes_to_var(payload)
	if not valid_model(safe):
		error = "Invalid protected model structure"
		return result(null)
	return result(transform_value(safe, true))
