@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("Sprite_object", "Node2D", preload("res://addons/Sprite_Object/Sprite_Object.gd"), preload("res://icon.svg"))


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("Sprite_object")
