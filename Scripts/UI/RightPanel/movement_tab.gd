extends Node

@onready var select: MenuButton = %EditValuesForMenu


func _ready() -> void:
	select.get_popup().id_pressed.connect(_on_selected)
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullify)
	Global.dev_mode.connect(check_dev_mode)
	nullify()

func check_dev_mode(check : bool = false):
	%OSFFold.visible = check

func enable() -> void:
	var sp: SpriteObject = null
	if Global.held_sprites:
		sp = Global.held_sprites[0]
	
	if !is_instance_valid(sp):
		nullify()
		return
	Global.editing_for = sp.get_value("editing_for")
	select.text = select.get_popup().get_item_text(int(Global.editing_for))

func nullify() -> void:
	Global.editing_for = Global.Mouth.Closed
	select.text = select.get_popup().get_item_text(0)

func _on_selected(id) -> void:
	select.text = select.get_popup().get_item_text(id)
	Global.editing_for = id as Global.Mouth
	
	for sp in Global.held_sprites:
		sp.sprite_data.editing_for = Global.editing_for

func _on_shared_movement_changed(value: bool) -> void:
	if !value: nullify()
