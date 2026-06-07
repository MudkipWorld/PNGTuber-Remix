extends TabBar

@export var sprite : AnimatedSprite2D


func _ready() -> void:
	sprite.stop()


func _process(_delta: float) -> void:
	if GlobalAudioStreamPlayer.t.value == 0:
		sprite.frame = 13
	else:
		sprite.frame = GlobalAudioStreamPlayer.t.actual_value
	if GlobalAudioStreamPlayer.t != null:
		%PhBox.get_child(GlobalAudioStreamPlayer.t.actual_value).value = GlobalAudioStreamPlayer.t.value
