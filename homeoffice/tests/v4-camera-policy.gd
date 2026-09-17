extends SceneTree
var w
var results=[]
var order=50000
func _initialize():call_deferred("run")
func check(label:String,okay:bool):
	results.append({"name":label,"passed":okay});print("PASS " if okay else "FAIL ",label)
func action(id:String,kind:String):
	order+=1;w.perform(id,{"actor":id,"requestId":id+":"+str(order),"epoch":w.epoch,"targetId":"","seq":order,"action":kind,"data":{}})
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false)
	w.add_player("guest")
	var a=w.players.local;var b=w.players.guest
	a.position=Vector3(0,0,18);a.command.yaw=0.0;a.command.pitch=0.0;a.command.third=true
	a.camera_rig.update(a,.1,false)
	check("Third-person default shows actual local body",a.camera_rig.third_person and a.standing.visible and a.camera_rig.actual_distance>2)
	var body_yaw=a.rotation.y;a.command.yaw=1.0;a.command.x=0.0;a.command.z=0.0;a.simulate(.02)
	check("Idle camera orbit does not turn body",is_equal_approx(a.rotation.y,body_yaw))
	a.command.x=0.0;a.command.z=-1.0;a.simulate(.1)
	check("Movement follows camera yaw independent of old body facing",a.velocity.x<-.1 and a.velocity.z<-.1)
	a.command.x=0.0;a.command.z=0.0;a.command.yaw=0.0;a.camera_rig.toggle();a.camera_rig.update(a,.1,false)
	check("First-person reaches eye and avoids local head interior",a.camera.global_position.distance_to(a.eye())<.01 and not a.standing.visible)
	a.camera_rig.update(a,.1,true);a.camera_rig.update(a,.1,false)
	check("Sleep camera returns to previous first-person preference",not a.camera_rig.third_person and a.camera.global_position.distance_to(a.eye())<.01)
	a.camera_rig.toggle();a.camera_rig.distance=3.2
	var wall=StaticBody3D.new();wall.collision_layer=1;wall.position=a.eye()+Vector3(0,0,1.2)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(3,3,.25);shape.shape=box;wall.add_child(shape);w.add_child(wall)
	for i in 3:await physics_frame
	a.camera_rig.update(a,.016,false)
	check("Camera volume contracts before a physical wall",a.camera_rig.actual_distance<1.1 and a.camera_rig.actual_distance>.3)
	wall.queue_free();await physics_frame
	a.camera_rig.aiming=true;a.camera_rig.update(a,1,false)
	check("Shoulder aim offsets camera to character right",a.camera.global_position.x>a.eye().x+.25 and a.camera_rig.actual_distance<2)
	a.camera_rig.zoom(100);check("Zoom cannot exceed bounded distance",a.camera_rig.distance==5.0)
	a.camera_rig.zoom(-100);check("Zoom cannot enter unbounded negative distance",a.camera_rig.distance==.9)
	var bad={"x":0.0,"z":0.0,"yaw":0.0,"pitch":0.0,"seq":1,"jump":false,"run":false,"zoom":INF}
	check("Untrusted camera values reject non-finite input",not w.valid_input(bad))
	a.set_meta("trigger_held",true);a.set_meta("charge_started",1);action("local","input_cancel")
	check("UI cancellation clears held fire and charge without releasing a shot",not a.get_meta("trigger_held") and not a.has_meta("charge_started"))
	b.set_meta("trigger_held",true)
	w.handle_packet("guest",{"type":"input","epoch":w.epoch,"command":{"x":0.0,"z":0.0,"yaw":0.0,"pitch":0.0,"seq":10,"jump":false,"run":false,"active":false}})
	check("Guest focus loss cancels authoritative automatic fire",not b.get_meta("trigger_held"))
	var rejected=w.command_results.rejected
	for kind in ["entry_grant","grant","weapon_zone","game_gate"]:action("local",kind)
	check("Retired approval commands cannot mutate policy",w.command_results.rejected==rejected+4)
	var gun=w.objects["tag-gun-1"];a.holding="tag-gun-1";gun.set_meta("owner","local");gun.gravity_scale=0
	a.command.third=false;a.command.pitch=0.0;a.command.yaw=0.0
	for row in [["meeting",Vector3(5,0,8)],["home",Vector3(-9,0,8)],["office",Vector3(5,0,0)],["garden",Vector3(0,0,18)],["play",Vector3(24,0,-4)]]:
		a.position=row[1];gun.position=a.eye()+a.direction()*.43;gun.set_meta("state",{"nextShot":0});w.update_living(0)
		for i in 2:await physics_frame
		var before=w.shot_serial;w.fire_tag("local")
		check("Free fire keeps ownership and fires in "+row[0],a.holding=="tag-gun-1" and w.shot_serial==before+1)
	w.classroom=true;gun.set_meta("state",{"nextShot":0});var before=w.shot_serial;w.fire_tag("local")
	check("Classroom flag does not prohibit free fire",w.shot_serial==before+1)
	w.rounds.tag.phase="results";gun.set_meta("state",{"nextShot":0});before=w.shot_serial;w.fire_tag("local")
	check("Ending a match cannot disable ordinary free fire",w.shot_serial==before+1)
	var state=w.network_state();check("Snapshot excludes retired per-player permissions",not state.has("grants") and not state.has("entryGrants") and not state.has("weaponZones"))
	var file=FileAccess.open("res://evidence/v4/camera-policy.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"environment":"Godot/Jolt controlled fixtures; no real people or UI acceptance","results":results},"  "));file.close()
	var okay=results.all(func(r):return r.passed);w.queue_free();w=null;a=null;b=null;gun=null;await process_frame;await create_timer(.2).timeout;quit(0 if okay else 1)
