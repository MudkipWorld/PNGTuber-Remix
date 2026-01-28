extends Node

@export var actor: SpriteObject
@export var modifier: Node2D
@export var mesh : CustomMesh = null

const DELAY_SPEED_MULT: float = 60.0 

var last_mouse_position : Vector2 = Vector2.ZERO
var last_dist : Vector2 = Vector2.ZERO
var mouse_coords : Vector2 = Vector2.ZERO
var vel = Vector2.ZERO
var distance : Vector2 = Vector2.ZERO
var last_dist_smoothed := Vector2.ZERO

var current_dir : Vector2 = Vector2.ZERO
var current_dist : float = 0.0
var dir_vel_anim : Vector2 = Vector2.ZERO
var smoothed_dir : Vector2 = Vector2.ZERO 

var frame_h : float = 0.0
var frame_v : float = 0.0

var target_x : float = 0.0
var target_y : float = 0.0
var target_scale : Vector2 = Vector2.ONE
var target_pos : Vector2 = Vector2.ZERO

var mouse_delta : Vector2 = Vector2.ZERO
var rest : bool = false
var axis_left : Vector2 = Vector2.ZERO
var axis_right : Vector2 = Vector2.ZERO
var axis_shoulderl : Vector2 = Vector2.ZERO
var axis_shoulderr : Vector2 = Vector2.ZERO
var axis_lr_3 : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if Global.static_view or actor.rest_mode == 5:
		return
	if actor.rest_mode in [1,3] and rest:
		reset_modifier()
	else:
		mouse_coords = follow_calculation() 
		
		var t = actor.get_value("mouse_delay")
		process_follow(delta, t)
		last_mouse_position = mouse_coords

func reset_modifier() -> void:
	modifier.position = Vector2.ZERO
	modifier.rotation = 0.0
	modifier.scale = Vector2.ONE

func mouse_delay():
	mouse_delta = last_mouse_position - mouse_coords
	distance = Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))
	
	if !mouse_delta.is_zero_approx():
		if is_nan(distance.x) or is_nan(distance.y):
			distance = Vector2.ZERO
		last_mouse_position = mouse_coords

func process_follow(delta: float, t: float) -> void:
	if actor.get_value("follow_mouse_velocity"):
		mouse_delay()
		var dir_vel_x = -sign(mouse_delta.x)
		var dir_vel_y = -sign(mouse_delta.y)
		
		var range_x = actor.get_value("pos_x_max")
		var range_y = actor.get_value("pos_y_max")
		
		last_dist.x = lerp(last_dist.x, dir_vel_x * (distance.length() * range_x), 0.5)
		last_dist.y = lerp(last_dist.y, dir_vel_y * (distance.length() * range_y), 0.5)
		vel = mouse_delta
		dir_vel_anim = mouse_delta 
	
	var dir = (mouse_coords - Vector2.ZERO).normalized() if mouse_coords.length() > 0.0001 else Vector2.ZERO
	var dist = mouse_coords.length()
	
	update_controller_inputs()

	update_position(dir, dist, t)
	update_rotation(t)
	update_scale(t)

	if actor.sprite_type == "Sprite2D" and actor.get_value("non_animated_sheet") and actor.get_value("animate_to_mouse"):
		update_sprite_animation(dir, dist, delta)

func get_screen_bounds() -> Rect2:
	var main_marker = Global.main.get_node("%Marker")
	
	if main_marker.current_screen != Monitor.ALL_SCREENS:
		var pos = Vector2(DisplayServer.screen_get_position(main_marker.current_screen))
		var size = Vector2(DisplayServer.screen_get_size(main_marker.current_screen))
		return Rect2(pos, size)
	
	var full_rect = Rect2()
	for i in DisplayServer.get_screen_count():
		var pos = Vector2(DisplayServer.screen_get_position(i))
		var size = Vector2(DisplayServer.screen_get_size(i))
		var screen_rect = Rect2(pos, size)
		
		if i == 0:
			full_rect = screen_rect
		else:
			full_rect = full_rect.merge(screen_rect)
			
	return full_rect

