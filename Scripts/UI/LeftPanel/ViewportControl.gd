extends Node


func _ready() -> void:
	await get_tree().current_scene.ready
	var view1 = Global.main.get_node("%SubViewport")
	%SubViewport.world_2d = view1.world_2d
	

func _on_zoom_in_button_pressed():
	if %Camera2D.zoom.x < 3.9:
		%Camera2D.zoom += Vector2(0.1,0.1)


func _on_zoom_reset_button_pressed():
	%Camera2D.zoom = Vector2(1,1)


func _on_zoom_out_button_pressed():
	if %Camera2D.zoom.x > 0.1:
		%Camera2D.zoom -= Vector2(0.1,0.1)


func _on_zoom_main_reset_button_pressed():
	Global.camera.zoom = Vector2(1,1)
	Global.camera.get_parent().global_position = Vector2(640, 360)
	Global.settings_dict.zoom  = Vector2(1,1)
	Global.settings_dict.pan = Vector2(640, 360)
