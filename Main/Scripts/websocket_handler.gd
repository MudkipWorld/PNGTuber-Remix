# Special credits to vj4 for the massive help!!
class_name WebSocketServer
extends Node

signal port_state

signal message_received(peer_id: int, message: String)
signal client_connected(peer_id: int)
signal client_disconnected(peer_id: int)

@export var handshake_headers := PackedStringArray()
@export var supported_protocols := PackedStringArray()
@export var handshake_timout := 7000
@export var use_tls := false
@export var tls_cert: X509Certificate
@export var tls_key: CryptoKey
@export var refuse_new_connections := false:
	set(refuse):
		if refuse:
			pending_peers.clear()
@export var port : int = 9321
var is_working : bool = false

class PendingPeer:
	var connect_time: int
	var tcp: StreamPeerTCP
	var connection: StreamPeer
	var ws: WebSocketPeer

	func _init(p_tcp: StreamPeerTCP) -> void:
		tcp = p_tcp
		connection = p_tcp
		connect_time = Time.get_ticks_msec()

var tcp_server := TCPServer.new()
var pending_peers: Array[PendingPeer] = []
var peers: Dictionary

func listen(nport: int) -> int:
	# Stop any existing server before starting new one
	if tcp_server.is_listening():
		tcp_server.stop()
		pending_peers.clear()
		peers.clear()
	return tcp_server.listen(nport)

func stop() -> void:
	tcp_server.stop()
	pending_peers.clear()
	peers.clear()
	port_state.emit(false)
	is_working = false

func start_websocket_server():
	# Ensure clean state before starting
	if tcp_server.is_listening():
		stop()
	
	var result = listen(port)
	if result == OK:
		is_working = true
		port_state.emit(true)
		print("Server now listening on port ", port)
	else:
		port_state.emit(false)
		is_working = false
		print("Failed to start server on port ", port, " - Error code: ", result)

func send(peer_id: int, message: String) -> int:
	var type := typeof(message)
	if peer_id <= 0:
		# Send to multiple peers, (zero = broadcast, negative = exclude one).
		for id: int in peers:
			if id == -peer_id:
				continue
			if type == TYPE_STRING:
				peers[id].send_text(message)
			else:
				peers[id].put_packet(message)
		return OK

	assert(peers.has(peer_id))
	var socket: WebSocketPeer = peers[peer_id]
	if type == TYPE_STRING:
		return socket.send_text(message)
	return socket.send(var_to_bytes(message))

func get_message(peer_id: int) -> Variant:
	assert(peers.has(peer_id))
	var socket: WebSocketPeer = peers[peer_id]
	if socket.get_available_packet_count() < 1:
		return null
	var pkt: PackedByteArray = socket.get_packet()
	if socket.was_string_packet():
		return pkt.get_string_from_utf8()
	return bytes_to_var(pkt)

func has_message(peer_id: int) -> bool:
	assert(peers.has(peer_id))
	return peers[peer_id].get_available_packet_count() > 0

func _create_peer() -> WebSocketPeer:
	var ws := WebSocketPeer.new()
	ws.supported_protocols = supported_protocols
	ws.handshake_headers = handshake_headers
	return ws

func poll() -> void:
	if not tcp_server.is_listening():
		return

	while not refuse_new_connections and tcp_server.is_connection_available():
		var conn: StreamPeerTCP = tcp_server.take_connection()
		assert(conn != null)
		pending_peers.append(PendingPeer.new(conn))

	var to_remove := []

	for p in pending_peers:
		if not _connect_pending(p):
			if p.connect_time + handshake_timout < Time.get_ticks_msec():
				# Timeout.
				to_remove.append(p)
			continue  # Still pending.

		to_remove.append(p)

	for r: RefCounted in to_remove:
		pending_peers.erase(r)

	to_remove.clear()

	for id: int in peers:
		var p: WebSocketPeer = peers[id]
		p.poll()

		if p.get_ready_state() != WebSocketPeer.STATE_OPEN:
			client_disconnected.emit(id)
			to_remove.append(id)
			continue

		while p.get_available_packet_count():
			message_received.emit(id, get_message(id))

	for r: int in to_remove:
		peers.erase(r)
	to_remove.clear()

