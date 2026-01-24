extends Node

var should_change : bool = false

func _ready() -> void:
	%ColorPickerButton.get_picker().picker_shape = 1
	%ColorPickerButton.get_picker().presets_visible = false
	%ColorPickerButton.get_picker().color_modes_visible = false
	%BlendMode.get_popup().id_pressed.connect(_on_blend_state_pressed)
	
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	Global.update_offset_spins.connect(update_offset)
	Global.update_pos_spins.connect(update_pos_spins)
	nullfy()

func nullfy():
	if %PosXSpinBox.value_changed.is_connected(_on_pos_x_spin_box_value_changed):
		%PosXSpinBox.value_changed.disconnect(_on_pos_x_spin_box_value_changed)
		%PosYSpinBox.value_changed.disconnect(_on_pos_y_spin_box_value_changed)
		%RotSpinBox.value_changed.disconnect(_on_rot_spin_box_value_changed)
	%TintPickerButton.disabled = true
	%ColorPickerButton.disabled = true

	%EyeOption.disabled = true
	%MouthOption.disabled = true
	%SizeSpinBox.editable = false
	%SizeSpinYBox.editable = false

	%PosXSpinBox.editable = false
	%PosYSpinBox.editable = false
	%RotSpinBox.editable = false
	%RotSpinBox.editable = false
	%BlendMode.disabled = true
	%ClipChildren.disabled = true
	%Visible.disabled = true
	%ZOrderSpinbox.editable = false

	%OffsetXSpinBox.editable = false
	%OffsetYSpinBox.editable = false
	%FlipSpriteH.disabled = true
	%FlipSpriteV.disabled = true
	%RestModeOption.disabled = true

func enable():
	var seen_comment : bool = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "Comment":
				seen_comment = true
			
			%TintPickerButton.disabled = false
			%ColorPickerButton.disabled = false
			%EyeOption.disabled = false
			%MouthOption.disabled = false
			%SizeSpinBox.editable = true
			%SizeSpinYBox.editable = true

			%PosXSpinBox.editable = true
			%PosYSpinBox.editable = true
			%RotSpinBox.editable = true
			%RotSpinBox.editable = true
			%BlendMode.disabled = false
			%ClipChildren.disabled = false
			%Visible.disabled = false
			%ZOrderSpinbox.editable = true
			%EyeOption.disabled = false
			%MouthOption.disabled = false
			
			%OffsetXSpinBox.editable = true
			%OffsetYSpinBox.editable = true
			if !seen_comment:
				%FlipSpriteH.disabled = false
				%FlipSpriteV.disabled = false
			else:
				%FlipSpriteH.disabled = true
				%FlipSpriteV.disabled = true
			%RestModeOption.disabled = false
			
			set_data()

func set_data():
	should_change = false
	for i in Global.held_sprites:
		%ColorPickerButton.color = i.get_value("colored")
		%TintPickerButton.color = i.get_value("tint")
		%Visible.button_pressed = i.get_value("visible")
		%ZOrderSpinbox.value = i.get_value("z_index")
		%SizeSpinBox.value = i.get_value("scale").x
		%SizeSpinYBox.value = i.get_value("scale").y
		
		if i.get_node("%Sprite2D").get_clip_children_mode() == 0:
			%ClipChildren.button_pressed = false
		else:
			%ClipChildren.button_pressed = true
			
		%BlendMode.text = i.get_value("blend_mode")
		%OffsetXSpinBox.value = i.get_value("offset").x
		%OffsetYSpinBox.value = i.get_value("offset").y
		
		%PosXSpinBox.value = i.get_value("position").x
		%PosYSpinBox.value = i.get_value("position").y
		%RotSpinBox.value = i.get_value("rotation") / 0.01745
		
		if !%PosXSpinBox.value_changed.is_connected(_on_pos_x_spin_box_value_changed):
			%PosXSpinBox.value_changed.connect(_on_pos_x_spin_box_value_changed)
			%PosYSpinBox.value_changed.connect(_on_pos_y_spin_box_value_changed)
			%RotSpinBox.value_changed.connect(_on_rot_spin_box_value_changed)
		
		if i.get_value("should_blink"):
			if i.get_value("open_eyes"):
				%EyeOption.select(1)
			else:
				%EyeOption.select(2)
		else:
			%EyeOption.select(0)
		
		if i.get_value("should_talk"):
			if i.get_value("open_mouth"):
				%MouthOption.select(1)
			else:
				%MouthOption.select(2)
		else:
			%MouthOption.select(0)
		
		
		%RestModeOption.select(i.rest_mode)
		if i.sprite_type == "Sprite2D":
			%FlipSpriteH.button_pressed = i.get_value("flip_sprite_h")
			%FlipSpriteV.button_pressed = i.get_value("flip_sprite_v")
		
		elif i.sprite_type == "WiggleApp":
			%FlipSpriteH.button_pressed = i.get_value("flip_h")
			%FlipSpriteV.button_pressed = i.get_value("flip_v")

		
	should_change = true

