extends SceneTree
var failures=[]
var results=[]
func check(ok:bool,label:String):
	results.append({"test":label,"passed":ok})
	if not ok:failures.append(label)
	print("PASS " if ok else "FAIL ",label)
func _initialize():run.call_deferred()
func run():
	var world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	world.set_physics_process(false)
	world.add_player("guest")
	var a=world.players.local
	var b=world.players.guest
	a.position=Vector3(8.65,0,3)
	b.position=Vector3(8.65,0,3)
	a.command.yaw=0.0;a.command.pitch=-.42
	b.command.yaw=0.0;b.command.pitch=-.42
	await physics_frame
	check(world.target(a).get("id")=="chair-0","T08 real physics ray selects chair at valid range")
	world.perform("local",{"epoch":world.epoch,"seq":1,"action":"interact"})
	world.perform("guest",{"epoch":world.epoch,"seq":1,"action":"interact"})
	check(a.seated=="chair-0" and b.seated=="","T05 simultaneous seat requests give one owner")
	a.position=Vector3(0,0,3);a.seated=""
	world.objects["chair-0"].set_meta("occupant","")
	var before=world.door_open
	world.perform("guest",{"epoch":"old-session","seq":2,"action":"interact"})
	check(world.door_open==before,"T15 stale epoch cannot mutate world")
	check(not world.valid_input({"x":1000,"z":0,"yaw":0,"pitch":0,"seq":2,"jump":false,"run":false}),"T15 exaggerated movement input rejected")
	check(not world.valid_input({"x":0,"z":0,"yaw":0,"pitch":NAN,"seq":2,"jump":false,"run":false}),"T15 nonfinite input rejected")
	a.position=Vector3(2,0,-.2);b.position=Vector3(2,0,-.2)
	a.command.pitch=-.62;b.command.pitch=-.62
	await physics_frame
	check(world.target(a).get("id")=="crate-1","T08 actual ray reaches crate")
	world.perform("local",{"epoch":world.epoch,"seq":3,"action":"interact"})
	world.perform("guest",{"epoch":world.epoch,"seq":3,"action":"interact"})
	check(a.holding=="crate-1" and b.holding=="","T05 simultaneous pickup gives one owner")
	world.update_held(.016)
	check(world.objects["crate-1"].linear_velocity.length()<=7.01,"T07 held body velocity bounded")
	world.perform("local",{"epoch":world.epoch,"seq":4,"action":"throw"})
	check(a.holding=="" and world.objects["crate-1"].linear_velocity.length()>5,"T07 throwing releases ownership and physical velocity")
	var count=world.strokes.size()
	world.perform("guest",{"epoch":world.epoch,"seq":5,"action":"stroke","data":{"points":[[0,0],[1,1]],"width":4,"color":"#183b32"}})
	check(world.strokes.size()==count,"T08 remote board editing blocked by distance")
	a.position=Vector3(9,0,-2.5);b.position=Vector3(10,0,-2.5)
	await physics_frame
	for entry in [["local",6],["guest",6]]:
		world.perform(entry[0],{"epoch":world.epoch,"seq":entry[1],"action":"stroke","data":{"points":[[.1,.1],[.5,.5]],"width":4,"color":"#183b32"}})
	check(world.strokes.size()==count+2,"T28 both authors' board strokes survive")
	world.perform("local",{"epoch":world.epoch,"seq":7,"action":"undo"})
	check(world.strokes.size()==count+1 and world.strokes[-1].author=="guest","T28 author Undo preserves other's stroke")
	var saved=world.save_world()
	world.restore_world(saved)
	check(world.objects.size()==saved.objects.size() and world.strokes==saved.board,"T42 furniture and board restore in actual engine")
	check(a.holding=="" and a.seated=="" and b.holding=="" and b.seated=="","T43 restore resets runtime occupancy")
	var file=FileAccess.open("res://evidence/host-physics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info(),"backend":ProjectSettings.get_setting("physics/3d/physics_engine"),"scope":"headless actual physics + handler tests; not multi-browser or microphone proof","results":results},"\t"))
	quit(0 if failures.is_empty() else 1)
