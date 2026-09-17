extends SceneTree
var w
var p
var order=1000
var results=[]
func _initialize():call_deferred("run")
func check(name:String,passed:bool,detail={}):
	results.append({"name":name,"passed":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",name," ",detail)
func action(kind:String,data={}):
	order+=1
	w.perform("local",{"actor":"local","requestId":"local:"+str(order),"targetId":"","epoch":w.epoch,"seq":order,"action":kind,"data":data})
func at(pos:Vector3,target:Vector3):
	p.position=pos
	p.velocity=Vector3.ZERO
	var d=target-p.eye()
	p.command.yaw=atan2(-d.x,-d.z)
	p.command.pitch=atan2(d.y,Vector2(d.x,d.z).length())
	p.last_input_ms=Time.get_ticks_msec()
func ticks(n:int):
	for i in range(n):await physics_frame
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w);await ticks(10);p=w.players.local;w.local_id="test-controller"
	at(Vector3(-13.8,0,-6.5),Vector3(-13.8,1,-8.6));action("use")
	check("fridge gives one visible held ingredient",p.holding.begins_with("ingredient-"))
	at(Vector3(-11,0,-7),Vector3(-11,.7,-8.8));action("use")
	check("cooker consumes ingredient once and starts cooking",p.holding=="" and w.objects["cook-station"].get_meta("state").has("cooking"))
	await ticks(380)
	check("actual cooking timer reaches ready",w.objects["cook-station"].get_meta("state").get("ready",false))
	action("use");await ticks(5)
	var food_id=""
	for id in w.objects:
		if w.definitions[id].kind=="meal":food_id=id
	check("cooked physical food appears",food_id!="")
	if food_id!="":
		at(Vector3(-11,0,-7),w.objects[food_id].position);action("carry");await ticks(5)
		check("cooked food can be picked up",p.holding==food_id)
		at(Vector3(-10.2,0,-4),Vector3(-10.2,.6,-5.7));action("use")
		check("counter plates food as shared object state",w.objects["plate-1"].get_meta("state").get("food",false))
		at(Vector3(-9.8,0,-4.2),w.objects["plate-1"].position);action("carry");await ticks(3)
		check("plate can be carried",p.holding=="plate-1")
		at(Vector3(-10.38,0,2.5),Vector3(-10.38,.46,1.05));action("use")
		check("sit while carrying food",p.seated=="dining-chair-1" and p.holding=="plate-1")
		action("eat");action("eat")
		check("food consumed only once leaves dirty plate",w.objects["plate-1"].get_meta("state")=={"food":false,"dirty":true})
		action("use")
		check("F stands before table interaction while holding a plate",p.seated=="" and p.posture=="standing")
		at(Vector3(-7.8,0,-7),Vector3(-7.8,.7,-8.8));action("use")
		check("sink clears dirty physical plate",w.objects["plate-1"].get_meta("state")=={"food":false,"dirty":false})
	if p.holding!="":w.release(p,false)
	if p.seated!="":w.clear_seat(p)
	at(Vector3(-13.7,3.6,-8.6),Vector3(-13.7,4.1,-10.3));action("use")
	check("bed enters lying state",p.posture=="lying" and p.seated=="bed-0")
	action("rest");check("sleep is an individual explicit state",p.posture=="sleeping")
	action("use");check("wake finds safe standing location",p.seated=="" and p.posture=="standing")
	# Exact engine crossing samples isolate scoring logic; these are not browser shot demonstrations.
	w.rounds.basketball.phase="practice"
	var ball=w.objects.basketball;ball.freeze=true;ball.position=Vector3(-16.35,2.99,30);ball.linear_velocity=Vector3(0,-3,0);w.ball_previous.basketball=Vector3(-16.35,3.12,30);w.update_sports(1.0/60)
	check("basket downward crossing scores once",w.basketball_score==[0,2]);w.update_sports(1.0/60);check("duplicate basket sample does not score",w.basketball_score==[0,2])
	ball.position=Vector3(-16.35,3.12,30);ball.linear_velocity=Vector3(0,3,0);w.ball_previous.basketball=Vector3(-16.35,2.9,30);w.update_sports(1.0/60);check("upward crossing rejected",w.basketball_score==[0,2])
	at(Vector3(23,0,-2),w.objects["tag-gun-1"].position);action("carry");check("Toy gun pickup needs no individual permission",p.holding=="tag-gun-1")
	w.update_living(0);check("Living tick preserves current gun ownership",p.holding=="tag-gun-1")
	at(Vector3(5,0,6),Vector3(6,1,6));w.objects[p.holding].position=p.eye()+p.direction()*.43
	var before=w.shot_serial;w.fire_tag("local");check("Meeting room accepts free fire",w.shot_serial==before+1)
	var file=FileAccess.open("res://evidence/v4/legacy-interactions.json",FileAccess.WRITE);file.store_string(JSON.stringify({"environment":"Actual Godot/Jolt engine. Direct fixture positions and action requests; scoring uses controlled crossing samples. Not browser/manual validation.","results":results},"  "));file.close();var code=1 if results.any(func(r):return not r.passed) else 0;w.queue_free();w=null;p=null;ball=null;await process_frame;await create_timer(.25).timeout;quit(code)
