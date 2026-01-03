extends RefCounted
class_name UndoRedoManager

static var undo_data : Array = []
static var redo_data : Array = []

static func push_data(data : Variant = null):
	if data == null: return
	undo_data.append(data)
	#print(data)

static func undo():
	if undo_data.size() == 0:
		print("no data to undo")
		return
	
	var data = undo_data.pop_back()
	if data is Array:
		if data[0].has("node"):
			undo_action_object(data)
		elif data[0].has("layer"):
			undo_mesh_layer(data)
			
	elif data is Dictionary:
		if data.has("tree"):
			undo_tree(data)
		elif data.has("sprite_container"):
			undo_sprite_container(data)

static func redo():
	if redo_data.size() == 0:
		print("no data to redo")
		return
	
	var data = redo_data.pop_back() 
	if data is Array:
		if data[0].has("node"):
			redo_action_object(data)
		elif data[0].has("layer"):
			redo_mesh_layer(data)
	elif data is Dictionary:
		if data.has("tree"):
			redo_tree(data)
		elif data.has("sprite_container"):
			redo_sprite_container(data)

static func undo_action_object(data):
	for dt in data:
		if dt.node == null or !is_instance_valid(dt.node): continue
		if dt.node.get_value(dt.action) == null: continue
		if  dt.node.states.is_empty() : continue
		if  dt.node.states.size() >  dt.state:
			if Global.current_state ==  dt.state:
				dt.node.sprite_data[ dt.action] = dt.value
				dt.node.save_state( dt.state)
				dt.node.get_state(dt.state)
				Global.reinfo.emit()
			else:
				dt.node.states[dt.state][dt.action] = dt.value
	redo_data.append(data) 

static func redo_action_object(data):
	for dt in data:
		if dt.node == null or !is_instance_valid(dt.node): continue
		if dt.node.get_value(dt.action) == null: continue
		if  dt.node.states.is_empty() : continue
		if  dt.node.states.size() >  dt.state:
			if Global.current_state ==  dt.state:
				dt.node.sprite_data[ dt.action] = dt.new_val
				dt.node.save_state( dt.state)
				dt.node.get_state(dt.state)
				Global.reinfo.emit()
			else:
				dt.node.states[dt.state][dt.action] = dt.new_val
	undo_data.append(data) 

static func undo_tree(data):
	var item = data.item
	var old_parent = data.old_parent
	var old_index = data.old_index

	if not is_instance_valid(item) or not is_instance_valid(old_parent):
		return

	if item.get_parent():
		item.get_parent().remove_child(item)

	old_parent.add_child(item)
	item.move_after(old_parent.get_child(old_index))

	if old_parent == data.tree.get_root():
		item.get_metadata(0).sprite_object.parent_id = 0
		if item.get_metadata(0).sprite_object.get_parent() != Global.sprite_container:
			item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
			Global.sprite_container.add_child(item.get_metadata(0).sprite_object)
	else:
		if item.get_metadata(0).sprite_object.get_parent() != old_parent.get_metadata(0).sprite_object.get_node("%Sprite2D"):
			item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
			old_parent.get_metadata(0).sprite_object.get_node("%Sprite2D").add_child(item.get_metadata(0).sprite_object)
			item.get_metadata(0).sprite_object.parent_id = old_parent.get_metadata(0).sprite_object.sprite_id
	redo_data.append(data)
	Global.reinfo.emit()

static func redo_tree(data):
	var item = data.item
	var new_parent = data.new_parent
	var new_index = data.new_index
	if not is_instance_valid(item) or not is_instance_valid(new_parent):
		return
	if item.get_parent():
		item.get_parent().remove_child(item)
	new_parent.add_child(item)
	item.move_after(new_parent.get_child(new_index))
	if new_parent == data.tree.get_root():
		item.get_metadata(0).sprite_object.parent_id = 0
		if item.get_metadata(0).sprite_object.get_parent() != Global.sprite_container:
			item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
			Global.sprite_container.add_child(item.get_metadata(0).sprite_object)
	else:
		if item.get_metadata(0).sprite_object.get_parent() != new_parent.get_metadata(0).sprite_object.get_node("%Sprite2D"):
			item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
			new_parent.get_metadata(0).sprite_object.get_node("%Sprite2D").add_child(item.get_metadata(0).sprite_object)
			item.get_metadata(0).sprite_object.parent_id = new_parent.get_metadata(0).sprite_object.sprite_id
		
	undo_data.append(data)
	Global.reinfo.emit()

