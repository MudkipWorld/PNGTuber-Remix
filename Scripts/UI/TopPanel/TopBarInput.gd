extends Node

@onready var files_button: MenuButton = %FilesButton
@onready var mode_button: MenuButton = %ModeButton
@onready var bg_button: MenuButton = %BGButton
@onready var grid_button: MenuButton = %GridButton
@onready var about_button: MenuButton = %AboutButton
@onready var window_button: MenuButton = %WindowButton
@onready var demos_popup: PopupMenu = %Demos
@onready var background_popup: PopupPanel = %Background
@onready var bg_color_picker: ColorPicker = %BGColorPicker
@onready var preview_mode_check: CheckBox = %PreviewModeCheck
@onready var hide_ui_button: CheckBox = %HideUIButton
@onready var credit_popup: PopupPanel = %CreditPopUp
@onready var model_optimizer: Window = %ModelOptimizer

const FILE_IMPORT_ITEMS := [
	"TR_ADD_IMAGE",
	"TR_ADD_APPENDAGE",
	"TR_PSD_IMPORT",
]

const WindowMenuId := {
	TOGGLE_BORDERS = 0,
	SAVE_WINDOW_POSITIONS = 1,
	ALWAYS_ON_TOP = 2,
	CENTER_WINDOW = 3,
	RESET_WINDOW = 8,
	ADD_WINDOW = 4,
	MINI_VIEW = 5,
	SPRITE_VIEW = 6,
	BOTTOM_BAR = 7,
	EDIT_WINDOWS = 100,
}

var settings_scene := preload("res://UI/EditorUI/TopUI/Components/Settings_popup.tscn")
var tutorial_scene := preload("res://UI/EditorUI/TopUI/Components/tutorial_pop_up.tscn")

var file_import_submenu: PopupMenu = PopupMenu.new()
var grid_size_dialog: AcceptDialog = null
var grid_size_spinbox: SpinBox = null

@onready var file_submenu_item_demos: PopupMenu = %Demos


func _ready() -> void:
	get_viewport().transparent_bg = false
	RenderingServer.set_default_clear_color(Color.SLATE_GRAY)

	files_button.get_popup().id_pressed.connect(_on_files_id_pressed)
	mode_button.get_popup().id_pressed.connect(_on_mode_id_pressed)
	bg_button.get_popup().id_pressed.connect(_on_bg_id_pressed)
	grid_button.get_popup().id_pressed.connect(_on_grid_id_pressed)
	_setup_grid()
	about_button.get_popup().id_pressed.connect(_on_about_id_pressed)
	window_button.get_popup().id_pressed.connect(_on_window_id_pressed)

	Global.mode_changed.connect(_on_mode_changed)
	Global.theme_update.connect(_on_grid_theme_update)
	Global.deselect.connect(_deselect_everything)
	Global.dev_mode.connect(_check_dev_mode)

	for tr_name in FILE_IMPORT_ITEMS:
		file_import_submenu.add_item(tr_name)
	files_button.get_popup().set_item_submenu_node(4, file_import_submenu)
	file_import_submenu.id_pressed.connect(_on_file_import_id_pressed)

	file_submenu_item_demos.get_parent().remove_child(file_submenu_item_demos)
	files_button.get_popup().set_item_submenu_node(5, file_submenu_item_demos)
	file_submenu_item_demos.id_pressed.connect(_on_demos_id_pressed)

	_update_window_button()
	_check_auto_saves()
	await get_tree().physics_frame
	_on_mode_id_pressed(Settings.theme_settings.mode)


func _check_dev_mode(enabled: bool = false) -> void:
	var popup := mode_button.get_popup()
	popup.clear()
	popup.add_item("TR_EDITOR", 0)
	popup.add_item("TR_PREVIEW", 1)
	if enabled:
		popup.add_item("Meshes (WIP)", 2)


