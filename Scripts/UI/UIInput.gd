extends Node

var should_change: bool = false


func _ready() -> void:
	await get_tree().current_scene.ready
	held_sprite_is_null()

	Global.reinfo.connect(reinfo)
	Global.deselect.connect(held_sprite_is_null)
	Global.show_model_warning.connect(show_model_warning)
	Global.dev_mode.connect(check_dev_mode)

	%InfluRad.value = MeshEditor.influence_radius
	%InfluStrength.value = MeshEditor.influence_strength
	%InfluRad.get_line_edit().add_theme_font_size_override("placeholder", 12)
	%InfluStrength.get_line_edit().add_theme_font_size_override("placeholder", 12)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		if _has_valid_held_sprite():
			held_sprite_is_true()
		else:
			held_sprite_is_null()


func check_dev_mode(_check: bool = false) -> void:
	pass
	# %Inspector.set_tab_hidden(7, !_check)


func show_model_warning(_warn: bool) -> void:
	%ModelSizeWarning.visible = _warn


#region Update Slider info
func _has_valid_held_sprite() -> bool:
	for i in Global.held_sprites:
		if i != null and is_instance_valid(i):
			return true
	return false


func held_sprite_is_null() -> void:
	%SpriteID.text = "%s %d" % [tr("TR_SPRITE_ID_LABEL"), 0]
	%ParentID.text = "%s %d" % [tr("TR_PARENT_ID_LABEL"), 0]
	%Name.editable = false
	%Name.text = ""
	%AdvancedLipSync.disabled = true


func held_sprite_is_true() -> void:
	Global.top_ui.get_node("%DeselectButton").show()
	%Name.editable = true
	%AdvancedLipSync.disabled = true

	for i in Global.held_sprites:
		if i != null and is_instance_valid(i):
			if i.sprite_type == "Sprite2D":
				%AdvancedLipSync.disabled = false

			%SpriteID.text = "%s %d" % [tr("TR_SPRITE_ID_LABEL"), int(i.sprite_id)]
			%ParentID.text = "%s %d" % [tr("TR_PARENT_ID_LABEL"), int(i.parent_id)]


func reinfo() -> void:
	held_sprite_is_null()
	should_change = false

	for i in Global.held_sprites:
		if i != null and is_instance_valid(i):
			%Name.text = i.sprite_name
			if i.sprite_type == "Sprite2D":
				%AdvancedLipSync.button_pressed = i.get_value("advanced_lipsync")

	await get_tree().create_timer(0.01).timeout
	held_sprite_is_true()

	%ChainTarget.clear()
	%ChainTarget.add_item("None")
	%ChainTarget.select(0)

	var sp = null
	if Global.held_sprites.size() > 0:
		sp = Global.held_sprites[0]

	var index: int = 1
	for i in get_tree().get_nodes_in_group("Sprites"):
		%ChainTarget.add_item(i.sprite_name)
		%ChainTarget.set_item_metadata(index, i)

		if sp != null and is_instance_valid(sp):
			if sp.target_ik != null and is_instance_valid(sp.target_ik):
				if i == sp.target_ik:
					%ChainTarget.select(index)

		index += 1

	should_change = true


func _on_name_text_submitted(new_text) -> void:
	if Global.held_sprites.size() <= 1:
		Global.held_sprites[0].treeitem.set_text(0, new_text)
		Global.held_sprites[0].sprite_name = new_text
		Global.held_sprites[0].save_state(Global.current_state)
	else:
		for i in Global.held_sprites.size():
			Global.held_sprites[i].treeitem.set_text(0, new_text + str(i + 1))
			Global.held_sprites[i].sprite_name = new_text + str(i + 1)
			Global.held_sprites[i].save_state(Global.current_state)

	Global.spinbox_held = false
	%Name.release_focus()
#endregion


#region Advanced-LipSync
func _on_advanced_lip_sync_toggled(toggled_on) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i != null and is_instance_valid(i):
				if i.sprite_type == "Sprite2D":
					i.sprite_data.advanced_lipsync = toggled_on
					i.sprite_data.animation_speed = 1

					if toggled_on:
						i.get_node("%Sprite2D").hframes = 6
					else:
						i.get_node("%Sprite2D").hframes = 1

					i.advanced_lipsyc()
					i.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
					i.save_state(Global.current_state)
					Global.reinfo.emit()


func _on_advanced_lip_sync_mouse_entered() -> void:
	%AdvancedLipSyncLabel.show()


func _on_advanced_lip_sync_mouse_exited() -> void:
	%AdvancedLipSyncLabel.hide()
#endregion


func _on_name_focus_entered() -> void:
	Global.spinbox_held = true


func _on_name_focus_exited() -> void:
	Global.spinbox_held = false


func _on_chain_target_item_selected(index: int) -> void:
	var selected = %ChainTarget.get_item_metadata(index)

	if selected != null and is_instance_valid(selected):
		for i in Global.held_sprites:
			i.target_ik = selected
	else:
		for i in Global.held_sprites:
			i.target_ik = null


func _on_influ_rad_value_changed(value: float) -> void:
	MeshEditor.influence_radius = value


func _on_influ_strength_value_changed(value: float) -> void:
	MeshEditor.influence_strength = value
