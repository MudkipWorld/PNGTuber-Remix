extends Button

func _ready():
	set_process_unhandled_input(false)
	update_key_text()


func _toggled(toggle):
	set_process_unhandled_input(toggle)
	if toggle:
		text = "TR_AWAITING_INPUT"
		grab_focus()

	else:
		update_key_text()
		release_focus()


func _unhandled_input(event):
	if not event is InputEventMouseMotion:
		if event.is_released():
			Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].backward = event.duplicate()
			update_key_text()
			button_pressed = false


func update_key_text():
	if %CycleChoice.get_selected_id() > 0:
		if Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].backward != null:
			self.text = Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].backward.as_text()
		else:
			self.text = "TR_BIND_KEY"

	else:
		self.text = "TR_BIND_KEY"


func _on_cycle_del_pressed() -> void:
	if %CycleChoice.get_selected_id() > 0:
		Global.settings_dict.cycles[%CycleChoice.get_selected_id() - 1].backward = null
	update_key_text()
