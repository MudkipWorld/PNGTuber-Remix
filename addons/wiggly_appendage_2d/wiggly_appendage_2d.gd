@tool
extends Line2D
class_name WigglyAppendage2D


enum {
	PREVIOUS_POINT = 0,
	POSITION = 1,
	ROTATION = 2,
	ANGULAR_MOMENTUM = 3,
}

@export var actor : SpriteObject

@export var anchor_target: Node2D
## Amout of segments
@export_range(1, 10) var segment_count: int = 5 :set = _set_segment_count
## Length of segments
@export var segment_length: float = 30.0
## How much the appendge should curve
@export_range(-1.57, 1.57) var curvature: float = 0.0
## How much more the later parts of the appendge should curve
@export_range(-3.0, 3.0) var curvature_exponent: float = 0.0
## Max angle for every segment. This is the actual value used in calculations
@export_range(0.0, 180.0, 0.01, "radians") var max_angle: float = TAU / 2
## How fast the segemnt should rotate back to the target rotation once the max angle is reached in radians per seccond
@export_range(0, 6.28) var comeback_speed: float = 0.0
## How stiff the tail should be
@export var stiffness: float = 20.0
## How much the stiffness should be lowered for the later parts of the appendage
@export var stiffness_decay: float = 0.0
## The stiffness decay is raised to this power
@export var stiffness_decay_exponent: float = 1.0
## The gravity acceleration to apply in pixels per second squared
@export var gravity := Vector2(0, 0)
## How much the appandge should slow down
@export var damping: float = 5.0
## The maximum rotational speed for every segment in radians per seccond
@export var max_angular_momentum: float = 25.13
## How much the line should be subdivided to achieve a smoother look. This value should not be 1
@export_range(0, 10) var subdivision: int = 2
## Add an aditional segment before start of the appendage to prevent it form appearing disconnected
@export var additional_start_segment := false
## Length of the additional start segment 
@export var additional_start_segment_length: float = 10.0
## If true, the additional start segment will be subdivided by the subdivisions parameter
@export var subdivide_additional_start_segment := true
## If true, only process when this node and all parents aren't hidden
@export var only_process_when_visible := true

@export var keep_length : bool = false

var _rest_direction_angle : float = 0.0

## If true, the first few segments will be stiffer and blend with root rotation
@export var stiff_root_segments: bool = false

## How many of the first segments should be stiffened (only used if stiff_root_segments = true)
@export_range(1, 5) var stiff_root_count: int = 5

@export_range(-360, 360, 0.01) var rest_direction_angle: float:
	set(value):
		rest_direction_angle = value
		_rest_direction_angle = deg_to_rad(value)
		if is_inside_tree(): reset()

@export var max_length_stretch : float = 500


@export var mirror_anchor_movement_h : bool = false

@export var mirror_anchor_movement_v : bool = false


var current_segment_length: float = 1.0
const PREVIOUS_POSITION = 1
var physics_points: Array
var current_dir : Vector2
var prev_pos : Array = []
var stretch_seg : float = 0.0
var test : Vector2 = Vector2.ZERO


var prev_root_pos: Vector2
var smoothed_root_pos: Vector2
@export_range(0.0, 1.0) var root_follow_smoothness := 0.65



func _ready():
	reset()
	prev_root_pos = global_position
	smoothed_root_pos = global_position

	

func _physics_process(delta):
	if only_process_when_visible and not is_visible_in_tree():
		return
	if anchor_target != null && is_instance_valid(anchor_target):
		var root_pos = get_global_position()
		var anchor_pos = anchor_target.get_node("%Origin").global_position
		var total_length = root_pos.distance_to(anchor_pos)
	current_segment_length = _get_true_segment_length()
	
	for i in range(physics_points.size()):
		if i == 0:
			_process_root_point(physics_points[i], delta)
		else:
			_process_point(physics_points[i], delta, i)
	
	if anchor_target != null && is_instance_valid(anchor_target):
		_apply_verlet_anchor(delta)
	_update_line()

func _verlet_integration(delta):
	for i in range(physics_points.size()):
		if i == 0:
			continue
		var point = physics_points[i]
		var current_pos = point[POSITION]
		var prev_pos = point[PREVIOUS_POSITION] if point.size() > 4 else current_pos
		var velocity = current_pos - prev_pos
		if velocity.length() < 0.01:
			velocity = Vector2.ZERO
		var acceleration = gravity
		var new_pos = current_pos + velocity + acceleration * delta * delta
		point[PREVIOUS_POSITION] = current_pos
		point[POSITION] = new_pos
		physics_points[i] = point

