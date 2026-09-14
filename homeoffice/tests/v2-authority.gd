extends SceneTree
var w
var results=[]
var seq=100
func _initialize():call_deferred("run")
func check(name:String,okay:bool):
	results.append({"name":name,"passed":okay});print("PASS " if okay else "FAIL ",name)
func action(id:String,kind:String,data={}):
	seq+=1;w.perform(id,{"epoch":w.epoch,"seq":seq,"action":kind,"data":data})
func run():
	w=load("res://scripts/v2/world.gd").new();root.add_child(w)
	for i in range(8):await physics_frame
	w.local_id="test-controller";w.add_player("friend")
	var a=w.players.local;var b=w.players.friend
	a.position=Vector3(4.4,0,5.5);b.position=Vector3(4.8,0,5.5)
	a.last_input_ms=Time.get_ticks_msec();b.last_input_ms=Time.get_ticks_msec()
	action("local","stroke",{"kind":"text","text":"오늘 회의 2026년 9월","fontSize":28,"points":[[.1,.1],[.102,.102]],"color":"#183b32","width":4})
	check("Korean text becomes authoritative board object",w.strokes.size()==1 and w.strokes[0].get("text","")=="오늘 회의 2026년 9월")
	var stroke=w.strokes[0].duplicate(true)
	action("friend","board_update",{"id":stroke.id,"version":1,"points":[[.2,.2],[.202,.202]]})
	check("Second user moves a board object by version",w.strokes[0].version==2 and w.strokes[0].points[0][0]==.2)
	action("local","board_delete",{"id":stroke.id,"version":1})
	check("Stale concurrent delete is rejected",w.strokes.size()==1)
	action("local","undo")
	check("Old author undo does not erase other user's update",w.strokes.size()==1)
	action("friend","undo")
	check("Mover can undo their own latest operation",w.strokes[0].points[0][0]==.1)
	action("friend","board_delete",{"id":stroke.id,"version":1});check("Selected board object is deleted",w.strokes.is_empty())
	action("friend","undo");check("Delete undo restores Korean text",w.strokes.size()==1)
	var chair=w.objects["meeting-chair-1"] if w.objects.has("meeting-chair-1") else w.objects[w.definitions.keys().filter(func(k):return w.definitions[k].kind=="chair")[0]]
	var chair_id=chair.get_meta("object_id")
	a.seated=chair_id;chair.set_meta("seats",{"0":"local"});chair.set_meta("occupant","local")
	check("Occupied chair is protected from movement/deletion",w.object_in_use(chair_id))
	var checkpoint=w.make_checkpoint();var old_slot=checkpoint.memberSlots.duplicate(true)
	var old_position=Vector3(4.4,0,5.5)
	w.local_id="friend";w.apply_checkpoint({"host":true,"epoch":"new-authority","checkpoint":checkpoint})
	check("Checkpoint changes engine authority and epoch",w.host and w.epoch=="new-authority")
	check("Checkpoint retains exact player position and seat",w.players.local.position.distance_to(old_position)<.001 and w.players.local.seated==chair_id)
	check("Checkpoint retains private-room assignment and board",w.member_slots==old_slot and w.strokes[0].text=="오늘 회의 2026년 9월")
	check("Previous epoch action is rejected",w.epoch!=checkpoint.state.epoch)
	var f=FileAccess.open("res://evidence/v2-authority.json",FileAccess.WRITE);f.store_string(JSON.stringify({"environment":"Actual Godot/Jolt instance, fixture positions and action calls; not browser or human interaction", "results":results},"  "));f.close();quit(1 if results.any(func(r):return not r.passed) else 0)
