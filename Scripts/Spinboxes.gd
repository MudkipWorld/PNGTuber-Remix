extends SpinBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_line_edit().focus_mode = 1
	focus_exited.connect(release)

func release():
	print("ya")
	get_line_edit().release_focus()
	release_focus()
