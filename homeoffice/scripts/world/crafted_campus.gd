extends Node3D
## Architecture, directory and facilities are components of the retained world.
var world
var data={}
var floor_nodes={}
var fixtures={}
var screens={}
var pointers={}
var pointer_until={}
var tap_states={}
var doors=preload("res://scripts/world/campus_doors.gd").new()
var tap_visuals={}
var lifts=preload("res://scripts/world/campus_lifts.gd").new()
var status_clock=0.0
var cctv:SubViewport
var cctv_camera:Camera3D
var cctv_active=false
var cctv_feed=0
var cctv_clock=0.0
var cctv_screen:MeshInstance3D

func setup(owner_world):
	world=owner_world
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v6/campus.json"))
	for floor in data.floors:
		var root=StaticBody3D.new();root.name="Campus_"+floor.id;root.collision_layer=1;add_child(root)
		var visual=load(floor.asset).instantiate();visual.name="Visual";root.add_child(visual);floor_nodes[floor.id]=root
		for shape in data.collisions:
			if shape.floor==floor.id:world.add_shape(root,shape)
		var sign=world.make_label(floor.id+"  ·  "+floor.title,Vector3(23,float(floor.y)+2.5,-32.9),0,.045)
		sign.modulate=Color("344044");sign.outline_size=0
		for x in [17,27]:
			var lamp=OmniLight3D.new();lamp.position=Vector3(x,float(floor.y)+2.7,-23);lamp.light_color=Color("ffe4ba");lamp.light_energy=.42;lamp.omni_range=8;lamp.distance_fade_enabled=true;lamp.distance_fade_begin=10;lamp.distance_fade_length=4;lamp.set_meta("base_energy",.42);world.room_lights.append(lamp);add_child(lamp)
		var wc_sign=world.make_label("WC  ·  공용 화장실",Vector3(31.8,float(floor.y)+2.58,-28.29),0,.025);wc_sign.modulate=Color("436d61");wc_sign.outline_size=0
	var passage=StaticBody3D.new();passage.add_child(load("res://assets/v6/passage.glb").instantiate());add_child(passage)
	for shape in JSON.parse_string(FileAccess.get_file_as_string("res://assets/v6/passage.json")):world.add_shape(passage,shape)
	var site=StaticBody3D.new();site.add_child(load("res://assets/v6/campus-site.glb").instantiate());add_child(site)
	for shape in data.collisions:
		if shape.floor=="site":world.add_shape(site,shape)
	for item in data.furniture:
		world.spawn_object({"id":item.id,"kind":item.kind,"p":item.p,"yaw":item.yaw,"state":{}})
	for item in data.fixtures:
		var node=StaticBody3D.new();node.position=world.vec(item.position);node.set_meta("object_id",item.id);node.collision_layer=1;add_child(node)
		var size=world.vec(item.size)
		if item.kind=="worktable":node.position.y-=.17;size.y=.12
		world.collision(node,Vector3.ZERO,size);fixtures[item.id]=item
		if item.kind=="tap":
			tap_states[item.id]=false
			var stream=MeshInstance3D.new();var tube=CylinderMesh.new();tube.top_radius=.018;tube.bottom_radius=.012;tube.height=.2;stream.mesh=tube;stream.position=node.position+Vector3(-.35,-.02,0)
			var water=StandardMaterial3D.new();water.albedo_color=Color(.35,.68,.72,.6);water.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;stream.material_override=water;stream.visible=false;add_child(stream);tap_visuals[item.id]=stream
	for room in data.rooms:
		var mesh=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(float(room.get("screenWidth",3.4)),1.8);mesh.mesh=quad;mesh.position=world.vec(room.screen)
		var mat=StandardMaterial3D.new();mat.albedo_color=Color("f7f4e9");mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=mat;mesh.layers=1<<13;add_child(mesh);screens[room.meetingId]=mesh
		var dot=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.035;sphere.height=.07;dot.mesh=sphere;var ink=StandardMaterial3D.new();ink.albedo_color=Color("ff3428");ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;dot.material_override=ink;dot.layers=1<<13;mesh.add_child(dot);dot.visible=false;pointers[room.meetingId]=dot
		var body=StaticBody3D.new();body.position=mesh.position;body.set_meta("object_id","campus-meeting-"+room.meetingId);world.collision(body,Vector3.ZERO,Vector3(quad.size.x,1.8,.10));add_child(body)
		fixtures["campus-meeting-"+room.meetingId]={"kind":"meeting","meetingId":room.meetingId,"position":room.screen}
		world.make_label({"council":"느티나무 · 주회의실","moss":"이끼 · 소회의실","clay":"흙빛 · 소회의실","seminar":"열린 세미나"}[room.meetingId],mesh.position+Vector3(0,1.12,.03),0,.034)
	add_child(lifts);lifts.setup(world,self)
	add_child(doors);doors.setup(world)
	var directory_body=StaticBody3D.new();directory_body.position=Vector3(27.3,1.78,-21.2);directory_body.set_meta("object_id","campus-directory");world.collision(directory_body,Vector3.ZERO,Vector3(2.4,1.4,.1));add_child(directory_body)
	var board=MeshInstance3D.new();var board_box=BoxMesh.new();board_box.size=Vector3(2.4,1.4,.1);board.mesh=board_box;var board_mat=StandardMaterial3D.new();board_mat.albedo_color=Color("f1e5d2");board.material_override=board_mat;directory_body.add_child(board)
	fixtures["campus-directory"]={"kind":"directory","position":[27.3,1.78,-21.2]}
	var text="COMMONS / 층 안내  ·  F 자세히 보기"
	for floor in data.floors:text+="\n"+floor.id+"  "+floor.title
	var directory_label=world.make_label(text,Vector3(27.3,1.78,-21.13),0,.018);directory_label.modulate=Color("344044");directory_label.outline_size=0
	setup_cctv()
	var gallery_end=StaticBody3D.new();gallery_end.position=Vector3(0,5.1,-12.1);world.collision(gallery_end,Vector3.ZERO,Vector3(2.8,3.0,.2));add_child(gallery_end)
	var closure=MeshInstance3D.new();var cap=BoxMesh.new();cap.size=Vector3(2.8,3.0,.2);closure.mesh=cap;var cap_mat=StandardMaterial3D.new();cap_mat.albedo_color=Color("819b7e");closure.material_override=cap_mat;gallery_end.add_child(closure)
	world.make_label("개인 작업실은 OFFICE 4F",Vector3(0,5.4,-11.96),0,.027)
	world.make_label("OFFICE ↑ · 공용 보행로",Vector3(17.5,2.67,1.66),0,.030)
	world.make_label("COMMONS  /  OFFICE",Vector3(23,3.03,-13.72),0,.068)
	world.make_label("카페 · 만남 · 공동 작업",Vector3(23,1.6,-13.72),0,.038)

