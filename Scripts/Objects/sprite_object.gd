extends SpriteObject

func get_default_object_data() -> Dictionary:
	return {
		vframes = 1,
		wiggle = false,
		wiggle_amp = 0,
		wiggle_freq = 0,
		wiggle_physics = false,
		wiggle_rot_offset = Vector2(0.5, 0.5),
		follow_parent_effects = false,
		flip_sprite_h = false,
		flip_sprite_v = false,
		pixel_art_sprite = false,
		non_animated_sheet = false,
		animate_to_mouse = false,
		animate_to_mouse_speed = 10,
		animate_to_mouse_track_pos = true,
		frame = 0,
	}

var wiggle_val : float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reparent_objects.connect(reparent_obj)
	og_glob = get_value("position")
	animation()
	%Dragger.top_level = true
	%Dragger.global_position = %Pos.global_position
	Global.reinfo.connect(sel)
	Global.deselect.connect(desel)

func sel():
	if self in Global.held_sprites:
		selected = true
		%Origin.show()
		if get_value("folder"):
			%Grab.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP
			%Grab.texture_normal.width = 500
			%Grab.texture_normal.height = 500
		%Grab.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		%Grab.modulate.a = 1.0
	else:
		%Origin.hide()

		desel()

func desel():
	%Origin.hide()
	selected = false

func animation():
	if not get_value("non_animated_sheet"):
		if not get_value("advanced_lipsync"):
			%Sprite2D.hframes = get_value("hframes")
			%Sprite2D.vframes = get_value("vframes")
			if get_value("hframes") > 1 or get_value("vframes") > 1:
				if get_value("one_shot") &&  %Sprite2D.frame == (get_value("hframes")*get_value("vframes")) - 1:
					return
				%Sprite2D.frame = wrapi(%Sprite2D.frame + 1, 0, (get_value("hframes")*get_value("vframes")))
			else:
				%Sprite2D.frame = 0

	elif get_value("non_animated_sheet"):
		%Sprite2D.hframes = get_value("hframes")
		%Sprite2D.vframes = get_value("vframes")
		if (get_value("hframes")*get_value("vframes")) - 1 > 1:
			if !get_value("animate_to_mouse"):
				%Sprite2D.frame = get_value("frame")
	
	$Animation.wait_time = 1.0/get_value("animation_speed") 
	$Animation.start()

func _process(_delta):
	if selected:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
		%Selection.texture = %Sprite2D.texture
		%Selection.show()
		%Selection.hframes = %Sprite2D.hframes
		%Selection.vframes = %Sprite2D.vframes
		%Selection.frame = %Sprite2D.frame
		%Selection.flip_h = %Sprite2D.flip_h
		%Selection.flip_v = %Sprite2D.flip_v
		
		if get_value("wiggle"):
			%WiggleOrigin.show()
			var pos = (%Sprite2D.material.get_shader_parameter("rotation_offset") * %Sprite2D.texture.get_size())/2
			%WiggleOrigin.position = Vector2(pos.x, pos.y)
			%Selection.material.set_shader_parameter("wiggle", true)
			%Selection.material.set_shader_parameter("rotation_offset", %Sprite2D.material.get_shader_parameter("rotation_offset"))
			%Selection.material.set_shader_parameter("rotation", %Sprite2D.material.get_shader_parameter("rotation"))
		else:
			%Selection.material.set_shader_parameter("wiggle", false)
			%WiggleOrigin.hide()
		
	else:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		%Selection.hide()
		%Grab.modulate.a = 0.0
		%WiggleOrigin.hide()
	
	if dragging:
		var mpos = get_parent().to_local(get_global_mouse_position())
		position = mpos - of
		sprite_data.position = position
		save_state(Global.current_state)
		Global.update_pos_spins.emit()
		
	if !Global.static_view:
		if get_value("wiggle"):
			wiggle_sprite()
	else:
		if get_value("wiggle"):
			%Sprite2D.material.set_shader_parameter("rotation", 0)
		
	advanced_lipsyc()

