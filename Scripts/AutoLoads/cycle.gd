extends Node

func _physics_process(_delta: float) -> void:
	update_cycles()

func update_cycles(settings_dict = Global.settings_dict):
	for cycle in settings_dict.cycles:
		if cycle.sprites.size() == 0:
			continue
		var toggle = cycle.get("toggle", null)
		var forward = cycle.get("forward", null)
		var backward = cycle.get("backward", null)

		if toggle != null:
			if cycle.toggle is InputEventKey and GlobInput.is_key_just_pressed(cycle.toggle.keycode):
				toggle_cycle(cycle)
			elif cycle.toggle is InputEventMouseButton and GlobInput.is_mouse_just_pressed(cycle.toggle.button_index):
				toggle_cycle(cycle)

		if forward != null:
			if cycle.forward is InputEventKey and GlobInput.is_key_just_pressed(cycle.forward.keycode):
				toggle_forward(cycle)
			elif cycle.forward is InputEventMouseButton and GlobInput.is_mouse_just_pressed(cycle.forward.button_index):
				toggle_forward(cycle)

		if backward != null:
			if cycle.backward is InputEventKey and GlobInput.is_key_just_pressed(cycle.backward.keycode):
				toggle_backward(cycle)
			elif cycle.backward is InputEventMouseButton and GlobInput.is_mouse_just_pressed(cycle.backward.button_index):
				toggle_backward(cycle)

func toggle_cycle(cycle):
	if cycle.sprites.size() < 1 : return
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
	if cycle.sprites.size() < 1 : return
	cycle.active = true
	cycle.pos = wrap(cycle.pos + 1, 0, cycle.sprites.size())
	cycle.last_sprite = cycle.sprites[cycle.pos]
	var sprite_found : bool = false
	var sp : SpriteObject = null
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").hide()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible
		if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
			sprite_found = true
			sp = sprite

	if sprite_found:
		sp.get_node("%Sprite2D").show()
		sp.was_active_before = sp.get_node("%Sprite2D").visible
	else:
		cycle.sprites.erase(cycle.pos)
		toggle_forward(cycle)
		return

func toggle_backward(cycle):
	if cycle.sprites.size() < 1 : return
	cycle.active = true
	cycle.pos = wrap(cycle.pos - 1, 0, cycle.sprites.size())
	cycle.last_sprite = cycle.sprites[cycle.pos]
	var sprite_found : bool = false
	var sp : SpriteObject = null
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
			sprite.get_node("%Sprite2D").hide()
			sprite.was_active_before = sprite.get_node("%Sprite2D").visible
		if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
			sprite_found = true
			sp = sprite

	if sprite_found:
		sp.get_node("%Sprite2D").show()
		sp.was_active_before = sp.get_node("%Sprite2D").visible
	else:
		cycle.sprites.erase(cycle.pos)
		toggle_backward(cycle)
		return

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
