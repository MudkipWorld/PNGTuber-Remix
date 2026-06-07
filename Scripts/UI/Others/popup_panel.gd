extends PopupPanel


func _on_button_pressed() -> void:
	Settings.save_before_closing()