func _update_window_button() -> void:
	var menu: PopupMenu = window_button.get_popup()

	var idx_always: int = menu.get_item_index(WindowMenuId.ALWAYS_ON_TOP)
	if idx_always != -1:
		menu.set_item_checked(idx_always, Settings.theme_settings.always_on_top)

	var idx_mini: int = menu.get_item_index(WindowMenuId.MINI_VIEW)
	if idx_mini != -1:
		menu.set_item_checked(idx_mini, Settings.theme_settings.hide_mini_view)

	var idx_sprite: int = menu.get_item_index(WindowMenuId.SPRITE_VIEW)
	if idx_sprite != -1:
		menu.set_item_checked(idx_sprite, Settings.theme_settings.hide_sprite_view)

	var idx_bottom: int = menu.get_item_index(WindowMenuId.BOTTOM_BAR)
	if idx_bottom != -1:
		menu.set_item_checked(idx_bottom, Settings.theme_settings.hide_bottom_bar)

	var edit_idx: int = menu.get_item_index(WindowMenuId.EDIT_WINDOWS)
	if edit_idx >= 0:
		menu.remove_item(edit_idx)

	for window in WindowHandler.windows:
		if not window.borderless:
			continue
		menu.add_item("Edit Windows", WindowMenuId.EDIT_WINDOWS)
		break


func _check_auto_saves() -> void:
	if not DirAccess.dir_exists_absolute(Settings.autosave_location):
		DirAccess.make_dir_absolute(Settings.autosave_location)


func _toggle_window_piece(id: int) -> void:
	var menu: PopupMenu = window_button.get_popup()
	var idx: int = menu.get_item_index(id)
	if idx == -1:
		return
	menu.toggle_item_checked(idx)
	Settings.set_ui_pieces(menu.is_item_checked(idx), id)
	Global.update_ui_pieces.emit()


func _on_window_id_pressed(id: int) -> void:
	match id:
		WindowMenuId.TOGGLE_BORDERS:
			Settings.toggle_borders()
		WindowMenuId.SAVE_WINDOW_POSITIONS:
			Settings.window_size_changed()
		WindowMenuId.ALWAYS_ON_TOP:
			var menu: PopupMenu = window_button.get_popup()
			var idx: int = menu.get_item_index(id)
			if idx == -1:
				return
			menu.toggle_item_checked(idx)
			Settings.set_always_on_top(menu.is_item_checked(idx))
		WindowMenuId.CENTER_WINDOW:
			Settings.center_window()
		WindowMenuId.ADD_WINDOW:
			Global.add_window.emit()
		WindowMenuId.MINI_VIEW, WindowMenuId.SPRITE_VIEW, WindowMenuId.BOTTOM_BAR:
			_toggle_window_piece(id)
		WindowMenuId.RESET_WINDOW:
			get_window().size = Vector2i(1152, 648)
			Settings.center_window()
			Settings.window_size_changed()
		WindowMenuId.EDIT_WINDOWS:
			Global.edit_windows.emit()


func _on_files_id_pressed(id: int) -> void:
	var main: Node = Global.main
	match id:
		0:
			main.new_file()
		1:
			main.load_file()
		2:
			if Global.save_path != "":
				SaveAndLoad.save_file(Global.save_path)
			else:
				main.save_as_file()
		3:
			main.save_as_file()
		4:
			pass
		5:
			_add_lipsync_config()
		6:
			SaveAndLoad.import_trimmed = false
			if Global.save_path == null or Global.save_path == "":
				_check_auto_saves()
				var save_location: String = Settings.autosave_location + "ReloadedFileBackup" + "/" + str(randi())
				SaveAndLoad.save_file(save_location)
				await get_tree().physics_frame
				SaveAndLoad.load_file(save_location)
			else:
				SaveAndLoad.save_file(Global.save_path)
				await get_tree().physics_frame
				SaveAndLoad.load_file(Global.save_path)
		7:
			SaveAndLoad.export_images(get_tree().get_nodes_in_group("Sprites"))
		11:
			if Global.swtich_session_popup != null and is_instance_valid(Global.swtich_session_popup):
				Global.swtich_session_popup.popup()
		13:
			model_optimizer.show()


func _on_file_import_id_pressed(id: int) -> void:
	var main: Node = Global.main
	match id:
		0:
			main.load_sprites()
		1:
			main.load_append_sprites()
		2:
			main.import_psd()


