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
		if data.has("sprite_holder"):
			pass

static func redo():
	if redo_data.size() == 0:
		print("no data to redo")
		return
	
	var data = redo_data.pop_back() 
	if data is Array:
		if data[0].has("node"):
			redo_action_object(data)
	elif data is Dictionary:
		if data.has("sprite_holder"):
			pass

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
