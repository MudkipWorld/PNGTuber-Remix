extends VBoxContainer
signal changed
const Preferences = preload("res://Protected/PlayerSettings.gd")
const ACTIONS = ["toggle", "forward", "backward"]
var cycles := OptionButton.new()
var actions := OptionButton.new()
var binding_edit := LineEdit.new()
var reset := Button.new()
var bindings := {}
var defaults := {}
var installed_actions: Array[String] = []

func _ready() -> void:
	var title := Label.new()
	title.text = "循环资源绑定 / Cycle bindings"
	add_child(title)
	cycles.item_selected.connect(func(_index): refresh_label())
	add_child(cycles)
	for label in ["启用 / 关闭 · Toggle", "下一个 · Next", "上一个 · Previous"]:
		actions.add_item(label)
	actions.item_selected.connect(func(_index): refresh_label())
	add_child(actions)
	binding_edit.placeholder_text = "点击后按键或右键 / Key or right-click"
	binding_edit.context_menu_enabled = false
	binding_edit.gui_input.connect(bind_input)
	add_child(binding_edit)
	reset.text = "恢复此循环动作原绑定 / Restore binding"
	reset.pressed.connect(restore_binding)
	add_child(reset)
	refresh_label()

static func action_name(key: String) -> String:
	return "protected_cycle_" + key

func clear_actions() -> void:
	for name in installed_actions:
		if InputMap.has_action(name): InputMap.erase_action(name)
	installed_actions.clear()

func _exit_tree() -> void:
	clear_actions()

func refresh_model() -> void:
	clear_actions()
	cycles.clear()
	defaults.clear()
	bindings.clear()
	for index in Global.settings_dict.cycles.size():
		var cycle = Global.settings_dict.cycles[index]
		cycles.add_item("循环 / Cycle %d (%d)" % [index + 1, cycle.sprites.size()])
		for action in ACTIONS:
			var event = cycle.get(action)
			defaults[str(index) + ":" + action] = event.duplicate() if event != null else null
	if cycles.item_count > 0: cycles.select(0)
	refresh_label()

func selected_key() -> String:
	return str(cycles.selected) + ":" + ACTIONS[actions.selected] if cycles.selected >= 0 else ""

func apply_bindings() -> void:
	clear_actions()
	bindings = Preferences.new().clean({"cycle_hotkeys": bindings}).get("cycle_hotkeys", {})
	for key in bindings:
		if not defaults.has(key): continue
		var name := action_name(key)
		InputMap.add_action(name)
		InputMap.action_add_event(name, Preferences.binding_event(bindings[key]))
		installed_actions.append(name)
	refresh_label()

func has_override(index: int, action: String) -> bool:
	return InputMap.has_action(action_name(str(index) + ":" + action))

func bind_input(event: InputEvent) -> void:
	var key := selected_key()
	if key.is_empty(): return
	if event is InputEventKey:
		if not event.pressed or event.echo: return
	elif event is InputEventMouseButton:
		if not event.pressed or event.button_index == MOUSE_BUTTON_LEFT: return
	else: return
	var binding = Preferences.event_binding(event)
	if binding == null: return
	bindings[key] = binding
	binding_edit.release_focus()
	get_viewport().set_input_as_handled()
	apply_bindings()
	changed.emit()

func restore_binding() -> void:
	bindings.erase(selected_key())
	apply_bindings()
	changed.emit()

func refresh_label() -> void:
	var key := selected_key()
	var available := defaults.has(key)
	binding_edit.editable = available
	reset.disabled = not available
	cycles.disabled = cycles.item_count == 0
	actions.disabled = not available
	binding_edit.text = "没有循环资源 / No cycles"
	if not available: return
	var event = Preferences.binding_event(bindings[key]) if bindings.has(key) else defaults[key]
	binding_edit.text = event.as_text() if event != null else "未绑定 / Unbound"
