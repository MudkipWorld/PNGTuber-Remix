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

var sprite_name : String = ""
@export var states : Array = [{}]
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
	offset = $Pos/Wobble/Squish/Drag/Rotation/Sprite2D.offset,
	ignore_bounce = false,
	clip = 0,
	physics = true,
	
	wiggle = false,
	wiggle_amp = 0,
	wiggle_freq = 0,
	wiggle_physics = false,
	wiggle_rot_offset = Vector2(0.5, 0.5),
	
	
	
	advanced_lipsync = false,
	
	look_at_mouse_pos = 0,
	look_at_mouse_pos_y = 0,
	
	should_rotate = false,
	should_rot_speed = 0.01,
	
	should_reset = false,
	one_shot = false,
	
	rainbow = false,
	rainbow_self = false,
	rainbow_speed = 0.01,
	
	follow_parent_effects = false,
	follow_wa_tip = false,
	tip_point = 0,
	
	}
var smooth_rot = 0.0
var smooth_glob = Vector2(0.0,0.0)

var anim_texture 
var anim_texture_normal 
var img_animated : bool = false
var is_apng : bool = false

var dragging_type = "Null"
@onready var og_glob = global_position

var dt = 0.0
var frames : Array[AImgIOFrame] = []
var frames2 : Array[AImgIOFrame] = []
var fidx = 0

var saved_event : InputEvent
var is_asset : bool = false
var was_active_before : bool = true
var should_disappear : bool = false
var saved_keys : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().get_node("Main").key_pressed.connect(asset)
	og_glob = dictmain.global_position
	Global.blink.connect(blink)
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	animation()
#	print(get_node("Pos/Wobble/Squish/Drag/Sprite2D/Grab").pivot_offset)

func animation():
	if not dictmain.advanced_lipsync:
		$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.hframes = dictmain.hframes
		$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.vframes = 1
		if dictmain.hframes > 1:
			coord = dictmain.hframes -1
			if not coord <= 0:
				if $Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame == coord:
					if dictmain.one_shot:
						return
					$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame = 0
					
				elif dictmain.hframes > 1:
					$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.set_frame_coords(Vector2(clamp($Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame +1, 0,coord), 0))
					
		else:
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.set_frame_coords(Vector2(0, 0))
	
	
	$Animation.wait_time = 1/dictmain.animation_speed 
	$Animation.start()



func _process(delta):
	if Global.held_sprite == self:
		%Grab.mouse_filter = 1
	else:
		%Grab.mouse_filter = 2
	#	%Origin.mouse_filter = 2
	if dragging:
		if dragging_type == "Sprite":
			global_position = get_global_mouse_position() - of
			smooth_glob = get_global_mouse_position() - of
			get_tree().get_root().get_node("Main/Control/UIInput").update_pos_spins()
	
	glob = dragger.global_position
	
	
	drag(delta)
	wobble()
	if not dictmain.ignore_bounce:
		glob.y -= contain.bounceChange
	
	var length = (glob.y - dragger.global_position.y)
	
	if dictmain.physics:
		if get_parent() is Sprite2D or get_parent() is WigglyAppendage2D or get_parent() is CanvasGroup:
			var c_parent = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
			
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			length += c_parrent_length
	
	rotationalDrag(length)
	stretch(length)
	
	if dictmain.wiggle:
		wiggle_sprite()
		
	
	if dictmain.should_rotate:
		auto_rotate()
	rainbow()
	follow_wiggle()
	follow_mouse()

func follow_wiggle():
	if dictmain.follow_wa_tip:
		if get_parent() is WigglyAppendage2D:
			var pnt = get_parent().points[clamp(dictmain.tip_point,0, get_parent().points.size() -1)]
			position = pnt
			%Pos.rotation = (pnt.y/100)
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
	
	var mouse = get_local_mouse_position()
	var dir = Vector2.ZERO.direction_to(mouse)
	%Pos.position.x = dir.x * dictmain.look_at_mouse_pos
	%Pos.position.y = dir.y * dictmain.look_at_mouse_pos_y

func auto_rotate():
	$Pos/Wobble.rotate(dictmain.should_rot_speed)

func wiggle_sprite():
	var wiggle_val = sin(Global.tick*dictmain.wiggle_freq)*dictmain.wiggle_amp
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
	wob.position.x = sin(Global.tick*dictmain.xFrq)*dictmain.xAmp
	wob.position.y = sin(Global.tick*dictmain.yFrq)*dictmain.yAmp

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
	else:
		%Pos.show()

func speaking():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			%Rotation.show()
			coord = 0
			animation()
				
		else:
			%Rotation.hide()
	else:
		%Rotation.show()
	currently_speaking = true

func advanced_lipsyc():
	if dictmain.advanced_lipsync:
		
		if $Pos/Wobble/Squish/Drag/Rotation/Sprite2D.hframes != 6:
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.hframes = 6
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
				$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame_coords.x = 1
				

			elif GlobalAudioStreamPlayer.used_bar > t3 && GlobalAudioStreamPlayer.used_bar < t4:
		#		print("s")
				$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame_coords.x = 2
				

			elif GlobalAudioStreamPlayer.used_bar > t5 && GlobalAudioStreamPlayer.used_bar < t6:
			#	print("o")
				$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame_coords.x = 3
				

				
			elif GlobalAudioStreamPlayer.used_bar > t9 && GlobalAudioStreamPlayer.used_bar < t10:
			#	print("e")
				$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame_coords.x = 4
				
			elif GlobalAudioStreamPlayer.used_bar > t7 && GlobalAudioStreamPlayer.used_bar < t8:
			#	print("h")
				$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame_coords.x = 5
			
	
		else:
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.frame_coords.x = 0
			
		
		await $Talk.timeout
		advanced_lipsyc()

