extends SceneTree

const Policy := preload("res://Main/Scripts/mac_window_policy.gd")

var failures := 0

func _initialize() -> void:
	test_transparency_availability()
	test_window_on_negative_origin_display()
	test_disconnected_display_restores_to_primary()
	test_tiny_or_headless_screen_is_safe()
	if failures > 0:
		printerr("%d check(s) failed" % failures)
	else:
		print("All MacWindowPolicy checks passed")
	quit(1 if failures > 0 else 0)

func check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		failures += 1
		printerr("  FAIL ", description)

func test_transparency_availability() -> void:
	check(Policy.transparency_enabled(true, true, true), "requested macOS transparency is allowed when available")
	check(not Policy.transparency_enabled(true, true, false), "unavailable macOS transparency falls back to opaque")
	check(not Policy.transparency_enabled(false, true, true), "opaque mode remains opaque on macOS when support exists")
	check(Policy.transparency_enabled(true, false, false), "Windows/Linux transparency keeps its previous requested value")

func test_window_on_negative_origin_display() -> void:
	var left_display := Rect2i(-1600, 0, 1600, 900)
	var primary_display := Rect2i(0, 0, 1440, 900)
	var window_rect := Rect2i(-1200, 100, 800, 600)
	check(Policy.has_visible_area(window_rect, [left_display, primary_display]),
		"a window with a negative display origin is kept in place")
	check(Policy.restored_position(window_rect, [left_display, primary_display], primary_display) == null,
		"visible secondary-screen geometry does not get moved")

func test_disconnected_display_restores_to_primary() -> void:
	var disconnected_window := Rect2i(-2200, 100, 800, 600)
	var primary_display := Rect2i(0, 0, 1440, 900)
	check(Policy.restored_position(disconnected_window, [primary_display], primary_display) == Vector2i(16, 16),
		"a window on a disconnected display returns to the primary screen")

func test_tiny_or_headless_screen_is_safe() -> void:
	var small_screen := Rect2i(-640, 0, 640, 480)
	var offscreen_window := Rect2i(9000, 9000, 720, 720)
	check(Policy.restored_position(offscreen_window, [small_screen], small_screen) == Vector2i(-624, 16),
		"small work areas keep window size and move the title bar into reach")
	check(Policy.restored_position(offscreen_window, [], Rect2i()) == null,
		"missing usable display geometry does not apply an invalid position")
