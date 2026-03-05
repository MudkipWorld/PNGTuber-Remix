extends Control

enum FileType {
	None,
	Import,
	Open,
}

var project_sel = preload("res://Scripts/UI/ProjectManager/project_selector.gd")
var current_type : FileType = FileType.None
var placeholder_path : String = ""

func _ready() -> void:
	await get_tree().physics_frame
	update_theme(Settings.current_theme)

func update_theme(new_theme : Theme = preload("res://Themes/PurpleTheme/GUITheme.tres")):
	theme = new_theme

func _on_import_project_pressed() -> void:
	%FileDialog.filters = ["*.pngRemix", "*.remixProj"]
	%FileDialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	%FileDialog.popup()

func _on_create_project_pressed() -> void:
	%FileDialog.filters = []
	%FileDialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_DIR
	%FileDialog.popup()

func _on_open_project_pressed() -> void:
	pass # Replace with function body.

func _on_rename_project_pressed() -> void:
	%Rename.text = ProjectManager.selected_project_data.project_name
	%RenamePopup.popup()

func _on_delete_project_pressed() -> void:
	ProjectManager.delete_project_from_list(ProjectManager.selected_project_node, ProjectManager.selected_project_data)
	check_data()

func _on_file_dialog_file_selected(path: String) -> void:
	print(path)
	var dir = path.get_base_dir()
	print(dir)
	var new_data = ProjectManagerResource.new()
	new_data.type = ProjectManagerResource.FileImportType.Remix
	new_data.path = dir
	new_data.project_name = path.get_file().get_basename()
	var spawn = project_sel.instantiate()
	spawn.main_ui = self
	spawn.data = new_data
	%ProjectHolder.add_child(spawn)
	spawn.update_data()
	
func _on_file_dialog_dir_selected(dir: String) -> void:
	%CreateName.text = "Untitled"
	%ProjectPath.text = dir
	placeholder_path = dir
	%NewProjectPopup.popup()

func _on_open_demo_pressed() -> void:
	pass # Replace with function body.

func check_data():
	if ProjectManager.selected_project_data != null &&is_instance_valid(ProjectManager.selected_project_data):
		%OpenProject.disabled = false
		%RenameProject.disabled = false
		%DeleteProject.disabled = false
		if ProjectManager.selected_project_data.type == ProjectManagerResource.FileImportType.Remix:
			%ConvertProject.disabled = false
		else:
			%ConvertProject.disabled = true
	else:
		%OpenProject.disabled = true
		%RenameProject.disabled = true
		%DeleteProject.disabled = true
		%ConvertProject.disabled = true

func _on_convert_project_pressed() -> void:
	pass # Replace with function body.

func _on_rename_text_submitted(new_text: String) -> void:
	ProjectManager.rename_project(ProjectManager.selected_project_node, new_text,ProjectManager.selected_project_data)

func _on_new_project_popup_confirmed() -> void:
	if !%CreateName.text.is_empty() && !ProjectManager.check_path(placeholder_path.path_join(%CreateName.text)):
		%NewProjectPopup.hide()
		create_new(placeholder_path)
		placeholder_path = ""

func create_new(dir : String):
	print(dir)
	var new_data = ProjectManagerResource.new()
	new_data.type = ProjectManagerResource.FileImportType.Project
	new_data.project_name = %CreateName.text
	new_data.path = dir.path_join(new_data.project_name)
	ProjectManager.projects.append(new_data)
	var spawn = project_sel.instantiate()
	spawn.main_ui = self
	spawn.data = new_data
	%ProjectHolder.add_child(spawn)
	spawn.update_data()

func _on_new_project_popup_close_requested() -> void:
	%NewProjectPopup.hide()
	placeholder_path = ""
