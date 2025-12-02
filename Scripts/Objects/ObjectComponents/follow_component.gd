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

var smoothed_dir := Vector2.ZERO
var dir_vel_anim := Vector2.ZERO
var dist_vel_anim := 0.0

var frame_h := 0.0
var frame_v := 0.0

var target_x := 0.0
var target_y := 0.0
var target_rotation :Vector2 = Vector2.ZERO
var target_scale :Vector2 = Vector2.ONE
var target_pos = Vector2.ZERO

var mouse_delta :Vector2 = Vector2.ZERO
var rest := false
var axis_left :Vector2 = Vector2.ZERO
var axis_right :Vector2 = Vector2.ZERO
var axis_shoulderl :Vector2 = Vector2.ZERO
var axis_shoulderr :Vector2 = Vector2.ZERO
var axis_lr_3 : Vector2 = Vector2.ZERO
var current_dir : Vector2 = Vector2.ZERO
var current_dist : float = 0.0


func _physics_process(delta: float) -> void:
	if Global.static_view or actor.rest_mode == 5:
		return
	if actor.rest_mode in [1,3] and rest:
		reset_modifier()
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
			mouse_coords = DisplayServer.mouse_get_position()
	
	elif main_marker.current_screen != Monitor.ALL_SCREENS:
		if !main_marker.mouse_in_current_screen():
			mouse_coords = Vector2.ZERO
		else:
			var viewport_size = actor.get_viewport().size
			var origin = actor.get_global_transform_with_canvas().origin
			var x_per = 1.0 - origin.x/float(viewport_size.x)
			var y_per = 1.0 - origin.y/float(viewport_size.y)
			var display_size = DisplayServer.screen_get_size(main_marker.current_screen)
			var offset = Vector2(display_size.x * x_per, display_size.y * y_per)
			var mouse_pos = DisplayServer.mouse_get_position() - DisplayServer.screen_get_position(main_marker.current_screen)
			mouse_coords = Vector2(mouse_pos - display_size) + offset 
	else:
		mouse_coords = actor.get_local_mouse_position()
	
	return mouse_coords

func update_controller_inputs() -> void:
	axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	axis_shoulderl = Input.get_vector("ShoulderL1", "ShoulderR1", "ShoulderL1", "ShoulderR1")
	axis_shoulderr = Input.get_vector("ShoulderL2", "ShoulderR2", "ShoulderL2", "ShoulderR2")
	axis_lr_3 = Input.get_vector("L3", "R3", "L3", "R3")