func _connect_pending(p: PendingPeer) -> bool:
	if p.ws != null:
		# Poll websocket client if doing handshake.
		p.ws.poll()
		var state := p.ws.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			var id := randi_range(2, 1 << 30)
			peers[id] = p.ws
			client_connected.emit(id)
			return true  # Success.
		elif state != WebSocketPeer.STATE_CONNECTING:
			return true  # Failure.
		return false  # Still connecting.
	elif p.tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return true  # TCP disconnected.
	elif not use_tls:
		# TCP is ready, create WS peer.
		p.ws = _create_peer()
		p.ws.accept_stream(p.tcp)
		return false  # WebSocketPeer connection is pending.

	else:
		if p.connection == p.tcp:
			assert(tls_key != null and tls_cert != null)
			var tls := StreamPeerTLS.new()
			tls.accept_stream(p.tcp, TLSOptions.server(tls_key, tls_cert))
			p.connection = tls
		p.connection.poll()
		var status: StreamPeerTLS.Status = p.connection.get_status()
		if status == StreamPeerTLS.STATUS_CONNECTED:
			p.ws = _create_peer()
			p.ws.accept_stream(p.connection)
			return false  # WebSocketPeer connection is pending.
		if status != StreamPeerTLS.STATUS_HANDSHAKING:
			return true  # Failure.

		return false

func _process(_delta: float) -> void:
	poll()
	
func _ready() -> void:
	message_received.connect(_on_message)

func find_sprite_by_identifier(identifier: String):
	"""Find a sprite object by its name or ID"""
	# First try to find by name
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if sprite.sprite_name == identifier:
			return sprite
	
	# If not found by name, try to find by ID (handle both int and float)
	if identifier.is_valid_int() or identifier.is_valid_float():
		var sprite_id = int(identifier.to_float())
		for sprite in get_tree().get_nodes_in_group("Sprites"):
			if sprite.sprite_id == sprite_id:
				return sprite
	
	return null

func hide_sprite_by_identifier(identifier: String) -> bool:
	"""Hide a sprite by its name or ID. If it's a group, hides all children too. Returns true if successful, false if sprite not found"""
	var sprite = find_sprite_by_identifier(identifier)
	if sprite != null:
		# Hide the main sprite
		sprite.sprite_data.visible = false
		sprite.visible = false
		sprite.save_state(Global.current_state)
		if sprite.has_node("%Sprite2D"):
			sprite.get_node("%Sprite2D").visible = false
		if "was_active_before" in sprite:
			sprite.was_active_before = false
		
		# Hide all children recursively if this is a group
		var children = get_all_sprite_children_recursive(sprite)
		for child in children:
			child.sprite_data.visible = false
			child.visible = false
			child.save_state(Global.current_state)
			if child.has_node("%Sprite2D"):
				child.get_node("%Sprite2D").visible = false
			if "was_active_before" in child:
				child.was_active_before = false
		
		Global.reinfo.emit()
		Global.update_layer_visib.emit()
		return true
	return false

func show_sprite_by_identifier(identifier: String) -> bool:
	"""Show a sprite by its name or ID. If it's a group, shows all children too. Returns true if successful, false if sprite not found"""
	var sprite = find_sprite_by_identifier(identifier)
	if sprite != null:
		# Show the main sprite
		sprite.sprite_data.visible = true
		sprite.visible = true
		sprite.save_state(Global.current_state)
		if sprite.has_node("%Sprite2D"):
			sprite.get_node("%Sprite2D").visible = true
		if "was_active_before" in sprite:
			sprite.was_active_before = true
		
		# Show all children recursively if this is a group
		var children = get_all_sprite_children_recursive(sprite)
		for child in children:
			child.sprite_data.visible = true
			child.visible = true
			child.save_state(Global.current_state)
			if child.has_node("%Sprite2D"):
				child.get_node("%Sprite2D").visible = true
			if "was_active_before" in child:
				child.was_active_before = true
		
		Global.reinfo.emit()
		Global.update_layer_visib.emit()
		return true
	return false

