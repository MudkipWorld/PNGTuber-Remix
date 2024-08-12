extends Control

@onready var view1 
@onready var view2 = $LeftPanel/VBox/VPPanel/SubViewportContainer2/SubViewport
@onready var tree = %LayersTree

var container
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

# Called when the node enters the scene tree for the first time.
func _ready():
	tree.update_tree.connect(update_tree)
	if get_parent().has_node("SubViewportContainer/SubViewport"):
		view1 = get_parent().get_node("SubViewportContainer/SubViewport")
		view2.world_2d = view1.world_2d
		
	var sprite_nodes = get_tree().get_nodes_in_group("Sprites")
	container = get_parent().get_node("SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
	_tree(sprite_nodes)
	
	Global.reinfo.connect(update_visib_buttons)
	sliders_revalue(Global.settings_dict)

func _process(_delta):
	var sample = AudioServer.get_bus_peak_volume_left_db(2, 0)
	var linear_sampler = db_to_linear(sample) 
	%VolumeBar.value = linear_sampler * Global.settings_dict.sensitivity_limit
	speech_value = %VolumeBar.value

func sliders_revalue(settings_dict):
	%BounceAmountSlider.value = settings_dict.bounceSlider
	%GravityAmountSlider.value = settings_dict.bounceGravity
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
	
	if %AutoSaveCheck.button_pressed:
		%AutoSaveTimer.start()

func _tree(sprites):
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Sprites")
	for i in sprites:
		var new_item
		new_item = tree.create_item(root)
		new_item.set_text(0, str(i.sprite_name))
		if i.dictmain.folder:
			new_item.set_icon(0, preload("res://UI/FolderButton.png"))
		else:
			new_item.set_icon(0, i.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture)
		
		new_item.set_icon_max_width(0, 20)
		new_item.add_button(0, preload("res://UI/EyeButton.png"), -1, false, "")
		var dic : Dictionary = {
			sprite_object = i,
			parent = new_item.get_parent()
		}
		new_item.set_metadata(0, dic)
		i.treeitem = new_item
		new_item.get_next()
	check_parent()
	update_visib_buttons()

func _added_tree(sprites):
	for i in sprites:
		var new_item
		new_item = tree.create_item(tree.get_root())
		new_item.set_text(0, str(i.sprite_name))
		new_item.add_button(0, preload("res://UI/EyeButton.png"), -1, false, "")
		if i.dictmain.folder:
			new_item.set_icon(0, preload("res://UI/FolderButton.png"))
		else:
			new_item.set_icon(0, i.texture)
		new_item.set_icon_max_width(0, 20)
		var dic : Dictionary = {
			sprite_object = i,
			parent = new_item.get_parent()
		}
		new_item.set_metadata(0, dic)
		i.treeitem = new_item
		new_item.get_next()
	check_parent()

func new_tree():
	var root = tree.create_item()
	root.set_text(0, "Sprites")

func loaded_tree(sprites):
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Sprites")
	for i in sprites:
		i.reparent_obj(get_tree().get_nodes_in_group("Sprites"))
	_tree(get_tree().get_nodes_in_group("Sprites"))

func check_parent():
	var sprites = get_tree().get_nodes_in_group("Sprites")
	for x in sprites:
		if x.get_parent() is Sprite2D:
			var parent = x.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
			x.treeitem.get_parent().remove_child(x.treeitem)
			parent.add_child(x.treeitem)
		elif x.get_parent() is WigglyAppendage2D:
			var parent = x.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
			x.treeitem.get_parent().remove_child(x.treeitem)
			parent.add_child(x.treeitem)

func update_tree(child, parent, boolean):
	var new_c_path = child.get_metadata(0)
	var new_parent = parent.get_metadata(0)
	if boolean:
		if child.get_parent() != new_parent.sprite_object:
			new_c_path.sprite_object.parent_id = new_parent.sprite_object.sprite_id
			new_c_path.sprite_object.reparent(new_parent.sprite_object.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D"))

			var dic : Dictionary = {
				sprite_object = new_c_path.sprite_object,
				parent = child.get_parent()
				}
			child.set_metadata(0, dic)
	else:
		new_c_path.sprite_object.reparent(container)
		new_c_path.sprite_object.parent_id = 0
		var dic : Dictionary = {
			sprite_object = new_c_path.sprite_object,
			parent = child.get_parent()
		}
		child.set_metadata(0, dic)
	Global.get_sprite_states(Global.current_state)
#	_tree(get_tree().get_nodes_in_group("Sprites"))

func add_item(sprite):
	var root = tree.get_root()
	var new_item
	new_item = tree.create_item(root)
	new_item.set_text(0, str(sprite.sprite_name))
	new_item.add_button(0, preload("res://UI/EyeButton.png"), -1, false, "")
	if sprite.dictmain.folder:
		new_item.set_icon(0, preload("res://UI/FolderButton.png"))
	else:
		new_item.set_icon(0, sprite.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture)
	new_item.set_icon_max_width(0, 20)
	var dic : Dictionary = {
		sprite_object = sprite,
		parent = new_item.get_parent()
	}
	new_item.set_metadata(0, dic)
	sprite.treeitem = new_item
	new_item.get_next()
	check_parent()

func _on_layers_tree_button_clicked(item, column, id, _mouse_button_index):
	item.get_metadata(0).sprite_object.dictmain.visible =! item.get_metadata(0).sprite_object.dictmain.visible 
	item.get_metadata(0).sprite_object.visible = item.get_metadata(0).sprite_object.dictmain.visible 
	item.get_metadata(0).sprite_object.save_state(Global.current_state)
#	print(column)
#	print(id)
	if item.get_metadata(0).sprite_object.visible:
		item.set_button(column, id, preload("res://UI/EyeButton.png"))
	elif not item.get_metadata(0).sprite_object.visible:
		item.set_button(column, id, preload("res://UI/EyeButton2.png"))

func update_visib_buttons():
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.dictmain.visible:
			i.treeitem.set_button(0, 0, preload("res://UI/EyeButton.png"))
		elif not i.dictmain.visible:
			i.treeitem.set_button(0, 0, preload("res://UI/EyeButton2.png"))

