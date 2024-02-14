extends Node

signal blink
signal reinfo
signal animation_state

signal speaking
signal not_speaking

var blink_timer : Timer = Timer.new()
var held_sprite = null
var current_state : int = 0
var blink_speed = 1
var checkinput : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().min_size = Vector2(720,720)
	add_child(blink_timer)
	blinking()

func blinking():
	blink_timer.wait_time = randf_range(1,5) * blink_speed
	blink_timer.start()
	await blink_timer.timeout
	blink.emit()
	blinking()

func get_sprite_states(state):
	current_state = state
	for i in get_tree().get_nodes_in_group("Sprites"):
		i.get_state(current_state)
	if held_sprite != null:
		emit_signal("reinfo")
		
	animation_state.emit(current_state)

func _input(_event):
	if held_sprite != null:
		if Input.is_action_pressed("ui_up"):
			held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").position.y -= 1
			offset()
		elif Input.is_action_pressed("ui_down"):
			held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").position.y += 1
			offset()
		if Input.is_action_pressed("ui_left"):
			held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").position.x -= 1
			offset()
		elif Input.is_action_pressed("ui_right"):
			held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").position.x += 1
			offset()

func offset():
	held_sprite.get_node("Wobble/Squish/Drag/Sprite2D").offset = -held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").position
	held_sprite.save_state(current_state)
