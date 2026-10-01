extends Node

var should_change : bool = false
var undo_redo_data = []

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
	%SkewSpinXBox.editable = false
	%SkewSpinYBox.editable = false

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
			%SkewSpinXBox.editable = true
			%SkewSpinYBox.editable = true

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
		%SkewSpinXBox.value = i.get_value("skew").x
		%SkewSpinYBox.value = i.get_value("skew").y
		
		if i.get_node("%Sprite2D").get_clip_children_mode() == 0:
			%ClipChildren.button_pressed = false
		else:
			%ClipChildren.button_pressed = true
		
		%BlendMode.selected = %BlendMode.get_item_index(get_item_id_by_blend_mode(i.get_value("blend_mode")))
		
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


		%RestModeOption.select(%RestModeOption.get_item_index(i.rest_mode))
		if i.sprite_type == "Sprite2D":
			%FlipSpriteH.button_pressed = i.get_value("flip_sprite_h")
			%FlipSpriteV.button_pressed = i.get_value("flip_sprite_v")

		elif i.sprite_type == "WiggleApp":
			%FlipSpriteH.button_pressed = i.get_value("flip_h")
			%FlipSpriteV.button_pressed = i.get_value("flip_v")

	should_change = true

func get_item_id_by_blend_mode(blend_mode: String) -> int:
	match blend_mode:
		"Normal":
			return 0
		"Add":
			return 1
		"Subtract":
			return 2
		"Multiply":
			return 3
		"Burn":
			return 4
		"HardMix":
			return 5
		"Cursed":
			return 6
		"Masking":
			return 101
	return 0

func get_blend_mode_by_id(id) -> String:
	match id:
		0:
			return "Normal"
		1:
			return "Add"
		2:
			return "Subtract"
		3:
			return "Multiply"
		4:
			return "Burn"
		5:
			return "HardMix"
		6:
			return "Cursed"
		101:
			return "Masking"
	return "Normal"

func _on_blend_state_pressed(id):
	undo_redo_data = []
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "blend_mode", Global.current_state, i.sprite_data.blend_mode, get_blend_mode_by_id(id))
		i.sprite_data.blend_mode = get_blend_mode_by_id(id)
		StateButton.multi_edit(i.sprite_data.blend_mode, "blend_mode", i, i.states)
		
		i.set_blend(i.get_value("blend_mode"))
		i.save_state(Global.current_state)
		undo_redo_data.append(d)
		
	UndoRedoManager.push_data(undo_redo_data)

func update_pos_spins():
	var was_should_change = should_change
	should_change = false
	for i in Global.held_sprites:
		%PosXSpinBox.value = i.sprite_data.position.x
		%PosYSpinBox.value =i.sprite_data.position.y
		%RotSpinBox.value = rad_to_deg(i.sprite_data.rotation)
		i.save_state(Global.current_state)
	should_change = was_should_change
	
func update_offset():
	var was_should_change = should_change
	should_change = false
	for i in Global.held_sprites:
		%OffsetXSpinBox.value = i.get_value("offset").x
		%OffsetYSpinBox.value = i.get_value("offset").y
		update_pos_spins()
	should_change = was_should_change
	
func init_undo_on_focus(spin_box: SpinBox):
	if spin_box.get_line_edit().has_focus():
		undo_redo_data = [] # new undo_redo_data
		#print("init undo_redo: " + str(undo_redo_data))

func add_or_merge_undo_redo(spin_box: SpinBox, data):
	if spin_box.get_line_edit().has_focus():
		undo_redo_data.append(data)
	else:
		for i in undo_redo_data:
			if i.action == data.action:
				i.merge({new_val = data.new_val}, true)
	#print("modify undo_redo: " + str(undo_redo_data))

func push_undo_redo_on_focus(spin_box: SpinBox):
	if spin_box.get_line_edit().has_focus():
		UndoRedoManager.push_data(undo_redo_data)
		spin_box.get_line_edit().release_focus()
		
		print("push undo_redo: " + str(undo_redo_data))

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
			var d = submit_to_undo_redo_manager(i, "tint", Global.current_state, i.get_value("tint") , ncolor)
			i.sprite_data.tint = ncolor
			i.get_node("%Sprite2D").self_modulate = ncolor
			StateButton.multi_edit(ncolor, "tint", i, i.states)
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
		UndoRedoManager.push_data(undo_redo_data)

func _on_pos_x_spin_box_value_changed(value):
	if not should_change:
		return
	init_undo_on_focus(%PosXSpinBox)
	for i in Global.held_sprites:
		var snapped_value: float = value
		if Global.grid_snap:
			snapped_value = Global.snap_position(Vector2(value, 0.0)).x
		var d = submit_to_undo_redo_manager(i, "position", Global.current_state, i.position , Vector2(snapped_value,i.position.y))
		i.sprite_data.position.x = snapped_value
		i.position.x = snapped_value
		StateButton.multi_edit(snapped_value, "position", i, i.states, true, "x")
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%PosXSpinBox, d)

	push_undo_redo_on_focus(%PosXSpinBox)

