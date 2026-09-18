extends SceneTree
var w
var results=[]
var seq=0
func _initialize():call_deferred("run")
func check(label,okay):results.append({"name":label,"passed":okay});print("PASS " if okay else "FAIL ",label)
func aim(p,at:Vector3):
	var delta=at-p.eye();p.command.yaw=atan2(-delta.x,-delta.z);p.command.pitch=atan2(delta.y,Vector2(delta.x,delta.z).length());p.rotation.y=p.command.yaw
func action(p,kind):
	seq+=1;w.perform(p.actor_id,{"actor":p.actor_id,"requestId":p.actor_id+":"+str(seq),"targetId":"","epoch":w.epoch,"seq":seq,"action":kind,"data":{}})
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in range(8):await physics_frame
	w.local_id="controller";w.add_player("friend")
	var a=w.players.local;var b=w.players.friend;var box=w.objects["living-storage"]
	a.position=box.global_transform*Vector3(0,0,1.5);b.position=box.position+Vector3(3,0,2)
	aim(a,box.position+Vector3(0,.5,0));await physics_frame
	check("Host ray reaches the physical storage chest",w.target(a).get("id","")=="living-storage")
	action(a,"use");check("F opens actual hinged chest",box.get_meta("state").get("open",false))
	w.spawn_object({"id":"stored-test-book","kind":"book","p":w.arr(a.eye()+a.direction()),"yaw":0.0,"state":{}})
	var book=w.objects["stored-test-book"];book.set_meta("owner",a.actor_id);book.gravity_scale=0;a.holding=String(book.name)
	action(a,"use");w.update_living_props(.5)
	print("STORED ",box.get_meta("state")," ",a.holding," ",book.freeze," ",book.collision_layer)
	check("Held book becomes a unique persisted container reference",a.holding=="" and box.get_meta("state").contents==["stored-test-book"] and book.freeze and book.collision_layer==0)
	check("Open chest shows its stored original book model",book.visible and book.position.distance_to(box.position)<1)
	action(a,"secondary");w.update_living_props(1)
	check("Closing lid hides contents and retains them",not book.visible and not box.get_meta("state").open and book.freeze)
	check("Full chest cannot be moved or removed",w.object_in_use("living-storage"))
	action(a,"use");w.update_living_props(1)
	var world=w.save_world();var file=FileAccess.open("res://evidence/v5/storage-world.json",FileAccess.WRITE);file.store_string(JSON.stringify(world));file.close()
	w.restore_world(world);box=w.objects["living-storage"];book=w.objects["stored-test-book"];w.update_living_props(1)
	print("RESTORED ",box.get_meta("state")," ",book.freeze," ",book.visible)
	check("Whole world restore retains the open chest and physical contents",box.get_meta("state").contents==["stored-test-book"] and book.freeze and book.visible)
	a.position=box.global_transform*Vector3(0,0,1.5);b.position=box.global_transform*Vector3(.65,0,1.5)
	aim(a,box.position+Vector3(0,.5,0));aim(b,box.position+Vector3(0,.5,0));await physics_frame
	action(a,"use");action(b,"use");w.update_living_props(.05)
	check("Two contenders cannot extract the same stored object twice",a.holding=="stored-test-book" and b.holding=="" and box.get_meta("state").get("contents",[]).is_empty() and book.get_meta("owner")==a.actor_id)
	check("Extracted item regains collision and is held with bounded physics",not book.freeze and book.collision_layer==4 and book.gravity_scale==0)
	w.release(a,false)
	var drawer=w.objects["living-drawer"]
	a.position=drawer.global_transform*Vector3(0,0,1.6);b.position=Vector3(-12,0,10);aim(a,drawer.position+Vector3(0,.55,0));await physics_frame
	print("DRAWER RAY ",w.target(a)," ",a.position," ",a.command);action(a,"use");w.update_living_props(1);print("DRAWER ",drawer.get_meta("state")," ",drawer.get_node("MovingPart").position)
	check("Drawer slides along its model anchor",drawer.get_meta("state").get("open",false) and drawer.get_node("MovingPart").position.z>.4)
	var lamp=w.objects["living-lamp"]
	a.position=lamp.position+Vector3(0,0,1.4);aim(a,lamp.position+Vector3(0,1.2,0));await physics_frame
	print("LAMP RAY ",w.target(a)," ",a.position," ",a.command);action(a,"use");w.update_living_props(1);w.local_id="local";w.update_room_lighting(1);print("LAMP ",lamp.get_meta("state"))
	check("Lamp interaction changes shared persisted power state",lamp.get_meta("state").get("on",true)==false and not lamp.get_node("BulbIndicator").visible)
	check("Powered-off lamp emits no local light",lamp.get_node("Bulb").light_energy==0)
	file=FileAccess.open("res://evidence/v5/retained-living-props.json",FileAccess.WRITE);file.store_string(JSON.stringify({"environment":"Actual Godot 4.6.1 / Jolt. Fixture positions and authentic target rays, action validation, meshes, physics and save/restore. Not human gameplay.","results":results},"  "));file.close();var code=1 if results.any(func(r):return not r.passed) else 0;w.queue_free();w=null;a=null;b=null;box=null;book=null;drawer=null;lamp=null;await process_frame;await create_timer(.25).timeout;quit(code)
