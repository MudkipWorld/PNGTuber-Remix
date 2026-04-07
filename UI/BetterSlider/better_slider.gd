@icon("res://UI/BetterSlider/BetSIcon.png")
extends HBoxContainer
class_name BetterSlider

enum Type { Both, Spin, Slide, NoLabel, NoLabelSpin }

@export var sp_type: String = "Null"
@export var label_text: String = "placeholder"
@export var mini_value: float
@export var max_value: float
@export var step: float
@export var value: float
@export var ui_type: Type
@export var value_to_update: String = "position": get = get_value
@export var has_alt_values := false

@export var allow_greater : bool = false

var should_change: bool = false
var held_spinbox = null
var val = []

func _ready():
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	Global.editing_for_changed.connect(enable)
	
	setup_spinbox()
	setup_slider()
	setup_label()
	
	%SpinBoxValue.allow_greater = allow_greater
	%SliderValue.allow_greater = allow_greater
	
	ready_type(ui_type)
	nullfy()

func setup_spinbox():
	%SpinBoxValue.get_line_edit().focus_mode = 1
	%SpinBoxValue.min_value = mini_value
	%SpinBoxValue.max_value = max_value
	%SpinBoxValue.step = step
	%SpinBoxValue.get_line_edit().focus_entered.connect(_on_spinbox_focused)
	%SpinBoxValue.get_line_edit().focus_exited.connect(_on_spinbox_unfocused)

func setup_slider():
	%SliderValue.min_value = mini_value
	%SliderValue.max_value = max_value
	%SliderValue.step = step

func setup_label():
	%BetterSliderLabel.text = label_text

func ready_type(typ):
	match typ:
		Type.Spin:
			hide_slider()
			expand_spinbox()
		Type.Slide:
			hide_spinbox()
		Type.NoLabel:
			%BetterSliderLabel.hide()
		Type.NoLabelSpin:
			hide_spinbox()
			expand_spinbox()
			%BetterSliderLabel.hide()
		_: pass

func hide_spinbox():
	%SpinBoxValue.hide()
	%SpinBoxValue.editable = false

func hide_slider():
	%SliderValue.hide()
	%SliderValue.editable = false

func expand_spinbox():
	%SpinBoxValue.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	%SpinBoxValue.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_FILL)

func get_value() -> String:
	if not has_alt_values:
		return value_to_update

	match Global.editing_for:
		Global.Mouth.Open: return "mo_" + value_to_update
		Global.Mouth.Screaming: return "scream_" + value_to_update
		_: return value_to_update

func _on_spinbox_focused():
	Global.spinbox_held = true
	held_spinbox = self
	val = []
	if Global.held_sprites.is_empty(): return
	for obj in Global.held_sprites:
		var d = {
				node = obj,
				action = value_to_update,
				state = Global.current_state,
				value = obj.sprite_data[value_to_update]
			}
		val.append(d)

func _on_spinbox_unfocused():
	Global.spinbox_held = false
	held_spinbox = null

func _on_spin_box_value_value_changed(nvalue):
	if should_change:
		if held_spinbox:
			_apply_value_to_selected(nvalue, true)
		held_spinbox = null
		Global.spinbox_held = false
		%SliderValue.value = nvalue
		if allow_greater:
			%SliderValue.value = -abs(nvalue)
		
		%SpinBoxValue.get_line_edit().release_focus()

func _on_slider_value_drag_started() -> void:
	if Global.held_sprites.is_empty(): return
	val = []
	if Global.held_sprites.is_empty(): return
	for obj in Global.held_sprites:
		var d = {
				node = obj,
				action = value_to_update,
				state = Global.current_state,
				value = obj.sprite_data[value_to_update]
			}
		val.append(d)

func _on_slider_value_value_changed(nvalue):
	if should_change:
		%SpinBoxValue.value = nvalue
		if allow_greater:
			%SpinBoxValue.value = -abs(nvalue)
		_apply_value_to_selected(%SpinBoxValue.value, false)

func _on_slider_value_drag_ended(value_changed: bool):
	if value_changed and sp_type != "Null":
		_apply_value_to_selected(%SliderValue.value, true)

func _apply_value_to_selected(nvalue: float, push_undo: bool):
	if not should_change:
		return
	for sprite in Global.held_sprites:
		if sprite == null or not is_instance_valid(sprite) or sp_type == "Null":
			continue
		sprite.sprite_data[value_to_update] = nvalue
		StateButton.multi_edit(sprite.sprite_data[value_to_update], value_to_update, sprite, sprite.states)
		if sprite.sprite_type == "WiggleApp" and sp_type == "WiggleApp":
			sprite.update_wiggle_parts()
		sprite.save_state(Global.current_state)
		for i in val:
			i.merge({new_val = sprite.sprite_data[value_to_update]}, true)
	if push_undo:
		UndoRedoManager.push_data(val)

func nullfy():
	if sp_type != "Null":
		%SpinBoxValue.editable = false
		%SliderValue.editable = false

func enable():
	should_change = false
	for sprite in Global.held_sprites:
		if sprite.sprite_type == sp_type or sp_type == "":
			%SpinBoxValue.editable = true
			%SliderValue.editable = true
			var _val = sprite.sprite_data[value_to_update]
			%SpinBoxValue.value = _val
			%SliderValue.value = _val
	should_change = true
