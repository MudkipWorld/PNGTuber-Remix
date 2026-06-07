extends Label



func _ready() -> void:
	hide()
	Global.project_updates.connect(update_text)


func update_text(update : String = "Nothing, just Silly"):
	text = update
	show()
	await get_tree().create_timer(1.5).timeout
	hide()
