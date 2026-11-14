extends Node

const State := preload("res://Scripts/UI/States/StateButton.gd")

class CapturingServer:
	extends "res://Main/Scripts/websocket_handler.gd"
	var responses: Array[Dictionary] = []
	func send(_peer_id: int, message: String) -> int:
		responses.append(JSON.parse_string(message))
		return OK

var failures := 0
var buttons: Array[Button] = []
var server: CapturingServer
var services: Node
@onready var root: Window = get_tree().root

func _ready() -> void:
	call_deferred("run_tests")

func check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		failures += 1
		printerr("  FAIL ", description)

func run_tests() -> void:
	services = root.get_node("Global")
	for index in 3:
		var button := State.new()
		button.state = index
		button.state_name = ["Idle", "Happy", "Talking"][index]
		button.set_physics_process(false)
		var marker := Control.new()
		marker.name = "Selected"
		marker.hide()
		button.add_child(marker)
		marker.owner = button
		marker.unique_name_in_owner = true
		button.add_to_group("StateButtons")
		root.add_child(button)
		buttons.append(button)
	server = CapturingServer.new()
	root.add_child(server)
	check(State.selected_state == buttons[0], "fixture starts with the first actual StateButton selected")

	var response := request({"event": "state", "state_id": 2})
	check(Global.current_state == 1 and services.get("loaded_states").back() == 1, "state ID still loads the requested model state")
	check(State.selected_state == buttons[1], "state ID selects the matching button")
	check(not buttons[0].get_node("%Selected").visible and buttons[1].get_node("%Selected").visible, "selection marker moves from the old button to the new one")
	check(response.size() == 4 and response.event == "state" and response.result == "success" and response.state_id == 2 and response.state_name == "Happy", "success response keeps the existing JSON contract")

	response = request({"event": "state", "state_name": "Talking"})
	check(Global.current_state == 2 and State.selected_state == buttons[2], "state names synchronize the model and button selection too")
	check(not buttons[1].get_node("%Selected").visible and buttons[2].get_node("%Selected").visible, "name-based selection hides the previous marker")
	request({"event": "state", "state_id": 3})
	check(State.selected_state == buttons[2] and buttons[2].get_node("%Selected").visible, "selecting the same state twice keeps its marker visible")

	var loads_before: int = services.get("loaded_states").size()
	for invalid in [0, 99, "Unknown"]:
		response = request({"event": "state", "state_id": invalid})
		check(response.result == "failed", "invalid state %s keeps the existing failure response" % invalid)
		check(Global.current_state == 2 and State.selected_state == buttons[2], "invalid state %s does not change model or selection" % invalid)
	check(services.get("loaded_states").size() == loads_before, "invalid requests never load a model state")
	check(request({"event": "ping"}) == {"event": "pong"}, "unrelated ping messages still work")

	State.selected_state = null
	State.other_states.clear()
	for button in buttons:
		button.free()
	server.free()
	if failures == 0:
		print("All WebSocket state selection checks passed")
	else:
		printerr("%d check(s) failed" % failures)
	get_tree().quit(0 if failures == 0 else 1)

func request(payload: Dictionary) -> Dictionary:
	# Run the real parser/dispatcher; only the network send is captured.
	server._on_message(1, JSON.stringify(payload))
	return server.responses.back()
