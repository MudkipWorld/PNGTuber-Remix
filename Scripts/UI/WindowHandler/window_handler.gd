extends Node

class_name WindowHandler

static var windows: Array[ExtraWindow] = []
var last_mode: int = -1


func _ready() -> void:
	Global.theme_update.connect(update_theme)
	Global.add_window.connect(new_window)
	Global.edit_windows.connect(unlock_windows)


func dont_reset_mode() -> void:
	last_mode = -1


func new_window() -> void:
	if windows.is_empty():
		last_mode = Global.mode
		Global.mode = 1
		Global.mode_changed.connect(dont_reset_mode, CONNECT_ONE_SHOT)

	var window := ExtraWindow.new(%SubViewport.world_2d, remove_window, lock_window, %Camera2D)
	windows.append(window)
	add_child(window)
	window.popup_centered()


func remove_window(window: ExtraWindow) -> void:
	windows.erase(window)
	window.always_on_top = false
	window.queue_free()

	for i in len(windows):
		if !is_instance_valid(windows[i]):
			continue
		windows[i].title = tr("TR_WINDOW") + " " + str(i + 1)

	if windows:
		return

	if Global.mode_changed.is_connected(dont_reset_mode):
		Global.mode_changed.disconnect(dont_reset_mode)

	if last_mode >= 0:
		Global.mode = last_mode


func lock_window(window: ExtraWindow) -> void:
	if !is_instance_valid(window):
		return
	window.borderless = true
	window.button.hide()


func update_theme(new_theme: Theme) -> void:
	for window in windows:
		window.button.theme = new_theme


func unlock_windows() -> void:
	for window in windows:
		window.borderless = false
		window.button.show()
		window.button.release_focus()
