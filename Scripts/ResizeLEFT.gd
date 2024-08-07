extends Control


var start : Vector2
var initialPosition : Vector2
var isResizing : bool
var resizeX : bool
var initialSize : Vector2
@export var ResizeThreshold := 7

func _ready():
	InputMap.load_from_project_settings()

func _input(event):
	if Input.is_action_just_pressed("lmb"):
		var rect = get_global_rect()
		var localMousePos = event.position - get_global_position()
		if abs(localMousePos.x - rect.size.x) < ResizeThreshold:
				start.x = event.position.x
				initialSize.x = get_size().x
				resizeX = true
				isResizing = true
		
	if Input.is_action_pressed("lmb"):
		
		if isResizing:
			var newWidith = get_size().x
			
			if resizeX:
				newWidith = initialSize.x - (start.x - event.position.x)
				
			if initialPosition.x != 0:
				newWidith = initialSize.x + (start.x - event.position.x)
				set_position(Vector2(initialPosition.x - (newWidith - initialSize.x), get_position().y))
			
			set_size(Vector2(newWidith, get_size().y))
		
	if Input.is_action_just_released("lmb"):
		initialPosition = Vector2(0,0)
		resizeX = false
		isResizing = false
