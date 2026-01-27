extends Node

@export var actor : SpriteObject
@export var mesh : CustomMesh = null

@onready var modifier_node : Node2D = %Modifier
@onready var modifier1_node : Node2D = %Modifier1
@onready var sprite_node : Node2D = %Sprite2D
@onready var follow_component : Node = %FollowComponent

var parent_node : Node
var parent_movements : Node

var applied_pos : Vector2 = Vector2.ZERO
var applied_rotation : float = 0.0
var applied_scale : Vector2 = Vector2.ONE
var placeholder_position : Vector2 = Vector2.ZERO

var prev_smoothed_pos : Vector2 = Vector2.ZERO
var has_prev : bool = false

var rot_drag : float = 0.0
var follow_point_rot : float = 0.0
var biased : float = 0.0

var last_wobble_pos : Vector2 = Vector2.ZERO
var paused_wobble : Vector2 = Vector2.ZERO
var paused_rotation : float = 0.0
var last_rot : float = 0.0
var should_rot_rotation : float = 0.0

var rest : bool = false

var index_change_len : float = 0.0
var index_change_len_y : float = 0.0

var shadow_dragger : Vector2 = Vector2.ZERO
var glob : Vector2 = Vector2.ZERO

var rdrag_rad : float = 0.0
var shadow_target : Vector2 = Vector2.ZERO

var last_modifier_position : Vector2 = Vector2.ZERO

func _ready() -> void:
	placeholder_position = actor.global_position
	applied_pos = placeholder_position
	shadow_dragger = placeholder_position
	parent_node = get_parent()
	if parent_node and parent_node.has_node("%Movements"):
		parent_movements = parent_node.get_node("%Movements")
	rdrag_rad = deg_to_rad(actor.get_value("rdragStr"))
	await get_tree().create_timer(0.025).timeout
	last_modifier_position = sprite_node.global_position

func _physics_process(delta: float) -> void:
	if !actor.get_value("follow_wa_tip"):
		follow_point_rot = 0.0
	else:
		follow_wiggle(delta)
	placeholder_position = modifier1_node.global_position
	applied_pos =  placeholder_position
	
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
		modifier_node.position = Vector2(0,0)
		modifier_node.rotation = 0.0
		modifier_node.scale = Vector2(1,1)
		sprite_node.self_modulate = actor.get_value("tint")
	if not Global.static_view:
		var final_rot = applied_rotation + rot_drag + follow_point_rot + should_rot_rotation
		modifier_node.rotation = GlobalCalculations.is_nan_or_inf(final_rot)
		modifier1_node.global_position = GlobalCalculations.is_nan_or_inf(applied_pos)
	
	shadow_target = modifier_node.global_position + follow_component.target_pos
	var test = (shadow_target - actor.global_position).normalized()
	var signed_len_x = (test.x)
	var signed_len_y = (test.y)
	index_change_len = lerp(index_change_len, signed_len_x, 0.95)
	index_change_len_y = lerp(index_change_len_y, signed_len_y, 0.95)
	index_change_len = index_change_len * actor.get_value("index_change")
	index_change_len_y = index_change_len_y * actor.get_value("index_change_y")
	modifier_node.z_index = floori(index_change_len + index_change_len_y)
	
	
	if actor.sprite_type == "Mesh" and mesh != null && is_instance_valid(mesh):
		var can_deform : bool = false
		if is_instance_valid(Global.mesh_text_node):
			can_deform = Global.mesh_text_node.deform
		if !mesh.editable && !can_deform:
			var t : Vector2 = (last_modifier_position - sprite_node.global_position).snappedf(0.00001)
			var mesh_len = (last_wobble_pos + follow_component.target_pos )
			var amp = Vector2(actor.get_value("xAmp"), actor.get_value("yAmp"))
			var follow_amp = Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			var final_amp = amp  + follow_amp 
			if actor.get_value("physics"):
				mesh_len -=   t
				final_amp += Vector2(75,75)
				
			var safe_deform_pos
			if Tracker.working:
				safe_deform_pos = mesh.apply_wobble_to_deformer(mesh_len, delta, final_amp, 0.08)
			else:
				safe_deform_pos = mesh.apply_wobble_to_deformer(mesh_len, delta, final_amp, final_amp.normalized().length())
			if abs(safe_deform_pos.x) != 0:
				mesh.deform_x = safe_deform_pos.x
			if abs(safe_deform_pos.y) != 0:
				mesh.deform_y = safe_deform_pos.y
			
			mesh.call_deferred("update_physics", delta, false)
	
		last_modifier_position = last_modifier_position.move_toward(sprite_node.global_position, 30*delta).snappedf(0.00001)

func _process(_delta : float) -> void:
	if actor.get_value("static_obj"):
		actor.global_position = Global.sprite_container.get_parent().get_parent().to_global(actor.get_value("position"))

func static_prev() -> void:
	modifier_node.position = Vector2.ZERO
	modifier_node.rotation = 0.0
	modifier_node.scale = Vector2.ONE
	modifier1_node.position = Vector2.ZERO
	modifier1_node.rotation = 0.0
	modifier1_node.scale = Vector2.ONE
	sprite_node.self_modulate = actor.get_value("tint")
	modifier_node.z_index = 0

func movements(delta : float) -> void:
	glob = shadow_dragger
	wobble(delta)
	drag()
	if not actor.get_value("ignore_bounce"):
		glob -= Vector2(Global.sprite_container.bounceChange, Global.sprite_container.bounceChange)
	var l = Vector2(glob - shadow_dragger)
	var length : float = l.length() * (l.normalized().x - l.normalized().y)
	length = add_parent_physics(length)
	rotational_drag(length, delta)
	stretch(length)

