extends SceneTree
var w
var checks=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String,detail={}):
	checks.append({"ok":ok,"label":label,"detail":detail});print("PASS " if ok else "FAIL ",label," ",detail)
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false);w.host=true;w.add_player("carry-fixture")
	var p=w.players["carry-fixture"];p.position=Vector3(0,0,6);p.command.yaw=0;p.set_meta("authority_grounded",true)
	w.spawn_object({"id":"v5-carry-chair","kind":"chair","p":[0,.015,5.1],"yaw":0,"state":{}})
	var chair=w.objects["v5-carry-chair"];chair.freeze=false;chair.set_meta("owner",p.actor_id);p.holding=String(chair.name);chair.gravity_scale=0
	var min_distance=99.0;var samples=[]
	for i in 120:
		w.update_held(1.0/60);p.animate(1.0/60);await physics_frame
		var local=chair.to_local(p.global_position);var box=w.furniture_carry.bounds(chair)
		var dx=local.x-clampf(local.x,box.position.x,box.end.x);var dz=local.z-clampf(local.z,box.position.z,box.end.z)
		min_distance=minf(min_distance,Vector2(dx,dz).length())
		if i%6==0:samples.append({"frame":i,"chair":w.arr(chair.position),"trace":w.furniture_carry.traces.get(p.actor_id,{}).duplicate(true),"handErrors":p.contact_ik.errors.duplicate()})
	check(chair.position.y>.3,"Chair lifts at authored two-hand grip height",{"position":w.arr(chair.position)})
	check(min_distance>=.27,"Entire chair envelope stays outside carrier capsule",{"minimumDistance":min_distance})
	check(not p in chair.get_collision_exceptions() and not chair in p.get_collision_exceptions(),"Furniture retains collision with its holder")
	var before=chair.position;p.command.yaw=PI
	for i in 20:w.update_held(1.0/60);await physics_frame
	check(chair.position.z<5.8,"Fast reversal cannot carry chair straight through torso",{"before":w.arr(before),"after":w.arr(chair.position)})
	var checkpoint=w.make_checkpoint()
	w.apply_checkpoint({"host":true,"epoch":"carry-handoff","checkpoint":checkpoint})
	chair=w.objects["v5-carry-chair"]
	check(not p in chair.get_collision_exceptions() and not chair in p.get_collision_exceptions(),"Handoff does not reintroduce furniture-holder collision exceptions")
	w.release(p,false);await physics_frame
	check(p.holding=="" and chair.get_meta("owner")=="" and chair.gravity_scale==1,"Release restores owner and gravity without leftover exceptions")
	FileAccess.open("res://evidence/v5/carry-volume.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":true,"checks":checks,"samples":samples},"  "))
	var failed=checks.any(func(c):return not c.ok)
	w.queue_free();w=null;p=null;chair=null;await process_frame;await create_timer(.2).timeout;quit(1 if failed else 0)
