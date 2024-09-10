extends Node


var save_dict : Dictionary = {}


func save_file(path):
	get_tree().get_root().get_node("Main/Control/_Themes_").theme_settings.path = path
	get_tree().get_root().get_node("Main/Control/TopBarInput").path = path
	var sprites = get_tree().get_nodes_in_group("Sprites")
	var bg_sprites = get_tree().get_nodes_in_group("BackgroundStuff")
	var inputs = get_tree().get_nodes_in_group("StateRemapButton")
	
	
	var sprites_array : Array = []
	var bg_sprites_array : Array = []
	var input_array : Array = []
	for input in inputs:
		input_array.append(input.saved_event)
	for sprt in sprites:
		sprt.save_state(Global.current_state)
		var img
		if sprt.is_apng:
			var exporter := AImgIOAPNGExporter.new()
			img = exporter.export_animation(sprt.frames, 10, self, "_progress_report", [])
			var normal_img
			if !sprt.frames2.is_empty:
				normal_img = exporter.export_animation(sprt.frames2, 10, self, "_progress_report", [])
			
			var cleaned_array = []
			
			var index = 0
			for st in sprt.states:
				if !st.is_empty():
					cleaned_array.append(st)

			
			
		#	print(cleaned_array)
			
			
			var sprt_dict = {
				img = img,
				normal = normal_img,
				states = cleaned_array,
				is_apng = sprt.is_apng,
				sprite_name = sprt.sprite_name,
				sprite_id = sprt.sprite_id,
				parent_id = sprt.parent_id,
				sprite_type = sprt.sprite_type,
				is_asset = sprt.is_asset,
				saved_event = sprt.saved_event,
				was_active_before = sprt.was_active_before,
				should_disappear = sprt.should_disappear,
				saved_keys = sprt.saved_keys,
				is_collapsed = sprt.is_collapsed,
			}
			
			sprites_array.append(sprt_dict)
		else:
			if sprt.img_animated:
				img = sprt.anim_texture
			else:
				img = sprt.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture.diffuse_texture.get_image().save_png_to_buffer()
				
			var normal_img
			if sprt.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture.normal_texture:
				if sprt.img_animated:
					normal_img = sprt.anim_texture_normal
				else:
					normal_img = sprt.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture.normal_texture.get_image().save_png_to_buffer()
			
			var cleaned_array = []
			
			var index = 0
			for st in sprt.states:
				if !st.is_empty():
					cleaned_array.append(st)

			
			
		#	print(cleaned_array)
			var sprt_dict = {
				img = img,
				normal = normal_img,
				states = cleaned_array,
				img_animated = sprt.img_animated,
				sprite_name = sprt.sprite_name,
				sprite_id = sprt.sprite_id,
				parent_id = sprt.parent_id,
				sprite_type = sprt.sprite_type,
				is_asset = sprt.is_asset,
				saved_event = sprt.saved_event,
				was_active_before = sprt.was_active_before,
				should_disappear = sprt.should_disappear,
				saved_keys = sprt.saved_keys,
				is_collapsed = sprt.is_collapsed,
			}
			sprites_array.append(sprt_dict)
			
			
	for sprt in bg_sprites:
		sprt.save_state(Global.current_state)
		var img = Marshalls.raw_to_base64(sprt.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture.diffuse_texture.get_image().save_png_to_buffer())
		var normal_img 
		if sprt.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture.normal_texture:
			normal_img = Marshalls.raw_to_base64(sprt.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture.normal_texture.get_image().save_png_to_buffer())
		else:
			normal_img = null
			
		for st in sprt.states:
	#		print(st)
			if st.is_empty():
				var ind = sprt.states.find(st)
				sprt.states.remove_at(ind)
			
			
		var sprt_dict = {
			img = img,
			normal = normal_img,
			states = sprt.states,
			sprite_name = sprt.sprite_name,
			sprite_id = sprt.sprite_id,
		}
		bg_sprites_array.append(sprt_dict)
	save_dict = {
		sprites_array = sprites_array,
		settings_dict = Global.settings_dict,
		input_array = input_array,
		bg_sprites_array = bg_sprites_array
	}
	
	
	var file = FileAccess.open(path,FileAccess.WRITE)
#	if FileAccess.file_exists(path):
	#	print(file.get_var())
	
	
	file.store_var(save_dict, true)
	file.close()
	file = null

