extends RefCounted

## Pure policy helpers for the macOS window startup and transparency fixes.

static func transparency_enabled(requested: bool, is_macos: bool, available: bool) -> bool:
	return requested and (not is_macos or available)


static func should_clear_transparency_preference(requested: bool, is_macos: bool, available: bool) -> bool:
	return requested and is_macos and not available


static func startup_settings(is_macos: bool, persisted: Dictionary) -> Dictionary:
	var result := persisted.duplicate(true)
	if is_macos:
		result.mode = 0
		result.software_mode = 0
		result.screen_window = 0
		result.borders = true
		result.always_on_top = false
	return result


static func should_persist_window_geometry(is_macos: bool, is_minimized: bool) -> bool:
	return not (is_macos and is_minimized)


static func has_reachable_title_bar(window_rect: Rect2i, usable_rects: Array[Rect2i]) -> bool:
	for usable_rect in usable_rects:
		if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
			continue
		var visible_width := mini(window_rect.end.x, usable_rect.end.x) - maxi(window_rect.position.x, usable_rect.position.x)
		var title_bar_height := mini(40, window_rect.size.y)
		var title_bar_end_y := window_rect.position.y + title_bar_height
		var visible_title_bar_height := mini(title_bar_end_y, usable_rect.end.y) - maxi(window_rect.position.y, usable_rect.position.y)
		if visible_width >= mini(100, window_rect.size.x) and visible_title_bar_height >= title_bar_height:
			return true
	return false


static func restored_position(window_rect: Rect2i, usable_rects: Array[Rect2i], primary_rect: Rect2i) -> Variant:
	if has_reachable_title_bar(window_rect, usable_rects):
		return null
	if primary_rect.size.x <= 0 or primary_rect.size.y <= 0:
		return null
	return primary_rect.position + Vector2i(16, 16)
