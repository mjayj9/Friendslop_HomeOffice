extends Node3D

const Avatar=preload("res://scripts/avatar.gd")
const Board=preload("res://scripts/board.gd")
var bridge
var host=true
var local_id="local"
var epoch="local"
var players={}
var objects={}
var definitions={}
var manifest={}
var inputs={}
var actions={}
var strokes=[]
var door_open=false
var door:Node3D
var board_view:SubViewport
var board_draw:Node2D
var board_body:StaticBody3D
var seq=0
var revision=0
var tick=0
var snapshot_timer=0.0
var state_timer=0.0
var yaw=0.0
var pitch=0.0
var hud:Label
var hint:Label
var ready_to_play=false
var last_snapshot_ms=0
var last_board_point=[]
var board_cooldown=0.0
var world_id=""
var pending_restore={}
var frozen=false
var last_remote_tick=-1

func _ready():
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset-manifest.json"))
	world_id="world-"+str(Time.get_unix_time_from_system())
	setup_environment()
	setup_board()
	default_furniture()
	setup_hud()
	var preview_camera=Camera3D.new()
	add_child(preview_camera)
	preview_camera.position=Vector3(2.8,1.7,3.8)
	preview_camera.look_at(Vector3(-1,.9,-1.5))
	preview_camera.current=true
	if OS.has_feature("web"):
		bridge=JavaScriptBridge.get_interface("Homeoffice")
		bridge.ready()
		hud.visible=false
		hint.visible=false
	else:
		ready_to_play=true
		add_player(local_id)
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	print("HOMEoffice_READY Godot ",Engine.get_version_info().string)

func vec(a) -> Vector3:return Vector3(float(a[0]),float(a[1]),float(a[2]))
func arr(v:Vector3) -> Array:return [v.x,v.y,v.z]

func collision(parent:Node3D,pos:Vector3,size:Vector3):
	var c=CollisionShape3D.new()
	var shape=BoxShape3D.new()
	shape.size=size
	c.shape=shape
	c.position=pos
	parent.add_child(c)

func model(kind:String) -> Node3D:
	return load("res://assets/environment/"+kind+".glb").instantiate()

func setup_environment():
	add_child(model("architecture"))
	var solid=StaticBody3D.new()
	solid.collision_layer=1
	add_child(solid)
	for c in manifest.assets.architecture.collisions:
		collision(solid,vec(c.position),vec(c.size))
	var env=WorldEnvironment.new()
	var e=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("aac7cc")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("fff0d9")
	e.ambient_light_energy=.32
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.environment=e
	add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-43,-28,0)
	sun.light_color=Color("fff1d4")
	sun.light_energy=.62
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=32
	add_child(sun)
	for p in [Vector3(-1,2.48,0),Vector3(9.5,2.48,0)]:
		var lamp=SpotLight3D.new()
		lamp.position=p
		lamp.light_color=Color("ffe4ad")
		lamp.light_energy=.8
		lamp.spot_range=7
		lamp.spot_angle=75
		lamp.rotation.x=-PI/2
		lamp.shadow_enabled=true
		add_child(lamp)
	door=StaticBody3D.new()
	door.position=Vector3(6,0,-.87)
	door.rotation.y=-PI/2
	door.set_meta("object_id","door")
	door.collision_layer=1
	door.add_child(model("door"))
	collision(door,Vector3(.63,1.18,0),Vector3(1.26,2.36,.08))
	add_child(door)

func setup_board():
	board_view=SubViewport.new()
	board_view.size=Vector2i(1024,512)
	board_view.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(board_view)
	board_draw=Board.new()
	board_view.add_child(board_draw)
	var mesh=MeshInstance3D.new()
	var quad=QuadMesh.new()
	quad.size=Vector2(3.46,1.68)
	mesh.mesh=quad
	var material=StandardMaterial3D.new()
	material.albedo_texture=board_view.get_texture()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override=material
	mesh.position=Vector3(9.5,1.76,-4.71)
	add_child(mesh)
	board_body=StaticBody3D.new()
	board_body.position=mesh.position
	board_body.set_meta("object_id","board")
	board_body.collision_layer=1
	collision(board_body,Vector3.ZERO,Vector3(3.48,1.7,.045))
	add_child(board_body)