func _on_demos_id_pressed(id: int) -> void:
	match id:
		0:
			SaveAndLoad.load_file("res://DemoModels/PickleModel.pngRemix")
		1:
			SaveAndLoad.load_file("res://DemoModels/PickleModelWithNormalMap.pngRemix")
		2:
			SaveAndLoad.load_file("res://DemoModels/PickleModelFollowMouse.pngRemix")
		3:
			SaveAndLoad.load_file("res://DemoModels/PicklesModelJoypad.pngRemix")
		4:
			SaveAndLoad.load_file("res://DemoModels/PickleModelAssets.pngRemix")


func _on_mode_changed(new_mode: int) -> void:
	if Global.grid_overlay != null and is_instance_valid(Global.grid_overlay):
		Global.grid_overlay.visible = Global.grid_visible and new_mode != 1

	match new_mode:
		0, 2:
			preview_mode_check.show()
			hide_ui_button.button_pressed = true
			hide_ui_button.show()
		1:
			hide_ui_button.hide()
			hide_ui_button.button_pressed = false
			preview_mode_check.hide()
			preview_mode_check.button_pressed = false
			_deselect_everything()


func _on_mode_id_pressed(id: int) -> void:
	Global.mode = id


func _on_bg_id_pressed(id: int) -> void:
	Global.settings_dict.is_transparent = false

	match id:
		0:
			Global.settings_dict.bg_color = Color.RED
		1:
			Global.settings_dict.bg_color = Color.BLUE
		2:
			Global.settings_dict.bg_color = Color.GREEN
		3:
			Global.settings_dict.bg_color = Color.MAGENTA
		4:
			Global.settings_dict.bg_color = Color.DIM_GRAY
			Global.settings_dict.is_transparent = true
		5:
			Global.settings_dict.bg_color = Color.SLATE_GRAY
		6:
			background_popup.popup()

	if not Global.is_editor:
		RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
		get_viewport().transparent_bg = Global.settings_dict.is_transparent


func _on_about_id_pressed(id: int) -> void:
	match id:
		1:
			credit_popup.popup()
		2:
			get_parent().add_child(tutorial_scene.instantiate())


func _setup_grid() -> void:
	var overlay_script: Script = preload("res://Scripts/UI/Others/grid.gd")
	var origin: Node2D = null
	if Global.main != null and is_instance_valid(Global.main):
		origin = Global.main.get_node_or_null("SubViewportContainer/SubViewport/Node2D/Origin") as Node2D

	if origin == null:
		call_deferred("_setup_grid")
		return

	if Global.grid_overlay == null or !is_instance_valid(Global.grid_overlay):
		var overlay: Node2D = Node2D.new()
		overlay.set_script(overlay_script)
		overlay.name = "GridOverlay"
		origin.add_child(overlay)
		Global.grid_overlay = overlay

	Global.grid_overlay.visible = Global.grid_visible and Global.mode != 1

	var popup: PopupMenu = grid_button.get_popup()
	popup.set_item_checked(0, Global.grid_visible)
	popup.set_item_checked(1, Global.grid_snap)
	popup.set_item_text(2, "Snap Size: %.1f px" % Global.grid_size)

func _on_grid_id_pressed(id: int) -> void:
	match id:
		0:
			Global.grid_visible = !Global.grid_visible
			if Global.grid_overlay != null and is_instance_valid(Global.grid_overlay):
				Global.grid_overlay.visible = Global.grid_visible
		1:
			Global.grid_snap = !Global.grid_snap
			if Global.grid_snap:
				for sprite in Global.held_sprites:
					var snapped: Vector2 = Global.snap_position(sprite.position)
					sprite.position = snapped
					sprite.sprite_data.position = snapped
					sprite.save_state(Global.current_state)
			Global.update_pos_spins.emit()
		2:
			_show_grid_size_dialog()

	var popup: PopupMenu = grid_button.get_popup()
	popup.set_item_checked(0, Global.grid_visible)
	popup.set_item_checked(1, Global.grid_snap)
	popup.set_item_text(2, "Snap Size: %.1f px" % Global.grid_size)

func _on_grid_theme_update(new_theme: Theme = null) -> void:
	if grid_size_dialog != null and is_instance_valid(grid_size_dialog):
		grid_size_dialog.theme = new_theme if new_theme != null else Settings.current_theme

