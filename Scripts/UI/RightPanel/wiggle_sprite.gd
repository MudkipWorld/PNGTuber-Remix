extends Node

var append_folder_selected : bool = false
var should_change : bool = false

func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()

func enable():
	nullfy()
	append_folder_selected = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			%TipSpin.editable = true
			%FollowWiggleAppTip.disabled = false
			
			if i.sprite_type == "Sprite2D" && !append_folder_selected:
				%WiggleCheck.disabled = false
				%FollowParentEffect.disabled = false
				%XoffsetSpinBox.editable = true
				%YoffsetSpinBox.editable = true
			else:
				%WiggleCheck.disabled = true
				%FollowParentEffect.disabled = true
				%XoffsetSpinBox.editable = false
				%YoffsetSpinBox.editable = false
				append_folder_selected = true
	set_data()

func set_data():
	should_change = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.get_parent() is WigglyAppendage2D:
				%TipSpin.max_value = i.get_parent().points.size() -1
				
			
			%TipSpin.value = i.get_value("tip_point")
			%FollowWiggleAppTip.button_pressed = i.get_value("follow_wa_tip")
			if i.sprite_type == "Sprite2D"  && !append_folder_selected:
				%WiggleStuff.show()
				%WiggleCheck.button_pressed = i.get_value("wiggle")
				%FollowParentEffect.button_pressed = i.get_value("follow_parent_effects")
				%XoffsetSpinBox.value = i.get_value("wiggle_rot_offset").x
				%YoffsetSpinBox.value = i.get_value("wiggle_rot_offset").y
			else:
				%WiggleStuff.hide()
	should_change = true


func nullfy():
	%TipSpin.editable = false
	
	%WiggleCheck.disabled = true
	%FollowParentEffect.disabled = true
	%FollowWiggleAppTip.disabled = true
	%XoffsetSpinBox.editable = false
	%YoffsetSpinBox.editable = false

func _on_follow_wiggle_app_tip_toggled(toggled_on):
	if toggled_on:
		%TipSpin.editable = true
		%MiniFWBSlider.show()
		%MaxFWBSlider.show()
	if not toggled_on:
		%TipSpin.editable = false
		%MiniFWBSlider.hide()
		%MaxFWBSlider.hide()
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.follow_wa_tip = toggled_on
				i.get_node("%Modifier").position = Vector2(0,0)
				StateButton.multi_edit(toggled_on, "follow_wa_tip", i, i.states)
				i.save_state(Global.current_state)

func _on_tip_spin_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.tip_point = value
				StateButton.multi_edit(value, "tip_point", i, i.states)
				i.save_state(Global.current_state)

func _on_wiggle_check_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.wiggle = toggled_on
				i.get_node("%Sprite2D").material.set_shader_parameter("wiggle", toggled_on)
				StateButton.multi_edit(toggled_on, "wiggle", i, i.states)
				i.save_state(Global.current_state)

func _on_follow_parent_effect_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.follow_parent_effects = toggled_on
				StateButton.multi_edit(toggled_on, "follow_parent_effects", i, i.states)
				i.save_state(Global.current_state)

func _on_xoffset_spin_box_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.wiggle_rot_offset.x = value
				i.get_node("%Sprite2D").material.set_shader_parameter("rotation_offset", Vector2(value, i.get_node("%Sprite2D").material.get_shader_parameter("rotation_offset").y))
				StateButton.multi_edit(value, "wiggle_rot_offset", i, i.states, true, "x")
				i.save_state(Global.current_state)

func _on_yoffset_spin_box_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.wiggle_rot_offset.y = value
				i.get_node("%Sprite2D").material.set_shader_parameter("rotation_offset", Vector2(i.get_node("%Sprite2D").material.get_shader_parameter("rotation_offset").x, value))
				StateButton.multi_edit(value, "wiggle_rot_offset", i, i.states, true, "y")
				i.save_state(Global.current_state)
