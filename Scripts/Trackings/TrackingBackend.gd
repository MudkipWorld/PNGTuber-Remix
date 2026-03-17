extends Node
class_name TrackingBackend

enum MouthForm {CLOSED, OPEN, WIDE, O_SHAPE, SMILE}

signal eye_right_blink
signal eye_left_blink
signal eyes_blink

@export var listen_port: int = 11573
@export var listen_host: String = "127.0.0.1"
@export var points: int = 68
static var blink_close_threshold := 0.5
static var blink_open_threshold := 0.5
@export var mouth_smooth_speed := 25.0
@export var brow_smooth_speed := 5.0
@export var gaze_smooth_speed := 10.0
@export var capture_fps : float = 60

const UPPER_LIP = 62
const LOWER_LIP = 66
const NOSE_BRIDGE = 27
const CHIN = 8
const MOUTH_LEFT = 48
const MOUTH_RIGHT = 54

var mouth_form := MouthForm.CLOSED
var track_pos: Vector2 = Vector2.ZERO
var track_rot: Vector3 = Vector3.ZERO
var track_quat: Quaternion 
var track_eye_left: float = 0.0
var track_eye_right: float = 0.0
var track_mouth_open: float = 0.0
var track_mouth_wide: float = 0.0
var track_features: Dictionary = {}
var track_points: Array = []
var track_points3D: Array = []
var track_confidence: Array = []

var smooth_mouth_open := 0.0
var smooth_mouth_wide := 0.0
var smooth_brow_left := 0.0
var smooth_brow_right := 0.0
var brow_left_final : float = 0.0
var brow_right_final : float = 0.0
var smooth_gaze_left: Vector2 = Vector2.ZERO
var smooth_gaze_right: Vector2 = Vector2.ZERO
var cheek_raise_left  = 0.0
var cheek_raise_right = 0.0
var cheek_average = 0.0

var is_blink_left := false
var is_blink_right := false
var is_blink := false

var udp: PacketPeerUDP
var packet_queue: Array = []
var stop_thread := false
var receive_thread: Thread

var eye_smile_left: float = 0.0
var eye_smile_right: float = 0.0
var eye_smile_avg: float = 0.0


var track_pupil_left: Vector2 = Vector2.ZERO
var track_pupil_right: Vector2 = Vector2.ZERO

var is_mouth_open := false

var current_tracker : TrackingRef = OpenSeeFaceBackend.new()
static var osf_pos_strength : float = 10
static var osf_mouth_strength : float = -0.05
var working : bool = false

func start_backend():
	udp = PacketPeerUDP.new()
	var err = udp.bind(listen_port)
	if err != OK:
		working = false
		push_error("Failed to bind UDP on port %d" % listen_port)
		return
	udp.set_broadcast_enabled(true)
	print("UDP server listening on %s:%d" % [listen_host, listen_port])
	working = true

func stop_backend():
	stop_thread = true
	udp.close()
	working = false

func _exit_tree():
	stop_thread = true
	if receive_thread and receive_thread.is_active():
		receive_thread.wait_to_finish()
	if udp:
		udp.close()
	working = false

func _udp_receive_loop():
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		packet_queue.append(packet)

func _physics_process(delta: float) -> void:
	if current_tracker == null: return
	if working:
		_udp_receive_loop()
		current_tracker.update(delta, self)

func smooth_value(current: float, target: float, delta: float, speed: float) -> float:
	return lerp(current, target, 1.0 - exp(-speed * delta))

func smooth_value_vec2(current: Vector2, target: Vector2, delta: float, speed: float) -> Vector2:
	return current.lerp(target, 1.0 - exp(-speed * delta))

func get_mouth_frame_8(form, open, _wide, smile) -> float:
	match form:
		MouthForm.CLOSED:
			return 7
		MouthForm.SMILE:
			return lerp(5.0, 3.0, smile)
		MouthForm.O_SHAPE:
			return 2
		MouthForm.WIDE:
			return 0
		MouthForm.OPEN:
			if open > 0.9:
				return 0
			return lerp(6.0, 5.0, open)
	return 7