func follow_calculation(_delta = 0.0):
	var mouse_global = Vector2(DisplayServer.mouse_get_position())
	var window_pos = Vector2(DisplayServer.window_get_position())
	var sprite_local = actor.get_global_transform_with_canvas().origin
	var sprite_global = window_pos + sprite_local
	mouse_coords = mouse_global - sprite_global
	return mouse_coords

func update_controller_inputs() -> void:
	axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	axis_shoulderl = Input.get_vector("ShoulderL1", "ShoulderR1", "ShoulderL1", "ShoulderR1")
	axis_shoulderr = Input.get_vector("ShoulderL2", "ShoulderR2", "ShoulderL2", "ShoulderR2")
	axis_lr_3 = Input.get_vector("L3", "R3", "L3", "R3")

func get_normalized_mouse() -> Vector2:
	var screen_rect = get_screen_bounds()
	var mouse_global = Vector2(DisplayServer.mouse_get_position())
	var window_pos = Vector2(DisplayServer.window_get_position())
	var sprite_local = actor.get_global_transform_with_canvas().origin
	var sprite_global = window_pos + sprite_local
	
	var diff = mouse_global - sprite_global
	var norm = Vector2.ZERO
	
	if diff.x >= 0:
		var screen_right = screen_rect.position.x + screen_rect.size.x
		var space = max(screen_right - sprite_global.x, 1.0)
		norm.x = clamp(diff.x / space, 0.0, 1.0)
	else:
		var screen_left = screen_rect.position.x
		var space = max(sprite_global.x - screen_left, 1.0)
		norm.x = clamp(diff.x / space, -1.0, 0.0)
		
	if diff.y >= 0:
		var screen_bottom = screen_rect.position.y + screen_rect.size.y
		var space = max(screen_bottom - sprite_global.y, 1.0)
		norm.y = clamp(diff.y / space, 0.0, 1.0)
	else:
		var screen_top = screen_rect.position.y
		var space = max(sprite_global.y - screen_top, 1.0)
		norm.y = clamp(diff.y / space, -1.0, 0.0)
		
	return norm

