extends SpriteObject

@export var mesh : CustomMesh


func get_default_object_data() -> Dictionary:
	return {
		move_with_wobble = true,
		move_with_follow= true,
		flip_sprite_h = false,
		flip_sprite_v = false,
	}

func _init() -> void:
	referenced_data = Global.image_data
	cached_defaults = DEFAULT_DATA.merged(get_default_object_data(), true)
	sprite_data = cached_defaults.duplicate(true)

func _ready():
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
		%Selection.show()
		
	else:
		%Sprite2D.editable = false
		%Origin.hide()
		%Selection.hide()

		desel()

func desel():
	%Sprite2D.editable = false
	%MeshEditor.queue_redraw()
	%Origin.hide()
	selected = false

func _process(_delta):
	if selected:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
		%Selection.show()
		
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
	if !mesh.editable:
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
		var old_glob = global_position
		position = get_value("position")
		%Sprite2D.position = get_value("offset") 
		%Sprite2D.scale = Vector2(1,1)
		if get_value("flip_sprite_h"):
			%Sprite2D.scale.x = -1
		else:
			%Sprite2D.scale.x = 1
		
		if get_value("flip_sprite_v"):
			%Sprite2D.scale.y = -1
		else:
			%Sprite2D.scale.y = 1
		
		%Modifier1.z_index = get_value("z_index")
		modulate = get_value("colored")
		scale = get_value("scale")
		if (global_position - old_glob).length() > get_value("drag_snap") && get_value("drag_snap") != 999999.0:
			%Modifier.global_position = %Modifier1.global_position
		%Sprite2D.set_clip_children_mode(get_value("clip"))
		
		rotation = get_value("rotation")
		if !get_value("should_blink"):
			%Modifier1.show()
		else:
			%ReactionConfig.update_to_mode_change(Global.mode)

		if get_value("fade"):
			trigger_fade(visible)
		else:
			modulate.a = 1.0
			visible = get_value("visible")
		
	elif states[id].is_empty():
		states[id] = sprite_data.duplicate(true)
	
	mesh.queue_redraw()

func check_talk():
	if get_value("should_talk"):
		if get_value("open_mouth"):
			%Rotation.hide()
		else:
			%Rotation.show()
	else:
		%Rotation.show()

func zazaza(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			sprite_data.position -= i.get_value("offset")
			if is_plus_first_import:
				for state in states:
					if !state.is_empty():
						global = global_position
						state.position = get_value("position")

func _on_sprite_2d_text_changed() -> void:
	sprite_data.text_data = %Sprite2D.text
	save_state(Global.current_state)

func update_mesh_data():
	if mesh.get_layer_count() < Global.selected_mesh_inx:
		return
	
	var _layer = mesh.get_layer(Global.selected_mesh_inx)
	pass
