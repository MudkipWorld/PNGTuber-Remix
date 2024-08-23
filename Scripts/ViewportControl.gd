extends Node


func _on_zoom_in_button_pressed():
	if %Camera2D.zoom.x < 3.9:
		%Camera2D.zoom += Vector2(0.1,0.1)


func _on_zoom_reset_button_pressed():
	%Camera2D.zoom = Vector2(1,1)


func _on_zoom_out_button_pressed():
	if %Camera2D.zoom.x > 0.1:
		%Camera2D.zoom -= Vector2(0.1,0.1)


func _on_zoom_main_reset_button_pressed():
	get_tree().get_root().get_node("Main/SubViewportContainer/%Camera2D").zoom = Vector2(1,1)
	get_tree().get_root().get_node("Main/SubViewportContainer/%CamPos").global_position = Vector2(640, 360)
	Global.settings_dict.zoom  = Vector2(1,1)
	Global.settings_dict.pan = Vector2(640, 360)
