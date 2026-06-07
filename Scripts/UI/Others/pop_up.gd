extends PopupPanel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_hide.connect(close)

func close():
	queue_free()
