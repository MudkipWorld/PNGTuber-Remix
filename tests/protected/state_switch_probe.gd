extends Node
func _ready():
	call_deferred("run")
func run():
	var model := "res://DemoModels/PickleModel.pngRemix"
	var output := "user://state-switch-trace.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("output="): output = arg.trim_prefix("output=")
		if arg.begins_with("model="): model = arg.trim_prefix("model=")
	Global.set_process(false)
	Global.set_physics_process(false)
	Global.tick = 0.0
	seed(12345)
	var scene = load("res://Main/main.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(scene)
	await get_tree().create_timer(0.5).timeout
	await SaveAndLoad.load_model(model)
	Settings.save_timer.stop()
	await get_tree().create_timer(0.1).timeout
	Global.blink_timer.stop()
	Global.static_view = false
	Global.mouth = Global.Mouth.Closed
	Global.editing_for = Global.Mouth.Closed
	var actors = get_tree().get_nodes_in_group("Sprites")
	var state_count = Global.settings_dict.states.size()
	var trace := []
	for frame in 240:
		Global.tick = frame / 60.0
		if frame % 40 == 0:
			Global.load_sprite_states((frame / 40 as int) % state_count)
		for actor in actors:
			var movement = actor.get_node_or_null("%Movements")
			if movement == null: continue
			movement._physics_process(1.0 / 60.0)
			var pos = actor.get_node("%Modifier").global_position
			var drag = actor.get_node("%Dragger").global_position
			trace.append([pos.x, pos.y, drag.x, drag.y, actor.get_value("drag_snap")])
	FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(trace))
	print("STATE SWITCH TRACE WRITTEN ", trace.size(), " states=", state_count)
	get_tree().quit()
