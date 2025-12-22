extends MarginContainer

enum LoadType {
	Images,
	Replace
}

var load_type : LoadType = LoadType.Images
var held_button : Control = null
var checked_sprited : Array = []
var held_items_assets : Array = []
var paths_placeholder = []
var path_placeholder : String = ""

func _ready() -> void:
	Global.remake_image_manager.connect(remake_files)
	Global.add_new_image.connect(add_file)
	create_default()

func create_default():
	%Tree.clear()
	var root : TreeItem = %Tree.create_item()
	root.set_text(0, "TR_FILE_SYSTEM")
	root.set_selectable(0, false)
	
	var assets : TreeItem = %Tree.create_item(root)
	assets.set_text(0, "TR_IMAGES")
	assets.set_selectable(0, false)
	
	'''
	var extensions : TreeItem = %Tree.create_item(root)
	extensions.set_text(0, "Extensions")
	extensions.set_selectable(0, false)'''

func _on_collapse_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%CollapseButton.icon = preload("res://UI/Assets/Collapse1.png")
		
	else:
		%CollapseButton.icon = preload("res://UI/Assets/Collapse2.png")
		
	%ManageContain.visible = toggled_on

func open_popup(node : Control):
	held_button = node
	print(node)

func remake_files():
	held_button = null
	create_default()
	for i in Global.image_manager_data:
		add_file(i)
	
	var assets : TreeItem = %Tree.get_root().get_child(0)
	assets.set_text(0, "Images " + "(" + str(assets.get_child_count()) + ")")

func add_file(file : ImageData):
		var spawn : TreeItem = %Tree.create_item(%Tree.get_root().get_child(0))
		spawn.set_metadata(0, file)
		spawn.set_text(0, file.image_name)
		ImageTrimmer.set_thumbnail(spawn)

func _on_add_image_button_pressed() -> void:
	load_type = LoadType.Images
	%FileDialog.filters = ["*.png, *.apng, *.gif", "*.png","*.svg", "*.apng"]
	$FileDialog.file_mode = 1
	%OffsetSprite.button_pressed = ImageTextureLoaderManager.should_offset
	%FileDialog.popup()

func _on_replace_button_pressed() -> void:
	load_type = LoadType.Replace
	%FileDialog.filters = ["*.png, *.apng, *.gif", "*.png", "*.jpeg", "*.jpg", "*.svg", "*.apng"]
	$FileDialog.file_mode = 0
	%FileDialog.popup()

func _on_delete_button_pressed() -> void:
	check_sprites()
	if checked_sprited.size() > 0:
		%ConfirmationDialog.dialog_text = "Currently selected items might be used by" + str(checked_sprited.size()) + "sprites. Deleting it will add a Placeholder.(Can be Replaced later)"
		%ConfirmationDialog.popup()
	else:
		delete_items()

func check_sprites():
	checked_sprited.clear()
	for sprite in get_tree().get_nodes_in_group("Sprites"):
		for asset in held_items_assets:
			if (sprite.referenced_data == asset.get_metadata(0) or sprite.referenced_data_normal == asset.get_metadata(0)) && sprite not in checked_sprited:
				checked_sprited.append(sprite)

func _on_confirmation_dialog_canceled() -> void:
	%ConfirmationDialog.hide()
	checked_sprited.clear()

func _on_confirmation_dialog_confirmed() -> void:
	delete_items()

func delete_items():
	for asset in held_items_assets:
		for sprite in checked_sprited:
			if sprite.referenced_data == asset.get_metadata(0):
				sprite.get_node("%Sprite2D").texture.diffuse_texture = Global.image_data.runtime_texture
				sprite.used_image_id = -1
				sprite.referenced_data = Global.image_data
				ImageTrimmer.set_thumbnail(sprite.treeitem)
			if sprite.referenced_data_normal == asset.get_metadata(0):
				sprite.get_node("%Sprite2D").texture.normal_texture = Global.image_data_normal.runtime_texture
				sprite.used_image_id_normal = -1
				sprite.referenced_data_normal = Global.image_data_normal
		asset.free()
	var assets : TreeItem = %Tree.get_root().get_child(0)
	assets.set_text(0, "Images " + "(" + str(assets.get_child_count()) + ")")

func _on_tree_multi_selected(_item: TreeItem, _column: int, _selected: bool) -> void:
	var cleaned_array : Array = []
	await  get_tree().physics_frame
	for i in %Tree.get_root().get_child(0).get_children():
		if i.is_selected(0):
			cleaned_array.append(i)
	
	held_items_assets = cleaned_array
	if held_items_assets.size() > 1:
		%ReplaceButton.disabled = true
	else:
		%ReplaceButton.disabled = false

func check_type(path, image_data):
	check_image_type(path, image_data)
	Global.image_manager_data.append(image_data)
	Global.add_new_image.emit(image_data)

func check_image_type(path, image_data):
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	if path.get_extension() == "gif":
		ImageTextureLoaderManager.import_gif(path, image_data)
	elif apng_test != ["No frames", null]:
		ImageTextureLoaderManager.import_apng_sprite(path, image_data)
	else:
		ImageTextureLoaderManager.import_png_from_file(path, null, image_data)

func _on_offset_sprite_toggled(toggled_on: bool) -> void:
	ImageTextureLoaderManager.should_offset = toggled_on

func _on_confirm_trim_confirmed() -> void:
	ImageTextureLoaderManager.trim = true
	if load_type == LoadType.Images:
		load_images()
	elif load_type == LoadType.Replace:
		replace_image(path_placeholder)

func _on_confirm_trim_canceled() -> void:
	ImageTextureLoaderManager.trim = false
	if load_type == LoadType.Images:
		load_images()
	elif load_type == LoadType.Replace:
		replace_image(path_placeholder)

func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	paths_placeholder = paths
	if Settings.theme_settings.enable_trimmer:
		%ConfirmTrim.popup_centered()
	else:
		load_images()
		ImageTextureLoaderManager.trim = false

func _on_file_dialog_file_selected(path: String) -> void:
	path_placeholder = path
	if Settings.theme_settings.enable_trimmer:
		%ConfirmTrim.popup_centered()
	else:
		replace_image(path_placeholder)
		ImageTextureLoaderManager.trim = false

func replace_image(path):
	var image_data = held_items_assets[0]
	check_image_type(path, image_data.get_metadata(0))
	ImageTrimmer.set_thumbnail(image_data)
	image_data.get_metadata(0).image_replaced()
	path_placeholder = ""

func load_images():
	for path in paths_placeholder:
		var new_image : ImageData = ImageData.new()
		check_type(path, new_image)
	paths_placeholder = []
	var assets : TreeItem = %Tree.get_root().get_child(0)
	assets.set_text(0, "Images " + "(" + str(assets.get_child_count()) + ")")