func _on_pos_y_spin_box_value_changed(value):
	if not should_change:
		return
	init_undo_on_focus(%PosYSpinBox)
	for i in Global.held_sprites:
		var snapped_value: float = value
		if Global.grid_snap:
			snapped_value = Global.snap_position(Vector2(0.0, value)).y
		var d = submit_to_undo_redo_manager(i, "position", Global.current_state, i.position , Vector2(i.position.x,snapped_value))
		i.sprite_data.position.y = snapped_value
		i.position.y = snapped_value
		StateButton.multi_edit(snapped_value, "position", i, i.states, true, "y")
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%PosYSpinBox, d)

	push_undo_redo_on_focus(%PosYSpinBox)

func _on_rot_spin_box_value_changed(value):
	if not should_change:
		return
	init_undo_on_focus(%RotSpinBox)
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "rotation", Global.current_state, i.rotation , value)
		i.sprite_data.rotation = deg_to_rad(value)
		i.apply_transform()
		StateButton.multi_edit(i.sprite_data.rotation, "rotation", i, i.states)
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%RotSpinBox,d)
		
	push_undo_redo_on_focus(%RotSpinBox)

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
	if not should_change:
		return
	init_undo_on_focus(%ZOrderSpinbox)
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "z_index", Global.current_state, i.sprite_data.z_index , value)
		i.sprite_data.z_index = value
		StateButton.multi_edit(value, "z_index", i, i.states)
		i.get_node("%Modifier1").z_index = value
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%ZOrderSpinbox,d)
		
	push_undo_redo_on_focus(%ZOrderSpinbox)

func _on_size_spin_y_box_value_changed(value):
	if not should_change:
		return
	init_undo_on_focus(%SizeSpinYBox)
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "scale", Global.current_state, i.sprite_data.scale , Vector2(i.sprite_data.scale.x, value))
		i.sprite_data.scale.y = value
		i.apply_transform()
		StateButton.multi_edit(value, "scale", i, i.states, true, "y")
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%SizeSpinYBox,d)
		
	push_undo_redo_on_focus(%SizeSpinYBox)

func _on_size_spin_box_value_changed(value):
	if not should_change:
		return
	init_undo_on_focus(%SizeSpinBox)
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "scale", Global.current_state, i.sprite_data.scale , Vector2(value, i.sprite_data.scale.y))
		i.sprite_data.scale.x = value
		i.apply_transform()
		StateButton.multi_edit(value, "scale", i, i.states, true, "x")
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%SizeSpinBox,d)
		
	push_undo_redo_on_focus(%SizeSpinBox)
	
func _on_offset_y_spin_box_value_changed(value):
	if not should_change:
		return
	init_undo_on_focus(%OffsetYSpinBox)
	for i in Global.held_sprites:
		var of = i.get_value("offset").y - value
		var d = submit_to_undo_redo_manager(i, "offset", Global.current_state, i.sprite_data.offset , Vector2(i.sprite_data.offset.x, value))
		var d2 = submit_to_undo_redo_manager(i, "position", Global.current_state, i.sprite_data.position , Vector2(i.sprite_data.position.x, i.sprite_data.position.y +of))

		i.sprite_data.position.y += of
		i.position.y = i.get_value("position").y
		i.sprite_data.offset.y = value
		StateButton.multi_edit(i.sprite_data.position.y, "position", i, i.states, true, "y")
		StateButton.multi_edit(value, "offset", i, i.states, true, "y")
		i.get_node("%Sprite2D").position.y = i.get_value("offset").y
		i.save_state(Global.current_state)
		update_pos_spins()
		add_or_merge_undo_redo(%OffsetYSpinBox,d)
		add_or_merge_undo_redo(%OffsetYSpinBox,d2)
		
	push_undo_redo_on_focus(%OffsetYSpinBox)

func _on_offset_x_spin_box_value_changed(value):
	if not should_change:
		return
	init_undo_on_focus(%OffsetXSpinBox)
	for i in Global.held_sprites:
		var of = i.get_value("offset").x - value
		var d = submit_to_undo_redo_manager(i, "offset", Global.current_state, i.sprite_data.offset , Vector2(value,i.sprite_data.offset.y))
		var d2 = submit_to_undo_redo_manager(i, "position", Global.current_state, i.sprite_data.position , Vector2(i.sprite_data.position.x +of,i.sprite_data.position.y))
		
		i.sprite_data.position.x += of
		i.position.x = i.get_value("position").x
		i.sprite_data.offset.x = value
		StateButton.multi_edit(i.sprite_data.position.x, "position", i, i.states, true, "x")
		StateButton.multi_edit(value, "offset", i, i.states, true, "x")
		
		i.get_node("%Sprite2D").position.x = i.get_value("offset").x
		i.save_state(Global.current_state)
		update_pos_spins()
		add_or_merge_undo_redo(%OffsetXSpinBox,d)
		add_or_merge_undo_redo(%OffsetXSpinBox,d2)
		
	push_undo_redo_on_focus(%OffsetXSpinBox)

