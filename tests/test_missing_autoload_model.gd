extends Node

class TestMenu:
	extends "res://Scripts/UI/Menu/menu.gd"
	func _ready() -> void:
		pass # Exercise auto_load_model without starting the rest of the app.

var failures := 0
var loader: Node
@onready var root: Window = get_tree().root

func _ready() -> void:
	call_deferred("run_tests")

func check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		failures += 1
		printerr("  FAIL ", description)

func run_tests() -> void:
	loader = root.get_node("SaveAndLoad")
	root.gui_embed_subwindows = true
	# The headless display server otherwise starts with a 64x64 window.
	root.size = Vector2i(1280, 720)
	install_translation()
	var existing_path := "user://autoload-existing.pngRemix"
	var file := FileAccess.open(existing_path, FileAccess.WRITE)
	file.store_string("Fixture: the loader call is observed, model decoding is not under test.")
	file.close()
	var missing_path := "user://moved or deleted model.pngRemix"
	if FileAccess.file_exists(missing_path):
		DirAccess.remove_absolute(missing_path)

	var menu := TestMenu.new()
	root.add_child(menu)
	Settings.theme_settings = {"auto_load": false, "path": missing_path, "session": 0}
	await menu.auto_load_model()
	check(loader.get("loaded_paths").is_empty() and find_warning(menu) == null, "disabled auto-load neither loads nor warns about a missing path")
	Settings.theme_settings.auto_load = true
	Settings.theme_settings.path = ""
	await menu.auto_load_model()
	check(loader.get("loaded_paths").is_empty() and find_warning(menu) == null, "no remembered path starts quietly without an empty-path warning")

	Settings.theme_settings.path = existing_path
	await menu.auto_load_model()
	check(loader.get("loaded_paths") == [existing_path], "enabled auto-load still loads an existing remembered file")
	check(find_warning(menu) == null, "an existing file does not produce a warning")

	Settings.theme_settings.path = missing_path
	await menu.auto_load_model()
	var warning := find_warning(menu)
	check(warning != null, "a missing remembered file creates an actual AcceptDialog")
	check(loader.get("loaded_paths") == [existing_path], "a missing file is never passed to the model loader")
	check(Settings.theme_settings.auto_load and Settings.theme_settings.path == missing_path, "the warning preserves the auto-load preference and remembered path")
	if warning != null:
		check(warning.visible, "the missing-file warning is shown")
		check(warning.title == "Auto-Load Model", "the dialog uses the localized existing title")
		check(warning.dialog_text.contains(missing_path) and warning.dialog_text.contains("Files"), "the localized message identifies the path and explains how to open another model")
		check(warning.theme == Settings.current_theme, "the warning uses the current application theme")
		warning.confirmed.emit()
		check(warning.is_queued_for_deletion(), "dismissing the warning schedules it for cleanup")
		await get_tree().process_frame
		await menu.auto_load_model()
		warning = find_warning(menu)
		warning.canceled.emit()
		check(warning.is_queued_for_deletion(), "closing the warning schedules cleanup too")
		check(menu.is_inside_tree(), "dismissing a warning leaves the editor's menu running")
	menu.free()
	DirAccess.remove_absolute(existing_path)
	if failures == 0:
		print("All missing auto-load model checks passed")
	else:
		printerr("%d check(s) failed" % failures)
	get_tree().quit(0 if failures == 0 else 1)

func find_warning(menu: Node) -> AcceptDialog:
	for child in menu.get_children():
		if child is AcceptDialog:
			return child
	return null

func install_translation() -> void:
	var english := Translation.new()
	english.locale = "en"
	var csv := FileAccess.open("res://Localization/translations.csv", FileAccess.READ)
	csv.get_csv_line()
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size() >= 2:
			english.add_message(row[0], row[1])
	TranslationServer.add_translation(english)
	TranslationServer.set_locale("en")
