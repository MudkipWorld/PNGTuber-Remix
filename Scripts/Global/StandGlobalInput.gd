class_name StandGlobalInput
extends GlobalInput

@onready var cycle :Node = %Cycle

# Typed as Object on purpose: the extension only ships a Windows library, so on other
# platforms the class is never registered and naming the type would break this script.
var rawMouseInput : Object = null;
var mouse_relative_movement:Vector2i = Vector2i.ZERO
var is_mouse_relative_movement:bool = false
var mouse_relative_movement_buffer:Vector2i = Vector2i.ZERO
var is_mouse_relative_movement_buffer:bool = false

func _ready() -> void:
	# use_physics_frames = true
	call_deferred("_rawmouse_init");

func _rawmouse_init():
	if rawMouseInput == null and OS.get_name() == "Windows" and ClassDB.class_exists("RawMouseInput"):
		print("raw input init start")
		rawMouseInput = ClassDB.instantiate("RawMouseInput")
		rawMouseInput.raw_mouse.connect(_on_raw_mouse_input_updated)

		add_child(rawMouseInput);

		if !rawMouseInput.is_inited:
			print("raw input init failed")
			remove_child(rawMouseInput)
			rawMouseInput = null
		else:
			print("raw input init end")

func _process(_delta: float) -> void:
	if rawMouseInput != null:
		mouse_relative_movement = mouse_relative_movement_buffer
		mouse_relative_movement_buffer = Vector2i.ZERO
		is_mouse_relative_movement = is_mouse_relative_movement_buffer
		is_mouse_relative_movement_buffer = false

# win32/api/winuser/ns-winuser-rawmouse usFlags
enum Raw_Mouse_Input_Flags {
	MOUSE_MOVE_RELATIVE = 0x00,
	MOUSE_MOVE_ABSOLUTE = 0x01,
	MOUSE_VIRTUAL_DESKTOP = 0x02,
	MOUSE_ATTRIBUTES_CHANGED = 0x04,
	MOUSE_MOVE_NOCOALESCE = 0x08,
}

func _on_raw_mouse_input_updated(lLastX: int, lLastY: int) -> void:
	mouse_relative_movement_buffer.x += lLastX
	mouse_relative_movement_buffer.y += lLastY
	is_mouse_relative_movement_buffer = true

func refresh_raw_mouse_input():
	if rawMouseInput != null:
		rawMouseInput.refresh()