func _on_flip_sprite_h_toggled(toggled_on: bool) -> void:
	if should_change:
		undo_redo_data = []
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D" or  i.sprite_type == "Mesh":
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
		undo_redo_data = []
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D" or  i.sprite_type == "Mesh":
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
		undo_redo_data = []
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
		undo_redo_data = []
		for i in Global.held_sprites:
			var is_should_blink = i.sprite_data.should_blink
			var is_open_eyes = i.sprite_data.open_eyes
			match index:
				0:
					is_should_blink = false
				1:
					is_should_blink = true
					is_open_eyes = true
				2:
					is_should_blink = true
					is_open_eyes = false
			var d = submit_to_undo_redo_manager(i, "should_blink", Global.current_state, i.sprite_data.should_blink , is_should_blink)
			var d2 = submit_to_undo_redo_manager(i, "open_eyes", Global.current_state, i.sprite_data.open_eyes , is_open_eyes)
			i.sprite_data.should_blink = is_should_blink
			i.sprite_data.open_eyes = is_open_eyes
			StateButton.multi_edit(i.sprite_data.should_blink, "should_blink", i, i.states)
			StateButton.multi_edit(i.sprite_data.open_eyes, "open_eyes", i, i.states)
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
			undo_redo_data.append(d2)
		
		UndoRedoManager.push_data(undo_redo_data)
		Global.blink.emit()

func _on_mouth_option_item_selected(index: int) -> void:
	if should_change:
		undo_redo_data = []
		for i in Global.held_sprites:
			var is_should_talk = i.sprite_data.should_talk
			var is_open_mouth = i.sprite_data.open_mouth
			match index:
				0:
					is_should_talk = false
				1:
					is_should_talk = true
					is_open_mouth = true
				2:
					is_should_talk = true
					is_open_mouth = false
			var d = submit_to_undo_redo_manager(i, "should_talk", Global.current_state, i.sprite_data.should_talk , is_should_talk)
			var d2 = submit_to_undo_redo_manager(i, "open_mouth", Global.current_state, i.sprite_data.open_mouth , is_open_mouth)
			i.sprite_data.should_talk = is_should_talk
			i.sprite_data.open_mouth = is_open_mouth
			StateButton.multi_edit(i.sprite_data.should_talk, "should_talk", i, i.states)
			StateButton.multi_edit(i.sprite_data.open_mouth, "open_mouth", i, i.states)
			i.save_state(Global.current_state)
			undo_redo_data.append(d)
			undo_redo_data.append(d2)
		
		UndoRedoManager.push_data(undo_redo_data)
		Global.not_speaking.emit()

func _on_rest_mode_option_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		i.rest_mode = %RestModeOption.get_item_id(index)
		i.save_state(Global.current_state)

func _on_skew_spin_x_box_value_changed(value: float) -> void:
	if not should_change:
		return
	init_undo_on_focus(%SkewSpinXBox)
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "skew", Global.current_state, i.sprite_data.skew, Vector2(value, i.sprite_data.skew.y))
		i.sprite_data.skew.x = value
		i.apply_transform()
		StateButton.multi_edit(value, "skew", i, i.states, true, "x")
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%SkewSpinXBox,d)
		
	push_undo_redo_on_focus(%SkewSpinXBox)


func _on_skew_spin_y_box_value_changed(value: float) -> void:
	if not should_change:
		return
	init_undo_on_focus(%SkewSpinYBox)
	for i in Global.held_sprites:
		var d = submit_to_undo_redo_manager(i, "skew", Global.current_state, i.sprite_data.skew, Vector2(i.sprite_data.skew.x, value))
		i.sprite_data.skew.y = value
		i.apply_transform()
		StateButton.multi_edit(value, "skew", i, i.states, true, "y")
		i.save_state(Global.current_state)
		add_or_merge_undo_redo(%SkewSpinYBox,d)
		
	push_undo_redo_on_focus(%SkewSpinYBox)

func submit_to_undo_redo_manager(node, action, state, value, new_value) -> Dictionary:
	var d = {
				node = node,
				action = action,
				state = state,
				value = value,
				new_val =new_value
			}
	return d
