extends SceneTree
var w
var checks=[]
var samples=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String,detail={}):
	checks.append({"ok":ok,"label":label,"detail":detail});print("PASS " if ok else "FAIL ",label," ",detail)
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false);w.host=true;w.add_player("seat-fixture")
	var p=w.players["seat-fixture"]
	w.spawn_object({"id":"v5-seat-sofa","kind":"sofa","p":[0,.01,6],"yaw":0,"state":{}})
	var sofa=w.objects["v5-seat-sofa"]
	for i in 2:await physics_frame
	for slot in 3:
		var spec=w.seat_contacts.contact(w,sofa,slot)
		p.position=sofa.global_transform*w.vec(spec.approach);p.rotation.y=PI;p.command.yaw=PI
		await physics_frame
		check(w.seat_contacts.select_slot(w,sofa,p)==slot,"Front approach resolves slot "+str(slot))
		p.position=w.seat_contacts.origin(w,sofa,slot);p.rotation.y=0;p.seat_yaw=0;p.command.yaw=0;p.seated=String(sofa.name);p.seat_index=slot;p.posture="seated"
		sofa.set_meta("seats",{str(slot):p.actor_id})
		for frame in 100:p.simulate(1.0/60);p.animate(1.0/60);await physics_frame
		var bones={}
		for bone in ["Hips","Spine","Thigh.L","Shin.L","Foot.L","Foot.R"]:
			bones[bone]=w.arr(p.skeleton.to_global(p.skeleton.get_bone_global_pose(p.skeleton.find_bone(bone)).origin))
		# Modifier diagnostics capture corrected pose before SkeletonModifier3D resets it.
		var contact=p.contact_ik.contact_samples.duplicate(true)
		check(not contact.is_empty() and contact.L.error<.015 and contact.R.error<.015,"Both feet reach floor contacts "+str(slot),contact)
		check(not p in sofa.get_collision_exceptions() and not sofa in p.get_collision_exceptions(),"Seating keeps furniture collision "+str(slot))
		samples.append({"slot":slot,"root":w.arr(p.position),"bones":bones,"contact":contact})
		check(w.stand_up(p),"Authored exit is safe "+str(slot))
		check(sofa.get_meta("seats",{}).is_empty() and p.posture=="standing","Exit clears occupancy "+str(slot))
		p.simulate(1.0/60)
		check(p.collider.shape.height>1.7,"Standing collider restores "+str(slot))
	p.position=sofa.global_transform*Vector3(0,0,1.1)
	check(w.seat_contacts.select_slot(w,sofa,p)==-1,"Back approach cannot teleport through sofa")
	p.position=sofa.global_transform*w.vec(w.seat_contacts.contact(w,sofa,1).approach);sofa.set_meta("seats",{"1":"another-actor"})
	check(w.seat_contacts.select_slot(w,sofa,p)==-1,"Occupied slot cannot be replaced or silently redirected")
	FileAccess.open("res://evidence/v5/seat-contacts.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":true,"body":"retained default male only; no body-shape acceptance","checks":checks,"samples":samples},"  "))
	var failed=checks.any(func(c):return not c.ok)
	w.queue_free();w=null;p=null;sofa=null;await process_frame;await create_timer(.2).timeout;quit(1 if failed else 0)
