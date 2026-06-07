extends Resource
class_name ThrowableResource

var mass : float = 1.0
var friction : float = 0.0
var rough : bool = false

var bounce : float = 1.0
var absorb : bool = false

var gravity_scale : float = 1.0

var inertia : float = 2.0

var collision_shape : Shape2D = CircleShape2D.new()
var image_data : ImageData = null
var audio_data : AudioStreamMP3 = null
var audio_buffer : PackedByteArray

func set_initial_data():
	if image_data == null : return
	var w : float = float(image_data.runtime_texture.get_image().get_width())
	var h : float = float(image_data.runtime_texture.get_image().get_height())
	var r : float = min(w, h)
	collision_shape.radius = Vector2(r, r).length()*0.5
	mass = collision_shape.radius/50

func recreate_audio():
	if audio_buffer.is_empty() : return
	var audio_stream : AudioStreamMP3 = AudioStreamMP3.load_from_buffer(audio_buffer)
	if audio_stream != null:
		audio_data = audio_stream