static func undo_sprite_container(data):
	match data.action:
		"bounce_state":
			if Global.current_state == data.state:
				data.sprite_container.bounce_state = data.value
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].bounce_state =  data.value
			
		"blink_chance":
			if Global.current_state == data.state:
				data.sprite_container.blink_chance = data.value
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].blink_chance =  data.value
			
		"should_squish":
			if Global.current_state == data.state:
				data.sprite_container.should_squish = data.value
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].should_squish =  data.value
		"blink_speed":
			Global.settings_dict.blink_speed = data.value
		"squish_amount":
			if Global.current_state == data.state:
				data.sprite_container.squish_amount = data.value
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].squish_amount =  data.value
		"current_mc_anim":
			if Global.current_state == data.state:
				data.sprite_container.current_mc_anim = data.value
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].current_mc_anim =  data.value
		"current_mo_anim":
			if Global.current_state == data.state:
				data.sprite_container.current_mo_anim = data.value
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].current_mo_anim =  data.value

static func redo_sprite_container(data):
	match data.action:
		"bounce_state":
			if Global.current_state == data.state:
				data.sprite_container.bounce_state = data.new_val
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].bounce_state =  data.new_val
			
		"blink_chance":
			if Global.current_state == data.state:
				data.sprite_container.blink_chance = data.new_val
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].blink_chance =  data.new_val
			
		"should_squish":
			if Global.current_state == data.state:
				data.sprite_container.should_squish = data.new_val
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].should_squish =  data.new_val
		"blink_speed":
			Global.settings_dict.blink_speed = data.new_val
		"squish_amount":
			if Global.current_state == data.state:
				data.sprite_container.squish_amount = data.new_val
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].squish_amount =  data.new_val
		"current_mc_anim":
			if Global.current_state == data.state:
				data.sprite_container.current_mc_anim = data.new_val
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].current_mc_anim =  data.new_val
		"current_mo_anim":
			if Global.current_state == data.state:
				data.sprite_container.current_mo_anim = data.new_val
				Global.sprite_container.save_state(Global.current_state)
				Global.reinfoanim.emit()
			else:
				if !Global.settings_dict.states.is_empty():
					if Global.settings_dict.states.size() > data.state:
						Global.settings_dict.states[data.state].current_mo_anim =  data.new_val

static func undo_mesh_layer(data):
	for lyr in data:
		if lyr.layer == null or !is_instance_valid(lyr.layer):
			continue
		
		match lyr.action:
			"stiffness":
				lyr.layer.stiffness = lyr.value
			"damping":
				lyr.layer.damping = lyr.value
			"mass":
				lyr.layer.mass = lyr.value
			"follow_lerp":
				lyr.layer.follow_lerp = lyr.value
			"noise_speed":
				lyr.layer.noise_speed = lyr.value
			"noise_scale":
				lyr.layer.noise_scale = lyr.value
			"sine_speed":
				lyr.layer.sine_speed = lyr.value
			"sine_amp":
				lyr.layer.sine_amplitude = lyr.value
			"motion":
				lyr.layer.motion = lyr.value
			"target_strength":
				lyr.layer.target_strength = lyr.value
			
	Global.reinfo.emit()

static func redo_mesh_layer(data):
	for lyr in data:
		if lyr.layer == null or !is_instance_valid(lyr.layer):
			continue
		
		match lyr.action:
			"stiffness":
				lyr.layer.stiffness = lyr.new_val
			"damping":
				lyr.layer.damping = lyr.new_val
			"mass":
				lyr.layer.mass = lyr.new_val
			"follow_lerp":
				lyr.layer.follow_lerp = lyr.new_val
			"noise_speed":
				lyr.layer.noise_speed = lyr.new_val
			"noise_scale":
				lyr.layer.noise_scale = lyr.new_val
			"sine_speed":
				lyr.layer.sine_speed = lyr.new_val
			"sine_amp":
				lyr.layer.sine_amplitude = lyr.new_val
			"motion":
				lyr.layer.motion = lyr.new_val
			"target_strength":
				lyr.layer.target_strength = lyr.new_val
			
	Global.reinfo.emit()