func not_speaking():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			%Rotation.hide()
		else:
			%Rotation.show()
			coord = 0
			animation()
	else:
		%Rotation.show()
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
	visible = dictmain.visible,
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
	rotation = dictmain.rotation,
	offset = dictmain.offset,
	ignore_bounce = dictmain.ignore_bounce,
	clip = dictmain.clip,
	physics = dictmain.physics,
	wiggle = dictmain.wiggle,
	wiggle_amp = dictmain.wiggle_amp,
	wiggle_freq = dictmain.wiggle_freq,
	wiggle_physics = dictmain.wiggle_physics,
	wiggle_rot_offset = dictmain.wiggle_rot_offset,
	
	advanced_lipsync = dictmain.advanced_lipsync,
	
	look_at_mouse_pos = dictmain.look_at_mouse_pos,
	look_at_mouse_pos_y = dictmain.look_at_mouse_pos_y,
	
	should_rotate = dictmain.should_rotate,
	should_rot_speed = dictmain.should_rot_speed,
	
	should_reset = dictmain.should_reset,
	one_shot = dictmain.one_shot,
	
	rainbow = dictmain.rainbow,
	rainbow_self = dictmain.rainbow_self,
	rainbow_speed = dictmain.rainbow_speed,
	
	follow_parent_wiggle = dictmain.follow_parent_effects,
	follow_wa_tip = dictmain.follow_wa_tip,
	tip_point = dictmain.tip_point,
	}
	states[id] = dict

func get_state(id):
	if not states[id].is_empty():
		var dict = states[id]
		dictmain.merge(dict, true)
		
		if dictmain.should_reset:
			if img_animated:
				%Sprite2D.texture.diffuse_texture.current_frame = 0
				if %Sprite2D.texture.normal_texture != null:
					%Sprite2D.texture.normal_texture.current_frame = 0
			elif dictmain.hframes > 1:
				%Sprite2D.frame = 0
				print(%Sprite2D.frame)
			elif is_apng:
				fidx = 0
				
		if img_animated:
			%Sprite2D.texture.diffuse_texture.one_shot = dictmain.one_shot
			if %Sprite2D.texture.normal_texture != null:
				%Sprite2D.texture.normal_texture.one_shot = dictmain.one_shot
			
		
		%Sprite2D.position = dictmain.offset 
		
		z_index = dictmain.z_index
		modulate = dictmain.colored
		scale = dictmain.scale
		global_position = dictmain.global_position
		position = dictmain.position

#		$Pos/Wobble/Squish/Drag/Rotation/Origin.position = - dictmain.offset 
		get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").set_clip_children_mode(dictmain.clip)
		rotation = dictmain.rotation
		$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("wiggle", dictmain.wiggle)
		$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.material.set_shader_parameter("rotation_offset", dictmain.wiggle_rot_offset)
		
		
		if dictmain.advanced_lipsync:
			$Pos/Wobble/Squish/Drag/Rotation/Sprite2D.hframes = 6
		
		if dictmain.should_blink:
			if dictmain.open_eyes:
				
				%Pos.show()
			else:
				%Pos.hide()
		
		
		visible = dictmain.visible
		speaking()
		not_speaking()
		animation()
		set_blend(dictmain.blend_mode)
		advanced_lipsyc()
		
		
		follow_p_wiggle()
		
		%Pos.position = Vector2(0,0)

func follow_p_wiggle():
	if dictmain.follow_parent_effects:
		use_parent_material = true
		%Sprite2D.use_parent_material = true
	else:
		use_parent_material = false
		%Sprite2D.use_parent_material = false

func check_talk():
	if dictmain.should_talk:
		if dictmain.open_mouth:
			%Rotation.hide()
		else:
			%Rotation.show()
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
		if not Input.is_action_pressed("ctrl"):
			of = get_global_mouse_position() - global_position
			dragging = true
			dragging_type = "Sprite"
		else:
			dragging_type = "Null"

func _on_grab_button_up():
	if Global.held_sprite == self && dragging:
		dragging_type = "Null"
		save_state(Global.current_state)
		dragging = false
	og_glob = dictmain.global_position

func reparent_obj(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			reparent(i.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	set_physics_process(false)
	var cframe2: AImgIOFrame
	if is_apng:
		if len(frames) == 0:
			return
		if fidx >= len(frames):
			fidx = 0
		dt += delta
		var cframe: AImgIOFrame = frames[fidx]
		if %Sprite2D.texture.normal_texture:
			cframe2= frames2[fidx]
		if dt >= cframe.duration:
			dt -= cframe.duration
			fidx += 1
		# yes this does this every _process, oh well
		var tex = ImageTexture.create_from_image(cframe.content)
		%Sprite2D.texture.diffuse_texture = tex
		if %Sprite2D.texture.normal_texture:
			if frames2.size() != frames.size():
				frames2.resize(frames.size())
			%Sprite2D.texture.normal_texture = ImageTexture.create_from_image(cframe2.content)


func asset(key):
	if is_asset:
		if InputMap.action_get_events(str(sprite_id)).size() > 0:
			if saved_event.as_text() == key:
				%Drag.visible = !%Drag.visible
				was_active_before = %Drag.visible
				for i in get_tree().get_nodes_in_group("Sprites"):
					if i.should_disappear:
						if saved_event.as_text() in i.saved_keys:
							i.get_node("%Drag").visible = false
							i.was_active_before = false