func update_position(dir: Vector2, _dist: float, t: float) -> void:
	var follow_type: int = actor.get_value("follow_type")
	var x_max: float = actor.get_value("pos_x_max")
	var x_min: float = actor.get_value("pos_x_min")
	var y_max: float = actor.get_value("pos_y_max")
	var y_min: float = actor.get_value("pos_y_min")
	var snap: bool = actor.get_value("snap_pos")
	
	var swap_x: bool = actor.get_value("pos_swap_x")
	var swap_y: bool = actor.get_value("pos_swap_y")
	
	var axis: Vector2 = Vector2.ZERO
	if follow_type == 0:
		axis = dir
	elif follow_type in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12]:
		axis = _get_input_axis(follow_type)

	if follow_type == 0:
		if actor.get_value("follow_mouse_velocity"):
			if snap:
				if abs(distance.x) > 0.5:
					target_pos.x = lerp(target_pos.x, last_dist.x, t)
					current_dir.x = axis.x
				if abs(distance.y) > 0.5:
					target_pos.y = lerp(target_pos.y, last_dist.y, t)
					current_dir.y = axis.y
			else:
				target_pos = target_pos.lerp(last_dist, t)
				current_dir = axis
		else:
			var norm = get_normalized_mouse()
			
			var input_for_x = norm.y if swap_x else norm.x
			var input_for_y = norm.x if swap_y else norm.y
			
			var limit_x = x_max if input_for_x >= 0 else x_min
			var limit_y = y_max if input_for_y >= 0 else y_min
			
			var val_x = abs(input_for_x) * abs(limit_x) * sign(limit_x)
			var val_y = abs(input_for_y) * abs(limit_y) * sign(limit_y)

			target_pos.x = lerp(target_pos.x, val_x, t)
			target_pos.y = lerp(target_pos.y, val_y, t)
			current_dir = axis

	elif follow_type in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12]:
		var input_for_x = axis.y if swap_x else axis.x
		var input_for_y = axis.x if swap_y else axis.y
		
		var limit_x = x_max if input_for_x >= 0 else x_min
		var limit_y = y_max if input_for_y >= 0 else y_min
		
		var target_val_x = abs(input_for_x) * limit_x
		var target_val_y = abs(input_for_y) * limit_y

		if snap:
			if axis.x != 0:
				target_x = lerp(target_x, target_val_x, t)
				current_dir.x = axis.x
			if axis.y != 0:
				target_y = lerp(target_y, target_val_y, t)
				current_dir.y = axis.y
			target_pos = Vector2(target_x, target_y)
		else:
			target_pos = target_pos.lerp(Vector2(target_val_x, target_val_y), t)
			current_dir = axis
		current_dist = target_pos.length()

	elif follow_type == 17 and Tracker.working:
		var raw_track: Vector2 = Vector2.ZERO
		match actor.get_value("udp_pos"):
			1: raw_track = Tracker.track_pos
			2: raw_track = Tracker.track_pupil_left * TrackingBackend.osf_pos_strength
			3: raw_track = Tracker.track_pupil_right * TrackingBackend.osf_pos_strength
			4: raw_track.y = Tracker.eye_smile_left * TrackingBackend.osf_pos_strength
			5: raw_track.y = Tracker.eye_smile_right * TrackingBackend.osf_pos_strength
			6: raw_track.y = Tracker.cheek_raise_left * TrackingBackend.osf_pos_strength
			7: raw_track.y = Tracker.cheek_raise_right * TrackingBackend.osf_pos_strength
			8: raw_track.y = Tracker.brow_left_final * TrackingBackend.osf_pos_strength
			9: raw_track.y = Tracker.brow_right_final * TrackingBackend.osf_pos_strength
		
		var input_for_x = raw_track.y if swap_x else raw_track.x
		var input_for_y = raw_track.x if swap_y else raw_track.y

		var real_min_x = min(x_min, x_max)
		var real_max_x = max(x_min, x_max)
		var real_min_y = min(y_min, y_max)
		var real_max_y = max(y_min, y_max)

		target_pos.x = clamp(input_for_x, real_min_x, real_max_x)
		target_pos.y = clamp(input_for_y, real_min_y, real_max_y)

	else:
		target_pos = Vector2.ZERO

	if not actor.get_value("animate_to_mouse_track_pos"):
		modifier.position = modifier.position.lerp(Vector2.ZERO, t)
		return

	if actor.sprite_type == "Mesh" and mesh != null and is_instance_valid(mesh):
		if not actor.get_value("move_with_follow"):
			modifier.position = modifier.position.lerp(Vector2.ZERO, t)
			return

	modifier.position.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.x, target_pos.x, t))
	modifier.position.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.y, target_pos.y, t))

