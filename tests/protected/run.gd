extends Node

var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + label)

func _ready() -> void:
	call_deferred("run")

func quit(code: int) -> void:
	get_tree().quit(code)

func run() -> void:
	var path := "res://Protected/ProtectedCodec.gd"
	if not ResourceLoader.exists(path):
		check(false, "protected codec is not implemented")
		quit(1)
		return
	var codec = load(path).new()
	var keys := {"enc": PackedByteArray(), "mac": PackedByteArray(), "id": PackedByteArray()}
	keys.enc.resize(32)
	keys.enc.fill(17)
	keys.mac.resize(32)
	keys.mac.fill(29)
	keys.id.resize(16)
	keys.id.fill(3)
	var payload := "private motion data 测试".to_utf8_buffer()
	var sealed: Dictionary = codec.seal(payload, keys)
	check(sealed.ok, "seal")
	if not sealed.ok:
		quit(1)
		return
	check(codec.open(sealed.value, keys).value == payload, "roundtrip")
	check(codec.seal(payload, keys).value != sealed.value, "random IV")
	for at in [0, 8, 16, 30, 50, sealed.value.size() - 1]:
		var bad: PackedByteArray = sealed.value.duplicate()
		bad[at] ^= 1
		check(not codec.open(bad, keys).ok, "tamper rejected at " + str(at))
	check(not codec.open(sealed.value.slice(0, 25), keys).ok, "truncation")
	var trailing: PackedByteArray = sealed.value.duplicate()
	trailing.append(0)
	check(not codec.open(trailing, keys).ok, "trailing bytes")
	var wrong := keys.duplicate(true)
	wrong.mac[0] = 99
	check(not codec.open(sealed.value, wrong).ok, "wrong authentication key")
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4".hex_decode(), "000102030405060708090a0b0c0d0e0f".hex_decode())
	check(aes.update("6bc1bee22e409f96e93d7e117393172a".hex_decode()).hex_encode() == "f58c4c04d6e5f1ba779eabfb5f7bfbd6", "NIST AES-256-CBC vector")
	aes.finish()
	if ResourceLoader.exists("res://Protected/ProtectedSchema.gd"):
		var schema = load("res://Protected/ProtectedSchema.gd").new()
		var event := InputEventKey.new()
		event.keycode = KEY_A
		event.ctrl_pressed = true
		var source := {"version":"1.4.5", "sprites_array":[], "settings_dict":{"states":[{}]}, "input_array":[{"hot_key":event}], "image_manager_data":[], "test": [Vector2(2,3), Color.RED, PackedByteArray([1,2])]}
		var encoded: Dictionary = schema.encode_model(source)
		check(encoded.ok, "schema encode")
		if encoded.ok:
			var decoded: Dictionary = schema.decode_model(encoded.value)
			check(decoded.ok, "schema decode")
			if decoded.ok:
				check(decoded.value.test == source.test, "Godot value types preserved")
				check(decoded.value.input_array[0].hot_key.keycode == KEY_A and decoded.value.input_array[0].hot_key.ctrl_pressed, "key event preserved")
		source.test.append(Resource.new())
		check(not schema.encode_model(source).ok, "arbitrary Resource rejected")
	else:
		check(false, "schema not implemented")
	if not ResourceLoader.exists("res://Protected/ProtectedSession.gd"):
		check(false, "protected export/load session not implemented")
	else:
		await integration()
	if failures == 0:
		print("PROTECTED TESTS PASSED")
	quit(0 if failures == 0 else 1)

