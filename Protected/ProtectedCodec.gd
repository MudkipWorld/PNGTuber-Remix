extends RefCounted

const MAX_BYTES := 512 * 1024 * 1024
const MAGIC := "PNGRMP01"

func fail(message: String) -> Dictionary:
	return {"ok": false, "value": null, "error": message}

func success(value: Variant) -> Dictionary:
	return {"ok": true, "value": value, "error": ""}

func valid_keys(keys: Dictionary) -> bool:
	return keys.get("enc", PackedByteArray()).size() == 32 and keys.get("mac", PackedByteArray()).size() == 32 and keys.get("id", PackedByteArray()).size() == 16

func tag(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	var h := HMACContext.new()
	if h.start(HashingContext.HASH_SHA256, key) != OK:
		return PackedByteArray()
	h.update(data)
	return h.finish()

func seal(payload: PackedByteArray, keys: Dictionary) -> Dictionary:
	if not valid_keys(keys) or payload.size() > MAX_BYTES - 128:
		return fail("Invalid key configuration or model too large")
	var iv := Crypto.new().generate_random_bytes(16)
	var padded := payload.duplicate()
	var padding := 16 - (padded.size() % 16)
	for i in padding:
		padded.append(padding)
	var aes := AESContext.new()
	if aes.start(AESContext.MODE_CBC_ENCRYPT, keys.enc, iv) != OK:
		return fail("Encryption initialization failed")
	var ciphertext := aes.update(padded)
	aes.finish()
	var header := StreamPeerBuffer.new()
	header.put_data(MAGIC.to_ascii_buffer())
	header.put_u32(1)
	header.put_u32(5)
	header.put_data("1.4.5".to_ascii_buffer())
	header.put_data(keys.id)
	header.put_data(iv)
	header.put_u64(ciphertext.size())
	var result := header.data_array
	result.append_array(ciphertext)
	result.append_array(tag(result, keys.mac))
	return success(result)

func open(container: PackedByteArray, keys: Dictionary) -> Dictionary:
	if not valid_keys(keys) or container.size() < 109 or container.size() > MAX_BYTES:
		return fail("Invalid protected file size or keys")
	if container.slice(0, 8).get_string_from_ascii() != MAGIC or container.decode_u32(8) != 1:
		return fail("Unsupported protected format")
	var version_length := container.decode_u32(12)
	if version_length < 1 or version_length > 32:
		return fail("Invalid version header")
	var offset := 16 + version_length
	if container.size() < offset + 72:
		return fail("Truncated header")
	var cipher_length := container.decode_u64(offset + 32)
	var header_length := offset + 40
	if cipher_length < 16 or cipher_length > MAX_BYTES - header_length - 32 or cipher_length % 16 != 0:
		return fail("Invalid encrypted payload length")
	if container.size() != header_length + cipher_length + 32:
		return fail("Truncated or trailing data")
	var actual := tag(container.slice(0, -32), keys.mac)
	if not Crypto.new().constant_time_compare(actual, container.slice(-32)):
		return fail("File damaged or incompatible player key")
	if container.slice(16, offset).get_string_from_utf8() != "1.4.5" or container.slice(offset, offset + 16) != keys.id:
		return fail("Incompatible model version or player")
	var aes := AESContext.new()
	if aes.start(AESContext.MODE_CBC_DECRYPT, keys.enc, container.slice(offset + 16, offset + 32)) != OK:
		return fail("Decryption initialization failed")
	var plain := aes.update(container.slice(header_length, -32))
	aes.finish()
	if plain.is_empty():
		return fail("Empty decrypted data")
	var padding := int(plain[-1])
	if padding < 1 or padding > 16:
		return fail("Invalid padding")
	for i in range(plain.size() - padding, plain.size()):
		if plain[i] != padding:
			return fail("Invalid padding")
	return success(plain.slice(0, plain.size() - padding))
