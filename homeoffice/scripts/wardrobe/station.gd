extends Node3D
const Appearance=preload("res://scripts/wardrobe/appearance.gd")
var world
var spec={}
var sessions={}
var local_session=""
var previews:CanvasLayer
var preview_model:Node3D
var preview_camera:Camera3D
var preview_view:SubViewport
var reflection
var initialized={}
var pending_profiles={}
var joined_at={}
var station_ids=["wardrobe-console","wardrobe-mirror"]

func setup(owner_world):
	world=owner_world
	spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v5/wardrobe.json"))
	position=world.vec(spec.origin)
	var body=StaticBody3D.new();body.collision_layer=1
	body.add_child(load("res://assets/v5/wardrobe.glb").instantiate());add_child(body)
	for shape in spec.colliders:world.add_shape(body,shape)
	for entry in [["wardrobe-console",spec.console,Vector3(.16,.44,.52)],["wardrobe-mirror",spec.mirror,Vector3(.10,1.98,1.13)]]:
		var surface=StaticBody3D.new();surface.collision_layer=1;surface.set_meta("object_id",entry[0]);add_child(surface)
		surface.position=world.vec(entry[1])-position;world.collision(surface,Vector3.ZERO,entry[2])
	var title=Label3D.new();title.font=load("res://assets/fonts/NotoSansKR-game.ttf");title.text="의상방\n거울 / 콘솔을 클릭해 꾸미기";title.font_size=36;title.pixel_size=.004
	title.position=Vector3(4.84,2.3,4);title.rotation.y=-PI/2;add_child(title)
	var light=OmniLight3D.new();light.position=Vector3(2.4,2.7,3);light.omni_range=5;light.light_energy=.7;light.light_color=Color("fff4e7");add_child(light)
	reflection=preload("res://scripts/wardrobe/mirror.gd").new();add_child(reflection);reflection.setup(world,world.vec(spec.mirror))

func inside(p) -> bool:
	if not p:return false
	return p.position.x>spec.bounds[0]+.15 and p.position.x<spec.bounds[2] and p.position.z>spec.bounds[1]+.15 and p.position.z<spec.bounds[3]-.15 and absf(p.position.y-3.6)<.35

func can_open(p) -> bool:
	return inside(p) and p.seated=="" and p.holding=="" and not p.get_meta("ko",false) and world.target(p).get("id","") in station_ids

func action(actor:String,name:String,data:Dictionary) -> String:
	var p=world.players.get(actor)
	if name=="wardrobe_open":
		if not can_open(p):return "의상방 안에서 빈손으로 거울 또는 꾸미기 콘솔을 직접 클릭하세요."
		var session=world.epoch+":"+actor+":"+str(Time.get_ticks_usec())
		initialized[actor]=true
		sessions[actor]={"token":session,"epoch":world.epoch}
		deliver(actor,{"type":"wardrobe-open","epoch":world.epoch,"token":session,"profile":p.appearance_profile})
		return ""
	if not sessions.has(actor) or data.get("token","")!=sessions[actor].token or sessions[actor].epoch!=world.epoch:return "의상방 편집 세션이 만료되었습니다."
	if name=="wardrobe_cancel":
		sessions.erase(actor);deliver(actor,{"type":"wardrobe-close","epoch":world.epoch});return ""
	if not inside(p) or p.get_meta("ko",false):
		sessions.erase(actor);deliver(actor,{"type":"wardrobe-close","epoch":world.epoch});return "의상방을 벗어나 편집을 취소했습니다."
	if name=="wardrobe_apply":
		var clean=Appearance.validate(data.get("profile"))
		if clean.is_empty():return "얼굴 이미지 또는 외형 데이터 형식이 올바르지 않습니다."
		if clean.revision!=p.appearance_profile.revision:return "외형이 다른 편집에서 변경되었습니다. 다시 열어 주세요."
		clean.revision+=1;p.set_appearance(clean);sessions.erase(actor);world.revision+=1
		deliver(actor,{"type":"wardrobe-saved","epoch":world.epoch,"profile":clean})
		world.send({"type":"appearance-update","epoch":world.epoch,"actor":actor,"profile":clean})
	return ""

func deliver(actor:String,message:Dictionary):
	if actor==world.local_id:receive(message)
	else:world.send(message,actor)

func receive(message:Dictionary):
	if message.get("epoch")!=world.epoch:return
	match message.type:
		"wardrobe-open":
			# A tool message alone cannot open this UI outside the physical room.
			if not inside(world.players.get(world.local_id)):return
			local_session=message.token;open_preview(message.profile)
			if world.bridge:world.bridge.wardrobe_open(JSON.stringify(message))
		"wardrobe-close","wardrobe-saved":
			close_preview()
			if message.type=="wardrobe-saved" and world.players.has(world.local_id):world.players[world.local_id].set_appearance(message.profile)
			if world.bridge:world.bridge.wardrobe_result(JSON.stringify(message))

