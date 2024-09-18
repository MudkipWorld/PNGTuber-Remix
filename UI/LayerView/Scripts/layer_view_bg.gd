extends PanelContainer
signal sprite_info 

@onready var layers_popup: PopupMenu = $LayersPopup
@onready var uiinput: = get_tree().get_root().get_node("Main/Control/UIInput")
@onready var topbarinput: = get_tree().get_root().get_node("Main/Control/TopBarInput")


func _ready() -> void:
	layers_popup.connect("id_pressed",choosing_layers_popup)

func deselect_all():
	for i in get_tree().get_nodes_in_group("Layers"):
		i.deselect()

func choosing_layers_popup(id):
	var main = get_tree().get_root().get_node("Main")
	match id:
		0:
			main.load_sprites()
		1:  
			uiinput._on_folder_button_pressed()
		2:#replace
			get_tree().get_root().get_node("Main").replacing_sprite()
		3:#duplicate
			uiinput._on_duplicate_button_pressed()
		4:#Delete
			uiinput._on_delete_button_pressed()
		5:#add normal
			get_tree().get_root().get_node("Main").add_normal_sprite()
		6: #delete normal
			uiinput._on_del_normal_button_pressed()
		7: #Deselect
			topbarinput.desel_everything()
