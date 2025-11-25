extends Node

@export var actor: SpriteObject

# --- Cached Nodes ---
var modifier_node: Node2D
var sprite_node: Node

var parent_node: Node
var parent_movements: Node

# --- State ---
var applied_pos: Vector2 = Vector2.ZERO
var applied_rotation: float = 0.0
var applied_scale: Vector2 = Vector2.ONE
var placeholder_position: Vector2 = Vector2.ZERO
var prev_smoothed_pos: Vector2 = Vector2.ZERO
var has_prev: bool = false
var rot_drag: float = 0.0
var follow_point_rot: float = 0.0
var biased: float = 0.0
var strength: float = 0.0
var _b: float = 0.0
var dragger_global: Vector2 = Vector2.ZERO
var last_wobble_pos: Vector2 = Vector2.ZERO
var paused_wobble: Vector2 = Vector2.ZERO
var paused_rotation: float = 0.0
var last_rot: float = 0.0
var should_rot_rotation: float = 0.0
var rest: bool = false


var glob: Vector2 = Vector2.ZERO
# --- Cached constants ---
var rdrag_rad: float = 0.0

func _ready() -> void:
	modifier_node = %Modifier
	sprite_node =  %Sprite2D

	placeholder_position = actor.global_position
	dragger_global = placeholder_position
	applied_pos = placeholder_position
	applied_rotation = 0.0
	applied_scale = Vector2.ONE

	modifier_node.rotation = 0.0
	modifier_node.scale = Vector2.ONE

	parent_node = actor_get_parent()
	if parent_node and parent_node.has_node("%Movements"):
		parent_movements = parent_node.get_node("%Movements")

	rdrag_rad = deg_to_rad(actor.get_value("rdragStr"))

func _physics_process(delta: float) -> void:
	follow_wiggle(delta)
	placeholder_position = %Modifier1.global_position
	applied_pos = %Modifier1.global_position
	applied_rotation = 0.0
	applied_scale = Vector2.ONE
	
	if !Global.static_view and actor.rest_mode != 5:
		if (actor.rest_mode == 2 or actor.rest_mode == 3) and rest:
			rest_mode_movements(delta)
		else:
			if actor.get_value("should_rotate"):
				auto_rotate()
			else:
				should_rot_rotation = 0.0
			rainbow(delta)
			movements(delta)
	elif Global.static_view:
		static_prev()
	else:
		%Modifier.position = Vector2(0,0)
		%Modifier.rotation = 0.0
		%Modifier.scale = Vector2(1,1)
		%Sprite2D.self_modulate = actor.get_value("tint")

	

	if not Global.static_view:
		var final_rot = applied_rotation + rot_drag + follow_point_rot + should_rot_rotation
		modifier_node.rotation = GlobalCalculations.is_nan_or_inf(final_rot)
		modifier_node.global_position = GlobalCalculations.is_nan_or_inf(applied_pos)

func static_prev():
	%Modifier.position = Vector2(0,0)
	%Modifier.rotation = 0.0
	%Modifier.scale = Vector2(1,1)
	%Sprite2D.self_modulate = actor.get_value("tint")
	%Modifier1.position = Vector2.ZERO
	%Modifier1.rotation = 0.0
	%Modifier1.scale = Vector2(1,1)
	dragger_global = %Modifier.global_position

func movements(delta):
	if Global.static_view:
		return

	drag(delta)
	wobble(delta)

	glob = dragger_global + last_wobble_pos
	if !actor.get_value("ignore_bounce"):
		glob -= Vector2(Global.sprite_container.bounceChange, Global.sprite_container.bounceChange)

	var length = (glob.x - dragger_global.x) + (glob.y - dragger_global.y)

	if actor.get_value("physics") and parent_movements:
		var c_len_y = parent_movements.glob.y - parent_node.get_node("%Modifier1").global_position.y
		var c_len_x = parent_movements.glob.x - parent_node.get_node("%Modifier1").global_position.x
		length += c_len_y + c_len_x

	rotationalDrag(length, delta)
	stretch(length, delta)

func rest_mode_movements(delta):
	if Global.static_view:
		return
	drag(delta)
	glob = dragger_global + last_wobble_pos
	if !actor.get_value("ignore_bounce"):
		glob -= Vector2(Global.sprite_container.bounceChange, Global.sprite_container.bounceChange)
	var length = (glob.x - dragger_global.x) + (glob.y - dragger_global.y)
	if actor.get_value("physics") and parent_movements:
		var c_len_y = parent_movements.glob.y - parent_node.get_node("%Modifier1").global_position.y
		var c_len_x = parent_movements.glob.x - parent_node.get_node("%Modifier1").global_position.x
		length += c_len_y + c_len_x
	rotationalDrag(length, delta)
	stretch(length, delta)

func drag(_delta):
	var target = placeholder_position
	if parent_node and (parent_node is Sprite2D or parent_node is WigglyAppendage2D):
		target += parent_node.applied_pos

	if actor.get_value("dragSpeed") == 0:
		dragger_global = modifier_node.global_position
	else:
		var t = 1.0 / max(actor.get_value("dragSpeed"), 1.0)
		dragger_global = dragger_global.lerp(target, t)
		applied_pos += dragger_global - placeholder_position

