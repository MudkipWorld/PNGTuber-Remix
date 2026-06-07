extends PanelContainer
class_name ProjectSelector

var data : ProjectManagerResource = null
var main_ui : Node = null


func update_data():
	if data != null && is_instance_valid(data):
		%ProjectName.text = data.project_name
		%ProjectPath.text = data.path
		if data.type == ProjectManagerResource.FileImportType.Remix:
			%ProjectType.text = "Portable"
		else:
			%ProjectType.text = "Project"
		
		if data.icon != null:
			%ProjectIcon.texture = data.icon
		
	else:
		queue_free()

func _on_selection_pressed() -> void:
	if ProjectManager.selected_project_node != null &&is_instance_valid(ProjectManager.selected_project_node):
		ProjectManager.selected_project_node.deselect()
	ProjectManager.selected_project_node = self
	ProjectManager.selected_project_data = data
	main_ui.check_data()

func deselect():
	$Selection.release_focus()
