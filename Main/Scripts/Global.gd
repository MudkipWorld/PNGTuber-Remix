extends Node2D

enum Mouth {
	Closed,
	Open,
	Screaming
}

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
signal project_updates

signal mode_changed
signal deselect
signal theme_update

signal update_pos_spins
signal update_offset_spins

signal delete_states
signal remake_states
signal remake_for_plus
signal reset_states

signal update_mouse_vel_pos
signal editing_for_changed
signal add_window
signal edit_windows

signal update_ui_pieces
signal image_replaced
signal add_new_image
signal delete_image
signal remake_image_manager
signal show_model_warning

signal dev_mode

# Remix version
@onready var version: String = ProjectSettings.get_setting("application/config/version")

var blink_timer : Timer = Timer.new()
var held_sprite = null
var held_sprites : Array[SpriteObject] = []
var tick = 0
var current_state : int = 0
var mouth := Mouth.Closed
var editing_for := Mouth.Closed:
	set(x):
		if x == editing_for: return
		editing_for = x
		editing_for_changed.emit()

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
	pan = Vector2(0, 0),
	
	should_delta = true,
	max_fps = 60,
	monitor = Monitor.ALL_SCREENS,
	snap_out_of_bounds = true,
	cycles = [],

	language = "automatic",
	preferred_language = null,
	trimmed = false,
}

var image_manager_data : Array = []

var mode: int = 0: set = set_mode

var show_warning: bool = false:
	set(n_mode):
		show_model_warning.emit(n_mode)
		show_warning = n_mode

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
var camera_pos : Node2D = null
var mesh_pointer : Node2D = null

var frame_counter : int = 0
const FRAME_INTERVAL : int = 3  # Run every 5 frames
var swtich_session_popup : Node = null
var over_tex : bool = false
var over_normal_tex : bool = false

var over_mesh_tex : bool = false
var mesh_text_node : Node = null

var save_path : String = ""
var is_editor : bool = true:
	set(x):
		if x == is_editor: 
			is_editor = x
			return
		is_editor = x
		Settings.change_cursor()

var image_data = ImageData.new()
var image_data_normal = ImageData.new()
var selected_mesh_inx : int = 1
var folder_texture : Texture2D = null

func _ready():
	var img = Image.create_empty(32,32, false, Image.FORMAT_RGBA8)
	folder_texture = ImageTexture.create_from_image(img)
	create_placeholders()
	get_window().min_size = Vector2(720,720)
	add_child(blink_timer)
	blinking()
	get_window().title = "PNGTuber-Remix V" + version
	current_state = 0

func create_placeholders():
	image_data.runtime_texture = preload("res://Misc/TestAssets/Placeholder.png")
	image_data_normal.runtime_texture = preload("res://Misc/TestAssets/Placeholder_n.png")

func set_mode(new_mode) -> void:
	if new_mode == mode: return
	mode = new_mode
	
	match mode:
		0:
			get_viewport().transparent_bg = false
			RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
			if main.has_node("%Control"):
				main.get_node("%Control").show()
			is_editor = true
		1:
			RenderingServer.set_default_clear_color(settings_dict.bg_color)
			get_viewport().transparent_bg = settings_dict.is_transparent
			if main.has_node("%Control"):
				main.get_node("%Control").hide()
			is_editor = false
			if light != null && is_instance_valid(light):
				light.get_node("Grab").hide()
			deselect.emit()
			static_view = false
	
	Settings.theme_settings.mode = mode
	Settings.save()
	mode_changed.emit(mode)

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
		
	reinfo.emit()
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
	
	reinfo.emit()
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
	i.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	i.sprite_data.position = i.position
	i.sprite_data.offset = i.get_node("%Sprite2D").position
	i.save_state(current_state)

	update_offset_spins.emit()

func _process(delta):
	if settings_dict.should_delta:
		tick = wrap(tick + delta, 0, 922337203685477630)
	else:
		tick = wrap(tick + 1, 0, 922337203685477630)
	#	print(tick)
	if !spinbox_held:
		moving_origin(delta)
		moving_sprite(delta)

func moving_origin(delta):
	for i in held_sprites:
		if i != null && is_instance_valid(i):
			if Input.is_action_pressed("up"):
				i.get_node("%Sprite2D").global_position.y += 10 * delta
				i.global_position.y -= 10 * delta
				offset(i)
			elif Input.is_action_pressed("down"):
				i.get_node("%Sprite2D").global_position.y -= 10 * delta
				i.global_position.y += 10 * delta
				offset(i)
			if Input.is_action_pressed("left"):
				i.get_node("%Sprite2D").global_position.x += 10 * delta
				i.global_position.x -= 10 * delta
				offset(i)
			elif Input.is_action_pressed("right"):
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
	i.rotation = i.get_value("rotation")
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
	if Input.is_action_just_pressed("debug_rep"):
		print_orphan_nodes()

func mouse_delay():
	frame_counter += 1
	if frame_counter >= FRAME_INTERVAL:
		update_mouse_vel_pos.emit()
		frame_counter = 0

func update_camera_smoothing() -> void:
	if !is_instance_valid(camera): return
	camera.position_smoothing_enabled = Settings.theme_settings.floaty_panning

func set_language(language: String) -> void:
	var locale = Util.get_locale(language)
	Settings.theme_settings.language = language
	Settings.save()
	if locale == "automatic":
		TranslationServer.set_locale(OS.get_locale_language())
	else:
		TranslationServer.set_locale(locale)
