extends Button

@export var id : int 

static var selected : Button

func _ready() -> void:
	if id != 0:
		self_modulate = Color.LIGHT_GRAY

func _pressed() -> void:
	MeshEditor.brush_type = id
	selected = self
	self_modulate = Color.WHITE
	for i in get_tree().get_nodes_in_group("DeformButtons"):
		if i == self:
			continue
		i.self_modulate = Color.LIGHT_GRAY
