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
var final_target : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if actor.get_value("follow_type") == 15:
		target_pos = Vector2.ZERO
		modifier.position = Vector2.ZERO
		return
	if Global.static_view or actor.rest_mode == 5:
		return
	if actor.rest_mode in [1,3] and rest:
		reset_modifier()
	else:
		process_follow(delta)
		mouse_coords = follow_calculation()
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

func follow_calculation(_delta = 0.0):
	var main_marker = Global.main.get_node("%Marker")
	if WindowHandler.windows:
		mouse_coords = Vector2.ZERO
		if main_marker.current_screen == Monitor.ALL_SCREENS or main_marker.mouse_in_current_screen():
			mouse_coords = get_mouse_coords(0)
	elif main_marker.current_screen != Monitor.ALL_SCREENS:
		if !main_marker.mouse_in_current_screen() && Global.settings_dict.snap_out_of_bounds:
			mouse_coords = Vector2.ZERO
		else:
			mouse_coords = get_mouse_coords(main_marker.current_screen)
	else:
		mouse_coords = get_mouse_coords(0)
	return mouse_coords

func get_mouse_coords(screen) -> Vector2:
	var coord : Vector2 = Vector2.ZERO
	if actor.get_value("use_object_pos"):
		
		var offset = Vector2(DisplayServer.screen_get_position(screen))
		coord = actor.to_local(actor.get_global_mouse_position() - (offset / Global.camera.zoom.clampf(0.001, 10.0)))
		
	else:
		var viewport_size = actor.get_viewport().size
		var origin = actor.get_global_transform_with_canvas().origin
		var x_per = 1.0 - origin.x/float(viewport_size.x)
		var y_per = 1.0 - origin.y/float(viewport_size.y)
		var display_size = Vector2(DisplayServer.screen_get_size(screen))
		var offset = Vector2(display_size.x * x_per, display_size.y * y_per)
		var mouse_pos = Vector2(DisplayServer.mouse_get_position()) - Vector2(DisplayServer.screen_get_position(screen))
		coord = Vector2(mouse_pos - display_size) + offset
		
	return coord

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
	var swap_x: bool = actor.get_value("pos_swap_x")
	var swap_y: bool = actor.get_value("pos_swap_y")
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
				var multip = Vector2(TrackingBackend.osf_pos_strength, TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Tracker.track_pupil_left.normalized(), Tracker.track_pupil_left * multip)
			3:
				var multip = Vector2(TrackingBackend.osf_pos_strength, TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Tracker.track_pupil_right.normalized(), Tracker.track_pupil_right * multip)
			4:
				var dis = Vector2(Tracker.eye_smile_left * TrackingBackend.osf_pos_strength, Tracker.eye_smile_left * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.eye_smile_left, Tracker.eye_smile_left), dis)
			5:
				var dis = Vector2(Tracker.eye_smile_right * TrackingBackend.osf_pos_strength, Tracker.eye_smile_right * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.eye_smile_right, Tracker.eye_smile_right), dis)
			6:
				var dis = Vector2(Tracker.cheek_raise_left * TrackingBackend.osf_pos_strength, Tracker.cheek_raise_left * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.cheek_raise_left, Tracker.cheek_raise_left), dis)
			7:
				var dis = Vector2(Tracker.cheek_raise_right * TrackingBackend.osf_pos_strength, Tracker.cheek_raise_right * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.cheek_raise_right, Tracker.cheek_raise_right), dis)
			8:
				var dis = Vector2(Tracker.brow_left_final * TrackingBackend.osf_pos_strength, Tracker.brow_left_final * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.brow_left_final, Tracker.brow_left_final),dis)
			9:
				var dis = Vector2(Tracker.brow_right_final * TrackingBackend.osf_pos_strength, Tracker.brow_right_final * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.brow_right_final, Tracker.brow_right_final), dis)
			10:
				var dis = Vector2(Tracker.cheek_average * TrackingBackend.osf_pos_strength, Tracker.cheek_average * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.cheek_average, Tracker.cheek_average), dis)
			11:
				var dis = Vector2(Tracker.mouth_pucker * TrackingBackend.osf_pos_strength, Tracker.mouth_pucker * TrackingBackend.osf_pos_strength_y)
				follow_position_calculations(Vector2(Tracker.mouth_pucker, Tracker.mouth_pucker), dis)
	else:
		target_pos = Vector2.ZERO
	
	var sw_x = target_pos.y if swap_x else target_pos.x
	var sw_y = target_pos.x if swap_y else target_pos.y
	
	if invert_x:
		sw_x *= -1
	if invert_y:
		sw_y *= -1
	
	final_target = Vector2(sw_x, sw_y)
	
	if actor.sprite_type == "Sprite2D" && actor.get_value("animate_to_mouse") && actor.get_value("non_animated_sheet"):
		update_sprite_animation(current_dir, current_dist, _delta)
		if !actor.get_value("animate_to_mouse_track_pos"):
			modifier.position = modifier.position.lerp(Vector2.ZERO, actor.get_value("mouse_delay"))
			return
	if actor.sprite_type == "Mesh" && mesh != null && is_instance_valid(mesh):
		if !actor.get_value("move_with_follow"):
			modifier.position = modifier.position.lerp(Vector2.ZERO, actor.get_value("mouse_delay"))
			return

	modifier.position = final_target

# shout out to the worst code i have ever made
func follow_position_calculations(dir : Vector2, m_dist : Vector2 = Vector2.ZERO):
	var dist = dir
	
	var min_x = actor.get_value("pos_x_min")
	var max_x = actor.get_value("pos_x_max")

	var min_y = actor.get_value("pos_y_min")
	var max_y = actor.get_value("pos_y_max")
	
	if m_dist != Vector2.ZERO:
		dist = m_dist
	else:
		dist = Vector2(abs(min_x) + max_x, abs(min_y) + max_y)*0.5
		
	var clamped_x_min = 0.0
	var clamped_y_min  = 0.0
	
	if min_x != 0 && max_x == 0:
		if dir.x <= 0:
			clamped_x_min = dir.x * min(dist.x, abs(min_x))
			
	elif min_x == 0 && max_x != 0:
		if dir.x >= 0:
			clamped_x_min = dir.x * min(dist.x, max_x)
	else:
		clamped_x_min =  abs(max(min_x, sign(dir.x) * dist.x))
		clamped_x_min = dir.x * min(max_x ,clamped_x_min)
	
	if min_y != 0 && max_y == 0:
		if dir.y >= 0:
			clamped_y_min = dir.y * clamp(dist.y, 0, abs(min_y))
	
	elif min_y == 0 && max_y != 0:
		if dir.y <= 0:
			clamped_y_min = dir.y * clamp(dist.y, 0, max_y)
		
	else:
		clamped_y_min =  abs(max(-max_y, sign(dir.y) * dist.y))
		clamped_y_min = dir.y * min(abs(min_y) ,clamped_y_min)
	
	var x = clamped_x_min
	var y = clamped_y_min
	
	if actor.get_value("snap_pos"):
		if dir.x != 0:
			target_pos.x =  lerp(target_pos.x, x, actor.get_value("mouse_delay"))
			current_dir.x = dir.x
		if dir.y != 0:
			target_pos.y = lerp(target_pos.y, y, actor.get_value("mouse_delay"))
			current_dir.y = dir.y
	else:
		var t = Vector2(x, y)

		target_pos.x = lerp(target_pos.x, t.x, actor.get_value("mouse_delay"))
		target_pos.y = lerp(target_pos.y, t.y, actor.get_value("mouse_delay"))
		current_dir = dir
		current_dist = target_pos.length()

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
