extends "res://scripts/v2/world.gd"
## V3 integration. V2 .gd is the retained implementation, never regenerated.
const Combat=preload("res://scripts/combat/combat_state.gd")
const BallProfile=preload("res://scripts/sports/ball_profile.gd")
const Capabilities=preload("res://scripts/interaction/prop_capabilities.gd")
var wardrobe=preload("res://scripts/wardrobe/station.gd").new()
var toy_effects
var combat=Combat.new()
var sports=preload("res://scripts/sports/match_rules.gd").new()
const Surface=preload("res://scripts/physics/surface_profile.gd")
var combat_view={}
var shot_serial=0
var local_charge_ms=0
var avatar_state_count=0
var classroom=false
var laser_clock=0.0
var placement_clearance=preload("res://scripts/interaction/placement_clearance.gd").new()
var placement_pointer=preload("res://scripts/interaction/placement_pointer.gd").new()
var furniture_support=preload("res://scripts/interaction/furniture_support.gd").new()
var facilities:Node3D
var facilities_cache={}
var last_extra_tick=-1
var command_ledger=preload("res://scripts/core/command_ledger.gd").new()
var active_request={}
var command_results={"accepted":0,"rejected":0,"duplicates":0}

func _ready():
	toy_effects=load("res://scripts/combat/toy_effects.gd").new();add_child(toy_effects)
	facilities=load("res://scripts/world/campus_details.gd").new();add_child(facilities)
	super._ready()
	add_child(wardrobe);wardrobe.setup(self)
	add_child(load("res://scripts/world/meeting_finish.gd").new())
	add_child(load("res://scripts/sports/hoop_feedback.gd").new())
	rounds.tag={"phase":"practice","mode":"practice","seconds":0.0}
	spawn_object({"id":"meeting-laser","kind":"laser","p":[8.6,1.0,8.2],"yaw":0.0,"state":{}})

func model(kind:String) -> Node3D:
	return load("res://assets/v2/laser-v3.glb").instantiate() if kind=="laser" else super.model(kind)

func spawn_object(d:Dictionary):
	if objects.has(d.id):return
	# The retained spawner handles carrying furniture with its original colliders.
	super.spawn_object(d)
	var body=objects.get(d.id)
	if d.id in ["meeting-table-0","meeting-table-1"] and body:body.get_child(0).visible=false
	if String(d.id).begins_with("meeting-chair-") and body:
		var old_visual=body.get_child(0);body.remove_child(old_visual);old_visual.queue_free()
		var visual=load("res://assets/v4/meeting-chair.glb").instantiate();body.add_child(visual);body.move_child(visual,0)
	if body is RigidBody3D and d.kind in ["basketball","football"]:
		body.get_child(0).scale=Vector3.ONE*.5
		for child in body.get_children():
			if child is CollisionShape3D and child.shape is SphereShape3D:child.shape.radius=BallProfile.radius(d.kind)
		BallProfile.configure(body,d.kind)
		sports.register_ball(d.id,d.kind)

func add_player(id:String):
	super.add_player(id)
	if players.has(id):combat.add(id)

func base_input(event):
	if event is InputEventMouseMotion and playing() and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		yaw-=event.relative.x*(float(bridge.look_sensitivity()) if bridge else .002)
		pitch=clampf(pitch-event.relative.y*(float(bridge.look_sensitivity()) if bridge else .002)*(-1.0 if bridge and bool(bridge.look_inverted()) else 1.0),-1.35,1.35)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			if bridge:bridge.menu()
		if not playing():return
		if key_event(event,"interact"):request_action("carry")
		if key_event(event,"drop"):request_action("throw")
		if key_event(event,"read"):request_action("use")

func _unhandled_input(event):
	if event is InputEventKey and not event.pressed:
		blocked_keys.erase(event.physical_keycode)
		if key_event(event,"jump"):last_jump_down=false
	if not playing():
		base_input(event)
		return
	var local_avatar=players.get(local_id)
	if local_avatar and event is InputEventKey and event.pressed and not event.echo and key_event(event,"camera"):
		local_avatar.camera_rig.toggle();return
	if local_avatar and event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			local_avatar.camera_rig.zoom(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1);return
		if event.button_index==MOUSE_BUTTON_RIGHT and definitions.get(local_avatar.holding,{}).get("kind")=="gun":
			local_avatar.camera_rig.aiming=event.pressed;return
	if build_kind!="":
		if event is InputEventKey and event.pressed and not event.echo:
			if key_event(event,"secondary"):build_angle+=PI/4;return
			if event.keycode==KEY_ESCAPE or key_event(event,"build"):end_build();return
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			if build_valid:request_action("place",{"kind":build_kind,"p":arr(build_point),"yaw":build_angle,"objectId":build_move_id})
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if key_event(event,"build"):
			if bridge:bridge.open_tool("catalog")
			return
		if key_event(event,"move"):
			var focused=target(players[local_id]).get("id","")
			if definitions.has(focused):begin_build(definitions[focused].kind,focused)
			return
		if key_event(event,"remove"):request_action("remove_object");return
		if key_event(event,"secondary"):request_action("secondary");return
		if key_event(event,"rest"):request_action("eat" if players[local_id].holding!="" and definitions[players[local_id].holding].kind=="plate" else "rest");return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		request_action("crossover");return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		var pointed=players.get(local_id)
		if event.pressed and pointed and wardrobe.can_open(pointed):request_action("wardrobe_open");return
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		var p=players.get(local_id)
		if not p:return
		if p.holding!="" and definitions[p.holding].kind in ["basketball","gun","laser"]:
			local_charge_ms=Time.get_ticks_msec() if event.pressed and definitions[p.holding].kind=="basketball" else 0
			request_action("trigger_down" if event.pressed else "trigger_up")
		elif p.holding=="" and zone_at(p.position)=="football":request_action("kick_start" if event.pressed else "kick")
		return
	base_input(event)

