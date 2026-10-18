extends Node

func _ready() -> void:
	ProjectSettings.set_setting("protected/player", true)
	var main = load("res://UI/Menu/menu.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var ui = get_node("/root/ProtectedUI")
	await ui.selected("res://tests/protected/out/测试 protected.pngRemixProtected")
	await get_tree().create_timer(0.5).timeout
	var global = get_node("/root/Global")
	if get_tree().get_nodes_in_group("Sprites").is_empty() or global.mode != 1:
		printerr("PLAYER PROBE FAILED")
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/protected/out/player-preview.png")
	print("PLAYER RENDER PROBE PASSED")
	get_node("/root/GlobInput").stop_hook()
	await get_tree().process_frame
	main._notification(NOTIFICATION_WM_CLOSE_REQUEST)
