# Special thanks for Guuvita for the help implementing this feature
extends Control
class_name Monitor

const ALL_SCREENS = 9999
var current_screen = ALL_SCREENS
var coords : Vector2 = Vector2(0,0)
var global_coords : Vector2 = Vector2(0,0)
var screen_count = 0

func _ready():
	screen_count = DisplayServer.get_screen_count()

func _physics_process(_delta: float) -> void:
	if current_screen == ALL_SCREENS:
		set_mouse_positions()
	else:
		if current_screen in range(screen_count):
			screen_based_position()

func mouse_in_current_screen():
	var screen_pos = Vector2(DisplayServer.screen_get_position(current_screen)) - Vector2(1,1)
	var screen_size = Vector2(DisplayServer.screen_get_size(current_screen))+ Vector2(1,1)
	var mouse_pos = Vector2(DisplayServer.mouse_get_position())

	return (mouse_pos.x >= screen_pos.x and mouse_pos.x < (screen_size.x + screen_pos.x) and 
			mouse_pos.y >= screen_pos.y and mouse_pos.y < (screen_size.y + screen_pos.y))

func set_mouse_positions():
	var global_mouse_pos = get_local_mouse_position()
	coords = global_mouse_pos
	global_coords = global_mouse_pos


func screen_based_position():
	if Global.settings_dict.snap_out_of_bounds:
		if !mouse_in_current_screen():
			coords = Vector2(0,0)
			global_coords = Vector2(0,0)
			return
	set_mouse_positions()