func wiggle_sprite():
	var length : float = 1.0
	
	if get_value("wiggle_physics"):
		if (get_parent() is Sprite2D  or get_parent() is WigglyAppendage2D) && is_instance_valid(get_parent()):
			var c_parent = get_parent().owner
			if c_parent != null && is_instance_valid(c_parent):
				var c_parrent_length = (c_parent.get_node("Movements").glob.y - c_parent.get_node("%Drag").global_position.y)
				var c_parrent_length2 = (c_parent.get_node("%Movements").glob.x - c_parent.get_node("%Drag").global_position.x)
				length +=((c_parrent_length + c_parrent_length2)/20)
	
	
	wiggle_val = lerp(wiggle_val, sin((Global.tick*length) + get_value("wiggle_freq"))*get_value("wiggle_amp"), 0.05)
	
	if !get_parent() is Sprite2D:
		%Sprite2D.material.set_shader_parameter("rotation", wiggle_val )
	elif get_parent() is Sprite2D:
		if get_value("follow_parent_effects"):
			var c_parent = get_parent().owner
			%Sprite2D.material.set_shader_parameter("rotation", c_parent.get_node("%Sprite2D").material.get_shader_parameter("rotation"))
		else:
			%Sprite2D.material.set_shader_parameter("rotation", wiggle_val )

func advanced_lipsyc():
	if get_value("advanced_lipsync"):
		if %Sprite2D.hframes != 14:
			%Sprite2D.hframes = 14
		if %ReactionConfig.currently_speaking:
			if GlobalAudioStreamPlayer.t.value == 0:
				%Sprite2D.frame_coords.x = 13
			else:
				%Sprite2D.frame_coords.x = GlobalAudioStreamPlayer.t.actual_value
		else:
			%Sprite2D.frame_coords.x = 13

func save_state(id):
	var dict : Dictionary = sprite_data.duplicate(true)
	states[id] = dict

func get_state(id):
	if !states[id].is_empty():
		var dict = states[id]
		sprite_data.merge(dict, true)
		
		
		if get_value("should_reset_state"):
			%ReactionConfig.reset_anim()
		
		%Sprite2D.position = get_value("offset") 
		%Sprite2D.scale = Vector2(1,1)
		
		%Rotation.z_index = get_value("z_index")
		modulate = get_value("colored")
		scale = get_value("scale")
	#	global_position = get_value("global_position")
		position = get_value("position")

		%Sprite2D.set_clip_children_mode(get_value("clip"))
		rotation = get_value("rotation")
		%Sprite2D.material.set_shader_parameter("wiggle", get_value("wiggle"))
		%Sprite2D.material.set_shader_parameter("rotation_offset", get_value("wiggle_rot_offset"))
		
		if get_value("flip_sprite_h"):
			%Sprite2D.scale.x = -1
		else:
			%Sprite2D.scale.x = 1
		
		if get_value("flip_sprite_v"):
			%Sprite2D.scale.y = -1
		else:
			%Sprite2D.scale.y = 1

		if get_value("pixel_art_sprite"):
			%Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			%Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

		if get_value("advanced_lipsync"):
			%Sprite2D.hframes = 6
		
		if !get_value("should_blink"):
			%Pos.show()
		else:
			%ReactionConfig.update_to_mode_change(Global.mode)

		visible = get_value("visible")
		
		animation()
		set_blend(get_value("blend_mode"))
		advanced_lipsyc()
			
		if !get_value("cycle") in range(Global.settings_dict.cycles.size()):
			sprite_data.cycle = 0
		
		
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

func _on_grab_button_down():
	if selected:
		if not Input.is_action_pressed("ctrl"):
			of = get_parent().to_local(get_global_mouse_position()) - position
			dragging = true

func _on_grab_button_up():
	if selected && dragging:
		save_state(Global.current_state)
		dragging = false

func _input(event: InputEvent) -> void:
	if event.is_action_released("lmb"):
		if selected && dragging:
			save_state(Global.current_state)
			dragging = false

func zazaza(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			sprite_data.position -= i.get_value("offset")
			if is_plus_first_import:
				for state in states:
					if !state.is_empty():
						global = global_position
						state.position = get_value("position")