func _on_blend_state_pressed(id):
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		var og_val = i.sprite_data.blend_mode 
		match id:
			0:
				i.sprite_data.blend_mode = "Normal"
			1:
				i.sprite_data.blend_mode = "Add"
			2:
				i.sprite_data.blend_mode = "Subtract"
			3:
				i.sprite_data.blend_mode = "Multiply"
				
			4:
				i.sprite_data.blend_mode = "Burn"
				
			5:
				i.sprite_data.blend_mode = "HardMix"
				
			6:
				i.sprite_data.blend_mode = "Cursed"
		undo_redo_data.append({
				node = i,
				action = "blend_mode",
				state = Global.current_state,
				value = og_val, 
				new_val = i.sprite_data.blend_mode 
			})
		StateButton.multi_edit(i.sprite_data.blend_mode, "blend_mode", i, i.states)
		%BlendMode.text = i.get_value("blend_mode")
		i.set_blend(i.get_value("blend_mode"))
		i.save_state(Global.current_state)
	UndoRedoManager.push_data(undo_redo_data)

func update_pos_spins():
	for i in Global.held_sprites:
		%PosXSpinBox.value = i.position.x
		%PosYSpinBox.value = i.position.y
		%RotSpinBox.value = i.rotation / 0.01745
		i.save_state(Global.current_state)

func update_offset():
	for i in Global.held_sprites:
		%OffsetXSpinBox.value = i.get_value("offset").x
		%OffsetYSpinBox.value = i.get_value("offset").y
		update_pos_spins()

func _on_color_picker_button_color_changed(color: Color) -> void:
	if should_change:
		var undo_redo_data : Array = []
		for i in Global.held_sprites:
			var d = submit_to_undo_redo_manager(i, "modulate", Global.current_state, i.sprite_data.colored , color)
			i.modulate = color
			i.sprite_data.colored = color
			StateButton.multi_edit(color, "modulate", i, i.states)
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
		UndoRedoManager.push_data(undo_redo_data)

func _on_color_picker_button_focus_entered() -> void:
	Global.spinbox_held = true

func _on_color_picker_button_focus_exited() -> void:
	Global.spinbox_held = false

func _on_tint_picker_button_color_changed(ncolor: Color) -> void:
	if should_change:
		var undo_redo_data : Array = []
		for i in Global.held_sprites:
			var d = submit_to_undo_redo_manager(i, "tint", Global.current_state, i.sprite_data.tint , ncolor)
			i.sprite_data.tint = ncolor
			i.get_node("%Sprite2D").self_modulate = ncolor
			StateButton.multi_edit(ncolor, "tint", i, i.states)
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
		UndoRedoManager.push_data(undo_redo_data)

func _on_pos_x_spin_box_value_changed(value):
	if %PosXSpinBox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "position", Global.current_state, i.position , Vector2(value,i.position.y))
				i.sprite_data.position.x = value
				i.position.x = value
				StateButton.multi_edit(value, "position", i, i.states, true, "x")
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)

func _on_pos_y_spin_box_value_changed(value):
	if %PosYSpinBox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "position", Global.current_state, i.position , Vector2(i.position.x,value))
				i.sprite_data.position.y = value
				i.position.y = value
				StateButton.multi_edit(value, "position", i, i.states, true, "y")
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)

