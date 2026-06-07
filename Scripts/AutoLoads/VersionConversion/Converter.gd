extends RefCounted
class_name Converter


## Override this in a subclass and convert the data before returning
func convert_data(old_data: Dictionary) -> Dictionary:
	return old_data