func default_furniture():
	spawn_object({"id":"sofa-1","kind":"sofa","p":[-1,0,1.8],"yaw":0.0})
	spawn_object({"id":"meeting-table","kind":"table","p":[9.5,0,0],"yaw":0.0})
	spawn_object({"id":"coffee-table","kind":"table","p":[-1,0,-.55],"yaw":0.0})
	for i in range(4):
		spawn_object({"id":"chair-"+str(i),"kind":"chair","p":[8.65+float(i%2)*1.6,0,1.2 if i<2 else -1.2],"yaw":0.0 if i<2 else PI})
	spawn_object({"id":"lounge-chair","kind":"chair","p":[2.4,0,.4],"yaw":-PI/2})
	spawn_object({"id":"book-1","kind":"book","p":[-.6,.89,-.5],"yaw":.15})
	spawn_object({"id":"crate-1","kind":"crate","p":[2,.25,-2],"yaw":.1})
	spawn_object({"id":"crate-2","kind":"crate","p":[2.6,.25,-2],"yaw":-.1})
	spawn_object({"id":"marker-1","kind":"marker","p":[9.5,1.01,-4.6],"yaw":0.0})

func spawn_object(d:Dictionary):
	var kind=String(d.kind)
	var movable=kind in ["crate","book","marker"]
	var body:PhysicsBody3D=RigidBody3D.new() if movable else StaticBody3D.new()
	body.name=d.id
	body.set_meta("object_id",d.id)
	body.set_meta("owner","")
	body.set_meta("occupant","")
	body.collision_layer=4 if movable else 1
	body.collision_mask=1|2|4
	body.position=vec(d.p)
	body.rotation.y=float(d.yaw)
	body.add_child(model(kind))
	if movable:
		var size=Vector3(.44,.44,.44) if kind=="crate" else (Vector3(.24,.075,.32) if kind=="book" else Vector3(.03,.19,.03))
		collision(body,Vector3.ZERO,size)
		body.mass=2.4 if kind=="crate" else .35
		body.continuous_cd=true
		body.linear_damp=.5
		body.angular_damp=2
		var physics=PhysicsMaterial.new()
		physics.friction=.65
		physics.bounce=.12
		body.physics_material_override=physics
		body.freeze=not host
	elif kind=="chair":
		collision(body,Vector3(0,.26,0),Vector3(.53,.52,.53))
		collision(body,Vector3(0,.84,.24),Vector3(.54,.60,.08))
	else:
		for c in manifest.assets[kind].collisions:collision(body,vec(c.position),vec(c.size))
	add_child(body)
	objects[d.id]=body
	definitions[d.id]=d.duplicate(true)

func add_player(id:String):
	if players.has(id) or players.size()>=8:return
	var a=Avatar.new()
	a.actor_id=id
	a.local_player=id==local_id
	a.position=Vector3(1+players.size()*.7,0,3.4)
	add_child(a)
	players[id]=a
	inputs[id]=-1
	actions[id]=-1
	if a.local_player:a.camera.current=true

