# Special thanks for the Pixelorama Team for the initial PSD import script, this is a modified version of it ( https://github.com/Orama-Interactive/Pixelorama/pull/1308 )
extends RefCounted
class_name PSDParser

const PSB_EIGHT_BYTE_ADDITIONAL_LAYER_KEYS: PackedStringArray = [
	"LMsk", "Lr16", "Lr32", "Layr", "Mt16", "Mt32", "Mtrn",
	"Alph", "FMsk", "lnk2", "FEid", "FXid", "PxSD"
]

static func open_photoshop_file(path: String) -> Array:
	var psd_file := FileAccess.open(path, FileAccess.READ)
	if psd_file == null:
		return []
	psd_file.big_endian = true

	if psd_file.get_buffer(4).get_string_from_utf8() != "8BPS":
		return []
	var version := psd_file.get_16()
	if version != 1 and version != 2:
		return []
	var is_psb := version == 2
	psd_file.get_buffer(6) 
	psd_file.get_16() 
	var doc_height := psd_file.get_32()
	var doc_width := psd_file.get_32()
	psd_file.get_16() 
	psd_file.get_16() 

	var color_data_length := psd_file.get_32()
	if color_data_length > 0:
		safe_seek(psd_file, color_data_length)

	var image_resources_length := psd_file.get_32()
	if image_resources_length > 0:
		safe_seek(psd_file, image_resources_length)

	if is_psb:
		psd_file.get_64()
	else:
		psd_file.get_32()

	var _layer_info_length: int
	if is_psb:
		_layer_info_length = psd_file.get_64()
	else:
		_layer_info_length = psd_file.get_32()

	var layer_count := get_signed_16(psd_file)
	if layer_count < 0:
		layer_count = -layer_count

	var psd_layers: Array[Dictionary] = []

	var cons_rand_id = int(randi()/ 2)
	for i in layer_count:
		var layer: Dictionary = {
			"id": 0, # will set from 'lyid'
			"parent_id": 0,
			"name": "Layer %s" % i,
			"type": "layer",
			"visible": true,
			"opacity": 1.0,
			"image": null,
			"channels": []
		}

		layer["top"] = get_signed_32(psd_file)
		layer["left"] = get_signed_32(psd_file)
		layer["bottom"] = get_signed_32(psd_file)
		layer["right"] = get_signed_32(psd_file)
		layer["width"] = layer["right"] - layer["left"]
		layer["height"] = layer["bottom"] - layer["top"]

		var num_channels := psd_file.get_16()
		for j in range(num_channels):
			var ch := {}
			ch["id"] = get_signed_16(psd_file)
			if is_psb:
				ch["length"] = psd_file.get_64()
			else:
				ch["length"] = psd_file.get_32()
			layer["channels"].append(ch)

		safe_seek(psd_file, 8)

		layer["opacity"] = psd_file.get_8() / 255.0
		psd_file.get_8()
		var flags := psd_file.get_8()
		layer["visible"] = flags & 2 != 2
		psd_file.get_8()

		var extra_data_field_length := psd_file.get_32()
		var extra_start := psd_file.get_position()
		var extra_end := extra_start + extra_data_field_length

		if psd_file.get_position() + 4 <= extra_end:
			var mask_len := psd_file.get_32()
			if mask_len > 0:
				safe_seek(psd_file, mask_len)

		if psd_file.get_position() + 4 <= extra_end:
			var blend_len := psd_file.get_32()
			if blend_len > 0:
				safe_seek(psd_file, blend_len)

		if psd_file.get_position() < extra_end:
			var name_length := psd_file.get_8()
			@warning_ignore("integer_division") var padded_length := (((name_length + 4) / 4) * 4) - 1
			if padded_length > 0 and psd_file.get_position() + padded_length <= extra_end:
				layer["name"] = psd_file.get_buffer(padded_length).get_string_from_utf8()
			else:
				layer["name"] = ""

		while psd_file.get_position() < extra_end:
			var _sig := psd_file.get_buffer(4).get_string_from_utf8()
			var key := psd_file.get_buffer(4).get_string_from_utf8()

			var length: int
			if is_psb and key in PSB_EIGHT_BYTE_ADDITIONAL_LAYER_KEYS:
				length = psd_file.get_64()
			else:
				length = psd_file.get_32()

			var block_start := psd_file.get_position()

			if key == "lyid":
				layer["id"] = psd_file.get_32() + cons_rand_id
			if key == "lsct":
				var section_type := psd_file.get_32()
				if section_type == 1 or section_type == 2:
					layer["type"] = "folder"
				elif section_type == 3:
					layer["type"] = "end_folder"
				else:
					layer["type"] = "layer"

			var to_seek := block_start + ((length + 1) & ~1)
			if to_seek > extra_end:
				safe_seek(psd_file, extra_end)
				break
			else:
				psd_file.seek(to_seek)

		if layer["id"] == 0:
			layer["id"] = randi()

		psd_layers.append(layer)
	var folder_stack: Array[int] = []
	for idx in range(psd_layers.size() - 1, -1, -1):
		var entry := psd_layers[idx]
		var t = entry["type"]
		if t == "folder":
			if folder_stack.size() > 0:
				entry["parent_id"] = folder_stack[folder_stack.size() - 1]
			else:
				entry["parent_id"] = 0
			folder_stack.append(entry["id"])
		elif t == "end_folder":
			if folder_stack.size() > 0:
				folder_stack.pop_back()
		elif t == "layer":
			if folder_stack.size() > 0:
				entry["parent_id"] = folder_stack[folder_stack.size() - 1]
			else:
				entry["parent_id"] = 0
	for layer in psd_layers:
		for channel in layer["channels"]:
			channel["data_offset"] = psd_file.get_position()
			var file_len := psd_file.get_length()
			if typeof(channel["length"]) != TYPE_INT:
				channel["length"] = 0
			if channel["length"] < 0 or channel["length"] > file_len:
				channel["length"] = max(0, file_len - psd_file.get_position())
			safe_seek(psd_file, channel["length"])

	for layer in psd_layers:
		if layer["type"] != "layer":
			continue
		var image := decode_psd_layer(psd_file, layer, is_psb)
		if image != null and not image.is_empty():
			layer["image"] = image
		else:
			var placeholder = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			placeholder.fill(Color(0, 0, 0, 0))
			
			layer["image"] = placeholder

	psd_file.close()

	var result := []
	for layer in psd_layers:
		if layer["type"] == "end_folder":
			continue
		var offset = Vector2()
		offset.x = layer["left"] - doc_width / 2 + (layer["right"] - layer["left"]) / 2
		offset.y = layer["top"] - doc_height / 2 + (layer["bottom"] - layer["top"]) / 2
		
		var entry := {}
		entry["id"] = layer["id"]
		entry["parent_id"] = layer["parent_id"]
		entry["type"] = layer["type"]
		entry["name"] = layer["name"]
		entry["image"] = layer["image"]
		entry["visible"] = layer["visible"]
		entry["opacity"] = layer["opacity"]
		entry["offset"] = offset
		result.append(entry)
	return result

