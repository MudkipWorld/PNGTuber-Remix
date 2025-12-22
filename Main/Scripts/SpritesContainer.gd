extends Node2D

signal reinfoanim
var mouth_closed = 0
var mouth_open = 0

var pos = Vector2(0,0)
var current_mc_anim = "Idle"
var current_mo_anim = "Idle"
var should_squish : bool = false
var squish_amount : float = 1.0
var bounce_state : bool = false
var dim_color : Color = Color.WHITE

var prev : int = 0

var state_parameters_default : Dictionary = {
	bounce_gravity = 575,
	bounce_energy = 250,
	xFrq = 0.3,
	xAmp = 5,
	yFrq = 0.4,
	yAmp = 5,
}

var default_model_effects : Dictionary = {
	color_blindness_effect = 0,
	effect_type = 0,
	effect_size = 1,
	effect_color = Color.WHITE,
}

var state_param_mc : Dictionary = state_parameters_default.duplicate()
var state_param_mo : Dictionary = state_parameters_default.duplicate()
var model_effects : Dictionary = default_model_effects.duplicate()

var tween : Tween

var bounce_amount = 50
var wave_amount = Vector2(100,100)

var yVel = 100
var bounceChange = 0.0

var currenly_speaking : bool = false
var tick = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.animation_state.connect(get_state)
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	Global.blink.connect(_squish)

func _squish():
	if should_squish:
		if tween:
			tween.kill()
		tween = create_tween()
		scale.y = 1.0 * (1/squish_amount)
		tween.tween_property(self, "scale:y", 1.0 * (squish_amount), 0.25).set_trans(Tween.TRANS_SINE)
		await tween.finished
		tween.kill()
		tween = create_tween()
		tween.tween_property(self, "scale:y", 1.0 , 0.1).set_trans(Tween.TRANS_SINE)
		await tween.finished
		tween.kill()

func _physics_process(delta: float) -> void:
	tick = Global.tick
	var hold = get_parent().position.y
	
	if !Global.static_view:
		get_parent().position.y = clamp(get_parent().position.y + (yVel * delta),-90000000, 0)
	else:
		get_parent().position.y = 0
	
	if get_parent().position.y < 16:
		bounceChange = hold - get_parent().position.y
#	get_parent().position.y = lerp(get_parent().position.y, 0.0, 0.05)
	
	if currenly_speaking:
		yVel = clamp(yVel + state_param_mo.bounce_gravity* delta,-90000000, 90000000)
	else:
		yVel = clamp(yVel + state_param_mc.bounce_gravity* delta,-90000000, 90000000)
	
	
	if !Global.static_view:
		if currenly_speaking:
			if current_mo_anim == "Bouncy":
				set_mo_bouncy()
				
			elif current_mo_anim == "Wobble":
				set_mo_wobble()
				
			elif current_mo_anim == "Squish":
				set_mo_squish()
			elif current_mo_anim == "Float":
				set_mo_float()
			else:
				position = lerp(position, pos, 0.05)
			if current_mo_anim != "Squish":
				scale = lerp(scale, Vector2(1.0,1.0), 0.08)
				
		elif not currenly_speaking:
			if current_mc_anim == "Bouncy":
				set_mc_bouncy()
			elif current_mc_anim == "Wobble":
				set_mc_wobble()
			elif current_mc_anim == "Squish":
				set_mc_squish()
			elif current_mc_anim == "Float":
				set_mc_float()
			else:
				position = lerp(position, pos, 0.05)
			
			if current_mc_anim != "Squish":
				scale = lerp(scale, Vector2(1.0,1.0), 0.08)
		else:
			position = pos
			scale = Vector2(1.0,1.0)


	if Global.settings_dict.darken && !currenly_speaking:
		modulate = lerp(modulate, dim_color, 0.08)
	else:
		modulate = Color.WHITE

func save_state(id):
	var dict = {
		mouth_closed = mouth_closed,
		mouth_open = mouth_open,
		current_mc_anim = current_mc_anim,
		current_mo_anim = current_mo_anim,
		should_squish = should_squish,
		squish_amount = squish_amount,
		bounce_state = bounce_state,
		state_param_mo = state_param_mo.duplicate(),
		state_param_mc = state_param_mc.duplicate(),
		model_effects = model_effects.duplicate(),
		dim_color = dim_color,
	}
	if id in range(Global.settings_dict.states.size()):
		Global.settings_dict.states[id] = dict
	
	if GlobalMicAudio.has_spoken:
		speaking()
	else:
		not_speaking()

