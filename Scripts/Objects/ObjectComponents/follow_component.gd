extends Node

@export var actor: SpriteObject
@export var modifier: Node2D
@export var mesh : CustomMesh = null

var last_mouse_position : Vector2 = Vector2(0,0)
var last_dist : Vector2 = Vector2(0,0)
var mouse_coords : Vector2 = Vector2(0,0)
var vel = Vector2.ZERO
var distance : Vector2 = Vector2.ZERO
var mouse_moving
var last_dist_smoothed := Vector2.ZERO

var smoothed_dir : Vector2 = Vector2.ZERO
var dir_vel_anim : Vector2 = Vector2.ZERO
var dist_vel_anim : float = 0.0

var frame_h : float = 0.0
var frame_v : float = 0.0

var target_x : float = 0.0
var target_y : float = 0.0
var target_rotation :Vector2 = Vector2.ZERO
var target_scale :Vector2 = Vector2.ONE
var target_pos = Vector2.ZERO

var mouse_delta :Vector2 = Vector2.ZERO
var rest : bool = false
var axis_left :Vector2 = Vector2.ZERO
var axis_right :Vector2 = Vector2.ZERO
var axis_shoulderl :Vector2 = Vector2.ZERO
var axis_shoulderr :Vector2 = Vector2.ZERO
var axis_lr_3 : Vector2 = Vector2.ZERO
var current_dir : Vector2 = Vector2.ZERO
var current_dist : float = 0.0

var window : Window = null

func _ready() -> void:
	window = Global.get_tree().get_root().get_window()

func _physics_process(delta: float) -> void:
	if Global.static_view or actor.rest_mode == 5:
		return
	if actor.rest_mode in [1,3] and rest:
		reset_modifier()
	else:
		if Settings.theme_settings.use_glob_input:
			mouse_coords = follow_calculation_glob() 
		else:
			mouse_coords = follow_calculation() 
		process_follow(delta)
		last_mouse_position = mouse_coords

func reset_modifier() -> void:
	modifier.position = Vector2.ZERO
	modifier.rotation = 0.0
	modifier.scale = Vector2.ONE

func mouse_delay():
	mouse_delta = last_mouse_position - mouse_coords
	distance = Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))
	if !mouse_delta.is_zero_approx():
		if distance.length() == NAN:
			distance = Vector2(0.0, 0.0)
		last_mouse_position = mouse_coords

func process_follow(delta: float) -> void:
	if actor.get_value("follow_mouse_velocity"):
		mouse_delay()
		var dir_vel_x = -sign(mouse_delta.x)
		var dir_vel_y = -sign(mouse_delta.y)
		last_dist.x = lerp(last_dist.x, dir_vel_x * (distance.length() * actor.get_value("look_at_mouse_pos")), 0.5)
		last_dist.y = lerp(last_dist.y, dir_vel_y * (distance.length() * actor.get_value("look_at_mouse_pos_y")), 0.5)
		vel = mouse_delta
		dir_vel_anim = mouse_delta 
	var dir = (mouse_coords - Vector2.ZERO).normalized() if mouse_coords.length() > 0.0001 else Vector2.ZERO
	var dist = mouse_coords.length()
	update_controller_inputs()

	update_position(dir, dist, delta)
	update_rotation(dir, delta)
	update_scale(dir, delta)

func follow_calculation(_delta = 0.0):
	var main_marker = Global.main.get_node("%Marker")
	if WindowHandler.windows:
		mouse_coords = Vector2.ZERO
		if main_marker.current_screen == Monitor.ALL_SCREENS or main_marker.mouse_in_current_screen():
			mouse_coords = actor.get_local_mouse_position()
	elif main_marker.current_screen != Monitor.ALL_SCREENS:
		if !main_marker.mouse_in_current_screen() && Global.settings_dict.snap_out_of_bounds:
			mouse_coords = Vector2.ZERO
		else:
			var viewport_size = actor.get_viewport().size
			var origin = actor.get_global_transform_with_canvas().origin
			var x_per = 1.0 - origin.x/float(viewport_size.x)
			var y_per = 1.0 - origin.y/float(viewport_size.y)
			var display_size = Vector2(DisplayServer.screen_get_size(main_marker.current_screen))
			var offset = Vector2(display_size.x * x_per, display_size.y * y_per)
			var mouse_pos = Vector2(DisplayServer.mouse_get_position()) - Vector2(DisplayServer.screen_get_position(main_marker.current_screen))
			mouse_coords = Vector2(mouse_pos - display_size) + offset 
	else:
		mouse_coords = actor.get_local_mouse_position()
	return mouse_coords

