extends Node3D
var key_bindings={"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SPACE,"run":KEY_SHIFT,"crouch":KEY_C,"interact":KEY_E,"drop":KEY_Q,"read":KEY_F,"secondary":KEY_R,"rest":KEY_Z,"build":KEY_B,"move":KEY_G,"remove":KEY_DELETE,"look_left":KEY_LEFT,"look_right":KEY_RIGHT,"look_up":KEY_UP,"look_down":KEY_DOWN}
var blocked_keys={}
var last_jump_down=false
var sunlight:DirectionalLight3D
var slide_laser:MeshInstance3D
var slide_laser_until=0

const Avatar=preload("res://scripts/v2/avatar.gd")
const Board=preload("res://scripts/v2/board.gd")
var layout={}
var v2_manifest={}
var doors={}
var door_states={}
var room_slots=[]
var member_slots={}
var member_identity={}
var room_claims={}
var room_fill:StaticBody3D
var room_lights=[]
var module_nodes=[]
var room_end:StaticBody3D
var entry_grants={}
var weapon_grants={}
var weapon_zones=["game"]
var rounds={"basketball":{"phase":"practice","mode":"practice","seconds":0.0},"football":{"phase":"practice","mode":"practice","seconds":0.0},"tag":{"phase":"ready","mode":"targets","seconds":0.0}}
var score_labels={}
var tag_score={}
var game_clock=0.0
var ball_previous={}
var basketball_score=[0,0]
var football_score=[0,0]
var game_results={}
var build_move_id=""
var build_kind=""
var build_angle=0.0
var build_point=Vector3.ZERO
var build_valid=false
var build_preview:Node3D
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
var board_history={}
var strokes=[]
var door_open=false
var door:Node3D
var board_view:SubViewport
var board_draw:Node2D
var board_body:StaticBody3D
var slide_mesh:MeshInstance3D
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
var transfer_frozen=false
var frozen=false
var last_remote_tick=-1

func _ready():
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset-manifest.json"))
	world_id="world-"+str(Time.get_unix_time_from_system())
	setup_environment()
	setup_board()
	setup_presentation()
	setup_game_targets()
	default_furniture()
	setup_hud()
	var preview_camera=Camera3D.new()
	add_child(preview_camera)
	preview_camera.position=Vector3(-6.3,1.7,10)
	preview_camera.look_at(Vector3(-11,1,6))
	preview_camera.current=true
	if OS.has_feature("web"):
		bridge=JavaScriptBridge.get_interface("Homeoffice")
		bridge.ready(FileAccess.get_file_as_string("res://assets/build-version.json"))
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
	var path="res://assets/v2/"+kind+".glb"
	if not ResourceLoader.exists(path):path="res://assets/environment/"+kind+".glb"
	return load(path).instantiate()

func setup_environment():
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v2/layout.json"))
	v2_manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v2/manifest.json"))
	for k in v2_manifest.assets:manifest.assets[k]=v2_manifest.assets[k]
	for kind in ["house","grounds"]:add_architecture(kind,Vector3.ZERO)
	var env=WorldEnvironment.new()
	var e=Environment.new()
	e.background_mode=Environment.BG_SKY
	var sky=Sky.new()
	var sky_mat=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("5f94b0")
	sky_mat.sky_horizon_color=Color("c8d9d5")
	sky_mat.ground_horizon_color=Color("c8d9d5")
	sky.sky_material=sky_mat
	e.sky=sky
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("e3e4d8")
	e.ambient_light_energy=.30
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.environment=e
	add_child(env)
	var sun=DirectionalLight3D.new()
	sunlight=sun
	sun.rotation_degrees=Vector3(-48,-35,0)
	sun.light_color=Color("fff0d3")
	sun.light_energy=.62
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=35
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	for r in layout.rooms:
		if not r.ceiling:continue
		var q=r.rect
		var lamp=OmniLight3D.new()
		lamp.position=Vector3((q[0]+q[2])/2,float(r.y)+2.9,(q[1]+q[3])/2)
		lamp.light_color=Color("ffe2b6")
		lamp.light_energy=.32
		lamp.omni_range=7
		lamp.distance_fade_enabled=true
		lamp.distance_fade_begin=15
		lamp.distance_fade_length=8
		lamp.set_meta("base_energy",.32)
		lamp.set_meta("zone",r.id)
		room_lights.append(lamp)
		add_child(lamp)
	for d in layout.doors:make_door(d)
	door=Node3D.new()
	add_child(door)
	# door is a compatibility placeholder for the previous V1 state field.
	make_label("모여집",Vector3(-1.8,2.8,12.14),0,.08)
	for r in layout.rooms:
		if r.ceiling:make_label(r.name,Vector3(float(r.rect[0])+.35,float(r.y)+2.55,float(r.rect[1])+.16),0,.032)

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
	mesh.position=vec(layout.board)
	add_child(mesh)
	board_body=StaticBody3D.new()
	board_body.position=mesh.position
	board_body.set_meta("object_id","board")
	board_body.collision_layer=1
	collision(board_body,Vector3.ZERO,Vector3(3.48,1.7,.045))
	add_child(board_body)

func default_furniture():
	for d in layout.furniture:spawn_object(d)

func spawn_object(d:Dictionary):
	if objects.has(d.id):return
	var kind=String(d.kind)
	var movable=kind in ["crate","book","marker","laser","basketball","football","gun","shield","plate","pan","ingredient","meal","chair","table","low_table","floor_lamp"]
	var body:PhysicsBody3D=RigidBody3D.new() if movable else StaticBody3D.new()
	body.name=d.id
	body.set_meta("object_id",d.id)
	body.set_meta("kind",kind)
	body.set_meta("owner","")
	body.set_meta("occupant","")
	body.set_meta("seats",{})
	body.set_meta("state",d.get("state",{}).duplicate(true))
	body.collision_layer=4 if movable else 1
	body.collision_mask=1|2|4
	body.position=vec(d.p)
	body.rotation.y=float(d.yaw)
	body.add_child(model(kind))
	setup_living_prop(body,kind)
	if movable:
		if kind in ["basketball","football","ingredient","meal"]:
			var c=CollisionShape3D.new()
			var shape=SphereShape3D.new()
			shape.radius=.24 if kind=="basketball" else (.22 if kind=="football" else .13)
			c.shape=shape
			body.add_child(c)
		else:
			var sizes={"crate":Vector3(.44,.44,.44),"book":Vector3(.24,.075,.32),"marker":Vector3(.03,.19,.03),"plate":Vector3(.4,.04,.4),"pan":Vector3(.5,.10,.42),"gun":Vector3(.12,.3,.45),"shield":Vector3(.7,.92,.16)}
			if kind=="chair":
				collision(body,Vector3(0,.26,0),Vector3(.53,.52,.53))
				collision(body,Vector3(0,.84,.24),Vector3(.54,.60,.08))
			elif kind=="laser":collision(body,Vector3.ZERO,Vector3(.03,.03,.19))
			elif sizes.has(kind):collision(body,Vector3.ZERO,sizes[kind])
			else:
				for c in manifest.assets[kind].collisions:add_shape(body,c)
		body.mass=float({"crate":2.4,"basketball":.62,"chair":6,"table":16,"low_table":8,"floor_lamp":4}.get(kind,.4))
		body.continuous_cd=true
		body.linear_damp=.08 if kind in ["basketball","football"] else .5
		body.angular_damp=.3 if kind in ["basketball","football"] else 2
		var physics=PhysicsMaterial.new()
		physics.friction=.65
		physics.bounce=.75 if kind=="basketball" else (.56 if kind=="football" else .08)
		body.physics_material_override=physics
		body.freeze=not host
	elif kind=="chair":
		collision(body,Vector3(0,.26,0),Vector3(.53,.52,.53))
		collision(body,Vector3(0,.84,.24),Vector3(.54,.60,.08))
	else:
		for c in manifest.assets[kind].collisions:add_shape(body,c)
	add_child(body)
	objects[d.id]=body
	definitions[d.id]=d.duplicate(true)
	if not definitions[d.id].has("state"):definitions[d.id].state={}

func add_player(id:String):
	if players.has(id) or players.size()>=8:return
	var a=Avatar.new()
	a.actor_id=id
	a.local_player=id==local_id
	a.position=vec(layout.spawn)+Vector3(.45,0,-players.size()*.85)
	a.remote_target=a.position
	add_child(a)
	players[id]=a
	inputs[id]=-1
	actions[id]=-1
	if a.local_player:a.camera.current=true
	if host:
		entry_grants[id]=id==local_id
		assign_room(id)

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

func base_input(event):
	if event is InputEventMouseMotion and playing() and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		yaw-=event.relative.x*(float(bridge.look_sensitivity()) if bridge else .002)
		pitch=clampf(pitch-event.relative.y*(float(bridge.look_sensitivity()) if bridge else .002),-1.35,1.35)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			if bridge:bridge.menu()
		if not playing():return
		if key_event(event,"interact"):request_action("interact")
		if key_event(event,"drop"):request_action("drop")
		if key_event(event,"read"):request_action("read")
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
		for code in blocked_keys.keys():
			if not Input.is_physical_key_pressed(code):blocked_keys.erase(code)
		if not enabled:
			for code in key_bindings.values():
				if Input.is_physical_key_pressed(code):blocked_keys[code]=true
		if enabled:
			yaw+=(float(key_down("look_left"))-float(key_down("look_right")))*dt*1.5
			pitch=clampf(pitch+(float(key_down("look_up"))-float(key_down("look_down")))*dt*1.2,-1.35,1.35)
		var cmd={"x":float(key_down("right"))-float(key_down("left")) if enabled else 0.0,"z":float(key_down("back"))-float(key_down("forward")) if enabled else 0.0,"yaw":yaw,"pitch":pitch,"jump":enabled and key_down("jump") and not last_jump_down,"run":enabled and key_down("run"),"crouch":enabled and key_down("crouch"),"seq":seq}
		last_jump_down=key_down("jump")
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
			var before=a.position
			if a.get_meta("ko",false):a.command.x=0;a.command.z=0;a.command.jump=false
			a.simulate(dt)
			if zone_at(a.position) in ["game","arcade"] and not allowed_entry(id):
				a.position=before;a.velocity=Vector3.ZERO
				if Time.get_ticks_msec()-int(a.get_meta("entry_notice",0))>2000:reject(id,"방장의 게임방 출입 허가가 필요합니다");a.set_meta("entry_notice",Time.get_ticks_msec())
		update_sports(dt)
		update_living(dt)
		update_held(dt)
		for obj in objects.values():
			if obj is RigidBody3D:
				if obj.linear_velocity.length_squared()>196:obj.linear_velocity=obj.linear_velocity.limit_length(14)
				if obj.angular_velocity.length_squared()>144:obj.angular_velocity=obj.angular_velocity.limit_length(12)
				if obj.position.y < -3:
					obj.position=vec(definitions[obj.name].p)
					obj.linear_velocity=Vector3.ZERO
	if not host:
		for id in players:
			if id==local_id:continue
			players[id].position=players[id].position.lerp(players[id].remote_target,1-exp(-dt*18))
			players[id].rotation.y=lerp_angle(players[id].rotation.y,players[id].remote_yaw,1-exp(-dt*18))
		for o in objects.values():
			if o is RigidBody3D and o.has_meta("remote_position") and o.get_meta("stored_in","")=="":
				var goal:Vector3=o.get_meta("remote_position")
				o.position=goal if o.position.distance_to(goal)>1.6 else o.position.lerp(goal,1-exp(-dt*20))
				o.quaternion=o.quaternion.slerp(Quaternion.from_euler(o.get_meta("remote_rotation")),1-exp(-dt*20))
		if Time.get_ticks_msec()-last_snapshot_ms>2500:
			frozen=true
			if bridge:bridge.status("호스트 응답 대기 · 마지막 확인 상태 보존 중")
	for a in players.values():a.animate(dt)
	update_doors(dt)
	state_timer+=dt
	snapshot_timer+=dt
	if state_timer>.067:
		state_timer=0
		var snapshot=network_state()
		if host:send(snapshot)
		if bridge:bridge.observe(JSON.stringify(snapshot))
	if bridge and tick%120==0:bridge.performance_sample(JSON.stringify({"fps":Engine.get_frames_per_second(),"frameMs":1000.0/maxf(1,Engine.get_frames_per_second()),"staticMemory":Performance.get_monitor(Performance.MEMORY_STATIC),"drawCalls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":objects.size(),"players":players.size()}))
	if snapshot_timer>2 and host:
		snapshot_timer=0
		send({"type":"world","epoch":epoch,"world":save_world(),"strokes":strokes})
	update_build_preview()
	update_object_visuals()
	update_living_props(dt)
	update_room_lighting(dt)
	update_hint()
	board_cooldown-=dt
	if p and playing() and p.holding!="" and definitions[p.holding].kind=="marker" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and board_cooldown<=0:
		board_cooldown=.07
		var hit=target(p)
		if hit.get("id","")=="board":
			var pt=objects[p.holding].global_transform*Vector3(0,-.10,0)
			if absf(pt.z-board_body.position.z)>.22:return
			var uv=[clampf((pt.x-(float(layout.board[0])-1.73))/3.46,0,1),clampf((float(layout.board[1])+.84-pt.y)/1.68,0,1)]
			if not last_board_point.is_empty():request_action("stroke",{"points":[last_board_point,uv],"color":String(bridge.pen_color()) if bridge else "#183b32","width":float(bridge.pen_width()) if bridge else 4,"physical":true})
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
	var zone=zone_at(p.position)
	hud.text="MOYEO HOUSE V2 / "+zone+"\n"+str(players.size())+" people · "+str(Engine.get_frames_per_second())+" FPS"
	var id=target(p).get("id","")
	var label=""
	if p.seated!="":label="E 일어서기"+ (" · Z 취침" if p.posture=="lying" else "")
	elif doors.has(id):label="E 문 열기 / 닫기"+(" · 방장 승인 필요" if id=="game-gate" and not door_states.get(id,false) else "")
	elif id=="presentation":label="E 발표 자료 · PDF / 이미지"
	elif id=="board":label="E 보드 확대 · 마카를 들고 클릭해 쓰기"
	elif objects.has(id):
		var kind=definitions[id].kind
		var labels={"chair":"E 앉기","sofa":"E 좌석에 앉기 · Z 눕기","bed":"E 눕기","table":"E 공동 보고서","fridge":"E 재료 꺼내기","cooker":"E 재료 조리 / 완성 음식 꺼내기","sink":"E 접시 정리","arcade":"E 아케이드 시작","counter":"E 음식 담기","storage":"E 열기 / 넣기 / 꺼내기 · R 뚜껑","drawer":"E 열기 / 넣기 / 꺼내기 · R 서랍","floor_lamp":"E 조명 켜기 / 끄기"}
		label=labels.get(kind,"E 집기")
	if p.seated!="" and p.holding!="" and definitions[p.holding].kind=="plate":label+=" · Z 먹기"
	if p.holding!="":
		label+=" · Q 내려놓기 · 클릭 던지기"
		var kind=definitions[p.holding].kind
		if kind=="book":label+=" · F 읽기"
		if kind=="basketball":label="클릭 충전 후 슛 · R 드리블 · Q 패스"
		if kind=="gun":label="클릭 발사 · R 재장전 · Q 내려놓기"
	if zone=="game":label+=" · 라운드 "+rounds.tag.phase+" "+str(int(rounds.tag.seconds))+"초"
	if zone=="basketball":label+="   농구 %d : %d"%[basketball_score[0],basketball_score[1]]
	if zone=="football":label+="   축구 %d : %d · F 길게 누른 뒤 슛 / 짧게 패스"%[football_score[0],football_score[1]]
	if build_kind!="":label=("클릭 설치" if build_valid else "설치 불가 · 충돌 또는 보호 구역")+" · R 회전 · B 취소"
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

func base_perform(id:String,m:Dictionary):
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
		if data.get("physical",false):
			if p.holding=="" or definitions[p.holding].kind!="marker":return
			var tip=objects[p.holding].global_transform*Vector3(0,-.10,0)
			if absf(tip.z-board_body.position.z)>.25:return
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
		var grip=p.eye()+p.direction()*.43+Vector3(0,-.38,0)
		if definitions[p.holding].kind in ["laser","marker"]:grip=p.eye()+p.direction()*.43+Vector3(0,-.22,0)+p.global_basis*Vector3(.15,0,0)
		var anchor_height=float({"chair":.55,"table":.78,"low_table":.42,"floor_lamp":.85}.get(definitions[p.holding].kind,0))
		grip-=o.basis*Vector3.UP*anchor_height
		if definitions[p.holding].kind=="basketball" and p.get_meta("dribble",false):
			# Jolt gravity and restitution produce the bounce. The hand only pushes downward at its reachable height.
			o.gravity_scale=1
			grip+=p.global_basis*Vector3(-.22 if p.get_meta("dribble_left",false) else .22,0,0)
			var offset=grip-o.position;offset.y=0
			if offset.length()>1.8 or zone_at(p.position)!="basketball":release(p,false);continue
			o.apply_central_force((offset*30-Vector3(o.linear_velocity.x,0,o.linear_velocity.z)*8).limit_length(20)*o.mass)
			if o.position.y-p.position.y>.78 and o.linear_velocity.y>0:o.apply_central_impulse(Vector3.DOWN*(o.linear_velocity.y+5.5)*o.mass)
			o.linear_velocity=o.linear_velocity.limit_length(8)
			o.sleeping=false
			continue
		var desired=Basis.from_euler(Vector3(float(p.command.pitch),float(p.command.yaw),0)).get_rotation_quaternion()
		if definitions[p.holding].kind=="marker":desired=Quaternion(Vector3.DOWN,p.direction())
		var turn=desired*o.quaternion.inverse()
		if turn.w<0:turn=-turn
		o.angular_velocity=(turn.get_axis()*turn.get_angle()*10).limit_length(9)
		var query=PhysicsRayQueryParameters3D.create(p.eye(),grip,1,[p.get_rid(),o.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():grip=hit.position-p.direction()*.28
		var delta=grip-o.position
		if delta.length()>3:release(p,false);continue
		# Bounded critically damped velocity, never teleport a held rigid body.
		o.linear_velocity=(delta*12).limit_length(7)
		o.sleeping=false

func release(p,throwing:bool):
	var o=objects.get(p.holding)
	if not o:return
	p.set_meta("dribble",false)
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
	for p in players.values():
		var state=p.state()
		state.zone=zone_at(p.position)
		ps.append(state)
	for id in objects:
		var o=objects[id]
		os.append({"id":id,"kind":definitions[id].kind,"p":arr(o.position),"r":arr(o.rotation),"owner":o.get_meta("owner"),"occupant":o.get_meta("occupant"),"state":o.get_meta("state"),"v":arr(o.linear_velocity) if o is RigidBody3D else [0,0,0],"av":arr(o.angular_velocity) if o is RigidBody3D else [0,0,0],"seats":o.get_meta("seats",{})})
	return {"type":"state","epoch":epoch,"tick":tick,"revision":revision,"players":ps,"objects":os,"door":door_open,"paused":frozen,"doors":door_states,"roomSlots":room_slots,"basketballScore":basketball_score,"footballScore":football_score,"entryGrants":entry_grants,"grants":weapon_grants,"weaponZones":weapon_zones,"rounds":rounds,"voiceOcclusion":acoustic_links()}

func save_world() -> Dictionary:
	var os=[]
	for id in definitions:
		var d=definitions[id].duplicate(true)
		var o=objects[id]
		d.p=arr(o.position)
		d.yaw=o.rotation.y
		d.state=o.get_meta("state",{}).duplicate(true)
		d.state.erase("reloadUntil")
		d.state.erase("nextShot")
		os.append(d)
	return {"schemaVersion":2,"worldId":world_id,"assetPack":2,"layoutVersion":2,"roomSlots":room_slots,"objects":os,"doors":door_states,"board":strokes,"revision":revision,"results":{"basketball":basketball_score,"football":football_score},"settings":{"maxPlayers":8}}

func handle_event(e:Dictionary):
	match e.get("type",""):
		"start":
			host=bool(e.host)
			local_id=e.id
			member_identity[local_id]=String(e.get("clientId",local_id))
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
				member_identity[e.id]=String(e.get("clientId",e.id))
				add_player(e.id)
				send({"type":"welcome","epoch":epoch,"world":save_world()},e.id)
		"leave":
			if players.has(e.id):
				var p=players[e.id]
				if host:
					if p.holding!="":release(p,false)
					if p.seated!="":clear_seat(p)
				p.queue_free()
				players.erase(e.id)
				member_slots.erase(e.id)
		"profile":
			if host:set_profile(String(e.id),String(e.get("name","친구")))
		"handoff_freeze":
			transfer_frozen=bool(e.paused)
			frozen=transfer_frozen
			for o in objects.values():
				if o is RigidBody3D:o.freeze=frozen or not host
		"handoff_capture":
			if host and bridge:bridge.handoff_capture(JSON.stringify(make_checkpoint()))
		"handoff_commit":apply_checkpoint(e)
		"slide_texture":set_slide(String(e.get("image","")))
		"slide_pointer":set_slide_pointer(e.get("uv"))
		"build":begin_build(String(e.get("kind","")))
		"bindings":
			for action in key_bindings:
				var code=OS.find_keycode_from_string(String(e.get("bindings",{}).get(action,"")))
				if code!=KEY_NONE and code!=KEY_ESCAPE:key_bindings[action]=code
		"resume":Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		"visibility":
			if host:
				frozen=transfer_frozen or bool(e.hidden)
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
			door_states=m.get("doors",{})
			if m.get("roomSlots",[])!=room_slots:
				var extended=m.roomSlots.size()>room_slots.size()
				room_slots=m.roomSlots
				if extended:rebuild_rooms()
				else:update_room_names()
			basketball_score=m.get("basketballScore",[0,0])
			football_score=m.get("footballScore",[0,0])
			entry_grants=m.get("entryGrants",{})
			weapon_grants=m.get("grants",{})
			weapon_zones=m.get("weaponZones",["game"])
			rounds=m.get("rounds",rounds)
			var live=[]
			for s in m.players:
				live.append(s.id)
				add_player(s.id)
				if not players.has(s.id):continue
				var p=players[s.id]
				p.nickname=String(s.get("displayName","친구"))
				p.command.pitch=s.pitch
				p.command.yaw=s.yaw if s.id!=local_id else yaw
				p.seated=s.seat
				p.seat_yaw=float(s.get("seatYaw",s.yaw))
				p.holding=s.hold
				p.posture=s.get("posture","standing")
				p.set_meta("activity",s.get("activity",""))
				p.remote_gesture=String(s.get("gesture",""))
				p.set_meta("dribble",s.get("dribble",false));p.set_meta("dribble_left",s.get("dribbleLeft",false))
				p.crouching=bool(s.get("crouch",false))
				p.seat_index=s.get("seatIndex",0)
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
			var live_objects=[]
			for value in m.objects:live_objects.append(value.id)
			for object_id in objects.keys():
				if not object_id in live_objects:objects[object_id].queue_free();objects.erase(object_id);definitions.erase(object_id)
			for s in m.objects:
				if not objects.has(s.id):spawn_object({"id":s.id,"kind":s.kind,"p":s.p,"yaw":s.r[1],"state":s.get("state",{})})
				if objects.has(s.id):
					if objects[s.id] is RigidBody3D:
						objects[s.id].set_meta("remote_position",vec(s.p));objects[s.id].set_meta("remote_rotation",vec(s.r))
					else:
						objects[s.id].position=vec(s.p);objects[s.id].rotation=vec(s.r)
					objects[s.id].set_meta("owner",s.owner)
					objects[s.id].set_meta("occupant",s.occupant)
					objects[s.id].set_meta("state",s.get("state",{}))
		"world":
			if bridge:bridge.recovery(JSON.stringify(m.world))
			strokes=m.strokes
			refresh_board()
		"board":
			var operation=m.get("operation",{})
			if operation.has("remove"):strokes=strokes.filter(func(stroke):return stroke.id!=operation.remove)
			if operation.has("add"):strokes.append(operation.add)
			refresh_board()
		"toy_effect":show_toy_effect(vec(m.from),vec(m.to))
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
	for o in objects.values():remove_child(o);o.queue_free()
	objects.clear()
	definitions.clear()
	room_slots=w.get("roomSlots",[]).duplicate(true)
	member_slots.clear()
	room_claims.clear()
	rebuild_rooms()
	for d in w.objects:spawn_object(d)
	board_history.clear()
	strokes=w.board.duplicate(true)
	door_states=w.get("doors",{}).duplicate(true)
	if door_states.has("game-gate"):door_states["game-gate"]=false
	entry_grants.clear()
	weapon_grants.clear()
	world_id=w.worldId
	revision=int(w.revision)
	basketball_score=w.get("results",{}).get("basketball",[0,0])
	football_score=w.get("results",{}).get("football",[0,0])
	for p in players.values():
		p.holding=""
		p.seated=""
		p.posture="standing"
		p.position=vec(layout.spawn)
		if host:assign_room(p.actor_id)
	refresh_board()


func key_down(action:String) -> bool:
	var code=int(key_bindings.get(action,KEY_NONE))
	return not blocked_keys.has(code) and Input.is_physical_key_pressed(code)

func key_event(event:InputEventKey,action:String) -> bool:
	return event.physical_keycode==int(key_bindings.get(action,KEY_NONE)) and not blocked_keys.has(event.physical_keycode)

func add_shape(parent:Node3D,c:Dictionary):
	var shape=CollisionShape3D.new()
	if c.has("points"):
		var convex=ConvexPolygonShape3D.new()
		var points=PackedVector3Array()
		for p in c.points:points.append(vec(p))
		convex.points=points
		shape.shape=convex
	else:
		var box=BoxShape3D.new()
		box.size=vec(c.size)
		shape.shape=box
		shape.position=vec(c.position)
		shape.rotation.y=float(c.get("yaw",0))
	parent.add_child(shape)


func add_architecture(kind:String,pos:Vector3) -> Node3D:
	var root=StaticBody3D.new()
	root.position=pos
	root.collision_layer=1
	root.add_child(model(kind))
	for c in manifest.assets[kind].collisions:add_shape(root,c)
	add_child(root)
	return root


func make_label(text:String,pos:Vector3,angle:float=0,size:float=.035) -> Label3D:
	var label=Label3D.new()
	label.text=text
	label.font=load("res://assets/fonts/NotoSansKR-game.ttf")
	label.font_size=48
	label.pixel_size=size/10
	label.position=pos
	label.rotation.y=angle
	label.modulate=Color("dae4ce")
	label.outline_modulate=Color("243c32")
	label.outline_size=5
	add_child(label)
	return label


func make_door(d:Dictionary):
	if doors.has(d.id):return
	var root=Node3D.new()
	root.position=vec(d.p)
	root.rotation.y=float(d.yaw)
	root.set_meta("definition",d)
	for side in range(2):
		var leaf=AnimatableBody3D.new()
		leaf.sync_to_physics=false
		leaf.position.x=0 if side==0 else float(d.width)
		leaf.rotation.y=0 if side==0 else PI
		leaf.set_meta("object_id",d.id)
		var visual=model("wide_door")
		visual.scale.x=float(d.width)/2/1.1
		leaf.add_child(visual)
		collision(leaf,Vector3(float(d.width)/4,1.23,0),Vector3(float(d.width)/2,2.46,.09))
		root.add_child(leaf)
	add_child(root)
	doors[d.id]=root
	if not door_states.has(d.id):door_states[d.id]=bool(d.get("open",false))


func update_doors(dt:float):
	for id in doors:
		var root=doors[id]
		for side in range(2):
			var target_angle=(-PI/2 if side==0 else PI*1.5) if door_states.get(id,false) else (0.0 if side==0 else PI)
			root.get_child(side).rotation.y=move_toward(root.get_child(side).rotation.y,target_angle,dt*2)


func zone_at(pos:Vector3) -> String:
	if pos.y>2.6 and pos.z < -12 and absf(pos.x)<6.3:
		if absf(pos.x)<1.4:return "personal-gallery"
		var pair=int(floor((-pos.z-12)/5.4))
		return "office-"+str(pair*2+(1 if pos.x<0 else 2))
	for r in layout.rooms:
		var q=r.rect
		if absf(pos.y-float(r.y))<1.5 and pos.x>=q[0] and pos.x<=q[2] and pos.z>=q[1] and pos.z<=q[3]:return r.id
	return "garden"


func assign_room(id:String):
	if member_slots.has(id):return
	var used=member_slots.values()
	var client_key=member_identity.get(id,id)
	var index=int(room_claims.get(client_key,-1))
	if index in used:index=-1
	for i in range(room_slots.size()):
		if index>=0:break
		if not i in used:index=i;break
	if index<0:
		if room_slots.size()>=8:return
		index=room_slots.size()
		room_slots.append({"personalRoomId":"office-"+str(index+1),"memberSlotId":"slot-"+str(index+1),"moduleIndex":int(index/2),"side":index%2,"label":"개인실 %02d"%(index+1)})
		add_room(index)
		update_room_end()
		revision+=1
	member_slots[id]=index
	room_claims[client_key]=index


func add_room(index:int,furnish:bool=true):
	var pair=int(index/2)
	var side=index%2
	var z=-12-pair*5.4
	if index%2==0:module_nodes.append(add_architecture("gallery",Vector3(0,3.6,z)))
	module_nodes.append(add_architecture("office_left" if side==0 else "office_right",Vector3(0,3.6,z)))
	var x=-3.8 if side==0 else 3.8
	var prefix="office-"+str(index+1)
	for d in [{"id":prefix+"-desk","kind":"table","p":[x,3.6,z-4],"yaw":0.0},{"id":prefix+"-chair","kind":"chair","p":[x,3.6,z-2.9],"yaw":0.0},{"id":prefix+"-book","kind":"book","p":[x,4.5,z-4],"yaw":0.0}]:
		if furnish and not objects.has(d.id):spawn_object(d)
	var door_id=prefix+"-door"
	make_door({"id":door_id,"p":[-1.4 if side==0 else 1.4,3.6,z-3.5],"yaw":-PI/2,"width":1.6,"open":true,"secure":false})
	var label=make_label("%02d"%(index+1),Vector3(-1.30 if side==0 else 1.30,5.8,z-2.7),PI/2 if side==0 else -PI/2,.04)
	label.set_meta("room_index",index)
	label.text=room_slots[index].label
	module_nodes.append(label)
	var lamp=OmniLight3D.new()
	lamp.position=Vector3(x,6.4,z-2.7)
	lamp.light_color=Color("ffe3b9")
	lamp.light_energy=.55
	lamp.omni_range=5.5
	lamp.distance_fade_enabled=true
	lamp.distance_fade_begin=12
	lamp.distance_fade_length=5
	add_child(lamp)
	lamp.set_meta("base_energy",.55)
	lamp.set_meta("zone",prefix)
	room_lights.append(lamp)
	module_nodes.append(lamp)


func update_room_end():
	if room_fill:
		remove_child(room_fill);room_fill.queue_free();room_fill=null
	if room_slots.size()%2==1:
		room_fill=StaticBody3D.new()
		room_fill.position=Vector3(1.4,3.6,-12-floorf(room_slots.size()/2.0)*5.4-2.7)
		collision(room_fill,Vector3(0,1.3,0),Vector3(.16,2.6,1.65))
		var panel=MeshInstance3D.new()
		var shape=BoxMesh.new()
		shape.size=Vector3(.16,2.6,1.65)
		panel.mesh=shape
		panel.position.y=1.3
		room_fill.add_child(panel)
		add_child(room_fill)
	if room_end:
		remove_child(room_end)
		room_end.queue_free()
	room_end=StaticBody3D.new()
	room_end.position=Vector3(0,3.6,-12-ceilf(room_slots.size()/2.0)*5.4)
	collision(room_end,Vector3(0,1.65,0),Vector3(2.8,3.3,.18))
	var mesh=MeshInstance3D.new()
	var box=BoxMesh.new()
	box.size=Vector3(2.8,3.3,.18)
	mesh.mesh=box
	mesh.position.y=1.65
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color("9eaa96")
	mesh.material_override=mat
	room_end.add_child(mesh)
	add_child(room_end)


func rebuild_rooms():
	for node in module_nodes:
		remove_child(node)
		node.queue_free()
	module_nodes.clear()
	for id in doors.keys():
		if id.begins_with("office-"):
			remove_child(doors[id])
			doors[id].queue_free()
			doors.erase(id)
	for i in range(room_slots.size()):add_room(i,false)
	update_room_end()


func _unhandled_input(event):
	if event is InputEventKey and not event.pressed:
		blocked_keys.erase(event.physical_keycode)
		if key_event(event,"jump"):last_jump_down=false
	if event is InputEventKey and key_event(event,"read") and not event.pressed and playing():
		if players.has(local_id) and players[local_id].holding=="":request_action("kick");return
	if build_kind!="":
		if event is InputEventKey and event.pressed and not event.echo:
			if key_event(event,"secondary"):build_angle+=PI/4;return
			if (event.keycode==KEY_ESCAPE or key_event(event,"build")):end_build()
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and playing():
			if build_valid:request_action("place",{"kind":build_kind,"p":arr(build_point),"yaw":build_angle,"objectId":build_move_id})
			return
	if event is InputEventKey and event.pressed and not event.echo and playing():
		if key_event(event,"move"):
			var object_id=target(players[local_id]).get("id","")
			if objects.has(object_id):begin_build(definitions[object_id].kind,object_id)
			return
		if key_event(event,"remove"):request_action("remove_object");return
		if key_event(event,"rest"):request_action("eat" if players.has(local_id) and players[local_id].seated!="" and players[local_id].holding!="" and definitions[players[local_id].holding].kind=="plate" else "rest");return
		if key_event(event,"secondary"):request_action("secondary");return
		if key_event(event,"build"):
			if bridge:bridge.open_tool("catalog")
			return
		if key_event(event,"read") and players.has(local_id) and players[local_id].holding=="":request_action("kick_start");return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and playing():
		var p=players.get(local_id)
		if p and p.holding!="" and definitions[p.holding].kind in ["basketball","gun"]:
			if event.pressed:request_action("trigger_down")
			else:request_action("trigger_up")
			return
	# Original movement, interaction and throw input remains the common path.
	base_input(event)


func clear_seat(p):
	if objects.has(p.seated):
		var o=objects[p.seated]
		var seats=o.get_meta("seats",{})
		seats.erase(str(p.seat_index))
		o.set_meta("seats",seats)
		if o.get_meta("lying","")==p.actor_id:o.set_meta("lying","")
		o.set_meta("occupant",seats.values()[0] if not seats.is_empty() else "")
	p.seated=""
	p.posture="standing"


func stand_up(p) -> bool:
	var o=objects.get(p.seated)
	if not o:return false
	var points=[Vector3(.9,0,.25),Vector3(-.9,0,.25)] if definitions[p.seated].kind=="bed" else [Vector3((p.seat_index-1)*.77 if definitions[p.seated].kind=="sofa" else 0,0,-1.15),Vector3(0,0,.95),Vector3(.9,0,0),Vector3(-.9,0,0)]
	for offset in points:
		var point=o.global_transform*offset
		if safe_stand(point,p):
			clear_seat(p)
			p.position=point
			return true
	return false


func allowed_weapon(id:String) -> bool:
	return allowed_entry(id) and weapon_grants.get(id,false) and players.has(id) and zone_at(players[id].position) in weapon_zones


func perform(id:String,m:Dictionary):
	if not host or frozen or not players.has(id) or m.get("epoch")!=epoch:return
	var order=int(m.get("seq",-1))
	if order<=int(actions.get(id,-1)):return
	var p=players[id]
	var action=m.get("action","")
	var data=m.get("data",{})
	if action in ["stroke","undo","board_update","board_delete"]:
		actions[id]=order
		if data is Dictionary:board_action(id,order,action,data)
		return
	if action=="drop" and p.holding!="" and definitions[p.holding].kind=="basketball":
		actions[id]=order
		var ball=objects[p.holding];release(p,false);ball.linear_velocity=p.direction()*6+Vector3.UP*1.1
		return
	if action in ["read","drop","throw"]:
		base_perform(id,m)
		return
	actions[id]=order
	if not data is Dictionary:return
	if action=="entry_grant":
		if id!=local_id or not players.has(String(data.get("peer",""))):return
		var who=String(data.peer)
		entry_grants[who]=bool(data.get("allow",false))
		if not entry_grants[who]:
			weapon_grants[who]=false
			var other=players[who]
			if other.holding!="" and definitions[other.holding].kind in ["gun","shield"]:release(other,false)
			if zone_at(other.position) in ["game","arcade"]:other.position=Vector3(18.7,0,0);other.velocity=Vector3.ZERO
		return
	if action=="round":
		if id!=local_id:return
		var game=String(data.get("game",""))
		if not rounds.has(game):return
		var op=String(data.get("op",""))
		if op=="prepare":rounds[game]={"phase":"rules","mode":String(data.get("mode","timed")),"seconds":0.0}
		if op=="start":
			rounds[game].phase="countdown"
			rounds[game].seconds=3.0
			if game=="basketball":basketball_score=[0,0]
			elif game=="football":football_score=[0,0]
			else:tag_score.clear()
		if op=="end":rounds[game].phase="results";rounds[game].seconds=0.0
		if op=="practice":rounds[game].phase="practice"
		return
	if action=="weapon_zone":
		if id!=local_id:return
		weapon_zones=["game","free"] if data.get("free",false) else ["game"]
		return
	if action=="grant":
		if id!=local_id:return
		var peer=String(data.get("peer",""))
		if not players.has(peer):return
		weapon_grants[peer]=bool(data.get("allow",false))
		if not weapon_grants[peer] and players[peer].holding!="" and definitions[players[peer].holding].kind in ["gun","shield"]:release(players[peer],false)
		return
	if action=="game_gate":
		if id==local_id:door_states["game-gate"]=bool(data.get("open",false));revision+=1
		return
	if action=="place":place_object(id,data);return
	if action=="remove_object":
		var object_id=target(p).get("id","")
		if not objects.has(object_id) or not definitions[object_id].kind in ["chair","table","sofa","bed","book","crate","marker","plate","gun","shield","storage","drawer","floor_lamp"]:return
		if object_in_use(object_id):return reject(id,"사용 중인 가구와 소품은 철거할 수 없습니다")
		var o=objects[object_id]
		remove_child(o);o.queue_free();objects.erase(object_id);definitions.erase(object_id);revision+=1
		return
	if action=="eat":
		if p.seated!="" and p.holding!="" and definitions[p.holding].kind=="plate":
			var plate=objects[p.holding]
			if plate.get_meta("state",{}).get("food",false):plate.set_meta("state",{"food":false,"dirty":true});revision+=1
		return
	if action=="rest":
		if p.posture=="lying":p.posture="sleeping";return
		if p.seated!="" and definitions[p.seated].kind=="sofa":
			var sofa=objects[p.seated]
			if sofa.get_meta("seats",{}).size()>1:return reject(id,"소파가 비어 있을 때 누울 수 있습니다")
			p.posture="lying";sofa.set_meta("lying",id);p.position=sofa.position;p.seat_yaw=sofa.rotation.y+PI/2
			return
		return
	if action=="trigger_down":
		if p.holding!="":
			p.set_meta("charge_started",Time.get_ticks_msec())
			if definitions[p.holding].kind=="basketball":p.set_meta("dribble",false);objects[p.holding].gravity_scale=0
			if definitions[p.holding].kind=="gun":fire_tag(id)
		return
	if action=="trigger_up":
		if p.holding!="" and definitions[p.holding].kind=="basketball":
			var ball=objects[p.holding]
			var strength=clampf((Time.get_ticks_msec()-int(p.get_meta("charge_started",Time.get_ticks_msec())))/1000.0,0,1.3)
			release(p,false)
			ball.linear_velocity=p.direction()*(5+strength*5)+Vector3.UP*2.4
		return
	if action=="secondary":
		var focused=target(p).get("id","")
		if definitions.has(focused) and definitions[focused].kind in ["storage","drawer"]:use_storage(p,focused,true);return
		if p.holding!="":
			var o=objects[p.holding]
			if definitions[p.holding].kind=="basketball":
				p.set_meta("dribble",not bool(p.get_meta("dribble",false)))
				o.gravity_scale=1 if p.get_meta("dribble",false) else 0
				if p.get_meta("dribble",false):o.linear_velocity.y=-5.5
			if definitions[p.holding].kind=="gun" and allowed_weapon(id):
				var st=o.get_meta("state",{})
				st.reloadUntil=Time.get_ticks_msec()+1400
				o.set_meta("state",st)
		return
	if action=="kick_start":
		p.set_meta("kick_started",Time.get_ticks_msec());return
	if action=="kick":
		var ball=objects.get("football")
		if ball and p.position.distance_to(ball.position)<1.5 and ball.get_meta("owner","")=="" and zone_at(p.position)=="football":
			var power=clampf((Time.get_ticks_msec()-int(p.get_meta("kick_started",Time.get_ticks_msec()-500)))/1000.0,0,1.2)
			ball.linear_velocity=(p.direction()+Vector3.UP*.18).normalized()*(5+power*10)
			p.remove_meta("kick_started")
		return
	if action!="interact":return
	if p.seated!="":
		if not stand_up(p):reject(id,"일어설 공간이 막혀 있습니다")
		return
	var hit=target(p)
	var target_id=hit.get("id","")
	if doors.has(target_id):
		if target_id=="game-gate" and id!=local_id:return reject(id,"게임방 출입은 방장 승인이 필요합니다")
		var d=doors[target_id].get_meta("definition")
		var centre=doors[target_id].global_transform*Vector3(float(d.width)/2,0,0)
		for a in players.values():
			if a.position.distance_to(centre)<1.25:return reject(id,"문에서 한 걸음 물러나 주세요")
		door_states[target_id]=not door_states.get(target_id,false)
		revision+=1
		return
	if target_id=="presentation":notify_ui(id,"presentation");return
	if target_id=="board":notify_ui(id,"board");return
	if not objects.has(target_id):return
	var o=objects[target_id]
	var kind=definitions[target_id].kind
	if kind in ["storage","drawer"]:use_storage(p,target_id);return
	if kind=="floor_lamp":
		var st=o.get_meta("state",{});st.on=not st.get("on",true);o.set_meta("state",st);revision+=1;return
	if kind in ["chair","sofa","bed"]:
		var seats=o.get_meta("seats",{})
		var seat_index=clampi(int(round((o.to_local(p.position).x+.77)/.77)),0,2) if kind=="sofa" else 0
		if o.get_meta("lying","")!="" or seats.has(str(seat_index)) or (kind=="bed" and o.get_meta("occupant","")!=""):return reject(id,"이미 다른 사람이 사용 중입니다")
		if p.holding!="" and not definitions[p.holding].kind in ["plate","meal","book"]:release(p,false)
		seats[str(seat_index)]=id
		o.set_meta("seats",seats)
		o.set_meta("occupant",id)
		p.seated=target_id
		p.seat_index=seat_index
		p.posture="lying" if kind=="bed" else "seated"
		p.seat_yaw=o.rotation.y
		p.position=o.global_transform*Vector3((seat_index-1)*.77 if kind=="sofa" else 0,0,0)
		p.rotation.y=o.rotation.y
		p.command.yaw=o.rotation.y
		if id==local_id:yaw=o.rotation.y
		return
	if kind in ["fridge","cooker","counter","sink"]:use_kitchen(p,target_id);return
	if kind=="arcade":notify_ui(id,"runner" if target_id=="arcade-runner" else "maze");return
	if kind in ["table","low_table"]:notify_ui(id,"report");return
	if kind in ["gun","shield"] and not allowed_weapon(id):return reject(id,"이 사용자와 현재 구역의 무기 허가가 필요합니다")
	if o is RigidBody3D:
		if o.get_meta("owner","")!="" or p.holding!="":return reject(id,"손이 차 있거나 이미 사용 중입니다")
		o.set_meta("owner",id)
		p.holding=target_id
		o.gravity_scale=0
		o.add_collision_exception_with(p)
		p.add_collision_exception_with(o)
		revision+=1


func use_kitchen(p,target_id:String):
	var o=objects[target_id]
	var kind=definitions[target_id].kind
	var st=o.get_meta("state",{})
	if kind=="fridge" and p.holding=="":
		var food_id="ingredient-"+str(revision)
		spawn_object({"id":food_id,"kind":"ingredient","p":arr(p.eye()+p.direction()*.8),"yaw":0.0,"state":{"recipe":"vegetable"}})
		var food=objects[food_id]
		food.set_meta("owner",p.actor_id)
		food.gravity_scale=0
		food.add_collision_exception_with(p)
		p.add_collision_exception_with(food)
		p.holding=food_id
	elif kind=="cooker":
		if p.holding!="" and definitions[p.holding].kind=="ingredient" and not st.has("cooking"):
			var food_id=p.holding
			release(p,false)
			objects[food_id].queue_free()
			objects.erase(food_id)
			definitions.erase(food_id)
			st.cooking=0.0
			st.ready=false
		elif st.get("ready",false) and p.holding=="":
			var food_id="meal-"+str(revision)
			spawn_object({"id":food_id,"kind":"meal","p":arr(o.position+Vector3(0,1.15,.2)),"yaw":0.0,"state":{"stage":"cooked"}})
			st.erase("cooking")
			st.erase("ready")
	elif kind=="counter" and p.holding!="" and definitions[p.holding].kind=="meal":
		for plate_id in objects:
			if definitions[plate_id].kind=="plate" and objects[plate_id].position.distance_to(o.position+Vector3.UP)<1.4:
				var plate=objects[plate_id]
				if plate.get_meta("state",{}).get("food",false):continue
				var food_id=p.holding
				release(p,false)
				objects[food_id].queue_free();objects.erase(food_id);definitions.erase(food_id)
				plate.set_meta("state",{"food":true,"dirty":false})
				break
	elif kind=="sink" and p.holding!="" and definitions[p.holding].kind=="plate":objects[p.holding].set_meta("state",{"food":false,"dirty":false})
	o.set_meta("state",st)
	revision+=1


func update_living(dt:float):
	for game in rounds:
		var round=rounds[game]
		if round.phase in ["countdown","play"]:
			round.seconds=maxf(0,float(round.seconds)-dt)
			if round.seconds<=0:
				if round.phase=="countdown":round.phase="play";round.seconds=120.0
				else:
					round.phase="results"
					if game=="tag":weapon_grants.clear()
	for id in objects:
		var o=objects[id]
		var st=o.get_meta("state",{})
		if definitions[id].kind=="cooker" and st.has("cooking") and not st.get("ready",false):
			st.cooking=float(st.cooking)+dt
			if st.cooking>=6:st.ready=true
			o.set_meta("state",st)
	for p in players.values():
		if p.holding!="" and definitions[p.holding].kind in ["gun","shield"] and not allowed_weapon(p.actor_id):release(p,false)


func update_sports(_dt:float):
	for id in ["basketball","football"]:
		var ball=objects.get(id)
		if not ball:return
		var previous=ball_previous.get(id,ball.position)
		var at=ball.position
		if id=="basketball":
			for i in range(2):
				var centre=Vector3(-16.35 if i==0 else 4.35,3.05,30)
				if rounds.basketball.phase in ["practice","play"] and previous.y>centre.y and at.y<=centre.y and ball.linear_velocity.y<0:
					var t=(centre.y-previous.y)/(at.y-previous.y)
					var cross=previous.lerp(at,t)
					if Vector2(cross.x-centre.x,cross.z-centre.z).length()<.20:
						basketball_score[i]+=2
						revision+=1
			if at.x < -21 or at.x>9 or at.z<20 or at.z>40:reset_ball(ball,Vector3(-7,.4,30))
		else:
			for i in range(2):
				var line=10 if i==0 else 40
				var crossed=previous.x>line and at.x<=line if i==0 else previous.x<line and at.x>=line
				if crossed and rounds.football.phase in ["practice","play"]:
					var t=(line-previous.x)/(at.x-previous.x)
					var cross=previous.lerp(at,t)
					if cross.z>29.22 and cross.z<34.78 and cross.y<2.18 and cross.y>.1:
						football_score[1-i]+=1
						revision+=1
						reset_ball(ball,Vector3(25,.4,32))
			if at.x<8 or at.x>42 or at.z<20 or at.z>44:reset_ball(ball,Vector3(25,.4,32))
		ball_previous[id]=ball.position


func reset_ball(ball:RigidBody3D,pos:Vector3):
	if ball.get_meta("owner","")!="":return
	ball.position=pos
	ball.linear_velocity=Vector3.ZERO
	ball.angular_velocity=Vector3.ZERO
	ball_previous[ball.name]=pos


func fire_tag(id:String):
	if not allowed_weapon(id) or not rounds.tag.phase in ["practice","play"]:return
	var p=players[id]
	var gun=objects[p.holding]
	var st=gun.get_meta("state",{})
	var now=Time.get_ticks_msec()
	if now<int(st.get("reloadUntil",0)) or now<int(st.get("nextShot",0)):return
	if st.has("reloadUntil"):st.ammo=12;st.erase("reloadUntil")
	if int(st.get("ammo",12))<=0:return reject(id,"R 키로 재장전하세요")
	st.ammo=int(st.get("ammo",12))-1
	st.nextShot=now+220
	gun.set_meta("state",st)
	var muzzle=gun.position+p.direction()*.27
	var block=PhysicsRayQueryParameters3D.create(p.eye(),muzzle,1,[p.get_rid(),gun.get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(block).is_empty():return
	var query=PhysicsRayQueryParameters3D.create(muzzle,muzzle+p.direction()*22,1|2,[p.get_rid(),gun.get_rid()])
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	emit_toy_effect(muzzle,hit.get("position",muzzle+p.direction()*22))
	if not hit.is_empty() and hit.collider.get_meta("object_id","").begins_with("target-"):
		tag_score[id]=int(tag_score.get(id,0))+1
		reject(id,"타깃 명중 · "+str(tag_score[id])+"점")
	if not hit.is_empty() and hit.collider in players.values():
		var other=hit.collider
		if not zone_at(other.position) in weapon_zones:return
		if other.holding!="" and definitions[other.holding].kind=="shield" and other.direction().dot((p.position-other.position).normalized())>.45:return
		tag_score[id]=int(tag_score.get(id,0))+1
		reject(other.actor_id,"태그! 비유혈 놀이 피격")
		reject(id,"명중 · "+str(tag_score[id])+"점")


func placement_size(kind:String) -> Vector3:
	var sizes={"chair":Vector3(.58,1.18,.58),"table":Vector3(2.8,.84,1.2),"sofa":Vector3(2.65,1.15,1.1),"bed":Vector3(1.2,1.3,2.15),"storage":Vector3(1.28,1.65,1.05),"drawer":Vector3(.96,.86,1.10),"floor_lamp":Vector3(.5,1.7,.5)}
	return sizes.get(kind,Vector3(.48,.48,.48))


func placement_ok(p,kind:String,point:Vector3,angle:float,move_id:String="") -> bool:
	if p.eye().distance_to(point)>4 or point.y < -.25 or point.y>7:return false
	if zone_at(point) in ["hall","upper_hall","personal-gallery","basketball","football","vestibule"]:return false
	for area in layout.protected:
		if area.has("p") and point.distance_to(vec(area.p))<float(area.radius):return false
	var floor_ray=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.15,point-Vector3.UP*.25,1)
	var ground=get_world_3d().direct_space_state.intersect_ray(floor_ray)
	if ground.is_empty() or ground.normal.y<.7:return false
	var excluded=[p.get_rid()]
	if objects.has(move_id):excluded.append(objects[move_id].get_rid())
	var ray=PhysicsRayQueryParameters3D.create(p.eye(),point+Vector3.UP*.3,1,excluded)
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():return false
	var q=PhysicsShapeQueryParameters3D.new()
	var shape=BoxShape3D.new()
	shape.size=placement_size(kind)
	q.shape=shape
	q.transform=Transform3D(Basis(Vector3.UP,angle),point+Vector3.UP*(shape.size.y/2+.02))
	q.collision_mask=1|2|4
	q.exclude=excluded
	return get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()


func place_object(id:String,data:Dictionary):
	var kind=String(data.get("kind",""))
	var move_id=String(data.get("objectId",""))
	if move_id!="" and (not objects.has(move_id) or definitions[move_id].kind!=kind or object_in_use(move_id)):return reject(id,"사용 중이거나 없는 가구는 옮길 수 없습니다")
	if not kind in ["chair","table","sofa","book","crate","marker","gun","shield","bed","plate","storage","drawer","floor_lamp"] or not data.get("p") is Array or data.p.size()!=3:return
	for n in data.p:
		if not (n is int or n is float) or not is_finite(float(n)) or absf(n)>110:return
	if not (data.get("yaw") is int or data.get("yaw") is float) or not is_finite(float(data.yaw)):return
	if objects.size()>=256:return reject(id,"가구 한도 256개입니다")
	var p=players[id]
	if move_id!="" and p.eye().distance_to(objects[move_id].position)>3.5:return
	if kind in ["gun","shield"] and not allowed_weapon(id):return
	var point=vec(data.p)
	var angle=snappedf(float(data.yaw),PI/4)
	if not placement_ok(p,kind,point,angle,move_id):return reject(id,"충돌, 거리 또는 보호 구역으로 설치할 수 없습니다")
	var object_id="placed-"+str(revision)+"-"+str(objects.size())
	if kind in ["book","crate","marker","gun","shield","plate"]:point.y+=.25
	if move_id!="":
		objects[move_id].position=point;objects[move_id].rotation.y=angle
		if objects[move_id] is RigidBody3D:objects[move_id].linear_velocity=Vector3.ZERO;objects[move_id].angular_velocity=Vector3.ZERO
		definitions[move_id].p=arr(point);definitions[move_id].yaw=angle
	else:spawn_object({"id":object_id,"kind":kind,"p":arr(point),"yaw":angle,"state":{}})
	revision+=1


func begin_build(kind:String,move_id:String=""):
	if not kind in ["chair","table","sofa","book","crate","marker","gun","shield","bed","plate","storage","drawer","floor_lamp"]:return
	end_build()
	build_kind=kind
	build_move_id=move_id
	build_angle=yaw
	build_preview=model(kind)
	add_child(build_preview)
	for node in build_preview.find_children("*","MeshInstance3D",true,false):
		var mat=StandardMaterial3D.new()
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color=Color(0.25,.9,.65,.48)
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		node.material_override=mat


func end_build():
	build_kind=""
	build_move_id=""
	if build_preview:build_preview.queue_free();build_preview=null


func update_build_preview():
	if build_kind=="" or not players.has(local_id):return
	var p=players[local_id]
	var projected=p.position+p.direction()*2.7
	projected.y=p.position.y
	projected.x=snappedf(projected.x,.25)
	projected.z=snappedf(projected.z,.25)
	build_point=projected
	build_valid=placement_ok(p,build_kind,build_point,build_angle,build_move_id)
	build_preview.position=build_point
	build_preview.rotation.y=build_angle
	for node in build_preview.find_children("*","MeshInstance3D",true,false):node.material_override.albedo_color=Color(.25,.9,.65,.48) if build_valid else Color(1,.25,.18,.48)


func update_object_visuals():
	for id in objects:
		var o=objects[id]
		var state=o.get_meta("state",{})
		if definitions[id].kind=="plate":
			var food=o.get_node_or_null("FoodVisual")
			if state.get("food",false) and not food:
				food=model("meal");food.name="FoodVisual";food.position.y=.1;o.add_child(food)
			if food and not state.get("food",false):food.queue_free()
		if definitions[id].kind=="cooker":
			var contents=o.get_node_or_null("CookingVisual")
			if state.has("cooking") and not contents:
				contents=model("meal");contents.name="CookingVisual";contents.position=Vector3(0,1.14,.15);o.add_child(contents)
			if contents:
				if state.has("cooking"):contents.scale=Vector3.ONE*(1.1 if state.get("ready",false) else .65+.1*sin(Time.get_ticks_msec()*.005))
				else:contents.queue_free()


func setup_presentation():
	slide_mesh=MeshInstance3D.new()
	var quad=QuadMesh.new()
	quad.size=Vector2(3.6,2.025)
	slide_mesh.mesh=quad
	slide_mesh.position=Vector3(9,1.85,4.14)
	var material=StandardMaterial3D.new()
	material.albedo_color=Color("e2e7d9")
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	slide_mesh.material_override=material
	add_child(slide_mesh)
	var body=StaticBody3D.new()
	body.position=slide_mesh.position
	body.set_meta("object_id","presentation")
	collision(body,Vector3.ZERO,Vector3(3.6,2.025,.045))
	add_child(body)


func set_slide(encoded:String):
	if encoded.length()>1500000:return
	var bytes=Marshalls.base64_to_raw(encoded)
	var img=Image.new()
	if img.load_jpg_from_buffer(bytes)!=OK or img.get_width()>2048 or img.get_height()>2048:return
	slide_mesh.material_override.albedo_texture=ImageTexture.create_from_image(img)


func emit_toy_effect(from:Vector3,to:Vector3):
	show_toy_effect(from,to)
	send({"type":"toy_effect","epoch":epoch,"from":arr(from),"to":arr(to)})


func show_toy_effect(from:Vector3,to:Vector3):
	var mesh=MeshInstance3D.new()
	var line=ImmediateMesh.new()
	var mat=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("ffb950")
	line.surface_begin(Mesh.PRIMITIVE_LINES,mat)
	line.surface_add_vertex(from)
	line.surface_add_vertex(to)
	line.surface_end()
	mesh.mesh=line
	add_child(mesh)
	get_tree().create_timer(.09).timeout.connect(mesh.queue_free)
	var audio=AudioStreamPlayer3D.new()
	audio.stream=load("res://assets/audio/toy-pop.wav")
	audio.position=from
	audio.volume_db=-15
	audio.max_distance=22
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


func setup_game_targets():
	for i in range(3):
		var body=StaticBody3D.new()
		body.position=Vector3(33.5,1.5,-4+i*2)
		body.set_meta("object_id","target-"+str(i))
		collision(body,Vector3.ZERO,Vector3(.10,1.05,1.05))
		var mesh=MeshInstance3D.new()
		var cylinder=CylinderMesh.new()
		cylinder.top_radius=.48
		cylinder.bottom_radius=.48
		cylinder.height=.05
		mesh.mesh=cylinder
		mesh.rotation.z=PI/2
		var mat=StandardMaterial3D.new()
		mat.albedo_color=Color("e99451")
		mesh.material_override=mat
		body.add_child(mesh)
		add_child(body)


func acoustic_links() -> Dictionary:
	var links={}
	var ids=players.keys()
	for i in range(ids.size()):
		for j in range(i+1,ids.size()):
			var a=players[ids[i]]
			var b=players[ids[j]]
			if a.position.distance_to(b.position)>26:continue
			var q=PhysicsRayQueryParameters3D.create(a.eye(),b.eye(),1,[a.get_rid(),b.get_rid()])
			var hit=get_world_3d().direct_space_state.intersect_ray(q)
			var gain=1.0
			if not hit.is_empty():gain=.22 if doors.has(hit.collider.get_meta("object_id","")) else .10
			if absf(a.position.y-b.position.y)>2.5:gain=minf(gain,.08)
			links[String(ids[i])+"|"+String(ids[j])]=gain
			links[String(ids[j])+"|"+String(ids[i])]=gain
	return links


func make_checkpoint() -> Dictionary:
	return {"world":save_world(),"state":network_state(),"memberSlots":member_slots,"memberIdentity":member_identity,"roomClaims":room_claims,"tagScore":tag_score}.duplicate(true)


func apply_checkpoint(e:Dictionary):
	var checkpoint=e.get("checkpoint",{})
	host=false
	if not checkpoint.is_empty():
		restore_world(checkpoint.world)
		var state=checkpoint.state
		for a in state.players:
			add_player(a.id)
			var player=players.get(a.id)
			if not player:continue
			player.position=vec(a.p)
			player.remote_target=vec(a.p)
			player.velocity=vec(a.v)
			player.rotation.y=float(a.yaw)
			player.remote_yaw=float(a.yaw)
			player.command.yaw=float(a.yaw)
			player.command.pitch=float(a.pitch)
			player.command.x=0.0;player.command.z=0.0;player.command.jump=false
			player.seated=a.seat;player.holding=a.hold
			player.seat_yaw=float(a.seatYaw)
			player.posture=a.posture;player.seat_index=int(a.seatIndex)
			player.last_input_ms=Time.get_ticks_msec()
			if a.id==local_id:yaw=float(a.yaw);pitch=float(a.pitch)
		for a in state.objects:
			var object=objects.get(a.id)
			if not object:continue
			object.position=vec(a.p);object.rotation=vec(a.r)
			object.set_meta("owner",a.owner);object.set_meta("occupant",a.occupant);object.set_meta("seats",a.get("seats",{}))
			var object_state=a.state.duplicate(true)
			object_state.erase("nextShot");object_state.erase("reloadUntil")
			object.set_meta("state",object_state)
			if object is RigidBody3D:object.linear_velocity=vec(a.v);object.angular_velocity=vec(a.av)
		for player in players.values():
			if player.holding!="" and objects.has(player.holding):
				var held=objects[player.holding]
				held.gravity_scale=0;held.add_collision_exception_with(player);player.add_collision_exception_with(held)
		member_slots=checkpoint.memberSlots.duplicate(true)
		member_identity=checkpoint.memberIdentity.duplicate(true)
		room_claims=checkpoint.roomClaims.duplicate(true)
		door_states=state.doors.duplicate(true)
		entry_grants=state.get("entryGrants",{}).duplicate(true)
		weapon_grants=state.grants.duplicate(true)
		weapon_zones=state.weaponZones.duplicate(true)
		rounds=state.rounds.duplicate(true)
		tag_score=checkpoint.tagScore.duplicate(true)
	host=bool(e.host)
	epoch=e.epoch
	inputs.clear();actions.clear();ball_previous.clear()
	last_remote_tick=-1
	last_snapshot_ms=Time.get_ticks_msec()
	transfer_frozen=false;frozen=false;ready_to_play=true
	for object in objects.values():
		if object is RigidBody3D:object.freeze=not host


func board_action(id:String,order:int,action:String,data:Dictionary):
	var player=players[id]
	if player.eye().distance_to(board_body.position)>4.2:return reject(id,"보드 가까이에서 사용할 수 있습니다")
	var ray=PhysicsRayQueryParameters3D.create(player.eye(),board_body.position,1,[player.get_rid()])
	var hit=get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.collider!=board_body:return
	var before={}
	var after={}
	var index=-1
	if action=="stroke":
		if not valid_stroke(data) or strokes.size()>=512:return
		if data.get("physical",false):
			if player.holding=="" or definitions[player.holding].kind!="marker":return
			if absf((objects[player.holding].global_transform*Vector3(0,-.10,0)).z-board_body.position.z)>.25:return
		after={"id":id+":"+str(order),"author":id,"points":data.points,"color":data.color,"width":data.width,"version":1}
		if data.get("kind","")=="text":
			if not data.get("text") is String or data.text.length()>160:return
			after.kind="text";after.text=data.text;after.fontSize=28
	elif action=="undo":
		if not board_history.has(id) or board_history[id].is_empty():return
		var entry=board_history[id].pop_back()
		var reference=entry.after if not entry.after.is_empty() else entry.before
		for i in range(strokes.size()):
			if strokes[i].id==reference.id:index=i;break
		if not entry.after.is_empty() and (index<0 or strokes[index].get("version",0)!=entry.after.get("version",0)):return reject(id,"다른 참가자가 수정한 항목은 Undo로 덮어쓰지 않습니다")
		if entry.after.is_empty() and index>=0:return
		before=entry.after;after=entry.before
	else:
		for i in range(strokes.size()):
			if strokes[i].id==data.get("id",""):index=i;break
		if index<0 or strokes[index].get("version",0)!=data.get("version",-1):return reject(id,"보드 항목이 변경되었습니다. 다시 선택해 주세요")
		before=strokes[index].duplicate(true)
		if action=="board_update":
			after=before.duplicate(true);after.points=data.get("points",[])
			if not valid_stroke(after):return
			after.version=int(before.get("version",0))+1
	if action!="undo":
		if not board_history.has(id):board_history[id]=[]
		board_history[id].append({"before":before,"after":after})
		if board_history[id].size()>80:board_history[id].pop_front()
	var operation={}
	if not before.is_empty():
		strokes=strokes.filter(func(s):return s.id!=before.id)
		operation.remove=before.id
	if not after.is_empty():strokes.append(after);operation.add=after
	refresh_board()
	send({"type":"board","epoch":epoch,"operation":operation})
	revision+=1


func object_in_use(object_id:String) -> bool:
	var object=objects.get(object_id)
	if not object:return true
	if not object.get_meta("state",{}).get("contents",[]).is_empty() or object.get_meta("state",{}).get("open",false):return true
	if object.get_meta("stored_in","")!="":return true
	if object.get_meta("owner","")!="" or not object.get_meta("seats",{}).is_empty():return true
	for player in players.values():
		if player.seated==object_id or player.holding==object_id:return true
	return false


func set_profile(id:String,value:String):
	if not players.has(id):return
	var clean=value.strip_edges().left(24).replace("\n"," ").replace("<","").replace(">","")
	if clean.is_empty():clean="친구"
	players[id].nickname=clean
	var index=int(member_slots.get(id,-1))
	if index>=0 and index<room_slots.size():room_slots[index].label=clean+"의 작업실";update_room_names();revision+=1


func update_room_names():
	for node in module_nodes:
		if node is Label3D and node.has_meta("room_index"):
			var index=int(node.get_meta("room_index"))
			if index<room_slots.size():node.text=room_slots[index].label


func allowed_entry(id:String) -> bool:
	return id==local_id or entry_grants.get(id,false)


func update_room_lighting(dt:float):
	if slide_laser and Time.get_ticks_msec()>slide_laser_until:slide_laser.visible=false
	var player=players.get(local_id)
	if not player:return
	room_lights=room_lights.filter(func(light):return is_instance_valid(light) and light.is_inside_tree())
	var eye=player.eye()
	room_lights.sort_custom(func(a,b):return a.global_position.distance_squared_to(eye)<b.global_position.distance_squared_to(eye))
	var low=bridge and String(bridge.graphics_quality())=="low"
	get_viewport().scaling_3d_scale=.65 if low else 1.0
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	if sunlight:sunlight.shadow_enabled=not low
	for i in range(room_lights.size()):
		var light=room_lights[i]
		var active=i<(2 if low else 4) and light.global_position.distance_to(eye)<16
		var furniture=String(light.get_meta("furniture",""))
		if objects.has(furniture):active=active and objects[furniture].get_meta("state",{}).get("on",true)
		light.light_energy=lerpf(light.light_energy,float(light.get_meta("base_energy",.32)) if active else 0.0,minf(1.0,dt*5))
		light.visible=light.light_energy>.005


func set_slide_pointer(uv):
	if uv==null:
		if slide_laser:slide_laser.visible=false
		return
	if not uv is Array or uv.size()!=2:return
	if not slide_laser:
		slide_laser=MeshInstance3D.new()
		var sphere=SphereMesh.new();sphere.radius=.025;sphere.height=.05
		var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(1,.05,.03)
		sphere.material=mat;slide_laser.mesh=sphere;add_child(slide_laser)
	slide_laser.position=Vector3(9+(float(uv[0])-.5)*3.6,1.85+(.5-float(uv[1]))*2.025,4.18)
	slide_laser.visible=true;slide_laser_until=Time.get_ticks_msec()+500


func setup_living_prop(body:PhysicsBody3D,kind:String):
	if kind in ["storage","drawer"]:
		var part=AnimatableBody3D.new()
		part.name="MovingPart";part.sync_to_physics=false;part.collision_layer=1;part.collision_mask=7
		part.set_meta("object_id",body.name)
		part.add_child(model("storage_lid" if kind=="storage" else "drawer_slide"))
		if kind=="storage":
			part.position=Vector3(0,.68,-.43)
			collision(part,Vector3(0,.025,.43),Vector3(1.28,.05,.94))
		else:
			part.position.y=.57
			collision(part,Vector3(0,-.02,0),Vector3(.85,.26,.6))
		body.add_child(part)
	if kind=="floor_lamp":
		var light=OmniLight3D.new();light.name="Bulb";light.position=Vector3(0,1.3,0)
		light.light_color=Color("ffe3b1");light.omni_range=4;light.light_energy=.45
		light.set_meta("base_energy",.45);light.set_meta("furniture",body.name)
		body.add_child(light);room_lights.append(light)
		var bulb=MeshInstance3D.new();bulb.name="BulbIndicator"
		var sphere=SphereMesh.new();sphere.radius=.055;sphere.height=.11;bulb.mesh=sphere;bulb.position=Vector3(0,1.24,0)
		var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color("ffe7b7");bulb.material_override=mat;body.add_child(bulb)


func use_storage(p,object_id:String,toggle=false):
	var o=objects[object_id];var kind=definitions[object_id].kind;var st=o.get_meta("state",{}).duplicate(true)
	var contents=st.get("contents",[])
	if toggle or not st.get("open",false) or (p.holding=="" and contents.is_empty()):
		# Refuse moving the lid/drawer through a body in its swept volume.
		for other in players.values():
			var at=o.to_local(other.position)
			if absf(at.x)<.95 and at.y<1.65 and at.y>-.3 and at.z>-.8 and at.z<1.1:return reject(p.actor_id,"가구에서 한 걸음 물러나 주세요")
		st.open=not st.get("open",false);o.set_meta("state",st);revision+=1;return
	if p.holding!="":
		var item_id=String(p.holding);var item_kind=definitions[item_id].kind
		var allowed=["book","marker","crate","plate","pan","ingredient","meal"] if kind=="storage" else ["book","marker","plate","ingredient","meal"]
		if not item_kind in allowed:return reject(p.actor_id,"이 물건은 여기에 수납할 수 없습니다")
		if contents.size()>=(4 if kind=="storage" else 2):return reject(p.actor_id,"수납 공간이 가득 찼습니다")
		release(p,false);contents.append(item_id)
	else:
		var item_id=String(contents.pop_back());var item=objects.get(item_id)
		if not item:return
		item.freeze=false;item.collision_layer=4;item.collision_mask=7;item.visible=true
		item.set_meta("stored_in","");item.set_meta("owner",p.actor_id);item.gravity_scale=0
		item.position=p.eye()+p.direction()*.72;item.linear_velocity=Vector3.ZERO
		item.add_collision_exception_with(p);p.add_collision_exception_with(item);p.holding=item_id
	st.contents=contents;o.set_meta("state",st);revision+=1


func update_living_props(dt:float):
	var stored={}
	for id in objects:
		var o=objects[id];var kind=definitions[id].kind;var st=o.get_meta("state",{})
		if kind in ["storage","drawer"]:
			var part=o.get_node("MovingPart");var opened=bool(st.get("open",false))
			if kind=="storage":part.rotation.x=move_toward(part.rotation.x,-1.75 if opened else 0.0,dt*2.8)
			else:part.position.z=move_toward(part.position.z,.42 if opened else 0.0,dt*.8)
			var items=st.get("contents",[])
			for i in range(items.size()):
				if not objects.has(items[i]):continue
				var offset=Vector3((i%2-.5)*.58,.37,(floori(i/2.0)-.5)*.43) if kind=="storage" else Vector3((i-.5)*.4,.54,part.position.z)
				stored[items[i]]={"id":id,"p":o.global_transform*offset,"open":opened,"yaw":o.rotation.y}
		if kind=="floor_lamp":o.get_node("BulbIndicator").visible=bool(st.get("on",true))
	for id in objects:
		var o=objects[id]
		if not o is RigidBody3D:continue
		if stored.has(id):
			var s=stored[id];o.set_meta("stored_in",s.id);o.freeze=true;o.visible=s.open;o.collision_layer=0;o.collision_mask=0
			o.position=s.p;o.rotation=Vector3(0,s.yaw,0);o.linear_velocity=Vector3.ZERO;o.angular_velocity=Vector3.ZERO
		elif o.get_meta("stored_in","")!="":
			o.set_meta("stored_in","");o.freeze=not host or frozen;o.visible=true;o.collision_layer=4;o.collision_mask=7
