extends Node

@export var actor : Node
@export var animation_handler : Node
var currently_speaking : bool = false
var blinking : bool = false
var tween : Tween

func _ready() -> void:
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	Global.blink.connect(blink)
	Global.mode_changed.connect(update_to_mode_change)
	Global.blink.connect(editor_blink)
	Global.animation_state.connect(reset_animations)
	await  get_tree().physics_frame
	not_speaking()

func _process(_delta: float) -> void:
	var gazing_l = Vector2(0, 0)
	var gazing_r = Vector2(0, 0)
	if Tracker.working && actor.sprite_data.follow_eye != 0:
		gazing_l = Tracker.smooth_gaze_left
		gazing_r = Tracker.smooth_gaze_right
		%Modifier1.modulate.a = 1

		if actor.sprite_data.should_blink:
			if actor.sprite_data.style_eye != 0:
				match actor.sprite_data.follow_eye:
					0:
						%Modifier.scale.y = 1
					1:
						%Modifier.scale.y = lerp(%Modifier.scale.y, Tracker.track_eye_left, 0.08)
					2:
						%Modifier.scale.y = lerp(%Modifier.scale.y, Tracker.track_eye_right, 0.08)
			else:
				%Modifier.scale.y = 1
			if Tracker.is_blink:
				if !actor.sprite_data.open_eyes:
					%Modifier1.show()
				else:
					%Modifier1.hide()
			elif !Tracker.is_blink:
				if !actor.sprite_data.open_eyes:
					%Modifier1.hide()
				else:
					%Modifier1.show()
	
	match actor.sprite_data.gaze_eye:
		1:
			%Sprite2D.position = %Sprite2D.position.lerp(actor.get_value("offset") + gazing_l, 0.25)
		2:
			%Sprite2D.position = %Sprite2D.position.lerp(actor.get_value("offset") + gazing_r, 0.25)

	if Tracker.working && actor.sprite_data.follow_mouth != 0:
		%Modifier.modulate.a = 1
		if actor.sprite_data.should_talk:
			if Tracker.is_mouth_open:
				if actor.sprite_data.open_mouth:
					%Modifier.show()
				else:
					%Modifier.hide()
			elif !Tracker.is_mouth_open:
				if actor.sprite_data.open_mouth:
					%Modifier.hide()
				else:
					%Modifier.show()

	if Global.settings_dict.checkinput != true:
		return
	var is_trying_to_appear = false
	var is_trying_to_disappear = false
	if GlobInput.is_action_just_pressed(str(actor.sprite_id)) && actor.hold_to_show:
		is_trying_to_appear = true
	
	elif GlobInput.is_action_just_released(str(actor.sprite_id)) && actor.hold_to_show:
		is_trying_to_disappear = true

	if GlobInput.is_action_just_pressed(str(actor.sprite_id)) && !actor.hold_to_show:
		if actor.show_only:
			if actor.get_value("fade_asset"):
				if actor.was_active_before: return
				var _new_vis = await actor.fade_asset(false, actor, %Sprite2D)
			%Sprite2D.visible = true
			actor.was_active_before = true
			
		else:
			if actor.get_value("fade_asset"):
				var new_vis = await actor.fade_asset(actor.was_active_before, actor, %Sprite2D)
				actor.was_active_before = new_vis
				%Sprite2D.visible = new_vis
			else:
				%Sprite2D.visible = !%Sprite2D.visible
				actor.was_active_before = %Sprite2D.visible

	if GlobInput.is_action_just_pressed(actor.disappear_keys) && !actor.hold_to_show:
		is_trying_to_disappear = true

	if is_trying_to_disappear:
		if actor.get_value("fade_asset"):
			if !actor.was_active_before: return
			var new_visibility = await actor.fade_asset(true, actor, %Sprite2D)
			%Sprite2D.visible = new_visibility
			actor.was_active_before = new_visibility
		else:
			%Sprite2D.visible = false
			actor.was_active_before = %Sprite2D.visible
		if !actor.is_asset && !%Sprite2D.visible:
			%Sprite2D.visible = true
			actor.was_active_before = true
		
	elif is_trying_to_appear:
		%Sprite2D.visible = true
		actor.was_active_before = %Sprite2D.visible
	
	'''
	if actor.sprite_data.is_cycle and actor.sprite_data.cycle > 0:
		var cycle = Global.settings_dict.cycles[actor.sprite_data.cycle - 1]
		var sprite_pos = cycle.sprites.find(actor.sprite_id)
		
		if is_trying_to_appear:
			cycle.active = true
			cycle.pos = sprite_pos
			cycle.last_sprite = actor.sprite_id
			
			for sprite in get_tree().get_nodes_in_group("Sprites"):
				if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
					sprite.get_node("%Sprite2D").hide()
					sprite.was_active_before = sprite.get_node("%Sprite2D").visible
				if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
					sprite.get_node("%Sprite2D").show()
					sprite.was_active_before = sprite.get_node("%Sprite2D").visible
					
		if is_trying_to_disappear:
			cycle.active = true
			cycle.pos = 0
			cycle.last_sprite = cycle.sprites[0]
			
			for sprite in get_tree().get_nodes_in_group("Sprites"):
				if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
					sprite.get_node("%Sprite2D").hide()
					sprite.was_active_before = sprite.get_node("%Sprite2D").visible
				if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
					sprite.get_node("%Sprite2D").show()
					sprite.was_active_before = sprite.get_node("%Sprite2D").visible
		
		actor.was_active_before = false
		if !actor.is_asset && !%Sprite2D.visible:
			%Sprite2D.visible = true
			actor.was_active_before = true
	'''