func follow_calculation_glob(_delta = 0.0):
	var main_marker = Global.main.get_node("%Marker")

	var delta_mouse = Vector2(window.get_position_with_decorations()) + Vector2((window.get_size_with_decorations())/2)
	var test = actor.to_local(GlobInput.get_mouse_position()-Vector2(delta_mouse))
	if WindowHandler.windows:
		mouse_coords = Vector2.ZERO
		if main_marker.current_screen == Monitor.ALL_SCREENS or main_marker.mouse_in_current_screen():
			mouse_coords = test
	elif main_marker.current_screen != Monitor.ALL_SCREENS:
		if !main_marker.mouse_in_current_screen() && Global.settings_dict.snap_out_of_bounds:
			mouse_coords = Vector2.ZERO
		else:
			var viewport_size = actor.get_viewport().size
			var origin = actor.get_global_transform_with_canvas().origin
			var x_per = 1.0 - origin.x/float(viewport_size.x)
			var y_per = 1.0 - origin.y/float(viewport_size.y)
			var display_size = Vector2(DisplayServer.screen_get_size(main_marker.current_screen))
			var offset = Vector2(display_size.x * x_per, display_size.y * y_per)
			var mouse_pos = GlobInput.get_mouse_position() - Vector2(DisplayServer.screen_get_position(main_marker.current_screen))
			mouse_coords = Vector2(mouse_pos - display_size) + offset 
	else:
		mouse_coords = test
	return mouse_coords

func update_controller_inputs() -> void:
	axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	axis_shoulderl = Input.get_vector("ShoulderL1", "ShoulderR1", "ShoulderL1", "ShoulderR1")
	axis_shoulderr = Input.get_vector("ShoulderL2", "ShoulderR2", "ShoulderL2", "ShoulderR2")
	axis_lr_3 = Input.get_vector("L3", "R3", "L3", "R3")

