extends HBoxContainer
class_name BetterSlider

@export var mini_value : float
@export var max_value : float
@export var step : float
@export var value : float

# Called when the node enters the scene tree for the first time.
func _ready():
	%SpinBoxValue.get_line_edit().focus_mode = 1
	%SpinBoxValue.min_value = mini_value
	%SpinBoxValue.max_value = max_value
	%SpinBoxValue.step = step
	
	%SliderValue.min_value = mini_value
	%SliderValue.max_value = max_value
	%SliderValue.step = step
	
	%SpinBoxValue.get_line_edit().focus_entered.connect(f_entered)
	%SpinBoxValue.get_line_edit().focus_exited.connect(release)

func release():
	Global.spinbox_held = false

func f_entered():
	Global.spinbox_held = true


func _on_spin_box_value_value_changed(nvalue):
	Global.spinbox_held = false
	%SliderValue.value = nvalue
	%SpinBoxValue.get_line_edit().release_focus()
	


func _on_slider_value_value_changed(nvalue):
	%SpinBoxValue.value = nvalue
	


func _on_spin_box_value_focus_exited() -> void:
	print("ya")
	Global.spinbox_held = false
	%SpinBoxValue.release_focus()
