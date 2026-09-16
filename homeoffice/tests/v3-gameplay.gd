extends SceneTree
var w
var order=10000
var results=[]
func _initialize():call_deferred("run")
func check(label:String,okay:bool):
	results.append({"name":label,"passed":okay});print("PASS " if okay else "FAIL ",label)
func command(actor:String,action:String,data={}):
	order+=1;w.perform(actor,{"epoch":w.epoch,"actor":actor,"requestId":actor+":"+str(order),"targetId":"","seq":order,"action":action,"data":data})
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in range(6):await physics_frame
	w.set_physics_process(false)
	for i in range(150):await physics_frame
	check("Movable chair has floor collision and remains stable",absf(w.objects["living-chair"].position.y)<.05 and w.objects["living-chair"].linear_velocity.length()<.1)
	var a=w.players.local
	check("Imported real male mesh has opaque visible materials",a.standing.find_children("*","MeshInstance3D",true,false)[0].get_active_material(0).albedo_color.a>.99)
	check("62 authored Blender animation clips load",a.animator and a.animator.get_animation_list().size()>=62)
	check("Default tag is immediately Practice",w.rounds.tag.phase=="practice")
	w.add_player("friend");w.entry_grants.friend=true;w.weapon_grants.local=true;w.weapon_grants.friend=true
	a.position=Vector3(25,0,-4);a.command.yaw=0.;a.command.pitch=0.
	var b=w.players.friend;b.position=Vector3(25,0,-7)
	for id in w.objects:
		if w.definitions[id].kind=="gun":a.holding=id;w.objects[id].set_meta("owner","local");w.objects[id].position=a.eye()+Vector3(0,0,-.6);break
	var gun=w.objects[a.holding]
	for i in range(20):
		var state=gun.get_meta("state",{});state.nextShot=0;gun.set_meta("state",state);w.fire_tag("local")
	check("Practice accepts >12 shots without reloading",w.shot_serial>=13)
	var before=w.shot_serial;w.weapon_grants.local=false;w.fire_tag("local");check("Revoked permission rejects fire",w.shot_serial==before)
	w.weapon_grants.local=true
	var combat=load("res://scripts/combat/combat_state.gd").new()
	for i in 4:combat.damage("a","b",1000+i)
	check("Four accepted hits cause KO and one kill",combat.fighters.b.hp==0 and combat.fighters.a.kills==1 and combat.fighters.a.meter==25)
	combat.damage("a","b",1010);check("KO cannot be scored twice",combat.fighters.a.kills==1)
	check("Timed respawn restores HP and adds protection",combat.advance(5000,.016)==["b"] and combat.fighters.b.hp==100 and not combat.damage("a","b",5001).accepted)
	combat.advance(22000,1);check("Kill gauge decays after inactivity",combat.fighters.a.meter<25)
	w.release(a,false)
	var ball=w.objects.basketball
	for child in ball.get_children():
		if child is CollisionShape3D and child.shape is SphereShape3D:check("Basketball collider radius 0.12m",is_equal_approx(child.shape.radius,.12))
	a.position=Vector3(-7,0,30);a.command.pitch=.6;a.holding="basketball";ball.set_meta("owner","local")
	command("local","trigger_down");a.set_meta("charge_started",Time.get_ticks_msec()-900);command("local","trigger_up")
	check("Charged release frees ball and applies real backspin",a.holding=="" and ball.angular_velocity.length()>7 and ball.linear_velocity.y>0)
	var profile=load("res://scripts/sports/ball_profile.gd")
	check("Hoop accepts descending centre and rejects rising/edge",profile.basket_crossing(Vector3(0,4,0),Vector3(0,2,0),Vector3(0,3,0)) and not profile.basket_crossing(Vector3(0,2,0),Vector3(0,4,0),Vector3(0,3,0)) and not profile.basket_crossing(Vector3(.2,4,0),Vector3(.2,2,0),Vector3(0,3,0)))
	w.handle_event({"type":"visibility","hidden":true});check("Document tab switch does not deliberately freeze host",not w.frozen)
	var file=FileAccess.open("res://evidence/v3/gameplay-tests.json",FileAccess.WRITE);file.store_string(JSON.stringify({"environment":"Godot headless engine with controlled fixture positions; not UI/human acceptance","results":results},"  "))
	file.close();file=null
	var okay=results.all(func(r):return r.passed)
	a=null;b=null;gun=null;ball=null;combat=null;profile=null
	w.queue_free();w=null;await process_frame;await create_timer(.25).timeout;quit(0 if okay else 1)
