class_name FormattedLocalizedLabel
extends Label

@export var localizations: Array[String] = []

func _ready() -> void:
	for index in self.localizations.size():
		self.text = self.text.replace("{%d}" % index, tr(self.localizations[index]))
