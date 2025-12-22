extends Node
class_name ImageTextureLoaderManager


static var trim : bool = false
static var should_offset : bool = true
static var import_flippd : bool = false
static var appendage_scene = load("res://Misc/AppendageObject/Appendage_object.tscn") as PackedScene
static var sprite_scene = load("res://Misc/SpriteObject/sprite_object.tscn") as PackedScene

static func load_apng(sprite , image_data = null, normal = false):
	var buffer = []
	var img = null
	if normal:
		if sprite.normal == null:
			return
		img = AImgIOAPNGImporter.load_from_buffer(sprite.normal)
		buffer = sprite.normal
	else:
		if sprite.img == null:
			return
		img = AImgIOAPNGImporter.load_from_buffer(sprite.img)
		buffer = sprite.img
	var tex = img[1] as Array[AImgIOFrame]
	if image_data:
		image_data.is_apng = true
		image_data.frames = tex
		
	for n in image_data.frames:
		if sprite.has("is_premultiplied") == false:
			n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = image_data.frames[0]
	image_data.is_apng = true
	image_data.img_animated = false
	image_data.anim_texture = buffer
	var text = ImageTexture.create_from_image(cframe.content)
	if text == null:
		image_data.runtime_texture = ImageTexture.create_from_image(Image.create_empty(32,32,false, Image.FORMAT_ETC2_RGBA8))
	else:
		image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in image_data.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		image_data.animated_frames.append(new_frame)
	
	image_data.has_data = true

static func load_gif(sprite, image_data = null, normal = true):
	var buffer = []
	var gif_tex
	if normal:
		if sprite.normal == null:
			return
		gif_tex = GifManager.sprite_frames_from_buffer(sprite.normal)
		buffer = sprite.normal
	else:
		
		if sprite.img == null:
			return
		gif_tex = GifManager.sprite_frames_from_buffer(sprite.img)
		buffer = sprite.img
		
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	if text == null:
		image_data.runtime_texture = ImageTexture.create_from_image(Image.create_empty(32,32,false, Image.FORMAT_ETC2_RGBA8))
	else:
		image_data.runtime_texture = text
	
	image_data.animated_frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i)/24
		image_data.animated_frames.append(new_frame)
	image_data.anim_texture = buffer
	image_data.img_animated = true
	image_data.is_apng = false
	image_data.has_data = true

#----------------------------------------------------------------------------
# Global Image Loading Section
static func import_gif(path : String, image_data):
	var g_file = FileAccess.get_file_as_bytes(path)
	var gif_tex : SpriteFrames = GifManager.sprite_frames_from_buffer(g_file)
	var img_can = CanvasTexture.new()
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	img_can.diffuse_texture = text
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = (gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i))/24
		image_data.animated_frames.append(new_frame)
		
	image_data.anim_texture = g_file
	image_data.img_animated = true
	image_data.is_apng = false
	image_data.image_name = "(Gif)" + path.get_file().get_basename() 

static func import_apng_sprite(path : String ,image_data):
	var ap_file = FileAccess.get_file_as_bytes(path)
	var img = AImgIOAPNGImporter.load_from_file(path)
	var tex = img[1] as Array[AImgIOFrame]
	image_data.frames = tex
	
	for n in image_data.frames:
		n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = image_data.frames[0]
	var text = ImageTexture.create_from_image(cframe.content)
	image_data.anim_texture = ap_file
	image_data.runtime_texture = text
	image_data.is_apng = true
	image_data.img_animated = false
	image_data.image_name = "(Apng) " + path.get_file().get_basename()
	image_data.animated_frames.clear()
	for i in image_data.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		image_data.animated_frames.append(new_frame)

static func import_png(img: Image, spawn, image_data, _trim, _should_offset):
	var og_image = img.duplicate(true)
	if trim:
		img = ImageTrimmer.trim_image(img)
		image_data.trimmed = true
		if should_offset:
			var original_width = og_image.get_width()
			var original_height = og_image.get_height()
			var trimmed_width = img.get_width()
			var trimmed_height = img.get_height()
			# Calculate offset to maintain visual position
			var trim_info = ImageTrimmer.calculate_trim_info(og_image)
			var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
			var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
			image_data.offset = Vector2(center_shift_x, center_shift_y)
			# Adjust position to keep image visually stable
			if spawn != null:
				spawn.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
				spawn.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
	image_data.is_apng = false
	image_data.img_animated = false
	img.fix_alpha_edges()
	var texture = ImageTexture.create_from_image(img)
	image_data.runtime_texture = texture

static func import_png_from_file(path: String, spawn, image_data):
	var img = Image.load_from_file(path)
	import_png(img, spawn, image_data, trim, should_offset)
	var buffer = FileAccess.get_file_as_bytes(path)
	if trim:
		if Settings.theme_settings.save_raw_sprite:
			image_data.image_data = buffer
		else:
			image_data.image_data = []
	else:
		image_data.image_data = []
	image_data.image_name = path.get_file().get_basename()

#----------------------------------------------------------------------------
# Global Image loading from buffer
static func load_apng_from_buffer(buffer , image_data = null, _normal = false):
	var img = AImgIOAPNGImporter.load_from_buffer(buffer)
	var tex = img[1] as Array[AImgIOFrame]
	image_data.frames = tex
	for n in image_data.frames:
		n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = image_data.frames[0]
	image_data.is_apng = true
	image_data.img_animated = false
	var text = ImageTexture.create_from_image(cframe.content)
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in image_data.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		image_data.animated_frames.append(new_frame)

static func load_gif_from_buffer(buffer, image_data = null):
	var gif_tex = GifManager.sprite_frames_from_buffer(buffer)
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i)/24
		image_data.animated_frames.append(new_frame)

static func _on_flip_h(texture) -> Texture2D:
	var diff_img : Image = texture.get_image().duplicate(true)
	diff_img.flip_x()
	var diff_texture = ImageTexture.create_from_image(diff_img)
	return diff_texture

static func _on_flip_v(texture) -> Texture2D:
	var diff_img : Image = texture.get_image().duplicate(true)
	diff_img.flip_y()
	var diff_texture = ImageTexture.create_from_image(diff_img)
	return diff_texture

static func _on_rotate_image(texture, obj = null) -> Texture2D:
	var diff_img : Image = texture.get_image().duplicate(true)
	for i in obj.rotated:
		diff_img.rotate_90(CLOCKWISE)
	var diff_texture = ImageTexture.create_from_image(diff_img)
	return diff_texture

static func check_flips(og_texture, object) -> Texture2D:
	var texture = og_texture
	if object.flipped_h:
		texture = _on_flip_h(texture)
	if object.flipped_v:
		texture = _on_flip_v(texture)
	if object.rotated != 0:
		texture = _on_rotate_image(texture, object)
	return texture

static func check_valid(obj, image_data) -> bool:
	if obj != null && is_instance_valid(obj):
		if (image_data.is_apng or image_data.img_animated) or obj.get_value("folder"):
			return false
		return true
	else:
		return false
