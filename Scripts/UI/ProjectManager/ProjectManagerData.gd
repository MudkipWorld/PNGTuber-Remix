extends RefCounted
class_name ProjectManager

static var projects : Array[ProjectManagerResource] = []
static var selected_project_data : ProjectManagerResource = null
static var selected_project_node : ProjectSelector = null

static func create_project_from_data(path : String) -> String:
	
	return ""

static func rename_project(node, new_name : String, data : ProjectManagerResource):
	if data != null && is_instance_valid(data):
		data.project_name = new_name
		node.update_data()
	else:
		return

static func delete_project_from_list(node, data : ProjectManagerResource):
	if data in projects:
		projects.erase(data)
		
	data.free()
	if node != null && is_instance_valid(node):
		node.queue_free()
	return

static func import_project(path : String) -> ProjectManagerResource:
	for i in projects:
		if i.path == path:
			print("Path already exists.")
			return
	
	return ProjectManagerResource.new()

static func create_project_files(path : String):
	pass


static func check_path(path : String) -> bool:
	return DirAccess.dir_exists_absolute(path)