func load_file(path):
	if path.get_extension() == "save":
		load_pngplus_file(path)
	else:
		get_tree().get_root().get_node("Main/Control/_Themes_").theme_settings.path = path
		get_tree().get_root().get_node("Main/Control/TopBarInput").path = path
		
		get_tree().get_root().get_node("Main/Control/StatesStuff").delete_all_states()
		get_tree().get_root().get_node("Main").clear_sprites()
		
		get_tree().get_root().get_node("Main/Timer").start()
		get_tree().get_root().get_node("Main/Control/StatesStuff").delete_all_states()
		await get_tree().get_root().get_node("Main/Timer").timeout
		
		var file = FileAccess.open(path, FileAccess.READ)
		var load_dict = file.get_var(true)
		
		if !load_dict.has("sprites_array"):
			return
		Global.settings_dict.merge(load_dict.settings_dict, true)
		get_tree().get_root().get_node("Main/Control/StatesStuff").update_states(load_dict.settings_dict.states)
		
		
		##########################################################################################################
		if load_dict.has("bg_sprites_array"):
			for sprite in load_dict.bg_sprites_array:
				var sprite_obj = preload("res://Misc/BackgroundObject/background_object.tscn").instantiate()
				var img_data = Marshalls.base64_to_raw(sprite.img)
				var img = Image.new()
				img.load_png_from_buffer(img_data)
				var img_tex = ImageTexture.new()
				img_tex.set_image(img)
				var img_can = CanvasTexture.new()
				img_can.diffuse_texture = img_tex
				sprite_obj.get_node("Pos/Wobble/Squish/Drag/Sprite2D").texture = img_can
				sprite_obj.states = sprite.states
				sprite_obj.sprite_name = sprite.sprite_name
				
				get_tree().get_root().get_node("Main/SubViewportContainer2/SubViewport/BackgroundStuff/BGContainer").add_child(sprite_obj)
				sprite_obj.get_state(0)
		
		
		##########################################################################################################
		for sprite in load_dict.sprites_array:
			var sprite_obj
			if sprite.has("sprite_type"):
				if sprite.sprite_type == "Sprite2D":
					sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
				elif sprite.sprite_type == "WiggleApp":
					sprite_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn").instantiate()
				elif sprite.sprite_type == "Folder":
					sprite_obj = preload("res://Misc/FolderObject/Folder_object.tscn").instantiate()
					
			else:
				sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
				
				
				
				
			var cleaned_array = []
			
			var index = 0
			for st in sprite.states:
				if !st.is_empty():
					cleaned_array.append(st)
					
			sprite_obj.states.clear()
			sprite_obj.states = cleaned_array
			
			if sprite.has("is_asset"):
				sprite_obj.is_asset = sprite.is_asset
				sprite_obj.saved_event = sprite.saved_event
				sprite_obj.should_disappear = sprite.should_disappear
				if sprite_obj.is_asset:
					sprite_obj.get_node("%Drag").visible = sprite.was_active_before
					sprite_obj.was_active_before = sprite.was_active_before
					sprite_obj.saved_keys = sprite.saved_keys
					InputMap.add_action(str(sprite.sprite_id))
					InputMap.action_add_event(str(sprite.sprite_id), sprite_obj.saved_event)
					
			if sprite.has("img_animated"):
				if sprite.img_animated:
					var gif_texture : AnimatedTexture = GifManager.animated_texture_from_buffer(sprite.img)
					sprite_obj.anim_texture = sprite.img
					var img_can = CanvasTexture.new()
					
					for n in gif_texture.frames:
						gif_texture.get_frame_texture(n).get_image().fix_alpha_edges()
					img_can.diffuse_texture = gif_texture
					if sprite.has("normal"):
						if sprite.normal != null:
							var gif_normal = GifManager.animated_texture_from_buffer(sprite.normal)
							
							for n in gif_normal.frames:
								gif_normal.get_frame_texture(n).get_image().fix_alpha_edges()
							
							img_can.normal_texture = gif_normal
							sprite_obj.anim_texture_normal = sprite.normal
					sprite_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can
					
				else:
					var img_data
					var img = Image.new()

					if sprite.img is not PackedByteArray:
						img_data = Marshalls.base64_to_raw(sprite.img)
						img.load_png_from_buffer(img_data)
					else:
						img.load_png_from_buffer(sprite.img)
					img.fix_alpha_edges()
					var img_tex = ImageTexture.new()
					img_tex.set_image(img)
					var img_can = CanvasTexture.new()
					img_can.diffuse_texture = img_tex
					if sprite.has("normal"):
						if sprite.normal != null:
							var img_normal
							var nimg = Image.new()
							
							if sprite.normal is not PackedByteArray:
								img_normal = Marshalls.base64_to_raw(sprite.normal)
								nimg.load_png_from_buffer(img_normal)
							else:
								nimg.load_png_from_buffer(sprite.normal)

							nimg.fix_alpha_edges()
							var nimg_tex = ImageTexture.new()
							nimg_tex.set_image(nimg)
							img_can.normal_texture = nimg_tex
					sprite_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can
			else:
				if sprite.has("is_apng"):
					var img = AImgIOAPNGImporter.load_from_buffer(sprite.img)
					var tex = img[1] as Array[AImgIOFrame]
					sprite_obj.frames = tex
					
					for n in sprite_obj.frames:
						n.content.fix_alpha_edges()
					
					var cframe: AImgIOFrame = sprite_obj.frames[0]
					
					var text = ImageTexture.create_from_image(cframe.content)
					var img_can = CanvasTexture.new()
					img_can.diffuse_texture = text
					if sprite.normal:
						var norm = AImgIOAPNGImporter.load_from_buffer(sprite.normal)
						var texn = norm[1] as Array[AImgIOFrame]
						sprite_obj.frames2 = texn
						for n in sprite_obj.frames2:
							n.content.fix_alpha_edges()
						
						var cframe2: AImgIOFrame = sprite_obj.frames2[0]
						var text2 = ImageTexture.create_from_image(cframe2.content)
						img_can.normal_texture = text2
					sprite_obj.texture = img_can
					sprite_obj.is_apng = true
					sprite_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can
				else:
					var img_data
					var img = Image.new()

					if sprite.img is not PackedByteArray:
						img_data = Marshalls.base64_to_raw(sprite.img)
						img.load_png_from_buffer(img_data)
					else:
						img.load_png_from_buffer(sprite.img)

					img.fix_alpha_edges()
					var img_tex = ImageTexture.new()
					img_tex.set_image(img)
					var img_can = CanvasTexture.new()
					img_can.diffuse_texture = img_tex
					if sprite.has("normal"):
						if sprite.normal != null:
							var img_normal
							var nimg = Image.new()
							
							if sprite.normal is not PackedByteArray:
								img_normal = Marshalls.base64_to_raw(sprite.normal)
								nimg.load_png_from_buffer(img_normal)
							else:
								nimg.load_png_from_buffer(sprite.normal)
							nimg.fix_alpha_edges()
							var nimg_tex = ImageTexture.new()
							nimg_tex.set_image(nimg)
							img_can.normal_texture = nimg_tex
					sprite_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D").texture = img_can

					
			if sprite.has("img_animated"):
				sprite_obj.img_animated = sprite.img_animated
			sprite_obj.sprite_id = sprite.sprite_id
			sprite_obj.parent_id = sprite.parent_id
			sprite_obj.sprite_name = sprite.sprite_name
			if sprite.has("is_collapsed"):
				sprite_obj.is_collapsed = sprite.is_collapsed
			get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer").add_child(sprite_obj)
			sprite_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT

		if !load_dict.input_array.is_empty():
			for input in len(load_dict.input_array):
				get_tree().get_nodes_in_group("StateRemapButton")[input].saved_event = load_dict.input_array[input]
				Global.settings_dict.saved_inputs = load_dict.input_array
				get_tree().get_nodes_in_group("StateRemapButton")[input].update_stuff()
		else:
			var idx = 0
			for input in Global.settings_dict.saved_inputs:
				get_tree().get_nodes_in_group("StateRemapButton")[idx].saved_event = input
				get_tree().get_nodes_in_group("StateRemapButton")[idx].update_stuff()
				idx += 1
		var state_count = get_tree().get_nodes_in_group("StateRemapButton").size()
		for i in get_tree().get_nodes_in_group("Sprites"):
			if i.states.size() != state_count:
				for l in abs(i.states.size() - state_count):
					i.states.append({})
		Global.load_sprite_states(0)
		get_tree().get_root().get_node("Main/Control").loaded_tree(get_tree().get_nodes_in_group("Sprites"))
		get_tree().get_root().get_node("Main/Control/BackgroundEdit").loaded_tree(get_tree().get_nodes_in_group("BackgroundStuff"))
		get_tree().get_root().get_node("Main/Control").sliders_revalue(Global.settings_dict)
		Global.load_sprite_states(0)
		get_tree().get_root().get_node("Main/Control/UIInput").reinfoanim()
		file.close()
		file = null

