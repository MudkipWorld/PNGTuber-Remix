extends Node2D

var throwable : PackedScene = preload("res://Misc/throwables/throwable.tscn")
var dir : Vector2 = Vector2(1500, 10)
var selected_items : Array = []
var throw_per_trigger : int = 1

func _ready() -> void:
	Global.mode_changed.connect(show_pointer)
	Global.throwable_spawner = self

func show_pointer(mode : int):
	match mode:
		0:
			%Pointer.show()
		_:
			%Pointer.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("throwing"):
		throw_item()

func throw_item():
	if selected_items.size() < 1 : return
	for i in throw_per_trigger:
		var spawn : ThrowableObject = throwable.instantiate()
		var img_data : ImageData = selected_items.pick_random()
		spawn.sprite_object.texture = img_data.runtime_texture
		add_child(spawn)
		spawn.apply_central_impulse(dir)
		await get_tree().create_timer(randf_range(0.05, 0.25)).timeout