func update_position(dir: Vector2, dist: float, _delta: float) -> void:
	if actor.get_value("follow_type") == 15:
		target_pos = Vector2.ZERO
		modifier.position = Vector2.ZERO
		return
	var invert_x: bool = actor.get_value("pos_invert_x")
	var invert_y: bool = actor.get_value("pos_invert_y")
	var follow_type: int = actor.get_value("follow_type")
	var keyboard_axis: Vector2 = Vector2.ZERO
	if follow_type == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_position_calculations(dir, last_dist)
		else:
			follow_position_calculations(dir, Vector2(dist, dist))
	elif follow_type in [1, 2, 10, 11, 12]:
		var axis: Vector2 = axis_left
		match follow_type:
			1: axis = axis_left
			2: axis = axis_right
			10: axis = axis_shoulderl
			11: axis = axis_shoulderr
			12: axis = axis_lr_3
			_: axis = Vector2.ZERO
		follow_position_calculations(axis)
	elif follow_type in [3, 4, 5, 6, 7, 8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type", actor)
		follow_position_calculations(keyboard_axis)
	elif follow_type == 17 and Tracker.working:
		match actor.get_value("udp_pos"):
			0:
				pass
			1:
				follow_position_calculations(Tracker.track_pos.normalized(), Tracker.track_pos)
			2:
				follow_position_calculations(Tracker.track_pupil_left.normalized(), Tracker.track_pupil_left * TrackingBackend.osf_pos_strength)
			3:
				follow_position_calculations(Tracker.track_pupil_right.normalized(), Tracker.track_pupil_right * TrackingBackend.osf_pos_strength)
			4:
				follow_position_calculations(Vector2(0, Tracker.eye_smile_left).normalized(), Vector2(0, Tracker.eye_smile_left * TrackingBackend.osf_pos_strength))
			5:
				follow_position_calculations(Vector2(0, Tracker.eye_smile_right).normalized(), Vector2(0, Tracker.eye_smile_right * TrackingBackend.osf_pos_strength))
			6:
				follow_position_calculations(Vector2(0, Tracker.cheek_raise_left).normalized(), Vector2(0, Tracker.cheek_raise_left * TrackingBackend.osf_pos_strength))
			7:
				follow_position_calculations(Vector2(0, Tracker.cheek_raise_right).normalized(), Vector2(0, Tracker.cheek_raise_right * TrackingBackend.osf_pos_strength))
			8:
				follow_position_calculations(Vector2(0, Tracker.brow_left_final).normalized(), Vector2(0, Tracker.brow_left_final * TrackingBackend.osf_pos_strength))
			9:
				follow_position_calculations(Vector2(0, Tracker.brow_right_final).normalized(), Vector2(0, Tracker.brow_right_final * TrackingBackend.osf_pos_strength))
	if actor.sprite_type == "Sprite2D" && actor.get_value("animate_to_mouse") && actor.get_value("non_animated_sheet"):
		update_sprite_animation(current_dir, current_dist, _delta)
		if !actor.get_value("animate_to_mouse_track_pos"):
			modifier.position = modifier.position.lerp(Vector2.ZERO, actor.get_value("mouse_delay"))
			return
	if actor.sprite_type == "Mesh" && mesh != null && is_instance_valid(mesh):
		if !actor.get_value("move_with_follow"):
			modifier.position = modifier.position.lerp(Vector2.ZERO, actor.get_value("mouse_delay"))
			return
	var final_target : Vector2 = target_pos
	if invert_x:
		final_target.x *= -1
	if invert_y:
		final_target.y *= -1
	modifier.position = modifier.position.lerp(final_target, actor.get_value("mouse_delay"))

func follow_position_calculations(dir : Vector2, m_dist : Vector2 = Vector2.ZERO):
	var dist = dir
	if m_dist != Vector2.ZERO:
		dist = m_dist
		if actor.get_value("snap_pos"):
			if dir.x != 0:
				target_pos.x =  lerp(target_pos.x, float(clamp(dir.x *dist.x, actor.get_value("pos_x_min"), actor.get_value("pos_x_max"))), actor.get_value("mouse_delay"))
				current_dir.x = dir.x
			if dir.y != 0:
				target_pos.y = lerp(target_pos.y,  float(clamp(dir.y *dist.y, actor.get_value("pos_y_min"), actor.get_value("pos_y_max"))), actor.get_value("mouse_delay"))
				current_dir.y = dir.y
		else:
			target_pos.x = lerp(target_pos.x, float(clamp(dir.x *dist.x, actor.get_value("pos_x_min"), actor.get_value("pos_x_max"))), actor.get_value("mouse_delay"))
			target_pos.y = lerp(target_pos.y,  float(clamp(dir.y *dist.y, actor.get_value("pos_y_min"), actor.get_value("pos_y_max"))), actor.get_value("mouse_delay"))
			current_dir = dir
			current_dist = target_pos.length()
	else:
		var _mouse_delay = actor.get_value("mouse_delay")
		var pos_norm = dir.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
		var pos_x = lerp(float(actor.get_value("pos_x_min")),float(actor.get_value("pos_x_max")),max(0.001, (pos_norm.x * 0.5) + 0.5))
		var pos_y = lerp(float(actor.get_value("pos_y_min")),float(actor.get_value("pos_y_max")),max(0.001, (pos_norm.y * 0.5 )+ 0.5))
		var _target_pos_final : Vector2 = Vector2(pos_x, pos_y)
		if actor.get_value("snap_pos"):
			if dir.x != 0:
				target_pos.x = lerp(target_pos.x, _target_pos_final.x, _mouse_delay)
				current_dir.x = dir.x
			if dir.y != 0:
				target_pos.y = lerp(target_pos.y, _target_pos_final.y, _mouse_delay)
				current_dir.y = dir.y
		else:
			target_pos.x = lerp(target_pos.x, _target_pos_final.x, _mouse_delay)
			target_pos.y = lerp(target_pos.y, _target_pos_final.y, _mouse_delay)
			current_dir = dir
			current_dist = target_pos.length()

func update_rotation(_dir: Vector2, delta: float) -> void:
	if actor.get_value("follow_type2") == 15:
		return
	var follow_type2 = actor.get_value("follow_type2")
	var target_rot = 0.0
	var keyboard_axis := Vector2.ZERO
	if follow_type2 in [3,4,5,6,7,8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type2", actor)
		if actor.get_value("snap_rot") and not keyboard_axis.is_zero_approx():
			target_rot = lerp(target_rot, follow_controller_rotation(keyboard_axis), 0.15)
		else:
			target_rot = follow_controller_rotation(keyboard_axis)

	elif follow_type2 == 0:
		if actor.get_value("follow_mouse_velocity"):
			target_rot = follow_mouse_vel_rotation()
		else:
			var main_marker = Global.main.get_node("%Marker")
			var screen_size = DisplayServer.screen_get_size(-1)
			if main_marker.current_screen == Monitor.ALL_SCREENS:
				screen_size = DisplayServer.screen_get_size(1)
			else:
				screen_size = DisplayServer.screen_get_size(main_marker.current_screen)
			var mouse_x = mouse_coords.x
			var screen_width = screen_size.x
			var normalized_mouse = (mouse_x) / (screen_width / 2)
			normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
			var rotation_factor = lerp(actor.sprite_data.mouse_rotation, actor.sprite_data.mouse_rotation_max, max((normalized_mouse + 1) / 2, 0.001))
			target_rot = GlobalCalculations.is_nan_or_inf(clamp_rotations(rotation_factor))

	elif follow_type2 == 1: target_rot = follow_controller_rotation(axis_left)
	elif follow_type2 == 2: target_rot =  follow_controller_rotation(axis_right)
	elif follow_type2 == 10: target_rot = follow_controller_rotation(axis_shoulderl)
	elif follow_type2 == 11: target_rot = follow_controller_rotation(axis_shoulderl)
	elif follow_type2 == 12: target_rot = follow_controller_rotation(axis_lr_3)
	elif follow_type2 == 17 && Tracker.working:
		var clamped_rot = 0
		match actor.get_value("udp_rot"):
			0:
				pass
			1:
				var inv = 1
				if signi(actor.sprite_data.mouse_rotation) < 0:
					inv = -1
				if actor.sprite_data.mouse_rotation > actor.sprite_data.mouse_rotation_max:
					clamped_rot = inv *clamp(Tracker.track_rot.y,actor.sprite_data.mouse_rotation_max, actor.sprite_data.mouse_rotation)
				else:
					clamped_rot = inv*clamp(Tracker.track_rot.y,actor.sprite_data.mouse_rotation, actor.sprite_data.mouse_rotation_max )
			2:
				clamped_rot = clamp_rotations(Tracker.track_pupil_left.angle())
			3:
				clamped_rot = clamp_rotations(Tracker.track_pupil_right.angle())
			4:
				clamped_rot = clamp_rotations(Tracker.eye_smile_left)
			5:
				clamped_rot = clamp_rotations(Tracker.eye_smile_right)
			6:
				clamped_rot = clamp_rotations(Tracker.cheek_raise_left)
			7:
				clamped_rot = clamp_rotations(Tracker.cheek_raise_right)
			8:
				clamped_rot = clamp_rotations(Tracker.smooth_brow_left)
			9:
				clamped_rot = clamp_rotations(Tracker.smooth_brow_right)
		target_rot = clamped_rot
	else:
		target_rot = 0
	var t = actor.get_value("mouse_delay") * delta * 60.0
	t = clamp(t, 0.0, 1.0)
	modifier.rotation = lerp_angle(modifier.rotation, target_rot, t)

func follow_controller_rotation(axis) -> float:
	var normalized = clamp(axis.x, -1.0, 1.0)
	var rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var rotation_factor = lerp(actor.get_value("rot_min"), actor.get_value("rot_max"), max((normalized + 1) / 2, 0.001))
	return clamp(rotation_factor, deg_to_rad(rot_min), deg_to_rad(rot_max))

func clamp_rotations(value) -> float :
	var clamped = 0
	var min_rot : float = actor.get_value("rot_min")
	var max_rot : float = actor.get_value("rot_max")
	if min_rot > max_rot:
		clamped = clamp(value,max_rot, min_rot)
	else:
		clamped = clamp(value,min_rot, max_rot)
	return clamped

func update_scale(dir: Vector2, delta: float) -> void:
	if actor.get_value("follow_type3") == 15:
		return
	var follow_type3: int = actor.get_value("follow_type3")
	var s_min_x = actor.get_value("scale_x_min")
	var s_max_x = actor.get_value("scale_x_max")
	var s_min_y = actor.get_value("scale_y_min")
	var s_max_y = actor.get_value("scale_y_max")
	var invert_x: bool = actor.get_value("scale_invert_x")
	var invert_y: bool = actor.get_value("scale_invert_y")
	var x_val: float = 0.0
	var y_val: float = 0.0
	var keyboard_axis: Vector2 = Vector2.ZERO
	match follow_type3:
		0:
			if actor.get_value("follow_mouse_velocity"):
				var s = follow_mouse_vel_scale()
				x_val = s.x
				y_val = s.y
			else:
				x_val = clamp(dir.x, s_min_x, s_max_x)
				y_val = clamp(dir.y, s_min_y, s_max_y)

		1, 2, 10, 11, 12:
			if follow_type3 == 1:
				x_val = clamp(axis_left.x, s_min_x, s_max_x)
				y_val = clamp(axis_left.y, s_min_y, s_max_y)
			elif follow_type3 == 2:
				x_val = clamp(axis_right.x, s_min_x, s_max_x)
				y_val = clamp(axis_right.y, s_min_y, s_max_y)
			elif follow_type3 == 10:
				x_val = clamp(axis_shoulderl.x, s_min_x, s_max_x)
				y_val = clamp(axis_shoulderl.y, s_min_y, s_max_y)
			elif follow_type3 == 11:
				x_val = clamp(axis_shoulderr.x, s_min_x, s_max_x)
				y_val = clamp(axis_shoulderr.y, s_min_y, s_max_y)
			elif follow_type3 == 12:
				x_val = clamp(axis_lr_3.x, s_min_x, s_max_x)
				y_val = clamp(axis_lr_3.y, s_min_y, s_max_y)

		3, 4, 5, 6, 7, 8:
			keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type3", actor)
			if actor.get_value("snap_scale") and not keyboard_axis.is_zero_approx():
				target_scale = target_scale.lerp(keyboard_axis, 0.15)
			else:
				target_scale = keyboard_axis
			x_val = clamp(target_scale.x, s_min_x, s_max_x)
			y_val = clamp(target_scale.y, s_min_y, s_max_y)
			
		17:
			if Tracker.working:
				var clamped_x: float = 1.0
				var clamped_y: float = 1.0
				match actor.get_value("udp_scale"):
					0:
						pass
					1:
						clamped_x = clamp(Tracker.track_pos.x, s_min_x, s_max_x)
						clamped_y = clamp(Tracker.track_pos.y, s_min_y, s_max_y)
					2:
						clamped_x = clamp(Tracker.track_pupil_left.x, s_min_x, s_max_x)
						clamped_y = clamp(Tracker.track_pupil_left.y, s_min_y, s_max_y)
					3:
						clamped_x = clamp(Tracker.track_pupil_right.x, s_min_x, s_max_x)
						clamped_y = clamp(Tracker.track_pupil_right.y, s_min_y, s_max_y)
					4:
						clamped_y = clamp(Tracker.eye_smile_left, s_min_y, s_max_y)
					5:
						clamped_y = clamp(Tracker.eye_smile_right, s_min_y, s_max_y)
					6:
						clamped_y = clamp(clamped_y - Tracker.cheek_raise_left, s_min_y, s_max_y)
					7:
						clamped_y = clamp(clamped_y - Tracker.cheek_raise_right, s_min_y, s_max_y)
					8:
						clamped_y = clamp(clamped_y + Tracker.smooth_brow_left, s_min_y, s_max_y)
					9:
						clamped_y = clamp(clamped_y + Tracker.smooth_brow_right, s_min_y, s_max_y)
				target_scale.x = clamped_x
				target_scale.y = clamped_y

	if follow_type3 == 17 and Tracker.working:
		modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_scale.x, actor.get_value("mouse_delay")))
		modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_scale.y, actor.get_value("mouse_delay")))
	else:
		if invert_x:
			x_val *= -1
		if invert_y:
			y_val *= -1
		var target_sx: float = 1.0 - clamp( x_val, s_min_x, s_max_x)
		var target_sy: float = 1.0 - clamp( y_val, s_min_y, s_max_y)
		var t: float = clamp(actor.get_value("mouse_delay") * delta * 60.0, 0.0, 1.0)
		modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_sx, t))
		modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_sy, t))