func event(e:Dictionary):
	if local_session=="" or e.get("token","")!=local_session:return
	if not inside(world.players.get(world.local_id)):cancel();return
	match e.get("op",""):
		"preview":
			var clean=Appearance.validate(e.get("profile"))
			if not clean.is_empty() and preview_model:Appearance.apply(preview_model,clean)
		"view":
			if preview_model:preview_model.rotation.y=clampf(float(e.get("angle",0)),-PI,PI)
			if preview_camera:
				var close=bool(e.get("face",false));preview_camera.position=Vector3(0,1.55,1.0) if close else Vector3(0,1.1,3.2);preview_camera.look_at(Vector3(0,1.55 if close else .85,0))
		"apply":world.request_action("wardrobe_apply",{"token":local_session,"profile":e.get("profile",{})})
		"cancel":cancel()

func cancel():
	if local_session!="":world.request_action("wardrobe_cancel",{"token":local_session})
	close_preview()

func close_preview():
	local_session=""
	if is_instance_valid(previews):previews.queue_free()
	previews=null;preview_model=null;preview_camera=null;preview_view=null

func open_preview(profile:Dictionary):
	if is_instance_valid(previews):previews.queue_free()
	previews=CanvasLayer.new();previews.layer=20;world.add_child(previews)
	var container=SubViewportContainer.new();container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);container.anchor_right=.58;container.offset_top=55;container.offset_bottom=-35;container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;previews.add_child(container)
	preview_view=SubViewport.new();preview_view.own_world_3d=true;preview_view.size=Vector2i(760,820);preview_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(preview_view)
	var environment=WorldEnvironment.new();var settings=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("dce3df");settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.65;environment.environment=settings;preview_view.add_child(environment)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-30,-35,0);sun.light_energy=1.2;preview_view.add_child(sun)
	preview_model=load("res://assets/characters/male-animated-v5.glb").instantiate();preview_model.rotation.y=0;preview_view.add_child(preview_model)
	for animation in preview_model.find_children("*","AnimationPlayer",true,false):
		for clip in animation.get_animation_list():
			if String(clip).ends_with("v3_idle"):animation.play(clip);animation.seek(0,true);animation.pause();break
	Appearance.apply(preview_model,profile)
	preview_camera=Camera3D.new();preview_view.add_child(preview_camera);preview_camera.position=Vector3(0,1.1,3.2);preview_camera.look_at(Vector3(0,.85,0));preview_camera.fov=40;preview_camera.current=true

func maintain():
	if world.host:
		for actor in sessions.keys():
			if not inside(world.players.get(actor)) or world.players[actor].get_meta("ko",false) or sessions[actor].epoch!=world.epoch:
				sessions.erase(actor);deliver(actor,{"type":"wardrobe-close","epoch":world.epoch})
	if local_session!="" and not inside(world.players.get(world.local_id)):
		close_preview()
		if world.bridge:world.bridge.wardrobe_result(JSON.stringify({"type":"wardrobe-close"}))


func reset_session():
	close_preview();sessions.clear();initialized.clear();pending_profiles.clear();joined_at.clear()
	joined_at[world.local_id]=Time.get_ticks_msec()

func initialize_profile(actor:String,value):
	# Reconnect bootstrap is limited to that transport actor's initial session.
	if not world.players.has(actor) or initialized.has(actor) or Time.get_ticks_msec()-int(joined_at.get(actor,0))>15000:return
	initialized[actor]=true
	var clean=Appearance.validate(value)
	if clean.is_empty():return
	world.players[actor].set_appearance(clean)
	world.send({"type":"appearance-update","epoch":world.epoch,"actor":actor,"profile":clean})

func update_profile(actor:String,value):
	var clean=Appearance.validate(value)
	if clean.is_empty() or actor.length()>100:return
	if not world.players.has(actor):pending_profiles[actor]=clean;return
	world.players[actor].set_appearance(clean)

func apply_pending():
	for actor in pending_profiles.keys():
		if world.players.has(actor):world.players[actor].set_appearance(pending_profiles[actor]);pending_profiles.erase(actor)

func sync(actor:String):
	joined_at[actor]=Time.get_ticks_msec()
	for p in world.players.values():
		world.send({"type":"appearance-update","epoch":world.epoch,"actor":p.actor_id,"profile":p.appearance_profile},actor)


func restore_conflicts(saved:Dictionary) -> Array:
	# Reject before mutation, rather than burying an old custom object in a new wall.
	# A complete relocation migration is a separate, still pending architecture task.
	var conflicts=[]
	for item in saved.get("objects",[]):
		var at=world.vec(item.p)
		if at.y<3.2 or at.y>6.9 or at.x< -12 or at.x> -3 or at.z< -6 or at.z>5:continue
		var dimensions=world.vec(world.manifest.assets.get(item.kind,{}).get("dimensions",[.3,.3,.3]))
		var angle=float(item.get("yaw",0));var extent=Vector3(absf(cos(angle))*dimensions.x+absf(sin(angle))*dimensions.z,dimensions.y,absf(sin(angle))*dimensions.x+absf(cos(angle))*dimensions.z)
		var object_box=AABB(at+Vector3(-extent.x/2,.015,-extent.z/2),extent-Vector3(0,.03,0)).grow(-.015)
		for shape in spec.colliders:
			var size=world.vec(shape.size);var shape_box=AABB(position+world.vec(shape.position)-size/2,size).grow(-.01)
			if object_box.intersects(shape_box):conflicts.append(String(item.id));break
	return conflicts
