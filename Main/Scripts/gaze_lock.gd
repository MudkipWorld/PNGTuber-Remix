extends RefCounted
class_name GazeLock

## Freezes where mouse-follow sprites are looking. While frozen, every sprite
## keeps the mouse coordinates it had when the lock was turned on, so eyes stay
## pointed in that direction until the hotkey is pressed again.

## Input action bound in Settings and checked through GlobInput.
const ACTION := "freeze_gaze"

static var frozen := false

static func toggle() -> void:
	frozen = !frozen

static func reset() -> void:
	frozen = false

## Coordinates a sprite uses this frame: the held ones while frozen, otherwise
## the result of `live`, which is only called when it is needed.
static func pick(held: Vector2, live: Callable) -> Vector2:
	if frozen:
		return held
	return live.call()
