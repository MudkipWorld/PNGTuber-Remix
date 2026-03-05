extends Node

signal language_changed(locale_code: String)

const AUTO_LOCALE := "auto"

var available_languages: Array[String] = []
var _current_locale: String = AUTO_LOCALE

func _enter_tree() -> void:
	available_languages = _build_languages()

func initialize(saved_locale: String) -> void:
	var validated := _validate_locale(saved_locale)
	_apply_locale(validated)
	if validated != saved_locale:
		language_changed.emit(validated)

func set_language(locale_code: String) -> void:
	if not available_languages.has(locale_code):
		push_warning("LanguageManager: unknown locale '%s'" % locale_code)
		return
	_apply_locale(locale_code)
	language_changed.emit(_current_locale)

func get_current_locale() -> String:
	return _current_locale

func get_display_name(locale_code: String) -> String:
	if locale_code == AUTO_LOCALE:
		return tr("TR_LANG_SYSTEM")
	var tr_obj := TranslationServer.get_translation_object(locale_code)
	if not tr_obj:
		return locale_code
	var display_name := String(tr_obj.get_message("TR_LANG_DISPLAY_NAME"))
	return display_name if not display_name.is_empty() else locale_code

func _build_languages() -> Array[String]:
	var result: Array[String] = [AUTO_LOCALE]
	var locales := TranslationServer.get_loaded_locales()
	locales.sort()
	for code in locales:
		if _is_locale_valid(code):
			result.append(code)
	return result

func _is_locale_valid(locale_code: String) -> bool:
	var tr_obj := TranslationServer.get_translation_object(locale_code)
	if not tr_obj:
		return false
	return not tr_obj.get_message("TR_LANG_DISPLAY_NAME").is_empty()

func _validate_locale(locale_code: String) -> String:
	if available_languages.has(locale_code):
		return locale_code
	push_warning("LanguageManager: locale '%s' is unavailable, falling back to auto" % locale_code)
	return AUTO_LOCALE

func _apply_locale(locale_code: String) -> void:
	if locale_code == _current_locale:
		return
	var resolved := _resolve_locale(locale_code)
	if resolved.is_empty():
		push_warning("LanguageManager: could not resolve locale for '%s'" % locale_code)
		return
	TranslationServer.set_locale(resolved)
	_current_locale = locale_code

func _resolve_locale(locale_code: String) -> String:
	if locale_code != AUTO_LOCALE and not locale_code.is_empty():
		return locale_code

	var system_lang := OS.get_locale_language()

	if available_languages.has(system_lang):
		return system_lang

	for lang in available_languages:
		if lang != AUTO_LOCALE and lang.begins_with(system_lang):
			return lang

	if available_languages.size() > 1:
		return available_languages[1]

	return ""
