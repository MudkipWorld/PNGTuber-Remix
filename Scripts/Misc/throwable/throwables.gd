extends Node2D

var throwable : PackedScene = preload("res://Misc/throwables/throwable.tscn")
var dir : Vector2 = Vector2(1500, 10)
var selected_items : Array = []
var throw_per_trigger : int = 1
var spawn_variance : float = 0.0
var both_sides : bool = false
var is_paused : bool = false
var current_throw_generation : int = 0

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
	if event.is_action_pressed("throwing_pause"):
		toggle_pause()

func toggle_pause():
	set_paused(!is_paused)

func set_paused(state: bool):
	is_paused = state
	if is_paused:
		current_throw_generation += 1

func throw_item():
	is_paused = false
	if selected_items.size() < 1 : return
	throw_random_items(throw_per_trigger)

func throw_random_items(amount: int, custom_variance: float = -1.0, custom_both_sides: int = -1):
	is_paused = false
	if selected_items.size() < 1 : return
	
	var my_generation = current_throw_generation
	var current_variance = spawn_variance if custom_variance < 0 else custom_variance
	var current_both_sides = both_sides if custom_both_sides < 0 else bool(custom_both_sides)
	
	for i in amount:
		if is_paused or current_throw_generation != my_generation: break
		var spawn : ThrowableObject = throwable.instantiate()
		var img_data : ImageData = selected_items.pick_random()
		spawn.sprite_object.texture = img_data.runtime_texture
		
		var is_flipped = current_both_sides and randf() > 0.5
		var current_dir = dir
		var base_pos = Vector2.ZERO
		if is_flipped:
			base_pos = -self.position * 2
			current_dir = -dir
			
		var offset = Vector2(randf_range(-current_variance, current_variance), randf_range(-current_variance, current_variance))
		spawn.position = base_pos + offset
		add_child(spawn)
		spawn.apply_central_impulse(current_dir - offset)
		await get_tree().create_timer(randf_range(0.05, 0.25)).timeout

func throw_specific_item(img_data: ImageData, amount: int = 1, custom_variance: float = -1.0, custom_both_sides: int = -1):
	is_paused = false
	
	var my_generation = current_throw_generation
	var current_variance = spawn_variance if custom_variance < 0 else custom_variance
	var current_both_sides = both_sides if custom_both_sides < 0 else bool(custom_both_sides)

	for i in amount:
		if is_paused or current_throw_generation != my_generation: break
		var spawn : ThrowableObject = throwable.instantiate()
		spawn.sprite_object.texture = img_data.runtime_texture
		
		var is_flipped = current_both_sides and randf() > 0.5
		var current_dir = dir
		var base_pos = Vector2.ZERO
		if is_flipped:
			base_pos = -self.position * 2
			current_dir = -dir
			
		var offset = Vector2(randf_range(-current_variance, current_variance), randf_range(-current_variance, current_variance))
		spawn.position = base_pos + offset
		add_child(spawn)
		spawn.apply_central_impulse(current_dir - offset)
		await get_tree().create_timer(randf_range(0.05, 0.25)).timeout