func toggle_sprite_by_identifier(identifier: String) -> Dictionary:
	"""Toggle a sprite's visibility by its name or ID. If it's a group, toggles all children too. Returns result dictionary with success status and visibility state"""
	var sprite = find_sprite_by_identifier(identifier)
	if sprite != null:
		var current_visibility = sprite.get_value("visible")
		var new_visibility = !current_visibility
		
		# Toggle the main sprite
		sprite.sprite_data.visible = new_visibility
		sprite.visible = new_visibility
		sprite.save_state(Global.current_state)
		
		# Sync with reaction_config logic
		if sprite.has_node("%Sprite2D"):
			sprite.get_node("%Sprite2D").visible = new_visibility
		if "was_active_before" in sprite:
			sprite.was_active_before = new_visibility
		
		# Toggle all children recursively if this is a group
		var children = get_all_sprite_children_recursive(sprite)
		for child in children:
			child.sprite_data.visible = new_visibility
			child.visible = new_visibility
			child.save_state(Global.current_state)
			if child.has_node("%Sprite2D"):
				child.get_node("%Sprite2D").visible = new_visibility
			if "was_active_before" in child:
				child.was_active_before = new_visibility
		
		Global.reinfo.emit()
		Global.update_layer_visib.emit()
		return {"success": true, "visible": new_visibility}
	return {"success": false}

func get_sprite_children(parent_sprite) -> Array:
	"""Get all direct children of a sprite"""
	var children = []
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if sprite.parent_id == parent_sprite.sprite_id:
			children.append(sprite)
	return children

func get_all_sprite_children_recursive(parent_sprite) -> Array:
	"""Get all children of a sprite recursively (including grandchildren, etc.)"""
	var all_children = []
	var direct_children = get_sprite_children(parent_sprite)
	
	for child in direct_children:
		all_children.append(child)
		# Recursively get grandchildren
		all_children.append_array(get_all_sprite_children_recursive(child))
	
	return all_children

func has_children(sprite) -> bool:
	"""Check if a sprite has any children"""
	return get_sprite_children(sprite).size() > 0

func get_all_groups() -> Array:
	"""Get a list of all sprites that have children (groups)"""
	var groups = []
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		if has_children(sprite):
			var children = get_sprite_children(sprite)
			var child_names = []
			for child in children:
				child_names.append(child.sprite_name)
			
			groups.append({
				"name": sprite.sprite_name,
				"visible": sprite.get_value("visible"),
				"id": sprite.sprite_id,
				"children": child_names,
				"child_count": children.size()
			})
	return groups

func get_all_sprite_names() -> Array:
	"""Get a list of all sprite names with their current visibility status and group info"""
	var sprite_list = []
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		var children = get_sprite_children(sprite)
		var child_names = []
		for child in children:
			child_names.append(child.sprite_name)
		
		sprite_list.append({
			"name": sprite.sprite_name,
			"visible": sprite.get_value("visible"),
			"id": sprite.sprite_id,
			"is_group": has_children(sprite),
			"children": child_names,
			"parent_id": sprite.parent_id
		})
	return sprite_list

func find_state_by_name_or_id(identifier: String) -> int:
	"""Find a state by its name or ID. Returns the state index or -1 if not found"""
	var state_buttons = get_tree().get_nodes_in_group("StateButtons")
	
	# First try to find by name
	for i in range(state_buttons.size()):
		var state_button = state_buttons[i]
		if state_button.state_name == identifier:
			return i
	
	# If not found by name, try to find by ID (1-based indexing)
	if identifier.is_valid_int() or identifier.is_valid_float():
		var state_id = int(identifier.to_float()) - 1  # Convert to 0-based index
		if state_id >= 0 and state_id < state_buttons.size():
			return state_id
	
	return -1

