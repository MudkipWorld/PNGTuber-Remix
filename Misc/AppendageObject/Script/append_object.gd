extends Node2D

#Movement
var heldTicks = 0
var dragSpeed = 0
@onready var dragger = $Pos/Wobble/Squish/Drag
@onready var wob = $Pos/Wobble
@onready var sprite = $Pos/Wobble/Squish/Drag/Rotation/Sprite2D
@onready var contain = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
@onready var img = $Pos/Wobble/Squish/Drag/Rotation/Sprite2D.texture.get_image()
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

var sprite_type : String = "WiggleApp"

var anim_texture 
var anim_texture_normal 
var img_animated : bool = false

@onready var dictmain : Dictionary = {
	xFrq = 0,
	xAmp = 0,
	yFrq = 0,
	yAmp = 0,
	
	rdragStr = 0,
	rLimitMax = 180,
	rLimitMin = -180,
	
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
	position = position,
	rotation = rotation,
#	offset = $Pos/Wobble/Squish/Drag/Rotation/Sprite2D.offset,
	ignore_bounce = false,
	clip = 0,
	physics = true,
	
#	wiggle = false,
#	wiggle_amp = 0,
#	wiggle_freq = 0,
#	wiggle_physics = false
	wiggle_segm = 5,
	wiggle_curve = 0,
	wiggle_stiff = 20,
	wiggle_max_angle = 30,
	wiggle_physics_stiffness = 2.5,

	advanced_lipsync = false,
	
	look_at_mouse_pos = 0,
	look_at_mouse_pos_y = 0,
	
	
	should_rotate = false,
	should_rot_speed = 0.001,
	
	width = 80,
	segm_length = 30,
	subdivision = 5,
	
	should_reset = false,
	one_shot = false,
	
	rainbow = false,
	rainbow_self = false,
	rainbow_speed = 0.01,
	
	follow_wa_tip = false,
	}

var smooth_rot = 0.0
var smooth_glob = Vector2(0.0,0.0)
var is_apng : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.blink.connect(blink)
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)


func _process(delta):
	if Global.held_sprite == self:
		%Grab.mouse_filter = 1
		%Grab.show()
	else:
		%Grab.mouse_filter = 2
		%Grab.hide()
	if dragging:
		global_position = get_global_mouse_position() - of
		smooth_glob = get_global_mouse_position() - of
		get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()
	
	
	tick += 1
	glob = dragger.global_position
	
	
	drag(delta)
	wobble()
	if not dictmain.ignore_bounce:
		glob.y -= contain.bounceChange
	
	var length = (glob.y - dragger.global_position.y)/dictmain.wiggle_physics_stiffness
	
	if dictmain.physics:
		if get_parent() is Sprite2D or get_parent() is WigglyAppendage2D or get_parent() is CanvasGroup:
			var c_parent = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			length += (c_parrent_length/dictmain.wiggle_physics_stiffness)
	
	rotationalDrag(length)
	stretch(length)
	
	follow_mouse()
	
	if dictmain.should_rotate:
		auto_rotate()
		
	rainbow()
	follow_wiggle()
	
	%Grab.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT


func follow_wiggle():
	if dictmain.follow_wa_tip:
		if get_parent() is WigglyAppendage2D:
			position = get_parent().points[get_parent().points.size() -1]
			%Pos.rotation = (get_parent().points[get_parent().points.size() -1].y/100)
		else:
			%Pos.rotation = 0
		
	else:
		%Pos.rotation = 0

func rainbow():
	if dictmain.rainbow:
		if not dictmain.rainbow_self:
			%Sprite2D.self_modulate.s = 0
			%Pos.modulate.s = 1
			%Pos.modulate.h = wrap(%Pos.modulate.h + dictmain.rainbow_speed, 0, 1)
		else:
			%Pos.modulate.s = 0
			%Sprite2D.self_modulate.s = 1
			%Sprite2D.self_modulate.h = wrap(%Sprite2D.self_modulate.h + dictmain.rainbow_speed, 0, 1)
	else:
		%Sprite2D.self_modulate.s = 0
		%Pos.modulate.s = 0


func follow_mouse():
	if dictmain.look_at_mouse_pos == 0:
		%Pos.position.x = 0
	if dictmain.look_at_mouse_pos_y == 0:
		%Pos.position.y = 0
	
	var mouse = get_local_mouse_position()
	var dir = Vector2.ZERO.direction_to(mouse)
	var dist = mouse.length()
	%Pos.position.x = dir.x * mini(dist, dictmain.look_at_mouse_pos)
	%Pos.position.y = dir.y * mini(dist, dictmain.look_at_mouse_pos_y)


func auto_rotate():
	%Rotation.rotation = wrap(%Rotation.rotation + dictmain.should_rot_speed, 0, 360)


func wiggle_sprite():
	var wiggle_val = sin(tick*dictmain.wiggle_freq)*dictmain.wiggle_amp
	if dictmain.wiggle_physics:
		if get_parent() is Sprite2D or get_parent() is WigglyAppendage2D:
			var c_parent = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			wiggle_val = wiggle_val + (c_parrent_length/10)
		
		
	$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("rotation", wiggle_val )

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
	
	%Rotation.rotation = lerp_angle(%Rotation.rotation,deg_to_rad(yvel),0.25)

