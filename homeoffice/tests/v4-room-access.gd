extends SceneTree
var w
var results=[]
func _initialize():call_deferred("run")
func check(label:String,okay:bool):
	results.append({"name":label,"passed":okay});print("PASS " if okay else "FAIL ",label)
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false)
	var p=w.players.local
	w.handle_event({"type":"room_policy","revision":1,"locks":{"meeting":true}})
	check("Only the selected physical room blocks new entry",w.room_access.blocks_entry("hall","meeting") and not w.room_access.blocks_entry("hall","living"))
	check("Existing occupants can leave and move within a locked room",not w.room_access.blocks_entry("meeting","hall") and not w.room_access.blocks_entry("meeting","meeting"))
	var outside=Vector3(1.3,0,7);p.position=Vector3(1.5,0,7);p.velocity=Vector3(2,0,0);w.room_access.guard(w,p,outside)
	check("Crossing a locked boundary restores the last outside position",p.position==outside and p.velocity.x==0)
	p.position=outside;w.room_access.guard(w,p,Vector3(1.5,0,7))
	check("Crossing outward succeeds without a PIN or administrator role",p.position==outside)
	w.room_access.apply_policy({"revision":0,"locks":{"meeting":false}})
	check("Older local policy cannot replace current locks",w.room_access.locks.meeting)
	var saved=w.save_world();w.restore_world(saved)
	check("World file restore does not overwrite current admin policy",w.room_access.locks.meeting and not saved.has("roomLocks") and not saved.has("pin"))
	w.handle_event({"type":"room_policy","revision":2,"locks":{"meeting":false}})
	check("Administrator unlock opens entry to every student",not w.room_access.blocks_entry("hall","meeting"))
	var door=w.doors["meeting-door"];var opening=door.to_global(Vector3(float(door.get_meta("definition").width)/2,0,0))
	p.position=opening;w.door_states["meeting-door"]=false;door.get_child(0).rotation.y=-PI/2;w.update_doors(1)
	check("Door leaf does not close onto an occupied opening",is_equal_approx(door.get_child(0).rotation.y,-PI/2))
	var light=w.room_lights.filter(func(l):return l.get_meta("zone","")=="meeting")[0];w.facilities.states.office_light=false;p.position=Vector3(3,0,7);w.update_room_lighting(1)
	check("Meeting lights respect the real office wall switch",light.light_energy==0)
	p.command.yaw=.6;p.rotation.y=-.3;w.yaw=.6;var checkpoint=w.make_checkpoint();w.apply_checkpoint({"host":true,"epoch":"handoff-test","checkpoint":checkpoint})
	check("Host handoff preserves look direction independently of body facing",is_equal_approx(w.yaw,.6))
	w.room_access.apply_policy({"revision":3,"locks":{"game":true}})
	check("KO return cannot place a player inside a locked game room",w.zone_at(w.respawn_position())=="hall")
	w.room_access.apply_policy({"revision":4,"locks":{"game":false}})
	check("Opening the game room restores its ordinary return location",w.respawn_position()==Vector3(24,0,-4))
	var file=FileAccess.open("res://evidence/v4/room-access.json",FileAccess.WRITE);file.store_string(JSON.stringify({"environment":"Godot/Jolt fixture; verified-policy injection, no real Clerk login","results":results},"  "));file.close()
	var okay=results.all(func(row):return row.passed);w.queue_free();w=null;p=null;await process_frame;await create_timer(.2).timeout;quit(0 if okay else 1)
