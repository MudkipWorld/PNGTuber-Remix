extends Panel


func _ready() -> void:
	Global.update_ui_pieces.connect(ui_pieces)
	await get_tree().create_timer(0.1).timeout

func _on_layers_view_split_dragged(offset: int) -> void:
	Settings.theme_settings.layers = offset
	Settings.save()

func ui_pieces():
	%CameraPanel.visible = Settings.theme_settings.hide_mini_view
	%BG.visible = Settings.theme_settings.hide_sprite_view
	%VSplit.split_offset = Settings.theme_settings.layers
	%VSplit2.split_offset = Settings.theme_settings.file_manager

func _on_v_split_dragged(offset: int) -> void:
	Settings.theme_settings.layers = offset
	Settings.save()

func _on_v_split_2_dragged(offset: int) -> void:
	Settings.theme_settings.file_manager = offset
	Settings.save()