func update_position(dir: Vector2, dist: float, _delta: float) -> void:
	
	var follow_type = actor.get_value("follow_type")
	var keyboard_axis := Vector2.ZERO
	if follow_type in [3,4,5,6,7,8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type", actor)
	if follow_type == 0:
		if actor.get_value("follow_mouse_velocity"):
			if actor.get_value("snap_pos"):
				if abs(distance.x) > 0.5:
					target_pos.x = lerp(target_pos.x, last_dist.x, actor.get_value("mouse_delay"))
					current_dir.x = dir.x
				if abs(distance.y) > 0.5:
					target_pos.y = lerp(target_pos.y, last_dist.y, actor.get_value("mouse_delay"))
					current_dir.y = dir.y
			else:
				target_pos = target_pos.lerp(last_dist, actor.get_value("mouse_delay")) 
				current_dir = dir
		
		else:
			target_pos.x = dir.x * min(dist, actor.get_value("look_at_mouse_pos"))
			target_pos.y = dir.y * min(dist, actor.get_value("look_at_mouse_pos_y"))
			current_dir = dir
		
		
		
	elif follow_type == 1:
		if actor.get_value("snap_pos"):
			if axis_left.x != 0:
				target_x = lerp(target_x, axis_left.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
				current_dir.x = axis_left.x
			if axis_left.y != 0:
				target_y = lerp(target_y, axis_left.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
				current_dir.y = axis_left.y
			target_pos = Vector2(target_x, target_y)
		else:
			target_pos = axis_left * Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			current_dir = axis_left
			current_dist = target_pos.length()
	elif follow_type == 2:
		if actor.get_value("snap_pos"):
			if axis_right.x != 0:
				target_x = lerp(target_x, axis_right.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
				current_dir.x = axis_right.x
			if axis_right.y != 0:
				target_y = lerp(target_y, axis_right.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
				current_dir.y = axis_right.y
			target_pos = Vector2(target_x, target_y)
		else:
			target_pos = axis_right * Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			current_dir = axis_right
			current_dist = target_pos.length()
	elif follow_type == 10:
		if actor.get_value("snap_pos"):
			if axis_shoulderl.x != 0:
				target_x = lerp(target_x, axis_shoulderl.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
				current_dir.x = axis_shoulderl.x
			if axis_shoulderl.y != 0:
				target_y = lerp(target_y, axis_shoulderl.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
				current_dir.y = axis_shoulderl.y
			target_pos = Vector2(target_x, target_y)
		else:
			target_pos = axis_shoulderl * Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			current_dir = axis_shoulderl
			current_dist = target_pos.length()
	elif follow_type == 11:
		if actor.get_value("snap_pos"):
			if axis_shoulderr.x != 0:
				target_x = lerp(target_x, axis_shoulderr.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
				current_dir.x = axis_shoulderr.x
			if axis_shoulderr.y != 0:
				target_y = lerp(target_y, axis_shoulderr.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
				current_dir.y = axis_shoulderr.y
			target_pos = Vector2(target_x, target_y)
		else:
			target_pos = axis_shoulderr * Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			current_dir = axis_shoulderr
			current_dist = target_pos.length()
	elif follow_type == 12:
		if actor.get_value("snap_pos"):
			if axis_lr_3.x != 0:
				target_x = lerp(target_x, axis_lr_3.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
				current_dir.x = axis_lr_3.x
			if axis_lr_3.y != 0:
				target_y = lerp(target_y, axis_lr_3.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
				current_dir.y = axis_lr_3.y
			target_pos = Vector2(target_x, target_y)
		else:
			target_pos = axis_lr_3 * Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			current_dir = axis_lr_3
			current_dist = target_pos.length()
	elif follow_type in [3,4,5,6,7,8]:
		if actor.get_value("snap_pos"):
			if keyboard_axis.x != 0:
				target_x = lerp(target_x, keyboard_axis.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
				current_dir.x = keyboard_axis.x
			if keyboard_axis.y != 0:
				target_y = lerp(target_y, keyboard_axis.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
				current_dir.y = keyboard_axis.y
			target_pos = Vector2(target_x, target_y)
		else:
			target_pos = keyboard_axis * Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			current_dir = keyboard_axis
		current_dist = target_pos.length()

	else:
		target_pos = dir * Vector2(
			min(dist, actor.get_value("look_at_mouse_pos")),
			min(dist, actor.get_value("look_at_mouse_pos_y"))
		)
	if actor.get_value("snap_pos"):
		if target_pos.x != 0:
			target_x = lerp(target_x, target_pos.x, actor.get_value("mouse_delay"))
		if target_pos.y != 0:
			target_y = lerp(target_y, target_pos.y, actor.get_value("mouse_delay"))
		target_pos = Vector2(target_x, target_y)

	if actor.sprite_type == "Sprite2D" && actor.get_value("non_animated_sheet") && actor.get_value("animate_to_mouse"):
		update_sprite_animation(current_dir, current_dist, _delta)
		if !actor.get_value("animate_to_mouse_track_pos"):
			modifier.position.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.x, 0.0, actor.get_value("mouse_delay")))
			modifier.position.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.y, 0.0, actor.get_value("mouse_delay")))
			return
	if actor.sprite_type == "Mesh" and mesh != null:
		var can_deform : bool = false
		if Global.mesh_text_node != null && is_instance_valid(Global.mesh_text_node):
			can_deform = Global.mesh_text_node.deform
		if !mesh.editable && !can_deform:
			var raw_offset = target_pos
			var amp = Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			var safe_deform_pos = mesh.apply_wobble_to_deformer(raw_offset, _delta, amp, 0.08)
			if abs((safe_deform_pos - Vector2(mesh.deform_x, mesh.deform_y)).length()) > 0.01:
				mesh.deformations_3x3(safe_deform_pos.x, safe_deform_pos.y)
		if !actor.get_value("move_with_follow"):
			modifier.position = modifier.position.lerp(Vector2.ZERO, actor.get_value("mouse_delay"))
			return

	modifier.position.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.x, target_pos.x, actor.get_value("mouse_delay")))
	modifier.position.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.y, target_pos.y, actor.get_value("mouse_delay")))

func update_rotation(_dir: Vector2, delta: float) -> void:
	var follow_type2 = actor.get_value("follow_type2")
	var target_rot = 0.0
	var keyboard_axis := Vector2.ZERO

	if follow_type2 in [3,4,5,6,7,8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type2", actor)
		if actor.get_value("snap_rot") and not keyboard_axis.is_zero_approx():
			target_rotation = target_rotation.lerp(keyboard_axis, 0.15)
		else:
			target_rotation = keyboard_axis
	if follow_type2 == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_rotation()
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
			var safe_rot_min = clamp(actor.sprite_data.rLimitMin, -360, 360)
			var safe_rot_max = clamp(actor.sprite_data.rLimitMax, -360, 360)
			var rotation_factor = lerp(actor.sprite_data.mouse_rotation, actor.sprite_data.mouse_rotation_max, max((normalized_mouse + 1) / 2, 0.001))
			target_rot = GlobalCalculations.is_nan_or_inf(clamp(rotation_factor, deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max)))

	elif follow_type2 == 1: target_rot = axis_left.x
	elif follow_type2 == 2: target_rot = axis_right.x
	elif follow_type2 == 10: target_rot = axis_shoulderl.x
	elif follow_type2 == 11: target_rot = axis_shoulderr.x
	elif follow_type2 == 12: target_rot = axis_lr_3.x
	elif follow_type2 in [3,4,5,6,7,8]:
		target_rot = target_rotation.x

	var t = actor.get_value("mouse_delay") * delta * 60.0
	t = clamp(t, 0.0, 1.0)
	modifier.rotation = lerp_angle(modifier.rotation, target_rot, t)

func update_scale(dir: Vector2, delta: float) -> void:
	var follow_type3 = actor.get_value("follow_type3")
	var keyboard_axis := Vector2.ZERO
	if follow_type3 in [3,4,5,6,7,8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type3", actor)
		if actor.get_value("snap_scale") and not keyboard_axis.is_zero_approx():
			target_scale = target_scale.lerp(keyboard_axis, 0.15)
		else:
			target_scale = keyboard_axis

	var x_val = 0.0
	var y_val = 0.0

	if follow_type3 == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_scale()
		else:
			x_val = abs(dir.x)
			y_val = abs(dir.y)
	elif follow_type3 == 1:
		x_val = abs(axis_left.x)
		y_val = abs(axis_left.y)
	elif follow_type3 == 2:
		x_val = abs(axis_right.x)
		y_val = abs(axis_right.y)
	elif follow_type3 == 10:
		x_val = abs(axis_shoulderl.x)
		y_val = abs(axis_shoulderl.y)
	elif follow_type3 == 11:
		x_val = abs(axis_shoulderr.x)
		y_val = abs(axis_shoulderr.y)
	elif follow_type3 == 12:
		x_val = abs(axis_lr_3.x)
		y_val = abs(axis_lr_3.y)
	elif follow_type3 in [3,4,5,6,7,8]:
		x_val = abs(target_scale.x)
		y_val = abs(target_scale.y)
	var target_sx = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x"), max(x_val, 0.01))
	var target_sy = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(y_val, 0.01))
	var t = actor.get_value("mouse_delay") * delta * 60.0
	t = clamp(t, 0.0, 1.0)
	modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_sx, t))
	modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_sy, t))

func follow_mouse_vel_rotation():
	var t = Vector2(-dir_vel_anim.x, 0).normalized()
	var normalized_mouse = t.x/2
	normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
	var rotation_factor = lerp(actor.get_value("mouse_rotation_max"), actor.get_value("mouse_rotation"), max(0.01, (normalized_mouse) / 2))
	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var _target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
	modifier.rotation = GlobalCalculations.is_nan_or_inf(lerp_angle(modifier.rotation, _target_rotation, actor.get_value("mouse_delay")))

func follow_mouse_vel_scale():
	var t = dir_vel_anim.normalized()
	var normalized_mouse = t/2

	var norm_x = clamp(abs(normalized_mouse.x), 0.0, 1.0)
	var norm_y = clamp(abs(normalized_mouse.y), 0.0, 1.0)

	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x") , max(norm_x, 0.01))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.01))
	modifier.scale.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.x, target_scale_x, actor.get_value("mouse_delay")), true)
	modifier.scale.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.scale.y, target_scale_y, actor.get_value("mouse_delay")), true)

func update_sprite_animation(dir: Vector2, dist: float, _delta: float) -> void:
	if actor.sprite_type != "Sprite2D" or not actor.get_value("non_animated_sheet") or not actor.get_value("animate_to_mouse"):
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
