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
@export var xFrq = 0.0
@export var xAmp = 0.0
@export var yFrq = 0.0
@export var yAmp = 0.0
#Rotational Drag
@export var rdragStr = 0
@export var rLimitMax = 180
@export var rLimitMin = -180
#Stretch
@export var stretchAmount = 0.0
var squish = 1
var texture 

# Misc
var treeitem : TreeItem
var blend_mode = "Normal"
var visb
var tick = 0
var sprite_name : String = ""
var open_mouth : bool = false
var should_blink : bool = false
var should_talk : bool = false
var open_eyes : bool
@export var states : Array = [{},{},{},{},{},{},{},{},{},{}]
var coord
var animation_speed = 1
var hframes = 1
var folder : bool = false
var dragging : bool = false
var of = Vector2(0,0)
var ignore_bounce : bool = false
var sprite_id : float
var parent_id : float = 0
var clip = 0
var physics : bool = true
var physics_effect = 1
var glob



# Called when the node enters the scene tree for the first time.
func _ready():
	Global.blink.connect(blink)
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	animation()

func animation():
	$Wobble/Squish/Drag/Sprite2D.hframes = hframes
	$Wobble/Squish/Drag/Sprite2D.vframes = 1
	if hframes > 1:
		coord = hframes -1
		if not coord <= 0:
			if $Wobble/Squish/Drag/Sprite2D.frame_coords.x == coord:
				$Wobble/Squish/Drag/Sprite2D.frame_coords.x = 0
				
			elif hframes > 1:
				$Wobble/Squish/Drag/Sprite2D.set_frame_coords(Vector2(clamp($Wobble/Squish/Drag/Sprite2D.frame_coords.x +1, 0,coord), 0))
				
	else:
		$Wobble/Squish/Drag/Sprite2D.set_frame_coords(Vector2(0, 0))
		
	$Animation.wait_time = animation_speed
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
	if not ignore_bounce:
		glob.y -= contain.bounceChange
	
	var length = (glob.y - dragger.global_position.y)
	
	if physics:
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
	wob.position.x = sin(tick*xFrq)*xAmp
	wob.position.y = sin(tick*yFrq)*yAmp

func rotationalDrag(length):
	var yvel = (length * rdragStr)
	
	#Calculate Max angle
	
	yvel = clamp(yvel,rLimitMin,rLimitMax)
	
	sprite.rotation = lerp_angle(sprite.rotation,deg_to_rad(yvel),0.25)

func stretch(length):
	var yvel = (length * stretchAmount * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	sprite.scale = lerp(sprite.scale,target,0.5)

func blink():
	if should_blink:
		if not open_eyes:
			show()
		else:
			hide()
	
	$Blink.wait_time = 0.2 * Global.blink_speed
	$Blink.start()
	await  $Blink.timeout
	if should_blink:
		if not open_eyes:
			hide()
		else:
			show()

func speaking():
	if should_talk:
		if open_mouth:
			show()
		else:
			hide()

func not_speaking():
	if should_talk:
		if open_mouth:
			hide()
		else:
			show()

func set_blend(value):
		match value:
			0:
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", false)
			1:
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/add.png"))
			2:
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/exclusion.png"))
			3:
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/multiply.png"))
			4:
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/burn.png"))
			5:
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/hardmix.png"))
			6:
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
				$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/test1.png"))

func save_state(id):
	var dict : Dictionary = {
		xFrq = xFrq,
		xAmp = xAmp,
		yFrq = yFrq,
		yAmp = yAmp,
		rdragStr = rdragStr,
		rLimitMax = rLimitMax,
		rLimitMin = rLimitMin,
		stretchAmount = stretchAmount,
		blend_mode = blend_mode,
		visible = visible,
		colored = modulate,
		z_index = z_index,
		open_eyes = open_eyes,
		open_mouth = open_mouth,
		should_blink = should_blink,
		should_talk = should_talk,
		animation_speed = animation_speed,
		hframes = hframes,
		scale = scale,
		folder = folder,
		global_position = global_position,
		offset = $Wobble/Squish/Drag/Sprite2D.offset,
		ignore_bounce = ignore_bounce,
		clip = clip,
		physics = physics
		
	}
	
	states[id] = dict

func get_state(id):
	if not states[id].is_empty():
		var dict = states[id]
		xFrq = dict.xFrq
		xAmp = dict.xAmp
		yFrq = dict.yFrq
		yAmp = dict.yAmp
		rdragStr = dict.rdragStr
		rLimitMax = dict.rLimitMax
		rLimitMin = dict.rLimitMin
		stretchAmount = dict.stretchAmount
		blend_mode = dict.blend_mode
		visible = dict.visible
		visb = dict.visible
		modulate = dict.colored
		z_index = dict.z_index
		
		open_eyes = dict.open_eyes
		open_mouth = dict.open_mouth
		should_blink = dict.should_blink
		should_talk = dict.should_talk
		
		animation_speed = dict.animation_speed
		hframes = dict.hframes
		scale = dict.scale
		folder = dict.folder
		global_position = dict.global_position
		$Wobble/Squish/Drag/Sprite2D.offset = dict.offset 
		$Wobble/Squish/Drag/Sprite2D/Origin.position = - dict.offset 
		ignore_bounce = dict.ignore_bounce
		physics = dict.physics
		get_node("Wobble/Squish/Drag/Sprite2D").set_clip_children_mode(dict.clip)
		speaking()
		not_speaking()
		animation()

func check_talk():
	if should_talk:
		if open_mouth:
			hide()
		else:
			show()


func _on_grab_button_down():
	if Global.held_sprite == self:
		of = get_global_mouse_position() - global_position
		dragging = true


func _on_grab_button_up():
	if Global.held_sprite == self:
		dragging = false


func reparent_obj(parent):
	for i in parent:
		if parent_id == 0:
			get_tree().get_root().get_node("Main/Control")._tree(get_tree().get_nodes_in_group("Sprites"))
			return
		if i.sprite_id == parent_id:
			reparent(i.get_node("Wobble/Squish/Drag/Sprite2D"))
	get_tree().get_root().get_node("Main/Control")._tree(get_tree().get_nodes_in_group("Sprites"))
	