func load_pngplus_file(path):
	get_tree().get_root().get_node("Main/Control/_Themes_").theme_settings.path = path
	get_tree().get_root().get_node("Main/Control/TopBarInput").path = path
	
	get_tree().get_root().get_node("Main/Control/StatesStuff").delete_all_states()
	get_tree().get_root().get_node("Main").clear_sprites()
	
	get_tree().get_root().get_node("Main/Timer").start()
	get_tree().get_root().get_node("Main/Control/StatesStuff").delete_all_states()
	await get_tree().get_root().get_node("Main/Timer").timeout
	
	
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = JSON.parse_string(file.get_as_text())
	
	file.close()
	file = null
	
	if !load_dict["0"].has("identification"):
		print("Failed")
		return
		
	
		
	
		
	for i in load_dict:
		var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		var img_data = Marshalls.base64_to_raw(load_dict[i]["imageData"])
		var img = Image.new()
		img.load_png_from_buffer(img_data)
		var img_tex = ImageTexture.new()
		img_tex.set_image(img)
		var img_can = CanvasTexture.new()
		img_can.diffuse_texture = img_tex
		sprite_obj.get_node("%Sprite2D").texture = img_can
		
	#	'''
		sprite_obj.dictmain.position = str_to_var(load_dict[i]["pos"])
		sprite_obj.sprite_id = load_dict[i]["identification"]
		sprite_obj.parent_id = load_dict[i]["parentId"]
		sprite_obj.sprite_name = "Sprite " + str(i)
		
		sprite_obj.dictmain.xFrq = load_dict[i]["xFrq"]
		sprite_obj.dictmain.xAmp = load_dict[i]["xAmp"]
		sprite_obj.dictmain.yFrq = load_dict[i]["yFrq"]
		sprite_obj.dictmain.yAmp = load_dict[i]["yAmp"]
		sprite_obj.dictmain.dragSpeed = load_dict[i]["drag"]
		sprite_obj.dictmain.rdragStr = load_dict[i]["rotDrag"]
		sprite_obj.dictmain.stretchAmount = load_dict[i]["stretchAmount"]
		
		sprite_obj.dictmain.ignore_bounce = load_dict[i]["ignoreBounce"]
		sprite_obj.dictmain.hframes = load_dict[i]["frames"]
		sprite_obj.dictmain.animation_speed = load_dict[i]["animSpeed"]
		
		if load_dict[i]["clipped"]:
			sprite_obj.dictmain.clip = 2
		else:
			sprite_obj.dictmain.clip = 0
		
		sprite_obj.dictmain.rLimitMin = load_dict[i]["rLimitMin"]
		sprite_obj.dictmain.rLimitMax = load_dict[i]["rLimitMax"]
		sprite_obj.dictmain.z_index = load_dict[i]["zindex"]
		sprite_obj.dictmain.offset = str_to_var(load_dict[i]["offset"])

		var test = load_dict[i]["showBlink"]
		var test2 = load_dict[i]["showTalk"]
		
		if test == 0:
			sprite_obj.dictmain.should_blink = false
			sprite_obj.dictmain.open_eyes = false
		elif test == 1:
			sprite_obj.dictmain.should_blink = true
			sprite_obj.dictmain.open_eyes = true
		elif test == 2:
			sprite_obj.dictmain.should_blink = true
			sprite_obj.dictmain.open_eyes = false
		
		if test2 == 0:
			sprite_obj.dictmain.should_talk = false
			sprite_obj.dictmain.open_mouth = false
		elif test2 == 1:
			sprite_obj.dictmain.should_talk = true
			sprite_obj.dictmain.open_mouth = false
		elif test2 == 2:
			sprite_obj.dictmain.should_talk = true
			sprite_obj.dictmain.open_mouth = true
			
		
		sprite_obj.states[0].merge(sprite_obj.dictmain, true)
		
		var cust = str_to_var(load_dict[i]["costumeLayers"])
		for l in cust:
			var ndict = sprite_obj.dictmain.duplicate()
			if l == 0:
				ndict.visible = false
			else:
				ndict.visible = true
			sprite_obj.states.append(ndict)
			
			
		get_tree().get_root().get_node("Main/SubViewportContainer/SubViewport/Node2D/Origin/SpritesContainer").add_child(sprite_obj)
		sprite_obj.get_node("Pos/Wobble/Squish/Drag/Rotation/Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		
	for n in 10:
		get_tree().get_root().get_node("Main/Control/StatesStuff").add_state()
	
	
		
	var dict = {
		mouth_closed = 0,
		mouth_open = 3,
		current_mc_anim = "Idle",
		current_mo_anim = "One Bounce",
	}
	
	
	var dict2 = {
		visible = false,
		energy = 0.2,
		color = Color.WHITE,
		global_position = Vector2(640,360),
		scale = Vector2(1,1),
	}
	
	
	for n in Global.settings_dict.states:
		n.merge(dict, true)
	
	for l in Global.settings_dict.light_states:
		l.merge(dict2, true)
		
	
	Global.load_sprite_states(0)
	get_tree().get_root().get_node("Main/Control").loaded_tree(get_tree().get_nodes_in_group("Sprites"))
	get_tree().get_root().get_node("Main/Control/BackgroundEdit").loaded_tree(get_tree().get_nodes_in_group("BackgroundStuff"))
	get_tree().get_root().get_node("Main/Control").sliders_revalue(Global.settings_dict)
	Global.load_sprite_states(0)
	get_tree().get_root().get_node("Main/Control/UIInput").reinfoanim()
