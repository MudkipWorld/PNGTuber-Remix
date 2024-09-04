extends SpinBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_line_edit().focus_mode = 1
	get_line_edit().text_submitted.connect(text_done)
	focus_exited.connect(release)
	focus_entered.connect(f_entered)
	get_line_edit().focus_entered.connect(f_entered)
	get_line_edit().focus_exited.connect(release)
	

func f_entered():
	Global.spinbox_held = true
	
	

func release():
	Global.spinbox_held = false
	print("ya")
	get_line_edit().release_focus()
	release_focus()

func text_done(_text):
	Global.spinbox_held = false
