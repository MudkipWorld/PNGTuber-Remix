extends Node

var sprite_selected : bool = false
var should_change : bool = false


func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()

func enable():
	nullfy()
	sprite_selected = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "WiggleApp" && !sprite_selected:
				%AutoWagCheck.disabled = false
				%TextureModeOption.disabled = false
				%AnchorSprite.disabled = false
				
			else:
				sprite_selected = true
				nullfy()
	
	set_data()

func nullfy():
	%AutoWagCheck.disabled = true
	%TextureModeOption.disabled = true
	%AnchorSprite.disabled = true

func set_data():
	should_change = false
	if !sprite_selected:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "WiggleApp":
					%WiggleAppStuff.show()
					%AutoWagCheck.button_pressed = i.get_value("auto_wag")
					
					populate_anchor_data()
					match i.get_value("tile"):
						1:
							%TextureModeOption.select(1)
						2:
							%TextureModeOption.select(0)
	else:
		%WiggleAppStuff.hide()
	
	should_change = true

func _on_auto_wag_check_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.auto_wag = toggled_on
				if toggled_on:
					%AutoWagSettings.show()
					%WiggleAppsCurveBSlider.hide()
				if !toggled_on:
					i.get_node("%Sprite2D").curvature = i.get_value("wiggle_curve")
					%AutoWagSettings.hide()
					%WiggleAppsCurveBSlider.show()
				
				StateButton.multi_edit(toggled_on, "auto_wag", i, i.states)
				i.save_state(Global.current_state)

func _on_texture_mode_option_item_selected(index: int) -> void:
	match index:
		0:
			if should_change:
				for i in Global.held_sprites:
					if i != null && is_instance_valid(i):
						i.sprite_data.tile = 2
						StateButton.multi_edit(2, "tile", i, i.states)
						i.get_node("%Sprite2D").texture_mode = 2
						i.save_state(Global.current_state)
		1:
			if should_change:
				for i in Global.held_sprites:
					if i != null && is_instance_valid(i):
						i.sprite_data.tile = 1
						StateButton.multi_edit(1, "tile", i, i.states)
						i.get_node("%Sprite2D").texture_mode = 1
						i.save_state(Global.current_state)

func populate_anchor_data():
	%AnchorSprite.clear()
	%AnchorSprite.add_item("None")
	
	var ind = 1
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.sprite_name != Global.held_sprites[0].sprite_name:
			%AnchorSprite.add_item(i.sprite_name)
			%AnchorSprite.set_item_metadata(ind, i)
			if Global.held_sprites[0].get_value("anchor_id") == i.sprite_id:
				%AnchorSprite.select(ind)
				
			ind += 1

func _on_anchor_sprite_item_selected(index: int) -> void:
	if index == 0:
		if should_change:
			for i in Global.held_sprites:
				if i != null && is_instance_valid(i):
					i.sprite_data.anchor_id = null
					StateButton.multi_edit(i.sprite_data.anchor_id, "anchor_id", i, i.states)
					i.get_node("%Sprite2D").anchor_target = null
					i.save_state(Global.current_state)
	else:
		if should_change:
			for i in Global.held_sprites:
				if i != null && is_instance_valid(i):
					i.sprite_data.anchor_id = %AnchorSprite.get_item_metadata(index).sprite_id
					StateButton.multi_edit(i.sprite_data.anchor_id, "anchor_id", i, i.states)
					i.get_node("%Sprite2D").anchor_target = %AnchorSprite.get_item_metadata(index).get_node("%Sprite2D")
					i.save_state(Global.current_state)
