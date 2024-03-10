@tool
extends EditorPlugin


func _enter_tree():
	# When this plugin node enters tree, add the custom type
	add_custom_type("WigglyAppendage2D", "Line2D", preload("res://addons/wiggly_appendage_2d/wiggly_appendage_2d.gd"), preload("res://addons/wiggly_appendage_2d/wiggly_appendage_2d_icon.svg"))


func _exit_tree():
	# When the plugin node exits the tree, remove the custom type
	remove_custom_type("WigglyAppendage2D")
