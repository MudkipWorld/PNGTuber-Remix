extends Node

var append_folder_selected: bool = false
var should_change: bool = false


func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()


func nullfy():
	%AnimationFramesSlider.editable = false
	%AnimationFramesSlider2.editable = false
	%AnimationSpeedSlider.editable = false


func enable():
	append_folder_selected = false
	should_change = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if !i.get_value("advanced_lipsync"):
				if i.sprite_type == "Sprite2D":
					if !append_folder_selected:
						%AnimationFramesSlider.editable = true
						%AnimationFramesSlider2.editable = true
						%AnimationSpeedSlider.editable = true
				else:
					%AnimationFramesSlider.editable = false
					%AnimationFramesSlider2.editable = false
					%AnimationSpeedSlider.editable = false
					append_folder_selected = true
			else:
				%AnimationFramesSlider.editable = false
				%AnimationFramesSlider2.editable = false
				%AnimationSpeedSlider.editable = false
			#	append_folder_selected = true

			if i.sprite_type == "Sprite2D" && !append_folder_selected:
				%AnimationFramesSlider.value = i.get_value("hframes")
				%AnimationFramesSlider2.value = i.get_value("vframes")
				%AnimationSpeedSlider.value = i.get_value("animation_speed")

	should_change = true


func _on_animation_frames_slider_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				if i != null && is_instance_valid(i):
					%AnimationFramesLabel.text = tr("TR_ANIMATION_FRAMES_H") + " " + str(value)
					i.sprite_data.hframes = value
					i.animation()
					i.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
					i.save_state(Global.current_state)


func _on_animation_speed_slider_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				if i != null && is_instance_valid(i):
					%AnimationSpeedLabel.text = tr("TR_ANIMATION_SPEED") + " " + str(value) + " Fps"
					i.sprite_data.animation_speed = value
					i.animation()
					i.save_state(Global.current_state)


func _on_animation_frames_slider_2_value_changed(value: float) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				if i != null && is_instance_valid(i):
					%AnimationFramesLabel2.text = tr("TR_ANIMATION_FRAMES_V") + " " + str(value)
					i.sprite_data.vframes = value
					i.animation()
					i.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
					i.save_state(Global.current_state)
