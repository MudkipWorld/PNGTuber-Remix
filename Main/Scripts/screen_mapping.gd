extends RefCounted
class_name ScreenMapping

## Pure helpers used by the mouse-follow code to map the global mouse position
## to a screen. Kept free of autoloads and nodes so they can be tested headless.

## Value of Monitor.current_screen when every screen is tracked.
const ALL_SCREENS = 9999

## Screen the mouse-follow math is measured against: the one picked in Settings
## or, when tracking all screens, the screen the window is on.
static func reference_screen(selected: int, window_screen: int, count: int) -> int:
	if selected == ALL_SCREENS:
		return clampi(window_screen, 0, count - 1)
	return clampi(selected, 0, count - 1)

## Mouse position relative to where the sprite would be if the window covered
## the whole `screen_rect`.
static func mouse_coords_on_screen(mouse_global: Vector2, screen_rect: Rect2, sprite_origin: Vector2, viewport_size: Vector2) -> Vector2:
	var x_per = 1.0 - sprite_origin.x / viewport_size.x
	var y_per = 1.0 - sprite_origin.y / viewport_size.y
	var offset = Vector2(screen_rect.size.x * x_per, screen_rect.size.y * y_per)
	return (mouse_global - screen_rect.position - screen_rect.size) + offset
