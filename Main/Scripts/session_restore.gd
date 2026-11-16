extends RefCounted
class_name SessionRestore

## macOS rules that make the app reopen where it was left: the last saved or
## opened model loads on start, and the model is saved when the window closes.
## Windows and Linux keep their current behavior.

## Marks that the macOS defaults were applied once, so later choices are kept.
const MACOS_DEFAULTS_KEY := "macos_restore_defaults_applied"

## Turns on Auto Load and Save on Exit the first time the app runs on macOS,
## for new and existing users. Returns true when `settings` changed.
static func apply_platform_defaults(settings: Dictionary, is_macos: bool) -> bool:
	if !is_macos or settings.get(MACOS_DEFAULTS_KEY, false):
		return false
	settings.auto_load = true
	settings.save_on_exit = true
	settings[MACOS_DEFAULTS_KEY] = true
	return true

## Whether saving a model also makes it the one Auto Load opens.
static func remembers_saved_model(is_macos: bool) -> bool:
	return is_macos

## Whether closing the window runs the Save on Exit flow.
static func saves_on_close(is_macos: bool) -> bool:
	return is_macos
