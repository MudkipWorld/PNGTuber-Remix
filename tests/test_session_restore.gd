extends SceneTree

## Checks the macOS rules that make the app reopen where it was left.
##
## Run from the project folder:
##   godot --headless --path . --script res://tests/test_session_restore.gd
## The process exits with code 1 when any check fails.

const Restore = preload("res://Main/Scripts/session_restore.gd")

var failures := 0


func _initialize() -> void:
	test_macos_turns_on_restore_for_new_and_existing_users()
	test_macos_keeps_the_user_choice_after_the_first_time()
	test_other_platforms_keep_their_settings()
	test_macos_remembers_the_saved_model()
	test_macos_saves_when_the_window_closes()
	test_previous_version_is_kept_before_overwriting()
	test_previous_version_replaces_the_older_copy()
	test_nothing_is_copied_without_a_model_file()

	remove_temp_dir()

	if failures > 0:
		printerr("%d check(s) failed" % failures)
	else:
		print("All checks passed")
	quit(1 if failures > 0 else 0)


func check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		failures += 1
		printerr("  FAIL ", description)


func default_settings() -> Dictionary:
	return {auto_load = false, save_on_exit = false, path = ""}


func test_macos_turns_on_restore_for_new_and_existing_users() -> void:
	var settings := default_settings()
	var changed := Restore.apply_platform_defaults(settings, true)
	check(changed, "macOS: the first run reports a change so it gets saved")
	check(settings.auto_load, "macOS: Auto Load is turned on")
	check(settings.save_on_exit, "macOS: Save on Exit is turned on")


func test_macos_keeps_the_user_choice_after_the_first_time() -> void:
	var settings := default_settings()
	Restore.apply_platform_defaults(settings, true)
	settings.auto_load = false
	settings.save_on_exit = false
	var changed := Restore.apply_platform_defaults(settings, true)
	check(!changed and !settings.auto_load and !settings.save_on_exit,
		"macOS: turning the options off later is respected")


func test_other_platforms_keep_their_settings() -> void:
	var settings := default_settings()
	var changed := Restore.apply_platform_defaults(settings, false)
	check(!changed and settings == default_settings(),
		"Windows/Linux: settings are left untouched")


func test_macos_remembers_the_saved_model() -> void:
	check(Restore.remembers_saved_model(true), "macOS: saving a model makes it the one that opens next time")
	check(!Restore.remembers_saved_model(false), "Windows/Linux: saving keeps the current behavior")


func test_macos_saves_when_the_window_closes() -> void:
	check(Restore.saves_on_close(true), "macOS: closing the window runs Save on Exit")
	check(!Restore.saves_on_close(false), "Windows/Linux: closing keeps the current behavior")


func temp_dir() -> String:
	var dir := OS.get_temp_dir().path_join("pngremix_session_restore_test")
	DirAccess.make_dir_recursive_absolute(dir)
	return dir


func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_previous_version_is_kept_before_overwriting() -> void:
	var dir := temp_dir()
	var model := dir.path_join("Texa.pngRemix")
	var backups := dir.path_join("backups")
	write_text(model, "model as it was")
	var copy := Restore.keep_previous_version(model, backups)
	check(copy == backups.path_join("Texa_previous.pngRemix"),
		"the previous version goes to backups as <name>_previous (got %s)" % copy)
	check(FileAccess.get_file_as_string(copy) == "model as it was",
		"the copy has the content the model had before saving")


func test_previous_version_replaces_the_older_copy() -> void:
	var dir := temp_dir()
	var model := dir.path_join("Texa.pngRemix")
	var backups := dir.path_join("backups")
	write_text(model, "first")
	Restore.keep_previous_version(model, backups)
	write_text(model, "second")
	var copy := Restore.keep_previous_version(model, backups)
	check(FileAccess.get_file_as_string(copy) == "second",
		"only the latest previous version is kept")


func test_nothing_is_copied_without_a_model_file() -> void:
	var dir := temp_dir()
	var copy := Restore.keep_previous_version(dir.path_join("missing.pngRemix"), dir.path_join("backups"))
	check(copy == "", "with no model file there is nothing to copy")


func remove_temp_dir() -> void:
	var dir := temp_dir()
	for sub in [dir.path_join("backups"), dir]:
		for file in DirAccess.get_files_at(sub):
			DirAccess.remove_absolute(sub.path_join(file))
		DirAccess.remove_absolute(sub)
