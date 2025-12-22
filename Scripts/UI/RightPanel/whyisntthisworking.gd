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
	
	%FollowOption.select(sp.get_value("follow_type"))
	%FollowOption2.select(sp.get_value("follow_type2"))
	%FollowOption3.select(sp.get_value("follow_type3"))

func nullify() -> void:
	%FollowOption2.disabled = true
	%FollowOption.disabled = true
	%FollowOption3.disabled = true

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
