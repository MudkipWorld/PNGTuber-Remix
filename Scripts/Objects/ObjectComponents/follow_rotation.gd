extends Node

@export var actor: SpriteObject
@export var modifier: Node2D

var smoothed_dir: Vector2 = Vector2.ZERO
var dir_vel_anim: Vector2 = Vector2.ZERO
var dist_vel_anim: float = 0.0

var target_rotation: Vector2 = Vector2.ZERO
var target_scale: Vector2 = Vector2.ONE
var mouse_coords : Vector2 = Vector2(0,0)

var rest: bool = false
var axis_left: Vector2 = Vector2.ZERO
var axis_right: Vector2 = Vector2.ZERO
var axis_shoulderl: Vector2 = Vector2.ZERO
var axis_shoulderr: Vector2 = Vector2.ZERO
var axis_lr_3: Vector2 = Vector2.ZERO
var final_target: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if actor.get_value("follow_type2") == 15:
		modifier.rotation = 0.0
		return
	if Global.static_view or actor.rest_mode == 5:
		return
	if actor.rest_mode in [1,3] and rest:
		reset_modifier()
	else:

		update_controller_inputs()
		update_rotation(delta)

func reset_modifier() -> void:
	modifier.rotation = 0.0

func update_controller_inputs() -> void:
	axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	axis_shoulderl = Input.get_vector("ShoulderL1", "ShoulderR1", "ShoulderL1", "ShoulderR1")
	axis_shoulderr = Input.get_vector("ShoulderL2", "ShoulderR2", "ShoulderL2", "ShoulderR2")
	axis_lr_3 = Input.get_vector("L3", "R3", "L3", "R3")

func update_rotation(delta: float) -> void:
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
				screen_size = DisplayServer.screen_get_size(DisplayServer.SCREEN_PRIMARY)
			else:
				var idx = clamp(main_marker.current_screen, 0, DisplayServer.get_screen_count() - 1)
				screen_size = DisplayServer.screen_get_size(idx)
				
			mouse_coords = %FollowPosition.follow_calculation() 
				
			var mouse_x = mouse_coords.x
			var screen_width = screen_size.x
			var normalized_mouse = (mouse_x) / (screen_width / 2)
			normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
			var rotation_factor = lerp(float(actor.get_value("rot_min")), float(actor.get_value("rot_max")), max((normalized_mouse + 1) / 2, 0.001))
			target_rot = GlobalCalculations.is_nan_or_inf(clamp_rotations(rotation_factor))

	elif follow_type2 == 1: target_rot = follow_controller_rotation(axis_left)
	elif follow_type2 == 2: target_rot =  follow_controller_rotation(axis_right)
	elif follow_type2 == 10: target_rot = follow_controller_rotation(axis_shoulderl)
	elif follow_type2 == 11: target_rot = follow_controller_rotation(axis_shoulderl)
	elif follow_type2 == 12: target_rot = follow_controller_rotation(axis_lr_3)
	elif follow_type2 == 17 && Tracker.working:
		var clamped_rot : float = 0.0
		var inv = 1
		if signi(actor.get_value("rot_min")) < 0:
			inv = -1
		
		match actor.get_value("udp_rot"):
			0:
				pass
			1:
				var test = follow_controller_rotation(Vector2(Tracker.track_rot.y, Tracker.track_rot.y))
				clamped_rot = inv * clamp_rotations(test)
			2:
				var test = Tracker.track_pupil_left.normalized().angle()
				clamped_rot = inv * clamp_rotations(test)
			3:
				var test = Tracker.track_pupil_right.normalized().angle()
				clamped_rot = inv * clamp_rotations(test)
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
				
			10:
				clamped_rot = clamp_rotations(Tracker.cheek_average)
			
			11:
				clamped_rot = clamp_rotations(Tracker.mouth_pucker)

		target_rot = clamped_rot
	else:
		target_rot = 0
	var t = actor.get_value("mouse_delay") * delta * 60.0
	t = clamp(t, 0.0, 1.0)
	modifier.rotation = lerp_angle(modifier.rotation, target_rot, t)

func follow_controller_rotation(axis) -> float:
	var normalized = clamp(axis.x, -1.0, 1.0)
	var rotation_factor = lerp(actor.get_value("rot_min"), actor.get_value("rot_max"), max((normalized + 1) / 2, 0.001))
	return rotation_factor

func clamp_rotations(value) -> float :
	var clamped := 0.0
	var min_rot : float = actor.get_value("rot_min")
	var max_rot : float = actor.get_value("rot_max")
	if min_rot > max_rot:
		clamped = clamp(value,max_rot, min_rot)
	else:
		clamped = clamp(value,min_rot, max_rot)
	return clamped

func follow_mouse_vel_rotation() -> float:
	var t = Vector2(dir_vel_anim.x, 0).normalized()
	var normalized_mouse = t.x/2
	normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
	var rotation_factor = lerp(float(actor.get_value("rot_min")), float(actor.get_value("rot_max")), max(0.01, (normalized_mouse *0.5)))
	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var _target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
	return _target_rotation

func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