func add_personal(index:int,furnish:bool):
	if index<0 or index>=data.get("personalSlots",[]).size():return
	var slot=data.personalSlots[index];var center=world.vec(slot.center);var row=int(index/4);var angle=PI if row==0 else 0.0;var direction=1.0 if row==0 else -1.0
	for item in [{"id":slot.id+"-desk","kind":"table","p":world.arr(center+Vector3(0,0,1.2*direction)),"yaw":angle,"state":{}},{"id":slot.id+"-chair","kind":"chair","p":world.arr(center+Vector3(0,0,.1*direction)),"yaw":angle,"state":{}},{"id":slot.id+"-book","kind":"book","p":world.arr(center+Vector3(0,.9,1.2*direction)),"yaw":angle,"state":{}}]:
		if furnish:world.spawn_object(item)
	world.make_door({"id":slot.id+"-door","p":slot.door,"yaw":0.0,"width":1.4,"open":true,"secure":false})
	var position=world.vec(slot.door)+Vector3(.7,2.55,-.08 if row==0 else .08)
	var label=world.make_label(world.room_slots[index].label,position,PI if row==0 else 0.0,.022);label.set_meta("room_index",index);world.module_nodes.append(label)

func migrate_personal(item:Dictionary):
	var point=world.vec(item.p)
	if point.y<3.35 or point.y>6.8 or point.z>=-12 or absf(point.x)<1.4 or absf(point.x)>6.3:return
	var pair=int(floor((-point.z-12)/5.4));var index=pair*2+(0 if point.x<0 else 1)
	if index<0 or index>=data.get("personalSlots",[]).size():return
	var origin=Vector3(-3.8 if point.x<0 else 3.8,3.6,-14.7-pair*5.4);var offset=point-origin;var slot=data.personalSlots[index]
	if index<4:offset=Basis(Vector3.UP,PI)*offset;item.yaw=float(item.yaw)+PI
	item.p=world.arr(world.vec(slot.center)+offset)

func floor_ready(id:String) -> bool:return floor_nodes.has(id) and is_instance_valid(floor_nodes[id])