func get_all_state_names() -> Array:
	"""Get a list of all state names with their IDs"""
	var state_list = []
	var state_buttons = get_tree().get_nodes_in_group("StateButtons")
	for i in range(state_buttons.size()):
		var state_button = state_buttons[i]
		state_list.append({
			"name": state_button.state_name,
			"id": i + 1,  # 1-based for user friendliness
			"is_current": i == Global.current_state
		})
	return state_list

func load_model_by_path(model_path: String) -> bool:
	"""Load a model by its file path. Returns true if successful, false if failed"""
	if not FileAccess.file_exists(model_path):
		return false
	
	if not (model_path.ends_with(".pngRemix") or model_path.ends_with(".save")):
		return false
	
	# Use SaveAndLoad directly to load the model
	SaveAndLoad.load_file(model_path)
	return true

func move_sprite_by_identifier(identifier: String, target_position: Vector2, duration: float, reset: bool = false, reset_delay: float = 0.0) -> bool:
	"""Move a sprite to a specific position with animation"""
	var sprite = find_sprite_by_identifier(identifier)
	if sprite != null:
		var original_position = sprite.position
		var tween = create_tween()
		tween.tween_property(sprite, "position", target_position, duration)
		
		if reset:
			# Wait for reset_delay, then return to original position
			tween.tween_interval(reset_delay)
			tween.tween_property(sprite, "position", original_position, duration)
		
		tween.tween_callback(func(): sprite.save_state(Global.current_state))
		return true
	return false

func animate_sprite_by_identifier(identifier: String, target_scale: Vector2, target_rotation: float, duration: float, reset: bool = false, reset_delay: float = 0.0) -> bool:
	"""Animate sprite scale and rotation"""
	var sprite = find_sprite_by_identifier(identifier)
	if sprite != null:
		var original_scale = sprite.scale
		var original_rotation = sprite.rotation
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "scale", target_scale, duration)
		tween.parallel().tween_property(sprite, "rotation", deg_to_rad(target_rotation), duration)
		
		if reset:
			# Wait for reset_delay, then return to original state
			tween.tween_interval(reset_delay)
			tween.parallel().tween_property(sprite, "scale", original_scale, duration)
			tween.parallel().tween_property(sprite, "rotation", original_rotation, duration)
		
		tween.tween_callback(func(): sprite.save_state(Global.current_state))
		return true
	return false

func shake_sprite_by_identifier(identifier: String, intensity: float, duration: float) -> bool:
	"""Shake a sprite with random movement"""
	var sprite = find_sprite_by_identifier(identifier)
	if sprite != null:
		var original_position = sprite.position
		var tween = create_tween()
		
		# Create shake effect with multiple random positions
		var shake_steps = int(duration * 20)  # 20 shakes per second
		for i in range(shake_steps):
			var random_offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			tween.tween_property(sprite, "position", original_position + random_offset, duration / shake_steps)
		
		# Return to original position
		tween.tween_property(sprite, "position", original_position, 0.1)
		tween.tween_callback(func(): sprite.save_state(Global.current_state))
		return true
	return false

func bounce_sprite_by_identifier(identifier: String, height: float, duration: float) -> bool:
	"""Bounce a sprite up and down"""
	var sprite = find_sprite_by_identifier(identifier)
	if sprite != null:
		var original_position = sprite.position
		var bounce_position = original_position + Vector2(0, -height)
		
		var tween = create_tween()
		# Bounce up
		tween.tween_property(sprite, "position", bounce_position, duration / 2)
		tween.tween_property(sprite, "position", bounce_position + Vector2(0, height * 0.1), duration / 8)
		# Bounce down
		tween.tween_property(sprite, "position", original_position, duration / 2)
		tween.tween_callback(func(): sprite.save_state(Global.current_state))
		return true
	return false

