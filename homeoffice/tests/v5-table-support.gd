extends SceneTree
var world
var results=[]
func _initialize():call_deferred("run")
func check(label:String,ok:bool,details={}):
	results.append({"name":label,"passed":ok,"details":details});print("PASS " if ok else "FAIL ",label," ",details)
func run():
	world=load("res://scripts/v3/world.gd").new();root.add_child(world)
	for i in 180:await physics_frame
	for id in ["living-low-table","reading-table","dining-table"]:
		var base=3.6 if id=="reading-table" else 0.0
		check(id+" rests on supports",absf(world.objects[id].position.y-base)<.015,{"originY":world.objects[id].position.y,"expected":base})
	var saved=world.save_world();var original=saved.duplicate(true)
	for item in saved.objects:
		if item.id=="living-low-table":item.p=[-10.4,-.381,6.3]
		if item.id=="living-book":item.p=[-10.4,.119,6.3]
	var before_count=saved.objects.size();world.restore_world(saved)
	for i in 45:await physics_frame
	check("Legacy buried table and supported book recover together",absf(world.objects["living-low-table"].position.y)<.015 and world.objects["living-book"].position.y>.44,{"tableY":world.objects["living-low-table"].position.y,"bookY":world.objects["living-book"].position.y})
	check("Repair preserves IDs, room slots and board",world.objects.size()==before_count and world.room_slots==original.roomSlots and world.strokes==original.board)
	check("Restore does not mutate the imported source",saved.objects.filter(func(d):return d.id=="living-low-table")[0].p[1]==-.381)
	var corrected=world.save_world();world.restore_world(corrected)
	for i in 45:await physics_frame
	check("Repair is idempotent",absf(world.objects["living-low-table"].position.y)<.015 and world.furniture_support.adjustments.is_empty())
	var report={"environment":"Actual Godot 4.6.1/Jolt physics; synthetic legacy save fixture, not human acceptance", "build":JSON.parse_string(FileAccess.get_file_as_string("res://assets/build-version.json")),"results":results}
	FileAccess.open("res://evidence/v5/table-support.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	var ok=results.all(func(r):return r.passed);world.queue_free();world=null;await process_frame;await create_timer(.2).timeout;quit(0 if ok else 1)
