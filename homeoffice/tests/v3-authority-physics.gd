extends SceneTree
var w
var results=[]
var order=20000
func _initialize():call_deferred("run")
func check(label:String,okay:bool,detail={}):
	results.append({"name":label,"passed":okay,"detail":detail});print("PASS " if okay else "FAIL ",label)
func packet(id:String,action:String,data={}) -> Dictionary:
	order+=1;return {"type":"action","actor":id,"epoch":w.epoch,"requestId":id+":"+str(order),"seq":order,"targetId":"","action":action,"data":data}
func aim(p,at:Vector3):
	var delta=at-p.eye();p.command.yaw=atan2(-delta.x,-delta.z);p.command.pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
func settle(n=3):
	for i in n:await physics_frame
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w);await settle(8);w.set_physics_process(false)
	w.add_player("friend");w.entry_grants.friend=true;w.weapon_grants.local=true;w.weapon_grants.friend=true
	var a=w.players.local;var b=w.players.friend
	a.position=Vector3(13.35,0,-8.9);aim(a,Vector3(13.35,1.03,-10));await settle()
	var request=packet("local","use");var before=w.facilities.states.tap_ground
	w.perform("local",request);var changed=w.facilities.states.tap_ground;w.perform("local",request)
	check("Duplicate F command toggles tap exactly once and returns cached response",changed!=before and w.facilities.states.tap_ground==changed and w.command_results.duplicates==1)
	var rejected=w.command_results.rejected;var bad=packet("local","use");bad.actor="friend";w.perform("local",bad)
	bad=packet("local","use");bad.epoch="retired-session";w.perform("local",bad)
	check("Forged actor and retired epoch reject without changing facilities",w.command_results.rejected==rejected+2 and w.facilities.states.tap_ground==changed)
	w.facilities.toggle("flush_ground");var deadline=w.facilities.flush_until.ground
	check("Flush has real cooldown and sound state",not w.facilities.toggle("flush_ground") and deadline>Time.get_ticks_msec())
	var saved=w.save_world()
	w.spawn_object({"id":"extra-football","kind":"football","p":[25,.3,32],"yaw":0,"state":{}})
	check("Newly placed ball is registered with shared sport rules",w.sports.ball_states.has("extra-football") and not w.sports.ball_states["extra-football"].matchBall)
	w.restore_world(saved);await settle()
	a=w.players.local;b=w.players.friend
	check("Restore clears removed ball metadata and never replays an old flush",not w.sports.ball_states.has("extra-football") and w.facilities.flush_until.is_empty())
	a.position=Vector3(25,0,32);aim(a,Vector3(25,1.62,30));var foot=w.objects.football;foot.position=Vector3(25,.2,31.2);foot.linear_velocity=Vector3.ZERO;await settle()
	w.perform("local",packet("local","carry"));check("Football in court cannot be picked up with E",a.holding=="" and foot.get_meta("owner","")=="")
	w.perform("local",packet("local","throw"));check("Q passes football by real velocity without hand ownership",foot.linear_velocity.length()>5 and a.holding=="" and w.sports.ball_states.football.state=="RELEASED")
	w.rounds.football.phase="practice";var football_score=w.football_score.duplicate();w.ball_previous.football=Vector3(10.4,.4,32);foot.position=Vector3(9.9,.4,32);w.update_sports(.016)
	check("Football crossing scores and restarts at midfield",w.football_score[1]==football_score[1]+1 and foot.position.distance_to(Vector3(25,.4,32))<.01)
	a.position=Vector3(-7,0,30);b.position=Vector3(-7,0,29);aim(a,Vector3(-7,.85,29.4));var ball=w.objects.basketball;ball.position=Vector3(-7,.85,29.4);ball.linear_velocity=Vector3.ZERO;ball.gravity_scale=0;ball.set_meta("owner","friend");b.holding="basketball";b.set_meta("dribble",true);await settle()
	w.steal_ball(a);check("Facing nearby dribble can be contested and becomes a loose physical ball",b.holding=="" and ball.get_meta("owner","")=="" and ball.linear_velocity.length()>1)
	w.rounds.basketball.phase="practice";ball.set_meta("scored",false);w.ball_previous.basketball=Vector3(-16.35,3.2,30);ball.position=Vector3(-16.35,2.9,30);var score=w.basketball_score.duplicate();w.update_sports(.016);w.update_sports(.016)
	check("Descending basket gives exactly two points once",w.basketball_score[1]==score[1]+2)
	w.entry_grants.friend=true;w.weapon_grants.local=true;w.weapon_grants.friend=true
	a.position=Vector3(25,0,1);b.position=Vector3(25,0,-2);aim(a,b.eye());w.combat.reset();w.combat.add("local");w.combat.add("friend")
	var gun;var shield
	for key in w.objects:
		if w.definitions[key].kind=="gun" and not gun:gun=w.objects[key];a.holding=key;gun.set_meta("owner","local");gun.gravity_scale=0
		if w.definitions[key].kind=="shield" and not shield:shield=w.objects[key]
	gun.position=a.eye()+a.direction()*.43;await settle()
	for i in 4:
		gun.set_meta("state",{"nextShot":0});w.fire_tag("local")
	check("Actual world muzzle ray applies HP damage and KO",w.combat.fighters.friend.hp==0 and w.combat.fighters.local.kills==1,{"victim":w.combat.fighters.friend})
	w.combat.reset();w.combat.add("local");w.combat.add("friend");b.holding=String(shield.name);shield.set_meta("owner","friend");shield.gravity_scale=0;b.command.yaw=PI;shield.position=b.eye()+b.direction()*.4;await settle()
	gun.set_meta("state",{"nextShot":0});w.fire_tag("local");check("Frontal shield blocks physical weapon ray",w.combat.fighters.friend.hp==100)
	b.command.yaw=0;shield.position=b.eye()+b.direction()*.4;await settle();gun.set_meta("state",{"nextShot":0});w.fire_tag("local");check("Shield does not protect an exposed back",w.combat.fighters.friend.hp==75)
	w.release(a,false);w.release(b,false);a.position=Vector3(9,0,6.5);b.position=Vector3(6,0,11);await settle()
	var origin=Vector3(9,1.85,6.2);var query=PhysicsRayQueryParameters3D.create(origin,Vector3(9,1.85,3.8),1|4,[a.get_rid()]);var hit=w.get_world_3d().direct_space_state.intersect_ray(query)
	var uv=Vector2(-1,-1)
	if not hit.is_empty() and hit.collider.get_meta("object_id","")=="presentation":
		var at=w.slide_mesh.to_local(hit.position);uv=Vector2(at.x/w.slide_mesh.mesh.size.x+.5,.5-at.y/w.slide_mesh.mesh.size.y)
	check("Physical presentation ray maps to surface-centre UV",uv.distance_to(Vector2(.5,.5))<.01,{"uv":[uv.x,uv.y]})
	var blocker=StaticBody3D.new();blocker.position=Vector3(9,1.85,5.5);blocker.collision_layer=1;var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(.4,.4,.4);shape.shape=box;blocker.add_child(shape);w.add_child(blocker);await settle();hit=w.get_world_3d().direct_space_state.intersect_ray(query)
	check("Physical laser stops at an intervening solid object",not hit.is_empty() and hit.collider==blocker)
	var file=FileAccess.open("res://evidence/v3/authority-physics.json",FileAccess.WRITE);file.store_string(JSON.stringify({"environment":"Real Godot/Jolt scene and raycasts, controlled engine fixture positions. No browser/human acceptance claim.","results":results},"  "));file.close()
	var okay=results.all(func(r):return r.passed);w.queue_free();w=null;a=null;b=null;gun=null;shield=null;ball=null;foot=null;blocker=null;await process_frame;await create_timer(.25).timeout;quit(0 if okay else 1)
