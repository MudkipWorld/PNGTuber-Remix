extends Node2D

#Movement
var heldTicks = 0
var dragSpeed = 0
@onready var dragger = $Pos/Wobble/Squish/Drag
@onready var wob = $Pos/Wobble
@onready var sprite = $Pos/Wobble/Squish/Drag/Sprite2D
@onready var contain = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
@onready var img = $Pos/Wobble/Squish/Drag/Sprite2D.texture.get_image()
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
var sprite_type : String = "Sprite2D"
var currently_speaking : bool = false

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
	rotation = rotation,
	offset = $Pos/Wobble/Squish/Drag/Sprite2D.offset,
	ignore_bounce = false,
	clip = 0,
	physics = true,
	
	wiggle = false,
	wiggle_amp = 0,
	wiggle_freq = 0,
	wiggle_physics = false,
	
	advanced_lipsync = false,
	
	look_at_mouse_pos = 0,
	look_at_mouse_pos_y = 0,
	}
var smooth_rot = 0.0
var smooth_glob = Vector2(0.0,0.0)



# Called when the node enters the scene tree for the first time.
func _ready():
	Global.blink.connect(blink)
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	animation()
#	print(get_node("Pos/Wobble/Squish/Drag/Sprite2D/Grab").pivot_offset)
	
	

func animation():
	if not dictmain.advanced_lipsync:
		$Pos/Wobble/Squish/Drag/Sprite2D.hframes = dictmain.hframes
		$Pos/Wobble/Squish/Drag/Sprite2D.vframes = 1
		if dictmain.hframes > 1:
			coord = dictmain.hframes -1
			if not coord <= 0:
				if $Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x == coord:
					$Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x = 0
					
				elif dictmain.hframes > 1:
					$Pos/Wobble/Squish/Drag/Sprite2D.set_frame_coords(Vector2(clamp($Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x +1, 0,coord), 0))
					
		else:
			$Pos/Wobble/Squish/Drag/Sprite2D.set_frame_coords(Vector2(0, 0))
		
	$Animation.wait_time = dictmain.animation_speed
	$Animation.start()
	await $Animation.timeout
	animation()

func _process(delta):
	follow_mouse()
	if Global.held_sprite == self:
		%Grab.mouse_filter = 1
	else:
		%Grab.mouse_filter = 2
	if dragging:
		global_position = get_global_mouse_position() - of
		dictmain.global_position = get_global_mouse_position() - of
		smooth_glob = get_global_mouse_position() - of
		get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()
	
	
	tick += 1
	glob = dragger.global_position
	
	
	drag(delta)
	wobble()
	if not dictmain.ignore_bounce:
		glob.y -= contain.bounceChange
	
	var length = (glob.y - dragger.global_position.y)
	
	if dictmain.physics:
		if get_parent() is Sprite2D:
			var c_parent = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			length += c_parrent_length
	
	rotationalDrag(length)
	stretch(length)
	
	if dictmain.wiggle:
		wiggle_sprite()
		
	

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



func wiggle_sprite():
	var wiggle_val = sin(tick*dictmain.wiggle_freq)*dictmain.wiggle_amp
	if dictmain.wiggle_physics:
		if get_parent() is Sprite2D or get_parent() is WigglyAppendage2D:
			var c_parent = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			wiggle_val = wiggle_val + (c_parrent_length/10)
		
		
	$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("rotation", wiggle_val )

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
			coord = 0
			animation()
			
		else:
			hide()
	currently_speaking = true
	

