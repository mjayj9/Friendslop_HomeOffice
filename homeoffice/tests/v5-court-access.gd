extends SceneTree
var w
var checks=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String,detail={}):
	checks.append({"ok":ok,"label":label,"detail":detail});print("PASS " if ok else "FAIL ",label)
func centre(zone:String) -> Vector3:
	for room in w.layout.rooms:
		if room.id==zone:return Vector3((room.rect[0]+room.rect[2])*.5,.02,(room.rect[1]+room.rect[3])*.5)
	return Vector3.ZERO
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false);w.add_player("ordinary-host");w.add_player("verified-fixture")
	var guest=w.players["ordinary-host"];var admin=w.players["verified-fixture"]
	var safe=w.vec(w.layout.spawn)
	var gun=""
	for object_id in w.definitions:
		if w.definitions[object_id].kind=="gun":gun=object_id;break
	check(gun!="","Global gun exists in retained world")
	for zone in ["basketball","football"]:
		for path in ["open-door","jump","restore","spawn","host-transfer"]:
			w.host=path=="host-transfer" or path=="open-door"
			guest.position=centre(zone)+(Vector3.UP*8 if path=="jump" else Vector3.ZERO)
			guest.holding=gun
			var held=guest.holding
			w.room_access.guard(w,guest,safe if path=="open-door" else guest.position)
			check(w.room_access.restricted_zone(w,guest.position,.28)=="",zone+" denies "+path)
			check(guest.holding==held,zone+" denial preserves global weapon")
	check(not w.room_access.is_administrator(guest.actor_id),"Simulation host and nickname are not administrator")
	var now=Time.get_unix_time_from_system()*1000.0
	w.room_access.apply_policy({"revision":2,"expiresAt":now+20000,"administrators":{admin.actor_id:now+20000},"locks":{"basketball":false,"football":false}})
	admin.local_player=true;admin.camera_rig.third_person=false;admin.camera_rig.distance=2.7
	for zone in ["basketball","football"]:
		admin.position=centre(zone);admin.velocity=Vector3.ZERO;admin.holding=""
		w.room_access.guard(w,admin,safe)
		check(w.room_access.restricted_zone(w,admin.position)==zone,"Explicit in-memory operator fixture enters "+zone)
		for i in 20:admin.animate(1.0/60);await physics_frame
		check(admin.motion_graph.base_clip==zone+"_ready","No-ball ready pose before a match: "+zone,{"clip":admin.motion_graph.base_clip})
		check(admin.motion_graph.upper_body=="" and admin.motion_graph.one_shot=="","No phantom ball action: "+zone)
		var entries=admin.motion_graph.profile_entries
		for i in 20:admin.animate(1.0/60);await physics_frame
		check(admin.motion_graph.profile_entries==entries,"Profile enters once: "+zone)
		check(admin.camera_rig.third_person and admin.camera_rig.profile==zone.to_upper(),"Dedicated camera: "+zone)
	admin.position=safe;admin.animate(1.0/60);await physics_frame
	check(not admin.camera_rig.third_person and absf(admin.camera_rig.distance-2.7)<.01,"Leaving courts restores previous camera once")
	w.room_access.policy_expires_at=now-1;admin.position=centre("basketball");w.room_access.guard(w,admin,admin.position)
	check(w.room_access.restricted_zone(w,admin.position)=="","Expired authority ejects safely")
	w.room_access.reset();check(not w.room_access.is_administrator(admin.actor_id),"Session reset removes authority")
	var report={"kind":"Local explicit fixture; no operational administrator account verified","checks":checks}
	FileAccess.open("res://evidence/v5/court-access.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	var failed=checks.any(func(c):return not c.ok)
	w.queue_free();w=null;guest=null;admin=null;await process_frame;await create_timer(.2).timeout;quit(1 if failed else 0)
