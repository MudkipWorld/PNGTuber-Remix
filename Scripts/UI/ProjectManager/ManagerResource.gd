extends Resource
class_name ProjectManagerResource

enum FileImportType {
	Remix,
	Project,
}


@export var project_name : String = "Untitled"
@export var path : String = ""
var icon = null
var type : FileImportType = FileImportType.Remix
