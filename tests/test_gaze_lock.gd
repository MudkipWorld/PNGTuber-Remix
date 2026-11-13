extends SceneTree

## Checks the freeze gaze toggle used by mouse-follow sprites.
##
## Run from the project folder:
##   godot --headless --path . --script res://tests/test_gaze_lock.gd
## The process exits with code 1 when any check fails.

const Lock = preload("res://Main/Scripts/gaze_lock.gd")

const LOOKING_DOWN := Vector2(0, 300)
const MOUSE_ELSEWHERE := Vector2(500, -200)

var failures := 0


func _initialize() -> void:
	test_follows_the_mouse_when_not_frozen()
	test_keeps_direction_while_frozen()
	test_does_not_compute_the_mouse_while_frozen()
	test_follows_again_after_unfreezing()
	test_reset_unfreezes()

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


func live(value: Vector2) -> Callable:
	return func() -> Vector2: return value


func test_follows_the_mouse_when_not_frozen() -> void:
	Lock.reset()
	check(Lock.pick(LOOKING_DOWN, live(MOUSE_ELSEWHERE)) == MOUSE_ELSEWHERE,
		"not frozen: sprites use the live mouse position")


func test_keeps_direction_while_frozen() -> void:
	Lock.reset()
	Lock.toggle()
	check(Lock.frozen, "toggling once freezes the gaze")
	check(Lock.pick(LOOKING_DOWN, live(MOUSE_ELSEWHERE)) == LOOKING_DOWN,
		"frozen: sprites keep looking where they were when it froze")


func test_does_not_compute_the_mouse_while_frozen() -> void:
	Lock.reset()
	Lock.toggle()
	var calls := [0]
	Lock.pick(LOOKING_DOWN, func() -> Vector2:
		calls[0] += 1
		return MOUSE_ELSEWHERE)
	check(calls[0] == 0, "frozen: the live mouse position is not computed")


func test_follows_again_after_unfreezing() -> void:
	Lock.reset()
	Lock.toggle()
	Lock.toggle()
	check(!Lock.frozen, "toggling twice unfreezes the gaze")
	check(Lock.pick(LOOKING_DOWN, live(MOUSE_ELSEWHERE)) == MOUSE_ELSEWHERE,
		"unfrozen: sprites follow the mouse again")


func test_reset_unfreezes() -> void:
	Lock.toggle()
	Lock.reset()
	check(!Lock.frozen, "reset (e.g. loading a model) unfreezes the gaze")
