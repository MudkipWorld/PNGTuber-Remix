extends RefCounted
class_name UndoRedoManager

static var undo_data : Array = []
static var redo_data : Array = []

static func push_data(data : Variant = null):
	if data == null: return
	undo_data.append(data)

static func undo():
	if undo_data.size() == 0:
		print("no data to undo")
		return
	
	var data = undo_data.pop_back()
	if data is Array:
		if data[0].has("node"):
			undo_action_object(data)
	elif data is Dictionary:
		if data.has("tree"):
			undo_tree(data)

static func redo():
	if redo_data.size() == 0:
		print("no data to redo")
		return
	
	var data = redo_data.pop_back() 
	if data is Array:
		if data[0].has("node"):
			redo_action_object(data)
	elif data is Dictionary:
		if data.has("tree"):
			redo_tree(data)

static func undo_action_object(data):
	for dt in data:
		if dt.node == null or !is_instance_valid(dt.node): continue
		if dt.node.get_value(dt.action) == null: continue
		if  dt.node.states.size() >  dt.state:
			if Global.current_state ==  dt.state:
				dt.node.sprite_data[ dt.action] = dt.value
				dt.node.save_state( dt.state)
				dt.get_state(dt.state)
				Global.reinfo.emit()
			else:
				dt.node.states[dt.state][dt.action] = dt.value
	redo_data.append(data) 

static func redo_action_object(data):
	for dt in data:
		if dt.node == null or !is_instance_valid(dt.node): continue
		if dt.node.get_value(dt.action) == null: continue
		if  dt.node.states.size() >  dt.state:
			if Global.current_state ==  dt.state:
				dt.node.sprite_data[ dt.action] = dt.new_val
				dt.node.save_state( dt.state)
				dt.get_state(dt.state)
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
