extends Window




func _ready() -> void:
	close_requested.connect(zaza)

func zaza():
	hide()

func _on_condition_1_pressed() -> void:
	zaza()


func _on_condition_2_pressed() -> void:
	zaza()


func _on_action_1_pressed() -> void:
	zaza()


func _on_action_2_pressed() -> void:
	zaza()


func _on_input_condition_1_pressed() -> void:
	zaza()


func _on_camera_list_pressed() -> void:
	%List.current_tab = 0


func _on_input_list_pressed() -> void:
	%List.current_tab = 2
