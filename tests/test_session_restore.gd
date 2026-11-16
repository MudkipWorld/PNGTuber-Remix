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
