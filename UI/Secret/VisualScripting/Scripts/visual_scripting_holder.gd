extends PanelContainer

var selected_condition
var selected_action

@export var list : Window

func _on_add_script_pressed() -> void:
	var condact = preload("res://UI/Secret/VisualScripting/condition_action.tscn").instantiate()
	condact.holder = self
	%ScriptList.add_child(condact)
	%ScriptList.move_child(%AddScript, condact.get_index())


func add_condition(condact):
	selected_condition = condact
	list.show()
