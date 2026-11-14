extends SceneTree

const Lock := preload("res://Main/Scripts/gaze_lock.gd")
const Binding := preload("res://Main/Scripts/gaze_lock_binding.gd")

var failures := 0

func _initialize() -> void:
	if not InputMap.has_action(Lock.ACTION):
		InputMap.add_action(Lock.ACTION)
	Binding.replace_event(null)
	Lock.reset()
	test_default_binding_is_unset()
	test_rebinding_replaces_instead_of_appending()
	test_serialized_model_round_trip_restores_the_key()
	test_older_model_without_key_clears_binding_and_resets_lock()
	test_null_or_invalid_model_key_clears_binding()
	Binding.replace_event(null)
	Lock.reset()
	if failures > 0:
		printerr("%d check(s) failed" % failures)
	else:
		print("All GazeLockBinding checks passed")
	quit(1 if failures > 0 else 0)

func check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		failures += 1
		printerr("  FAIL ", description)

func key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	return event

func current_keycode() -> int:
	var event := Binding.current_event()
	return (event as InputEventKey).keycode if event is InputEventKey else -1

func test_default_binding_is_unset() -> void:
	check(Binding.current_event() == null, "the default action has no bound key")
	check(InputMap.action_get_events(Lock.ACTION).is_empty(), "the default action event list is empty")

func test_rebinding_replaces_instead_of_appending() -> void:
	Binding.replace_event(key_event(KEY_H))
	Binding.replace_event(key_event(KEY_J))
	check(InputMap.action_get_events(Lock.ACTION).size() == 1, "rebinding keeps exactly one event")
	check(current_keycode() == KEY_J, "rebinding retains the replacement key")

func test_serialized_model_round_trip_restores_the_key() -> void:
	Binding.replace_event(key_event(KEY_H))
	var model_bytes := var_to_bytes_with_objects({"gaze_lock_event": Binding.current_event()})
	var model: Dictionary = bytes_to_var_with_objects(model_bytes)
	Binding.replace_event(key_event(KEY_J))
	Lock.toggle()
	Binding.restore_from_model(model)
	check(current_keycode() == KEY_H, "model serialization restores the original key binding")
	check(InputMap.action_get_events(Lock.ACTION).size() == 1, "restoring a model does not append to the current key")
	check(not Lock.frozen, "loading a model clears a previous frozen gaze state")

func test_older_model_without_key_clears_binding_and_resets_lock() -> void:
	Binding.replace_event(key_event(KEY_H))
	Lock.toggle()
	Binding.restore_from_model({"version": "older-model"})
	check(Binding.current_event() == null, "older model without the field clears the active key")
	check(not Lock.frozen, "older model load unfreezes gaze")

func test_null_or_invalid_model_key_clears_binding() -> void:
	Binding.replace_event(key_event(KEY_H))
	Binding.restore_from_model({"gaze_lock_event": null})
	check(Binding.current_event() == null, "null model key clears the active binding")
	Binding.replace_event(key_event(KEY_H))
	Binding.restore_from_model({"gaze_lock_event": "not an input event"})
	check(Binding.current_event() == null, "invalid model value does not leave a stale binding")
