@icon("res://UI/BetterSlider/BetSIcon .png")
extends HBoxContainer
class_name BetterSlider

enum Type {
	
	Both,
	Spin,
	Slide,
	NoLabel,
	NoLabelSpin,

}

@export var sp_type : String = "Null"
@export var label_text : String = "placeholder"
@export var mini_value : float
@export var max_value : float
@export var step : float
@export var value : float
@export var ui_type : Type
@export var value_to_update : String = "position"

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()
	%SpinBoxValue.get_line_edit().focus_mode = 1
	%SpinBoxValue.min_value = mini_value
	%SpinBoxValue.max_value = max_value
	%SpinBoxValue.step = step
	
	%SliderValue.min_value = mini_value
	%SliderValue.max_value = max_value
	%SliderValue.step = step
	
	%SpinBoxValue.get_line_edit().focus_entered.connect(f_entered)
	%SpinBoxValue.get_line_edit().focus_exited.connect(release)
	%BetterSliderLabel.text = label_text
	ready_type(ui_type)

func ready_type(typ):
	match typ:
		Type.Both:
			pass
		Type.Spin:
			%SliderValue.hide()
			%SliderValue.editable = false
		Type.Slide:
			%SpinBoxValue.hide()
			%SpinBoxValue.editable = false
		Type.NoLabel:
			%BetterSliderLabel.hide()
		Type.NoLabelSpin:
			%SpinBoxValue.hide()
			%SpinBoxValue.editable = false
			%BetterSliderLabel.hide()


func release():
	Global.spinbox_held = false

func f_entered():
	Global.spinbox_held = true

func _on_spin_box_value_value_changed(nvalue):
	Global.spinbox_held = false
	%SliderValue.value = nvalue
	%SpinBoxValue.get_line_edit().release_focus()
	if Global.held_sprite != null && sp_type != "Null":
		Global.held_sprite.dictmain[value_to_update] = nvalue
		Global.held_sprite.save_state(Global.current_state)




func _on_slider_value_value_changed(nvalue):
	%SpinBoxValue.value = nvalue
	if Global.held_sprite != null && sp_type != "Null":
		Global.held_sprite.dictmain[value_to_update] = nvalue
		if sp_type == "WiggleApp":
			Global.held_sprite.update_wiggle_parts()
		Global.held_sprite.save_state(Global.current_state)
	

func _on_spin_box_value_focus_exited() -> void:
	Global.spinbox_held = false
	%SpinBoxValue.release_focus()

func nullfy():
	if sp_type != "Null":
		%SpinBoxValue.editable = false
		%SliderValue.editable = false

func enable():
	if Global.held_sprite.sprite_type == sp_type:
		%SpinBoxValue.editable = true
		%SliderValue.editable = true
		%SliderValue.value = Global.held_sprite.dictmain[value_to_update]
		
	elif sp_type == "":
		%SpinBoxValue.editable = true
		%SliderValue.editable = true
		%SliderValue.value = Global.held_sprite.dictmain[value_to_update]

func _on_slider_value_drag_ended(value_changed: bool) -> void:
	if value_changed && sp_type != "Null":
		Global.held_sprite.dictmain[value_to_update] = %SliderValue.value
		if sp_type == "WiggleApp":
			Global.held_sprite.update_wiggle_parts()
		Global.held_sprite.save_state(Global.current_state)