func execute_action(id:String,m:Dictionary):
	if not host or frozen or not players.has(id) or m.get("epoch")!=epoch:return
	var order=int(m.get("seq",-1))
	if order<=int(actions.get(id,-1)):return
	var p=players[id]
	var action=String(m.get("action",""))
	if not combat.alive(id) and action not in ["trigger_up","input_cancel"]:actions[id]=order;return reject(id,"KO 상태입니다. 곧 안전한 위치에서 복귀합니다.")
	if action=="input_cancel":
		actions[id]=order;p.set_meta("trigger_held",false);p.remove_meta("charge_started");p.remove_meta("kick_started");return
	if action.begins_with("wardrobe_"):
		actions[id]=order
		var reason=wardrobe.action(id,action,m.get("data",{}))
		if reason!="":return reject(id,reason)
		return
	var sport_action=action in ["kick_start","kick","crossover"] or (action=="round" and m.get("data",{}).get("game","") in ["basketball","football"])
	var request_target_id=String(m.get("targetId",""))
	var target_kind=String(definitions.get(request_target_id,{}).get("kind",""))
	var held_kind=String(definitions.get(p.holding,{}).get("kind",""))
	if target_kind in ["basketball","football"] or held_kind in ["basketball","football"]:sport_action=true
	if action in ["carry","use","throw","secondary"] and room_access.restricted_zone(self,p.position)!="":sport_action=true
	if sport_action and not room_access.is_administrator(id):
		actions[id]=order;return reject(id,"농구·축구 활동은 검증된 운영 관리자만 사용할 수 있습니다.")
	if action=="activity":
		actions[id]=order
		var mode=String(m.get("data",{}).get("mode",""))
		if not mode in ["","book","documents","report","brainstorm","mindmap","meeting","presentation","broadcast","board","catalog","runner","maze"]:return reject(id,"지원하지 않는 활동입니다.")
		p.set_meta("activity",mode);return
	if action=="secondary" and p.seated!="":
		if definitions.get(p.holding,{}).get("kind","")=="book":actions[id]=order;notify_ui(id,"book");return
		if p.holding=="" and zone_at(p.position)=="meeting":actions[id]=order;notify_ui(id,"documents");return
	if action=="crossover":
		actions[id]=order
		if p.holding!="" and definitions[p.holding].kind=="basketball" and p.get_meta("dribble",false):p.set_meta("dribble_left",not p.get_meta("dribble_left",false));p.set_meta("gesture","crossover");p.set_meta("gesture_until",Time.get_ticks_msec()+650)
		return
	if action=="carry":
		actions[id]=order
		if p.seated!="":return reject(id,"F로 먼저 일어서세요.")
		if p.holding!="":release(p,false);return
		var focused=target(p).get("id","")
		if not definitions.has(focused):return reject(id,"집을 수 있는 사물을 가까이서 바라보세요. 고정 시설은 F로 사용합니다.")
		var kind=definitions[focused].kind
		if not Capabilities.can_carry(kind) and kind!="laser":return reject(id,"고정 시설입니다. F로 사용하세요.")
		if kind=="football" and zone_at(p.position)=="football":return reject(id,"축구장에서는 발로 제어합니다. 클릭 슛 · Q 패스 · F 가로채기")
		var o=objects[focused]
		if focused in ["meeting-table-0","meeting-table-1"]:return reject(id,"컴퓨터가 설치된 회의 책상은 고정되어 있습니다. 다른 책상은 집을 수 있습니다.")
		if not o is RigidBody3D or object_in_use(focused):return reject(id,"다른 사람이 사용 중이거나 내용물이 있는 사물입니다.")
		o.set_meta("owner",id);p.holding=focused;o.gravity_scale=0
		if kind not in furniture_carry.KINDS:o.add_collision_exception_with(p);p.add_collision_exception_with(o)
		p.set_meta("gesture","pickup");p.set_meta("gesture_until",Time.get_ticks_msec()+650)
		if kind in ["basketball","football"]:sports.transition(focused,"HELD",id);o.set_meta("scored",false)
		revision+=1;return
	if action=="use":
		# Standing or waking takes priority over the object beyond the occupied seat.
		if p.seated!="":
			var stand=m.duplicate(true);stand.action="interact";super.perform(id,stand);return
		if p.holding!="" and definitions[p.holding].kind=="book" and definitions.get(target(p).get("id",""),{}).get("kind","") not in ["storage","drawer"]:actions[id]=order;notify_ui(id,"book");return
		if p.holding=="" and zone_at(p.position) in ["basketball","football"]:actions[id]=order;steal_ball(p);return
		var target_id=target(p).get("id","")
		if facilities.fixtures.has(target_id):
			actions[id]=order
			if target_id=="broadcast_console":notify_ui(id,"broadcast")
			elif target_id=="meeting_computer":notify_ui(id,"documents")
			elif facilities.toggle(target_id):revision+=1;p.set_meta("gesture","switch");p.set_meta("gesture_until",Time.get_ticks_msec()+700)
			return
		if definitions.has(target_id) and definitions[target_id].kind in ["table","low_table"]:actions[id]=order;notify_ui(id,"documents");return
		if definitions.has(target_id) and definitions[target_id].kind=="arcade":actions[id]=order;notify_ui(id,"runner");return
		var use=m.duplicate(true);use.action="interact";super.perform(id,use)
		var gesture="door_use" if doors.has(target_id) else {"sink":"clean","cooker":"cook","counter":"plate","storage":"drawer_use","drawer":"drawer_use"}.get(definitions.get(target_id,{}).get("kind",""),"")
		if gesture!="":p.set_meta("gesture",gesture);p.set_meta("gesture_until",Time.get_ticks_msec()+900)
		return
	if action=="throw":
		if p.holding=="" and zone_at(p.position)=="football":actions[id]=order;kick_ball(p,.2);return
		if p.holding!="" and definitions[p.holding].kind=="basketball":
			actions[id]=order;var ball=objects[p.holding];release(p,false);sports.transition(String(ball.name),"RELEASED",id);ball.linear_velocity=p.direction()*6.5+Vector3.UP*.5;p.set_meta("gesture","pass");p.set_meta("gesture_until",Time.get_ticks_msec()+500);return
	if action=="trigger_down":
		actions[id]=order
		if p.holding=="":return
		p.set_meta("trigger_held",true);p.set_meta("charge_started",Time.get_ticks_msec())
		if definitions[p.holding].kind=="basketball":p.set_meta("dribble",false);objects[p.holding].gravity_scale=0;sports.transition(p.holding,"SHOT_CHARGING",id)
		if definitions[p.holding].kind=="gun":fire_tag(id)
		return
	if action=="trigger_up":
		actions[id]=order;p.set_meta("trigger_held",false)
		if p.holding!="" and definitions[p.holding].kind=="basketball" and p.has_meta("charge_started"):
			var charge=clampf((Time.get_ticks_msec()-int(p.get_meta("charge_started")))/1300.0,0,1)
			var ball=objects[p.holding];release(p,false)
			ball.linear_velocity=BallProfile.shot(p.direction(),charge)
			ball.angular_velocity=Vector3(p.direction().z,0,-p.direction().x).normalized()*-8
			sports.transition(String(ball.name),"RELEASED",id)
			ball.set_meta("shot",str(id)+":"+str(order));ball.set_meta("scored",false)
			p.set_meta("gesture","shot");p.set_meta("gesture_until",Time.get_ticks_msec()+850)
			feedback(id,"슛 릴리스 · 힘 %d%% · 백스핀"%int(charge*100))
		p.remove_meta("charge_started");return
	if action=="kick_start":actions[id]=order;p.set_meta("kick_started",Time.get_ticks_msec());return
	if action=="kick":
		actions[id]=order
		if p.has_meta("kick_started"):kick_ball(p,clampf((Time.get_ticks_msec()-int(p.get_meta("kick_started")))/1200.0,0,1));p.remove_meta("kick_started")
		return
	super.perform(id,m)
	if action=="stroke":p.set_meta("gesture","marker_write");p.set_meta("gesture_until",Time.get_ticks_msec()+300)
	if action=="secondary" and p.holding!="" and definitions[p.holding].kind=="basketball":sports.transition(p.holding,"DRIBBLING" if p.get_meta("dribble",false) else "GATHER",id)
	if action=="secondary" and p.holding!="" and definitions[p.holding].kind=="gun":p.set_meta("gesture","reload");p.set_meta("gesture_until",Time.get_ticks_msec()+1400)
	if action=="round" and id==local_id and m.get("data",{}).get("op")=="start":
		var game=String(m.data.get("game","basketball"));var ids=[]
		for person in players.values():
			if zone_at(person.position)==("game" if game=="tag" else game):ids.append(person.actor_id)
		sports.assign(game,ids)
		if game=="tag":combat.reset()

