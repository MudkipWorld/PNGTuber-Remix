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
}

var undo_redo : UndoRedo = UndoRedo.new()
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

func _input(event : InputEvent):
	if held_sprite != null:
		if held_sprite.sprite_type == "Sprite2D":
			if Input.is_action_pressed("ui_up"):
				held_sprite.position.y -= 1
				held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D").position.y += 1
				offset()
			elif Input.is_action_pressed("ui_down"):
				held_sprite.position.y += 1
				held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D").position.y -= 1
				offset()
			if Input.is_action_pressed("ui_left"):
				held_sprite.position.x -= 1
				held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D").position.x += 1
				offset()
			elif Input.is_action_pressed("ui_right"):
				held_sprite.position.x += 1
				held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D").position.x -= 1

				offset()
			
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

				
			elif Input.is_action_pressed("lmb"):
				var of = get_local_mouse_position() - (Vector2(get_window().size.x,get_window().size.y)/2)
				held_sprite.position = of
				held_sprite.get_node("Pos//Wobble/Squish/Drag/Rotation/Sprite2D").position = -held_sprite.position
				offset()
			
			
	if held_bg_sprite != null:
		if Input.is_action_pressed("ctrl"):
			if Input.is_action_pressed("scrollup"):
				held_bg_sprite.rotation -= 0.05
				bg_rot()

			elif Input.is_action_pressed("scrolldown"):
				held_bg_sprite.rotation += 0.05
				bg_rot()
	if event.is_action_pressed("ui_undo"):
		undo_redo.undo()
		print(undo_redo.undo())
	elif event.is_action_pressed("ui_redo"):
		undo_redo.redo()
		print(undo_redo.redo())

func offset():
	held_sprite.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	held_sprite.dictmain.global_position = held_sprite.global_position
	held_sprite.dictmain.position = held_sprite.position
	held_sprite.dictmain.offset = -held_sprite.position
	held_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/UIInput").update_offset()
	get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()
	

func rot(value):
	var val = held_sprite.rotation + value
	undo_redo.create_action("zaza")
	undo_redo.add_undo_property(held_sprite, "rotation", held_sprite.rotation)
	undo_redo.add_do_property(held_sprite, "rotation", val)
	undo_redo.commit_action(true)
	held_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()

func bg_rot():
	held_bg_sprite.save_state(current_state)
	get_tree().get_root().get_node("Main/Control/BackgroundEdit").update_pos_spins()


func _process(_delta):
	tick += 1