static func safe_seek(file: FileAccess, offset: int) -> bool:
	var pos := file.get_position()
	var end := pos + offset
	if offset < 0 or end > file.get_length():
		return false
	file.seek(end)
	return true

static func get_signed_16(file: FileAccess) -> int:
	if file.get_length() >= 2:
		var buffer := file.get_buffer(2)
		if file.big_endian:
			buffer.reverse()
		return buffer.decode_s16(0)
	else:
		return -1

static func get_signed_32(file: FileAccess) -> int:
	if file.get_length() >= 4:
		var buffer := file.get_buffer(4)
		if file.big_endian:
			buffer.reverse()
		return buffer.decode_s32(0)
	else:
		return -1

static func decode_psd_layer(psd_file: FileAccess, layer: Dictionary, is_psb: bool) -> Image:
	var img_channels := {}
	var file_len := psd_file.get_length()

	for channel in layer["channels"]:
		if not channel.has("data_offset") or not channel.has("length"):
			continue
		var data_offset = channel["data_offset"]
		var ch_length = channel["length"]
		if data_offset < 0 or data_offset >= file_len:
			push_error("Bad data_offset for channel: %s" % str(data_offset))
			continue
		if ch_length <= 0 or ch_length > file_len:
			push_error("Bad channel length: %s" % str(ch_length))
			continue

		psd_file.seek(data_offset)
		if psd_file.get_position() + 2 > file_len:
			push_error("Unexpected EOF reading compression")
			continue
		var compression := psd_file.get_16()

		var width: int = layer["width"]
		var height: int = layer["height"]
		var size: int = width * height
		if size <= 0:
			continue

		if size > 200_000_000:
			push_error("Layer size too large: %d" % size)
			continue

		var raw_data := PackedByteArray()

		if compression == 0:
			if psd_file.get_position() + size > data_offset + ch_length:
				push_error("Channel raw data shorter than expected")
				continue
			raw_data = psd_file.get_buffer(size)
		elif compression == 1:
			var scanline_counts := []
			for r in range(height):
				if is_psb:
					if psd_file.get_position() + 4 > data_offset + ch_length:
						push_error("Unexpected EOF reading scanline count (psb)")
						break
					scanline_counts.append(psd_file.get_32())
				else:
					if psd_file.get_position() + 2 > data_offset + ch_length:
						push_error("Unexpected EOF reading scanline count (psd)")
						break
					scanline_counts.append(psd_file.get_16())

			for rcount in scanline_counts:
				if rcount < 0 or rcount > ch_length:
					push_error("Suspicious scanline count: %s" % str(rcount))
					# clamp
					rcount = clamp(rcount, 0, ch_length)

			for r_i in range(scanline_counts.size()):
				var to_read = scanline_counts[r_i]
				var scanline := PackedByteArray()
				var bytes_read := 0
				while scanline.size() < width and bytes_read < to_read:
					if psd_file.get_position() >= data_offset + ch_length:
						push_error("Unexpected EOF while reading RLE data")
						break
					var n := psd_file.get_8()
					bytes_read += 1
					if n >= 128:
						var count := 257 - n
						if psd_file.get_position() >= data_offset + ch_length:
							push_error("Unexpected EOF reading RLE replicate value")
							break
						var val := psd_file.get_8()
						bytes_read += 1
						for k in range(count):
							scanline.append(val)
					else:
						var count := n + 1
						for k in range(count):
							if psd_file.get_position() >= data_offset + ch_length:
								push_error("Unexpected EOF reading RLE literal values")
								break
							scanline.append(psd_file.get_8())
							bytes_read += 1
				raw_data.append_array(scanline)
		else:
			push_error("Unsupported compression: %d" % compression)
			continue

		if raw_data.size() == size:
			img_channels[channel["id"]] = raw_data
		else:
			if raw_data.size() > 0:
				push_warning("Channel data size mismatch: expected %d got %d" % [size, raw_data.size()])
				var padded := PackedByteArray()
				padded.resize(size)
				for ii in range(size):
					if ii < raw_data.size():
						padded[ii] = raw_data[ii]
					else:
						padded[ii] = 255
				img_channels[channel["id"]] = padded
			else:
				continue

	if layer["width"] <= 0 or layer["height"] <= 0:
		return null

	var pixel_count = layer["width"] * layer["height"]
	var img_data := PackedByteArray()
	img_data.resize(pixel_count * 4)

	var fully_transparent := true

	for p in range(pixel_count):
		var r := 255
		var g := 255
		var b := 255
		var a := 255
		if img_channels.has(0):
			r = img_channels[0][p]
		if img_channels.has(1):
			g = img_channels[1][p]
		if img_channels.has(2):
			b = img_channels[2][p]
		if img_channels.has(-1):
			a = img_channels[-1][p]

		var base := p * 4
		img_data[base + 0] = r
		img_data[base + 1] = g
		img_data[base + 2] = b
		img_data[base + 3] = a

		if a > 0:
			fully_transparent = false

	# if no channel data OR fully transparent, return tiny placeholder
	if img_channels.size() == 0 or fully_transparent:
		var placeholder := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		placeholder.fill(Color(0, 0, 0, 0))
		return placeholder

	return Image.create_from_data(layer["width"], layer["height"], false, Image.FORMAT_RGBA8, img_data)