func setup_hud():
	var canvas=CanvasLayer.new()
	add_child(canvas)
	hud=Label.new()
	hud.position=Vector2(26,25)
	hud.add_theme_font_size_override("font_size",18)
	hud.add_theme_color_override("font_shadow_color",Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x",1)
	hud.add_theme_constant_override("shadow_offset_y",1)
	canvas.add_child(hud)
	hint=Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint.position=Vector2(580,380)
	canvas.add_child(hint)
	var cross=Label.new()
	cross.text="·"
	cross.add_theme_font_size_override("font_size",30)
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	canvas.add_child(cross)
	cross.visible=not OS.has_feature("web")

func playing() -> bool:
	return ready_to_play and (not bridge or bool(bridge.is_playing())) and not frozen

func _unhandled_input(event):
	if event is InputEventMouseMotion and playing() and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		yaw-=event.relative.x*.002
		pitch=clampf(pitch-event.relative.y*.002,-1.35,1.35)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			if bridge:bridge.menu()
		if not playing():return
		if event.keycode==KEY_E:request_action("interact")
		if event.keycode==KEY_Q:request_action("drop")
		if event.keycode==KEY_F:request_action("read")
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and playing():
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		if players.has(local_id) and players[local_id].holding!="":
			if definitions[players[local_id].holding].kind!="marker":request_action("throw")

func _physics_process(dt):
	if bridge:
		var events=JSON.parse_string(String(bridge.take_events()))
		if events is Array:
			for event in events:handle_event(event)
	if not ready_to_play:return
	tick+=1
	var p=players.get(local_id)
	if p:
		seq+=1
		var enabled=playing()
		if enabled:
			yaw+=(float(Input.is_physical_key_pressed(KEY_LEFT))-float(Input.is_physical_key_pressed(KEY_RIGHT)))*dt*1.5
			pitch=clampf(pitch+(float(Input.is_physical_key_pressed(KEY_UP))-float(Input.is_physical_key_pressed(KEY_DOWN)))*dt*1.2,-1.35,1.35)
		var cmd={"x":float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)) if enabled else 0.0,"z":float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)) if enabled else 0.0,"yaw":yaw,"pitch":pitch,"jump":enabled and Input.is_physical_key_pressed(KEY_SPACE) and not p.command.jump,"run":enabled and Input.is_physical_key_pressed(KEY_SHIFT),"seq":seq}
		p.command=cmd
		p.last_input_ms=Time.get_ticks_msec()
		if not host and tick%2==0:send({"type":"input","epoch":epoch,"command":cmd})
		if not host and not frozen:p.simulate(dt)
	if host and not frozen:
		for id in players:
			var a=players[id]
			if id!=local_id and Time.get_ticks_msec()-a.last_input_ms>300:
				a.command.x=0
				a.command.z=0
				a.command.jump=false
			a.simulate(dt)
		update_held(dt)
		for obj in objects.values():
			if obj is RigidBody3D:
				obj.linear_velocity=obj.linear_velocity.limit_length(14)
				obj.angular_velocity=obj.angular_velocity.limit_length(12)
				if obj.position.y < -3:
					obj.position=vec(definitions[obj.name].p)
					obj.linear_velocity=Vector3.ZERO
	if not host:
		for id in players:
			if id==local_id:continue
			players[id].position=players[id].position.lerp(players[id].remote_target,1-exp(-dt*18))
			players[id].rotation.y=lerp_angle(players[id].rotation.y,players[id].remote_yaw,1-exp(-dt*18))
		if Time.get_ticks_msec()-last_snapshot_ms>2500:
			frozen=true
			if bridge:bridge.status("호스트 응답 대기 · 마지막 확인 상태 보존 중")
	for a in players.values():a.animate(dt)
	door.rotation.y=move_toward(door.rotation.y,0.0 if door_open else -PI/2,dt*2)
	state_timer+=dt
	snapshot_timer+=dt
	if state_timer>.067:
		state_timer=0
		var snapshot=network_state()
		if host:send(snapshot)
		if bridge:bridge.observe(JSON.stringify(snapshot))
	if snapshot_timer>2 and host:
		snapshot_timer=0
		send({"type":"world","epoch":epoch,"world":save_world(),"strokes":strokes})
	update_hint()
	board_cooldown-=dt
	if p and playing() and p.holding!="" and definitions[p.holding].kind=="marker" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and board_cooldown<=0:
		board_cooldown=.07
		var hit=target(p)
		if hit.get("id","")=="board":
			var pt=hit.point
			var uv=[clampf((pt.x-7.77)/3.46,0,1),clampf((2.60-pt.y)/1.68,0,1)]
			if not last_board_point.is_empty():request_action("stroke",{"points":[last_board_point,uv],"color":"#183b32","width":4})
			last_board_point=uv
	else:last_board_point=[]

func target(p) -> Dictionary:
	var query=PhysicsRayQueryParameters3D.create(p.eye(),p.eye()+p.direction()*3.0,1|4,[p.get_rid()])
	if p.holding!="" and objects.has(p.holding):
		var excluded=query.exclude
		excluded.append(objects[p.holding].get_rid())
		query.exclude=excluded
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():return {}
	return {"id":hit.collider.get_meta("object_id",""),"point":hit.position}