func _on_message(peer_id: int, message: String):
	print("Received message from peer %d: %s" % [peer_id, message])
	var json_data:Dictionary = {}
	var json = JSON.new()
	var error = json.parse(message)
	if error != OK:
		print("Error parsing message as JSON: %s" % message)
		send(peer_id, JSON.stringify({"event": "error", "message": "Invalid JSON format", "error_line": json.get_error_line(), "error_message": json.get_error_message()}))
		return
	
	json_data = json.data
	
	# Validate that json_data is a dictionary
	if typeof(json_data) != TYPE_DICTIONARY:
		print("Invalid message format: expected dictionary, got %s" % typeof(json_data))
		send(peer_id, JSON.stringify({"event": "error", "message": "Invalid message format: expected JSON object"}))
		return
	
	print(json_data)
	if json_data.has("event"):
			match json_data["event"]:
				"ping":
					#print("Received ping from peer %d" % peer_id)
					send(peer_id, JSON.stringify({"event": "pong"}))
				"state":
					#print("Change state received from peer %d " % peer_id)
					#print(json_data["state_id"])
					
					# Support both state_name and state_id parameters
					var identifier = str(json_data.get("state_name", json_data.get("state_id", "")))
					var state_index = find_state_by_name_or_id(identifier)
					
					if state_index >= 0:
						var state_buttons = get_tree().get_nodes_in_group("StateButtons")
						var state_button = state_buttons[state_index]
						Global.current_state = state_index
						Global.load_sprite_states(Global.current_state)
						send(peer_id, JSON.stringify({"event": "state", "result": "success", "state_id": state_index + 1, "state_name": state_button.state_name}))
					else:
						send(peer_id, JSON.stringify({"event": "state", "result": "failed", "error": "state not found", "identifier": identifier, "available_states": Global.settings_dict.get("states").size()}))
				"general":
					var key = str(json_data["key"])
					var actions_found = trigger_sprites_by_physical_key(key)
					send(peer_id, JSON.stringify({"event": "general", "result": "success", "key": key, "actions_found": actions_found}))
				"hide_sprite":
					var identifier = str(json_data.get("sprite_name", json_data.get("sprite_id", json_data.get("id", ""))))
					var result = hide_sprite_by_identifier(identifier)
					if result:
						send(peer_id, JSON.stringify({"event": "hide_sprite", "result": "success", "identifier": identifier}))
					else:
						send(peer_id, JSON.stringify({"event": "hide_sprite", "result": "failed", "identifier": identifier, "error": "sprite not found"}))
				"show_sprite":
					var identifier = str(json_data.get("sprite_name", json_data.get("sprite_id", json_data.get("id", ""))))
					var result = show_sprite_by_identifier(identifier)
					if result:
						send(peer_id, JSON.stringify({"event": "show_sprite", "result": "success", "identifier": identifier}))
					else:
						send(peer_id, JSON.stringify({"event": "show_sprite", "result": "failed", "identifier": identifier, "error": "sprite not found"}))
				"toggle_sprite":
					var identifier = str(json_data.get("sprite_name", json_data.get("sprite_id", json_data.get("id", ""))))
					var reverse = json_data.get("reverse", false)
					var match_sprite = json_data.get("match_sprite", "")
					
					var result
					if match_sprite != "":
						var target = find_sprite_by_identifier(identifier)
						var source = find_sprite_by_identifier(match_sprite)
						if target != null and source != null:
							var source_visible = source.get_value("visible")
							var new_visible = !source_visible if reverse else source_visible
							target.sprite_data.visible = new_visible
							target.visible = new_visible
							target.save_state(Global.current_state)
							if target.has_node("%Sprite2D"):
								target.get_node("%Sprite2D").visible = new_visible
							if "was_active_before" in target:
								target.was_active_before = new_visible
							
							Global.reinfo.emit()
							Global.update_layer_visib.emit()
							result = {"success": true, "visible": new_visible}
						else:
							result = {"success": false}
					else:
						result = toggle_sprite_by_identifier(identifier)
						if reverse and result.has("success"):
							# If reverse was requested but no match_sprite, we just toggle again? 
							# No, reverse without match doesn't make much sense for a single toggle.
							# But we'll keep it simple: if match_sprite is provided, we sync.
							pass

					if result.has("success"):
						var visibility_state = "visible" if result.visible else "hidden"
						send(peer_id, JSON.stringify({"event": "toggle_sprite", "result": "success", "identifier": identifier, "visibility": visibility_state}))
					else:
						send(peer_id, JSON.stringify({"event": "toggle_sprite", "result": "failed", "identifier": identifier, "error": "sprite not found"}))
				"list_sprites":
					var sprite_list = get_all_sprite_names()
					send(peer_id, JSON.stringify({"event": "list_sprites", "result": "success", "sprites": sprite_list}))
				"list_states":
					print("Debug: list_states command received")
					var state_buttons = get_tree().get_nodes_in_group("StateButtons")
					print("Debug: Found ", state_buttons.size(), " state buttons")
					
					if state_buttons.size() == 0:
						send(peer_id, JSON.stringify({"event": "list_states", "result": "failed", "error": "no state buttons found"}))
					else:
						var state_list = get_all_state_names()
						print("Debug: State list: ", state_list)
						send(peer_id, JSON.stringify({"event": "list_states", "result": "success", "states": state_list}))
				"load_model":
					var file_path = json_data.get("file_path", "")
					if file_path == "":
						send(peer_id, JSON.stringify({"event": "load_model", "result": "failed", "error": "file_path is required"}))
					else:
						var result = load_model_by_path(file_path)
						if result:
							send(peer_id, JSON.stringify({"event": "load_model", "result": "success", "file_path": file_path}))
						else:
							send(peer_id, JSON.stringify({"event": "load_model", "result": "failed", "file_path": file_path, "error": "failed to load model"}))
				"list_groups":
					var groups = get_all_groups()
					send(peer_id, JSON.stringify({"event": "list_groups", "result": "success", "groups": groups}))
				"hide_group":
					var identifier = str(json_data.get("group_name", json_data.get("group_id", json_data.get("id", ""))))
					var result = hide_sprite_by_identifier(identifier)
					if result:
						send(peer_id, JSON.stringify({"event": "hide_group", "result": "success", "identifier": identifier}))
					else:
						send(peer_id, JSON.stringify({"event": "hide_group", "result": "failed", "identifier": identifier, "error": "group not found"}))
				"show_group":
					var identifier = str(json_data.get("group_name", json_data.get("group_id", json_data.get("id", ""))))
					var result = show_sprite_by_identifier(identifier)
					if result:
						send(peer_id, JSON.stringify({"event": "show_group", "result": "success", "identifier": identifier}))
					else:
						send(peer_id, JSON.stringify({"event": "show_group", "result": "failed", "identifier": identifier, "error": "group not found"}))
				"toggle_group":
					var identifier = str(json_data.get("group_name", json_data.get("group_id", json_data.get("id", ""))))
					var reverse = json_data.get("reverse", false)
					var match_sprite = json_data.get("match_sprite", "")
					
					var result
					if match_sprite != "":
						var target = find_sprite_by_identifier(identifier)
						var source = find_sprite_by_identifier(match_sprite)
						if target != null and source != null:
							var source_visible = source.get_value("visible")
							var new_visible = !source_visible if reverse else source_visible
							
							# Apply to group (and children)
							target.sprite_data.visible = new_visible
							target.visible = new_visible
							target.save_state(Global.current_state)
							if target.has_node("%Sprite2D"):
								target.get_node("%Sprite2D").visible = new_visible
							if "was_active_before" in target:
								target.was_active_before = new_visible
								
							var children = get_all_sprite_children_recursive(target)
							for child in children:
								child.sprite_data.visible = new_visible
								child.visible = new_visible
								child.save_state(Global.current_state)
								if child.has_node("%Sprite2D"):
									child.get_node("%Sprite2D").visible = new_visible
								if "was_active_before" in child:
									child.was_active_before = new_visible
							
							Global.reinfo.emit()
							Global.update_layer_visib.emit()
							result = {"success": true, "visible": new_visible}
						else:
							result = {"success": false}
					else:
						result = toggle_sprite_by_identifier(identifier)

					if result.has("success"):
						var visibility_state = "visible" if result.visible else "hidden"
						send(peer_id, JSON.stringify({"event": "toggle_group", "result": "success", "identifier": identifier, "visibility": visibility_state}))
					else:
						send(peer_id, JSON.stringify({"event": "toggle_group", "result": "failed", "identifier": identifier, "error": "group not found"}))
				"move_sprite":
					var identifier = str(json_data.get("sprite_name", json_data.get("sprite_id", json_data.get("id", ""))))
					var x = json_data.get("x", 0.0)
					var y = json_data.get("y", 0.0)
					var duration = json_data.get("duration", 1.0)
					var reset = json_data.get("reset", false)
					var reset_delay = json_data.get("reset_delay", 0.0)
					var result = move_sprite_by_identifier(identifier, Vector2(x, y), duration, reset, reset_delay)
					if result:
						send(peer_id, JSON.stringify({"event": "move_sprite", "result": "success", "identifier": identifier, "x": x, "y": y, "duration": duration, "reset": reset}))
					else:
						send(peer_id, JSON.stringify({"event": "move_sprite", "result": "failed", "identifier": identifier, "error": "sprite not found"}))
				"animate_sprite":
					var identifier = str(json_data.get("sprite_name", json_data.get("sprite_id", json_data.get("id", ""))))
					var scale_x = json_data.get("scale_x", json_data.get("scale", 1.0))
					var scale_y = json_data.get("scale_y", scale_x)
					var rotation = json_data.get("rotation", 0.0)
					var duration = json_data.get("duration", 1.0)
					var reset = json_data.get("reset", false)
					var reset_delay = json_data.get("reset_delay", 0.0)
					var result = animate_sprite_by_identifier(identifier, Vector2(scale_x, scale_y), rotation, duration, reset, reset_delay)
					if result:
						send(peer_id, JSON.stringify({"event": "animate_sprite", "result": "success", "identifier": identifier, "scale_x": scale_x, "scale_y": scale_y, "rotation": rotation, "duration": duration, "reset": reset}))
					else:
						send(peer_id, JSON.stringify({"event": "animate_sprite", "result": "failed", "identifier": identifier, "error": "sprite not found"}))
				"shake_sprite":
					var identifier = str(json_data.get("sprite_name", json_data.get("sprite_id", json_data.get("id", ""))))
					var intensity = json_data.get("intensity", 10.0)
					var duration = json_data.get("duration", 1.0)
					var result = shake_sprite_by_identifier(identifier, intensity, duration)
					if result:
						send(peer_id, JSON.stringify({"event": "shake_sprite", "result": "success", "identifier": identifier, "intensity": intensity, "duration": duration}))
					else:
						send(peer_id, JSON.stringify({"event": "shake_sprite", "result": "failed", "identifier": identifier, "error": "sprite not found"}))
				"bounce_sprite":
					var identifier = str(json_data.get("sprite_name", json_data.get("sprite_id", json_data.get("id", ""))))
					var height = json_data.get("height", 20.0)
					var duration = json_data.get("duration", 0.5)
					var result = bounce_sprite_by_identifier(identifier, height, duration)
					if result:
						send(peer_id, JSON.stringify({"event": "bounce_sprite", "result": "success", "identifier": identifier, "height": height, "duration": duration}))
					else:
						send(peer_id, JSON.stringify({"event": "bounce_sprite", "result": "failed", "identifier": identifier, "error": "sprite not found"}))
				"throw_item":
					if Global.throwable_spawner == null or not is_instance_valid(Global.throwable_spawner):
						send(peer_id, JSON.stringify({"event": "throw_item", "result": "failed", "error": "throwable spawner not active"}))
					else:
						var item_name = str(json_data.get("item_name", ""))
						var amount = int(json_data.get("amount", 1))
						var variance = float(json_data.get("variance", -1.0))
						var both_sides_val = -1
						if json_data.has("both_sides"):
							both_sides_val = 1 if bool(json_data["both_sides"]) else 0
						
						var found_img = null
						if item_name != "":
							for img in Global.image_manager_data:
								if img.image_name == item_name:
									found_img = img
									break
						
						if found_img != null:
							Global.throwable_spawner.throw_specific_item(found_img, amount, variance, both_sides_val)
							send(peer_id, JSON.stringify({"event": "throw_item", "result": "success", "item_name": item_name, "amount": amount}))
						else:
							send(peer_id, JSON.stringify({"event": "throw_item", "result": "failed", "item_name": item_name, "error": "item not found"}))
				"throw_random":
					if Global.throwable_spawner == null or not is_instance_valid(Global.throwable_spawner):
						send(peer_id, JSON.stringify({"event": "throw_random", "result": "failed", "error": "throwable spawner not active"}))
					else:
						var amount = int(json_data.get("amount", -1))
						var variance = float(json_data.get("variance", -1.0))
						var both_sides_val = -1
						if json_data.has("both_sides"):
							both_sides_val = 1 if bool(json_data["both_sides"]) else 0
							
						if amount > 0:
							Global.throwable_spawner.throw_random_items(amount, variance, both_sides_val)
						else:
							Global.throwable_spawner.throw_random_items(Global.throwable_spawner.throw_per_trigger, variance, both_sides_val)
						
						send(peer_id, JSON.stringify({"event": "throw_random", "result": "success"}))
				_:
					send(peer_id, JSON.stringify({"event": "error", "message": "Unknown event: " + str(json_data.get("event", "unknown"))}))
					#print(Global.current_state)
	else:
		# No "event" key found in the message
		send(peer_id, JSON.stringify({"event": "error", "message": "Missing 'event' field in message"}))

