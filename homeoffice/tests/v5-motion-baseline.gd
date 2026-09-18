extends SceneTree
var w
func _initialize():call_deferred("run")
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 8:await physics_frame
	w.set_physics_process(false);w.add_player("remote-motion-fixture")
	var p=w.players["remote-motion-fixture"];p.position=Vector3(0,0,0);p.velocity=Vector3(0,0,-3.1)
	p.set_meta("authority_grounded",true)
	var clips={};var transitions=0;var previous="";var frames=[]
	for i in 120:
		p.position.z-=3.1/60.0;p.animate(1.0/60)
		await physics_frame
		clips[p.last_clip]=int(clips.get(p.last_clip,0))+1
		if p.last_clip!=previous:transitions+=1;previous=p.last_clip
		if i%6==0:frames.append({"frame":i,"clip":p.last_clip,"localFloorQuery":p.is_on_floor(),"authorityGrounded":true,"phase":p.animator.current_animation_position/maxf(.001,p.animator.current_animation_length),"ikErrors":p.contact_ik.errors.duplicate()})
	var report={"fixture":"Remote position interpolation, constant ground truth grounded=true and 3.1m/s. Character does not call move_and_slide, as in real remote path.","clips":clips,"transitions":transitions,"frames":frames}
	FileAccess.open("res://evidence/v5/motion-before.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MOTION_BASELINE ",clips);w.queue_free();w=null;p=null;await process_frame;await create_timer(.2).timeout;quit()
