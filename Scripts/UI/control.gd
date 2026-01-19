extends Control


func _ready() -> void:
	Global.update_ui_pieces.connect(ui_pieces)

func ui_pieces():
	%VSplit.split_offset = Settings.theme_settings.properties
	%MainSplit.split_offset = Settings.theme_settings.left
	%SecondarySplit.split_offset = Settings.theme_settings.right

func _on_v_split_dragged(offset: int) -> void:
	Settings.theme_settings.properties = offset
	Settings.save()

func _on_main_split_dragged(offset: int) -> void:
	Settings.theme_settings.left = offset
	Settings.save()

func _on_secondary_split_dragged(offset: int) -> void:
	Settings.theme_settings.right = offset
	Settings.save()
