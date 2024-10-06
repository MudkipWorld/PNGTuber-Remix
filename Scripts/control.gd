extends Control

@onready var view1 
@onready var view2 = $HSplitContainer/LeftPanel/VBox/VPPanel/SubViewportContainer2/SubViewport
var container
@onready var top_bar = get_tree().get_root().get_node("Main/%TopUI")

# Called when the node enters the scene tree for the first time.
func _ready():
#	tree.update_tree.connect(update_tree)
	Global.theme_update.connect(update_ui)
	if get_parent().get_parent().has_node("SubViewportContainer/SubViewport"):
		view1 = get_parent().get_parent().get_node("SubViewportContainer/SubViewport")
		view2.world_2d = view1.world_2d
		
	var sprite_nodes = get_tree().get_nodes_in_group("Sprites")
	container = get_parent().get_parent().get_node("SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")
	_tree(sprite_nodes)
	
	Global.reinfo.connect(update_visib_buttons)
	


func update_ui(index):
	match index:
		0:
			purple_theme()
		1:
			blue_theme()
		2:
			orange_theme()
		3:
			white_theme()
		4:
			dark_theme()
		5:
			green_theme()
		6:
			funky_theme()



func blue_theme():
	
	%Panelt.self_modulate = Color.LIGHT_BLUE
	%Paneln.self_modulate = Color.LIGHT_BLUE
	%PanelL1_2.self_modulate = Color.LIGHT_BLUE
	%Properties.self_modulate = Color.LIGHT_BLUE
	%LayersButtons.modulate = Color.AQUA

	%ViewportCam.modulate = Color.AQUA
	top_bar.get_node("%ResetMicButton").modulate = Color.AQUA
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	top_bar.self_modulate = Color.WHITE

func purple_theme():
	
	%Panelt.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Paneln.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%PanelL1_2.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%Properties.self_modulate = Color(0.898, 0.796, 0.996, 1 )
	%LayersButtons.modulate = Color(0.898, 0.796, 0.996, 1 )

	%ViewportCam.modulate = Color(0.898, 0.796, 0.996, 1 )
	top_bar.get_node("%ResetMicButton").modulate = Color(0.898, 0.796, 0.996, 1 )
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	top_bar.self_modulate = Color.WHITE

func orange_theme():
	
	%Panelt.self_modulate = Color.ORANGE
	%Paneln.self_modulate = Color.ORANGE
	%PanelL1_2.self_modulate = Color.ORANGE
	%Properties.self_modulate = Color.ORANGE
	%LayersButtons.modulate = Color.ORANGE

	%ViewportCam.modulate = Color.ORANGE
	top_bar.get_node("%ResetMicButton").modulate = Color.ORANGE
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	top_bar.self_modulate = Color.WHITE

func white_theme():
	
	%Panelt.self_modulate = Color.WHITE
	%Paneln.self_modulate = Color.WHITE
	%PanelL1_2.self_modulate = Color.WHITE
	%Properties.self_modulate = Color.WHITE
	%LayersButtons.modulate = Color.WHITE

	%ViewportCam.modulate = Color.WHITE
	top_bar.get_node("%ResetMicButton").modulate = Color.WHITE
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	top_bar.self_modulate = Color.WHITE

func dark_theme():
	
	%Panelt.self_modulate = Color.WEB_GRAY
	%Paneln.self_modulate = Color.WEB_GRAY
	%PanelL1_2.self_modulate = Color.WEB_GRAY
	%Properties.self_modulate = Color.WEB_GRAY
	%LayersButtons.modulate = Color.DIM_GRAY

	%ViewportCam.modulate = Color.DIM_GRAY
	top_bar.get_node("%ResetMicButton").modulate = Color.DIM_GRAY
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	top_bar.self_modulate = Color.WHITE

func green_theme():
	
	%Panelt.self_modulate = Color.LIGHT_GREEN
	%Paneln.self_modulate = Color.LIGHT_GREEN
	%PanelL1_2.self_modulate = Color.LIGHT_GREEN
	%Properties.self_modulate = Color.LIGHT_GREEN
	%LayersButtons.modulate = Color.LIGHT_GREEN

	%ViewportCam.modulate = Color.LIGHT_GREEN
	top_bar.get_node("%ResetMicButton").modulate = Color.LIGHT_GREEN
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	top_bar.self_modulate = Color.WHITE

func funky_theme():
	
	%Panelt.self_modulate = Color.SKY_BLUE
	%Paneln.self_modulate = Color.SKY_BLUE
	%PanelL1_2.self_modulate = Color.SKY_BLUE
	%Properties.self_modulate = Color.MEDIUM_SEA_GREEN
	%LayersButtons.modulate = Color.SKY_BLUE

	%ViewportCam.modulate = Color.SKY_BLUE
	top_bar.get_node("%ResetMicButton").modulate = Color.SKY_BLUE
	
	%LeftPanel.self_modulate = Color.WHITE
	%RightPanel.self_modulate = Color.WHITE
	top_bar.self_modulate = Color.WHITE





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
		new_item.get_node("%LayerItem").data = dic
		sprite.treeitem = new_item.get_node("%LayerItem")
		new_item.get_node("%LayerItem").layer_holder = %LayerViewBG
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
		new_item.get_node("%LayerItem").data = dic
		sprite.treeitem = new_item.get_node("%LayerItem")
		new_item.get_node("%LayerItem").layer_holder = %LayerViewBG
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
			new_item.treeitem.get_parent().get_parent().remove_child(new_item.treeitem.get_parent())
			parent.get_node("%OtherLayers").add_child(new_item.treeitem.get_parent())
			parent.get_node("%Collapse").disabled = false
			parent.get_node("%Intend").show()
			new_item.treeitem.get_node("%Intend2").show()
			new_item.treeitem.get_node("%Intend").show()
		elif new_item.get_parent() is WigglyAppendage2D:
			var parent = new_item.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
			new_item.treeitem.get_parent().get_parent().remove_child(new_item.treeitem.get_parent())
			parent.get_parent().add_child(new_item.treeitem.get_parent())
			parent.get_node("%Collapse").disabled = false
			parent.get_node("%Intend").show()
			new_item.treeitem.get_node("%Intend2").show()
			new_item.treeitem.get_node("%Intend").show()
	
	else:
		for x in sprites:
			if x.get_parent() is Sprite2D:
				var parent = x.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
				x.treeitem.get_parent().get_parent().remove_child(x.treeitem.get_parent())
				parent.get_node("%OtherLayers").add_child(x.treeitem.get_parent())
				x.treeitem.get_node("%Intend2").show()
				x.treeitem.get_node("%Intend").show()
				parent.get_node("%Intend").show()
				parent.get_node("%Collapse").disabled = false
			elif x.get_parent() is WigglyAppendage2D:
				var parent = x.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().treeitem
				x.treeitem.get_parent().get_parent().remove_child(x.treeitem.get_parent())
				parent.get_node("%OtherLayers").add_child(x.treeitem.get_parent())
				x.treeitem.get_node("%Intend2").show()
				x.treeitem.get_node("%Intend").show()
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
	new_item.get_node("%LayerItem").data = dic
	sprite.treeitem = new_item.get_node("%LayerItem")
	new_item.get_node("%LayerItem").layer_holder = %LayerViewBG
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
