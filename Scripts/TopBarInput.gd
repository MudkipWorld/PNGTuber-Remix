extends Node

@onready var files = %FilesButton
@onready var mode = %ModeButton
@onready var bgcolor = %BGButton
@onready var about = %AboutButton
var bg_color = Color.DIM_GRAY
var is_transparent : bool
var is_editor : bool = true
var last_path : String = ""
@onready var origin = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")

func _ready():
	RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
	files.get_popup().connect("id_pressed",choosing_files)
	mode.get_popup().connect("id_pressed",choosing_mode)
	bgcolor.get_popup().connect("id_pressed",choosing_bg_color)
	about.get_popup().connect("id_pressed",choosing_about)

func choosing_files(id):
	var main = get_tree().get_root().get_node("Main")
	match id:
		0:
			main.new_file()
		1:
			main.load_file()
		2:
			main.save_file(last_path)
		3:
			main.save_as_file()
		4:
			main.load_sprites()

func choosing_mode(id):
	match id:
		0:
			get_viewport().transparent_bg = false
			RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
			%RightPanel.show()
			%LeftPanel.show()
			is_editor = true
				
		1:
			RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
			get_viewport().transparent_bg = Global.settings_dict.is_transparent
			%RightPanel.hide()
			%LeftPanel.hide()
			is_editor = false
			
	if Global.held_sprite != null:
		Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D/Origin").hide()
		Global.held_sprite = null
		%LayersTree.get_selected().deselect(0)
		%UIInput.held_sprite_is_null()
		%LayersTree.deselect_all()

func choosing_bg_color(id):
	Global.settings_dict.is_transparent = false
	match id:
		0:
			Global.settings_dict.bg_color = Color.RED
		1:
			Global.settings_dict.bg_color =  Color.BLUE
		2:
			Global.settings_dict.bg_color = Color.GREEN
		3:
			Global.settings_dict.bg_color = Color.MAGENTA
		4:
			Global.settings_dict.bg_color = Color.DIM_GRAY
			Global.settings_dict.is_transparent  = true
		5:
			Global.settings_dict.bg_color = Color.SLATE_GRAY
			
		6:
			%Background.popup()
	if not is_editor:
		RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
		get_viewport().transparent_bg = Global.settings_dict.is_transparent

func choosing_about(id):
	match id:
		0:
			%AboutPopUp.popup()
		1:
			%CreditPopUp.popup()
		2:
			%TutorialPopUp.popup()

func _notification(what):
	if not is_editor:
		if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			%TopBar.show()
		elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			%TopBar.hide()

func _on_inputs_button_pressed():
	%InputsPopup.popup()

func _on_bounce_control_button_pressed():
	%BounceControlPopup.popup()

func _on_bounce_amount_slider_value_changed(value):
	Global.settings_dict.bounceSlider = value
	%BounceAmount.text = "Bounce Amount : " + str(value)

func _on_gravity_amount_slider_value_changed(value):
	Global.settings_dict.bounceGravity = value
	%GravityAmount.text = "Bounce Gravity : " + str(value)

func _on_input_check_button_toggled(toggled_on):
	Global.settings_dict.checkinput = toggled_on

func _on_color_picker_color_changed(color):
	Global.settings_dict.bg_color = color
	if not is_editor:
		RenderingServer.set_default_clear_color(color)

func update_bg_color(color, transparency):
	Global.settings_dict.bg_color = color
	Global.settings_dict.is_transparent = transparency
	%BGColorPicker.color = color

func _on_collab_button_pressed():
	pass # Replace with function body.
