extends RefCounted

## Pure policy helpers for the macOS window startup and transparency fixes.

static func transparency_enabled(requested: bool, is_macos: bool, available: bool) -> bool:
	return requested and (not is_macos or available)


static func has_visible_area(window_rect: Rect2i, usable_rects: Array[Rect2i]) -> bool:
	for usable_rect in usable_rects:
		if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
			continue
		var visible_width := mini(window_rect.end.x, usable_rect.end.x) - maxi(window_rect.position.x, usable_rect.position.x)
		var visible_height := mini(window_rect.end.y, usable_rect.end.y) - maxi(window_rect.position.y, usable_rect.position.y)
		if visible_width >= mini(100, window_rect.size.x) and visible_height >= mini(40, window_rect.size.y):
			return true
	return false


static func restored_position(window_rect: Rect2i, usable_rects: Array[Rect2i], primary_rect: Rect2i) -> Variant:
	if has_visible_area(window_rect, usable_rects):
		return null
	if primary_rect.size.x <= 0 or primary_rect.size.y <= 0:
		return null
	return primary_rect.position + Vector2i(16, 16)
