extends RigidBody2D
class_name ThrowableObject

var throw_resource : ThrowableResource

@export var sprite_object : Sprite2D
@export var collision : CollisionShape2D

func _ready() -> void:
	if sprite_object == null or collision == null: return
	pass
	'''
	if sprite_object.texture:
		var w : float = float(sprite_object.texture.get_image().get_width())
		var h : float = float(sprite_object.texture.get_image().get_height())
		var r : float = min(w, h)
		collision.shape.radius = Vector2(r, r).length()*0.5
		mass *= collision.shape.radius/50
	'''

func set_data(base_mass : float = 1):
	if throw_resource == null : return
	mass = throw_resource.mass * base_mass
	collision.shape = throw_resource.collision_shape
	sprite_object.texture = throw_resource.image_data.runtime_texture
	%AudioPlayer.stream = throw_resource.audio_data

func _physics_process(_delta: float) -> void:
	for i in get_colliding_bodies():
		if i is StaticBody2D:
			var vel : Vector2 = linear_velocity
			var obj : SpriteObject = i.owner
			sprite_object.rotation = vel.normalized().angle()
			if obj.get_value("can_be_hit"):
				%AudioPlayer.play()
				obj.get_node("%Movements").hit_rotation -= vel.normalized().x * obj.get_value("reaction_strength") * mass

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
