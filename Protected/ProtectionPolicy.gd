extends Node

func is_player() -> bool:
	return OS.has_feature("protected_player") or ProjectSettings.get_setting("protected/player", false)

func allows(action: String) -> bool:
	if action in ["edit_model", "import_assets", "export_assets", "save_model", "backup_model", "remote_control"]:
		return not is_player()
	return false