func release(p,throwing:bool):
	var held=objects.get(p.holding)
	var kind=definitions.get(p.holding,{}).get("kind","")
	p.set_meta("trigger_held",false)
	p.remove_meta("charge_started")
	if kind in ["basketball","football"]:sports.transition(p.holding,"RELEASED" if throwing else "LOOSE_BALL",p.actor_id)
	super.release(p,throwing)
	if held and throwing:held.linear_velocity=p.direction()*Capabilities.throw_speed(kind)+Vector3.UP*1.2
	p.set_meta("gesture","throw" if throwing else "drop");p.set_meta("gesture_until",Time.get_ticks_msec()+500)

func fire_tag(id:String):
	var p=players.get(id)
	if not p or p.holding=="" or not definitions.has(p.holding) or definitions[p.holding].kind!="gun":return
	if not combat.alive(id):return
	var gun=objects[p.holding];var st=gun.get_meta("state",{});var now=Time.get_ticks_msec()
	if gun.get_meta("owner","")!=id:return reject(id,"현재 총 소유권이 일치하지 않습니다.")
	if now<int(st.get("nextShot",0)):return
	var unlimited=not (rounds.tag.phase=="play" and sports.team("tag",id)>=0 and rounds.tag.get("mode")=="limited")
	if not unlimited:
		if now<int(st.get("reloadUntil",0)):return
		if st.has("reloadUntil"):st.ammo=12;st.erase("reloadUntil")
		if int(st.get("ammo",12))<=0:p.set_meta("trigger_held",false);return reject(id,"탄약 없음 · R 재장전")
	var muzzle=gun.position+p.direction()*.27
	var block=PhysicsRayQueryParameters3D.create(p.eye(),muzzle,1|4,[p.get_rid(),gun.get_rid()])
	st.nextShot=now+220
	if not get_world_3d().direct_space_state.intersect_ray(block).is_empty():gun.set_meta("state",st);p.set_meta("trigger_held",false);return reject(id,"총구가 벽이나 사물에 막혔습니다.")
	if not unlimited:st.ammo=int(st.get("ammo",12))-1
	gun.set_meta("state",st);shot_serial+=1
	p.set_meta("gesture","fire");p.set_meta("gesture_until",now+220)
	var shot_direction=(p.aim_point()-muzzle).normalized()
	var query=PhysicsRayQueryParameters3D.create(muzzle,muzzle+shot_direction*22,1|2|4,[p.get_rid(),gun.get_rid()])
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.get_meta("kind","")=="shield":
		var owner=players.get(hit.collider.get_meta("owner",""))
		if owner and owner.direction().dot((p.position-owner.position).normalized())>.45:
			owner.set_meta("gesture","block");owner.set_meta("gesture_until",now+300)
		else:
			var excluded=query.exclude;excluded.append(hit.collider.get_rid());query.exclude=excluded
			hit=get_world_3d().direct_space_state.intersect_ray(query)
	emit_toy_effect(muzzle,hit.get("position",muzzle+shot_direction*22))
	if hit.is_empty():return
	if hit.collider.get_meta("object_id","").begins_with("target-"):tag_score[id]=int(tag_score.get(id,0))+1;return
	if hit.collider not in players.values():return
	var other=hit.collider
	if other.holding!="" and definitions[other.holding].kind=="shield" and other.direction().dot((p.position-other.position).normalized())>.45:return
	var result=combat.damage(id,other.actor_id,now)
	if result.accepted:
		revision+=1;other.set_meta("gesture","ko" if result.ko else "hit");other.set_meta("gesture_until",now+(3000 if result.ko else 300))
		if result.ko:
			if other.holding!="":release(other,false)
			other.set_meta("gesture","ko");other.set_meta("gesture_until",now+3000)
			feedback(other.actor_id,"KO · 3초 후 복귀");feedback(id,"KO 확정 · 킬 게이지 +25")

