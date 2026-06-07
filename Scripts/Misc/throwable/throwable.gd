extends RigidBody2D
class_name ThrowableObject

var throw_resource : ThrowableResource

@export var sprite_object : Sprite2D
@export var collision : CollisionShape2D
var audio_played : bool = false

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
	
	gravity_scale = throw_resource.gravity_scale
	inertia = throw_resource.inertia
	
	physics_material_override.absorbent = throw_resource.absorb
	physics_material_override.friction = throw_resource.friction
	physics_material_override.bounce = throw_resource.bounce
	physics_material_override.rough = throw_resource.rough
	
	%AudioPlayer.stream = throw_resource.audio_data

func _physics_process(_delta: float) -> void:
	for i in get_colliding_bodies():
		if i is StaticBody2D:
			var vel : Vector2 = linear_velocity
			var obj : SpriteObject = i.owner
			sprite_object.rotation = vel.normalized().angle()
			if obj.get_value("can_be_hit"):
				if !audio_played:
					%AudioPlayer.play()
				obj.get_node("%Movements").hit_rotation -= vel.normalized().x * obj.get_value("reaction_strength") * mass
				audio_played = true

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	await get_tree().create_timer(2).timeout
	queue_free()
