extends Node2D

var throwable : PackedScene = preload("res://Misc/throwables/throwable.tscn")
var throw_force : float = 1500.0
var selected_items : Array = []
var throw_per_trigger : int = 1
var spawn_variance : float = 0.0
var both_sides : bool = false
var is_paused : bool = false
var current_throw_generation : int = 0
var base_mass : float = 1
var time_variance : float = 0.15
var spawn_radius : float = 750.0

var spawn_distance: float = 750.0:
	set(val):
		spawn_distance = val
		_update_position()

var spawn_degree: float = 0.0:
	set(val):
		spawn_degree = val
		_update_position()

func get_target_global_position() -> Vector2:
	if Global.held_sprites.size() > 0 and is_instance_valid(Global.held_sprites[0]):
		var sprite_node = Global.held_sprites[0].get_node_or_null("%Sprite2D")
		if sprite_node != null and is_instance_valid(sprite_node):
			return sprite_node.global_position
		return Global.held_sprites[0].global_position
	return get_parent().global_position

func update_polar_from_position():
	if not is_inside_tree(): return
	var target_local = get_parent().to_local(get_target_global_position())
	var relative_pos = position - target_local
	spawn_distance = relative_pos.length()
	spawn_degree = rad_to_deg(atan2(relative_pos.x, -relative_pos.y))

func _update_position():
	if not is_inside_tree(): return
	var rad = deg_to_rad(spawn_degree)
	var offset = Vector2(sin(rad), -cos(rad)) * spawn_distance
	var target_global = get_target_global_position()
	position = get_parent().to_local(target_global + offset)

func _ready() -> void:
	Global.mode_changed.connect(show_pointer)
	Global.throwable_spawner = self
	update_polar_from_position()

func show_pointer(mode : int):
	match mode:
		0:
			%Pointer.show()
		_:
			%Pointer.hide()

func _process(_delta: float) -> void:
	if GlobInput.is_action_just_pressed('throwing'):
		throw_item()
	if GlobInput.is_action_just_pressed("throwing_pause"):
		toggle_pause()
	_update_position()

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
		var data : ThrowableResource = selected_items.pick_random()
		spawn.throw_resource = data
		spawn.set_data(base_mass)
		
		var is_flipped = current_both_sides and randf() > 0.5
		
		var target_global_pos = get_target_global_position()
		var randomized_angle = deg_to_rad(spawn_degree + randf_range(-current_variance, current_variance))
		var offset_from_target = Vector2(sin(randomized_angle), -cos(randomized_angle)) * spawn_distance
		if is_flipped:
			offset_from_target.x = -offset_from_target.x
			
		var spawn_global_pos = target_global_pos + offset_from_target
		spawn.position = to_local(spawn_global_pos)
		add_child(spawn)
		
		var impulse_dir = (target_global_pos - spawn_global_pos).normalized()
		var impulse = impulse_dir * throw_force
		spawn.apply_central_impulse(impulse)
		
		await get_tree().create_timer(randf_range(0.05, time_variance)).timeout

func throw_specific_item(img_data: ImageData, amount: int = 1, custom_variance: float = -1.0, custom_both_sides: int = -1):
	is_paused = false
	
	var my_generation = current_throw_generation
	var current_variance = spawn_variance if custom_variance < 0 else custom_variance
	var current_both_sides = both_sides if custom_both_sides < 0 else bool(custom_both_sides)

	for i in amount:
		if is_paused or current_throw_generation != my_generation: break
		var spawn : ThrowableObject = throwable.instantiate()
		var find_match : ThrowableResource
		for l in selected_items:
			if  l.image_data == img_data:
				find_match = l
				break
			
		spawn.throw_resource = find_match
		spawn.set_data(base_mass)
		
		var is_flipped = current_both_sides and randf() > 0.5
		
		var target_global_pos = get_target_global_position()
		var randomized_angle = deg_to_rad(spawn_degree + randf_range(-current_variance, current_variance))
		var offset_from_target = Vector2(sin(randomized_angle), -cos(randomized_angle)) * spawn_distance
		if is_flipped:
			offset_from_target.x = -offset_from_target.x
			
		var spawn_global_pos = target_global_pos + offset_from_target
		spawn.position = to_local(spawn_global_pos)
		add_child(spawn)
		
		var impulse_dir = (target_global_pos - spawn_global_pos).normalized()
		var impulse = impulse_dir * throw_force
		spawn.apply_central_impulse(impulse)
		
		await get_tree().create_timer(randf_range(0.05, time_variance)).timeout
