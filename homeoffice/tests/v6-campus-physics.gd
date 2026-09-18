extends SceneTree
var w
var checks=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String,detail={}):
	checks.append({"ok":ok,"label":label,"detail":detail});print("PASS " if ok else "FAIL ",label," ",detail)
func frames(count):
	for i in count:await physics_frame
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w);await frames(10)
	w.handle_event({"type":"start","host":true,"id":"lift-fixture","epoch":"v6-physics-fixture"})
	var p=w.players[w.local_id];var lifts=w.campus.lifts;var car=lifts.cars.passenger
	check(w.campus.floor_nodes.size()==8,"All eight authored storeys instantiate")
	check(lifts.request(w.local_id,"passenger","RF")!="","Remote floor request cannot call a car")
	p.position=Vector3(22.8,.03,-31.25);await frames(5)
	check(lifts.request(w.local_id,"passenger","1F")=="","Physical lobby call accepted")
	await frames(75)
	check(car.open>.98,"Car and occupied landing open together",lifts.snapshot().passenger)
	p.position=Vector3(21,.04,-34.2);await frames(20)
	check(lifts.occupants(car).has(p.actor_id),"Character is inside real cabin")
	check(lifts.request(w.local_id,"passenger","2F")=="","Cabin accepts destination")
	lifts.request(w.local_id,"passenger","2F")
	check(car.queue.count("2F")==1,"Repeated destination is queued only once")
	await frames(680)
	check(car.floor=="2F" and car.open>.98,"Car completes a trip and opens at 2F",lifts.snapshot().passenger)
	check(absf(p.position.y-3.6)<.08,"Character rides AnimatableBody without extra position offset",{"position":w.arr(p.position)})
	check(lifts.request(w.local_id,"passenger","3F")=="","Next destination accepted before obstruction")
	p.position=Vector3(21,3.62,-33.28);car.elapsed=6;await frames(90)
	check(car.state in ["OPEN","OPENING"] and car.queue.has("3F"),"Door obstruction reopens and preserves destination",lifts.snapshot().passenger)
	var checkpoint=lifts.snapshot();lifts.restore(checkpoint,true)
	check(car.queue.has("3F") and car.floor=="2F","Handoff preserves queued trip without opening another landing")
	var source=w.save_world();source.erase("campusVersion");source.objects=[{"id":"kept-book","kind":"book","p":[0,.7,6],"yaw":0,"state":{}},{"id":"blocked-chair","kind":"chair","p":[21,0,-34.8],"yaw":0,"state":{}}]
	var unchanged=source.duplicate(true);var migrated=w.migration.prepare(w,source)
	check(source==unchanged,"Migration leaves source unchanged")
	check(migrated.objects.any(func(o):return o.id=="kept-book") and migrated.unplaced.any(func(o):return o.id=="blocked-chair"),"Conflicting furniture keeps its ID in unplaced storage")
	check(w.migration.prepare(w,migrated)==migrated,"Migration is idempotent")
	FileAccess.open("res://evidence/v6/campus-physics.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":true,"checks":checks},"  "))
	var failed=checks.any(func(c):return not c.ok);w.queue_free();await process_frame;quit(1 if failed else 0)
