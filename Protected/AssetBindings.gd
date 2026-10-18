extends VBoxContainer

signal changed
const Preferences = preload("res://Protected/PlayerSettings.gd")
var resources := OptionButton.new()
var binding_edit := LineEdit.new()
var behavior := Label.new()
var reset := Button.new()
var bindings := {}
var defaults := {}
var actors := {}

func _ready() -> void:
	var title := Label.new()
	title.text = "资源切换绑定 / Asset bindings"
	add_child(title)
	resources.custom_minimum_size.x = 260
	resources.item_selected.connect(func(_index): refresh_label())
	add_child(resources)
	add_child(behavior)
	binding_edit.placeholder_text = "点击后按键或右键 / Key or right-click"
	binding_edit.context_menu_enabled = false
	binding_edit.gui_input.connect(bind_input)
	add_child(binding_edit)
	reset.text = "恢复资源原绑定 / Restore asset binding"
	reset.pressed.connect(restore_binding)
	add_child(reset)
	refresh_label()

func refresh_model() -> void:
	resources.clear()
	defaults.clear()
	actors.clear()
	bindings.clear()
	for actor in get_tree().get_nodes_in_group("Sprites"):
		if not actor.is_asset:
			continue
		var id := str(int(actor.sprite_id))
		var action := str(actor.sprite_id)
		actors[id] = actor
		defaults[id] = InputMap.action_get_events(action).duplicate(true) if InputMap.has_action(action) else []
		resources.add_item(str(actor.sprite_name) + " [" + id + "]")
		resources.set_item_metadata(resources.item_count - 1, id)
	if resources.item_count > 0:
		resources.select(0)
	refresh_label()

func selected_id() -> String:
	return str(resources.get_item_metadata(resources.selected)) if resources.selected >= 0 else ""

func apply_bindings() -> void:
	bindings = Preferences.new().clean({"asset_hotkeys": bindings}).get("asset_hotkeys", {})
	for id in actors:
		var actor = actors[id]
		if not is_instance_valid(actor):
			continue
		var action := str(actor.sprite_id)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		if bindings.has(id):
			InputMap.action_add_event(action, Preferences.binding_event(bindings[id]))
		else:
			for event in defaults[id]:
				InputMap.action_add_event(action, event)
	refresh_label()

func bind_input(event: InputEvent) -> void:
	var id := selected_id()
	if id.is_empty():
		return
	if event is InputEventKey:
		if not event.pressed or event.echo: return
	elif event is InputEventMouseButton:
		if not event.pressed or event.button_index == MOUSE_BUTTON_LEFT: return
	else:
		return
	var binding = Preferences.event_binding(event)
	if binding == null: return
	bindings[id] = binding
	binding_edit.release_focus()
	get_viewport().set_input_as_handled()
	apply_bindings()
	changed.emit()

func restore_binding() -> void:
	bindings.erase(selected_id())
	apply_bindings()
	changed.emit()

func refresh_label() -> void:
	var id := selected_id()
	var available := actors.has(id) and is_instance_valid(actors[id])
	binding_edit.editable = available
	reset.disabled = not available
	resources.disabled = resources.item_count == 0
	binding_edit.text = ""
	behavior.text = "此模型没有可切换资源 / No switchable assets"
	if not available: return
	var actor = actors[id]
	behavior.text = "按住显示 / Hold to show" if actor.hold_to_show else ("按下显示 / Show on press" if actor.show_only else "按下切换显隐 / Toggle visibility")
	var events := InputMap.action_get_events(str(actor.sprite_id))
	binding_edit.text = events[0].as_text() if not events.is_empty() else "未绑定 / Unbound"
