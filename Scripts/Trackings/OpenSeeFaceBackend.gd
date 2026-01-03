extends TrackingRef
class_name OpenSeeFaceBackend

#  python facetracker.py -c 1 -p 8999 --model 2 -W 640 -H 480 -F 30 -s 1

func update(delta : float, backend : TrackingBackend = null):
	if not backend:
		push_error("OpenSeeFaceBackend: Backend object is null")
		return
		
	if backend.packet_queue.is_empty():
		return

	var packet: PackedByteArray = backend.packet_queue.pop_back()
	backend.packet_queue.clear()
	
	var data_package := parse_packet(packet, backend)
	if data_package.is_empty():
		return

	backend.track_rot = data_package["euler"]
	backend.track_quat = data_package["quaternion"]

	backend.track_eye_left = data_package["leftEyeOpen"]
	backend.track_eye_right = data_package["rightEyeOpen"]
	backend.track_mouth_open = data_package["features"]["MouthOpen"]
	backend.track_mouth_wide = data_package["features"]["MouthWide"]

	backend.track_features = data_package["features"]
	backend.track_points = data_package["points"]
	backend.track_points3D = data_package["points3D"]
	backend.track_confidence = data_package["confidence"]
	
	backend.smooth_mouth_open = backend.smooth_value(backend.smooth_mouth_open, backend.track_mouth_open, delta, backend.mouth_smooth_speed)
	backend.smooth_mouth_wide = backend.smooth_value(backend.smooth_mouth_wide, backend.track_mouth_wide, delta, backend.mouth_smooth_speed)
	backend.is_blink_left = backend.track_eye_left < backend.blink_close_threshold
	backend.is_blink_right = backend.track_eye_right < backend.blink_close_threshold
	backend.is_blink = backend.is_blink_left and backend.is_blink_right

	var open = backend.smooth_mouth_open
	var wide = backend.smooth_mouth_wide
	var corner_up_left  = backend.track_features.get("MouthCornerUpDownLeft", 0.0)
	var corner_up_right = backend.track_features.get("MouthCornerUpDownRight", 0.0)
	var corner_up = (corner_up_left + corner_up_right) * 0.75
	
	if open < 0.15:
		backend.mouth_form = TrackingBackend.MouthForm.CLOSED
	elif open > 0.6 and wide < 0.5:
		backend.mouth_form = TrackingBackend.MouthForm.O_SHAPE
	elif open > 0.6 and wide > 0.6:
		backend.mouth_form = TrackingBackend.MouthForm.WIDE
	elif corner_up > 0.4:
		backend.mouth_form = TrackingBackend.MouthForm.SMILE
	else:
		backend.mouth_form = TrackingBackend.MouthForm.OPEN

	var head_quat = backend.track_quat

	var euler = head_quat.get_euler()
	var target_pos = Vector2(-euler.y, -tanh(euler.x)) * TrackingBackend.osf_pos_strength

	backend.track_pos = backend.track_pos.lerp(target_pos, 0.5)
	var brow_up_left = backend.track_features.get("EyeBrowUpDownLeft", 0.0)
	var brow_up_right = backend.track_features.get("EyeBrowUpDownRight", 0.0)
	var brow_steep_left = backend.track_features.get("EyeBrowSteepnessLeft", 0.0)
	var brow_steep_right = backend.track_features.get("EyeBrowSteepnessRight", 0.0)
	var brow_quirk_left = backend.track_features.get("EyeBrowQuirkLeft", 0.0)
	var brow_quirk_right = backend.track_features.get("EyeBrowQuirkRight", 0.0)
	
	backend.smooth_brow_left = brow_up_left
	backend.smooth_brow_right = brow_up_right
	backend.brow_left_final = backend.smooth_brow_left + brow_steep_left + brow_quirk_left
	backend.brow_right_final = backend.smooth_brow_right + brow_steep_right + brow_quirk_right
	if backend.track_points3D.size() >= 70:
		var left_pupil = backend.track_points3D[67]
		var left_center = backend.track_points3D[69]
		var right_pupil = backend.track_points3D[66]
		var right_center = backend.track_points3D[68]
		var left_pupil_offset  = (left_pupil - left_center) / 15.0 
		var right_pupil_offset = (right_pupil - right_center) / 15.0
		left_pupil_offset  = Vector3(left_pupil_offset.y, left_pupil_offset.x, 0).normalized() * head_quat.get_euler()
		right_pupil_offset = Vector3(right_pupil_offset.y, right_pupil_offset.x, 0).normalized() * head_quat.get_euler()
		
		backend.track_pupil_left  = backend.track_pupil_left.slerp(Vector2(left_pupil_offset.x, -left_pupil_offset.y), 0.25)
		backend.track_pupil_right = backend.track_pupil_right.slerp(Vector2(right_pupil_offset.x, -right_pupil_offset.y), 0.25)
		var gaze_scale = 45.0
		var left_gaze_3d  = head_quat * Vector3(0, 0, -1)
		var right_gaze_3d = head_quat * Vector3(0, 0, -1)
		var left_gaze_screen  = Vector2(left_gaze_3d.x, -left_gaze_3d.y) * gaze_scale
		var right_gaze_screen = Vector2(right_gaze_3d.x, -right_gaze_3d.y) * gaze_scale
		
		backend.smooth_gaze_left  = backend.smooth_value_vec2(backend.smooth_gaze_left, left_gaze_screen, delta, backend.gaze_smooth_speed)
		backend.smooth_gaze_right = backend.smooth_value_vec2(backend.smooth_gaze_right, right_gaze_screen, delta, backend.gaze_smooth_speed)
	var eye_left  = backend.track_features.get("EyeLeft", 0.0)
	var eye_right = backend.track_features.get("EyeRight", 0.0)
	backend.eye_smile_left  = clamp(eye_left, 0.0, 1.0)
	backend.eye_smile_right = clamp(eye_right, 0.0, 1.0)
	backend.eye_smile_avg = (backend.eye_smile_left + backend.eye_smile_right) * 0.5
	
	backend.cheek_raise_left  = corner_up_left + eye_left
	backend.cheek_raise_right = corner_up_right + eye_right
	backend.cheek_average = 1.0 - (clamp(corner_up_left + eye_left, 0.0, 0.85) + clamp(corner_up_right + eye_right, 0.0, 0.85)) * 0.5
	
	var mouth_inout_left  = backend.track_features.get("MouthCornerInOutLeft", 0.0)
	var mouth_inout_right = backend.track_features.get("MouthCornerInOutRight", 0.0)
	var mouth_asymmetry = mouth_inout_right - mouth_inout_left
	var mouth_pucker = (1.0 - wide) * 0.5

