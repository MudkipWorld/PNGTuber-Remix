extends Node

@export var actor: SpriteObject
@export var modifier: Node2D

var smoothed_dir : Vector2 = Vector2.ZERO
var dir_vel_anim : Vector2 = Vector2.ZERO
var dist_vel_anim : float = 0.0

var target_rotation :Vector2 = Vector2.ZERO
var target_scale :Vector2 = Vector2.ONE

var rest : bool = false
var axis_left :Vector2 = Vector2.ZERO
var axis_right :Vector2 = Vector2.ZERO
var axis_shoulderl :Vector2 = Vector2.ZERO
var axis_shoulderr :Vector2 = Vector2.ZERO
var axis_lr_3 : Vector2 = Vector2.ZERO
var final_target : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if actor.get_value("follow_type3") == 15:
		modifier.scale = Vector2.ONE
		return
	if Global.static_view or actor.rest_mode == 5:
		return
	if actor.rest_mode in [1,3] and rest:
		reset_modifier()
	else:
		var dir = (%FollowPosition.mouse_coords - Vector2.ZERO).normalized() if %FollowPosition.mouse_coords.length() > 0.0001 else Vector2.ZERO
		update_controller_inputs()
		update_scale(dir, delta)

func reset_modifier() -> void:
	modifier.scale = Vector2.ONE

func update_controller_inputs() -> void:
	axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	axis_shoulderl = Input.get_vector("ShoulderL1", "ShoulderR1", "ShoulderL1", "ShoulderR1")
	axis_shoulderr = Input.get_vector("ShoulderL2", "ShoulderR2", "ShoulderL2", "ShoulderR2")
	axis_lr_3 = Input.get_vector("L3", "R3", "L3", "R3")

