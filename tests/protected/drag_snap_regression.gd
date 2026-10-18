extends RefCounted

# Compatibility contract from the user's V1.4.5 Windows runtime.
func run(check: Callable) -> void:
	var actor = Engine.get_main_loop().get_nodes_in_group("Sprites")[0]
	var saved_states = actor.states.duplicate(true)
	var saved_data = actor.sprite_data.duplicate(true)
	var modifier = actor.get_node("%Modifier")
	var dragger = actor.get_node("%Dragger")
	var movement = actor.get_node("%Movements")
	var saved_modifier = modifier.global_position
	var saved_dragger = dragger.global_position
	actor.states = [saved_data.duplicate(true)]
	actor.states[0].shared_movement = true
	for threshold in [30.0, 200.0, 999999.0]:
		actor.position = Vector2.ZERO
		actor.states[0].position = Vector2(200, 0)
		actor.states[0].drag_snap = threshold
		dragger.global_position = Vector2(-50, -20)
		var before = dragger.global_position
		actor.get_state(0)
		if threshold == 30.0:
			check.call(dragger.global_position.is_equal_approx(modifier.global_position), "Drag Snap resets follower on state jump")
		else:
			check.call(dragger.global_position.is_equal_approx(before), "Drag Snap retains follower at boundary/disabled threshold")
	actor.position = Vector2(200, 0)
	actor.scale = Vector2.ONE
	actor.rotation = 0
	actor.global_position = Vector2(200, 0)
	actor.sprite_data.dragSpeed = 20.0
	actor.sprite_data.shared_movement = true
	modifier.global_position = Vector2(200, 0)
	dragger.global_position = Vector2.ZERO
	movement.last_wobble_pos = Vector2.ZERO
	movement.applied_pos = Vector2.ZERO
	movement.drag(1.0 / 60.0)
	# Original runtime: follower reaches x=10, local x=-190, half-weight output=-95.
	check.call(movement.applied_pos.is_equal_approx(Vector2(-95, 0)), "drag smoothing matches localized V1.4.5 reference")
	actor.states = saved_states
	actor.sprite_data = saved_data
	actor.get_state(Global.current_state)
	modifier.global_position = saved_modifier
	dragger.global_position = saved_dragger
