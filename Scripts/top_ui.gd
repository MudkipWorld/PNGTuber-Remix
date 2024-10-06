extends Control


var audio = AudioServer
var sample 
var linear_sampler


var has_spoken : bool = true
var has_delayed : bool = true

var speech_value : float : 
	set(value):
		if value >= Global.settings_dict.volume_limit:
			if not has_spoken:
				%DelayBar.value = 1
				Global.speaking.emit()
				has_delayed = true
				has_spoken = true

		if value < Global.settings_dict.volume_limit:
			if has_spoken:
				has_spoken = false

var speech_delay : float : 
	set(value):
		if value < Global.settings_dict.volume_delay:
			if has_delayed:
				Global.not_speaking.emit()
				has_delayed = false



# Called when the node enters the scene tree for the first time.
func _ready():
	sliders_revalue(Global.settings_dict)
	Global.reinfo.connect(info_held)

func info_held():
	%DeselectButton.show()

func _process(_delta):
	sample = audio.get_bus_peak_volume_left_db(2, 0)
	linear_sampler = db_to_linear(sample) 
	%VolumeBar.value = linear_sampler * Global.settings_dict.sensitivity_limit
	%DelayBar.value = move_toward(%DelayBar.value, %VolumeBar.value, 0.01)
	speech_value = %VolumeBar.value
	speech_delay = %DelayBar.value

func sliders_revalue(settings_dict):
	%BounceAmountSlider.get_node("%SliderValue").value = settings_dict.bounceSlider
	%GravityAmountSlider.get_node("%SliderValue").value = settings_dict.bounceGravity
	%BGColorPicker.color = settings_dict.bg_color
	%InputCheckButton.button_pressed = settings_dict.checkinput
	%VolumeSlider.value = settings_dict.volume_limit
	%SensitivitySlider.value = settings_dict.sensitivity_limit
	%AntiAlCheck.button_pressed = settings_dict.anti_alias
	$TopBarInput.origin_alias()
	%BounceStateCheck.button_pressed = settings_dict.bounce_state
	%XFreqWobbleSlider.value = settings_dict.xFrq
	%XAmpWobbleSlider.value = settings_dict.xAmp
	%YFreqWobbleSlider.value = settings_dict.yFrq
	%YAmpWobbleSlider.value = settings_dict.yAmp
	%AutoSaveCheck.button_pressed = settings_dict.auto_save
	%AutoSaveSpin.value = settings_dict.auto_save_timer
	%DelaySlider.value = settings_dict.volume_delay
	get_tree().get_root().get_node("Main/SubViewportContainer/%Camera2D").zoom = settings_dict.zoom
	get_tree().get_root().get_node("Main/SubViewportContainer/%CamPos").global_position = settings_dict.pan
	
	get_tree().get_root().get_node("Main/%Control/%BlinkSpeedSlider").value = Global.settings_dict.blink_speed
	%DeltaTimeCheck.button_pressed = settings_dict.should_delta
	%MaxFPSlider.value = settings_dict.max_fps
	update_fps(settings_dict.max_fps)
	
	
	if %AutoSaveCheck.button_pressed:
		%AutoSaveTimer.start()



func update_fps(value):
	if value == 241:
		Engine.max_fps = 0
		return
	
	Engine.max_fps = value


func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Global.settings_dict.volume_limit = %VolumeSlider.value


func _on_delay_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Global.settings_dict.volume_delay = %DelaySlider.value

func _on_sensitivity_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Global.settings_dict.sensitivity_limit = %SensitivitySlider.value