func update_rotation(t: float) -> void:
	var follow_type2: int = actor.get_value("follow_type2")
	var r_min_deg = actor.get_value("rot_min") 
	var r_max_deg = actor.get_value("rot_max") 
	
	var target_rot_rad: float = 0.0
	
	if follow_type2 == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_rotation(r_min_deg, r_max_deg, t)
			return 
		else:
			var norm = get_normalized_mouse()
			var input_val = norm.x
			
			var limit_deg = r_max_deg if input_val >= 0 else r_min_deg
			var target_deg = abs(input_val) * abs(limit_deg) * sign(limit_deg)
			target_rot_rad = deg_to_rad(target_deg)

	elif follow_type2 == 17 and Tracker.working:
		var raw_rot_deg = 0.0
		match actor.get_value("udp_rot"):
			1: 
				var real_min = min(r_min_deg, r_max_deg)
				var real_max = max(r_min_deg, r_max_deg)
				raw_rot_deg = clamp(Tracker.track_rot.y, real_min, real_max)
			2: raw_rot_deg = rad_to_deg(Tracker.track_pupil_left.angle())
			3: raw_rot_deg = rad_to_deg(Tracker.track_pupil_right.angle())
			4: raw_rot_deg = Tracker.eye_smile_left * r_max_deg
			5: raw_rot_deg = Tracker.eye_smile_right * r_max_deg
			6: raw_rot_deg = Tracker.cheek_raise_left * r_max_deg
			7: raw_rot_deg = Tracker.cheek_raise_right * r_max_deg
			8: raw_rot_deg = Tracker.smooth_brow_left * r_max_deg
			9: raw_rot_deg = Tracker.smooth_brow_right * r_max_deg
			
		target_rot_rad = deg_to_rad(raw_rot_deg)

	elif follow_type2 in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12]:
		var axis = _get_input_axis(follow_type2)
		var input_val = axis.x
		
		var limit_deg = r_max_deg if input_val >= 0 else r_min_deg
		var target_deg = abs(input_val) * abs(limit_deg) * sign(limit_deg)
		target_rot_rad = deg_to_rad(target_deg)

		if follow_type2 in [3,4,5,6,7,8] and actor.get_value("snap_rot") and not axis.is_zero_approx():
			target_rot_rad = lerp(modifier.rotation, target_rot_rad, 0.15) 
	
	modifier.rotation = lerp(modifier.rotation, target_rot_rad, t)

func update_scale(t: float) -> void:
	var follow_type3: int = actor.get_value("follow_type3")
	var s_min_x = actor.get_value("scale_x_min")
	var s_max_x = actor.get_value("scale_x_max")
	var s_min_y = actor.get_value("scale_y_min")
	var s_max_y = actor.get_value("scale_y_max")
	
	var swap_x: bool = actor.get_value("scale_swap_x")
	var swap_y: bool = actor.get_value("scale_swap_y")

	var x_val: float = 0.0
	var y_val: float = 0.0

	if follow_type3 == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_scale(s_min_x, s_max_x, s_min_y, s_max_y, t)
			return
		else:
			var norm = get_normalized_mouse()
			
			var input_for_scale_x = norm.y if swap_x else norm.x
			var input_for_scale_y = norm.x if swap_y else norm.y
			
			var limit_x = s_max_x if input_for_scale_x >= 0 else s_min_x
			var limit_y = s_max_y if input_for_scale_y >= 0 else s_min_y
			
			x_val = abs(input_for_scale_x) * limit_x
			y_val = abs(input_for_scale_y) * limit_y

	elif follow_type3 == 17 and Tracker.working:
		var clamped_x: float = 1.0
		var clamped_y: float = 1.0
		var scale_x = s_max_x 
		var scale_y = s_max_y
		
		match actor.get_value("udp_scale"):
			1:
				clamped_x = clamp(Tracker.track_pos.x * scale_x, 0.001, 1.0)
				clamped_y = clamp(Tracker.track_pos.y * scale_y, 0.001, 1.0)
			2:
				clamped_x = clamp(Tracker.track_pupil_left.x * scale_x, 0.001, 1.0)
				clamped_y = clamp(Tracker.track_pupil_left.y * scale_y, 0.001, 1.0)
			3:
				clamped_x = clamp(Tracker.track_pupil_right.x * scale_x, 0.0, 1.0)
				clamped_y = clamp(Tracker.track_pupil_right.y * scale_y, 0.0, 1.0)
			4: clamped_y = Tracker.eye_smile_left * scale_y
			5: clamped_y = Tracker.eye_smile_right * scale_y
			6: clamped_y -= Tracker.cheek_raise_left * (1.0 - scale_y)
			7: clamped_y -= Tracker.cheek_raise_right * (1.0 - scale_y)
			8: clamped_y += Tracker.smooth_brow_left * scale_y
			9: clamped_y += Tracker.smooth_brow_right * scale_y
		
		target_scale = Vector2(clamped_x, clamped_y)
		modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_scale.x, t))
		modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_scale.y, t))
		return

	elif follow_type3 in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12]:
		var axis = _get_input_axis(follow_type3)
		
		var input_for_scale_x = axis.y if swap_x else axis.x
		var input_for_scale_y = axis.x if swap_y else axis.y
		
		var limit_x = s_max_x if input_for_scale_x >= 0 else s_min_x
		var limit_y = s_max_y if input_for_scale_y >= 0 else s_min_y
		
		if follow_type3 in [3, 4, 5, 6, 7, 8]:
			if actor.get_value("snap_scale") and not axis.is_zero_approx():
				target_scale = target_scale.lerp(axis, 0.15)
			else:
				target_scale = axis
			x_val = abs(target_scale.x) * limit_x
			y_val = abs(target_scale.y) * limit_y
		else:
			x_val = abs(input_for_scale_x) * limit_x
			y_val = abs(input_for_scale_y) * limit_y
			
	var target_sx: float = 1.0 + x_val
	var target_sy: float = 1.0 + y_val
	
	modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_sx, t))
	modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_sy, t))