func update_hint():
	var p=players.get(local_id)
	if not p:return
	var zone="MEETING ROOM" if p.position.x>6 else "LIVING ROOM"
	hud.text="MOYEO HOUSE    /    "+zone+"\n"+str(players.size())+" people   ·   "+("HOST" if host else "CONNECTED")+"   ·   "+str(Engine.get_frames_per_second())+" FPS"
	var id=target(p).get("id","")
	var label=""
	if p.seated!="":label="E  Stand up"
	elif id=="door":label="E  Open / Close"
	elif id=="board":label="E  Whiteboard"
	elif objects.has(id):
		var kind=definitions[id].kind
		label="E  Sit down" if kind in ["chair","sofa"] else ("E  Pick up" if kind in ["book","crate","marker"] else "")
	if p.holding!="":label+="   Q Drop · Click Throw" if definitions[p.holding].kind!="marker" else "   Click Draw · Q Drop"
	if p.holding!="" and definitions[p.holding].kind=="book":label+=" · F Read"
	hint.text=label
	if bridge:bridge.hint(label)

func request_action(kind:String,data:Dictionary={}):
	seq+=1
	var message={"type":"action","epoch":epoch,"seq":seq,"action":kind,"data":data}
	if host:perform(local_id,message)
	else:send(message)

func send(message:Dictionary,to:String=""):
	if bridge:bridge.send(JSON.stringify(message),to)

func reject(id:String,reason:String):
	if id==local_id and bridge:bridge.status(reason)
	elif id!=local_id:send({"type":"notice","text":reason},id)

