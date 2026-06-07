extends Button
class_name BetterToggles


var should_change : bool = false
@export var sp_type : String = "Null"
@export var seen_type : String = "Zaza"
@export var value_to_update : String = "position": get = get_value
@export var has_alt_values := false
@export var inverted := false

func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	Global.editing_for_changed.connect(enable)
	nullfy()
	toggle_mode = true
	toggled.connect(on_toggle)

func enable():
	should_change = false
	if sp_type == "Null": return
	if Global.held_sprites.is_empty(): return
	
	var sp: SpriteObject = null
	var seen = false
	for x in Global.held_sprites:
		if !is_instance_valid(x): continue
		if sp_type not in [x.sprite_type, ""]: continue
		if seen_type.to_lower()  == x.sprite_type.to_lower() : 
			seen = true
			break
		
		sp = x
	
	if seen:
		nullfy()
		return
		
	
	if !is_instance_valid(sp): return
	disabled = false
	button_pressed = sp.sprite_data[value_to_update] != inverted
	await get_tree().process_frame
	should_change = true

func get_value() -> String:
	if !has_alt_values:
		return value_to_update
	
	match Global.editing_for:
		Global.Mouth.Open:
			return "mo_" + value_to_update
		Global.Mouth.Screaming:
			return "scream_" + value_to_update
	
	return value_to_update

func nullfy():
	disabled = true

func on_toggle(toggle : bool):
	if !should_change: return
	if sp_type == "Null": return
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		var og_val = i.sprite_data[value_to_update]
		if sp_type in [i.sprite_type, ""]:
			i.sprite_data[value_to_update] = toggle != inverted
			StateButton.multi_edit(i.sprite_data[value_to_update], value_to_update, i, i.states)
			i.save_state(Global.current_state)
		undo_redo_data.append({
				node = i,
				action = value_to_update,
				state = Global.current_state,
				value = og_val, 
				new_val = i.sprite_data[value_to_update]
			})
		if i.sprite_type == "WiggleApp" and sp_type == "WiggleApp":
			i.update_wiggle_parts()
	UndoRedoManager.push_data(undo_redo_data)
