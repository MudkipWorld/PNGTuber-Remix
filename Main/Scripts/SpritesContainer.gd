extends Node2D

signal reinfoanim
var mouth_closed = 0
var mouth_open = 0

var pos = Vector2(0,0)
var current_mc_anim = "Idle"
var current_mo_anim = "Idle"

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

func _process(delta):
	tick +=1
	var hold = get_parent().position.y
	
	get_parent().position.y += yVel * delta
	if get_parent().position.y > 0:
		get_parent().position.y = 0
	bounceChange = hold - get_parent().position.y
	
	yVel += Global.settings_dict.bounceGravity*delta
	
	
	if currenly_speaking:
		if current_mo_anim == "Bouncy":
			set_mo_bouncy()
			
		elif current_mo_anim == "Wobble":
			set_mo_wobble()
			
		elif current_mc_anim == "Squish":
			set_mo_squish()
	elif not currenly_speaking:
		if Global.settings_dict.darken:
			modulate = lerp(modulate, Global.settings_dict.dim_color, 0.08)
		else:
			modulate = Color.WHITE
		
		if current_mc_anim == "Bouncy":
			set_mc_bouncy()
		elif current_mc_anim == "Wobble":
			set_mc_wobble()
		elif current_mc_anim == "Squish":
			set_mc_squish()

func save_state(id):
	var dict = {
		mouth_closed = mouth_closed,
		mouth_open = mouth_open,
		current_mc_anim = current_mc_anim,
		current_mo_anim = current_mo_anim
	}
	Global.settings_dict.states[id] = dict
	
	if get_tree().get_root().get_node("Main/Control").has_spoken:
		speaking()
	else:
		not_speaking()

func get_state(state):
	if not Global.settings_dict.states[state].is_empty():
		var dict = Global.settings_dict.states[state]
		mouth_closed = dict.mouth_closed
		mouth_open = dict.mouth_open
		current_mc_anim = dict.current_mc_anim
		current_mo_anim = dict.current_mo_anim
		if Global.settings_dict.bounce_state:
			set_mc_one_bounce()
			
		if get_tree().get_root().get_node("Main/Control").has_spoken:
			speaking()
		else:
			not_speaking()
			
	reinfoanim.emit()
	

func not_speaking():
	currenly_speaking = false
	
	match mouth_closed:
		0:
			set_mc_idle()
		1:
			position = pos
			set_mc_bouncy()
		3:
			position = pos
			set_mc_one_bounce()
		4:
			set_mc_wobble()
		5:
			set_mc_squish()

func speaking():
	modulate = Color.WHITE
	currenly_speaking = true
	
	match mouth_open:
		0:
			set_mo_idle()
		1:
			position = pos
			set_mo_bouncy()
		3:
			position = pos
			set_mo_one_bounce()
		4:
			set_mo_wobble()
		5:
			set_mo_squish()

func set_mc_idle():
	position = pos

func set_mc_bouncy():
	if get_parent().position.y > -1:
		yVel = Global.settings_dict.bounceSlider * -1

func set_mc_one_bounce():
	if get_parent().position.y > -16:
		yVel = Global.settings_dict.bounceSlider * -1

func set_mc_wobble():
	position.x = sin(tick*Global.settings_dict.xFrq)*Global.settings_dict.xAmp
	position.y = sin(tick*Global.settings_dict.yFrq)*Global.settings_dict.yAmp
	

func set_mc_squish():
	position.y = sin(tick*Global.settings_dict.yFrq)*Global.settings_dict.yAmp
	
	var yvel = (position.y * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)

	scale = lerp(scale,target,0.5)




func set_mo_idle():
	position = pos

func set_mo_bouncy():
	if get_parent().position.y > -1:
		yVel = Global.settings_dict.bounceSlider * -1

func set_mo_one_bounce():
	if get_parent().position.y > -16:
		yVel = Global.settings_dict.bounceSlider * -1

func set_mo_wobble():
	position.x = sin(tick*Global.settings_dict.xFrq)*Global.settings_dict.xAmp
	position.y = sin(tick*Global.settings_dict.yFrq)*Global.settings_dict.yAmp
	


func set_mo_squish():
	position.y = sin(tick*Global.settings_dict.yFrq)*Global.settings_dict.yAmp
	var yvel = (position.y * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)

	scale = lerp(scale,target,0.5)



