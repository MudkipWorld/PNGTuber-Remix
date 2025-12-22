extends Window

var apply_trim : bool = false
var apply_resize : bool = false


func _ready() -> void:
	check_toggles()
	Global.project_updates.connect(check_toggles)

func _on_close_requested() -> void:
	hide()
	check_toggles()

func _on_image_trim_toggled(toggled_on: bool) -> void:
	apply_trim = toggled_on

func _on_apply_optimization_pressed() -> void:
	var save_path: String
	if Global.save_path != "":
		save_path = Global.save_path.get_basename() + "Optimized" + ".pngRemix"
	else:
		save_path = Settings.autosave_location + "/" + "Optimized" + str(randi()) + ".pngRemix"


	SaveAndLoad.import_trimmed = apply_trim
	SaveAndLoad.import_resized = apply_resize
	
	SaveAndLoad.save_model(save_path)
	await get_tree().process_frame
	await get_tree().process_frame
	SaveAndLoad.load_file(save_path)
	check_toggles()
	await get_tree().process_frame
	await get_tree().process_frame
	SaveAndLoad.import_trimmed = false
	SaveAndLoad.import_resized = false
	SaveAndLoad.save_model(save_path)

func _on_about_to_popup() -> void:
	check_toggles()

func check_toggles(_arg = ""):
	%ApplyOptimization.disabled = false
	%ImageTrim.disabled = false
	%ImageResize.disabled = false
	%ResizePrecent.editable = true

func _on_image_resize_toggled(toggled_on: bool) -> void:
	apply_resize = toggled_on

func _on_spin_box_value_changed(value: float) -> void:
	SaveAndLoad.import_percent = value
