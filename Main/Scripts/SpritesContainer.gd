extends Node2D

signal reinfoanim

@export var states : Array = [{},{},{},{},{},{},{},{},{},{}]
var mouth_closed = 0
var mouth_open = 0

var pos = Vector2(0,0)
var current_mc_anim = "Idle"
var current_mo_anim = "Idle"

var bounce_amount = 50
var wave_amount = Vector2(100,100)

var yVel = 100
var bounceGravity = 1000
var bounceChange = 0.0
var bounceSlider = 100

var currenly_speaking : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.animation_state.connect(get_state)
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)

func _process(delta):
	var hold = get_parent().position.y
	
	get_parent().position.y += yVel * delta
	if get_parent().position.y > 0:
		get_parent().position.y = 0
	bounceChange = hold - get_parent().position.y
	
	yVel += bounceGravity*delta
	
	
	if currenly_speaking:
		if current_mo_anim == "Bouncy":
			set_mo_bouncy()
	elif not currenly_speaking:
		if current_mc_anim == "Bouncy":
			set_mc_bouncy()

func save_state(id):
	var dict = {
		mouth_closed = mouth_closed,
		mouth_open = mouth_open,
		current_mc_anim = current_mc_anim,
		current_mo_anim = current_mo_anim
	}
	states[id] = dict
	
	if get_tree().get_root().get_node("Main/Control").has_spoken:
		speaking()
	else:
		not_speaking()

func get_state(state):
	if not states[state].is_empty():
		var dict = states[state]
		mouth_closed = dict.mouth_closed
		mouth_open = dict.mouth_open
		current_mc_anim = dict.current_mc_anim
		current_mo_anim = dict.current_mo_anim
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
			set_mc_bouncy()
		3:
			set_mc_one_bounce()

func speaking():
	currenly_speaking = true
	match mouth_open:
		0:
			set_mo_idle()
		1:
			set_mo_bouncy()
		3:
			set_mo_one_bounce()

func set_mc_idle():
	pass

func set_mc_bouncy():
	if get_parent().position.y > -16:
		yVel = bounceSlider * -1

func set_mc_one_bounce():
	if get_parent().position.y > -16:
		yVel = bounceSlider * -1

func set_mo_idle():
	pass

func set_mo_bouncy():
	if get_parent().position.y > -16:
		yVel = bounceSlider * -1

func set_mo_one_bounce():
	if get_parent().position.y > -16:
		yVel = bounceSlider * -1
