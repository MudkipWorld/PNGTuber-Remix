class_name Util

## Returns the parent of the provided path. If an error occurs, then the provided
## path is returned.
static func get_parent_path(path: String) -> String:
	var parent_slash_index = path.rfind("/");
	if parent_slash_index < 0:
		return path;
	return path.substr(0, parent_slash_index);
