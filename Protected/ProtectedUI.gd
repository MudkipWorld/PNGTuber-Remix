extends CanvasLayer

const Preferences = preload("res://Protected/PlayerSettings.gd")
var panel: VBoxContainer
var dialog: FileDialog
var status: Label
var states: OptionButton
var key_edit: LineEdit
var hotkeys := {}
var default_events := {}
var loading := false
var asset_bindings: VBoxContainer
var cycle_bindings: VBoxContainer
var scroll: ScrollContainer
var mic: OptionButton
var threshold: HSlider
var transparent: CheckButton

func _ready() -> void:
	layer = 100
	await get_tree().process_frame
	if get_tree().current_scene == null or get_tree().current_scene.name == "ProtectedTests":
		return
	await get_tree().create_timer(0.4).timeout
	panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll = ScrollContainer.new()
	scroll.position = Vector2(14, 40)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.add_child(panel)
	resize_panel()
	get_window().size_changed.connect(resize_panel)
	dialog = FileDialog.new()
	dialog.use_native_dialog = true
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.pngRemixProtected ; Protected PNGRemix"])
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE if ProtectionPolicy.is_player() else FileDialog.FILE_MODE_SAVE_FILE
	add_child(dialog)
	dialog.file_selected.connect(selected)
	var button := Button.new()
	button.text = "打开保护模型 / Open model" if ProtectionPolicy.is_player() else "导出保护版 / Export protected"
	button.pressed.connect(func(): dialog.popup_centered_ratio(0.7))
	panel.add_child(button)
	status = Label.new()
	status.text = "Tab：隐藏/显示控制面板" if ProtectionPolicy.is_player() else ""
	panel.add_child(status)
	if not ProtectionPolicy.is_player():
		return
	get_window().title = "Protected PNGRemix Player — 1.4.5"
	Global.set_mode(1)
	if Global.main.has_node("%UIHold"):
		Global.main.get_node("%UIHold").hide()
	if Global.main.has_node("%ProjectNamePanel"):
		Global.main.get_node("%ProjectNamePanel").hide()
	Settings.save_timer.stop()
	mic = OptionButton.new()
	for device in AudioServer.get_input_device_list():
		mic.add_item(device)
	mic.item_selected.connect(func(index): AudioServer.input_device = mic.get_item_text(index); persist())
	panel.add_child(mic)
	threshold = HSlider.new()
	threshold.min_value = 0
	threshold.max_value = 1
	threshold.step = 0.01
	threshold.value = Global.settings_dict.volume_limit
	threshold.tooltip_text = "说话音量阈值 / Speech threshold"
	threshold.value_changed.connect(func(value): Global.settings_dict.volume_limit = value; persist())
	panel.add_child(threshold)
	transparent = CheckButton.new()
	transparent.text = "透明背景 / Transparent"
	transparent.toggled.connect(func(value): Global.settings_dict.is_transparent = value; get_viewport().transparent_bg = value; RenderingServer.set_default_clear_color(Color.TRANSPARENT if value else Color.SLATE_GRAY); persist())
	panel.add_child(transparent)
	states = OptionButton.new()
	states.item_selected.connect(func(index): Global.load_sprite_states(index); refresh_hotkey())
	panel.add_child(states)
	Global.animation_state.connect(sync_state_selection)
	key_edit = LineEdit.new()
	key_edit.placeholder_text = "点击后按键或右键 / Key or right-click"
	key_edit.context_menu_enabled = false
	key_edit.gui_input.connect(bind_key)
	panel.add_child(key_edit)
	var reset_key := Button.new()
	reset_key.text = "恢复当前状态原绑定 / Restore binding"
	reset_key.pressed.connect(restore_binding)
	panel.add_child(reset_key)
	asset_bindings = preload("res://Protected/AssetBindings.gd").new()
	panel.add_child(asset_bindings)
	asset_bindings.changed.connect(persist)
	cycle_bindings = preload("res://Protected/CycleBindings.gd").new()
	panel.add_child(cycle_bindings)
	cycle_bindings.changed.connect(persist)
	var save := Button.new()
	save.text = "保存个人设置 / Save preferences"
	save.pressed.connect(persist)
	panel.add_child(save)
	get_window().files_dropped.connect(func(files):
		if files.size() == 1:
			selected(files[0]))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("model="):
			selected(arg.trim_prefix("model="))

func selected(path: String) -> void:
	if loading:
		return
	loading = true
	var err: Error
	if ProtectionPolicy.is_player():
		err = await ProtectedSession.load_protected(path)
		if err == OK:
			default_events.clear()
			states.clear()
			for button in get_tree().get_nodes_in_group("StateButtons"):
				states.add_item(button.state_name)
			if asset_bindings != null:
				asset_bindings.refresh_model()
			if cycle_bindings != null:
				cycle_bindings.refresh_model()
			apply_preferences()
	else:
		err = ProtectedSession.export_protected(path, true)
	status.text = "完成 / Ready" if err == OK else "失败 / Failed: " + ProtectedSession.last_error
	loading = false