func parse_packet(data: PackedByteArray, backend : TrackingBackend) -> Dictionary:
	var pkg: Dictionary = {
		"time": 0.0,
		"id": 0,
		"cam": Vector2.ZERO,
		"rightEyeOpen": 0.0,
		"leftEyeOpen": 0.0,
		"3d": 0,
		"fitError": 0.0,
		"quaternion": Quaternion.IDENTITY,
		"euler": Vector3.ZERO,
		"translation": Vector3.ZERO,
		"confidence": [],
		"points": [],
		"points3D": [],
		"features": {}
	}
	
	if data.size() == 0:
		return pkg

	var spb := StreamPeerBuffer.new()
	spb.big_endian = false
	spb.data_array = data

	pkg["time"] = spb.get_double()
	pkg["id"] = spb.get_32()
	pkg["cam"] = Vector2(spb.get_float(), spb.get_float())
	pkg["rightEyeOpen"] = spb.get_float()
	pkg["leftEyeOpen"] = spb.get_float()
	pkg["3d"] = spb.get_u8()
	pkg["fitError"] = spb.get_float()
	
	var raw_q = Quaternion(spb.get_float(), spb.get_float(), spb.get_float(), spb.get_float())
	
	pkg["quaternion"] = convert_osf_quaternion_to_godot(raw_q)

	pkg["euler"] = pkg["quaternion"].get_euler() 
	
	pkg["translation"] = Vector3(spb.get_float(), spb.get_float(), spb.get_float())
	
	var num_points := 68
	if backend and backend.has_method("get_point_count"):
		num_points = backend.get_point_count()
	elif backend and typeof(backend.points) == TYPE_INT:
		num_points = backend.points

	for i in range(num_points):
		pkg["confidence"].append(spb.get_float())

	for i in range(num_points):
		pkg["points"].append(Vector2(spb.get_float(), spb.get_float()))

	var expected_3d_points = num_points + 2 
	var bytes_remaining = data.size() - spb.get_position()
	var floats_remaining = bytes_remaining / 4
	var readable_3d_count = min(expected_3d_points, floats_remaining / 3)
	
	for i in range(readable_3d_count):
		var p = Vector3(spb.get_float(), spb.get_float(), spb.get_float())
		pkg["points3D"].append(Vector3(p.x, -p.y, -p.z))

	var feature_keys = [
		"EyeLeft","EyeRight","EyeBrowSteepnessLeft","EyeBrowUpDownLeft","EyeBrowQuirkLeft",
		"EyeBrowSteepnessRight","EyeBrowUpDownRight","EyeBrowQuirkRight",
		"MouthCornerUpDownLeft","MouthCornerInOutLeft",
		"MouthCornerUpDownRight","MouthCornerInOutRight",
		"MouthOpen","MouthWide"
	]
	
	for key in feature_keys:
		if spb.get_position() + 4 <= data.size():
			pkg["features"][key] = spb.get_float()
		else:
			pkg["features"][key] = 0.0
			
	return pkg
func convert_osf_quaternion_to_godot(q: Quaternion) -> Quaternion:
	var basis := Basis(q)
	var osf_right = basis.x
	var osf_up    = basis.y
	var osf_fwd   = basis.z
	var godot_right = Vector3(osf_right.x, -osf_right.y, -osf_right.z)
	var godot_up    = Vector3(osf_up.x,    -osf_up.y,    -osf_up.z)
	var godot_fwd   = Vector3(osf_fwd.x,   -osf_fwd.y,   -osf_fwd.z)

	var q_godot = Basis(godot_right, godot_up, godot_fwd).get_rotation_quaternion()
	return Quaternion(q_godot.x, -q_godot.y, -q_godot.z, q_godot.w)
