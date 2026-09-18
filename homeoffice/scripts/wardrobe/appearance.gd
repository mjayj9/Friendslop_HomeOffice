extends RefCounted
## Validated raster/palette data only. Each avatar owns its material instances.
const MAX_PNG=262144
const SIZE=512

static func defaults() -> Dictionary:
	return {"version":1,"revision":0,"face":"","faceHash":"","shirt":"","pants":"","shoes":""}

static func validate(value) -> Dictionary:
	if not value is Dictionary or value.size()!=7:return {}
	for key in defaults():
		if not value.has(key):return {}
	if value.version!=1 or not (value.revision is int or value.revision is float) or not is_finite(float(value.revision)) or value.revision<0 or value.revision>1000000 or float(value.revision)!=floor(float(value.revision)):return {}
	for key in ["shirt","pants","shoes"]:
		if not value[key] is String:return {}
		var color=String(value[key])
		if color!="" and (color.length()!=7 or not color.begins_with("#") or not color.substr(1).is_valid_hex_number()):return {}
	if not value.face is String or not value.faceHash is String or value.face.length()>MAX_PNG*4/3+4:return {}
	if value.face=="":
		if value.faceHash!="":return {}
	else:
		var bytes=Marshalls.base64_to_raw(value.face)
		if bytes.size()<33 or bytes.size()>MAX_PNG or bytes.slice(0,8)!=PackedByteArray([137,80,78,71,13,10,26,10]):return {}
		# Header limits precede decompression; fixed canvas and 8-bit RGB/RGBA only.
		if bytes.slice(12,16).get_string_from_ascii()!="IHDR" or bytes[16]!=0 or bytes[17]!=0 or bytes[18]!=2 or bytes[19]!=0 or bytes[20]!=0 or bytes[21]!=0 or bytes[22]!=2 or bytes[23]!=0 or bytes[24]!=8 or bytes[25] not in [2,6]:return {}
		var image=Image.new()
		if image.load_png_from_buffer(bytes)!=OK or image.get_width()!=SIZE or image.get_height()!=SIZE:return {}
		var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
		if hash.finish().hex_encode()!=value.faceHash:return {}
	return value.duplicate(true)

static func apply(visual:Node,profile:Dictionary):
	var face_texture:ImageTexture
	if profile.get("face","")!="":
		var painted=Image.new();painted.load_png_from_buffer(Marshalls.base64_to_raw(profile.face))
		painted.convert(Image.FORMAT_RGBA8)
		face_texture=ImageTexture.create_from_image(painted)
	for node in visual.find_children("*","MeshInstance3D",true,false):
		if not node.mesh:continue
		for index in node.mesh.get_surface_count():
			var source=node.mesh.surface_get_material(index)
			if not source is StandardMaterial3D:continue
			var material=source.duplicate(true)
			var name=source.resource_name.to_lower()
			for part in ["shirt","pants","shoes"]:
				if name.begins_with(part) and profile.get(part,"")!="":material.albedo_color=Color(profile[part])
			if name.begins_with("v5_face") and face_texture:
				# Paint is composited over the original skin; eraser exposes the source skin.
				var base=Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
				base.fill(source.albedo_color)
				base.blend_rect(face_texture.get_image(),Rect2i(0,0,SIZE,SIZE),Vector2i.ZERO)
				material.albedo_texture=ImageTexture.create_from_image(base);material.albedo_color=Color.WHITE
			node.set_surface_override_material(index,material)
