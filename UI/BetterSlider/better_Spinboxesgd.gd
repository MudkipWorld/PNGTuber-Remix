@icon("res://UI/BetterSlider/BetSIcon .png")
extends HBoxContainer
class_name BetterSpinboxes

@export var sp_type: String = "Null"
@export var label_text: String = "placeholder"
@export var mini_value: float
@export var max_value: float
@export var step: float
@export var value: float
@export var value_to_update: String = "position": get = get_value
@export var has_alt_values := false
@export var is_x : String = ""

var should_change: bool = false
var held_spinbox = null
var val = []
@export var update_mesh : bool = false

func _ready():
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	Global.editing_for_changed.connect(enable)
	
	_setup_spinbox()
	_setup_label()

func _setup_spinbox():
	%SpinBoxValue.get_line_edit().focus_mode = 1
	%SpinBoxValue.min_value = mini_value
	%SpinBoxValue.max_value = max_value
	%SpinBoxValue.step = step
	%SpinBoxValue.get_line_edit().focus_entered.connect(_on_spinbox_focused)
	%SpinBoxValue.get_line_edit().focus_exited.connect(_on_spinbox_unfocused)

func _setup_label():
	%BetterSliderLabel.text = label_text


func _expand_spinbox():
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
		%SpinBoxValue.get_line_edit().release_focus()

func _apply_value_to_selected(nvalue: float, push_undo: bool):
	if not should_change:
		return
	for sprite in Global.held_sprites:
		if sprite == null or not is_instance_valid(sprite) or sp_type == "Null":
			continue
		
		if update_mesh:
			if is_x.is_empty():
				sprite.mesh.set(value_to_update, nvalue)
			elif is_x.to_lower()  == "x":
				var test = sprite.mesh.get(value_to_update)
				test.x = nvalue
				sprite.mesh.set(value_to_update, test)
			elif is_x.to_lower() == "y":
				var test = sprite.mesh.get(value_to_update)
				test.y = nvalue
				sprite.mesh.set(value_to_update, test)

		else:
			if is_x.is_empty():
				sprite.sprite_data[value_to_update] = nvalue
			elif is_x.to_lower()  == "x":
				sprite.sprite_data[value_to_update].x = nvalue
			elif is_x.to_lower() == "y":
				sprite.sprite_data[value_to_update].y = nvalue
			if sprite.sprite_type == "WiggleApp" and sp_type == "WiggleApp":
				sprite.update_wiggle_parts()
				
			StateButton.multi_edit(sprite.sprite_data[value_to_update], value_to_update, sprite, sprite.states)
			sprite.save_state(Global.current_state)
		
		for i in val:
			i.merge({new_val = sprite.sprite_data[value_to_update]}, true)
		
	if push_undo:
		UndoRedoManager.push_data(val)

func nullfy():
	%SpinBoxValue.editable = false

func enable():
	should_change = false
	for sprite in Global.held_sprites:
		if sprite.sprite_type == sp_type or sp_type == "":
			%SpinBoxValue.editable = true
			var _val = sprite.sprite_data[value_to_update]
			
			if is_x.is_empty():
				%SpinBoxValue.value  = _val
			elif is_x.to_lower()  == "x":
				%SpinBoxValue.value  =  _val.x
			elif is_x.to_lower() == "y":
				%SpinBoxValue.value = _val.y
	should_change = true
