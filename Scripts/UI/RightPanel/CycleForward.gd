extends Button

func _ready():
	set_process_input(false)
	update_key_text()


func _toggled(toggle):
	set_process_input(toggle)
	if toggle:
		text = "TR_AWAITING_INPUT"
		grab_focus()
	else:
		update_key_text()
		release_focus()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		if event.is_released():
			Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].forward = event.duplicate()
			update_key_text()
			button_pressed = false


func update_key_text():
	if %CycleChoice.get_selected_id() > 0:
		if Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].forward != null:
			self.text = Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].forward.as_text()
		else:
			self.text = "TR_BIND_KEY"
	else:
		self.text = "TR_BIND_KEY"


func _on_cycle_del_pressed() -> void:
	if %CycleChoice.get_selected_id() > 0:
		Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].forward = null
	update_key_text()
