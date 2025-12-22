extends HBoxContainer


func _ready() -> void:
	pass

func _on_zoom_in_button_pressed() -> void:
	var val = min(Global.camera.zoom.x*1.1, 5.0)
	Global.camera.zoom = Vector2(val, val)
	Global.settings_dict.zoom  = Global.camera.zoom

func _on_zoom_out_button_pressed() -> void:
	var val = max(Global.camera.zoom.x/1.1, 0.01)
	Global.camera.zoom = Vector2(val, val)
	Global.settings_dict.zoom  = Global.camera.zoom


func _on_zoom_main_reset_button_pressed() -> void:
	Global.camera.zoom = Vector2(1,1)
	Global.camera.get_parent().global_position = Vector2(0, 0)
	Global.settings_dict.zoom  = Vector2(1,1)
	Global.settings_dict.pan = Vector2(0, 0)
