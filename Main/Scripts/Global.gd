extends Node2D

signal key_pressed

signal blink

signal reinfo
signal animation_state
signal slider_values
signal light_info

signal speaking
signal not_speaking

signal reinfoanim
signal remake_layers
signal update_layers
signal update_layer_visib
signal reparent_objects
signal reparent_layers

signal new_file
signal load_model

signal mode_changed
signal deselect
signal theme_update

signal update_pos_spins
signal update_offset_spins

signal delete_states
signal remake_states
signal reset_states

signal update_mouse_vel_pos

var blink_timer : Timer = Timer.new()
var held_sprite = null
var held_sprites : Array[SpriteObject] = []
var tick = 0
var current_state : int = 0

var settings_dict : Dictionary = {
	sensitivity_limit = 1,
	volume_limit = 0.1,
	volume_delay = 0.5,
	blink_speed = 1,
	blink_chance = 10,
	checkinput = true,
	bg_color = Color.SLATE_GRAY,
	is_transparent = false,
	states = [{}],
	light_states = [{}],
	darken = false,
	anti_alias = true,

	dim_color = Color.DIM_GRAY,
	auto_save = false,
	auto_save_timer = 1.0,
	
	saved_inputs = [],
	zoom = Vector2(1,1),
	pan = Vector2(640, 360),
	
	should_delta = false,
	max_fps = 241,
	monitor = 9999,
	cycles = [],
}

var mode : int = 0 : 
	set(nmode):
		mode = nmode
		mode_changed.emit(nmode)
		
#var undo_redo : UndoRedo = UndoRedo.new()
var new_rot = 0
var static_view : bool = false
var spinbox_held : bool = false

var main = null
var sprite_container = null
var viewer = null
var viewport = null
var top_ui = null
var file_dialog : FileDialog = null
var light = null
var camera : Camera2D = null

var frame_counter := 0
const FRAME_INTERVAL := 3  # Run every 5 frames
var swtich_session_popup : Node = null

var save_dir: String = OS.get_executable_path().get_base_dir()

func _init():
	save_dir = OS.get_user_data_dir()

func _ready():
	get_window().min_size = Vector2(720,720)
	add_child(blink_timer)
	blinking()
	get_window().title = "PNGTube-Remix V" + str(ProjectSettings.get_setting("application/config/version"))
	current_state = 0
	key_pressed.connect(update_cycles)


func blinking():
	blink_timer.wait_time = settings_dict.blink_speed
	blink_timer.start()
	await blink_timer.timeout
	var rand = randi() % int(settings_dict.blink_chance)
	if rand == 0:
		blink.emit()
	blinking()

func load_sprite_states(state):
	current_state = state
	for i in get_tree().get_nodes_in_group("Sprites"):
		i.get_state(current_state)
	if held_sprite != null && is_instance_valid(held_sprite):
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
	if held_sprite != null && is_instance_valid(held_sprite):
		emit_signal("reinfo")
		
	animation_state.emit(current_state)
	light_info.emit(current_state)
	update_layer_visib.emit()
	reinfoanim.emit()

func _input(_event : InputEvent):
	for i in held_sprites:
		if i != null && is_instance_valid(i):
			if Input.is_action_pressed("ctrl"):
				if Input.is_action_pressed("scrollup"):
					i.sprite_data.rotation -= 0.05
					rot(i)

				elif Input.is_action_pressed("scrolldown"):
					i.sprite_data.rotation += 0.05
					rot(i)

func offset(i):
	i.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	i.sprite_data.position = i.position
	i.sprite_data.offset = i.get_node("%Sprite2D").position
	i.save_state(current_state)

	update_offset_spins.emit()

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
	for i in held_sprites:
		if i != null && is_instance_valid(i):
			if Input.is_action_pressed("ui_up"):
				i.get_node("%Sprite2D").global_position.y += 10 * delta
				i.global_position.y -= 10 * delta
				offset(i)
			elif Input.is_action_pressed("ui_down"):
				i.get_node("%Sprite2D").global_position.y -= 10 * delta
				i.global_position.y += 10 * delta
				offset(i)
			if Input.is_action_pressed("ui_left"):
				i.get_node("%Sprite2D").global_position.x += 10 * delta
				i.global_position.x -= 10 * delta
				offset(i)
			elif Input.is_action_pressed("ui_right"):
				i.get_node("%Sprite2D").global_position.x -= 10 * delta
				i.global_position.x += 10 * delta

				offset(i)
			
			
		if main.can_scroll:
			if Input.is_action_pressed("ctrl"):
				if Input.is_action_just_pressed("lmb"):
					var of = i.get_parent().to_local(i.get_parent().get_global_mouse_position()) - i.position
					i.position += of
					i.get_node("%Sprite2D").global_position -= of

					offset(i)