func _apply_verlet_anchor(delta):
	_verlet_integration(delta)
	var root = physics_points[0]
	root[POSITION] = global_position
	physics_points[0] = root
	if anchor_target != null and is_instance_valid(anchor_target):
		physics_points[-1][POSITION] = anchor_target.get_node("%Origin").global_position
		var anchor = anchor_target.get_node("%Origin").global_position
		var root_pos = global_position
		var max_reach = segment_length * (physics_points.size() - 1)
		var max_stretch_reached = max_length_stretch * (physics_points.size() - 1)
		if keep_length:
			var to_anchor = anchor - root_pos
			var dir = to_anchor.normalized()
			physics_points[-1][POSITION] = root_pos + dir * current_segment_length
		else:
			var to_anchor = anchor - root_pos
			var distance_to_anchor = to_anchor.length()
			max_reach = segment_length * (physics_points.size() - 1)
			var stretch_factor = clamp(distance_to_anchor / max_reach, 1.0, max_length_stretch / segment_length)
			var stretched_segment_length = segment_length * stretch_factor
			stretch_seg = stretched_segment_length
			if to_anchor.length() > current_segment_length && max_length_stretch != 999999.0:
				var dir = Vector2.ZERO
				if distance_to_anchor > 0:
					dir = to_anchor.normalized()
				for i in range(physics_points.size()):
					physics_points[i][POSITION] = root_pos + dir * (stretched_segment_length * i)
			else:
				physics_points[-1][POSITION] = anchor
	apply_constraints_merged()
	
func apply_constraints_merged():
	if actor != null && is_instance_valid(actor):
		var min_angle = deg_to_rad(actor.get_value("follow_wa_mini"))
		var max_angle = deg_to_rad(actor.get_value("follow_wa_max"))
		var rest_dir = _rest_direction_angle
		if physics_points.size() < 1:
			return
		var root_pos = physics_points[0][POSITION]
		var anchor_pos = anchor_target.global_position
		for l in range(5):
			for i in range(physics_points.size() - 1):
				var p1 = physics_points[i]
				var p2 = physics_points[i + 1]
				var delta_vec = p2[POSITION] - p1[POSITION]
				var dist = delta_vec.length()
				var to_p2 = p2[POSITION] - root_pos
				if to_p2 == Vector2.ZERO:
					continue
				var seg_angle = to_p2.angle()
				var rel_angle = wrapf(seg_angle - rest_dir, -PI, PI)
				if mirror_anchor_movement_h:
					var to_anchor = anchor_pos - p2[POSITION]
					if to_anchor.length() > 0.25:
						var local_anchor = to_anchor.rotated(-rest_dir)
						local_anchor.x = abs(local_anchor.x)
						var anchor_angle = wrapf(local_anchor.angle(), -PI, PI)
						var norm = clamp(anchor_angle / max_angle, -1.0, 1.0)
						var mapped_angle = lerp(min_angle, max_angle, max((norm + 1.0) / 2.0, 0))
						rel_angle = (rel_angle + mapped_angle) * 0.5
					
				var clamped_angle = rel_angle
				var target_angle = rest_dir + clamped_angle
				var dir_vec = Vector2(cos(target_angle), sin(target_angle)).normalized()
				var new_pos = root_pos + dir_vec * to_p2.length()
				p2[POSITION] = new_pos
				if dist < current_segment_length:
					var correction = (delta_vec.normalized() * (current_segment_length - dist)) * 0.5
					if i != 0:
						p1[POSITION] -= correction
					if i + 1 != physics_points.size() - 1:
						p2[POSITION] += correction
				elif dist > segment_length:
					var correction = (delta_vec.normalized() * (dist - segment_length)) * 0.5
					if i != 0:
						p1[POSITION] += correction
					if i + 1 != physics_points.size() - 1:
						p2[POSITION] -= correction
				physics_points[i] = p1
				physics_points[i + 1] = p2


func reset(point_count: int = segment_count + 1) -> void:
	physics_points = []
	var starting_pos := get_global_position()
	
	var direction : Vector2 = Vector2.ZERO.rotated(_rest_direction_angle)
	current_dir = direction
	# Decide base position
	var root_pos := starting_pos
	if additional_start_segment:
		# Back-shift the root by the extra segment length
		root_pos -= direction * additional_start_segment_length

	# Segment length setup
	if anchor_target != null and is_instance_valid(anchor_target):
		var total_length = starting_pos.distance_to(anchor_target.global_position)
		current_segment_length = total_length / segment_count
	else:
		current_segment_length = segment_length

	# Create chain
	for i in range(point_count):
		var pos = root_pos + direction * current_segment_length * i
		var new_point := [
			null,
			pos,
			direction.angle(),
			0.0,
		]
		if i != 0:
			new_point[PREVIOUS_POINT] = physics_points[-1]
		physics_points.append(new_point)


## Returns the global positions of all points in the appendage
func get_global_point_positions() -> PackedVector2Array:
	var output := PackedVector2Array()
	for point in physics_points:
		output.append(point[POSITION])
	return output