func floor_at(point:Vector3) -> String:
	if point.x<9.7 or point.x>36.3 or point.z< -38.3 or point.z> -13.7:return ""
	var nearest="";var distance=100.0
	for floor in data.get("floors",[]):
		var d=point.y-float(floor.y)
		if d>=-.25 and d<3.6 and absf(d)<distance:nearest=floor.id;distance=absf(d)
	return nearest

func zone_at(point:Vector3) -> String:
	var floor=floor_at(point)
	if floor=="":return ""
	var restricted=world.room_access.restricted_zone(world,point)
	if restricted!="":return restricted
	for slot in data.get("personalSlots",[]):
		var rect=slot.rect
		if floor=="4F" and point.x>=rect[0] and point.x<=rect[2] and point.z>=rect[1] and point.z<=rect[3]:return slot.id
	for room in data.rooms:
		var q=room.rect
		if room.floor==floor and point.x>=q[0] and point.x<=q[2] and point.z>=q[1] and point.z<=q[3]:return room.id
	if point.x>30.6 and point.z< -28.4:return "office-"+floor+"-wc"
	return "office-"+floor+"-hall"

func meeting_at(point:Vector3) -> String:
	for room in data.rooms:
		if zone_at(point)==room.id:return room.meetingId
	return ""

func fixture_action(actor:String,focused:String) -> bool:
	if not world.players.has(actor):return false
	var p=world.players[actor]
	if focused.begins_with("campus-door-"):
		var reason=doors.action(actor,focused.trim_prefix("campus-door-"))
		if reason!="":world.reject(actor,reason)
		return true
	if focused.begins_with("lift-console-"):
		var lift_id=focused.trim_prefix("lift-console-")
		if lifts.cars.has(lift_id) and lifts.occupants(lifts.cars[lift_id]).has(actor):world.notify_ui(actor,"lift:"+lift_id);return true
	if not fixtures.has(focused):return false
	var item=fixtures[focused]
	if p.eye().distance_to(world.vec(item.position))>4.0:return true
	match item.kind:
		"lift-call":
			var reason=lifts.request(actor,item.liftId,item.floor)
			if reason!="":world.reject(actor,reason)
			else:world.notify_ui(actor,"lift:"+item.liftId)
		"directory":world.notify_ui(actor,"directory")
		"meeting":world.notify_ui(actor,"workspace:"+item.meetingId)
		"worktable":world.notify_ui(actor,"broadcast" if focused=="broadcast-campus" else "workspace:"+meeting_at(p.position))
		"tap":
			tap_states[focused]=not tap_states[focused]
			world.send({"type":"campus-fixtures","epoch":world.epoch,"states":tap_states})
		"cctv":
			if not world.room_access.is_administrator(actor):world.reject(actor,"운영 관리자 인증 후 이 콘솔을 사용할 수 있습니다.")
			elif actor==world.local_id:open_cctv()
			else:world.send({"type":"campus-cctv","epoch":world.epoch,"open":true},actor)
	return true

func setup_cctv():
	cctv=SubViewport.new();cctv.size=Vector2i(640,360);cctv.own_world_3d=false;cctv.world_3d=get_world_3d();cctv.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(cctv)
	cctv_camera=Camera3D.new();cctv.add_child(cctv_camera);cctv_camera.current=true;cctv_camera.fov=48;cctv_camera.far=9.0;cctv_camera.cull_mask=0xfffff&~((1<<12)|(1<<13))
	cctv_screen=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(1.6,.9);cctv_screen.mesh=quad;cctv_screen.position=Vector3(13,15.7,-20.56);cctv_screen.layers=1<<13
	var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_texture=cctv.get_texture();cctv_screen.material_override=mat;add_child(cctv_screen);cctv_screen.visible=false

func open_cctv():
	cctv_active=true;cctv_screen.visible=true;select_feed(0)
	world.notify_ui(world.local_id,"cctv")

func select_feed(index:int):
	cctv_feed=clampi(index,0,1)
	var y=0.0 if cctv_feed==0 else -3.6
	cctv_camera.position=Vector3(23,y+2.6,-31.1);cctv_camera.look_at(Vector3(23,y+.9,-25.5))

func close_cctv():
	cctv_active=false;cctv.render_target_update_mode=SubViewport.UPDATE_DISABLED;cctv_screen.visible=false

func set_slide(meeting_id:String,image:String):
	if not screens.has(meeting_id) or image.length()>1500000:return
	var decoded=Image.new()
	if decoded.load_jpg_from_buffer(Marshalls.base64_to_raw(image))!=OK:return
	if decoded.get_width()>2048 or decoded.get_height()>2048:return
	screens[meeting_id].material_override.albedo_texture=ImageTexture.create_from_image(decoded)

