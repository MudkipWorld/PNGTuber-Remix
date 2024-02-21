extends Node2D

#Movement
var heldTicks = 0
var dragSpeed = 0
@onready var dragger = $Wobble/Squish/Drag
@onready var wob = $Wobble
@onready var sprite = $Wobble/Squish/Drag/Sprite2D
@onready var contain = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
@onready var img = $Wobble/Squish/Drag/Sprite2D.texture.get_image()
#Wobble
var squish = 1
var texture 

# Misc
var treeitem : TreeItem
var visb
var tick = 0
var sprite_name : String = ""
@export var states : Array = [{},{},{},{},{},{},{},{},{},{}]
var coord
var dragging : bool = false
var of = Vector2(0,0)

var sprite_id : float
var parent_id : float = 0
var physics_effect = 1
var glob

@onready var dictmain : Dictionary = {
	xFrq = 0,
	xAmp = 0,
	yFrq = 0,
	yAmp = 0,
	rdragStr = 0,
	rLimitMax = 100,
	rLimitMin = -100,
	stretchAmount = 0,
	blend_mode = "Normal",
	visible = visible,
	colored = modulate,
	z_index = z_index,
	open_eyes = true,
	open_mouth = false,
	should_blink = false,
	should_talk =  false,
	animation_speed = 1,
	hframes = 1,
	scale = scale,
	folder = false,
	global_position = global_position,
	offset = $Wobble/Squish/Drag/Sprite2D.offset,
	ignore_bounce = false,
	clip = 0,
	physics = true
	}


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.blink.connect(blink)
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	animation()

func animation():
	$Wobble/Squish/Drag/Sprite2D.hframes = dictmain.hframes
	$Wobble/Squish/Drag/Sprite2D.vframes = 1
	if dictmain.hframes > 1:
		coord = dictmain.hframes -1
		if not coord <= 0:
			if $Wobble/Squish/Drag/Sprite2D.frame_coords.x == coord:
				$Wobble/Squish/Drag/Sprite2D.frame_coords.x = 0
				
			elif dictmain.hframes > 1:
				$Wobble/Squish/Drag/Sprite2D.set_frame_coords(Vector2(clamp($Wobble/Squish/Drag/Sprite2D.frame_coords.x +1, 0,coord), 0))
				
	else:
		$Wobble/Squish/Drag/Sprite2D.set_frame_coords(Vector2(0, 0))
		
	$Animation.wait_time = dictmain.animation_speed
	$Animation.start()
	await $Animation.timeout
	animation()

func _process(delta):
	if Global.held_sprite == self:
		%Grab.mouse_filter = 1
	else:
		%Grab.mouse_filter = 2
	if dragging:
		global_position = get_global_mouse_position() - of
	
	
	tick += 1
	glob = dragger.global_position
	
	
	drag(delta)
	wobble()
	if not dictmain.ignore_bounce:
		glob.y -= contain.bounceChange
	
	var length = (glob.y - dragger.global_position.y)
	
	if dictmain.physics:
		if get_parent() is Sprite2D:
			var c_parent = get_parent().get_parent().get_parent().get_parent().get_parent()
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			length += c_parrent_length
	
	rotationalDrag(length)
	stretch(length)

func drag(delta):
	if dragSpeed == 0:
		dragger.global_position = wob.global_position
	else:
		dragger.global_position = lerp(dragger.global_position,wob.global_position,(delta*20)/dragSpeed)

func wobble():
	wob.position.x = sin(tick*dictmain.xFrq)*dictmain.xAmp
	wob.position.y = sin(tick*dictmain.yFrq)*dictmain.yAmp

func rotationalDrag(length):
	var yvel = (length * dictmain.rdragStr)
	
	#Calculate Max angle
	
	yvel = clamp(yvel,dictmain.rLimitMin,dictmain.rLimitMax)
	
	sprite.rotation = lerp_angle(sprite.rotation,deg_to_rad(yvel),0.25)

func stretch(length):
	var yvel = (length * dictmain.stretchAmount * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	sprite.scale = lerp(sprite.scale,target,0.5)

func blink():
	if dictmain.should_blink:
		if not dictmain.open_eyes:
			show()
		else:
			hide()
	
	$Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
	$Blink.start()
	await  $Blink.timeout
	if dictmain.should_blink:
		if not dictmain.open_eyes:
			hide()
		else:
			show()

func speaking():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			show()
		else:
			hide()

func not_speaking():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			hide()
		else:
			show()

func save_state(id):
	var dict : Dictionary = {
	xFrq = dictmain.xFrq,
	xAmp = dictmain.xAmp,
	yFrq = dictmain.yFrq,
	yAmp = dictmain.yAmp,
	rdragStr = dictmain.rdragStr,
	rLimitMax = dictmain.rLimitMax,
	rLimitMin = dictmain.rLimitMin,
	stretchAmount = dictmain.stretchAmount,
	blend_mode = dictmain.blend_mode,
	visible = visible,
	colored = modulate,
	z_index = z_index,
	open_eyes =  dictmain.open_eyes,
	open_mouth = dictmain.open_mouth,
	should_blink = dictmain.should_blink,
	should_talk =  dictmain.should_talk,
	animation_speed = dictmain.animation_speed ,
	hframes = dictmain.hframes,
	scale = scale,
	folder = dictmain.folder,
	global_position = global_position,
	offset = $Wobble/Squish/Drag/Sprite2D.offset,
	ignore_bounce = dictmain.ignore_bounce,
	clip = dictmain.clip,
	physics = dictmain.physics
	}
	states[id] = dict
	

func get_state(id):
	if not states[id].is_empty():
		var dict = states[id]
		dictmain.merge(dict, true)
		
		
		z_index = dictmain.z_index
		modulate = dictmain.colored
		visible = dictmain.visible
		scale = dictmain.scale
		$Wobble/Squish/Drag/Sprite2D.offset = dictmain.offset 
		$Wobble/Squish/Drag/Sprite2D/Origin.position = - dictmain.offset 
		get_node("Wobble/Squish/Drag/Sprite2D").set_clip_children_mode(dictmain.clip)
		
		speaking()
		not_speaking()
		animation()
		set_blend(dictmain.blend_mode)


func check_talk():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			hide()
		else:
			show()


func set_blend(blend):
	match  blend:
		"Normal":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", false)
		"Add":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/add.png"))
		"Subtract":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/exclusion.png"))
		"Multiply":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/multiply.png"))
		"Burn":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/burn.png"))
		"HardMix":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/hardmix.png"))
		"Cursed":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/test1.png"))


func _on_grab_button_down():
	if Global.held_sprite == self:
		of = get_global_mouse_position() - global_position
		dragging = true


func _on_grab_button_up():
	if Global.held_sprite == self:
		dragging = false


func reparent_obj(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			reparent(i.get_node("Wobble/Squish/Drag/Sprite2D"))

