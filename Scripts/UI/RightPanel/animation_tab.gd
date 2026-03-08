extends Control

var should_change: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()


func nullfy():
	%AnimationReset.disabled = true
	%AnimationOneShot.disabled = true
	%ResetonStateChange.disabled = true
	%RSSlider.editable = false
	%NonAnimatedSheetCheck.disabled = true
	%FrameSpinbox.editable = false


func enable():
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			%RSSlider.editable = true
			if i.sprite_type == "Sprite2D":
				%NonAnimatedSheetCheck.disabled = false
				%FrameSpinbox.editable = true
			else:
				%NonAnimatedSheetCheck.disabled = true
				%FrameSpinbox.editable = false

			set_data()


func set_data():
	should_change = false
	for i in Global.held_sprites:
		%RSSlider.value = i.get_value("rainbow_speed")
		if i.sprite_type == "Sprite2D":
			%NonAnimatedSheetCheck.button_pressed = i.get_value("non_animated_sheet")
			%FrameSpinbox.value = i.get_value("frame")
			%FrameSpinbox.max_value = (i.get_node("%Sprite2D").hframes * i.get_node("%Sprite2D").vframes) - 1

	should_change = true


func _on_rs_slider_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				%RSLabel.text = tr("TR_EFFECT_RAINBOW_SPEED") + " " + str(snapped(value * 10, 0.001))
				i.sprite_data.rainbow_speed = value
				StateButton.multi_edit(value, "rainbow_speed", i, i.states)
				i.save_state(Global.current_state)


func _on_non_animated_sheet_check_toggled(toggled_on: bool) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "Sprite2D":
					%FrameSpinbox.max_value = (i.get_node("%Sprite2D").hframes * i.get_node("%Sprite2D").vframes) - 1
					i.sprite_data.non_animated_sheet = toggled_on
					i.animation()
					if toggled_on:
						%FrameHBox.show()
					else:
						%FrameHBox.hide()
				else:
					%FrameHBox.hide()


func _on_frame_spinbox_value_changed(value: float) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "Sprite2D":
					%FrameSpinbox.max_value = (i.get_node("%Sprite2D").hframes * i.get_node("%Sprite2D").vframes) - 1
					i.sprite_data.frame = clamp(value, 0, (i.get_node("%Sprite2D").hframes * i.get_node("%Sprite2D").vframes) - 1)
					i.get_node("%Sprite2D").frame = clamp(value, 0, (i.get_node("%Sprite2D").hframes * i.get_node("%Sprite2D").vframes) - 1)


func _on_frame_spinbox_mouse_entered() -> void:
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "Sprite2D":
					%FrameSpinbox.max_value = (i.get_node("%Sprite2D").hframes * i.get_node("%Sprite2D").vframes) - 1