func set_pointer(meeting_id:String,uv):
	if not pointers.has(meeting_id):return
	var dot=pointers[meeting_id]
	if uv==null:dot.visible=false;return
	if not uv is Array or uv.size()!=2 or float(uv[0])<0 or float(uv[0])>1 or float(uv[1])<0 or float(uv[1])>1:return
	var size=screens[meeting_id].mesh.size
	dot.position=Vector3((float(uv[0])-.5)*size.x,(.5-float(uv[1]))*size.y,.08);dot.visible=true;pointer_until[meeting_id]=Time.get_ticks_msec()+450

func placement_clear(volume:AABB) -> bool:
	if not doors.clearance(volume):return false
	for lift in data.get("lifts",[]):
		if volume.intersects(AABB(Vector3(lift.x-lift.width*.5-.35,-4,-36.6),Vector3(lift.width+.7,29,4.5))):return false
	for hole in data.get("stairHoles",[]):
		if volume.intersects(AABB(Vector3(hole[0]-.15,-4,hole[1]-.1),Vector3(hole[2]-hole[0]+.3,29,hole[3]-hole[1]+1.4))):return false
	return true

func _process(dt):
	if not world or not world.ready_to_play:return
	var p=world.players.get(world.local_id)
	if not p:return
	if cctv_active:
		var point=world.vec(fixtures["campus-cctv"].position)
		if not world.room_access.is_administrator(world.local_id) or p.eye().distance_to(point)>4.0:close_cctv()
		else:
			cctv_clock+=dt
			if cctv_clock>=.125:cctv_clock=0;cctv.render_target_update_mode=SubViewport.UPDATE_ONCE
	for id in pointer_until:
		if Time.get_ticks_msec()>pointer_until[id]:pointers[id].visible=false
	status_clock+=dt
	if status_clock>.3 and world.bridge:
		status_clock=0;refresh_visibility(p);world.bridge.campus_status(JSON.stringify({"stored":world.unplaced.map(func(o):return {"id":o.id,"kind":o.kind,"contained":world.unplaced.any(func(parent):return parent.state.get("contents",[]).has(o.id))}),"floor":floor_at(p.position),"zone":zone_at(p.position),"directory":data.floors.map(func(f):return {"id":f.id,"title":f.title}),"lifts":lifts.snapshot(),"cctv":cctv_active,"feed":cctv_feed,"taps":tap_states}))

func refresh_visibility(p):
	var floor=floor_at(p.position)
	for id in tap_visuals:tap_visuals[id].visible=bool(tap_states.get(id,false))
	for f in data.floors:
		var visual=floor_nodes[f.id].get_node("Visual")
		var feed_visible=cctv_active and f.id==("1F" if cctv_feed==0 else "B1")
		visual.visible=(floor=="" and f.id!="B1") or absf(float(f.y)-p.position.y)<5.3 or feed_visible
		for mesh in visual.find_children("*","MeshInstance3D",true,false):
			if String(mesh.name).begins_with("Inside_"):mesh.visible=absf(float(f.y)-p.position.y)<4.2 and p.position.distance_to(Vector3(23,p.position.y,-26))<36 or feed_visible
	for id in world.objects:
		var object=world.objects[id]
		var object_floor=floor_at(object.position)
		if object_floor=="":
			if object.get_meta("campus_render_hidden",false):object.get_child(0).visible=true;object.remove_meta("campus_render_hidden")
			continue
		var feed_visible=cctv_active and object_floor==("1F" if cctv_feed==0 else "B1")
		var show_object=absf(object.position.y-p.position.y)<3 and object.position.distance_to(p.position)<40 or feed_visible
		object.get_child(0).visible=show_object;object.set_meta("campus_render_hidden",not show_object)
	for entry in doors.entries.values():
		var show_door=absf(float(entry.spec.p[1])-p.position.y)<4.2
		entry.body.visible=show_door;entry.button.visible=show_door
	for car in lifts.cars.values():
		car.body.visible=absf(car.body.position.y-p.position.y)<5.5
		for f in data.floors:
			var show_landing=absf(float(f.y)-p.position.y)<4.2 or cctv_active and f.id==("1F" if cctv_feed==0 else "B1")
			for leaf in car.landings[f.id]:leaf.visible=show_landing
	for door in world.doors.values():
		if door.position.x>9:door.visible=absf(door.position.y-p.position.y)<4.2
	for avatar in world.players.values():
		for label in avatar.find_children("*","Label3D",true,false):label.layers=1<<12