func _on_rot_spin_box_value_changed(value):
	if %RotSpinBox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "rotation", Global.current_state, i.rotation , value)
				i.rotation = value * 0.01745
				i.sprite_data.rotation = value * 0.01745
				StateButton.multi_edit(i.sprite_data.rotation, "rotation", i, i.states)
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)

func _on_visible_toggled(toggled_on):
	if should_change:
		var undo_redo_data : Array = []
		for i in Global.held_sprites:
			var d = submit_to_undo_redo_manager(i, "visible", Global.current_state, i.sprite_data.visible , toggled_on)
			if toggled_on:
				i.sprite_data.visible = true
				i.visible = true
				i.treeitem.set_button(0, 0, preload("res://UI/Assets/EyeButton.png"))
			else:
				i.sprite_data.visible = false
				i.visible = false
				i.treeitem.set_button(0, 0, preload("res://UI/Assets/EyeButton2.png"))
			
			StateButton.multi_edit(i.sprite_data.visible, "visible", i, i.states)
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
		UndoRedoManager.push_data(undo_redo_data)

func _on_z_order_spinbox_value_changed(value):
	if %ZOrderSpinbox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "z_index", Global.current_state, i.sprite_data.z_index , value)
				i.sprite_data.z_index = value
				StateButton.multi_edit(value, "z_index", i, i.states)
				i.get_node("%Modifier1").z_index = value
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)

func _on_size_spin_y_box_value_changed(value):
	if %SizeSpinYBox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "scale", Global.current_state, i.sprite_data.scale , Vector2(i.sprite_data.scale.x, value))
				i.sprite_data.scale.y = value
				i.scale.y = value
				StateButton.multi_edit(value, "scale", i, i.states, true, )
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)

func _on_size_spin_box_value_changed(value):
	if %SizeSpinBox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "scale", Global.current_state, i.sprite_data.scale , Vector2(value, i.sprite_data.scale.y))
				i.sprite_data.scale.x = value
				i.scale.x = value
				StateButton.multi_edit(value, "scale", i, i.states, true, "x")
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)

func _on_offset_y_spin_box_value_changed(value):
	if %OffsetYSpinBox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "offset", Global.current_state, i.sprite_data.offset , Vector2(i.sprite_data.offset.x, value))
				var of = i.get_value("offset").y - value
				i.sprite_data.position.y += of
				i.position.y = i.get_value("position").y
				i.sprite_data.offset.y = value
				StateButton.multi_edit(i.sprite_data.position.y, "position", i, i.states, true, "y")
				StateButton.multi_edit(value, "offset", i, i.states, true, "y")
				i.get_node("%Sprite2D").position.y = i.get_value("offset").y
				i.save_state(Global.current_state)
				update_pos_spins()
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)

func _on_offset_x_spin_box_value_changed(value):
	if %OffsetXSpinBox.get_line_edit().has_focus():
		if should_change:
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var d = submit_to_undo_redo_manager(i, "offset", Global.current_state, i.sprite_data.offset , Vector2(value,i.sprite_data.offset.y))
				var of = i.get_value("offset").x - value
				i.sprite_data.position.x += of
				i.position.x = i.get_value("position").x
				i.sprite_data.offset.x = value
				StateButton.multi_edit(i.sprite_data.position.x, "position", i, i.states, true, "x")
				StateButton.multi_edit(value, "offset", i, i.states, true, "x")
				
				i.get_node("%Sprite2D").position.x = i.get_value("offset").x
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			UndoRedoManager.push_data(undo_redo_data)
			
		update_pos_spins()