func perform(id:String,m:Dictionary):
	if not host or frozen or not players.has(id) or m.get("epoch")!=epoch:return
	var order=int(m.get("seq",-1))
	if order<=int(actions.get(id,-1)):return
	actions[id]=order
	var p=players[id]
	var action=m.get("action","")
	var data=m.get("data",{})
	if action in ["drop","throw"]:
		if p.holding!="":release(p,action=="throw")
		return
	if action=="read":
		if p.holding!="" and definitions[p.holding].kind=="book":notify_ui(id,"book")
		return
	if action in ["stroke","undo"]:
		if p.eye().distance_to(board_body.position)>4.2:return reject(id,"보드 가까이에서 사용할 수 있습니다")
		var ray=PhysicsRayQueryParameters3D.create(p.eye(),board_body.position,1,[p.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider!=board_body:return
		var operation={}
		if action=="undo":
			for i in range(strokes.size()-1,-1,-1):
				if strokes[i].author==id:
					operation={"remove":strokes[i].id}
					strokes.remove_at(i)
					break
		elif strokes.size()<512 and valid_stroke(data):
			strokes.append({"id":id+":"+str(order),"author":id,"points":data.points,"color":data.color,"width":data.width})
			operation={"add":strokes[-1]}
		else:return reject(id,"보드 획 한도 또는 형식을 확인해 주세요")
		refresh_board()
		send({"type":"board","epoch":epoch,"operation":operation})
		revision+=1
		return
	if action!="interact":return
	if p.seated!="":
		var chair=objects[p.seated]
		var point=chair.global_transform*Vector3(0,0,-.90)
		if not safe_stand(point,p):return reject(id,"일어설 자리에 물건이 있습니다")
		chair.set_meta("occupant","")
		p.seated=""
		p.position=point
		return
	var hit=target(p)
	var object_id=hit.get("id","")
	if object_id=="door":
		for a in players.values():
			if a.position.distance_to(Vector3(6.3,0,-.25))<1.15:return reject(id,"문에서 한 걸음 물러나 주세요")
		door_open=not door_open
		revision+=1
		return
	if object_id=="board":notify_ui(id,"board");return
	if not objects.has(object_id):return
	var o=objects[object_id]
	var kind=definitions[object_id].kind
	if kind in ["chair","sofa"]:
		if o.get_meta("occupant")!="":return reject(id,"이미 다른 사람이 앉아 있습니다")
		if p.holding!="":release(p,false)
		o.set_meta("occupant",id)
		p.seated=object_id
		p.seat_yaw=o.rotation.y
		p.position=o.position
		p.rotation.y=o.rotation.y
		p.command.yaw=o.rotation.y
		if id==local_id:yaw=o.rotation.y
	elif o is RigidBody3D:
		if o.get_meta("owner")!="" or p.holding!="":return reject(id,"이미 사용 중이거나 손이 차 있습니다")
		o.set_meta("owner",id)
		p.holding=object_id
		o.gravity_scale=0
		o.add_collision_exception_with(p)
		p.add_collision_exception_with(o)
		revision+=1

func safe_stand(point:Vector3,p) -> bool:
	var s=CapsuleShape3D.new()
	s.radius=.28
	s.height=1.72
	var q=PhysicsShapeQueryParameters3D.new()
	q.shape=s
	q.transform.origin=point+Vector3(0,.88,0)
	q.collision_mask=1|2|4
	q.exclude=[p.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()

func update_held(dt:float):
	for p in players.values():
		if p.holding=="":continue
		var o=objects.get(p.holding)
		if not o:continue
		var grip=p.eye()+p.direction()*1.05+Vector3(0,-.35,0)
		var query=PhysicsRayQueryParameters3D.create(p.eye(),grip,1,[p.get_rid(),o.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():grip=hit.position-p.direction()*.28
		var delta=grip-o.position
		if delta.length()>3:release(p,false);continue
		# Bounded critically damped velocity, never teleport a held rigid body.
		o.linear_velocity=(delta*12).limit_length(7)
		o.angular_velocity=Vector3.ZERO
		o.sleeping=false

func release(p,throwing:bool):
	var o=objects.get(p.holding)
	if not o:return
	o.set_meta("owner","")
	o.gravity_scale=1
	o.linear_velocity=p.direction()*(9 if throwing else 0)+Vector3.UP*(1.6 if throwing else 0)
	o.remove_collision_exception_with(p)
	p.remove_collision_exception_with(o)
	p.holding=""
	revision+=1

func valid_stroke(d) -> bool:
	if not d is Dictionary or not d.get("points") is Array:return false
	if d.points.size()<2 or d.points.size()>256:return false
	if not d.get("color","") in ["#183b32","#bd5737","#305ea2","#f4f4ed"]:return false
	if not (d.get("width",0) is float or d.get("width",0) is int):return false
	if d.width<1 or d.width>24:return false
	for p in d.points:
		if not p is Array or p.size()!=2:return false
		for v in p:
			if not (v is int or v is float) or not is_finite(float(v)) or v<0 or v>1:return false
	return true

func notify_ui(id:String,mode:String):
	if id==local_id and bridge:bridge.open_tool(mode)
	elif id!=local_id:send({"type":"tool","mode":mode},id)

func refresh_board():
	board_draw.strokes=strokes
	board_draw.queue_redraw()
	board_view.render_target_update_mode=SubViewport.UPDATE_ONCE
	if bridge:bridge.board(JSON.stringify(strokes))

func network_state() -> Dictionary:
	var ps=[]
	var os=[]
	for p in players.values():ps.append(p.state())
	for id in objects:
		var o=objects[id]
		os.append({"id":id,"p":arr(o.position),"r":arr(o.rotation),"owner":o.get_meta("owner"),"occupant":o.get_meta("occupant")})
	return {"type":"state","epoch":epoch,"tick":tick,"revision":revision,"players":ps,"objects":os,"door":door_open,"paused":frozen}

func save_world() -> Dictionary:
	var os=[]
	for id in definitions:
		var d=definitions[id].duplicate(true)
		var o=objects[id]
		d.p=arr(o.position)
		d.yaw=o.rotation.y
		os.append(d)
	return {"schemaVersion":1,"worldId":world_id,"assetPack":1,"zones":["living","meeting"],"objects":os,"doorOpen":door_open,"board":strokes,"revision":revision}

func handle_event(e:Dictionary):
	match e.get("type",""):
		"start":
			host=bool(e.host)
			local_id=e.id
			epoch=e.epoch
			for p in players.values():p.queue_free()
			players.clear()
			add_player(local_id)
			ready_to_play=true
			last_remote_tick=-1
			frozen=false
			last_snapshot_ms=Time.get_ticks_msec()
			for o in objects.values():
				if o is RigidBody3D:o.freeze=not host
		"join":
			if host:
				add_player(e.id)
				send({"type":"welcome","epoch":epoch,"world":save_world()},e.id)
		"leave":
			if players.has(e.id):
				var p=players[e.id]
				if host:
					if p.holding!="":release(p,false)
					if p.seated!="":objects[p.seated].set_meta("occupant","")
				p.queue_free()
				players.erase(e.id)
		"resume":Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		"visibility":
			if host:
				frozen=bool(e.hidden)
				for body in objects.values():
					if body is RigidBody3D:body.freeze=frozen
		"action":request_action(e.action,e.get("data",{}))
		"export":
			if host and bridge:bridge.export_world(JSON.stringify(save_world()))
		"restore":
			if host and players.size()==1:
				restore_world(e.world)
				epoch="restored-"+str(Time.get_unix_time_from_system())
				if bridge:bridge.set_epoch(epoch)
		"data":handle_packet(e.sender,e.message)

func handle_packet(sender:String,m):
	if not m is Dictionary:return
	if host:
		if not players.has(sender) or m.get("epoch")!=epoch:return
		if m.get("type")=="action":perform(sender,m)
		if m.get("type")=="input":
			var c=m.get("command",{})
			if not valid_input(c) or int(c.seq)<=int(inputs.get(sender,-1)):return
			inputs[sender]=int(c.seq)
			players[sender].command=c
			players[sender].last_input_ms=Time.get_ticks_msec()
		return
	if m.get("type")=="welcome":
		epoch=m.epoch
		if bridge:bridge.set_epoch(epoch)
		restore_world(m.world)
	if m.get("epoch",epoch)!=epoch:return
	match m.get("type",""):
		"state":
			last_snapshot_ms=Time.get_ticks_msec()
			frozen=bool(m.paused)
			if int(m.tick)<=last_remote_tick:return
			last_remote_tick=int(m.tick)
			door_open=m.door
			var live=[]
			for s in m.players:
				live.append(s.id)
				add_player(s.id)
				if not players.has(s.id):continue
				var p=players[s.id]
				p.command.pitch=s.pitch
				p.command.yaw=s.yaw if s.id!=local_id else yaw
				p.seated=s.seat
				p.seat_yaw=float(s.get("seatYaw",s.yaw))
				p.holding=s.hold
				p.velocity=vec(s.v)
				if s.id==local_id:
					var error=vec(s.p)-p.position
					if s.seat!="" or error.length()>.8:p.position=vec(s.p)
					elif error.length()>.08:p.position+=error*.3
				else:
					p.remote_target=vec(s.p)
					p.remote_yaw=s.yaw
			for id in players.keys():
				if not id in live and id!=local_id:players[id].queue_free();players.erase(id)
			for s in m.objects:
				if objects.has(s.id):
					objects[s.id].position=vec(s.p)
					objects[s.id].rotation=vec(s.r)
					objects[s.id].set_meta("owner",s.owner)
					objects[s.id].set_meta("occupant",s.occupant)
		"world":
			if bridge:bridge.recovery(JSON.stringify(m.world))
			strokes=m.strokes
			refresh_board()
		"board":
			var operation=m.get("operation",{})
			if operation.has("add"):
				var exists=false
				for stroke in strokes:
					if stroke.id==operation.add.id:exists=true
				if not exists:strokes.append(operation.add)
			if operation.has("remove"):
				strokes=strokes.filter(func(stroke):return stroke.id!=operation.remove)
			refresh_board()
		"tool":
			if bridge:bridge.open_tool(m.mode)
		"notice":
			if bridge:bridge.status(m.text)

func valid_input(c) -> bool:
	if not c is Dictionary:return false
	for k in ["x","z","yaw","pitch","seq"]:
		if not (c.get(k) is float or c.get(k) is int) or not is_finite(float(c[k])):return false
	return absf(c.x)<=1 and absf(c.z)<=1 and absf(c.yaw)<100000 and absf(c.pitch)<=1.4 and c.seq>=0 and c.seq<1e12 and c.get("jump") is bool and c.get("run") is bool

func restore_world(w:Dictionary):
	# Only schema-validated browser save files or the trusted session host reach this method.
	for o in objects.values():remove_child(o);o.queue_free()
	objects.clear()
	definitions.clear()
	for d in w.objects:spawn_object(d)
	strokes=w.board.duplicate(true)
	door_open=w.doorOpen
	world_id=w.worldId
	revision=int(w.revision)
	for p in players.values():
		p.holding=""
		p.seated=""
		p.position=Vector3(1,0,3.4)
	refresh_board()
