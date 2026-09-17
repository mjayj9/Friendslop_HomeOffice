extends SceneTree
func _initialize():call_deferred("run")
func run():
	var lab=load("res://scripts/physics/verification_lab.gd").new();root.add_child(lab)
	for i in range(360):await physics_frame
	var basketball=0.0;var football=0.0;var hit_basket=false;var hit_football=false;var max_x=0.0
	for sample in lab.samples:
		if sample.basket_drop.p[1]<.16:hit_basket=true
		if sample.football_drop.p[1]<.15:hit_football=true
		if hit_basket:basketball=maxf(basketball,sample.basket_drop.p[1])
		if hit_football:football=maxf(football,sample.football_drop.p[1])
		max_x=maxf(max_x,sample.ccd.p[0])
	var results=[{"name":"Basketball bounces without gaining energy","passed":hit_basket and basketball>.6 and basketball<2.7,"firstReboundMaxM":basketball},{"name":"Football has lower restitution than basketball","passed":hit_football and football>.2 and football<basketball,"reboundMaxM":football},{"name":"14m/s CCD ball stays on near side of 6cm wall","passed":max_x<8.05,"maxXM":max_x},{"name":"Both balls remain above the floor after 6 seconds","passed":lab.objects.basket_drop.position.y>.07 and lab.objects.football_drop.position.y>.06}]
	var file=FileAccess.open("res://evidence/v4/physics-lab.json",FileAccess.WRITE);file.store_string(JSON.stringify({"environment":"Godot 4.6.1 Jolt headless 60Hz, controlled independent physics scene, no user input simulation claim","results":results,"samples":lab.samples},"  "));file.close()
	var okay=results.all(func(r):return r.passed)
	for r in results:print("PASS " if r.passed else "FAIL ",r.name)
	lab.queue_free();lab=null;await process_frame;quit(0 if okay else 1)
