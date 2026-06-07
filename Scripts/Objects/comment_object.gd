extends SpriteObject

@export var comment_object : TextEdit


func get_default_object_data() -> Dictionary:
	return {
		text_data = "",
		hidden_item = true,
		
	}


func _init() -> void:
	cached_defaults = DEFAULT_DATA.merged(get_default_object_data(), true)
	sprite_data = cached_defaults.duplicate(true)

func _ready():
	sprite_type = "Sprite2D"
	Global.image_replaced.connect(image_replaced)
	Global.reparent_objects.connect(reparent_obj)
	og_glob = get_value("position")
	Global.reinfo.connect(sel)
	Global.deselect.connect(desel)
	grab_object.button_down.connect(_on_grab_button_down)
	grab_object.button_up.connect(_on_grab_button_up)

func sel():
	if self in Global.held_sprites:
		selected = true
		%Origin.show()
		%Grab.modulate.a = 1.0
		%Sprite2D.editable = true
		%Selection.show()
	else:
		%Sprite2D.editable = false
		%Origin.hide()
		%Selection.hide()

		desel()

func desel():
	%Sprite2D.editable = false
	%Origin.hide()
	selected = false

func _process(_delta):
	if selected:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
		%Selection.show()
		%Sprite2D.editable = true
		
	else:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		%Selection.hide()
		%Sprite2D.editable = false
		
	if dragging:
		var mouse_pos = get_parent().to_local(get_global_mouse_position())
		for s in Global.held_sprites:
			s.position = mouse_pos - drag_offsets[s]
			s.sprite_data.position = s.position
			s.save_state(Global.current_state)
		Global.update_pos_spins.emit()


func _on_grab_button_down():
	if selected:
		if not Input.is_action_pressed("ctrl"):
			dragging = true
			drag_offsets.clear()
			var mouse_pos = get_parent().to_local(get_global_mouse_position())
			for s in Global.held_sprites:
				drag_offsets[s] = mouse_pos - s.position

func _on_grab_button_up():
	if selected && dragging:
		save_state(Global.current_state)
		dragging = false

func _input(event: InputEvent) -> void:
	if event.is_action_released("lmb"):
		if selected && dragging:
			save_state(Global.current_state)
			dragging = false

func save_state(id):
	var dict : Dictionary = sprite_data.duplicate(true)
	states[id] = dict

func get_state(id):
	if !states[id].is_empty():
		var dict = states[id]
		sprite_data.merge(dict, true)
		if get_value("should_reset_state"):
			%ReactionConfig.reset_anim()
		
		var old_glob = global_position
		position = get_value("position")
		%Sprite2D.position = get_value("offset") 
		%Sprite2D.scale = Vector2(1,1)
		%Sprite2D.text = get_value("text_data") 
		
		%Modifier1.z_index = get_value("z_index")
		modulate = get_value("colored")
		%Sprite2D.self_modulate = get_value("tint")
		scale = get_value("scale")

		if (global_position - old_glob).length() > get_value("drag_snap") && get_value("drag_snap") != 999999.0:
			%Modifier.global_position = %Modifier1.global_position
			%Dragger.global_position = %Modifier.global_position
		
		%Sprite2D.set_clip_children_mode(get_value("clip"))
		rotation = get_value("rotation")


		if !get_value("should_blink"):
			%Modifier1.show()
		else:
			%ReactionConfig.update_to_mode_change(Global.mode)

		if get_value("fade"):
			trigger_fade(visible)
		else:
			modulate.a = get_value("colored").a
			visible = get_value("visible")
		
		if !get_value("should_blink"):
			%Modifier1.modulate.a = 1
			%Modifier1.show()
		
	elif states[id].is_empty():
		states[id] = sprite_data.duplicate(true)

func check_talk():
	if get_value("should_talk"):
		if get_value("open_mouth"):
			%Rotation.hide()
		else:
			%Rotation.show()
	else:
		%Rotation.show()

func _on_sprite_2d_text_changed() -> void:
	sprite_data.text_data = %Sprite2D.text
	save_state(Global.current_state)