func _show_grid_size_dialog() -> void:
	if grid_size_dialog != null and is_instance_valid(grid_size_dialog):
		grid_size_dialog.theme = Settings.current_theme
		grid_size_dialog.popup_centered()
		grid_size_spinbox.grab_focus()
		grid_size_spinbox.get_line_edit().select_all()
		return

	grid_size_dialog = AcceptDialog.new()
	grid_size_dialog.theme = Settings.current_theme
	grid_size_dialog.title = "Grid Snap Size"
	grid_size_dialog.ok_button_text = "Apply"
	grid_size_dialog.min_size = Vector2i(320, 130)

	var container: VBoxContainer = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	grid_size_dialog.add_child(container)

	var label: Label = Label.new()
	label.text = "Snap distance (0.1 to 100 pixels):"
	container.add_child(label)

	grid_size_spinbox = SpinBox.new()
	grid_size_spinbox.min_value = 0.1
	grid_size_spinbox.max_value = 100.0
	grid_size_spinbox.step = 0.1
	grid_size_spinbox.value = Global.grid_size
	grid_size_spinbox.allow_greater = false
	grid_size_spinbox.allow_lesser = false
	grid_size_spinbox.tooltip_text = "Distance between snap points in pixels."
	container.add_child(grid_size_spinbox)

	grid_size_dialog.confirmed.connect(_apply_grid_size)
	get_tree().current_scene.add_child(grid_size_dialog)
	grid_size_dialog.popup_centered()
	grid_size_spinbox.grab_focus()
	grid_size_spinbox.get_line_edit().select_all()

func _apply_grid_size() -> void:
	if grid_size_spinbox == null:
		return
	Global.grid_size = clampf(grid_size_spinbox.value, 0.1, 100.0)

	if Global.grid_overlay != null and is_instance_valid(Global.grid_overlay):
		Global.grid_overlay.queue_redraw()

	if Global.grid_snap:
		for sprite in Global.held_sprites:
			var snapped: Vector2 = Global.snap_position(sprite.position)
			sprite.position = snapped
			sprite.sprite_data.position = snapped
			sprite.save_state(Global.current_state)
		Global.update_pos_spins.emit()

	var popup: PopupMenu = grid_button.get_popup()
	popup.set_item_text(2, "Snap Size: %.1f px" % Global.grid_size)

func _notification(what: int) -> void:
	if not Global.is_editor:
		if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			%TopBar.show()
		elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			%TopBar.hide()


func _on_inputs_button_pressed() -> void:
	Global.top_ui.add_child(settings_scene.instantiate())


func _on_color_picker_color_changed(color: Color) -> void:
	Global.settings_dict.bg_color = color
	if not Global.is_editor:
		RenderingServer.set_default_clear_color(color)


func update_bg_color(color: Color, transparency: bool) -> void:
	Global.settings_dict.bg_color = color
	Global.settings_dict.is_transparent = transparency
	bg_color_picker.color = color
	if not Global.is_editor:
		RenderingServer.set_default_clear_color(color)
		get_viewport().transparent_bg = transparency


func origin_alias() -> void:
	if Global.settings_dict.anti_alias:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS


func _on_hide_ui_button_toggled(toggled_on: bool) -> void:
	Global.main.get_node("%Control").visible = toggled_on


func _on_deselect_button_pressed() -> void:
	Global.deselect.emit()


func _deselect_everything() -> void:
	if Global.held_sprite != null and is_instance_valid(Global.held_sprite):
		if Global.held_sprite.has_node("%Origin"):
			Global.held_sprite.get_node("%Origin").hide()
	Global.held_sprite = null


func _on_preview_mode_check_toggled(toggled_on: bool) -> void:
	Global.static_view = toggled_on


func _on_background_focus_entered() -> void:
	Global.spinbox_held = true


func _on_background_focus_exited() -> void:
	Global.spinbox_held = false


func _add_lipsync_config() -> void:
	var lipsync := preload("res://UI/Lipsync stuff/lipsync_configuration_popup.tscn").instantiate()
	lipsync.name = "LipsyncConfigurationPopup"
	get_parent().add_child(lipsync)


func _on_window_button_about_to_popup() -> void:
	_update_window_button()
