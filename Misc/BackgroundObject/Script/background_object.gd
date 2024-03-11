extends Node2D

#Movement
var heldTicks = 0
var dragSpeed = 0
@onready var dragger = $Wobble/Squish/Drag
@onready var wob = $Wobble
@onready var sprite = $Wobble/Squish/Drag/Sprite2D
@onready var contain = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
@onready var img = $Wobble/Squish/Drag/Sprite2D.texture.get_image()
#Wobble
var squish = 1
var texture 

# Misc
var treeitem : TreeItem
var visb
var tick = 0
var sprite_name : String = ""
@export var states : Array = [{},{},{},{},{},{},{},{},{},{}]
var coord
var dragging : bool = false
var of = Vector2(0,0)

var sprite_id : float
var parent_id : float = 0
var physics_effect = 1
var glob
var sprite_type : String = "Sprite2D"

@onready var dictmain : Dictionary = {
	blend_mode = "Normal",
	visible = visible,
	colored = modulate,
	z_index = z_index,
	animation_speed = 1,
	hframes = 1,
	scale = scale,
	global_position = global_position,
	rotation = rotation,
	offset = $Wobble/Squish/Drag/Sprite2D.offset,
	clip = 0,
	}
var smooth_rot = 0.0
var smooth_glob = Vector2(0.0,0.0)



# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	print(get_node("Wobble/Squish/Drag/Sprite2D/Grab").pivot_offset)
	
	


func _process(_delta):
	if Global.held_bg_sprite == self:
		%Grab.mouse_filter = 1
	else:
		%Grab.mouse_filter = 2
	if dragging:
		global_position = get_global_mouse_position() - of
		smooth_glob = get_global_mouse_position() - of
		get_tree().get_root().get_node("Main/Control/BackgroundEdit").update_pos_spins()
		save_state(Global.current_state)
		
	
	

func save_state(id):
	var dict : Dictionary = {
	blend_mode = dictmain.blend_mode,
	visible = visible,
	colored = modulate,
	z_index = z_index,
	animation_speed = dictmain.animation_speed ,
	hframes = dictmain.hframes,
	scale = scale,
	global_position = global_position,
	rotation = rotation,
	offset = $Wobble/Squish/Drag/Sprite2D.offset,
	clip = dictmain.clip,
	}
	states[id] = dict


func get_state(id):
	if not states[id].is_empty():
		var dict = states[id]
		dictmain.merge(dict, true)
		z_index = dictmain.z_index
		modulate = dictmain.colored
		visible = dictmain.visible
		scale = dictmain.scale
		global_position = dictmain.global_position
		$Wobble/Squish/Drag/Sprite2D.offset = dictmain.offset 
		$Wobble/Squish/Drag/Sprite2D/Origin.position = - dictmain.offset 
		get_node("Wobble/Squish/Drag/Sprite2D").set_clip_children_mode(dictmain.clip)
		rotation = dictmain.rotation
		
		set_blend(dictmain.blend_mode)


func set_blend(blend):
	match  blend:
		"Normal":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", false)
		"Add":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/add.png"))
		"Subtract":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/exclusion.png"))
		"Multiply":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/multiply.png"))
		"Burn":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/burn.png"))
		"HardMix":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/hardmix.png"))
		"Cursed":
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("enabled", true)
			$Wobble/Squish/Drag/Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/test1.png"))


func _on_grab_button_down():
	if Global.held_bg_sprite == self:
		of = get_global_mouse_position() - global_position
		dragging = true


func _on_grab_button_up():
	if Global.held_bg_sprite == self:
		dragging = false
		save_state(Global.current_state)


