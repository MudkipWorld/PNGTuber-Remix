extends Control

signal key_pressed

var peer
@export var users : PackedScene
var path
var port = 8910
var regex = RegEx.new()
var oldtext = ""
var has_spoken : bool = true


var speech_value : float : 
	set(value):
		if value >= Global.settings_dict.volume_limit:
			if not has_spoken:
				Global.speaking.emit()
				has_spoken = true
		
		if value < Global.settings_dict.volume_limit:
			if has_spoken:
				Global.not_speaking.emit()
				has_spoken = false

var user_id

func _process(_delta):
	var sample = AudioServer.get_bus_peak_volume_left_db(2, 0)
	var linear_sampler = db_to_linear(sample) 
	speech_value = linear_sampler * Global.settings_dict.sensitivity_limit


# Called when the node enters the scene tree for the first time.
func _ready():
	%FileDialog.use_native_dialog = true
	regex.compile("^[0-9]*$")
	%PortLine.text = str(8910)
	oldtext = str(8910)
	

func _on_line_edit_text_changed(new_text):
	if regex.search(new_text):
		oldtext = new_text
		port = oldtext.to_int()
		
	else:
		%PortLine.text = oldtext

func _on_host_button_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 2)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_user)
	add_user()

func add_user(id = 1):
	var user = users.instantiate()
	user.name = str(id)
	$Spawn.call_deferred("add_child", user)


func _on_join_button_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("localhost", port)
	multiplayer.multiplayer_peer = peer


func load_file(path, user, user_name_id):
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = file.get_var()
	
	Global.settings_dict.merge(load_dict.settings_dict, true)
	
	for sprite in load_dict.sprites_array:
		var sprite_obj = preload("res://Misc/SpriteObject/collab_sprite_object.tscn").instantiate()
		
		var img_data = Marshalls.base64_to_raw(sprite.img)
		var img = Image.new()
		img.load_png_from_buffer(img_data)
		var img_tex = ImageTexture.new()
		img_tex.set_image(img)
		sprite_obj.get_node("Wobble/Squish/Drag/Sprite2D").texture = img_tex
		sprite_obj.states = sprite.states
		sprite_obj.sprite_id = sprite.sprite_id
		sprite_obj.parent_id = sprite.parent_id
		sprite_obj.sprite_name = sprite.sprite_name
		sprite_obj.user_origin = user
		
		user.add_child(sprite_obj)

	for sprite in get_tree().get_nodes_in_group("Sprites"):
		sprite.reparent_obj(get_tree().get_nodes_in_group("Sprites"))

	for input in len(load_dict.input_array):
		get_tree().get_nodes_in_group("StateButtons")[input].input_key = load_dict.input_array[input]
		get_tree().get_nodes_in_group("StareRemapButton")[input].text = load_dict.input_array[input]
	
	Global.load_sprite_states(0)
	
	file.close()


func _on_file_dialog_file_selected(used_path):
	path = used_path
	$CanvasLayer/Panel/HostButton.disabled = false
	$CanvasLayer/Panel/JoinButton.disabled = false


func _on_select_model_pressed():
	$FileDialog.popup()


func _on_settings_pressed():
	%InputsPopup.popup()

func _on_background_input_capture_bg_key_pressed(_node, keys_pressed):
	if Global.settings_dict.checkinput:
		var keyStrings = []
		var costumeKeys = []
		for l in get_tree().get_nodes_in_group("StateButtons"):
			costumeKeys.append(InputMap.action_get_events(l.input_key)[0].as_text())
		
		
		for i in keys_pressed:
			if keys_pressed[i]:
				
				keyStrings.append(OS.get_keycode_string(i))
		
		if %FileDialog.visible:
			return
			
		
		for key in keyStrings:
			var i = costumeKeys.find(key)
			if i >= 0:
				print(i)
				key_pressed.emit(i)