func _process_point(point: Array, delta: float, index: int):
	var prev_point = point[PREVIOUS_POINT]

	var direction: Vector2 = prev_point[POSITION].direction_to(point[POSITION])
	var point_rotation: float = direction.angle()

	var ideal_rotation: float = prev_point[ROTATION] + _get_true_curvature() * pow(float(index), curvature_exponent)
	ideal_rotation = fmod(ideal_rotation, TAU)

	var rotation_diff: float = _angle_difference(ideal_rotation, point_rotation)
	var actual_stiffness = max(0, stiffness - pow(float(index), stiffness_decay_exponent) * stiffness_decay)

	var force: float = _signed_sqrt(rotation_diff) * actual_stiffness
	force += gravity.length() * cos(point_rotation - gravity.angle() + TAU / 4)

	if sign(force) != sign(point[ANGULAR_MOMENTUM]):
		force *= damping

	point[ANGULAR_MOMENTUM] += force * delta
	point[ANGULAR_MOMENTUM] = clamp(point[ANGULAR_MOMENTUM], -max_angular_momentum, max_angular_momentum)

	point_rotation += point[ANGULAR_MOMENTUM] * delta

	if abs(rotation_diff) > max_angle:
		point_rotation += rotation_diff - abs(max_angle) * sign(rotation_diff)
		if sign(point[ANGULAR_MOMENTUM]) != sign(rotation_diff) or abs(point[ANGULAR_MOMENTUM]) < comeback_speed:
			point[ANGULAR_MOMENTUM] = comeback_speed * sign(rotation_diff)

	# Optional stiff root segment behavior
	if stiff_root_segments and index < stiff_root_count:
		var t = 1.0 - float(index) / float(stiff_root_count)
		point_rotation = lerp_angle(point_rotation, prev_point[ROTATION], t)


	point[ROTATION] = point_rotation
	point[POSITION] = prev_point[POSITION] + Vector2(current_segment_length, 0).rotated(point_rotation)


func _process_root_point(point: Array, delta: float):
	var current_pos = get_global_position()
	smoothed_root_pos = smoothed_root_pos.lerp(current_pos, 1.0 - pow(1.0 - root_follow_smoothness, delta * 60.0))
	point[POSITION] = smoothed_root_pos
	prev_root_pos = current_pos

	if anchor_target != null and is_instance_valid(anchor_target):
		point[ROTATION] = 0.0
	else:
		point[ROTATION] = _rest_direction_angle + global_transform.get_rotation()


func _update_line():
	var new_line_points := PackedVector2Array()

	# base array from physics
	for point in physics_points:
		new_line_points.append(to_local(point[POSITION]))

	# insert a dynamic "extra start segment" before the root
	if additional_start_segment:
		if new_line_points.size() > 1:
			var dir := (new_line_points[1] - new_line_points[0]).normalized()
			var extra_point := new_line_points[0] - dir * additional_start_segment_length

			if subdivide_additional_start_segment:
				new_line_points.insert(0, extra_point)
			else:
				# just prepend after bezier
				points = _bezier_interpolate(new_line_points, subdivision)
				points.insert(0, extra_point)
				return

	# run bezier normally if no special-case insert happened above
	points = _bezier_interpolate(new_line_points, subdivision)


func _bezier_interpolate(line: PackedVector2Array, subdivision: int) -> PackedVector2Array:
	if subdivision < 1: return line
	if line.size() < 3: return line
	var output := PackedVector2Array()
	for i in range(line.size() - 1):
		var a: Vector2
		var b: Vector2
		var c: Vector2
		var actual_subdivisions: int
		a = line[i]
		b = line[i + 1]
		var c_index := i + 2
		if c_index > line.size() - 1:
			var before_a := line[i - 1]
			var angle := _angle_difference((b - a).angle(), (a - before_a).angle())
			c = b + (b - a).rotated(angle)
			actual_subdivisions = (subdivision) / 2 + 1
		else:
			c = line[c_index]
			actual_subdivisions = subdivision
		var true_a = lerp(a, b, 0.5) if i != 0 else a
		var true_c = lerp(b, c, 0.5)
		for o in range(actual_subdivisions):
			var t: float = 1.0 / subdivision * o
			var ab: Vector2 = lerp(true_a, b, t)
			var bc: Vector2 = lerp(b, true_c, t)
			output.append(lerp(ab, bc, t))
	return output


func _angle_difference(angle_a: float, angle_b: float) -> float:
	var diff := angle_a - angle_b
	if abs(diff) > TAU / 2.0:
		diff -= TAU * sign(diff)
	return diff


func _signed_sqrt(value: float) -> float:
	return sqrt(abs(value)) * sign(value)


func _get_true_segment_length() -> float:
	return segment_length * get_global_scale().x


func _get_true_curvature() -> float:
	var gt = get_global_transform()
	var det = gt.x.x * gt.y.y - gt.x.y * gt.y.x
	return curvature * sign(det)


func _set_segment_count(value: float):
	segment_count = value
	reset()
