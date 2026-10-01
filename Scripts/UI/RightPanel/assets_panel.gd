extends VBoxContainer



func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	Global.load_model.connect(update_cycle_choice)
	Global.new_file.connect(clear_cycle_choice)
	nullfy()

func nullfy():
	%IsAssetCheck.disabled = true
	%IsAssetButton.disabled = true
	%RemoveAssetButton.disabled = true
	%ShouldDisappearCheck.disabled = true
	%DontHideOnToggleCheck.disabled = true
	%HoldToShowCheck.disabled = true
	%MinDurationSpinBox.editable = false
	%CastTimeSpinBox.editable = false
	%InclusiveKeyCheck.disabled = true
	%IgnoreIfRestCheck.disabled = true
	%AutoShowCheck.disabled = true
	%ShouldDisDelButton.disabled = true
	%ShouldDisRemapButton.disabled = true
	%ShouldDisAddButton.disabled = true
	%ShouldDisDelButton.disabled = true
	%ShouldDisRemapButton.disabled = true
	%ShouldDisListContainer.hide()
	%CycleChoiceSprite.disabled = true
	#%CycleMargin.hide()

func enable():
	if Global.held_sprites.size() == 1:
		%IsAssetCheck.disabled = false
		%IsAssetButton.disabled = false
		%RemoveAssetButton.disabled = false
		%ShouldDisappearCheck.disabled = false
		%DontHideOnToggleCheck.disabled = false
		%HoldToShowCheck.disabled = false
		%MinDurationSpinBox.editable = true
		%CastTimeSpinBox.editable = true
		%InclusiveKeyCheck.disabled = false
		%IgnoreIfRestCheck.disabled = false
		%AutoShowCheck.disabled = false
		%ShouldDisAddButton.disabled = false
		%ShouldDisDelButton.disabled = false
		%ShouldDisRemapButton.disabled = false
		%IsAssetButton.text = "Null"
		%CycleChoiceSprite.disabled = false
		
		set_data()
	else:
		nullfy()

func set_data():
	%IsAssetButton.action = str(Global.held_sprites[0].sprite_id)
	%IsAssetCheck.button_pressed = Global.held_sprites[0].is_asset
	%DontHideOnToggleCheck.button_pressed = Global.held_sprites[0].show_only
	%ShouldDisList.clear()
	if InputMap.has_action(Global.held_sprites[0].disappear_keys):
		for i in InputMap.action_get_events(Global.held_sprites[0].disappear_keys):
			%ShouldDisList.add_item(i.as_text())
	%ShouldDisappearCheck.button_pressed = Global.held_sprites[0].should_disappear
	if %ShouldDisappearCheck.button_pressed:
		%ShouldDisListContainer.show()
	else:
		%ShouldDisListContainer.hide()
	%HoldToShowCheck.button_pressed = Global.held_sprites[0].hold_to_show
	%MinDurationSpinBox.value = Global.held_sprites[0].min_duration
	%CastTimeSpinBox.value = Global.held_sprites[0].cast_time
	%InclusiveKeyCheck.button_pressed = Global.held_sprites[0].inclusive_key_check
	%IgnoreIfRestCheck.button_pressed =  Global.held_sprites[0].ignore_if_rest
	%AutoShowCheck.button_pressed =  Global.held_sprites[0].auto_show
	%IsAssetButton.update_key_text()
	%CycleChoiceSprite.select(Global.held_sprites[0].sprite_data.cycle)
	if !Global.held_sprites[0].sprite_data.is_cycle:
		%CycleChoiceSprite.disabled = true
	_on_cycle_choice_item_selected(%CycleChoice.selected)
	
func _on_cycle_choice_item_selected(index: int) -> void:
	if index == 0:
		%CycleMargin.hide()
	else:
		%CycleMargin.show()
		%CycleKey.update_key_text()
		%CycleForward.update_key_text()
		%CycleBackward.update_key_text()

func _on_add_cycle_pressed() -> void:
	%CycleChoiceSprite.add_item("Cycle " + str(%CycleChoice.item_count))
	%CycleChoice.add_item("Cycle " + str(%CycleChoice.item_count))
	
	Global.settings_dict.cycles.append({
		toggle = null,
		forward = null,
		backward = null,
		sprites = [],
		pos = 0,
		last_sprite = 0,
		active = false,
	})


func _on_delete_cycle_pressed() -> void:
	if %CycleChoice.get_selected_id() != 0:
		var cycle_id = %CycleChoice.get_selected_id() - 1
		var cycle = Global.settings_dict.cycles[cycle_id]
		var behind_sprites: Array = []
		# clear relative sprite cycle bindings.
		for sprite in get_tree().get_nodes_in_group("Sprites"):
			if sprite.get_value("is_cycle") == false:
				continue
			if  sprite.sprite_id in cycle.sprites:
				sprite.sprite_data.cycle = 0
				sprite.sync_sprite_cycle_in_states()
			elif sprite.get_value("cycle") - 1 > cycle_id:
				behind_sprites.append(sprite)
		
		# the behind cycle numbers will be shifted forward to compensate.
		for sprite in behind_sprites:
			sprite.sprite_data.cycle = sprite.sprite_data.cycle - 1
			sprite.sync_sprite_cycle_in_states()
		# remove target cycle data
		Global.settings_dict.cycles.remove_at(cycle_id)
		#%CycleChoiceSprite.remove_item(%CycleChoice.get_selected_id())
		#%CycleChoice.remove_item(%CycleChoice.get_selected_id())
		update_cycle_choice()

func _on_cycle_choice_sprite_item_selected(index: int) -> void:
	if %CycleChoiceSprite.get_selected_id() != 0:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if index == i.sprite_data.cycle:
					continue
				i.sprite_data.cycle = index
				i.sync_sprite_cycle_in_states()
				for l in Global.settings_dict.cycles:
					if l.sprites.has(i.sprite_id):
						l.sprites.remove_at(l.sprites.find(i.sprite_id))
				Global.settings_dict.cycles[%CycleChoiceSprite.get_selected_id() - 1].sprites.append(i.sprite_id)
	if %CycleChoiceSprite.get_selected_id() == 0:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.cycle = index
				i.sync_sprite_cycle_in_states()
				for l in Global.settings_dict.cycles:
					if l.sprites.has(i.sprite_id):
						l.sprites.remove_at(l.sprites.find(i.sprite_id))
						i.get_node("%Sprite2D").show()
	
	
func update_cycle_choice():
	%CycleChoiceSprite.clear()
	%CycleChoice.clear()
	
	%CycleChoiceSprite.add_item("None")
	%CycleChoice.add_item("None")
	for i in Global.settings_dict.cycles.size():
		%CycleChoiceSprite.add_item("Cycle " + str(i + 1))
		%CycleChoice.add_item("Cycle " + str(i + 1))

func clear_cycle_choice():
	Global.settings_dict.cycles.clear()
	update_cycle_choice()

func _on_is_cycle_checkbox_changed(button_changed):
	if !button_changed:
		%CycleChoiceSprite.select(0)
		(%CycleChoiceSprite.item_selected as Signal).emit(%CycleChoiceSprite.selected)
		%CycleChoiceSprite.disabled = true
	else:
		%CycleChoiceSprite.disabled = false
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sync_sprite_cycle_in_states()


func _on_delete_cycle_mouse_entered() -> void:
	%CycleDeleteTip.show()

func _on_delete_cycle_mouse_exited() -> void:
	%CycleDeleteTip.hide()
