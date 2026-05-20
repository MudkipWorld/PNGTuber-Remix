extends Node2D

var throwable : PackedScene = preload("res://Misc/throwables/throwable.tscn")
var dir : Vector2 = Vector2(1500, 10)
var selected_items : Array = []
var throw_per_trigger : int = 1
var spawn_variance : float = 0.0
var both_sides : bool = false
var base_mass : float = 1

func _ready() -> void:
	Global.mode_changed.connect(show_pointer)
	Global.throwable_spawner = self

func show_pointer(mode : int):
	match mode:
		0:
			%Pointer.show()
		_:
			%Pointer.hide()

func _process(_delta: float) -> void:
	if GlobInput.is_action_just_pressed('throwing'):
		throw_item()

func throw_item():
	if selected_items.size() < 1 : return
	throw_random_items(throw_per_trigger)

func throw_random_items(amount: int, custom_variance: float = -1.0, custom_both_sides: int = -1):
	if selected_items.size() < 1 : return
	
	var current_variance = spawn_variance if custom_variance < 0 else custom_variance
	var current_both_sides = both_sides if custom_both_sides < 0 else bool(custom_both_sides)
	
	for i in amount:
		var spawn : ThrowableObject = throwable.instantiate()
		var img_data : ImageData = selected_items.pick_random()
		spawn.sprite_object.texture = img_data.runtime_texture
		
		var is_flipped = current_both_sides and randf() > 0.5
		var current_dir = dir
		var base_pos = Vector2.ZERO
		if is_flipped:
			if position.x > 0:
				base_pos.x = self.position.x * 2
				current_dir.x = -dir.x
			else:
				base_pos.x = -self.position.x * 2
				current_dir.x = -dir.x
			current_dir.y = -dir.y
			
		var offset = Vector2(randf_range(-current_variance, current_variance), randf_range(-current_variance, current_variance))
		spawn.position = base_pos + offset
		spawn.mass = base_mass
		add_child(spawn)
		spawn.apply_central_impulse(current_dir - offset)
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout

func throw_specific_item(img_data: ImageData, amount: int = 1, custom_variance: float = -1.0, custom_both_sides: int = -1):
	var current_variance = spawn_variance if custom_variance < 0 else custom_variance
	var current_both_sides = both_sides if custom_both_sides < 0 else bool(custom_both_sides)

	for i in amount:
		var spawn : ThrowableObject = throwable.instantiate()
		spawn.sprite_object.texture = img_data.runtime_texture
		
		var is_flipped = current_both_sides and randf() > 0.5
		var current_dir = dir
		var base_pos = Vector2.ZERO
		if is_flipped:
			if position.x > 0:
				base_pos.x = self.position.x * 2
				current_dir.x = -dir.x
			else:
				base_pos.x = -self.position.x * 2
				current_dir.x = -dir.x
				
			current_dir.y = -dir.y
			
		var offset = Vector2(randf_range(-current_variance, current_variance), randf_range(-current_variance, current_variance))
		spawn.position = base_pos + offset
		spawn.mass = base_mass
		add_child(spawn)
		spawn.apply_central_impulse(current_dir - offset)
		await get_tree().create_timer(randf_range(0.05, 0.25)).timeout
