extends Node
class_name GlobalCalculations

static func is_nan_or_inf(value, should_be_one := false):
	var fallback := 1.0 if should_be_one else 0.0

	if value is float or value is int:
		return fallback if (is_inf(value) or is_nan(value)) else value

	elif value is Vector2 or value is Vector2i:
		var x = fallback if (is_inf(value.x) or is_nan(value.x)) else value.x
		var y = fallback if (is_inf(value.y) or is_nan(value.y)) else value.y
		return Vector2(x, y)
	
	return value


static func clamp_angle(value: float, min_angle: float, max_angle: float, rest: float = 0.0) -> float:
	var v = value + rest
	var n = min_angle + rest
	var m = max_angle + rest
	if n <= m:
		return clampf(v, n, m)
	if v > m and v < n:
		var dist_min = abs(v - n)
		var dist_max = abs(v - m)
		return n if dist_min < dist_max else m
	return v


static func _get_distance(a: float, b: float) -> float:
	return a - b

static func some_keyboard_calc_wasd(type_name: String = "follow_type", actor: Node = null) -> Vector2:
	var normal = Vector2(0.0, 0.0)
	if actor.get_value(type_name) in [3, 4, 5]:
		var ws: Vector2 = Vector2.ZERO
		var ad: Vector2 = Vector2.ZERO
		if GlobInput.is_action_pressed("KeyMovementW"):
			ws.y = 1.0
		if GlobInput.is_action_pressed("KeyMovementS"):
			ws.x = 1.0
		if GlobInput.is_action_pressed("KeyMovementA"):
			ad.y = 1.0
		if GlobInput.is_action_pressed("KeyMovementD"):
			ad.x = 1.0

		if actor.get_value(type_name) == 3:
			normal = Vector2(ws.x - ws.y, ws.x - ws.y)
		elif actor.get_value(type_name) == 4:
			normal = Vector2(ad.x - ad.y, ad.x - ad.y)
		elif actor.get_value(type_name) == 5:
			normal = Vector2(ad.x - ad.y, ws.x - ws.y)

	elif actor.get_value(type_name) in [6, 7, 8]:
		var ws: Vector2 = Vector2.ZERO
		var ad: Vector2 = Vector2.ZERO
		if GlobInput.is_action_pressed("Up"):
			ws.y = 1.0
		if GlobInput.is_action_pressed("Down"):
			ws.x = 1.0
		if GlobInput.is_action_pressed("Left"):
			ad.y = 1.0
		if GlobInput.is_action_pressed("Right"):
			ad.x = 1.0

		if actor.get_value(type_name) == 6:
			normal = Vector2(ws.x - ws.y, ws.x - ws.y)
		elif actor.get_value(type_name) == 7:
			normal = Vector2(ad.x - ad.y, ad.x - ad.y)
		elif actor.get_value(type_name) == 8:
			normal = Vector2(ad.x - ad.y, ws.x - ws.y)

	return normal


static func follow_type_helper(type_name : String = "follow_type", actor : Node = null, type = "position", axis_left = Vector2.ZERO, axis_right = Vector2.ZERO, move : Node = null):
	var dist : float = 0.0
	var selected_axis = Vector2.ZERO
	if actor.get_value(type_name) == 1 or actor.get_value(type_name) == 9:
		selected_axis = axis_left
	elif actor.get_value(type_name) == 2 or actor.get_value(type_name) == 10:
		selected_axis = axis_right

	
	if type == "position":
		if actor.get_value("snap_pos"):
			if selected_axis.x != 0:
				move.tracked.target_x = lerp(move.tracked.target_x, selected_axis.x * actor.get_value("look_at_mouse_pos"),actor.get_value("mouse_delay"))
			if selected_axis.y != 0 && actor.get_value("snap_pos"):
				move.tracked.target_y = lerp(move.tracked.target_y, selected_axis.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
		else:
			move.tracked.target_x = selected_axis.x * actor.get_value("look_at_mouse_pos")
			move.tracked.target_y = selected_axis.y * actor.get_value("look_at_mouse_pos_y")
		dist = Vector2(move.tracked.target_x, move.tracked.target_y).length()
		return {axis = selected_axis, dist = dist}

	if type == "angle":
		if actor.get_value("snap_rot"):
			if !selected_axis.is_zero_approx():
				move.target_rotation_axis = move.target_rotation_axis.lerp(axis_left, 0.15)
		else:
			move.tracked.target_rotation_axis = selected_axis
		return {axis = selected_axis}
	
	if type == "scale":
		if actor.get_value("snap_scale"):
			if selected_axis.is_zero_approx():
				move.tracked.target_scale_axis = move.tracked.target_scale_axis.lerp(selected_axis, 0.15)
		else:
			move.tracked.target_scale_axis = selected_axis
		return {axis = selected_axis}
