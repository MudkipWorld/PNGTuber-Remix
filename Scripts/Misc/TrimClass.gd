extends Node
# image_trimmer.gd
class_name ImageTrimmer

# Calculate the trim boundaries of an image
static func calculate_trim_info(image: Image) -> Dictionary:
	var width = image.get_width()
	var height = image.get_height()
	
	# Find boundaries of non-transparent pixels
	var min_x = width
	var min_y = height
	var max_x = -1
	var max_y = -1
	
	# Scan the entire image for non-transparent pixels
	for y in range(height):
		for x in range(width):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.01:  # If pixel is not fully transparent
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	
	# Check if we found any non-transparent pixels
	if max_x >= min_x and max_y >= min_y:
		var trim_width = max_x - min_x + 1
		var trim_height = max_y - min_y + 1
		var rect = Rect2(min_x, min_y, trim_width, trim_height)
		
		return {
			"width": trim_width,
			"height": trim_height,
			"rect": rect,
			"min_x": min_x,
			"min_y": min_y,
			"max_x": max_x,
			"max_y": max_y
		}
	
	# Return empty result if image is fully transparent
	return {}

# Trim the image based on non-transparent pixels
static func trim_image(image: Image) -> Image:
	var trim_info = calculate_trim_info(image)
	
	# If no trim needed, return original image
	if trim_info.is_empty():
		return image
	
	# Create trimmed image
	var trimmed_image = Image.create(trim_info.width, trim_info.height, false, image.get_format())
	
	# Blit the non-transparent area
	trimmed_image.blit_rect(image, trim_info.rect, Vector2.ZERO)
	
	return trimmed_image

static func trim_normal(image : Image, normal : Image) -> Image:
	var trim_info = calculate_trim_info(image)
	
	# If no trim needed, return original image
	if trim_info.is_empty():
		return normal
	
	# Create trimmed normal
	var trimmed_image = Image.create(trim_info.width, trim_info.height, false, normal.get_format())
	
	# Blit the non-transparent area
	trimmed_image.blit_rect(normal, trim_info.rect, Vector2.ZERO)
	
	return trimmed_image


static func set_thumbnail(item : TreeItem):
	var img = Image.new()
	if item.get_metadata(0) is ImageData:
		#var test = item.get_metadata(0)
		img = item.get_metadata(0).runtime_texture.get_image().duplicate(true)
	else:
		if item.get_metadata(0).sprite_object.get_node("%Sprite2D").texture:
			img = item.get_metadata(0).sprite_object.get_node("%Sprite2D").texture.get_image().duplicate(true)

	var thumbnail_size = 32
	
	# Create a transparent square image
	var square_img = Image.create(thumbnail_size, thumbnail_size, false, img.get_format())
	square_img.fill(Color(0, 0, 0, 0))
	
	var scaled_img = img.duplicate()
	var scale_factor = min(
		float(thumbnail_size) / scaled_img.get_width(),
		float(thumbnail_size) / scaled_img.get_height()
	)
	
	var new_width = int(scaled_img.get_width() * scale_factor)
	var new_height = int(scaled_img.get_height() * scale_factor)
	
	scaled_img.resize(max(new_width, 1), max(new_height,1), Image.INTERPOLATE_BILINEAR)
	
	var offset_x = (thumbnail_size - new_width) / 2
	var offset_y = (thumbnail_size - new_height) / 2
#	printt(offset_x, offset_y, new_width, new_height)
	
	square_img.blit_rect(scaled_img, Rect2(0, 0, new_width, new_height), Vector2(offset_x, offset_y))
	
	var texture = ImageTexture.create_from_image(square_img)
	item.set_icon(0, texture)
	# Force the tree to redraw to ensure thumbnails appear immediately