func integration() -> void:
	var scene = load("res://Main/main.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(0.5).timeout
	await SaveAndLoad.load_model("res://DemoModels/PickleModel.pngRemix")
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	load("res://tests/protected/drag_snap_regression.gd").new().run(check)
	var session = get_node("/root/ProtectedSession")
	var old_path: String = Global.save_path
	DirAccess.make_dir_recursive_absolute("res://tests/protected/out")
	var export_path := "res://tests/protected/out/测试 protected.pngRemixProtected"
	check(session.export_protected(export_path, true) == OK, "export demo")
	check(Global.save_path == old_path, "export preserves source path")
	var io = load("res://Protected/ProtectedIO.gd").new()
	var original: Dictionary = io.read_container(export_path)
	check(original.ok, "read exported file")
	check(not io.write_container(export_path, PackedByteArray([1]), false).ok, "overwrite denied")
	check(io.read_container(export_path).value == original.value, "overwrite leaves original intact")
	check(session.inspect_file(export_path).ok, "real demo roundtrip schema")
	var model: Dictionary = session.inspect_file(export_path).value
	var schema = load("res://Protected/ProtectedSchema.gd").new()
	var invalid := model.duplicate(true)
	invalid.settings_dict.monitor = "invalid monitor"
	check(not schema.encode_model(invalid).ok, "invalid settings type rejected before scene replacement")
	invalid = model.duplicate(true)
	invalid.input_array = [42]
	check(not schema.encode_model(invalid).ok, "malformed state binding rejected before replacement")
	invalid = model.duplicate(true)
	invalid.settings_dict.cycles = [{}]
	check(not schema.encode_model(invalid).ok, "malformed cycle rejected before replacement")
	invalid = model.duplicate(true)
	invalid.sprites_array[0].parent_id = invalid.sprites_array[0].sprite_id
	check(not schema.encode_model(invalid).ok, "parent cycle rejected before scene replacement")
	invalid = model.duplicate(true)
	invalid.image_manager_data[0].runtime_texture = PackedByteArray([1,2,3])
	check(not schema.encode_model(invalid).ok, "invalid image rejected before scene replacement")
	load("res://tests/protected/mouse_hotkey_regression.gd").new().run(check)
	load("res://tests/protected/asset_hotkey_regression.gd").new().run(check)
	load("res://tests/protected/cycle_hotkey_regression.gd").new().run(check)
	var prefs = load("res://Protected/PlayerSettings.gd").new()
	check(prefs.save_preferences("test", {"microphone":"Default", "zoom":2.0, "secret_parameter": 4}) == OK, "save player preferences")
	var restored: Dictionary = prefs.load_preferences("test")
	check(restored.get("zoom") == 2.0 and not restored.has("secret_parameter"), "preferences whitelist")
	var policy = get_node("/root/ProtectionPolicy")
	# Editor-only test override is not available in exported player/creator.
	ProjectSettings.set_setting("protected/player", true)
	for action in ["edit_model", "save_model", "backup_model", "export_assets", "import_assets", "remote_control"]:
		check(not policy.allows(action), "deny " + action)
	var denied := "user://must-not-exist.pngRemix"
	SaveAndLoad.save_model(denied)
	check(not FileAccess.file_exists(denied), "direct model save denied")
	check(await session.load_protected(export_path) == OK, "load protected demo")
	var count := get_tree().get_nodes_in_group("Sprites").size()
	check(count > 0, "demo sprites instantiated")
	var bad_path := "user://damaged.pngRemixProtected"
	io.write_container(bad_path, PackedByteArray([1,2,3]), true)
	check(await session.load_protected(bad_path) != OK, "damaged model rejected")
	check(get_tree().get_nodes_in_group("Sprites").size() == count, "failure preserves scene")
	var backup_dir := "res://tests/protected/out/forbidden-backups"
	SaveAndLoad.backs_dir = backup_dir
	SaveAndLoad.dire = "res://tests/protected/out/forbidden-images"
	Settings.autosave_location = "res://tests/protected/out/forbidden-autosaves"
	SaveAndLoad.save_backup(model, "private.pngRemix")
	SaveAndLoad.export_images()
	Settings.auto_save()
	check(not DirAccess.dir_exists_absolute(backup_dir), "backup creates no directory")
	check(not DirAccess.dir_exists_absolute(SaveAndLoad.dire), "image export denied")
	check(not DirAccess.dir_exists_absolute(Settings.autosave_location), "autosave denied")
	check(WebsocketHandler.listen(19321) == ERR_UNAUTHORIZED, "websocket cannot listen")
	Global.set_mode(0)
	check(Global.mode == 1, "player cannot enter editor mode")
	var buttons := get_tree().get_nodes_in_group("StateButtons")
	check(buttons.size() == model.settings_dict.states.size(), "protected load has exact state count")
	if buttons.size() > 1:
		var event := InputEventKey.new()
		event.keycode = KEY_F9
		buttons[1].saved_event = event
		buttons[1].update_stuff()
		var ui = get_node("/root/ProtectedUI")
		ui.hotkeys = {str(buttons[0].state): KEY_F9}
		ui.apply_hotkeys()
		check(InputMap.action_get_events(buttons[1].input_key).is_empty(), "remap removes conflicting default state key")
		ui.hotkeys = {str(buttons[0].state): KEY_F10}
		ui.apply_hotkeys()
		check(InputMap.action_get_events(buttons[1].input_key).size() == 1, "changing override restores released default key")
	load("res://tests/protected/mouse_hotkey_regression.gd").new().integration(check)
	load("res://tests/protected/asset_hotkey_regression.gd").new().integration(check)
	load("res://tests/protected/cycle_hotkey_regression.gd").new().integration(check)
	var settings_ui = get_node("/root/ProtectedUI")
	settings_ui.threshold = HSlider.new()
	settings_ui.threshold.max_value = 1
	settings_ui.threshold.step = 0.01
	settings_ui.transparent = CheckButton.new()
	Global.settings_dict.volume_limit = 0.37
	Global.settings_dict.is_transparent = true
	settings_ui.sync_preferences_controls()
	check(is_equal_approx(settings_ui.threshold.value, 0.37) and settings_ui.transparent.button_pressed, "restored settings synchronize visible controls")
	settings_ui.threshold.free()
	settings_ui.transparent.free()
	settings_ui.threshold = null
	settings_ui.transparent = null
	var invalid_header := PackedByteArray()
	invalid_header.resize(109)
	var header_path := "res://tests/protected/out/invalid-header.bin"
	io.write_container(header_path, invalid_header, true)
	check(not io.read_container(header_path).ok, "IO rejects invalid header before payload read")
	await motion_roundtrip(scene, model, export_path)
	ProjectSettings.set_setting("protected/player", false)

func motion_roundtrip(scene: Node, model: Dictionary, path: String) -> void:
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	Global.set_process(false)
	Global.blink_timer.stop()
	seed(12345)
	Global.tick = 0.0
	await SaveAndLoad.apply_protected_data(model)
	await get_tree().create_timer(0.1).timeout
	var before := trace_motion()
	seed(12345)
	Global.tick = 0.0
	check(await get_node("/root/ProtectedSession").load_protected(path) == OK, "motion fixture load")
	await get_tree().create_timer(0.1).timeout
	var after := trace_motion()
	check(before.size() == after.size() and before.size() > 0, "motion sample count")
	var max_error := 0.0
	for i in mini(before.size(), after.size()):
		max_error = maxf(max_error, before[i].distance_to(after[i]))
	check(max_error < 0.0001, "300-frame motion roundtrip error=" + str(max_error))
	print("MOTION samples=", before.size(), " max_error=", max_error)

func trace_motion() -> Array[Vector3]:
	var trace: Array[Vector3] = []
	var sprites := get_tree().get_nodes_in_group("Sprites")
	for frame in 300:
		Global.tick = float(frame) / 60.0
		Global.mouth = Global.Mouth.Open if frame % 120 > 60 else Global.Mouth.Closed
		for sprite in sprites:
			var movement = sprite.get_node_or_null("%Movements")
			if movement != null:
				movement._physics_process(1.0 / 60.0)
				var node = sprite.get_node("%Modifier")
				trace.append(Vector3(node.position.x, node.position.y, node.rotation))
	return trace
