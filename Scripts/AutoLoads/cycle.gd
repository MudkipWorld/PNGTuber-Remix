extends Node

func _physics_process(_delta: float) -> void:
	update_cycles()

func update_cycles(settings_dict = Global.settings_dict):
	for index in settings_dict.cycles.size():
		var cycle = settings_dict.cycles[index]
		if cycle.sprites.size() == 0:
			continue
		if event_pressed(index, "toggle", cycle.get("toggle")):
			toggle_cycle(cycle)
		if event_pressed(index, "forward", cycle.get("forward")):
			toggle_forward(cycle)
		if event_pressed(index, "backward", cycle.get("backward")):
			toggle_backward(cycle)

func event_pressed(index: int, action: String, event: InputEvent) -> bool:
	if ProtectionPolicy.is_player():
		var ui = get_node_or_null("/root/ProtectedUI")
		if ui != null and ui.cycle_bindings != null and ui.cycle_bindings.has_override(index, action):
			return GlobInput.is_action_just_pressed(ui.cycle_bindings.action_name(str(index) + ":" + action))
	if event is InputEventKey:
		return GlobInput.is_key_just_pressed(event.keycode)
	if event is InputEventMouseButton:
		return GlobInput.is_mouse_just_pressed(event.button_index)
	return false

func toggle_cycle(cycle):
	cycle.active = !cycle.active
	if cycle.active:
		var array = cycle.sprites.duplicate()
		if array.has(cycle.last_sprite):
			array.remove_at(array.find(cycle.last_sprite))
		if array.size() > 0:
			var rand = array.pick_random()
			cycle.last_sprite = rand
			cycle.pos = cycle.sprites.find(rand)

		for sprite in get_tree().get_nodes_in_group("Sprites"):
			if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
				sprite.get_node("%Sprite2D").hide()
				sprite.was_active_before = sprite.get_node("%Sprite2D").visible

			if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
				sprite.get_node("%Sprite2D").show()
				sprite.was_active_before = sprite.get_node("%Sprite2D").visible
	else:
		for sprite in get_tree().get_nodes_in_group("Sprites"):
			if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
				sprite.get_node("%Sprite2D").hide()
				sprite.was_active_before = sprite.get_node("%Sprite2D").visible

func toggle_forward(cycle):
	cycle.active = true
	cycle.pos = wrap(cycle.pos + 1, 0, cycle.sprites.size())
	cycle.last_sprite = cycle.sprites[cycle.pos]
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").hide()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible
		if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").show()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible

func toggle_backward(cycle):
	cycle.active = true
	cycle.pos = wrap(cycle.pos - 1, 0, cycle.sprites.size())
	cycle.last_sprite = cycle.sprites[cycle.pos]
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").hide()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible
		if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").show()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible

func toggle_to(cycle, pos):
	cycle.active = true
	cycle.pos = wrap(pos, 0, cycle.sprites.size())
	cycle.last_sprite = cycle.sprites[cycle.pos]
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").hide()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible
		if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").show()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible
