extends Node2D

signal blink
signal reinfo
signal animation_state
signal light_info
signal speaking
signal not_speaking
signal reinfoanim

var blink_timer : Timer = Timer.new()
var held_sprite = null
var held_bg_sprite = null
var tick = 0
var current_state : int = 0

var settings_dict : Dictionary = {
	sensitivity_limit = 1,
	volume_limit = 0.1,
	volume_delay = 0.5,
	blink_speed = 1,
	checkinput = true,
	bg_color = Color.SLATE_GRAY,
	is_transparent = false,
	bounceGravity = 1000,
	bounceSlider = 100,
	states = [{}],
	light_states = [{}],
	darken = false,
	anti_alias = true,
	bounce_state = false,
	
	xFrq = 0.3,
	xAmp = 5,
	yFrq = 0.4,
	yAmp = 5,
	
	dim_color = Color.DIM_GRAY,
	auto_save = false,
	auto_save_timer = 1.0,
	
	saved_inputs = [],
	zoom = Vector2(1,1),
	pan = Vector2(640, 360),
	
	should_delta = false,
}

#var undo_redo : UndoRedo = UndoRedo.new()
var new_rot = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().min_size = Vector2(1000,720)
	add_child(blink_timer)
	blinking()
	get_window().title = "PNGTube-Remix V" + str(ProjectSettings.get_setting("application/config/version"))
	current_state = 0

func blinking():
	blink_timer.wait_time = randf_range(1,5) * settings_dict.blink_speed
	blink_timer.start()
	await blink_timer.timeout
	blink.emit()
	blinking()

func load_sprite_states(state):
	current_state = state
	for i in get_tree().get_nodes_in_group("Sprites"):
		i.get_state(current_state)
	if held_sprite != null:
		emit_signal("reinfo")
		
	animation_state.emit(current_state)
	light_info.emit(current_state)
	reinfoanim.emit()

func get_sprite_states(state):
	if state != current_state:
		for i in get_tree().get_nodes_in_group("Sprites"):
			i.save_state(current_state)
	
	current_state = state
	for i in get_tree().get_nodes_in_group("Sprites"):
		i.get_state(current_state)
	if held_sprite != null:
		emit_signal("reinfo")
		
	animation_state.emit(current_state)
	light_info.emit(current_state)
	reinfoanim.emit()


func _input(_event : InputEvent):
	if Input.is_action_pressed("ctrl"):
		if Input.is_action_pressed("scrollup"):
			new_rot += 0.05
		elif Input.is_action_just_released("scrollup"):
			rot(new_rot)
			new_rot = 0
		if Input.is_action_pressed("scrolldown"):
			new_rot -= 0.05
			
		elif Input.is_action_just_released("scrolldown"):
			rot(new_rot)
			new_rot = 0
			
		if Input.is_action_pressed("w"):
			held_sprite.position.y -= 1
			held_sprite.dictmain.position.y -= 1
			held_sprite.save_state(current_state)
		elif Input.is_action_pressed("s"):
			held_sprite.position.y += 1
			held_sprite.dictmain.position.y += 1
			held_sprite.save_state(current_state)
			
		if Input.is_action_pressed("a"):
			held_sprite.position.x -= 1
			held_sprite.dictmain.position.x -= 1
			held_sprite.save_state(current_state)
			
		elif Input.is_action_pressed("d"):
			held_sprite.position.x += 1
			held_sprite.dictmain.position.x += 1
			held_sprite.save_state(current_state)
			
			
			
			
			
			
		if Input.is_action_pressed("ctrl"):
			if Input.is_action_pressed("scrollup"):
				new_rot += 0.05
			elif Input.is_action_just_released("scrollup"):
				rot(new_rot)
				new_rot = 0
			if Input.is_action_pressed("scrolldown"):
				new_rot -= 0.05
				
			elif Input.is_action_just_released("scrolldown"):
				rot(new_rot)
				new_rot = 0
				
				
				
			if Input.is_action_just_pressed("lmb"):
				var sprite_pos := held_sprite.get_node("%Sprite2D").global_position as Vector2
				held_sprite.global_position = held_sprite.get_global_mouse_position()
				held_sprite.get_node("%Sprite2D").global_position = sprite_pos
				offset()
			
			''' TO DO - > Being able to drag the Origin point.
			if Input.is_action_pressed("lmb"):
				var of = get_local_mouse_position() - (Vector2(get_window().size.x,get_window().size.y)/2)
				held_sprite.get_node("%Sprite2D").position = -of
			#	held_sprite.position = of
				offset()
			'''
			
	if held_bg_sprite != null:
		if Input.is_action_pressed("ctrl"):
			if Input.is_action_pressed("scrollup"):
				held_bg_sprite.rotation -= 0.05
				bg_rot()

			elif Input.is_action_pressed("scrolldown"):
				held_bg_sprite.rotation += 0.05
				bg_rot()

