extends RefCounted
class_name SessionRestore

## macOS rules that make the app reopen where it was left: the last saved or
## opened model loads on start, and the model is saved when the window closes.
## Windows and Linux keep their current behavior.

## Marks that the macOS defaults were applied once, so later choices are kept.
const MACOS_DEFAULTS_KEY := "macos_restore_defaults_applied"

## Turns on Auto Load and Save on Exit the first time the app runs on macOS,
## for new and existing users. Returns true when `settings` changed.
static func apply_platform_defaults(settings: Dictionary, is_macos: bool) -> bool:
	if !is_macos or settings.get(MACOS_DEFAULTS_KEY, false):
		return false
	settings.auto_load = true
	settings.save_on_exit = true
	settings[MACOS_DEFAULTS_KEY] = true
	return true

## Whether saving a model also makes it the one Auto Load opens.
static func remembers_saved_model(is_macos: bool) -> bool:
	return is_macos

## Whether closing the window runs the Save on Exit flow.
static func saves_on_close(is_macos: bool) -> bool:
	return is_macos

## Copies the model file to `backups_dir` as "<name>_previous.<ext>" before it
## is overwritten on close, so the last saved version can still be recovered.
## Returns the copy's path, or "" when there is no model file to copy.
static func keep_previous_version(model_path: String, backups_dir: String) -> String:
	if model_path == "" or !FileAccess.file_exists(model_path):
		return ""
	DirAccess.make_dir_recursive_absolute(backups_dir)
	var name := model_path.get_file().get_basename() + "_previous." + model_path.get_extension()
	var copy_path := backups_dir.path_join(name)
	if DirAccess.copy_absolute(model_path, copy_path) != OK:
		push_error("SessionRestore: failed to keep the previous version at %s" % copy_path)
		return ""
	return copy_path
