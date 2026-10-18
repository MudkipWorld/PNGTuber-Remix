extends RefCounted

const MAX_BYTES := 512 * 1024 * 1024

func response(ok: bool, value: Variant = null, message: String = "") -> Dictionary:
	return {"ok": ok, "value": value, "error": message}

func read_container(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return response(false, null, "Cannot open protected model")
	var size := file.get_length()
	if size < 109 or size > MAX_BYTES:
		return response(false, null, "Invalid protected model size")
	var prefix := file.get_buffer(16)
	if prefix.size() != 16 or prefix.slice(0,8).get_string_from_ascii() != "PNGRMP01" or prefix.decode_u32(8) != 1:
		return response(false, null, "Unsupported protected format")
	var version_length := prefix.decode_u32(12)
	if version_length < 1 or version_length > 32:
		return response(false, null, "Invalid version header")
	var header_length := 16 + version_length + 40
	if size < header_length + 48:
		return response(false, null, "Truncated header")
	var tail := file.get_buffer(version_length + 40)
	var declared := tail.decode_u64(version_length + 32)
	if declared < 16 or declared > MAX_BYTES - header_length - 32 or declared % 16 != 0 or size != header_length + declared + 32:
		return response(false, null, "Invalid encrypted payload length")
	if tail.slice(0,version_length).get_string_from_utf8() != "1.4.5":
		return response(false, null, "Unsupported model version")
	file.seek(0)
	var data := file.get_buffer(size)
	if data.size() != size:
		return response(false, null, "Incomplete read")
	return response(true, data)

func write_container(path: String, bytes: PackedByteArray, overwrite: bool) -> Dictionary:
	if FileAccess.file_exists(path) and not overwrite:
		return response(false, null, "Destination already exists")
	var temp := path + "." + Crypto.new().generate_random_bytes(8).hex_encode() + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return response(false, null, "Cannot write destination")
	file.store_buffer(bytes)
	file.flush()
	var err := file.get_error()
	file.close()
	if err == OK:
		err = DirAccess.rename_absolute(temp, path)
	if err != OK:
		DirAccess.remove_absolute(temp)
		return response(false, null, "Cannot complete protected export")
	return response(true)