func _get_input_axis(f_type: int) -> Vector2:
	match f_type:
		1: return axis_left
		2: return axis_right
		10: return axis_shoulderl
		11: return axis_shoulderr
		12: return axis_lr_3
		3, 4, 5, 6, 7, 8:
			return GlobalCalculations.some_keyboard_calc_wasd("follow_type", actor)
	return Vector2.ZERO

func follow_mouse_vel_rotation(r_min: float, r_max: float, t: float):
	var vec = Vector2(-dir_vel_anim.x, 0).normalized()
	var normalized_vel = vec.x 
	
	var limit_deg = r_max if normalized_vel >= 0 else r_min
	
	var target_deg = abs(normalized_vel) * abs(limit_deg) * sign(limit_deg)
	var target_rot_rad = deg_to_rad(target_deg)
	
	modifier.rotation = GlobalCalculations.is_nan_or_inf(lerp(modifier.rotation, target_rot_rad, t))

func follow_mouse_vel_scale(s_min_x: float, s_max_x: float, s_min_y: float, s_max_y: float, t: float):
	var vec = dir_vel_anim.normalized()
	var normalized_mouse = vec/2

	var norm_x = clamp(abs(normalized_mouse.x), 0.0, 1.0)
	var norm_y = clamp(abs(normalized_mouse.y), 0.0, 1.0)

	var limit_x = s_max_x if normalized_mouse.x >= 0 else s_min_x
	var limit_y = s_max_y if normalized_mouse.y >= 0 else s_min_y
	
	var change_x = limit_x * norm_x
	var change_y = limit_y * norm_y
	
	var target_scale_x = 1.0 + change_x
	var target_scale_y = 1.0 + change_y
	
	modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_scale_x, t), true)
	modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_scale_y, t), true)

func update_sprite_animation(dir: Vector2, dist: float, _delta: float) -> void:
	if actor.sprite_type != "Sprite2D" or not actor.get_value("non_animated_sheet") or not actor.get_value("animate_to_mouse"):
		return

	var range_x = actor.get_value("pos_x_max")
	var range_y = actor.get_value("pos_y_max")
	
	var dist_x = dir.x * min(dist, range_x)
	var dist_y = dir.y * min(dist, range_y)

	var hframes = %Sprite2D.hframes
	var vframes = %Sprite2D.vframes

	var norm_x = (dist_x / (2.0 * range_x)) + 0.5
	var norm_y = (dist_y / (2.0 * range_y)) + 0.5

	var frame_x = clamp(floor(norm_x * hframes), 0, hframes - 1)
	var frame_y = clamp(floor(norm_y * vframes), 0, vframes - 1)

	frame_h = move_toward(frame_h, frame_x, actor.get_value("animate_to_mouse_speed"))
	frame_v = move_toward(frame_v, frame_y, actor.get_value("animate_to_mouse_speed"))

	%Sprite2D.frame_coords.x = floor(frame_h)
	%Sprite2D.frame_coords.y = floor(frame_v)

func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
