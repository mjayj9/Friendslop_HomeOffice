extends SceneTree
var w
var checks=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	checks.append({"ok":ok,"label":label});print("PASS " if ok else "FAIL ",label)
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false);w.host=true;w.epoch="placement-fixture";w.local_id="placement-fixture";w.add_player(w.local_id)
	var p=w.players[w.local_id];p.position=Vector3(-8.8,0,7.8)
	var point=Vector3(-7.5,0,8)
	check(w.placement_ok(p,"chair",point,0),"Empty supported living-room floor accepts chair")
	check(not w.placement_ok(p,"chair",Vector3(0,0,10.5),0),"Public corridor stays clear")
	p.position=Vector3(-10.5,0,10.5)
	check(not w.placement_clearance.valid(w,p,"table",Vector3(-11,0,12),0),"Open terrace door reserves its passage")
	var sofa_id=""
	for object_id in w.definitions:
		if w.definitions[object_id].kind=="sofa":sofa_id=object_id;break
	var sofa=w.objects[sofa_id]
	var approach=sofa.global_transform*Vector3(0,0,-.95)
	p.position=approach+Vector3(2,0,0)
	check(not w.placement_clearance.valid(w,p,"chair",approach,sofa.rotation.y),"Sofa approach stays clear")
	p.position=Vector3(-8.8,0,7.8)
	check(not w.placement_ok(p,"chair",point+Vector3.UP,0),"Unsupported floating furniture is rejected")
	p.position=Vector3(0,0,26)
	check(not w.placement_ok(p,"chair",Vector3(0,0,27),0),"Administrator court cannot be bypassed by placement")
	p.position=Vector3(-8.8,0,7.8);p.camera.global_position=p.eye();p.camera.look_at(point)
	w.placement_pointer.handle(w,{"phase":"begin","token":"11111111-1111-4111-8111-111111111111","kind":"chair"})
	w.placement_pointer.handle(w,{"phase":"move","token":w.placement_pointer.token,"u":.5,"v":.5,"inside":true,"angle":0,"snap":false})
	check(w.build_valid and w.build_point.distance_to(point)<.04,"Screen-centre ray hits actual chosen support")
	var before=w.objects.size()
	w.placement_pointer.handle(w,{"phase":"cancel","token":w.placement_pointer.token})
	check(w.objects.size()==before and w.build_kind=="","Cancel removes preview without spawning")
	var m={"type":"action","actor":p.actor_id,"epoch":w.epoch,"requestId":"placement-fixture:place:unique-drop","seq":1,"targetId":"","action":"place","data":{"kind":"chair","p":w.arr(point),"yaw":0,"objectId":""}}
	w.perform(p.actor_id,m);await physics_frame
	check(w.objects.size()==before+1,"Valid authoritative drop creates exactly one object")
	w.perform(p.actor_id,m);await physics_frame
	check(w.objects.size()==before+1 and w.command_results.duplicates==1,"Duplicate request returns cached result without a second object")
	FileAccess.open("res://evidence/v5/placement.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":true,"checks":checks},"  "))
	var failed=checks.any(func(c):return not c.ok)
	w.queue_free();w=null;p=null;await process_frame;await create_timer(.2).timeout;quit(1 if failed else 0)