func follow_mouse_vel_rotation() -> float:
	var t = Vector2(dir_vel_anim.x, 0).normalized()
	var normalized_mouse = t.x/2
	normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
	var rotation_factor = lerp(float(actor.get_value("rot_min")), float(actor.get_value("rot_max")), max(0.01, (normalized_mouse *0.5)))
	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var _target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
	return _target_rotation

func follow_mouse_vel_scale() -> Vector2:
	var t = Vector2(dir_vel_anim.x, 0).normalized()
	var normalized_mouse = t.x/2
	normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
	var s_min_x = actor.get_value("scale_x_min")
	var s_max_x = actor.get_value("scale_x_max")
	var s_min_y = actor.get_value("scale_y_min")
	var s_max_y = actor.get_value("scale_y_max")
	var scl_x = lerp(float(s_min_x), float(s_max_x), max(0.01, (normalized_mouse) / 2))
	var scl_y = lerp(float(s_min_y), float(s_max_y), max(0.01, (normalized_mouse) / 2))
	var _target_scale : Vector2 = Vector2(scl_x, scl_y)
	return _target_scale

func update_sprite_animation(dir: Vector2, dist: float, _delta: float) -> void:
	if actor.sprite_type != "Sprite2D":
		return

	var dist_x = dir.x * min(dist, actor.get_value("look_at_mouse_pos"))
	var dist_y = dir.y * min(dist, actor.get_value("look_at_mouse_pos_y"))

	var hframes = %Sprite2D.hframes
	var vframes = %Sprite2D.vframes

	var norm_x = (dist_x / (2.0 * actor.get_value("look_at_mouse_pos"))) + 0.5
	var norm_y = (dist_y / (2.0 * actor.get_value("look_at_mouse_pos_y"))) + 0.5

	var frame_x = clamp(floor(norm_x * hframes), 0, hframes - 1)
	var frame_y = clamp(floor(norm_y * vframes), 0, vframes - 1)

	frame_h = move_toward(frame_h, frame_x, actor.get_value("animate_to_mouse_speed"))
	frame_v = move_toward(frame_v, frame_y, actor.get_value("animate_to_mouse_speed"))

	%Sprite2D.frame_coords.x = floor(frame_h)
	%Sprite2D.frame_coords.y = floor(frame_v)

func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
