extends SceneTree
var w
var checks=[]
func _initialize():call_deferred("run")
func check(ok,label):checks.append({"ok":ok,"label":label});print("PASS " if ok else "FAIL ",label)
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in 10:await physics_frame
	w.handle_event({"type":"start","host":true,"id":"private-fixture","epoch":"private-fixture"})
	for i in 8:w.member_identity["person-"+str(i)]="device-"+str(i);w.assign_room("person-"+str(i))
	check(w.room_slots.size()==8,"Eight fixed personal room slots have a hard boundary")
	var before={}
	for i in 8:
		var id="office-"+str(i+1)+"-desk";if not w.objects.has(id):check(false,"Missing authored personal furniture "+id);continue
		before[id]=w.objects[id].position
		check(absf(w.objects[id].position.y-10.8)<.04,"Personal desk "+str(i+1)+" is on authored fourth floor")
	for frame in 180:await physics_frame
	check(before.keys().all(func(id):return w.objects[id].position.distance_to(before[id])<.06),"Personal desks settle without pushing into shelves or walls")
	w.member_slots.erase("person-2");w.assign_room("person-2")
	check(before.keys().all(func(id):return w.objects[id].position.distance_to(before[id])<.06),"Leaving and reconnecting never moves existing room furniture")
	var old={"id":"old-personal-book","kind":"book","p":[-3.8,4.5,-16.0],"yaw":0.0,"state":{}}
	var world=w.save_world();world.erase("campusVersion");world.objects=[old];var copy=world.duplicate(true);var migrated=w.migration.prepare(w,world)
	var found=(migrated.objects+migrated.unplaced).filter(func(item):return item.id==old.id)
	check(world==copy and found.size()==1,"Old personal item is copied once with the same identity")
	check(found.size()==1 and absf(found[0].p[1]-11.7)<.01,"Old personal room height maps to fourth floor")
	check(w.migration.prepare(w,migrated)==migrated,"Personal room migration is idempotent")
	FileAccess.open("res://evidence/v6/private-rooms.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":true,"checks":checks},"  "))
	var failed=checks.any(func(c):return not c.ok);w.queue_free();await process_frame;quit(1 if failed else 0)
