extends ColorRect



func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("ControllerUp"):
		color = Color.AQUA
	else:
		color = Color.WHITE
