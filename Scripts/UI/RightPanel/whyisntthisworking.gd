extends Node

var should_change : bool = false

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
	
	should_change = false
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
	should_change = true

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
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "follow_type", Global.current_state, i.sprite_data["follow_type"] , index)
		i.sprite_data["follow_type"] = index 
		StateButton.multi_edit(i.sprite_data["follow_type"], "follow_type", i, i.states)
		i.save_state(Global.current_state)
		undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_follow_option_2_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "follow_type2", Global.current_state, i.sprite_data["follow_type2"] , index)
		i.sprite_data["follow_type2"] = index 
		StateButton.multi_edit(i.sprite_data["follow_type2"], "follow_type2", i, i.states)
		i.save_state(Global.current_state)
		undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_follow_option_3_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "follow_type3", Global.current_state, i.sprite_data["follow_type3"] , index)
		i.sprite_data["follow_type3"] = index 
		StateButton.multi_edit(i.sprite_data["follow_type3"], "follow_type3", i, i.states)
		i.save_state(Global.current_state)
		undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_udp_pos_option_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var d = submit_to_undo_redo_manager(i, "udp_pos", Global.current_state, i.sprite_data["udp_pos"] , index)
			StateButton.multi_edit(i.sprite_data["udp_pos"], "udp_pos", i, i.states)
			i.sprite_data.udp_pos = index
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_udp_rot_option_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var d = submit_to_undo_redo_manager(i, "udp_rot", Global.current_state, i.sprite_data["udp_rot"] , index)
			StateButton.multi_edit(i.sprite_data["udp_rot"], "udp_rot", i, i.states)
			i.sprite_data.udp_rot = index
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_udp_scale_option_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var d = submit_to_undo_redo_manager(i, "udp_scale", Global.current_state, i.sprite_data["udp_scale"] , index)
			StateButton.multi_edit(i.sprite_data["udp_scale"], "udp_scale", i, i.states)
			i.sprite_data.udp_scale = index
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_follow_eye_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var d = submit_to_undo_redo_manager(i, "follow_eye", Global.current_state, i.sprite_data["follow_eye"] , index)
			StateButton.multi_edit(i.sprite_data["follow_eye"], "follow_eye", i, i.states)
			i.sprite_data.follow_eye = index
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_follow_eye_gaze_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var d = submit_to_undo_redo_manager(i, "gaze_eye", Global.current_state, i.sprite_data["gaze_eye"] , index)
			StateButton.multi_edit(i.sprite_data["gaze_eye"], "gaze_eye", i, i.states)
			i.sprite_data.gaze_eye = index
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_eye_style_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var d = submit_to_undo_redo_manager(i, "style_eye", Global.current_state, i.sprite_data["style_eye"] , index)
			StateButton.multi_edit(i.sprite_data["style_eye"], "style_eye", i, i.states)
			i.sprite_data.style_eye = index
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func _on_mouth_follow_item_selected(index: int) -> void:
	if !should_change: return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			var d = submit_to_undo_redo_manager(i, "follow_mouth", Global.current_state, i.sprite_data["follow_mouth"] , index)
			StateButton.multi_edit(i.sprite_data["follow_mouth"], "follow_mouth", i, i.states)
			i.sprite_data.follow_mouth = index
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
	UndoRedoManager.push_data(undo_redo_data)

func submit_to_undo_redo_manager(node, action, state, value, new_value) -> Dictionary:
	var d = {
				node = node,
				action = action,
				state = state,
				value = value, 
				new_val =new_value
			}
	return d
