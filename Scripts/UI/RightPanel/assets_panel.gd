extends VBoxContainer



func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	Global.load_model.connect(update_cycle_choice)
	nullfy()

func nullfy():
	%IsAssetCheck.disabled = true
	%IsAssetButton.disabled = true
	%RemoveAssetButton.disabled = true
	%ShouldDisappearCheck.disabled = true
	%DontHideOnToggleCheck.disabled = true
	%HoldToShowCheck.disabled = true
	%ShouldDisDelButton.disabled = true
	%ShouldDisRemapButton.disabled = true
	%ShouldDisAddButton.disabled = true
	%ShouldDisDelButton.disabled = true
	%ShouldDisRemapButton.disabled = true
	%ShouldDisListContainer.hide()
	%CycleChoiceSprite.disabled = true
	%CycleMargin.hide()

func enable():
	if Global.held_sprites.size() == 1:
		%IsAssetCheck.disabled = false
		%IsAssetButton.disabled = false
		%RemoveAssetButton.disabled = false
		%ShouldDisappearCheck.disabled = false
		%DontHideOnToggleCheck.disabled = false
		%HoldToShowCheck.disabled = false
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
	%IsAssetButton.update_key_text()
	%CycleChoiceSprite.select(Global.held_sprites[0].sprite_data.cycle)

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
		Global.settings_dict.cycles.remove_at(%CycleChoice.get_selected_id() - 1)
		# TODO: move forward remained IDs after the deleted ID
		%CycleChoiceSprite.remove_item(%CycleChoice.get_selected_id())
		%CycleChoice.remove_item(%CycleChoice.get_selected_id())

func _on_cycle_choice_sprite_item_selected(index: int) -> void:
	if %CycleChoice.get_selected_id() != 0:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.cycle = index
				for l in Global.settings_dict.cycles:
					if l.sprites.has(i.sprite_id):
						l.sprites.remove_at(l.sprites.find(i.sprite_id))
				Global.settings_dict.cycles[%CycleChoiceSprite.get_selected_id() - 1].sprites.append(i.sprite_id)
	if %CycleChoice.get_selected_id() == 0:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.cycle = index
				for l in Global.settings_dict.cycles:
					if l.sprites.has(i.sprite_id):
						l.sprites.remove_at(l.sprites.find(i.sprite_id))
						i.get_node("%Sprite2D").show()

func update_cycle_choice():
	%CycleChoice.clear()
	%CycleChoiceSprite.clear()
	
	%CycleChoice.add_item("None")
	%CycleChoiceSprite.add_item("None")
	for i in Global.settings_dict.cycles.size():
		%CycleChoice.add_item("Cycle " + str(i + 1))
		%CycleChoiceSprite.add_item("Cycle " + str(i + 1))
