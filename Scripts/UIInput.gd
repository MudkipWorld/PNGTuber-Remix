extends Node

@onready var x_amp = %XAmpSlider
@onready var x_freq = %XFSlider

@onready var y_amp = %YAmpSlider
@onready var y_freq = %YFSlider

@onready var rot = %RotationLevel
@onready var blend = %BlendMode
@onready var clip = %ClipChildren
@onready var color = %ColorPickerButton
@onready var vis = %Visible
@onready var zord = %ZOrderSpinbox
@onready var checke = %CheckEye
@onready var checkm = %CheckMouth
@onready var eyeop = %EyeOpen
@onready var mouthop = %MouthOpen
@onready var mc_anim = %MouthClosedAnim
@onready var mo_anim = %MouthOpenAnim
@onready var contain = get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	color.get_picker().picker_shape = 1
	color.get_picker().presets_visible = false
	color.get_picker().sampler_visible = false
	color.get_picker().color_modes_visible = false
	
	
	held_sprite_is_null()
	%LayersTree.connect("sprite_info", reinfo)
	Global.connect("reinfo", reinfo)
	blend.get_popup().connect("id_pressed",_on_blend_state_pressed)
	mo_anim.get_popup().connect("id_pressed",_on_mo_anim_state_pressed)
	mc_anim.get_popup().connect("id_pressed",_on_mc_anim_state_pressed)


func held_sprite_is_null():
	x_amp.editable = false
	x_freq.editable = false
	
	y_amp.editable = false
	y_freq.editable = false
	%StretchSlider.editable = false
	
	%AnimationFramesSlider.editable = false
	%AnimationSpeedSlider.editable = false
	%SizeSpinBox.editable = false
	%ReplaceButton.disabled = true
	%DuplicateButton.disabled = true
	%DeleteButton.disabled = true
	
	%Name.editable = false
	color.disabled = true
	rot.editable = false
	blend.disabled = true
	clip.disabled = true
	vis.disabled = true
	checke.disabled = true
	checkm.disabled = true
	eyeop.disabled = true
	mouthop.disabled = true
	zord.editable = false

func held_sprite_is_true():
	x_amp.editable = true
	x_freq.editable = true
	
	y_amp.editable = true
	y_freq.editable = true
	%StretchSlider.editable = true
	
	%AnimationFramesSlider.editable = true
	%AnimationSpeedSlider.editable = true
	%SizeSpinBox.editable = true
	%ReplaceButton.disabled = false
	%DuplicateButton.disabled = false
	%DeleteButton.disabled = false
	
	%Name.editable = true
	color.disabled = false
	rot.editable = true
	blend.disabled = false
	clip.disabled = false
	vis.disabled = false
	checke.disabled = false
	checkm.disabled = false
	eyeop.disabled = false
	mouthop.disabled = false
	zord.editable = true

func _on_blend_state_pressed(id):
	if Global.held_sprite:
		match id:
			0:
				Global.held_sprite.blend_mode = "Normal"
			1:
				Global.held_sprite.blend_mode = "Add"
			2:
				Global.held_sprite.blend_mode = "Subtract"
			3:
				Global.held_sprite.blend_mode = "Multiply"
				
		blend.text = Global.held_sprite.blend_mode
		Global.held_sprite.set_blend(id)
		Global.held_sprite.save_state(Global.current_state)

func _on_mo_anim_state_pressed(id):
	contain.mouth_open = id
	match id:
		0:
			contain.current_mo_anim = "Idle"
		1:
			contain.current_mo_anim = "Bouncy"
		2:
			contain.current_mo_anim = "Wavy"
		3:
			contain.current_mo_anim = "One Bounce"
			
	mo_anim.text = contain.current_mo_anim
	
	contain.save_state(Global.current_state)

func _on_mc_anim_state_pressed(id):
	contain.mouth_closed = id
	match id:
		0:
			contain.current_mc_anim = "Idle"
		1:
			contain.current_mc_anim = "Bouncy"
		2:
			contain.current_mc_anim = "Wavy"
			
		3:
			contain.current_mc_anim = "One Bounce"
			
	mc_anim.text = contain.current_mc_anim
	contain.save_state(Global.current_state)


func reinfo():
	held_sprite_is_true()
	x_amp.value = Global.held_sprite.xAmp
	x_freq.value = Global.held_sprite.xFrq
	
	y_amp.value = Global.held_sprite.yAmp
	y_freq.value = Global.held_sprite.yFrq
	
	rot.value = Global.held_sprite.rdragStr
	vis.button_pressed = Global.held_sprite.visible
	
	checke.button_pressed = Global.held_sprite.should_blink
	eyeop.button_pressed = Global.held_sprite.open_eyes
	
	checkm.button_pressed = Global.held_sprite.should_talk
	mouthop.button_pressed = Global.held_sprite.open_mouth
	
	%Name.text = Global.held_sprite.treeitem.get_text(0)
	%CurrentSelected.texture = Global.held_sprite.texture
	%AnimationFramesSlider.value = Global.held_sprite.hframes
	%AnimationSpeedSlider.value = Global.held_sprite.animation_speed
	%SizeSpinBox.value = Global.held_sprite.scale.x
	%StretchSlider.value = Global.held_sprite.stretchAmount
	color.color = Global.held_sprite.modulate
	
	if Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D").get_clip_children_mode() == 0:
		clip.button_pressed = false
	else:
		clip.button_pressed = true
		
	blend.text = Global.held_sprite.blend_mode