func update_scale(_dir: Vector2, delta: float) -> void:
	if actor.get_value("follow_type3") == 15:
		return
	
	var main_marker = Global.main.get_node("%Marker")
	var follow_type3: int = actor.get_value("follow_type3")
	var s_min_x : float = actor.get_value("scale_x_min")
	var s_max_x : float = actor.get_value("scale_x_max")
	var s_min_y : float = actor.get_value("scale_y_min")
	var s_max_y : float = actor.get_value("scale_y_max")
	var invert_x: bool = actor.get_value("scale_invert_x")
	var invert_y: bool = actor.get_value("scale_invert_y")
	var swap_x: bool = actor.get_value("scale_swap_x")
	var swap_y: bool = actor.get_value("scale_swap_y")
	
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
				var test = follow_mouse_scale(%FollowPosition.mouse_coords, main_marker )
				x_val = test.x
				y_val = test.y
				
		1, 2, 10, 11, 12:
			var axis = Vector2.ZERO
			if follow_type3 == 1:
				axis = follow_controller_scale(axis_left)

			elif follow_type3 == 2:
				axis = follow_controller_scale(axis_right)
			elif follow_type3 == 10:
				axis = follow_controller_scale(axis_shoulderl)

			elif follow_type3 == 11:
				axis = follow_controller_scale(axis_shoulderr)

			elif follow_type3 == 12:
				axis = follow_controller_scale(axis_lr_3)
			
			if actor.get_value("snap_scale"):
				if axis.x != 0:
					x_val = axis.x
					
				if axis.y != 0:
					y_val = axis.y
			else:
				x_val = axis.x
				y_val = axis.y

		3, 4, 5, 6, 7, 8:
			keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type3", actor)
			var axis = follow_controller_scale(keyboard_axis)
			if actor.get_value("snap_scale"):
				if axis.x != 0:
					x_val = axis.x
					
				if axis.y != 0:
					y_val = axis.y
			else:
				x_val = axis.x
				y_val = axis.y
			
		17:
			if Tracker.working:
				var clamped_x: float = 1.0
				var clamped_y: float = 1.0
				var norm_1 : float = 0.0
				var norm_2 : float = 0.0
				
				match actor.get_value("udp_scale"):
					0:
						pass
					1:
						
						norm_1 = Vector2(Tracker.track_pos.normalized().x, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.track_pos.normalized().y).length()

					2:
						norm_1 = Vector2(Tracker.track_pupil_left.normalized().x, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.track_pupil_left.normalized().y).length()

					3:
						norm_1 = Vector2(Tracker.track_pupil_right.normalized().x, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.track_pupil_right.normalized().y).length()
					4:
						norm_1 = Vector2(Tracker.eye_smile_left, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.eye_smile_left).length()
					5:
						norm_1 = Vector2(Tracker.eye_smile_left, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.eye_smile_left).length()
					6:
						norm_1 = Vector2(Tracker.cheek_raise_left, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.cheek_raise_left).length()

					7:
						norm_1 = Vector2(Tracker.cheek_raise_right, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.cheek_raise_right).length()

					8:
						norm_1 = Vector2(Tracker.smooth_brow_left, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.smooth_brow_left).length()
						
					9:
						norm_1 = Vector2(Tracker.smooth_brow_right, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.smooth_brow_right).length()
					10:
						norm_1 = Vector2(Tracker.cheek_average, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.cheek_average).length()
						
					11:
						norm_1 = Vector2(Tracker.mouth_pucker, 0.0).length()
						norm_2 = Vector2( 0.0, Tracker.mouth_pucker).length()
						
				clamped_x = lerp(s_max_x, s_min_x, norm_1)
				clamped_y = lerp(s_max_y, s_min_y, norm_2)
				x_val = clamped_x
				y_val = clamped_y

	target_scale = target_scale.lerp(Vector2(x_val, y_val), 0.15)
	
	var sw_x = y_val if swap_x else x_val
	var sw_y = x_val if swap_y else y_val
	
	if invert_x:
		sw_x *= -1
	if invert_y:
		sw_y *= -1
		
	final_target = Vector2(sw_x, sw_y)
	
	var target_sx: float = 1.0 - final_target.x
	var target_sy: float = 1.0 - final_target.y
	var t: float = clamp(actor.get_value("mouse_delay") * delta * 60.0, 0.0, 1.0)
	modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_sx, t))
	modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_sy, t))

func follow_mouse_scale(mouse, main_marker) -> Vector2:
	var screen_size = DisplayServer.screen_get_size(-1)
	if main_marker.current_screen == Monitor.ALL_SCREENS:
		screen_size = DisplayServer.screen_get_size(0)
	else:
		screen_size = DisplayServer.screen_get_size(main_marker.current_screen)

	var center = screen_size * 0.5
	var dist_from_center = mouse - center
	
	var norm_x = clamp(abs(dist_from_center.x) / center.x, 0.0, 1.0)
	var norm_y = clamp(abs(dist_from_center.y) / center.y, 0.0, 1.0)

	var s_min_x : float = actor.get_value("scale_x_min")
	var s_max_x : float = actor.get_value("scale_x_max")
	var s_min_y : float = actor.get_value("scale_y_min")
	var s_max_y : float = actor.get_value("scale_y_max")

	var target_scale_x = -lerp(s_max_x, s_min_x, norm_x)
	var target_scale_y = -lerp(s_min_y,s_max_y , norm_y)

	return Vector2(target_scale_x, target_scale_y)

func follow_controller_scale(axis: Vector2) -> Vector2:
	var s_min_x : float = actor.get_value("scale_x_min")
	var s_max_x : float = actor.get_value("scale_x_max")
	var s_min_y : float = actor.get_value("scale_y_min")
	var s_max_y : float = actor.get_value("scale_y_max")

	var dist : float = clamp(axis.length(), 0.0, 1.0)

	var target_scale_x : float = -lerp(s_max_x, s_min_x, dist)
	var target_scale_y : float = -lerp(s_max_y, s_min_y, dist)

	return Vector2(target_scale_x, target_scale_y)

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

func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
