extends Node

const Codec = preload("res://Protected/ProtectedCodec.gd")
const Schema = preload("res://Protected/ProtectedSchema.gd")
const IO = preload("res://Protected/ProtectedIO.gd")
const KEY_PATH := "res://Protected/generated/BuildKeys.gd"
var last_error := ""
var busy := false
var current_model_id := ""

func inspect_file(path: String) -> Dictionary:
	var read := IO.new().read_container(path)
	if not read.ok:
		return read
	var decoded := Codec.new().open(read.value, build_keys())
	if not decoded.ok:
		return decoded
	return Schema.new().decode_model(decoded.value)

func export_protected(path: String, overwrite: bool = false) -> Error:
	if not ProtectionPolicy.allows("save_model") or busy:
		return ERR_UNAUTHORIZED
	SaveAndLoad.save_data()
	var encoded := Schema.new().encode_model(SaveAndLoad.save_dict)
	SaveAndLoad.save_dict.clear()
	if not encoded.ok:
		last_error = encoded.error
		return ERR_INVALID_DATA
	var sealed := Codec.new().seal(encoded.value, build_keys())
	if not sealed.ok:
		last_error = sealed.error
		return ERR_INVALID_DATA
	var written := IO.new().write_container(path, sealed.value, overwrite)
	last_error = written.error
	return OK if written.ok else ERR_CANT_CREATE

func load_protected(path: String) -> Error:
	if not ProtectionPolicy.is_player() or busy:
		return ERR_UNAUTHORIZED
	busy = true
	var decoded := inspect_file(path)
	if not decoded.ok:
		last_error = decoded.error
		busy = false
		return ERR_INVALID_DATA
	# All authentication and schema checks complete before replacing the scene.
	var applied = await SaveAndLoad.apply_protected_data(decoded.value)
	if applied != OK:
		last_error = "Model could not be instantiated; previous session restored"
		busy = false
		return ERR_CANT_CREATE
	Global.save_path = ""
	Settings.save_timer.stop()
	current_model_id = FileAccess.get_sha256(path)
	last_error = ""
	busy = false
	print("Protected model loaded successfully")
	return OK

func build_keys() -> Dictionary:
	if not ResourceLoader.exists(KEY_PATH):
		return {}
	var script = load(KEY_PATH)
	return script.get_keys() if script != null and script.has_method("get_keys") else {}