func reinfoanim():
	mc_anim.text = contain.current_mc_anim
	mo_anim.text = contain.current_mo_anim
	

func _on_x_amp_slider_value_changed(value):
	Global.held_sprite.xAmp = value
	%XALabel.text = "X-Amp : " + str(value)
	Global.held_sprite.save_state(Global.current_state)

func _on_xf_slider_value_changed(value):
	Global.held_sprite.xFrq = value
	%XFLabel.text = "X-Freq : " + str(value)
	Global.held_sprite.save_state(Global.current_state)

func _on_y_amp_slider_value_changed(value):
	Global.held_sprite.yAmp = value
	%YALabel.text = "Y-Amp : " + str(value)
	Global.held_sprite.save_state(Global.current_state)

func _on_yf_slider_value_changed(value):
	Global.held_sprite.yFrq = value
	%YFLabel.text = "Y-Freq : " + str(value)
	Global.held_sprite.save_state(Global.current_state)

func _on_rotation_level_value_changed(value):
	Global.held_sprite.rdragStr = value
	%Rlable.text = "Rot-Degree:" + str(value)
	Global.held_sprite.save_state(Global.current_state)


func _on_check_box_toggled(toggled_on):
	if toggled_on:
		Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D").set_clip_children_mode(2)
	else:
		Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D").set_clip_children_mode(0)
	Global.held_sprite.save_state(Global.current_state)

func _on_name_text_submitted(new_text):
	Global.held_sprite.treeitem.set_text(0, new_text)
	Global.held_sprite.save_state(Global.current_state)

func _on_visible_toggled(toggled_on):
	if toggled_on:
		Global.held_sprite.visible = true
	else:
		Global.held_sprite.visible = false
	Global.held_sprite.save_state(Global.current_state)

func _on_z_order_spinbox_value_changed(value):
	Global.held_sprite.z_index = value
	Global.held_sprite.save_state(Global.current_state)

func _on_check_eye_toggled(toggled_on):
	Global.held_sprite.should_blink = toggled_on
	if not toggled_on:
		Global.held_sprite.show()
	Global.held_sprite.save_state(Global.current_state)

func _on_eye_open_toggled(toggled_on):
	Global.held_sprite.open_eyes = toggled_on
	Global.held_sprite.blink()
	
	Global.held_sprite.save_state(Global.current_state)

func _on_check_mouth_toggled(toggled_on):
	Global.held_sprite.should_talk = toggled_on
	if not toggled_on:
		Global.held_sprite.show()
	Global.held_sprite.save_state(Global.current_state)

func _on_mouth_open_toggled(toggled_on):
	pass
	Global.held_sprite.open_mouth = toggled_on
	Global.held_sprite.check_talk()
	
	Global.held_sprite.save_state(Global.current_state)

func _on_volume_slider_value_changed(value):
	GlobalAudioStreamPlayer.volume_limit = value

func _on_sensitivity_slider_value_changed(value):
	GlobalAudioStreamPlayer.sensitivity_limit = value
	%SensitivityBar.value = value


func _on_color_picker_button_color_changed(newcolor):
	Global.held_sprite.modulate = newcolor
	Global.held_sprite.save_state(Global.current_state)


func _on_animation_frames_slider_value_changed(value):
	Global.held_sprite.hframes = value
	%AnimationFramesLabel.text = "Animation frames : " + str(value)
	Global.held_sprite.animation()
	Global.held_sprite.save_state(Global.current_state)


func _on_animation_speed_slider_value_changed(value):
	Global.held_sprite.animation_speed = value
	%AnimationSpeedLabel.text = "Animation Speed : " + str(value)
	Global.held_sprite.animation()
	Global.held_sprite.save_state(Global.current_state)


func _on_blink_speed_slider_value_changed(value):
	Global.blink_speed = value


func _on_delete_button_pressed():
	if Global.held_sprite != null:
		Global.held_sprite.treeitem.free()
		Global.held_sprite.queue_free()
		%CurrentSelected.texture = null
		Global.held_sprite = null
		held_sprite_is_null()

func _on_duplicate_button_pressed():
	var obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
	contain.add_child(obj)
	obj.texture = Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D").texture
	obj.get_node("Wobble/Squish/Drag/Sprite2D").texture = Global.held_sprite.get_node("Wobble/Squish/Drag/Sprite2D").texture
	obj.sprite_name = "Duplicate" + Global.held_sprite.sprite_name 
	get_parent()._tree(get_tree().get_nodes_in_group("Sprites"))
	
func _on_size_spin_box_value_changed(value):
	Global.held_sprite.scale = Vector2(value, value)


func _on_replace_button_pressed():
	get_tree().get_root().get_node("Main").replacing_sprite()


func _on_stretch_slider_value_changed(value):
	Global.held_sprite.stretchAmount = value
	%StretchLabel.text = "Stretch Amount : " + str(value)
	Global.held_sprite.save_state(Global.current_state)


func _on_folder_button_pressed():
	var sprte_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
	contain.add_child(sprte_obj)
	sprte_obj.texture = preload("res://Misc/SpriteObject/Folder.png")
	sprte_obj.get_node("Wobble/Squish/Drag/Sprite2D").texture = preload("res://Misc/SpriteObject/Folder.png")
	sprte_obj.sprite_name = str("Folder")
	sprte_obj.folder = true
		
	var sprite_nodes = get_tree().get_nodes_in_group("Sprites")
	get_parent()._tree(sprite_nodes)
