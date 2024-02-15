extends Control

@onready var view1 
@onready var view2 = $LeftPanel/VBox/VPPanel/SubViewportContainer2/SubViewport
@onready var tree = %LayersTree
var container
var has_spoken : bool = true
var speech_value : float : 
	set(value):
		if value >= GlobalAudioStreamPlayer.volume_limit:
			if not has_spoken:
				Global.speaking.emit()
				has_spoken = true
		
		if value < GlobalAudioStreamPlayer.volume_limit:
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

func _process(_delta):
	var sample = AudioServer.get_bus_peak_volume_left_db(2, 0)
	var linear_sampler = db_to_linear(sample) 
	%VolumeBar.value = linear_sampler * GlobalAudioStreamPlayer.sensitivity_limit
	speech_value = %VolumeBar.value

func sliders_revalue(volume, sensi, bounce, gravity, check):
	%VolumeSlider.value = volume
	%SensitivityBar.value = sensi
	%SensitivitySlider.value = sensi
	%BounceAmountSlider.value = bounce
	%GravityAmountSlider.value = gravity
	%InputCheckButton.button_pressed = check

func _tree(sprites):
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Sprites")
	for i in sprites:
		var new_item
		new_item = tree.create_item(root)
		new_item.set_text(0, str(i.sprite_name))
		if i.folder:
			new_item.set_icon(0, preload("res://UI/FolderButton.png"))
		else:
			new_item.set_icon(0, i.get_node("Wobble/Squish/Drag/Sprite2D").texture)
		new_item.set_icon_max_width(0, 20)
		var dic : Dictionary = {
			sprite_object = i,
			parent = new_item.get_parent()
		}
		new_item.set_metadata(0, dic)
		i.treeitem = new_item
		new_item.get_next()
	check_parent()

func loaded_tree(sprites):
	for i in sprites:
		i.reparent_obj(get_tree().get_nodes_in_group("Sprites"))


func check_parent():
	var sprites = get_tree().get_nodes_in_group("Sprites")
	for x in sprites:
		if x.get_parent() is Sprite2D:
			var parent = x.get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
			x.treeitem.get_parent().remove_child(x.treeitem)
			parent.add_child(x.treeitem)

func update_tree(child, parent, boolean):
	var new_c_path = child.get_metadata(0)
	var new_parent = parent.get_metadata(0)
	if boolean:
		if child.get_parent() != new_parent.sprite_object:
			new_c_path.sprite_object.parent_id = new_parent.sprite_object.sprite_id
			print(new_c_path.sprite_object.parent_id)
			new_c_path.sprite_object.reparent(new_parent.sprite_object.get_node("Wobble/Squish/Drag/Sprite2D"))

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
	_tree(get_tree().get_nodes_in_group("Sprites"))

func add_item(sprite):
	var root = tree.get_root()
	var new_item
	new_item = tree.create_item(root)
	new_item.set_text(0, str(sprite.sprite_name))
	if sprite.folder:
		new_item.set_icon(0, preload("res://UI/FolderButton.png"))
	else:
		new_item.set_icon(0, sprite.get_node("Wobble/Squish/Drag/Sprite2D").texture)
	new_item.set_icon_max_width(0, 20)
	var dic : Dictionary = {
		sprite_object = sprite,
		parent = new_item.get_parent()
	}
	new_item.set_metadata(0, dic)
	sprite.treeitem = new_item
	new_item.get_next()
	check_parent()
