extends SceneTree
var w
var p
var checks=[]
func _initialize():call_deferred("run")
func check(ok,label):checks.append({"ok":ok,"label":label,"position":w.arr(p.position)});print("PASS " if ok else "FAIL ",label," ",p.position)
func walk(x,z,max_frames=260):
	for i in max_frames:
		var d=Vector2(x-p.position.x,z-p.position.z)
		if d.length()<.18:return true
		p.command={"x":0.0,"z":-1.0,"yaw":atan2(-d.x,-d.y),"pitch":0.0,"jump":false,"run":false,"crouch":false,"seq":i}
		p.simulate(1.0/60);await physics_frame
	return false
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 10:await physics_frame
	w.set_physics_process(false);w.host=true;w.local_id="stairs-fixture";w.add_player(w.local_id);p=w.players[w.local_id]
	p.position=Vector3(17.5,-.17,3.1)
	check(await walk(17.5,-3.1),"Public passage threshold is walkable without jumping")
	for origin in [[10.8,-32.0],[31.7,-18.0]]:
		p.position=Vector3(origin[0]+.8,-3.58,origin[1]+.8)
		for level in range(7):
			var base=-3.6+level*3.6
			check(await walk(origin[0]+.8,origin[1]-3.5),"Flight rises from level "+str(level))
			check(absf(p.position.y-base-1.8)<.12,"Actual half landing height at level "+str(level))
			check(await walk(origin[0]+2.45,origin[1]-3.5),"Half landing turns at level "+str(level))
			check(await walk(origin[0]+2.45,origin[1]+.8),"Return flight reaches next floor "+str(level))
			check(absf(p.position.y-base-3.6)<.12,"Full storey rise at level "+str(level))
			if level<6:check(await walk(origin[0]+.8,origin[1]+.8),"Floor landing connects next flight "+str(level))
		for level in range(6,-1,-1):
			check(await walk(origin[0]+2.45,origin[1]-3.5),"Downward return flight "+str(level))
			check(await walk(origin[0]+.8,origin[1]-3.5),"Downward half landing "+str(level))
			check(await walk(origin[0]+.8,origin[1]+.8),"Downward main flight "+str(level))
			check(absf(p.position.y-(-3.6+level*3.6))<.12,"Descent stops on correct floor "+str(level))
			if level>0:check(await walk(origin[0]+2.45,origin[1]+.8),"Floor landing connects descending flight "+str(level))
	FileAccess.open("res://evidence/v6/stair-route.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":true,"checks":checks},"  "))
	var failed=checks.any(func(c):return not c.ok);w.queue_free();await process_frame;quit(1 if failed else 0)
