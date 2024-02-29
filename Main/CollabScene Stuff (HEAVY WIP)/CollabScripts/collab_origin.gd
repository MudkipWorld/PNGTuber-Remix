extends Node2D


func _enter_tree():
	set_multiplayer_authority(name.to_int())
	var main = get_tree().get_root().get_node("CollabMain")
	main.user_id = name.to_int()
	main.load_file(main.path, %SpriteContainer, self.name.to_int())
	
	%Camera2D.enabled = is_multiplayer_authority()



func _input(event):
	if is_multiplayer_authority():
		if Input.is_action_pressed("ui_left"):
			position.x -= 2
		if Input.is_action_pressed("ui_right"):
			position.x += 2
		if Input.is_action_pressed("ui_up"):
			position.y -= 2
		if Input.is_action_pressed("ui_down"):
			position.y += 2
			
		if Input.is_action_pressed("z"):
			z_index += 1
		elif Input.is_action_pressed("x"):
			z_index -= 1
		
	if event.is_action_pressed("scrollup"):
		if %Camera2D.zoom != Vector2(4,4):
			%Camera2D.zoom += Vector2(0.1,0.1)
	elif event.is_action_pressed("scrolldown"):
		if %Camera2D.zoom > Vector2(0.1,0.1):
			%Camera2D.zoom -= Vector2(0.1,0.1)
