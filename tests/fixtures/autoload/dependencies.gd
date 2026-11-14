extends Node

signal new_file
signal deselect

var swtich_session_popup
var save_path := ""
var main
var current_theme := Theme.new()
var theme_settings := {"auto_load": false, "path": "", "session": 0}
var loaded_paths: Array[String] = []

func load_file(path: String) -> void:
	loaded_paths.append(path)

func save_file(_path: String) -> void:
	pass

func start_hook() -> void:
	pass

func stop_hook() -> void:
	pass

func update_tracking_backend() -> void:
	pass
