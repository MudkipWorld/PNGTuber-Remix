extends Node2D

signal blink

@warning_ignore("unused_signal")
signal reinfo
signal animation_state
signal light_info
@warning_ignore("unused_signal")
signal speaking
@warning_ignore("unused_signal")
signal not_speaking
signal reinfoanim

@warning_ignore("unused_signal")
signal mode_changed
@warning_ignore("unused_signal")
signal deselect
@warning_ignore("unused_signal")
signal theme_update

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
	bounceGravity = 575,
	bounceSlider = 250,
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
	max_fps = 241,
}

var mode : int = 0 : 
	set(nmode):
		mode = nmode
		mode_changed.emit(nmode)
		
#var undo_redo : UndoRedo = UndoRedo.new()
var new_rot = 0
var static_view : bool = false
var spinbox_held : bool = false

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
	if held_bg_sprite != null:
		if Input.is_action_pressed("ctrl"):
			if Input.is_action_pressed("scrollup"):
				held_bg_sprite.rotation -= 0.05
				bg_rot()

			elif Input.is_action_pressed("scrolldown"):
				held_bg_sprite.rotation += 0.05
				bg_rot()
	
	if held_sprite != null:
		if Input.is_action_pressed("ctrl"):
			if Input.is_action_pressed("scrollup"):
				held_sprite.dictmain.rotation -= 0.05
				rot()

			elif Input.is_action_pressed("scrolldown"):
				held_sprite.dictmain.rotation += 0.05
				rot()






func offset():
	held_sprite.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	held_sprite.dictmain.position = held_sprite.position
	held_sprite.dictmain.offset = held_sprite.get_node("%Sprite2D").position
	held_sprite.save_state(current_state)

	get_tree().get_root().get_node("Main/Control/UIInput").update_offset()


func bg_rot():
	held_bg_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/BackgroundEdit").update_pos_spins()


func _process(delta):
	if settings_dict.should_delta:
		tick = wrap(tick + delta, 0, 922337203685477630)
	elif !settings_dict.should_delta:
		tick = wrap(tick + 1, 0, 922337203685477630)
	#	print(tick)
	if !spinbox_held:
		moving_origin(delta)
		moving_sprite(delta)

func moving_origin(delta):
	if held_sprite != null:
		if Input.is_action_pressed("ui_up"):
			held_sprite.get_node("%Sprite2D").position.y += 10 * delta
			held_sprite.position.y -= 10 * delta
			offset()
		elif Input.is_action_pressed("ui_down"):
			held_sprite.get_node("%Sprite2D").position.y -= 10 * delta
			held_sprite.position.y += 10 * delta
			offset()
		if Input.is_action_pressed("ui_left"):
			held_sprite.get_node("%Sprite2D").position.x += 10 * delta
			held_sprite.position.x -= 10 * delta
			offset()
		elif Input.is_action_pressed("ui_right"):
			held_sprite.get_node("%Sprite2D").position.x -= 10 * delta
			held_sprite.position.x += 10 * delta

			offset()
			
			
		if get_tree().get_root().get_node("Main").can_scroll:
			if Input.is_action_pressed("ctrl"):
				if Input.is_action_just_pressed("lmb"):
					var of = held_sprite.get_parent().to_local(held_sprite.get_parent().get_global_mouse_position()) - held_sprite.position
					held_sprite.position += of
					held_sprite.get_node("%Sprite2D").position -= of

					offset()


func rot():
	held_sprite.rotation = held_sprite.dictmain.rotation
	held_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()



func moving_sprite(delta):
	if held_sprite != null:
		if Input.is_action_pressed("w"):
			held_sprite.position.y -= 10 * delta
			held_sprite.dictmain.position.y -= 10 * delta
			update_spins()
		elif Input.is_action_pressed("s"):
			held_sprite.position.y += 10 * delta
			held_sprite.dictmain.position.y += 10 * delta
			update_spins()
			
		if Input.is_action_pressed("a"):
			held_sprite.position.x -= 10 * delta
			held_sprite.dictmain.position.x -= 10 * delta
			update_spins()
			
		elif Input.is_action_pressed("d"):
			held_sprite.position.x += 10 * delta
			held_sprite.dictmain.position.x += 10 * delta
			update_spins()

func update_spins():
	held_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()
