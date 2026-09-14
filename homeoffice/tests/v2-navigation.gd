extends SceneTree
var w
var actor
var results=[]
func _initialize():call_deferred("run")
func record(name:String,passed:bool,extra={}):
	results.append({"name":name,"passed":passed,"detail":extra})
	print("PASS " if passed else "FAIL ",name," ",extra)
func walk(x:float,z:float):
	var target=Vector3(x,actor.position.y,z)
	var frames=0
	while Vector2(actor.position.x-x,actor.position.z-z).length()>.18 and frames<900:
		var delta=target-actor.position
		actor.command={"x":0.0,"z":-1.0,"yaw":atan2(-delta.x,-delta.z),"pitch":0.0,"run":false,"jump":false,"crouch":false,"seq":frames}
		actor.last_input_ms=Time.get_ticks_msec()
		await physics_frame
		frames+=1
	actor.command.z=0.0
	var okay=Vector2(actor.position.x-x,actor.position.z-z).length()<.3
	if not okay:record("walk waypoint",false,{"target":[x,z],"actual":w.arr(actor.position)})
	return okay
func run():
	w=load("res://scripts/v2/world.gd").new()
	root.add_child(w)
	await physics_frame
	actor=w.players.local
	w.local_id="test-controller"
	for i in range(60):await physics_frame
	record("Godot V2 actual initialization",w.objects.size()>=60)
	var fixed=w.objects["office-1-desk"].position
	for i in range(1,8):w.add_player("test-"+str(i))
	record("2/4/8 append-only office assignment",w.room_slots.size()==8 and w.objects["office-1-desk"].position==fixed,{"rooms":w.room_slots.size()})
	# Other test actors stay at entrance, so remove their colliders from the navigation course.
	for id in w.players.keys():
		if id!="local":w.players[id].collision_layer=0
	var routes=[
		["living",[[0,11],[-6,10.8],[-10,10.8]]],
		["terrace",[[-10,13.3],[-10,16]]],
		["basketball",[[-10,20],[-7,24],[-7,29]]],
		["football",[[-7,20],[25,20],[25,25]]],
		["kitchen",[[25,20],[0,20],[0,13.5],[-1.8,13.5],[-1.8,11.2],[0,11],[0,-6.5],[-6,-6.5],[-7,-6.5]]],
		["dining",[[-6.8,-4],[-6.8,0]]],
		["meeting",[[-2,0],[0,7],[3,7],[3,10]]],
		["free",[[3,7],[0,7],[0,-2],[3,-2],[12,-2],[14,0]]],
		["game",[[18,0],[22,0],[24,0]]],
		["stairs",[[22,0],[18,0],[12,0],[12,-2],[0,-2],[0,11],[-4.15,11],[-4.15,6.4],[-2.35,6.4],[-2.35,11]]],
		["upper gallery",[[0,11],[0,-13],[0,-30]]],
		["office 8",[[0,-30.9],[2.7,-30.9]]],
		["sleep",[[0,-30.9],[0,-8],[-6,-8],[-9,-8]]],
		["reading",[[-6,-8],[0,-8],[0,0],[-6,0],[-10,0]]]
	]
	w.door_states["game-gate"]=true
	for route in routes:
		var okay=true
		for point in route[1]:
			if not await walk(point[0],point[1]):okay=false;break
		record("Continuous physical route: "+route[0],okay,{"position":w.arr(actor.position),"zone":w.zone_at(actor.position)})
		if not okay:break
	var f=FileAccess.open("res://evidence/v2-navigation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"environment":"Godot 4.6.1 Jolt headless actual CharacterBody motor, fixed ticks, input commands; not browser or human test","results":results},"  "))
	f.close()
	quit(1 if results.any(func(r):return not r.passed) else 0)
