extends Node

var should_change : bool = false

func _ready() -> void:
	await get_tree().current_scene.ready
	Global.connect("update_anim", update_anim)
	%SquishAmount.get_node("%SliderValue").value_changed.connect(_on_squish_amount_changed)
	%SquishAmount.get_node("%SpinBoxValue").value_changed.connect(_on_squish_amount_changed)
	%BlinkChanceSlider.value = 10
	Global.slider_values.connect(set_slider_data)
	update_anim()

func set_slider_data(data):
	%BlinkChanceSlider.value = data.blink_chance
	%BlinkSpeedSlider.value = data.blink_speed

func update_anim():
	should_change = false
	%BounceStateCheck.button_pressed = Global.sprite_container.bounce_state
	%MouthClosedAnim.select(Global.sprite_container.mouth_closed)
	%MouthOpenAnim.select(Global.sprite_container.mouth_open)
	%ShouldSquish.button_pressed = Global.sprite_container.should_squish
	%SquishAmount.get_node("%SliderValue").value = Global.sprite_container.squish_amount
	should_change = true

func _on_squish_amount_changed(value : float):
	add_to_undo("squish_amount",Global.sprite_container.squish_amount, value)
	Global.sprite_container.squish_amount = value
	Global.sprite_container.save_state(Global.current_state)

func _on_blink_speed_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		add_to_undo("blink_speed",Global.sprite_container.blink_speed, %BlinkSpeedSlider.value )
		Global.settings_dict.blink_speed = %BlinkSpeedSlider.value
		%BlinkSpeedLabel.text = "Blink Speed : " + str(snappedf(%BlinkSpeedSlider.value, 0.1))

func _on_blink_speed_slider_value_changed(value):
	%BlinkSpeedLabel.text = "Blink Speed : " + str(snappedf(value, 0.1))
	Global.settings_dict.blink_speed = value

func _on_should_squish_toggled(toggled_on: bool) -> void:
	add_to_undo("should_squish",Global.sprite_container.should_squish, toggled_on )
	Global.sprite_container.should_squish = toggled_on
	Global.sprite_container.save_state(Global.current_state)

func _on_blink_chance_slider_value_changed(value: float) -> void:
	add_to_undo("blink_chance",Global.settings_dict.blink_chance , value )
	%BlinkChanceLabel.text = "Blink Chance : " + str(value)
	Global.settings_dict.blink_chance = value

func _on_bounce_state_check_toggled(toggled_on):
	add_to_undo("bounce_state",Global.sprite_container.bounce_state, toggled_on )
	Global.sprite_container.bounce_state = toggled_on
	Global.sprite_container.save_state(Global.current_state)

func add_to_undo(action, value, new_value):
	if should_change:
		var d = {
		sprite_container = Global.sprite_container, 
		state = Global.current_state,
		action  = action,
		value = value,
		new_val = new_value
		}
		UndoRedoManager.push_data(d)

func _on_mouth_closed_anim_item_selected(index: int) -> void:
	Global.sprite_container.mouth_closed = index
	var old_state = Global.sprite_container.current_mc_anim
	match index:
		0:
			Global.sprite_container.current_mc_anim = "Idle"
		1:
			Global.sprite_container.current_mc_anim = "Bouncy"
		3:
			Global.sprite_container.current_mc_anim = "One Bounce"
			
		4:
			Global.sprite_container.current_mc_anim = "Wobble"
			
		5:
			Global.sprite_container.current_mc_anim = "Squish"
			
		6:
			Global.sprite_container.current_mc_anim = "Float"
	
	add_to_undo("current_mc_anim", old_state, Global.sprite_container.current_mc_anim)

	Global.sprite_container.save_state(Global.current_state)

func _on_mouth_open_anim_item_selected(index: int) -> void:
	Global.sprite_container.mouth_open = index
	var old_state = Global.sprite_container.current_mo_anim
	match index:
		0:
			Global.sprite_container.current_mo_anim = "Idle"
		1:
			Global.sprite_container.current_mo_anim = "Bouncy"
		3:
			Global.sprite_container.current_mo_anim = "One Bounce"
		4:
			Global.sprite_container.current_mo_anim = "Wobble"
		5:
			Global.sprite_container.current_mo_anim = "Squish"
		6:
			Global.sprite_container.current_mo_anim = "Float"
			
	add_to_undo("current_mo_anim", old_state, Global.sprite_container.current_mo_anim)
	Global.sprite_container.save_state(Global.current_state)
