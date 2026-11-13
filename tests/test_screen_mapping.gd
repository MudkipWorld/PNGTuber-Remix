extends SceneTree

## Checks how the mouse position is mapped to a screen for mouse-follow sprites.
##
## Run from the project folder:
##   godot --headless --path . --script res://tests/test_screen_mapping.gd
## The process exits with code 1 when any check fails.

const Mapping = preload("res://Main/Scripts/screen_mapping.gd")

# Two 1080p monitors side by side, the primary one on the left.
const PRIMARY_SCREEN := Rect2(0, 0, 1920, 1080)
const SECONDARY_SCREEN := Rect2(1920, 0, 1920, 1080)
const SCREENS := [PRIMARY_SCREEN, SECONDARY_SCREEN]

const VIEWPORT_SIZE := Vector2(1152, 648)
const SPRITE_AT_CENTER := Vector2(576, 324)

var failures := 0


func _initialize() -> void:
	test_selected_screen_is_used()
	test_selected_screen_out_of_range_is_clamped()
	test_all_screens_follows_the_window_screen()
	test_single_monitor_is_unchanged()
	test_window_on_secondary_looks_toward_mouse_on_primary()
	test_window_on_primary_looks_toward_mouse_on_secondary()

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


func coords_for(window_screen: int, mouse_global: Vector2) -> Vector2:
	var screen := Mapping.reference_screen(Mapping.ALL_SCREENS, window_screen, SCREENS.size())
	return Mapping.mouse_coords_on_screen(mouse_global, SCREENS[screen], SPRITE_AT_CENTER, VIEWPORT_SIZE)


func test_selected_screen_is_used() -> void:
	check(Mapping.reference_screen(1, 0, 2) == 1,
		"a screen picked in Settings is used even if the window is elsewhere")


func test_selected_screen_out_of_range_is_clamped() -> void:
	check(Mapping.reference_screen(3, 0, 2) == 1,
		"a picked screen that no longer exists falls back to the last one")


func test_all_screens_follows_the_window_screen() -> void:
	check(Mapping.reference_screen(Mapping.ALL_SCREENS, 1, 2) == 1,
		"with all screens, the screen the window is on is used")


func test_single_monitor_is_unchanged() -> void:
	check(Mapping.reference_screen(Mapping.ALL_SCREENS, 0, 1) == 0,
		"with one monitor, screen 0 is used")
	var coords := Mapping.mouse_coords_on_screen(Vector2(1800, 540), PRIMARY_SCREEN, SPRITE_AT_CENTER, VIEWPORT_SIZE)
	check(coords == Vector2(840, 0),
		"with one monitor, the mapping matches the previous behavior (got %s)" % coords)


func test_window_on_secondary_looks_toward_mouse_on_primary() -> void:
	# Mouse near the right edge of the primary screen, left of the window.
	var coords := coords_for(1, Vector2(1800, 540))
	check(coords.x < 0,
		"window on the secondary screen looks left at a mouse on the primary screen (got %s)" % coords)


func test_window_on_primary_looks_toward_mouse_on_secondary() -> void:
	# Mouse on the secondary screen, right of the window.
	var coords := coords_for(0, Vector2(2000, 540))
	check(coords.x > 0,
		"window on the primary screen looks right at a mouse on the secondary screen (got %s)" % coords)
