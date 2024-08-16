# Made by Henrique Alves
@tool
extends EditorPlugin

func _enter_tree():
	# When this plugin node enters tree, add the custom type
	add_custom_type("Recorder","ReferenceRect",preload("res://addons/Recorder/recorder.gd"),preload("res://addons/Recorder/recorder_icon.png"))

func _exit_tree():
	# When the plugin node exits the tree, remove the custom type
	remove_custom_type("Recorder")
