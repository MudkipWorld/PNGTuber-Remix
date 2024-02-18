extends Node


func _on_zoom_in_button_pressed():
	if %Camera2D.zoom.x < 3.9:
		%Camera2D.zoom += Vector2(0.1,0.1)


func _on_zoom_reset_button_pressed():
	%Camera2D.zoom = Vector2(1,1)


func _on_zoom_out_button_pressed():
	if %Camera2D.zoom.x > 0.1:
		%Camera2D.zoom -= Vector2(0.1,0.1)
