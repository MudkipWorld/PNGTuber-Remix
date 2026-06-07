extends Control

var can_scroll : bool = true
var of

enum State {
	LoadFile,
	SaveSettings,
	LoadSettings,
}
var current_state : State

func load_file():
	%FileDialog.filters = ["*.pngRemix, *.save"]
	$FileDialog.file_mode = 0
	current_state = State.LoadFile
	%FileDialog.show()


func _ready() -> void:
	Global.mode = 1
	Global.viewport = %SubViewportContainer
	Global.viewer = %Effects
	Global.main = self
	Global.sprite_container = %SpritesContainer
	Global.light = %LightSource
	Global.camera = %Camera2D
	Global.camera_pos = %CamPos
	Global.theme_update.connect(update_theme)
	update_theme(Settings.current_theme)
	await get_tree().create_timer(0.1).timeout
	Global.update_camera_smoothing()

func update_theme(new_theme : Theme = preload("res://Themes/PurpleTheme/GUITheme.tres")):
	%UI.theme = new_theme


func clear_sprites():
	Global.held_sprite = null
	Global.deselect.emit()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if InputMap.has_action(str(i.sprite_id)):
			InputMap.erase_action(str(i.sprite_id))

	for i in %SpritesContainer.get_children():
		i.queue_free()
	
	Global.delete_states.emit()
	Global.reset_states.emit()
	%Camera2D.zoom = Vector2(1,1)
	%CamPos.global_position = Vector2(640, 360)
	Global.settings_dict.zoom = Vector2(1,1)
	Global.settings_dict.pan = Vector2(640, 360)

func _on_sub_viewport_container_mouse_entered():
	can_scroll = true

func _on_sub_viewport_container_mouse_exited():
	can_scroll = false

func _input(event):
	if can_scroll && not Input.is_action_pressed("ctrl"):
		if event.is_action_pressed("scrollup"):
				%Camera2D.zoom = clamp(%Camera2D.zoom*Vector2(1.1,1.1) , Vector2(0.01,0.01), Vector2(5,5))
				Global.settings_dict.zoom = %Camera2D.zoom
		elif event.is_action_pressed("scrolldown"):
				%Camera2D.zoom = clamp(%Camera2D.zoom/Vector2(1.1,1.1) , Vector2(0.01,0.01), Vector2(5,5))
				Global.settings_dict.zoom = %Camera2D.zoom
		
		if Input.is_action_just_pressed("pan"):
			of = get_global_mouse_position() + %CamPos.global_position
		
		elif Input.is_action_pressed("pan"):
			%CamPos.global_position = -get_global_mouse_position() + of
			Global.settings_dict.pan = %CamPos.global_position


func _on_file_dialog_file_selected(path: String) -> void:
	match current_state:
		State.LoadFile:
			SaveAndLoad.load_file(path)