func update_to_mode_change(mode : int):
	match mode:
		0:
			%Modifier1.show()
			if actor.get_value("should_blink"):
				if actor.get_value("open_eyes"):
					if !blinking:
						%Modifier1.modulate.a = 1
					elif blinking:
						%Modifier1.modulate.a = 0.2

				elif !actor.get_value("open_eyes"):
					if blinking:
						%Modifier1.modulate.a = 1
					elif !blinking:
						%Modifier1.modulate.a = 0.2

			
			%Modifier.show()
			if actor.get_value("should_talk"):
				if actor.get_value("open_mouth"):
					if currently_speaking:
						%Modifier.modulate.a = 1
					else:
						%Modifier.modulate.a = 0.2

				elif !actor.get_value("open_mouth"):
					if !currently_speaking:
						%Modifier.modulate.a = 1
					else:
						%Modifier.modulate.a = 0.2
			else:
				%Modifier.show()
				%Modifier.modulate.a = 1
		1:
			%Modifier1.modulate.a = 1
			if actor.get_value("should_blink"):
				if actor.get_value("open_eyes"):
					if !blinking:
						%Modifier1.show()
					elif blinking:
						%Modifier1.hide()

				elif !actor.get_value("open_eyes"):
					if blinking:
						%Modifier1.show()
					elif !blinking:
						%Modifier1.hide()

			%Modifier.modulate.a = 1
			if actor.get_value("should_talk"):
				if actor.get_value("open_mouth"):
					if currently_speaking:
						%Modifier.show()
					else:
						%Modifier.hide()

				elif !actor.get_value("open_mouth"):
					if !currently_speaking:
						%Modifier.show()
					else:
						%Modifier.hide()
			else:
				%Modifier.show()
				%Modifier.modulate.a = 1

func editor_blink():
	if Tracker.working && actor.sprite_data.follow_eye != 0: return
	if Global.mode == 0:
		if actor.get_value("should_blink"):
			%Modifier1.show()
			if not actor.get_value("open_eyes"):
				%Modifier1.modulate.a = 1
				reset_animations()
			else:
				%Modifier1.modulate.a = 0.2
		
		blinking = true
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		await %Blink.timeout
		if actor.get_value("should_blink"):
			if not actor.get_value("open_eyes"):
				%Modifier1.modulate.a = 0.2
			else:
				%Modifier1.modulate.a = 1
				reset_animations()
		else:
			%Modifier1.modulate.a = 1
		blinking = false

func blink():
	if Tracker.working && actor.sprite_data.follow_eye != 0: return
	if Global.mode != 0:
		if actor.get_value("should_blink"):
			%Modifier1.modulate.a = 1
			if not actor.get_value("open_eyes"):
				%Modifier1.show()
				reset_animations()
			else:
				%Modifier1.hide()
		
		blinking = true
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		await %Blink.timeout
		if actor.get_value("should_blink"):
			if not actor.get_value("open_eyes"):
				%Modifier1.hide()
			else:
				%Modifier1.show()
				reset_animations()
		else:
			%Modifier1.show()
		blinking = false

func speaking():
	if Tracker.working && actor.sprite_data.follow_mouth != 0: return
	if Global.mode != 0:
		%Modifier.modulate.a = 1
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				reset_animations()
				%Modifier.show()
					
			else:
				%Modifier.hide()
		else:
			%Modifier.show()
			
	elif Global.mode == 0:
		%Modifier.show()
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Modifier.modulate.a = 1
				reset_animations()
			else:
				%Modifier.modulate.a = 0.2
		else:
			%Modifier.modulate.a = 1
	currently_speaking = true

func reset_animations(_place_holder : int = 0):
	if actor.get_value("one_shot"):
		reset_anim()
	
	if actor.get_value("should_reset"):
		reset_anim()

func reset_anim():
	if actor.referenced_data == null or !is_instance_valid(actor.referenced_data):
		return
	if actor.referenced_data.is_apng or actor.referenced_data.img_animated:
		animation_handler.index = 0
		animation_handler.proper_apng_one_shot()
	animation_handler.played_once = false
	if actor.sprite_type == "Sprite2D":
		%Sprite2D.frame = 0
		actor.animation()

func not_speaking():
	if Tracker.working && actor.sprite_data.follow_mouth != 0: return
	if Global.mode != 0:
		%Modifier.modulate.a = 1
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Modifier.hide()
			else:
				reset_animations()
				%Modifier.show()
		else:
			%Modifier.show()
			
	elif Global.mode == 0:
		%Modifier.show()
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Modifier.modulate.a = 0.2
			else:
				reset_animations()
				%Modifier.modulate.a = 1
		else:
			%Modifier.modulate.a = 1
			
	currently_speaking = false
