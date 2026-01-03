extends Node

func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullify)
	nullify()

func enable() -> void:
	var sp: SpriteObject = null
	if Global.held_sprites:
		sp = Global.held_sprites[0]
	
	if !is_instance_valid(sp):
		nullify()
		return
	
	%FollowOption2.disabled = false
	%FollowOption.disabled = false
	%FollowOption3.disabled = false
	%FollowEye.disabled = false
	%FollowEyeGaze.disabled = false
	%EyeStyle.disabled = false
	%UDPPosOption.disabled = false
	%UDPRotOption.disabled = false
	%UDPScaleOption.disabled = false
	
	
	%FollowOption.select(sp.get_value("follow_type"))
	%FollowOption2.select(sp.get_value("follow_type2"))
	%FollowOption3.select(sp.get_value("follow_type3"))
	%FollowEye.select(sp.get_value("follow_eye"))
	%FollowEyeGaze.select(sp.get_value("gaze_eye"))
	%EyeStyle.select(sp.get_value("style_eye"))
	%UDPPosOption.select(sp.get_value("udp_pos"))
	%UDPRotOption.select(sp.get_value("udp_rot"))
	%UDPScaleOption.select(sp.get_value("udp_scale"))
	
	



func nullify() -> void:
	%FollowOption2.disabled = true
	%FollowOption.disabled = true
	%FollowOption3.disabled = true
	%FollowEye.disabled = true
	%FollowEyeGaze.disabled = true
	%EyeStyle.disabled = true
	%UDPPosOption.disabled = true
	%UDPRotOption.disabled = true
	%UDPScaleOption.disabled = true

func _on_follow_option_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		i.sprite_data["follow_type"] = index 
		StateButton.multi_edit(i.sprite_data["follow_type"], "follow_type", i, i.states)
		i.save_state(Global.current_state)
	


func _on_follow_option_2_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		i.sprite_data["follow_type2"] = index 
		StateButton.multi_edit(i.sprite_data["follow_type2"], "follow_type2", i, i.states)
		i.save_state(Global.current_state)


func _on_follow_option_3_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		i.sprite_data["follow_type3"] = index 
		StateButton.multi_edit(i.sprite_data["follow_type3"], "follow_type3", i, i.states)
		i.save_state(Global.current_state)

func _on_udp_pos_option_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.sprite_data.udp_pos = index

func _on_udp_rot_option_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.sprite_data.udp_rot = index


func _on_udp_scale_option_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.sprite_data.udp_scale = index

func _on_follow_eye_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.sprite_data.follow_eye = index

func _on_follow_eye_gaze_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.sprite_data.gaze_eye = index


func _on_eye_style_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.sprite_data.style_eye = index
