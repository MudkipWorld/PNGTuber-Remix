extends RefCounted
class_name GazeLockBinding

const GazeLockScript := preload("res://Main/Scripts/gaze_lock.gd")

## Returns the configured key, or null when the model has no binding.
static func current_event() -> InputEvent:
	var action := GazeLockScript.ACTION
	if not InputMap.has_action(action):
		return null
	var events := InputMap.action_get_events(action)
	return events[0] if not events.is_empty() else null


## Replaces the action binding instead of appending another key.
static func replace_event(event: InputEvent) -> void:
	var action := GazeLockScript.ACTION
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	if event != null:
		InputMap.action_add_event(action, event)


## Older model files have no gaze key; restoring them clears the current key.
static func restore_from_model(model: Dictionary) -> void:
	var saved_event: Variant = model.get("gaze_lock_event", null)
	if saved_event is InputEvent:
		replace_event(saved_event)
	else:
		replace_event(null)
	GazeLockScript.reset()
