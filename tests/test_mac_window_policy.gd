extends SceneTree

const Policy := preload("res://Main/Scripts/mac_window_policy.gd")

var failures := 0

func _initialize() -> void:
	test_transparency_availability()
	test_transparency_preference_mutation_is_macos_only()
	test_startup_settings_are_platform_scoped()
	test_minimized_geometry_is_not_persisted_on_macos()
	test_window_on_negative_origin_display()
	test_disconnected_display_restores_to_primary()
	test_visible_body_does_not_hide_an_inaccessible_title_bar()
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

func test_transparency_preference_mutation_is_macos_only() -> void:
	check(Policy.should_clear_transparency_preference(true, true, false),
		"unsupported macOS transparency clears the unusable preference")
	check(not Policy.should_clear_transparency_preference(true, false, false),
		"Windows/Linux transparency preference is not mutated")
	check(not Policy.should_clear_transparency_preference(true, true, true),
		"supported macOS transparency preference is preserved")
	check(not Policy.should_clear_transparency_preference(false, true, false),
		"opaque preference remains unchanged when transparency is unavailable")

func test_startup_settings_are_platform_scoped() -> void:
	var persisted := {
		"mode": 1,
		"software_mode": 1,
		"screen_window": 1,
		"borders": false,
		"always_on_top": true,
		"screen_pos": Vector2i(-800, 30),
	}
	var mac_settings := Policy.startup_settings(true, persisted)
	check(mac_settings.mode == 0 and mac_settings.software_mode == 0,
		"macOS starts in editor mode instead of reopening a transparent preview")
	check(mac_settings.screen_window == 0 and mac_settings.borders and not mac_settings.always_on_top,
		"macOS starts windowed, bordered, and without always-on-top")
	check(mac_settings.screen_pos == persisted.screen_pos,
		"macOS retains saved position for later reachability validation")
	var other_platform_settings := Policy.startup_settings(false, persisted)
	check(other_platform_settings == persisted,
		"Windows/Linux keep all saved startup window preferences")

func test_minimized_geometry_is_not_persisted_on_macos() -> void:
	check(not Policy.should_persist_window_geometry(true, true),
		"minimized macOS geometry is skipped")
	check(Policy.should_persist_window_geometry(true, false),
		"normal macOS geometry is persisted")
	check(Policy.should_persist_window_geometry(false, true),
		"Windows/Linux preserve their existing minimized geometry behavior")

func test_window_on_negative_origin_display() -> void:
	var left_display := Rect2i(-1600, 0, 1600, 900)
	var primary_display := Rect2i(0, 0, 1440, 900)
	var window_rect := Rect2i(-1200, 100, 800, 600)
	check(Policy.has_reachable_title_bar(window_rect, [left_display, primary_display]),
		"a window with a negative display origin is kept in place")
	check(Policy.restored_position(window_rect, [left_display, primary_display], primary_display) == null,
		"visible secondary-screen geometry does not get moved")

func test_visible_body_does_not_hide_an_inaccessible_title_bar() -> void:
	var primary_display := Rect2i(0, 0, 1440, 900)
	var window_rect := Rect2i(100, -100, 800, 720)
	check(not Policy.has_reachable_title_bar(window_rect, [primary_display]),
		"visible window body is insufficient when the title bar is off-screen")
	check(Policy.restored_position(window_rect, [primary_display], primary_display) == Vector2i(16, 16),
		"an inaccessible title bar is moved back onto the primary screen")

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