func get_state(state):
	if !Global.settings_dict.states.is_empty():
		if not Global.settings_dict.states[state].is_empty():
			var dict : Dictionary = Global.settings_dict.states[state]
			mouth_closed = dict.mouth_closed
			mouth_open = dict.mouth_open
			current_mc_anim = dict.current_mc_anim
			current_mo_anim = dict.current_mo_anim
			dim_color = dict.get("dim_color", Global.settings_dict.dim_color)
			if dict.has("state_param_mo"):
				bounce_state = dict.bounce_state
				state_param_mo.merge(dict.state_param_mo, true)
				state_param_mc.merge(dict.state_param_mc, true)
				model_effects.merge(dict.model_effects, true)
				set_effects()
			
			if dict.has("squish_amount"):
				squish_amount = dict.squish_amount
				should_squish = dict.should_squish
			
			if bounce_state:
				if !Global.static_view:
					state_bounce()
				
			if GlobalMicAudio.has_spoken:
				speaking()
			else:
				not_speaking()
		
		reinfoanim.emit()

func not_speaking():
	currenly_speaking = false
	if !Global.static_view:
		match mouth_closed:
			0:
				set_mc_idle()
			1:
			#	position = pos
				set_mc_bouncy()
			3:
			#	position = pos
				set_mc_one_bounce()
			4:
				set_mc_wobble()
			5:
				set_mc_squish()

func speaking():
#	modulate = Color.WHITE
	currenly_speaking = true
	if !Global.static_view:
		match mouth_open:
			0:
				set_mo_idle()
			1:
			#	position = pos
				set_mo_bouncy()
			3:
			#	position = pos
				set_mo_one_bounce()
			4:
				set_mo_wobble()
				
			5:
				set_mo_squish()

func state_bounce():
	if get_parent().position.y > -16:
		yVel = ((state_param_mc.bounce_energy + state_param_mo.bounce_energy)/2) * -1

func set_mc_float():
	position.y = lerp(position.y, (sin(tick*state_param_mc.yFrq)*(state_param_mc.yAmp)), 0.08)
#	yVel = (position.y * 0.08)
	bounceChange = position.y /8

func set_mc_idle():
	pass

func set_mc_bouncy():
	if get_parent().position.y > -1:
		yVel = state_param_mc.bounce_energy * -1

func set_mc_one_bounce():
	if get_parent().position.y > -16:
		yVel = state_param_mo.bounce_energy * -1

func set_mc_wobble():
	position.x = lerp(position.x, sin(tick*state_param_mo.xFrq)*state_param_mo.xAmp, 0.08)
	position.y = lerp(position.y, sin(tick*state_param_mo.yFrq)*state_param_mo.yAmp, 0.08)
	bounceChange = position.y/10

func set_mc_squish():
	position.y = lerp(position.y,sin(tick*state_param_mc.yFrq)*state_param_mc.yAmp, 0.08)
	
	var yvel = (position.y * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)

	scale = lerp(scale,target,0.08)

func set_mo_float():
	position.y = lerp(position.y, (sin(tick*state_param_mo.yFrq)*(state_param_mo.yAmp)), 0.08)
#	yVel = (position.y * 0.08)
	bounceChange = position.y /8

func set_mo_idle():
	pass
#	position = pos

func set_mo_bouncy():
	if get_parent().position.y > -1:
		yVel = state_param_mo.bounce_energy * -1

func set_mo_one_bounce():
	if get_parent().position.y > -16:
		yVel = state_param_mo.bounce_energy * -1

func set_mo_wobble():
	position.x = lerp(position.x, sin(tick*state_param_mo.xFrq)*state_param_mo.xAmp, 0.08)
	position.y = lerp(position.y, sin(tick*state_param_mo.yFrq)*state_param_mo.yAmp, 0.08)
	bounceChange = position.y/10

func set_mo_squish():
	position.y = lerp(position.y,sin(tick*state_param_mo.yFrq)*state_param_mo.yAmp, 0.08)
	
	var yvel = (position.y * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)

	scale = lerp(scale,target,0.08)

func set_effects():
	if Global.viewer != null && is_instance_valid(Global.viewer):
		Global.viewport.material.set_shader_parameter("effect", model_effects.color_blindness_effect)
		Global.viewer.material.set_shader_parameter("effect", model_effects.effect_type)
		# outline, auro
		Global.viewer.material.set_shader_parameter("line_scale", model_effects.effect_size)
		Global.viewer.material.set_shader_parameter("line_color", model_effects.effect_color)
