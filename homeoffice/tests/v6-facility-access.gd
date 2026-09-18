extends SceneTree
var w
var p
var checks=[]
func _initialize():call_deferred("run")
func check(ok,label):
	checks.append({"ok":ok,"label":label,"position":w.arr(p.position)})
	print("PASS " if ok else "FAIL ",label," ",p.position)
func walk(x,z):
	for i in 180:
		var d=Vector2(x-p.position.x,z-p.position.z)
		if d.length()<.18:return true
		p.command={"x":0.0,"z":-1.0,"yaw":atan2(-d.x,-d.y),"pitch":0.0,"jump":false,"run":false,"crouch":false,"seq":i}
		p.simulate(1.0/60);await physics_frame
	return false
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 10:await physics_frame
	w.set_physics_process(false);w.host=true;w.local_id="facility-fixture";w.add_player(w.local_id);p=w.players[w.local_id]
	for floor in w.campus.data.floors:
		p.position=Vector3(31.8,float(floor.y)+.02,-27.6)
		check(await walk(32,-30),floor.id+" public corridor reaches washroom")
		check(await walk(32,-35.3),floor.id+" accessible aisle reaches back cubicle")
		var id="wc-"+floor.id+"-0"
		check(w.campus.doors.action(w.local_id,id)=="",floor.id+" local washroom door opens")
		for i in 70:await physics_frame
		check(await walk(33.8,-35.3),floor.id+" real capsule enters cubicle without clipping")
		check(await walk(32,-35.3),floor.id+" cubicle exit stays walkable")
	p.position=Vector3(15.5,14.4,-23.3)
	check(w.campus.doors.action(w.local_id,"operations")!="","Simulation host cannot open administrator room")
	p.position=Vector3(13,14.4,-20)
	w.campus.fixture_action(w.local_id,"campus-cctv")
	check(not w.campus.cctv_active,"Simulation host does not activate CCTV")
	check(w.campus.cctv.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Closed unauthorized CCTV never renders")
	FileAccess.open("res://evidence/v6/facility-access.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":true,"checks":checks},"  "))
	var failed=checks.any(func(c):return not c.ok);w.queue_free();await process_frame;quit(1 if failed else 0)