func _on_flip_sprite_h_toggled(toggled_on: bool) -> void:
	if should_change:
		var undo_redo_data : Array = []
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				var d = submit_to_undo_redo_manager(i, "flip_sprite_h", Global.current_state, i.sprite_data.flip_sprite_h , toggled_on)
				i.sprite_data.flip_sprite_h = toggled_on
				if i.get_value("flip_sprite_h"):
					i.get_node("%Sprite2D").scale.x = -1
				else:
					i.get_node("%Sprite2D").scale.x = 1
				
				StateButton.multi_edit(toggled_on, "flip_sprite_h", i, i.states)
				undo_redo_data.append(d)
				i.save_state(Global.current_state)
			elif i.sprite_type == "WiggleApp":
				var d = submit_to_undo_redo_manager(i, "flip_h", Global.current_state, i.sprite_data.flip_h , toggled_on)
				i.sprite_data.flip_h = toggled_on
				if i.get_value("flip_h"):
					i.get_node("%Sprite2D").scale.x = -1
				else:
					i.get_node("%Sprite2D").scale.x = 1
				StateButton.multi_edit(toggled_on, "flip_h", i, i.states)
				undo_redo_data.append(d)
				i.save_state(Global.current_state)
		UndoRedoManager.push_data(undo_redo_data)

func _on_flip_sprite_v_toggled(toggled_on: bool) -> void:
	if should_change:
		var undo_redo_data : Array = []
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				var d = submit_to_undo_redo_manager(i, "flip_sprite_v", Global.current_state, i.sprite_data.flip_sprite_h , toggled_on)
				i.sprite_data.flip_sprite_v = toggled_on
				if i.get_value("flip_sprite_v"):
					i.get_node("%Sprite2D").scale.y = -1
				else:
					i.get_node("%Sprite2D").scale.y = 1
				StateButton.multi_edit(toggled_on, "flip_sprite_v", i, i.states)
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
				
			elif i.sprite_type == "WiggleApp":
				var d = submit_to_undo_redo_manager(i, "flip_v", Global.current_state, i.sprite_data.flip_h , toggled_on)
				i.sprite_data.flip_v = toggled_on
				if i.get_value("flip_v"):
					i.get_node("%Sprite2D").scale.y = -1
				else:
					i.get_node("%Sprite2D").scale.y = 1
				StateButton.multi_edit(toggled_on, "flip_v", i, i.states)
				i.save_state(Global.current_state)
				undo_redo_data.append(d)
			
		UndoRedoManager.push_data(undo_redo_data)

func _on_clip_children_toggled(toggled_on: bool) -> void:
	if should_change:
		var undo_redo_data : Array = []
		for i in Global.held_sprites:
			var t = 0
			if toggled_on:
				i.get_node("%Sprite2D").set_clip_children_mode(2)
				t = 2
			else:
				i.get_node("%Sprite2D").set_clip_children_mode(0)
				t = 0
			var d = submit_to_undo_redo_manager(i, "clip", Global.current_state,i.sprite_data.clip , t)
			i.sprite_data.clip = t
			StateButton.multi_edit(i.sprite_data.clip, "clip", i, i.states)
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
		UndoRedoManager.push_data(undo_redo_data)

func _on_eye_option_item_selected(index: int) -> void:
	if should_change:
		var _undo_redo_data : Array = []
		for i in Global.held_sprites:
			match index:
				0:
					i.sprite_data.should_blink = false
				1:
					i.sprite_data.should_blink = true
					i.sprite_data.open_eyes = true
				2:
					i.sprite_data.should_blink = true
					i.sprite_data.open_eyes = false
				
			StateButton.multi_edit(i.sprite_data.should_blink, "should_blink", i, i.states)
			StateButton.multi_edit(i.sprite_data.open_eyes, "open_eyes", i, i.states)
			
		
		Global.blink.emit()

func _on_mouth_option_item_selected(index: int) -> void:
	if should_change:
		var _undo_redo_data : Array = []
		for i in Global.held_sprites:
			match index:
				0:
					i.sprite_data.should_talk = false
				1:
					i.sprite_data.should_talk = true
					i.sprite_data.open_mouth = true
				2:
					i.sprite_data.should_talk = true
					i.sprite_data.open_mouth = false
			StateButton.multi_edit(i.sprite_data.should_talk, "should_talk", i, i.states)
			StateButton.multi_edit(i.sprite_data.open_mouth, "open_mouth", i, i.states)
		Global.not_speaking.emit()

func _on_rest_mode_option_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		i.rest_mode = index

func submit_to_undo_redo_manager(node, action, state, value, new_value) -> Dictionary:
	var d = {
				node = node,
				action = action,
				state = state,
				value = value, 
				new_val =new_value
			}
	return d
