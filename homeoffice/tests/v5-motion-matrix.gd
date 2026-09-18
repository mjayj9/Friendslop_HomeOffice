extends SceneTree
var w
var failures=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false);w.host=false;w.add_player("motion-fixture")
	var p=w.players["motion-fixture"];var report={"fixture":true,"modes":{}}
	p.set_meta("authority_grounded",true)
	for mode in ["animation_only","ik_only","combined","remote_interpolation"]:
		p.motion_graph.debug_mode="combined" if mode=="remote_interpolation" else mode
		p.position=Vector3(-1.0,0,9.5);p.velocity=Vector3(0,0,-3.1);p.rotation.y=0
		var clips={};var frames=[]
		for i in 120:
			p.position.z-=3.1/60.0
			p.set_meta("snapshot_tick",i/3)
			p.animate(1.0/60)
			await physics_frame
			clips[p.last_clip]=int(clips.get(p.last_clip,0))+1
			if i%3==0:
				var sample=p.motion_graph.diagnostics();sample.frame=i;sample.ikErrors=p.contact_ik.errors.duplicate()
				for side in ["L","R"]:
					var bone=p.skeleton.find_bone("Foot."+side);var pos=p.skeleton.to_global(p.skeleton.get_bone_global_pose(bone).origin)
					sample["foot"+side]=[pos.x,pos.y,pos.z]
				frames.append(sample)
		report.modes[mode]={"clips":clips,"frames":frames}
		check(not clips.has("v3_land"),mode+" does not repeatedly enter landing")
		check(p.motion_graph.grounded,mode+" uses authority ground state")
		if mode!="ik_only":check(p.motion_graph.locomotion=="walk",mode+" retains locomotion")
	p.position=Vector3(-1,0,9.5);p.velocity=Vector3(0,0,-3.1);p.set_meta("gesture","reload");p.set_meta("gesture_until",Time.get_ticks_msec()+500)
	p.animate(1.0/60);await physics_frame
	check(p.motion_graph.base_clip.begins_with("walk") and p.motion_graph.upper_body=="reload","reload preserves lower-body walking")
	p.set_meta("gesture_until",0);p.set_meta("authority_grounded",false);p.velocity.y=3;p.animate(1.0/60);await physics_frame
	p.set_meta("authority_grounded",true);p.velocity.y=0;p.animate(1.0/60);await physics_frame
	check(p.motion_graph.base_clip=="land","one real airborne-to-ground edge enters landing")
	for i in 30:p.animate(1.0/60);await physics_frame
	check(p.motion_graph.base_clip.begins_with("walk"),"landing finishes and walking resumes")
	report.failures=failures
	FileAccess.open("res://evidence/v5/motion-matrix.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	w.queue_free();w=null;p=null;await process_frame;await create_timer(.2).timeout;quit(0 if failures.is_empty() else 1)