func stretch(length):
	var yvel = (length * dictmain.stretchAmount * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	sprite.scale = lerp(sprite.scale,target,0.5)

func blink():
	if dictmain.should_blink:
		if not dictmain.open_eyes:
			%Pos.show()
		else:
			%Pos.hide()
	
	$Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
	$Blink.start()
	await  $Blink.timeout
	if dictmain.should_blink:
		if not dictmain.open_eyes:
			%Pos.hide()
		else:
			%Pos.show()

func speaking():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			%Rotation.show()
		else:
			%Rotation.hide()

func not_speaking():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			%Rotation.hide()
		else:
			%Rotation.show()

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
	colored = dictmain.colored,
	z_index = z_index,
	open_eyes =  dictmain.open_eyes,
	open_mouth = dictmain.open_mouth,
	should_blink = dictmain.should_blink,
	should_talk =  dictmain.should_talk,
	animation_speed = dictmain.animation_speed ,
	hframes = dictmain.hframes,
	scale = scale,
	folder = dictmain.folder,
	global_position = dictmain.global_position,
	position = dictmain.position,
	rotation = rotation,
#	offset = $Pos/Wobble/Squish/Drag/Rotation/Sprite2D.offset,
	ignore_bounce = dictmain.ignore_bounce,
	clip = dictmain.clip,
	physics = dictmain.physics,
	wiggle_segm = get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").segment_count,
	wiggle_curve = get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").curvature,
	wiggle_stiff = get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").stiffness,
	wiggle_max_angle = get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").max_angle,
	wiggle_physics_stiffness = dictmain.wiggle_physics_stiffness,
	advanced_lipsync = dictmain.advanced_lipsync,
	
	look_at_mouse_pos = dictmain.look_at_mouse_pos,
	look_at_mouse_pos_y = dictmain.look_at_mouse_pos_y,
	width = dictmain.width,
	segm_length = dictmain.segm_length,
	subdivision = dictmain.subdivision,
	
	
	should_rotate = dictmain.should_rotate,
	should_rot_speed = dictmain.should_rot_speed,
	should_reset = dictmain.should_reset,
	one_shot = dictmain.one_shot,
	
	rainbow = dictmain.rainbow,
	rainbow_self = dictmain.rainbow_self,
	rainbow_speed = dictmain.rainbow_speed,
	
	follow_wa_tip = dictmain.follow_wa_tip,
	}
	states[id] = dict


func get_state(id):
	if not states[id].is_empty():
		var dict = states[id]
		dictmain.merge(dict, true)
		
		if img_animated && dictmain.should_reset:
			%Sprite2D.texture.diffuse_texture.current_frame = 0
			if %Sprite2D.texture.normal_texture != null:
				%Sprite2D.texture.normal_texture.current_frame = 0
				
			if img_animated:
				%Sprite2D.texture.diffuse_texture.one_shot = dictmain.one_shot
				if %Sprite2D.texture.normal_texture != null:
					%Sprite2D.texture.normal_texture.one_shot = dictmain.one_shot
		
		z_index = dictmain.z_index
		modulate = dictmain.colored
		visible = dictmain.visible
		scale = dictmain.scale
		global_position = dictmain.global_position
		position = dictmain.position
		
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").segment_count = dictmain.wiggle_segm
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").curvature = dictmain.wiggle_curve
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").stiffness = dictmain.wiggle_stiff
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").max_angle = dictmain.wiggle_max_angle
		
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").width = dictmain.width
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").segment_length = dictmain.segm_length
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").subdivision = dictmain.subdivision
		
#		$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.offset = dictmain.offset 
#		$Pos/Wobble/Squish/Drag/Rotation/Sprite2D/Origin.position = - dictmain.offset 
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").set_clip_children_mode(dictmain.clip)
		rotation = dictmain.rotation
#		$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("wiggle", dictmain.wiggle)
		
		if dictmain.should_blink:
			if dictmain.open_eyes:
				
				%Pos.show()
			else:
				%Pos.hide()
		speaking()
		not_speaking()
#		animation()
		set_blend(dictmain.blend_mode)


func check_talk():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			%Rotation.hide()
		else:
			%Rotation.show()


func set_blend(blend):
	match  blend:
		"Normal":
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("enabled", false)
		"Add":
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/add.png"))
		"Subtract":
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/exclusion.png"))
		"Multiply":
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/multiply.png"))
		"Burn":
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/burn.png"))
		"HardMix":
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/hardmix.png"))
		"Cursed":
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/test1.png"))


func _on_grab_button_down():
	if Global.held_sprite == self:
		of = get_global_mouse_position() - global_position
		dragging = true


func _on_grab_button_up():
	if Global.held_sprite == self:
		dragging = false
		save_state(Global.current_state)


func reparent_obj(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			reparent(i.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D"))