func advanced_lipsyc():
	if dictmain.advanced_lipsync:
		if $Pos/Wobble/Squish/Drag/Sprite2D.hframes != 6:
			$Pos/Wobble/Squish/Drag/Sprite2D.hframes = 6
		$Talk.start()
	#	var vol_lim_array = [Global.settings_dict.volume_limit, Global.settings_dict.volume_limit, Global.settings_dict.volume_limit, Global.settings_dict.volume_limit]
		var t1 = [21.8125849517025, 0, 0, 0]
		var t2 = [28.79458014297, 5.76142491051318, 0, 0]
		
		var t3 = [1.94345997247315, 16.6082798477067, 20.2565333927231, 0]
		var t4 = [3.01663259741776, 17.0816552167815, 18.6912089735756, 0]
		# 
		var t5 = [15.9207278487366, 0, 0, 0]
		var t6 = [19.8393356272706, 0.94239520235854, 0, 0]
		
		var t7 = [19.8393356272706, 0.94239520235854, 0, 0]
		var t8 = [21.8125849517025, 0, 0, 0]
		
		var t9 = [3.01663259741776, 17.0816552167815, 18.6912089735756, 0]
		var t10 = [15.9207278487366, 0, 0, 0]
		
		if currently_speaking:
			if GlobalAudioStreamPlayer.used_bar > t1 && GlobalAudioStreamPlayer.used_bar < t2:
		#		print("a")
				$Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x = 1
				

			elif GlobalAudioStreamPlayer.used_bar > t3 && GlobalAudioStreamPlayer.used_bar < t4:
		#		print("s")
				$Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x = 2
				

			elif GlobalAudioStreamPlayer.used_bar > t5 && GlobalAudioStreamPlayer.used_bar < t6:
			#	print("o")
				$Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x = 3
				

				
			elif GlobalAudioStreamPlayer.used_bar > t9 && GlobalAudioStreamPlayer.used_bar < t10:
			#	print("e")
				$Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x = 4
				
			elif GlobalAudioStreamPlayer.used_bar > t7 && GlobalAudioStreamPlayer.used_bar < t8:
			#	print("h")
				$Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x = 5
			
	
		else:
			$Pos/Wobble/Squish/Drag/Sprite2D.frame_coords.x = 0
			
		
		await $Talk.timeout
		advanced_lipsyc()



func not_speaking():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			hide()
		else:
			show()
			coord = 0
			animation()
	currently_speaking = false


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
	global_position = dictmain.global_position,
	rotation = rotation,
	offset = $Pos/Wobble/Squish/Drag/Sprite2D.offset,
	ignore_bounce = dictmain.ignore_bounce,
	clip = dictmain.clip,
	physics = dictmain.physics,
	wiggle = dictmain.wiggle,
	wiggle_amp = dictmain.wiggle_amp,
	wiggle_freq = dictmain.wiggle_freq,
	wiggle_physics = dictmain.wiggle_physics,
	advanced_lipsync = dictmain.advanced_lipsync,
	
	look_at_mouse_pos = dictmain.look_at_mouse_pos,
	look_at_mouse_pos_y = dictmain.look_at_mouse_pos_y,
	
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
		global_position = dictmain.global_position
		$Pos/Wobble/Squish/Drag/Sprite2D.offset = dictmain.offset 
		$Pos/Wobble/Squish/Drag/Sprite2D/Origin.position = - dictmain.offset 
		get_node("Pos/Wobble/Squish/Drag/Sprite2D").set_clip_children_mode(dictmain.clip)
		rotation = dictmain.rotation
		$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("wiggle", dictmain.wiggle)
		
		if dictmain.advanced_lipsync:
			$Pos/Wobble/Squish/Drag/Sprite2D.hframes = 6
		
		speaking()
		not_speaking()
		animation()
		set_blend(dictmain.blend_mode)
		advanced_lipsyc()


func check_talk():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			hide()
		else:
			show()


func set_blend(blend):
	match  blend:
		"Normal":
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", false)
		"Add":
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/add.png"))
		"Subtract":
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/exclusion.png"))
		"Multiply":
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/multiply.png"))
		"Burn":
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/burn.png"))
		"HardMix":
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/hardmix.png"))
		"Cursed":
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Pos/Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/test1.png"))


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
			reparent(i.get_node("Pos/Wobble/Squish/Drag/Sprite2D"))

