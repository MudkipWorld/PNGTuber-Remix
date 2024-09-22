extends Control

@onready var view1 
@onready var view2 = $HSplitContainer/LeftPanel/VBox/VPPanel/SubViewportContainer2/SubViewport
var audio = AudioServer
var sample 
var linear_sampler

var container
var has_spoken : bool = true
var has_delayed : bool = true

var speech_value : float : 
	set(value):
		if value >= Global.settings_dict.volume_limit:
			if not has_spoken:
				%DelayBar.value = 1
				Global.speaking.emit()
				has_delayed = true
				has_spoken = true

		if value < Global.settings_dict.volume_limit:
			if has_spoken:
				has_spoken = false

var speech_delay : float : 
	set(value):
		if value < Global.settings_dict.volume_delay:
			if has_delayed:
				Global.not_speaking.emit()
				has_delayed = false



# Called when the node enters the scene tree for the first time.
func _ready():
#	tree.update_tree.connect(update_tree)
	if get_parent().has_node("SubViewportContainer/SubViewport"):
		view1 = get_parent().get_node("SubViewportContainer/SubViewport")
		view2.world_2d = view1.world_2d
		
	var sprite_nodes = get_tree().get_nodes_in_group("Sprites")
	container = get_parent().get_node("SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
	_tree(sprite_nodes)
	
	Global.reinfo.connect(update_visib_buttons)
	sliders_revalue(Global.settings_dict)

func _process(_delta):
	sample = audio.get_bus_peak_volume_left_db(2, 0)
	linear_sampler = db_to_linear(sample) 
	%VolumeBar.value = linear_sampler * Global.settings_dict.sensitivity_limit
	%DelayBar.value = move_toward(%DelayBar.value, %VolumeBar.value, 0.01)
	speech_value = %VolumeBar.value
	speech_delay = %DelayBar.value

func sliders_revalue(settings_dict):
	%BounceAmountSlider.get_node("%SliderValue").value = settings_dict.bounceSlider
	%GravityAmountSlider.get_node("%SliderValue").value = settings_dict.bounceGravity
	%BGColorPicker.color = settings_dict.bg_color
	%InputCheckButton.button_pressed = settings_dict.checkinput
	%VolumeSlider.value = settings_dict.volume_limit
	%SensitivitySlider.value = settings_dict.sensitivity_limit
	%AntiAlCheck.button_pressed = settings_dict.anti_alias
	$TopBarInput.origin_alias()
	%BounceStateCheck.button_pressed = settings_dict.bounce_state
	%XFreqWobbleSlider.value = settings_dict.xFrq
	%XAmpWobbleSlider.value = settings_dict.xAmp
	%YFreqWobbleSlider.value = settings_dict.yFrq
	%YAmpWobbleSlider.value = settings_dict.yAmp
	%AutoSaveCheck.button_pressed = settings_dict.auto_save
	%AutoSaveSpin.value = settings_dict.auto_save_timer
	%BlinkSpeedSlider.value = settings_dict.blink_speed
	%DelaySlider.value = settings_dict.volume_delay
	get_tree().get_root().get_node("Main/SubViewportContainer/%Camera2D").zoom = settings_dict.zoom
	get_tree().get_root().get_node("Main/SubViewportContainer/%CamPos").global_position = settings_dict.pan
	%DeltaTimeCheck.button_pressed = settings_dict.should_delta
	%MaxFPSlider.value = settings_dict.max_fps
	update_fps(settings_dict.max_fps)
	
	
	if %AutoSaveCheck.button_pressed:
		%AutoSaveTimer.start()


func update_fps(value):
	if value == 241:
		Engine.max_fps = 0
		return
	
	Engine.max_fps = value




func _tree(sprites):
	for i in %LayerViewBG.get_node("%LayerVBox").get_children():
		i.free()


	for sprite in sprites:
		var new_item = preload("res://UI/LayerView/layer_item.tscn").instantiate()
		new_item.get_node("%NameLabel").text = str(sprite.sprite_name)
		if sprite.dictmain.folder:
			new_item.get_node("%Icon").texture = preload("res://UI/FolderButton.png")
		else:
			new_item.get_node("%Icon").texture = sprite.get_node("%Sprite2D").texture
		var dic : Dictionary = {
			sprite_object = sprite,
			parent = new_item.get_parent()
		}
		new_item.data = dic
		sprite.treeitem = new_item
		new_item.layer_holder = %LayerViewBG
		%LayerViewBG.get_node("%LayerVBox").add_child(new_item)
	check_parent()
	update_visib_buttons()

func _added_tree(sprites):
	for sprite in sprites:
		var new_item = preload("res://UI/LayerView/layer_item.tscn").instantiate()
		new_item.get_node("%NameLabel").text = str(sprite.sprite_name)
		if sprite.dictmain.folder:
			new_item.get_node("%Icon").texture = preload("res://UI/FolderButton.png")
		else:
			new_item.get_node("%Icon").texture = sprite.get_node("%Sprite2D").texture
		var dic : Dictionary = {
			sprite_object = sprite,
			parent = new_item.get_parent()
		}
		new_item.data = dic
		sprite.treeitem = new_item
		new_item.layer_holder = %LayerViewBG
		%LayerViewBG.get_node("%LayerVBox").add_child(new_item)
		check_parent(sprite)





func loaded_tree(sprites):
	for i in sprites:
		i.reparent_obj(get_tree().get_nodes_in_group("Sprites"))
	_tree(get_tree().get_nodes_in_group("Sprites"))
	collapsing(get_tree().get_nodes_in_group("Sprites"))

func check_parent(new_item = null):
	var sprites = get_tree().get_nodes_in_group("Sprites")
	
	if new_item != null:
		if new_item.get_parent() is Sprite2D:
			var parent = new_item.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
			new_item.treeitem.get_parent().remove_child(new_item.treeitem)
			parent.add_child(new_item.treeitem)
			parent.get_node("%Collapse").disabled = false
			parent.get_node("%Intend").show()
			new_item.treeitem.get_node("%Intend2").show()
		elif new_item.get_parent() is WigglyAppendage2D:
			var parent = new_item.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
			new_item.treeitem.get_parent().remove_child(new_item.treeitem)
			parent.add_child(new_item.treeitem)
			parent.get_node("%Collapse").disabled = false
			parent.get_node("%Intend").show()
			new_item.treeitem.get_node("%Intend2").show()
	
	else:
		for x in sprites:
			if x.get_parent() is Sprite2D:
				var parent = x.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
				x.treeitem.get_parent().remove_child(x.treeitem)
				parent.get_node("%OtherLayers").add_child(x.treeitem)
				x.treeitem.get_node("%Intend2").show()
				parent.get_node("%Intend").show()
				parent.get_node("%Collapse").disabled = false
			elif x.get_parent() is WigglyAppendage2D:
				var parent = x.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
				x.treeitem.get_parent().remove_child(x.treeitem)
				parent.get_node("%OtherLayers").add_child(x.treeitem)
				x.treeitem.get_node("%Intend2").show()
				parent.get_node("%Intend").show()
				parent.get_node("%Collapse").disabled = false


func add_item(sprite):
	var new_item = preload("res://UI/LayerView/layer_item.tscn").instantiate()
	new_item.get_node("%NameLabel").text = str(sprite.sprite_name)
	if sprite.dictmain.folder:
		new_item.get_node("%Icon").texture = preload("res://UI/FolderButton.png")
	else:
		new_item.get_node("%Icon").texture = sprite.get_node("%Sprite2D").texture
	var dic : Dictionary = {
		sprite_object = sprite,
		parent = new_item.get_parent()
	}
	new_item.data = dic
	sprite.treeitem = new_item
	new_item.layer_holder = %LayerViewBG
	%LayerViewBG.get_node("%LayerVBox").add_child(new_item)
	check_parent()


func update_visib_buttons():
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.dictmain.visible:
			i.treeitem.get_node("%Visiblity").button_pressed = false
		elif not i.dictmain.visible:
			i.treeitem.get_node("%Visiblity").button_pressed = true


func collapsing(sprites):
	for i in sprites:
		if i.treeitem.get_node("%OtherLayers").get_child_count() > 0:
			i.treeitem.get_node("%Collapse").button_pressed = i.is_collapsed
	


func _on_layer_view_bg_focus_entered() -> void:
	if %LayerViewBG.has_focus():
		%LayerViewBG.release_focus()
	%LayerViewBG.deselect_all()
	%TopBarInput.desel_everything()