func rest_mode_movements(delta : float) -> void:
	glob = shadow_dragger
	drag()
	if not actor.get_value("ignore_bounce"):
		glob -= Vector2(Global.sprite_container.bounceChange, Global.sprite_container.bounceChange)

	var length : float = (glob - shadow_dragger).x + (glob - shadow_dragger).y
	length = add_parent_physics(length)
	rotational_drag(length, delta)
	stretch(length)

func add_parent_physics(length : float) -> float:
	var leng = length
	if not actor.get_value("physics"):
		return leng
	var p = actor.get_parent()
	if (p is Sprite2D or p is WigglyAppendage2D or p is CustomMesh)  && is_instance_valid(p):
			var c_parent = actor.get_parent().owner
			if c_parent != null && is_instance_valid(c_parent):
				var c_len_y = c_parent.get_node("%Movements").glob.y - c_parent.get_node("%Movements").shadow_dragger.y
				var c_len_x = c_parent.get_node("%Movements").glob.x - c_parent.get_node("%Movements").shadow_dragger.x
				leng += c_len_y + c_len_x
	return leng

func drag():
	var drag_speed = actor.get_value("dragSpeed")
	var target = applied_pos
	if drag_speed > 0:
		
		var t = 1.0/drag_speed
		shadow_dragger = shadow_dragger.lerp(target, t)
		applied_pos = shadow_dragger
	else:
		shadow_dragger =  shadow_dragger.lerp(target, 0.85)

func wobble(delta : float) -> void:
	var use_delta : float = delta if Global.settings_dict.should_delta else 1.0

	if actor.get_value("pause_movement"):
		paused_wobble += Vector2.ONE * use_delta
	else:
		last_wobble_pos.x = sin((Global.tick - paused_wobble.x) * actor.get_value("xFrq")) * actor.get_value("xAmp")
		last_wobble_pos.y = sin((Global.tick - paused_wobble.y) * actor.get_value("yFrq")) * actor.get_value("yAmp")

	if actor.sprite_type != "Mesh" or actor.get_value("move_with_wobble"):
		applied_pos += last_wobble_pos

func rotational_drag(length, delta: float):
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
	
	var yvel = ((length * actor.get_value("rdragStr"))*0.5)

	yvel = clamp(yvel,actor.get_value("rLimitMin"),actor.get_value("rLimitMax"))
	
	applied_rotation = GlobalCalculations.is_nan_or_inf(lerp_angle(applied_rotation,deg_to_rad(yvel),0.15))

func stretch(length : float) -> void:
	var yvel : float = (length * actor.get_value("stretchAmount") * 0.01)*0.5
	var target : Vector2 = Vector2(1.0 - yvel, 1.0 + yvel)
	modifier1_node.scale = modifier1_node.scale.lerp(target, 0.15)

func follow_wiggle(_delta : float) -> void:
	var parent = actor.get_parent()
	if not parent or not (parent is WigglyAppendage2D):
		follow_point_rot = 0.0
		return

	var tip_index : int = clamp(actor.get_value("tip_point"), 0, parent.points.size() - 1)
	var raw_tip : Vector2 = parent.points[tip_index]
	var global_raw_tip : Vector2 = parent.to_global(raw_tip)

	if not has_prev:
		prev_smoothed_pos = global_raw_tip
		has_prev = true

	var d : float = prev_smoothed_pos.distance_to(global_raw_tip)
	var w : float = clamp(d * actor.get_value("follow_strength"), 0.0, 1.0)
	prev_smoothed_pos = prev_smoothed_pos.lerp(global_raw_tip, w)

	modifier1_node.global_position = prev_smoothed_pos.lerp(modifier1_node.global_position, actor.get_value("follow_strength"))

	var prev_point : Vector2 = raw_tip
	if tip_index > 0:
		prev_point = parent.points[tip_index - 1]

	var dir : Vector2 = raw_tip - prev_point
	if dir == Vector2.ZERO:
		dir = Vector2(cos(parent._rest_direction_angle), sin(parent._rest_direction_angle))

	var rest_angle : float = parent._rest_direction_angle
	var target_ang : float = rest_angle + wrapf(atan2(dir.y, dir.x) - rest_angle, -PI, PI)

	if abs(target_ang - biased) < actor.get_value("rotation_threshold"):
		return

	biased = lerp(biased, target_ang, actor.get_value("follow_strength"))
	follow_point_rot = GlobalCalculations.clamp_angle(
		biased,
		deg_to_rad(actor.get_value("follow_wa_mini")) + rest_angle,
		deg_to_rad(actor.get_value("follow_wa_max")) + rest_angle,
		rest_angle
	)

func rainbow(delta : float) -> void:
	if actor.get_value("hidden_item") and Global.mode != 0:
		sprite_node.self_modulate.a = 0.0
		return

	if actor.get_value("rainbow"):
		var h_speed : float = actor.get_value("rainbow_speed") * delta
		if actor.get_value("rainbow_self"):
			sprite_node.self_modulate.s = 1.0
			modifier_node.modulate.s = 0.0
			sprite_node.self_modulate.h = wrap(sprite_node.self_modulate.h + h_speed, 0.0, 1.0)
		else:
			sprite_node.self_modulate.s = 0.0
			modifier_node.modulate.s = 1.0
			modifier_node.modulate.h = wrap(modifier_node.modulate.h + h_speed, 0.0, 1.0)
	else:
		sprite_node.self_modulate = actor.get_value("tint")
		modifier_node.modulate.s = 0.0

func auto_rotate():
	should_rot_rotation += actor.get_value("should_rot_speed")

func actor_get_parent():
	return get_parent()

func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