func trigger_sprites_by_physical_key(key_str: String) -> Array:
	var key_code = OS.find_keycode_from_string(key_str)
	if key_code == KEY_NONE:
		# Manual fallback for common number keys if string search fails
		match key_str:
			"0": key_code = KEY_0
			"1": key_code = KEY_1
			"2": key_code = KEY_2
			"3": key_code = KEY_3
			"4": key_code = KEY_4
			"5": key_code = KEY_5
			"6": key_code = KEY_6
			"7": key_code = KEY_7
			"8": key_code = KEY_8
			"9": key_code = KEY_9

	if key_code == KEY_NONE:
		return []

	var items_triggered = []
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		var triggered = false
		
		# 1. Check if this is the sprite's main Bind Key
		if sprite.get("saved_event") is InputEventKey:
			if sprite.saved_event.keycode == key_code or sprite.saved_event.physical_keycode == key_code:
				toggle_sprite_by_identifier(str(sprite.sprite_id))
				items_triggered.append(sprite.sprite_name + " (Toggle)")
				triggered = true
		
		# 2. Check if this is one of the sprite's Hide Keys
		if !triggered:
			var action_name = str(sprite.sprite_id) + "Disappear"
			if InputMap.has_action(action_name):
				for event in InputMap.action_get_events(action_name):
					if event is InputEventKey:
						if event.keycode == key_code or event.physical_keycode == key_code:
							hide_sprite_by_identifier(str(sprite.sprite_id))
							items_triggered.append(sprite.sprite_name + " (Hide)")
							break
							
	return items_triggered