func rot(i):
	i.rotation = i.sprite_data.rotation
	i.save_state(current_state)
	update_pos_spins.emit()

func moving_sprite(delta):
	for i in held_sprites:
		if i != null && is_instance_valid(i):
			if Input.is_action_pressed("w"):
				i.position.y -= 10 * delta
				i.sprite_data.position.y -= 10 * delta
				update_spins()
			elif Input.is_action_pressed("s_move"):
				i.position.y += 10 * delta
				i.sprite_data.position.y += 10 * delta
				update_spins()
				
			if Input.is_action_pressed("a"):
				i.position.x -= 10 * delta
				i.sprite_data.position.x -= 10 * delta
				update_spins()
				
			elif Input.is_action_pressed("d"):
				i.position.x += 10 * delta
				i.sprite_data.position.x += 10 * delta
				update_spins()

func update_spins():
	for i in held_sprites:
		if i != null && is_instance_valid(i):
			i.save_state(current_state)
			update_pos_spins.emit()

func _physics_process(_delta: float) -> void:
	mouse_delay()


func mouse_delay():
	frame_counter += 1
	if frame_counter >= FRAME_INTERVAL:
		update_mouse_vel_pos.emit()
		frame_counter = 0


func update_cycles(key):
	for cycle in settings_dict.cycles:
		if cycle.sprites.size() > 0:
			if cycle.toggle.as_text() == key:
				cycle.active = !cycle.active
				
				if cycle.active:
					var array = cycle.sprites.duplicate()
					if array.has(cycle.last_sprite):
						array.remove_at(array.find(cycle.last_sprite))

					var rand = array.pick_random()
					cycle.last_sprite = rand
					cycle.pos = cycle.sprites.find(rand)
					for sprite in get_tree().get_nodes_in_group("Sprites"):
						if sprite.sprite_id in cycle.sprites && sprite.sprite_data.is_cycle:
							sprite.get_node("%Drag").hide()
							sprite.was_active_before = sprite.get_node("%Drag").visible
						
						if sprite.sprite_id == rand && sprite.sprite_data.is_cycle:
							sprite.get_node("%Drag").show()
							sprite.was_active_before = sprite.get_node("%Drag").visible
					
					
				elif !cycle.active:
					for sprite in get_tree().get_nodes_in_group("Sprites"):
						if sprite.sprite_id in cycle.sprites && sprite.sprite_data.is_cycle:
							sprite.get_node("%Drag").hide()
							sprite.was_active_before = sprite.get_node("%Drag").visible
						
					#print(rand)
					
			elif cycle.forward.as_text() == key:
				cycle.pos = wrap(cycle.pos +1,0 ,  cycle.sprites.size() - 1)
				cycle.last_sprite = cycle.sprites[cycle.pos]
				for sprite in get_tree().get_nodes_in_group("Sprites"):
					if sprite.sprite_id in cycle.sprites && sprite.sprite_data.is_cycle:
						sprite.get_node("%Drag").hide()
						sprite.was_active_before = sprite.get_node("%Drag").visible
					
					if sprite.sprite_id == cycle.last_sprite && sprite.sprite_data.is_cycle:
						sprite.get_node("%Drag").show()
						sprite.was_active_before = sprite.get_node("%Drag").visible
				
			elif cycle.backward.as_text() == key:
				cycle.pos = wrap(cycle.pos -1,0 ,  cycle.sprites.size() - 1)
				cycle.last_sprite = cycle.sprites[cycle.pos]
				for sprite in get_tree().get_nodes_in_group("Sprites"):
					if sprite.sprite_id in cycle.sprites && sprite.sprite_data.is_cycle:
						sprite.get_node("%Drag").hide()
						sprite.was_active_before = sprite.get_node("%Drag").visible
					
					if sprite.sprite_id == cycle.last_sprite && sprite.sprite_data.is_cycle:
						sprite.get_node("%Drag").show()
						sprite.was_active_before = sprite.get_node("%Drag").visible