func wobble(_delta: float) -> void:
	if actor.get_value("pause_movement"):
		last_wobble_pos = Vector2.ZERO
	else:
		var tick = Global.tick
		last_wobble_pos.x = sin((tick - paused_wobble.x) * actor.get_value("xFrq")) * actor.get_value("xAmp")
		last_wobble_pos.y = sin((tick - paused_wobble.y) * actor.get_value("yFrq")) * actor.get_value("yAmp")
	applied_pos += last_wobble_pos

func rotationalDrag(length, delta: float):
	if actor.is_default("rot_frq"):
		if actor.get_value("pause_movement"):
			if actor.is_all_default("rot_frq"):
				last_rot = 0
			else:
				paused_rotation += delta if Global.settings_dict.should_delta else 1.
		else:
			last_rot = sin((Global.tick-paused_rotation) * actor.get_value("rot_frq"))
			last_rot *= deg_to_rad(actor.get_value("rdragStr"))
	else:
		last_rot = sin((Global.tick-paused_rotation) * actor.get_value("rot_frq"))
		last_rot *= deg_to_rad(actor.get_value("rdragStr"))
	
	applied_rotation = lerp_angle(applied_rotation, last_rot, 0.15)
	
	var yvel = ((length * actor.get_value("rdragStr"))* 0.5)
	
	
	yvel = clamp(yvel,actor.get_value("rLimitMin"),actor.get_value("rLimitMax"))
	
	applied_rotation = lerp_angle(applied_rotation,deg_to_rad(yvel),0.15)

func stretch(length, delta):
	var yvel = length * actor.get_value("stretchAmount") * 0.01
	var target = Vector2(1.0 - yvel, 1.0 + yvel)
	modifier_node.scale = lerp(modifier_node.scale, target, delta* 0.15)

var points_cache: Array = []
var points_dirty: bool = true

func follow_wiggle(delta):
	if not actor.get_value("follow_wa_tip"):
		follow_point_rot = 0.0
		return
	var parent = actor.get_parent()
	if not is_instance_valid(parent) or not (parent is WigglyAppendage2D):
		follow_point_rot = 0.0
		return
	var tip_index = clamp(actor.get_value("tip_point"), 0, parent.points.size() - 1)
	var raw_tip = parent.points[tip_index]
	var global_raw_tip = parent.to_global(parent.points[tip_index])
	var speed_strength = actor.get_value("follow_strength")
	if not has_prev:
		prev_smoothed_pos = global_raw_tip
		has_prev = true
	var d = prev_smoothed_pos.distance_to(global_raw_tip)
	var w = clamp(d * speed_strength, 0.0, 1.0)
	var smoothed = prev_smoothed_pos.lerp(global_raw_tip, w)
	prev_smoothed_pos = smoothed
	var parent_pos = %Modifier1.global_position
	var final_pos = smoothed.lerp(parent_pos, actor.get_value("follow_strength"))
	%Modifier1.global_position = final_pos
	
	var prev_point_pos
	if tip_index > 0:
		prev_point_pos = parent.points[tip_index - 1]
	else:
		prev_point_pos = raw_tip - Vector2(cos(parent._rest_direction_angle), sin(parent._rest_direction_angle))
	var dir = raw_tip - prev_point_pos
	if dir == Vector2.ZERO:
		dir = Vector2(cos(parent._rest_direction_angle), sin(parent._rest_direction_angle))
	var dir_angle = atan2(dir.y, dir.x)
	var rest_angle = parent._rest_direction_angle
	var min_angle = deg_to_rad(actor.get_value("follow_wa_mini")) + rest_angle
	var max_angle = deg_to_rad(actor.get_value("follow_wa_max")) + rest_angle
	var rel_angle = wrapf(dir_angle - rest_angle, -PI, PI)
	var target_ang = rest_angle + rel_angle

	if abs(target_ang - biased) < actor.get_value("rotation_threshold"):
		return

	_b = target_ang
	biased = lerp(biased, _b, actor.get_value("follow_strength"))
	follow_point_rot = GlobalCalculations.clamp_angle(biased, min_angle, max_angle, rest_angle)




func rainbow(delta):
	if actor.get_value("hidden_item") and Global.mode != 0:
		sprite_node.self_modulate.a = 0.0
		return

	if actor.get_value("rainbow"):
		var h_speed = actor.get_value("rainbow_speed") * delta
		if not actor.get_value("rainbow_self"):
			sprite_node.self_modulate.s = 0
			modifier_node.modulate.s = 1
			modifier_node.modulate.h = wrap(modifier_node.modulate.h + h_speed, 0, 1)
		else:
			modifier_node.modulate.s = 0
			sprite_node.self_modulate.s = 1
			sprite_node.self_modulate.h = wrap(sprite_node.self_modulate.h + h_speed, 0, 1)
	else:
		sprite_node.self_modulate = actor.get_value("tint")
		modifier_node.modulate.s = 0

func auto_rotate():
	should_rot_rotation += actor.get_value("should_rot_speed")

func actor_get_parent():
	return get_parent()

func _frame_lerp(delta: float, base_t := 0.15) -> float:
	var fps = max(30.0, Engine.max_fps)
	var per_second_k = -log(1.0 - clamp(base_t, 0.001, 0.999)) * fps
	return clamp(1.0 - exp(-per_second_k * clamp(delta, 0.0, 1.0)), 0.0, 1.0)

func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
