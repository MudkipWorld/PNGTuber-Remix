extends Node


@export var conversion_map: Array[VersionMapper] = []


func convert_save(old_data: Dictionary, old_version: String) -> Dictionary:
	var data := old_data
	
	for converter in conversion_map:
		if converter.from_version != old_version: continue
		old_version = converter.to_version
		var conv := converter.converter.new() as Converter
		data = conv.convert_data(data)
	
	data["version"] = Global.version
	return data
