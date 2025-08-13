extends SpriteObject


var smooth_rot = 0.0
var smooth_glob = Vector2(0.0,0.0)


func get_default_object_data() -> Dictionary:
	return {
		wiggle_segm = 5,
		wiggle_curve = 0,
		wiggle_stiff = 20,
		wiggle_max_angle = 0.5,
		wiggle_physics_stiffness = 2.5,
		wiggle_gravity = Vector2(0,0),
		wiggle_closed_loop = false,
		width = 80,
		segm_length = 30,
		subdivision = 5,
		auto_wag = false,
		wag_mini = -180,
		wag_max = 180,
		wag_speed = 0.5,
		wag_freq = 0.02,
		
		max_angular_momentum = 15,
		damping = 5,
		comeback_speed = 0.419,
		flip_h = false,
		flip_v = false,
		pixel_art = false,
		
		tile = 2,
		anchor_id = null,
	}

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reparent_objects.connect(reparent_obj)
	Global.reparent_objects.connect(set_anchor_sprite)
	%Dragger.top_level = true
	%Dragger.global_position = %Pos.global_position
	set_process(true)
	update_wiggle_parts()
	Global.reinfo.connect(sel)
	Global.deselect.connect(desel)

func sel():
	if self in Global.held_sprites:
		selected = true
		%Origin.show()
		%Grab.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP
		%Grab.texture_normal.width =  %Sprite2D.texture.get_image().get_size().x/2
		%Grab.texture_normal.height = get_value("width")
		%Grab.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		%Grab.position.x -= %Grab.texture_normal.width/2
	else:
		%Origin.hide()
		desel()

func desel():
	%Origin.hide()
	selected = false


func correct_sprite_size():
	var w = %Sprite2D.texture.get_image().get_size().y / 0.98
	var l = %Sprite2D.texture.get_image().get_size().x / 5
	
	sprite_data.width = w
	sprite_data.segm_length = l

func _process(_delta):
	if selected:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
		%Selection.show()
	else:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		%Selection.hide()
	#	%Origin.mouse_filter = 2
	if dragging:
		var mpos = get_parent().to_local(get_global_mouse_position())
		position = mpos - of
		sprite_data.position = position
		save_state(Global.current_state)
		Global.update_pos_spins.emit()
	
	
	if !Global.static_view:
		if get_value("auto_wag"):
			%Sprite2D.curvature = clamp(sin(Global.tick*(get_value("wag_freq")))*get_value("wag_speed"), deg_to_rad(get_value("wag_mini")), deg_to_rad(get_value("wag_max")))
	else:
		if get_value("auto_wag"):
			%Sprite2D.curvature = 0.0
		
	%Grab.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT

func wiggle_sprite():
	var wiggle_val = sin(Global.tick*get_value("wiggle_freq"))*get_value("wiggle_amp")
	if get_value("wiggle_physics"):
		if get_parent() is Sprite2D or get_parent() is WigglyAppendage2D:
			var c_parent = get_parent().owner
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			wiggle_val = wiggle_val + (c_parrent_length/10)
		
		
	%Sprite2D.material.set_shader_parameter("rotation", wiggle_val )

func save_state(id):
	var dict : Dictionary = sprite_data.duplicate()
	states[id] = dict

func get_state(id):
	if not states[id].is_empty():
		var dict = states[id]
		sprite_data.merge(dict, true)
		%Rotation.z_index = get_value("z_index")
		modulate = get_value("colored")
		visible = get_value("visible")
		scale = get_value("scale")
	#	global_position = get_value("global_position")
		if get_value("should_reset_state"):
			%ReactionConfig.reset_anim()
	
		position = get_value("position")
		%Sprite2D.position = get_value("offset") 
		%Sprite2D.scale = Vector2(1,1)
		
		%Sprite2D.closed = get_value("wiggle_closed_loop")
		%Sprite2D.gravity = get_value("wiggle_gravity")
		
		%Sprite2D.texture_mode = get_value("tile")
		
		%Sprite2D.set_clip_children_mode(get_value("clip"))
		rotation = get_value("rotation")

		if get_value("flip_h"):
			%Sprite2D.scale.x = -1
		else:
			%Sprite2D.scale.x = 1
		if get_value("flip_v"):
			%Sprite2D.scale.y = -1
		else:
			%Sprite2D.scale.y = 1
		if get_value("pixel_art"):
			%Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			%Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		
		if !get_value("should_blink"):
			%Pos.show()
		else:
			%ReactionConfig.update_to_mode_change(Global.mode)
			
		update_wiggle_parts()
		set_anchor_sprite()
#		animation()
		set_blend(get_value("blend_mode"))
		if get_value("one_shot"):
			if is_apng:
				%AnimatedSpriteTexture.index = 0
				%AnimatedSpriteTexture.proper_apng_one_shot()
				
		if !get_value("cycle") in range(Global.settings_dict.cycles.size()):
			sprite_data.cycle = 0
				
	elif states[id].is_empty():
		states[id] = sprite_data.duplicate(true)

func set_anchor_sprite(_placeholder = null):
	if get_value("anchor_id") == null:
		%Sprite2D.anchor_target = null
	else:
		for i in get_tree().get_nodes_in_group("Sprites"):
			if i.sprite_id == get_value("anchor_id"):
				%Sprite2D.anchor_target = i.get_node("%Sprite2D")
				return
			else:
				%Sprite2D.anchor_target = null



func update_wiggle_parts():
	if %Sprite2D.segment_count != get_value("wiggle_segm"):
		%Sprite2D.segment_count = get_value("wiggle_segm")
	if %Sprite2D.curvature != get_value("wiggle_curve"):
		%Sprite2D.curvature = get_value("wiggle_curve")
	if %Sprite2D.stiffness != get_value("wiggle_stiff"):
		%Sprite2D.stiffness = get_value("wiggle_stiff")
	if %Sprite2D.max_angle != get_value("wiggle_max_angle"):
		%Sprite2D.max_angle = get_value("wiggle_max_angle")
	
	if %Sprite2D.width != get_value("width"):
		%Sprite2D.width = get_value("width")
	if %Sprite2D.segment_length != get_value("segm_length"):
		%Sprite2D.segment_length = get_value("segm_length")
	if %Sprite2D.subdivision!= get_value("subdivision"):
		%Sprite2D.subdivision = get_value("subdivision")
		
	if %Sprite2D.comeback_speed!= get_value("comeback_speed"):
		%Sprite2D.comeback_speed = get_value("comeback_speed")
		
	if %Sprite2D.max_angular_momentum!= get_value("max_angular_momentum"):
		%Sprite2D.max_angular_momentum = get_value("max_angular_momentum")
		
	if %Sprite2D.damping!= get_value("damping"):
		%Sprite2D.damping = get_value("damping")

func check_talk():
	if get_value("should_talk"):
		if get_value("open_mouth"):
			%Rotation.hide()
		else:
			%Rotation.show()

func _on_grab_button_down():
	if selected:
		of = get_parent().to_local(get_global_mouse_position()) - position
		dragging = true

func _on_grab_button_up():
	if selected:
		dragging = false
		save_state(Global.current_state)

func _input(event: InputEvent) -> void:
	if event.is_action_released("lmb"):
		if selected && dragging:
			save_state(Global.current_state)
			dragging = false