func bind_key(event: InputEvent) -> void:
	if states.selected < 0:
		return
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
	elif event is InputEventMouseButton:
		if not event.pressed or event.button_index == MOUSE_BUTTON_LEFT:
			return
	else:
		return
	var binding = Preferences.event_binding(event)
	if binding == null:
		return
	for state in hotkeys.keys():
		var existing := Preferences.binding_event(hotkeys[state])
		if existing != null and event.is_match(existing):
			hotkeys.erase(state)
	hotkeys[str(states.selected)] = binding
	key_edit.release_focus()
	get_viewport().set_input_as_handled()
	apply_hotkeys()
	persist()

func restore_binding() -> void:
	if states == null or states.selected < 0:
		return
	hotkeys.erase(str(states.selected))
	apply_hotkeys()
	persist()

func sync_state_selection(index: int) -> void:
	if states != null and index >= 0 and index < states.item_count:
		states.select(index)
		refresh_hotkey()

func refresh_hotkey() -> void:
	if states == null or key_edit == null:
		return
	key_edit.text = "未绑定 / Unbound"
	for button in get_tree().get_nodes_in_group("StateButtons"):
		if button.state == states.selected and button.saved_event != null:
			var event: InputEvent = button.saved_event
			key_edit.text = event.as_text()
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not (event.ctrl_pressed or event.alt_pressed or event.shift_pressed or event.meta_pressed):
				key_edit.text = "鼠标右键 / Right mouse button"
			break

func apply_hotkeys() -> void:
	hotkeys = Preferences.new().clean({"hotkeys": hotkeys, "asset_hotkeys": asset_bindings.bindings if asset_bindings != null else {}, "cycle_hotkeys": cycle_bindings.bindings if cycle_bindings != null else {}}).get("hotkeys", {})
	var buttons := get_tree().get_nodes_in_group("StateButtons")
	for button in buttons:
		var id := str(button.state)
		if not default_events.has(id):
			default_events[id] = button.saved_event.duplicate() if button.saved_event != null else null
		button.saved_event = default_events[id]
		InputMap.action_erase_events(button.input_key)
		button.update_stuff()
	for button in get_tree().get_nodes_in_group("StateButtons"):
		var key := str(button.state)
		if hotkeys.has(key):
			var event := Preferences.binding_event(hotkeys[key])
			if event == null:
				continue
			for other in get_tree().get_nodes_in_group("StateButtons"):
				if other != button:
					for existing in InputMap.action_get_events(other.input_key):
						if event.is_match(existing):
							InputMap.action_erase_event(other.input_key, existing)
							other.saved_event = null
			button.saved_event = event
			button.update_stuff()

	refresh_hotkey()

func apply_preferences() -> void:
	var prefs := Preferences.new().load_preferences(ProtectedSession.current_model_id)
	if prefs.has("microphone") and AudioServer.get_input_device_list().has(prefs.microphone):
		AudioServer.input_device = prefs.microphone
	for key in ["volume_limit", "sensitivity_limit"]:
		if prefs.has(key):
			Global.settings_dict[key] = prefs[key]
	if prefs.has("zoom"):
		Global.camera.zoom = Vector2.ONE * prefs.zoom
	if prefs.has("pan_x") and prefs.has("pan_y"):
		Global.camera_pos.global_position = Vector2(prefs.pan_x, prefs.pan_y)
	if prefs.has("transparent"):
		Global.settings_dict.is_transparent = prefs.transparent
		get_viewport().transparent_bg = prefs.transparent
		RenderingServer.set_default_clear_color(Color.TRANSPARENT if prefs.transparent else Color.SLATE_GRAY)
	if asset_bindings != null:
		asset_bindings.bindings = prefs.get("asset_hotkeys", {})
		asset_bindings.apply_bindings()
	if cycle_bindings != null:
		cycle_bindings.bindings = prefs.get("cycle_hotkeys", {})
		cycle_bindings.apply_bindings()
	hotkeys = prefs.get("hotkeys", {})
	apply_hotkeys()
	sync_preferences_controls()

func persist() -> void:
	if not ProtectionPolicy.is_player() or ProtectedSession.current_model_id.is_empty():
		return
	Preferences.new().save_preferences(ProtectedSession.current_model_id, {"microphone": AudioServer.input_device, "volume_limit": float(Global.settings_dict.volume_limit), "sensitivity_limit": float(Global.settings_dict.sensitivity_limit), "zoom": float(Global.camera.zoom.x), "pan_x": float(Global.camera_pos.global_position.x), "pan_y": float(Global.camera_pos.global_position.y), "transparent": bool(Global.settings_dict.is_transparent), "hotkeys": hotkeys, "asset_hotkeys": asset_bindings.bindings if asset_bindings != null else {}, "cycle_hotkeys": cycle_bindings.bindings if cycle_bindings != null else {}})

func _input(event: InputEvent) -> void:
	if ProtectionPolicy.is_player() and panel != null and event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		panel.visible = not panel.visible
		if scroll != null: scroll.visible = panel.visible
		get_viewport().set_input_as_handled()


func resize_panel() -> void:
	if scroll != null:
		scroll.size = Vector2(minf(380, maxf(120, get_viewport().get_visible_rect().size.x - 28)), maxf(100, get_viewport().get_visible_rect().size.y - 60))

func sync_preferences_controls() -> void:
	if mic != null:
		for index in mic.item_count:
			if mic.get_item_text(index) == AudioServer.input_device:
				mic.select(index)
	if threshold != null:
		threshold.set_value_no_signal(Global.settings_dict.volume_limit)
	if transparent != null:
		transparent.set_pressed_no_signal(Global.settings_dict.is_transparent)
