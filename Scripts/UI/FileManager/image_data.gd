extends RefCounted
class_name ImageData

var runtime_texture = null
var anim_texture 
var img_animated : bool = false
var is_apng : bool = false
var image_data = null
var frames : Array[AImgIOFrame] = []
var animated_frames : Array
var has_data : bool = false
var image_name : String = "Placeholder"
var trimmed = false
var offset = Vector2.ZERO
var sprite_sheet : bool = false
var id : int = randi()


func get_data() -> Dictionary:
	var data : Dictionary = {
		runtime_texture = runtime_texture.get_image().save_png_to_buffer(),
		anim_texture = anim_texture,
		img_animated = img_animated,
		is_apng = is_apng,
		image_data = image_data,
		image_name = image_name,
		trimmed = trimmed,
		offset = offset,
		id = id,
		sprite_sheet = sprite_sheet,
	}
	return data

func set_data(_data : Dictionary):
	if _data.get("runtime_texture", null) != null:
		var img = Image.new()
		img.load_png_from_buffer(_data.runtime_texture)
		var texture = ImageTexture.create_from_image(img)
		runtime_texture = texture
		if runtime_texture.get_size().x > 1280 or runtime_texture.get_size().y > 1280:
			Global.show_warning = true
	
	img_animated = _data.get("img_animated", false)
	is_apng = _data.get("is_apng", false)
	anim_texture =  _data.get("anim_texture", null)
	if anim_texture != null:
		if img_animated:
			ImageTextureLoaderManager.load_gif_from_buffer(anim_texture, self)
		elif is_apng:
			ImageTextureLoaderManager.load_apng_from_buffer(anim_texture, self)
	
	image_data = _data.get("image_data", [])
	image_name = _data.get("image_name", "Placeholder")
	trimmed = _data.get("trimmed", false)
	offset = _data.get("offset", Vector2.ZERO)
	id = _data.get("id", randi())
	sprite_sheet = _data.get("sprite_sheet", false)
	
	#printt(img_animated, is_apng)

func image_replaced():
	Global.image_replaced.emit(self)

func trim_image(sprite_node: Sprite2D = null):
	if !sprite_sheet:
		if !is_apng && !img_animated:
			var image : Image = runtime_texture.get_image().duplicate(true)
			var og_image = image.duplicate(true)
			image = ImageTrimmer.trim_image(image)
			var original_width = og_image.get_width()
			var original_height = og_image.get_height()
			var trimmed_width = image.get_width()
			var trimmed_height = image.get_height()
			var trim_info = ImageTrimmer.calculate_trim_info(og_image)
			if !trim_info.is_empty():
				var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
				var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
				offset += Vector2(center_shift_x, center_shift_y)
				if sprite_node != null:
					sprite_node.position += Vector2(center_shift_x, center_shift_y)
			else:
				image.resize(32,32, Image.INTERPOLATE_BILINEAR)
			
			var tex = ImageTexture.create_from_image(image)
			runtime_texture = tex
			trimmed = true
	else:
		trimmed = false
		image_data = []
		sprite_sheet = true