func nearest_football(p,max_distance=1.5):
	var best=null;var distance=max_distance
	for object_id in objects:
		if definitions[object_id].kind!="football":continue
		var ball=objects[object_id];var d=p.position.distance_to(ball.position)
		if d>=distance or ball.get_meta("owner","")!="":continue
		var query=PhysicsRayQueryParameters3D.create(p.position+Vector3.UP*.3,ball.position,1|4,[p.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider!=ball:continue
		best=ball;distance=d
	return best

func kick_ball(p,power:float):
	if p.holding!="" or zone_at(p.position)!="football":return
	var ball=nearest_football(p)
	if not ball:return reject(p.actor_id,"발이 닿는 공이 없습니다.")
	var now=Time.get_ticks_msec()
	if now<int(p.get_meta("kick_cooldown",0)):return
	ball.linear_velocity=(p.direction()+Vector3.UP*lerpf(.02,.28,power)).normalized()*lerpf(5,14,power)
	sports.transition(String(ball.name),"RELEASED",p.actor_id)
	ball.angular_velocity=Vector3(0,2,0);ball.set_meta("touch_until",now+450)
	p.set_meta("kick_cooldown",now+350);p.set_meta("gesture","kick");p.set_meta("gesture_until",now+550)

func steal_ball(p):
	var now=Time.get_ticks_msec()
	if p.holding!="" or now<int(p.get_meta("steal_until",0)):return
	p.set_meta("steal_until",now+700);p.set_meta("gesture","steal");p.set_meta("gesture_until",now+550)
	if zone_at(p.position)=="football":kick_ball(p,.12);return
	for other in players.values():
		if other==p or other.holding=="" or definitions[other.holding].kind!="basketball":continue
		var ball=objects[other.holding]
		if p.eye().distance_to(ball.position)>1.65 or not other.get_meta("dribble",false) or ball.position.y>other.position.y+1.18:continue
		var dir=(ball.position-p.eye()).normalized()
		if dir.dot(p.direction())<.4:continue
		var q=PhysicsRayQueryParameters3D.create(p.eye(),ball.position,1|4,[p.get_rid(),other.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and hit.collider!=ball:continue
		sports.transition(other.holding,"CONTESTED",p.actor_id);release(other,false);ball.linear_velocity=p.direction()*2.5+Vector3.UP*.6;return

func respawn_position() -> Vector3:
	var preferred=Vector3(24,0,-4)
	# A KO must not bypass the administrator's entry policy.
	return Vector3(0,0,10.3) if room_access.blocks_entry("hall",zone_at(preferred)) else preferred

func _physics_process(dt):
	for player in players.values():
		room_access.guard(self,player,player.position)
		var bubble=player.get_node_or_null("MessageBubble")
		if bubble and Time.get_ticks_msec()>int(bubble.get_meta("until",0)):bubble.visible=false
	for object_id in objects:
		if objects[object_id] is RigidBody3D and definitions[object_id].kind=="chair":
			var locked=not host or objects[object_id].get_meta("occupant","")!=""
			if objects[object_id].freeze!=locked:objects[object_id].freeze=locked
	for fixed_id in ["meeting-table-0","meeting-table-1"]:
		if objects.has(fixed_id):objects[fixed_id].freeze=true
	super._physics_process(dt)
	if not ready_to_play:return
	wardrobe.maintain()
	var now=Time.get_ticks_msec()
	if host and not frozen:
		for id in combat.advance(now,dt):
			if players.has(id):players[id].position=respawn_position();players[id].velocity=Vector3.ZERO;players[id].set_meta("gesture","respawn");players[id].set_meta("gesture_until",now+600)
		for id in players:
			var p=players[id]
			p.set_meta("ko",not combat.alive(id))
			if not combat.alive(id):p.command.x=0;p.command.z=0;p.command.jump=false;p.velocity=Vector3.ZERO
			if now-p.last_input_ms>300:p.set_meta("trigger_held",false)
			if id==local_id and not playing():p.set_meta("trigger_held",false)
			if p.get_meta("trigger_held",false) and p.holding!="" and definitions[p.holding].kind=="gun":fire_tag(id)
			if zone_at(p.position)=="football" and room_access.is_administrator(p.actor_id) and p.holding=="" and Vector2(p.velocity.x,p.velocity.z).length()>.2:
				var ball=nearest_football(p,1.0)
				if ball and now>=int(ball.get_meta("touch_until",0)) and absf(ball.position.y-p.position.y)<.4:
					var desired=p.position+Vector3(p.velocity.x,0,p.velocity.z).normalized()*.75-ball.position
					ball.apply_central_impulse(Vector3(desired.x,0,desired.z).limit_length(.8)*ball.mass*3.5)
					ball.set_meta("touch_until",now+160);sports.transition(String(ball.name),"FOOT_CONTROL",id)
					p.set_meta("gesture","foot_touch");p.set_meta("gesture_until",now+200)
		combat_view=combat.snapshot(now)
	laser_clock+=dt
	if host and laser_clock>.08:
		laser_clock=0
		for p in players.values():
			if p.holding=="" or definitions[p.holding].kind!="laser" or not p.get_meta("trigger_held",false):continue
			var source=objects[p.holding].global_position
			var q=PhysicsRayQueryParameters3D.create(source,source+p.direction()*20,1|4,[p.get_rid(),objects[p.holding].get_rid()])
			var hit=get_world_3d().direct_space_state.intersect_ray(q)
			if not hit.is_empty() and hit.collider.get_meta("object_id","")=="presentation":
				var at=slide_mesh.to_local(hit.position);var size=slide_mesh.mesh.size
				if bridge:bridge.physical_laser(p.actor_id,JSON.stringify([at.x/size.x+.5,.5-at.y/size.y]))
	if bridge:
		bridge.gameplay_hud(JSON.stringify({"combat":combat_view.get(local_id,{}),"charge":clampf((now-local_charge_ms)/1300.0,0,1) if local_charge_ms>0 else -1,"shots":shot_serial}))
		if tick%60==0:bridge.avatar_diagnostics(JSON.stringify(avatar_diagnostics()))

func network_state() -> Dictionary:
	var s=super.network_state()
	if not host:s.tick=last_remote_tick
	s.combat=combat.snapshot(Time.get_ticks_msec()) if host else combat_view;s.shots=shot_serial;s.protocolVersion=4;s.sports=sports.snapshot();s.facilities=facilities.states.duplicate(true)
	return s

func handle_packet(sender:String,m):
	if m is Dictionary and String(m.get("type","")).begins_with("wardrobe-"):
		if not host:wardrobe.receive(m)
		return
	if m is Dictionary and m.get("type")=="appearance-init":
		if host and m.get("epoch")==epoch:wardrobe.initialize_profile(sender,m.get("profile"))
		return
	if m is Dictionary and m.get("type")=="appearance-update":
		if not host and m.get("epoch")==epoch:wardrobe.update_profile(String(m.get("actor","")),m.get("profile"))
		return
	if not host and m is Dictionary and m.get("type")=="toy_effect":
		if m.get("epoch")==epoch:toy_effects.show_shot(String(m.get("shotId","")),vec(m.from),vec(m.to))
		return
	super.handle_packet(sender,m)
	if not host and m is Dictionary and m.get("type")=="state" and m.get("epoch")==epoch and int(m.get("tick",-1))>last_extra_tick:
		last_extra_tick=int(m.tick)
		sports.restore(m.get("sports",{}))
		facilities.restore(m.get("facilities",{}))
		for p in players.values():p.set_meta("ko",int(m.get("combat",{}).get(p.actor_id,{}).get("hp",100))<=0)
		wardrobe.apply_pending()
		avatar_state_count+=1;combat_view=m.get("combat",{});shot_serial=int(m.get("shots",0))

func handle_event(e:Dictionary):
	if e.get("type")=="wardrobe":wardrobe.event(e);return
	if e.get("type")=="appearance_bootstrap":
		if host:wardrobe.initialize_profile(local_id,e.get("profile"))
		else:send({"type":"appearance-init","epoch":epoch,"profile":e.get("profile")})
		return
	if e.get("type")=="placement":placement_pointer.handle(self,e);return
	if e.get("type")=="room_policy":room_access.apply_policy(e);return
	if e.get("type")=="chat_bubble":
		var speaker=players.get(String(e.get("sender","")))
		if speaker:
			var bubble=speaker.get_node_or_null("MessageBubble")
			if not bubble:
				bubble=Label3D.new();bubble.name="MessageBubble";bubble.position=Vector3(0,2.25,0);bubble.font=load("res://assets/fonts/NotoSansKR-game.ttf");bubble.font_size=36;bubble.pixel_size=.003;bubble.billboard=BaseMaterial3D.BILLBOARD_ENABLED;bubble.outline_size=9;speaker.add_child(bubble)
			bubble.text=String(e.get("text","")).left(60);bubble.visible=true;bubble.set_meta("until",Time.get_ticks_msec()+6000)
		return
	if e.get("type")=="ui_focus":
		local_charge_ms=0
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		if players.has(local_id):
			players[local_id].camera_rig.aiming=false
			request_action("input_cancel")
		return
	if e.get("type")=="broadcast_visual":facilities.broadcast_display(bool(e.get("active",false)));toy_effects.duck=.35 if e.get("active",false) else 1.0;return
	if e.get("type")=="activity":request_action("activity",{"mode":e.get("mode","")});return
	if e.get("type")=="visibility":
		# Host scheduling can still be throttled by the browser. Do not deliberately freeze on a Docs window switch.
		if host:frozen=transfer_frozen
		return
	if e.get("type")=="start":room_access.reset();classroom=bool(e.get("classroom",false));command_ledger.clear();combat.reset();last_extra_tick=-1
	if e.get("type")=="restore":combat.reset()
	super.handle_event(e)
	if e.get("type")=="start":wardrobe.reset_session()
	if e.get("type")=="join" and host:wardrobe.sync(String(e.id))
	if e.get("type")=="leave":wardrobe.initialized.erase(String(e.id))

func avatar_diagnostics() -> Dictionary:
	var rows=[]
	for p in players.values():
		var meshes=[]
		for n in p.standing.find_children("*","MeshInstance3D",true,false):meshes.append({"visible":n.is_visible_in_tree(),"surfaces":n.mesh.get_surface_count() if n.mesh else 0,"aabb":str(n.get_aabb())})
		rows.append({"id":p.actor_id,"local":p.local_player,"position":arr(p.position),"standingVisible":p.standing.is_visible_in_tree(),"appearance":{"revision":p.appearance_profile.revision,"faceHash":p.appearance_profile.faceHash,"shirt":p.appearance_profile.shirt},"cameraRig":p.camera_rig.diagnostics(),"cameraPosition":arr(p.camera.global_position),"motion":p.motion_graph.diagnostics(),"contactWeights":p.contact_ik.contact_weights,"contactSamples":p.contact_ik.contact_samples,"carry":furniture_carry.traces.get(p.actor_id,{}),"contactErrors":p.contact_ik.errors,"handContactErrors":p.hand_ik.errors,"skeletonBones":p.skeleton.get_bone_count() if p.skeleton else 0,"meshes":meshes})
	return {"commandResults":command_results,"role":"host" if host else "guest","epoch":epoch,"stateCount":avatar_state_count,"stateAgeMs":Time.get_ticks_msec()-last_snapshot_ms,"instances":rows,"camera":str(get_viewport().get_camera_3d().get_path())}

func target(p) -> Dictionary:
	var direct=super.target(p)
	if direct.get("id","")!="":return direct
	# Small tools keep their real physical colliders; a 7 cm aiming tolerance
	# improves keyboard/controller pickup, with a separate solid occlusion ray.
	var best={};var nearest=3.0
	for object_id in objects:
		if definitions[object_id].kind not in ["laser","marker"] or object_id==p.holding:continue
		var object=objects[object_id];var delta=object.global_position-p.eye();var along=delta.dot(p.direction())
		if along<=0 or along>=nearest or (delta-p.direction()*along).length()>.07:continue
		var q=PhysicsRayQueryParameters3D.create(p.eye(),object.global_position,1|4,[p.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and hit.collider!=object:continue
		nearest=along;best={"id":object_id,"point":object.global_position}
	return best if not best.is_empty() else direct

func update_hint():
	super.update_hint()
	var p=players.get(local_id)
	if not p:return
	var focused=target(p).get("id","")
	var label="E 집기 / 내리기 · Q 던지기 · F 기능 사용"
	if p.seated!="":
		label="F 일어서기 / 깨기"
		if definitions.get(p.holding,{}).get("kind","")=="book":label+=" · R 책 읽기"
		elif p.holding=="" and zone_at(p.position)=="meeting":label+=" · R 회의 자료"
	elif p.holding!="":
		var kind=definitions[p.holding].kind
		label="E 내리기 · Q 던지기"
		if kind=="book":label+=" · F 읽기"
		if kind=="basketball":label="클릭 누르기→슛 게이지→놓기 · R 드리블 · 우클릭 손 전환 · Q 패스 · E 내리기"
		if kind=="gun":label="클릭 유지 연사 · "+("연습 무제한 탄약" if rounds.tag.phase=="practice" else "R 재장전")+" · E 내리기"
		if kind=="laser":label="클릭 유지: 3D 발표 레이저 · 발표자 권한 필요 · E 내리기"
	elif definitions.has(focused):
		var kind=definitions[focused].kind
		var verbs={"chair":"앉기","sofa":"앉기","bed":"취침","table":"회의 자료 / 컴퓨터","low_table":"회의 자료 / 컴퓨터","floor_lamp":"전등 켜기/끄기","arcade":"공룡 러너","storage":"수납","drawer":"서랍","fridge":"재료 꺼내기","sink":"설거지","cooker":"조리","counter":"담기"}
		label=("E 집기 · " if Capabilities.can_carry(kind) else "고정 시설 · ")+"F "+verbs.get(kind,"사용")
	elif focused in wardrobe.station_ids:label="빈손으로 클릭 · 꾸미기 시작"
	elif facilities.fixtures.has(focused):label="F "+{"toilet_ground":"변기 뚜껑 열기/닫기","toilet_upper":"변기 뚜껑 열기/닫기","flush_ground":"물내림","flush_upper":"물내림","vent":"환기 켜기/끄기","tap_ground":"수도 켜기/끄기","tap_upper":"수도 켜기/끄기","broadcast_console":"방송석","meeting_computer":"회의 자료 / 컴퓨터"}.get(focused,"조명 켜기/끄기")
	elif doors.has(focused):label="F 문 열기 / 닫기"
	elif focused=="presentation":label="F 발표 자료 · PDF/이미지"
	elif focused=="board":label="F 보드 확대 · 마카를 들고 클릭해 쓰기"
	if zone_at(p.position)=="football" and p.holding=="":label="발 드리블 · 클릭 충전/슛 · Q 패스 · F 가로채기"
	elif zone_at(p.position)=="basketball" and p.holding=="":label+=" · F 드리블 공 스틸"
	if placement_pointer.token!="":label=("놓으면 설치" if build_valid else "유효한 지지면으로 이동")+" · R 회전 · Esc 취소"
	elif build_kind!="":label=("클릭 설치" if build_valid else "충돌/보호 구역 · 설치 불가")+" · R 회전 · B 취소"
	hint.text=label
	if bridge:bridge.hint(label)

func save_world() -> Dictionary:
	var w=super.save_world();w.facilities=facilities.states.duplicate(true);return w

func restore_world(w:Dictionary):
	var conflicts=wardrobe.restore_conflicts(w)
	if not conflicts.is_empty():
		if bridge:bridge.status("기존 사물이 의상방 구조와 겹쳐 복원을 중단했습니다. 현재 공간과 원본 파일을 유지합니다: "+", ".join(conflicts))
		return
	sports=preload("res://scripts/sports/match_rules.gd").new();command_ledger.clear()
	super.restore_world(furniture_support.prepare_restore(self,w))
	if facilities:facilities.reset();facilities.restore(w.get("facilities",{}),true)
	combat.reset()
	for p in players.values():combat.add(p.actor_id);p.set_meta("ko",false);p.set_meta("trigger_held",false);p.set_meta("gesture","");p.set_meta("gesture_until",0)

func object_in_use(object_id:String) -> bool:
	# Computer desks carry wired equipment; keep their fixed mounting and explain why.
	if object_id in ["meeting-table-0","meeting-table-1"]:return true
	return super.object_in_use(object_id)

func add_architecture(kind:String,pos:Vector3) -> Node3D:
	if kind=="house":
		var body=StaticBody3D.new();body.position=pos;body.collision_layer=1
		body.add_child(load("res://assets/v2/house-v3.glb").instantiate())
		for c in JSON.parse_string(FileAccess.get_file_as_string("res://assets/v2/house-collisions-v3.json")):add_shape(body,c)
		add_child(body);return body
	if kind!="grounds":return super.add_architecture(kind,pos)
	var node=StaticBody3D.new();node.position=pos;node.collision_layer=1;node.physics_material_override=Surface.material("court")
	node.add_child(load("res://assets/v2/grounds-v3.glb").instantiate())
	for c in JSON.parse_string(FileAccess.get_file_as_string("res://assets/v2/grounds-collisions-v3.json")):
		var surface="rim" if absf(c.get("position",[0,0,0])[1]-3.05)<.02 else ("backboard" if c.get("size",[0,0,0])[0]<.08 and c.get("size",[0,0,0])[1]>1 else "")
		if surface!="":
			var contact=StaticBody3D.new();contact.collision_layer=1;contact.physics_material_override=Surface.material(surface);node.add_child(contact);add_shape(contact,c)
		else:add_shape(node,c)
	add_child(node);return node

func update_sports(_dt:float):
	for object_id in objects:
		var kind=definitions[object_id].kind
		if kind not in ["basketball","football"]:continue
		if object_id!=kind and rounds[kind].phase=="play":continue
		var ball=objects[object_id];var at=ball.position;var previous=ball_previous.get(object_id,at)
		var toucher=String(sports.ball_states.get(object_id,{}).get("lastTouch",""))
		if not room_access.is_administrator(toucher):ball_previous[object_id]=at;continue
		if ball.get_meta("owner","")!="":ball_previous[object_id]=at;continue
		if kind=="basketball":
			if rounds.basketball.phase in ["practice","play"] and not ball.get_meta("scored",false):
				for i in range(2):
					if BallProfile.basket_crossing(previous,at,Vector3(-16.35 if i==0 else 4.35,3.05,30)):
						var scoring_team=1-i
						var shooter=String(sports.ball_states.get(object_id,{}).get("lastTouch",""))
						if rounds.basketball.get("mode")=="team" and sports.team("basketball",shooter)!=scoring_team:continue
						basketball_score[scoring_team]+=2;revision+=1;ball.set_meta("scored",true)
			if at.y<.3:ball.set_meta("scored",false)
			if at.x < -21 or at.x>9 or at.z<20 or at.z>40:reset_ball(ball,Vector3(-7,.4,30))
		else:
			for i in range(2):
				var line=10 if i==0 else 40
				var crossed=previous.x>line and at.x<=line if i==0 else previous.x<line and at.x>=line
				if crossed and rounds.football.phase in ["practice","play"]:
					var crossing=previous.lerp(at,(line-previous.x)/(at.x-previous.x))
					if crossing.z>29.17 and crossing.z<34.83 and crossing.y<2.23 and crossing.y>.10:
						football_score[1-i]+=1;revision+=1;reset_ball(ball,Vector3(25,.4,32))
			if at.x<8 or at.x>42 or at.z<20 or at.z>44:reset_ball(ball,Vector3(25,.4,32))
		ball_previous[object_id]=ball.position

func apply_checkpoint(e:Dictionary):
	command_ledger.clear()
	super.apply_checkpoint(e)
	last_extra_tick=-1
	wardrobe.reset_session()
	var appearances=e.get("checkpoint",{}).get("appearances",{})
	if appearances is Dictionary and appearances.size()<=8:
		for actor in appearances:
			if players.has(actor):wardrobe.update_profile(actor,appearances[actor])
	if host:
		var snapshot=e.get("checkpoint",{}).get("state",{})
		sports.restore(snapshot.get("sports",{}))
		combat.restore(snapshot.get("combat",{}),Time.get_ticks_msec())
		shot_serial=int(snapshot.get("shots",0))
		for p in players.values():p.set_meta("ko",not combat.alive(p.actor_id));p.set_meta("trigger_held",false)

func request_action(kind:String,data:Dictionary={}):
	seq+=1
	var actor=players.get(local_id)
	var target_id=String(target(actor).get("id","")) if actor else ""
	if actor and actor.holding!="" and kind in ["throw","carry","trigger_down","trigger_up","secondary"]:target_id=actor.holding
	var message={"type":"action","actor":local_id,"requestId":local_id+":place:"+String(data.placementId) if kind=="place" and data.has("placementId") else local_id+":"+str(seq),"epoch":epoch,"seq":seq,"targetId":target_id,"action":kind,"data":data}
	if host:perform(local_id,message)
	else:send(message)

func perform(id:String,m:Dictionary):
	if not host or not players.has(id):return
	var validation=command_ledger.inspect(id,m,epoch)
	if not validation.valid:
		command_results.rejected+=1
		send_command_result(id,{"type":"action-result","requestId":String(m.get("requestId","")).left(100),"actor":id,"epoch":epoch,"targetId":"","accepted":false,"reason":validation.reason,"stateRevision":revision})
		feedback(id,validation.reason);return
	if not validation.cached.is_empty():
		command_results.duplicates+=1;send_command_result(id,validation.cached);return
	active_request={"type":"action-result","requestId":m.requestId,"actor":id,"epoch":epoch,"targetId":m.get("targetId",""),"accepted":true,"reason":"","stateRevision":revision}
	var allowed=["wardrobe_open","wardrobe_apply","wardrobe_cancel","carry","throw","use","trigger_down","trigger_up","kick_start","kick","secondary","crossover","activity","rest","eat","place","remove_object","input_cancel","round","stroke","undo","board_update","board_delete"]
	if frozen:reject(id,"방장 이전 중에는 조작을 잠시 기다려 주세요.")
	elif int(m.seq)<=int(actions.get(id,-1)):reject(id,"이미 처리된 순서의 요청입니다.")
	elif not m.get("action","") in allowed:reject(id,"지원하지 않는 동작입니다.")
	else:execute_action(id,m)
	active_request.stateRevision=revision
	command_results["accepted" if active_request.accepted else "rejected"]+=1
	command_ledger.remember(id,epoch,m.requestId,active_request);send_command_result(id,active_request);active_request={}

func send_command_result(id:String,result:Dictionary):
	if id==local_id:
		if bridge:bridge.command_result(JSON.stringify(result))
	else:send(result,id)

func reject(id:String,reason:String):
	if active_request.get("actor")==id:active_request.accepted=false;active_request.reason=reason
	feedback(id,reason)

func feedback(id:String,reason:String):
	super.reject(id,reason)

func emit_toy_effect(from:Vector3,to:Vector3):
	var shot_id=epoch+":"+str(shot_serial)
	toy_effects.show_shot(shot_id,from,to)
	send({"type":"toy_effect","epoch":epoch,"shotId":shot_id,"from":arr(from),"to":arr(to)})

func update_build_preview():
	if placement_pointer.token!="":placement_pointer.update(self)
	else:super.update_build_preview()

func placement_ok(p,kind:String,point:Vector3,angle:float,move_id:String="") -> bool:
	return super.placement_ok(p,kind,point,angle,move_id) and placement_clearance.valid(self,p,kind,point,angle,move_id)


func zone_at(pos:Vector3) -> String:
	if pos.y>3.3 and pos.y<4.1 and pos.x> -9.9 and pos.x< -5.0 and pos.z> -3.9 and pos.z<2.9:return "wardrobe"
	return super.zone_at(pos)

func make_checkpoint() -> Dictionary:
	var checkpoint=super.make_checkpoint()
	checkpoint.appearances={}
	for actor in players:checkpoint.appearances[actor]=players[actor].appearance_profile.duplicate(true)
	return checkpoint
