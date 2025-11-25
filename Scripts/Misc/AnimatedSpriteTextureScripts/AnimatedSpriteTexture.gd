extends Node
class_name AnimatedSpriteTexture

@export var actor : Node
@export var sprite_node : Node
var index : int = 0
var dt : float = 0
var played_once : bool = false

func _ready() -> void:
	if actor.sprite_type == "Comment":
		set_physics_process(false)
		set_process(false)


func _physics_process(delta):
	var cframe2
	if actor.referenced_data == null:
		return
	var ref_data = actor.referenced_data.animated_frames
	var ref_data_normal
	if actor.referenced_data_normal == null:
		ref_data_normal = []
	else:
		ref_data_normal = actor.referenced_data_normal.animated_frames
		
	if actor.referenced_data.is_apng or actor.referenced_data.img_animated:
		if !played_once:
			if len(ref_data) == 0:
				return
			if index >= len(ref_data):
				if actor.get_value("one_shot"):
					played_once = true
					return
				index = 0
			dt += delta
			var cframe = ref_data[index]
			if sprite_node.texture.normal_texture:
				if index in range(ref_data_normal.size()):
					cframe2 = ref_data_normal[index]
			if dt >= cframe.duration:
				dt -= cframe.duration
				index += 1
			# yes this does this every _process, oh well
			sprite_node.texture.set_diffuse_texture.call_deferred(cframe.texture)
			if sprite_node.texture.normal_texture != null:
				if actor.referenced_data_normal.animated_frames.size() != actor.referenced_data.animated_frames.size():
					actor.referenced_data_normal.animated_frames.resize(actor.referenced_data.animated_frames.size())
				if cframe2 != null:
					sprite_node.texture.set_normal_texture.call_deferred(cframe2.texture)


func proper_apng_one_shot():
	if actor.sprite_type == "Comment":
		return
	if actor.referenced_data == null:
		return
	var ref_data = actor.referenced_data.animated_frames
	var ref_data_normal
	if actor.referenced_data_normal == null:
		ref_data_normal = []
	else:
		ref_data_normal = actor.referenced_data_normal.animated_frames
	var cframe = ref_data[0]
	sprite_node.texture.diffuse_texture = cframe.texture
	if ref_data_normal.size() > 0:
		var cframe2 = ref_data_normal[0]
		sprite_node.texture.normal_texture = cframe2.texture
