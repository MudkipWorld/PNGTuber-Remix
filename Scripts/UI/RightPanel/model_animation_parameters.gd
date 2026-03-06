extends GridContainer

enum ModelAnimationType {
	MouthClosed,
	MouthOpen,
}

@export var type : ModelAnimationType

const KEY_X_FREQ_WOBBLE := "TR_X_FREQUENCY_WOBBLE"
const KEY_X_AMP_WOBBLE  := "TR_X_AMPLITUDE_WOBBLE"
const KEY_Y_FREQ_WOBBLE := "TR_Y_FREQUENCY_WOBBLE"
const KEY_Y_AMP_WOBBLE  := "TR_Y_AMPLITUDE_WOBBLE"

func _ready() -> void:
	await get_tree().current_scene.ready
	%BounceAmountSlider.get_node("%SliderValue").value_changed.connect(_on_bounce_amount_slider_value_changed)
	%GravityAmountSlider.get_node("%SliderValue").value_changed.connect(_on_gravity_amount_slider_value_changed)
	Global.update_anim.connect(set_data)
	set_data()

func set_data():
	if type == ModelAnimationType.MouthClosed:
		%BounceAmountSlider.get_node("%SliderValue").value = Global.sprite_container.state_param_mc.bounce_energy
		%GravityAmountSlider.get_node("%SliderValue").value = Global.sprite_container.state_param_mc.bounce_gravity
		%BounceAmountSlider.get_node("%SpinBoxValue").value = Global.sprite_container.state_param_mc.bounce_energy
		%GravityAmountSlider.get_node("%SpinBoxValue").value = Global.sprite_container.state_param_mc.bounce_gravity
		
		%XFreqWobbleSlider.value = Global.sprite_container.state_param_mc.xFrq
		%XAmpWobbleSlider.value = Global.sprite_container.state_param_mc.xAmp
		%YFreqWobbleSlider.value = Global.sprite_container.state_param_mc.yFrq
		%YAmpWobbleSlider.value = Global.sprite_container.state_param_mc.yAmp
		
	if type == ModelAnimationType.MouthOpen:
		%BounceAmountSlider.get_node("%SliderValue").value = Global.sprite_container.state_param_mo.bounce_energy
		%GravityAmountSlider.get_node("%SliderValue").value = Global.sprite_container.state_param_mo.bounce_gravity
		%BounceAmountSlider.get_node("%SpinBoxValue").value = Global.sprite_container.state_param_mo.bounce_energy
		%GravityAmountSlider.get_node("%SpinBoxValue").value = Global.sprite_container.state_param_mo.bounce_gravity
		%XFreqWobbleSlider.value = Global.sprite_container.state_param_mo.xFrq
		%XAmpWobbleSlider.value = Global.sprite_container.state_param_mo.xAmp
		%YFreqWobbleSlider.value = Global.sprite_container.state_param_mo.yFrq
		%YAmpWobbleSlider.value = Global.sprite_container.state_param_mo.yAmp

func _on_bounce_amount_slider_value_changed(value):
	if type == ModelAnimationType.MouthClosed:
		Global.sprite_container.state_param_mc.bounce_energy = value
		%BounceAmountSlider.get_node("%SpinBoxValue").value = value
	if type == ModelAnimationType.MouthOpen:
		Global.sprite_container.state_param_mo.bounce_energy = value
		%BounceAmountSlider.get_node("%SpinBoxValue").value = value
	Global.sprite_container.save_state(Global.current_state)
	
#	%BounceAmount.text = "Bounce Amount : " + str(value)

func _on_gravity_amount_slider_value_changed(value):
	if type == ModelAnimationType.MouthClosed:
		Global.sprite_container.state_param_mc.bounce_gravity = value
		%GravityAmountSlider.get_node("%SpinBoxValue").value = value
	if type == ModelAnimationType.MouthOpen:
		Global.sprite_container.state_param_mo.bounce_gravity = value
		%GravityAmountSlider.get_node("%SpinBoxValue").value = value
	Global.sprite_container.save_state(Global.current_state)

func _on_x_freq_wobble_slider_value_changed(value):
	if type == ModelAnimationType.MouthClosed:
		Global.sprite_container.state_param_mc.xFrq = value
	if type == ModelAnimationType.MouthOpen:
		Global.sprite_container.state_param_mo.xFrq = value

	%XFreqWobbleLabel.text = tr(KEY_X_FREQ_WOBBLE).format({ "value": value })
	Global.sprite_container.save_state(Global.current_state)

func _on_x_amp_wobble_slider_value_changed(value):
	if type == ModelAnimationType.MouthClosed:
		Global.sprite_container.state_param_mc.xAmp = value
	if type == ModelAnimationType.MouthOpen:
		Global.sprite_container.state_param_mo.xAmp = value

	%XAmpWobbleLabel.text = tr(KEY_X_AMP_WOBBLE).format({ "value": value })
	Global.sprite_container.save_state(Global.current_state)

func _on_y_freq_wobble_slider_value_changed(value):
	if type == ModelAnimationType.MouthClosed:
		Global.sprite_container.state_param_mc.yFrq = value
	if type == ModelAnimationType.MouthOpen:
		Global.sprite_container.state_param_mo.yFrq = value

	%YFreqWobbleLabel.text = tr(KEY_Y_FREQ_WOBBLE).format({ "value": value })
	Global.sprite_container.save_state(Global.current_state)

func _on_y_amp_wobble_slider_value_changed(value):
	if type == ModelAnimationType.MouthClosed:
		Global.sprite_container.state_param_mc.yAmp = value
	if type == ModelAnimationType.MouthOpen:
		Global.sprite_container.state_param_mo.yAmp = value

	%YAmpWobbleLabel.text = tr(KEY_Y_AMP_WOBBLE).format({ "value": value })
	Global.sprite_container.save_state(Global.current_state)
