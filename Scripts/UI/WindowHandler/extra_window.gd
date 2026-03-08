extends Window

class_name ExtraWindow

const WINDOW_SIZE := Vector2(512, 512)
const BUTTON_MARGIN: int = 16

var dragging := false
var offset := Vector2i.ZERO

var viewport_container := SubViewportContainer.new()
var viewport := SubViewport.new()
var camera := WindowCamera.new()
var button := Button.new()
var control := Control.new()


func _init(world: World2D, remove_window: Callable, lock_window: Callable, other_camera: Camera2D) -> void:
	add_child(viewport_container)
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.add_child(viewport)
	viewport_container.stretch = true
	viewport.transparent_bg = true
	viewport.world_2d = world
	viewport.add_child(camera)
	camera.global_position = other_camera.global_position
	camera.zoom = other_camera.zoom

	hide()
	size = WINDOW_SIZE
	title = tr("TR_WINDOW") + " " + str(len(WindowHandler.windows) + 1)
	always_on_top = true
	transparent = true
	transparent_bg = true
	force_native = true
	close_requested.connect(remove_window.bind(self ))

	add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_default_cursor_shape = Control.CURSOR_DRAG
	control.mouse_filter = Control.MOUSE_FILTER_PASS

	control.add_child(button)
	button.theme = Settings.current_theme
	button.text = tr("TR_LOCK_SIZE")
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position -= Vector2.ONE * BUTTON_MARGIN
	button.pressed.connect(lock_window.bind(self ))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb"):
		offset = get_mouse_position()
		dragging = true
	elif event.is_action_released("lmb"):
		dragging = false

	viewport.push_input(event)


func _process(_delta: float) -> void:
	if !dragging:
		return
	position = DisplayServer.mouse_get_position() - offset
