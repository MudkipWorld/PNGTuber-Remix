#@tool
# Intern initializations
extends ReferenceRect # Extends from ReferenceRect


# Export variables!
@export var frames_per_second = 15.0
@export var output_folder = "ImageSequence Output"
@export var flip_y = true
@export var use_thread = false # so the game wont freeze while the frames are being saved

# Intern variables
@onready var _frametick = 1.0/frames_per_second
@onready var _images = []
@onready var _running = false
@export var _viewport = get_parent()

@onready var _thread = Thread.new()
const GIFExporter = preload("res://addons/gdgifexporter/exporter.gd")
const Quantization = preload("res://addons/gdgifexporter/quantization/uniform.gd")
# ======================================================

func _ready():
	set_process(false)




func save():
	if (use_thread):
		if(not _thread.is_alive()):
			var err = _thread.start(save_frames.bind("Null"))
	else:
		save_frames(null)
	get_window().unresizable = false
	set_process(false)


func record():
	if (_thread.is_alive()):
		return
	_running = !_running
	get_window().unresizable = true
	set_process(true)


func saveg():
	if (use_thread):
		if(not _thread.is_alive()):
			var err = _thread.start(save_gif.bind("Null"))
	else:
		save_gif(null)
	get_window().unresizable = false
	set_process(false)
	


func save_gif(userdata):
	# userdata wont be used, is just for the thread calling
	if !DirAccess.dir_exists_absolute(output_folder.get_base_dir()):
		print("An error occurred when trying to create the output folder.")
		var dire = DirAccess.make_dir_absolute(output_folder.get_base_dir())
	
	
	var i = 0
	var exporter := GIFExporter.new(_images[0].get_width(), _images[0].get_height())
	for image in _images:
		image.convert(Image.FORMAT_RGBA8)
		exporter.add_frame(image, 1, Quantization)
	
	var file: FileAccess = FileAccess.open(output_folder + ".gif", FileAccess.WRITE)
	file.store_buffer(exporter.export_file_data())
	file.close()
	_images.clear()
	_thread.call_deferred("wait_to_finish")



func _process(delta):
	# Get images
	if _running:
		_frametick += delta
		if (_frametick > 1.0/frames_per_second):
			_frametick -= 1.0/frames_per_second
			# Retrieve viewport texture
			var image = _viewport.get_texture().get_image()
			# Get the recorder frame section out of it
			var pos = get_global_transform_with_canvas().origin
			var rect = Rect2(Vector2(pos.x,_viewport.size.y - (pos.y + get_rect().size.y)), get_rect().size)
			image.blit_rect(image, rect, Vector2(0,0))
			_images.append(image)


func save_frames(userdata):
	# userdata wont be used, is just for the thread calling
	if !DirAccess.dir_exists_absolute(output_folder.get_base_dir()):
		print("An error occurred when trying to create the output folder.")
		var dire = DirAccess.make_dir_absolute(output_folder.get_base_dir())
	var i = 0
	for image in _images:
		if (flip_y):
			image.flip_y()
		image.save_png(output_folder +"."+ "%04d" % i + ".png")
		i+=1
	_images.clear()
	
	_thread.call_deferred("wait_to_finish")


func end_func():
	var result = _thread.wait_to_finish()
	return result

func cancelled():
	_images.clear()