func offset():
	held_sprite.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	held_sprite.dictmain.position = held_sprite.position
	held_sprite.dictmain.offset = held_sprite.get_node("%Sprite2D").position
	held_sprite.save_state(current_state)

	get_tree().get_root().get_node("Main/Control/UIInput").update_offset()


func rot(_value):
	held_sprite.dictmain.rotation += _value
	held_sprite.rotation = held_sprite.dictmain.rotation
	held_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()

func bg_rot():
	held_bg_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/BackgroundEdit").update_pos_spins()


func _process(delta):
	if settings_dict.should_delta:
		tick = wrap(tick + delta, 0, 922337203685477630)
	elif !settings_dict.should_delta:
		tick = Time.get_ticks_msec() / 1000.0
	moving_origin(delta)
	rotating_sprite()
	moving_sprite(delta)

func moving_origin(delta):
	if held_sprite != null:
		if Input.is_action_pressed("ui_up"):
			held_sprite.get_node("%Sprite2D").position.y += 1 * delta
			held_sprite.position.y -= 1 * delta
			offset()
		elif Input.is_action_pressed("ui_down"):
			held_sprite.get_node("%Sprite2D").position.y -= 1 * delta
			held_sprite.position.y += 1 * delta
			offset()
		if Input.is_action_pressed("ui_left"):
			held_sprite.get_node("%Sprite2D").position.x += 1 * delta
			held_sprite.position.x -= 1 * delta
			offset()
		elif Input.is_action_pressed("ui_right"):
			held_sprite.get_node("%Sprite2D").position.x -= 1 * delta
			held_sprite.position.x += 1 * delta

			offset()
			
			

		if Input.is_action_pressed("ctrl"):
			if Input.is_action_just_pressed("lmb"):
				var of = get_local_mouse_position() - (Vector2(get_window().size.x,get_window().size.y)/2)
				var sprite_of = held_sprite.position - of
				held_sprite.get_node("%Sprite2D").position += sprite_of
				held_sprite.position -= sprite_of
				offset()

func rotating_sprite():
	if held_bg_sprite != null:
		if Input.is_action_pressed("ctrl"):
			if Input.is_action_pressed("scrollup"):
				held_bg_sprite.rotation -= 0.05
				bg_rot()

			elif Input.is_action_pressed("scrolldown"):
				held_bg_sprite.rotation += 0.05
				bg_rot()

func moving_sprite(delta):
	if held_sprite != null:
		if Input.is_action_pressed("w"):
			held_sprite.position.y -= 1 * delta
			held_sprite.dictmain.position.y -= 1 * delta
			update_spins()
		elif Input.is_action_pressed("s"):
			held_sprite.position.y += 1 * delta
			held_sprite.dictmain.position.y += 1 * delta
			update_spins()
			
		if Input.is_action_pressed("a"):
			held_sprite.position.x -= 1 * delta
			held_sprite.dictmain.position.x -= 1 * delta
			update_spins()
			
		elif Input.is_action_pressed("d"):
			held_sprite.position.x += 1 * delta
			held_sprite.dictmain.position.x += 1 * delta
			update_spins()


func update_spins():
	held_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()
