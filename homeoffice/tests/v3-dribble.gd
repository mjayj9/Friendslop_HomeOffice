extends SceneTree
var w
func _initialize():call_deferred("run")
func run():
	w=load("res://scripts/v3/world.gd").new();root.add_child(w)
	for i in range(10):await physics_frame
	var p=w.players.local;w.local_id="fixture-controller"
	p.position=Vector3(-7,0,30);p.command.yaw=0;p.command.pitch=0;p.holding="basketball";p.set_meta("dribble",true)
	var ball=w.objects.basketball;ball.position=Vector3(-7,1.2,29.4);ball.set_meta("owner","local");ball.gravity_scale=1;ball.linear_velocity=Vector3(0,-5.5,0)
	ball.add_collision_exception_with(p);p.add_collision_exception_with(ball)
	var height_min=100.0;var height_max=0.0;var speed_max=0.0;var bounces=0;var previous_v=-5.5
	for i in range(420):
		await physics_frame
		height_min=minf(height_min,ball.position.y);height_max=maxf(height_max,ball.position.y);speed_max=maxf(speed_max,ball.linear_velocity.length())
		if previous_v < -1 and ball.linear_velocity.y>1:bounces+=1
		previous_v=ball.linear_velocity.y
	var passed=bounces>=3 and height_min>.10 and height_max<2.0 and speed_max<=8.1 and p.holding=="basketball"
	var result={"environment":"Actual Godot/Jolt fixed physics ticks; controlled player/ball initial fixture; no render animation driving ball Y.","passed":passed,"bounces":bounces,"minY":height_min,"maxY":height_max,"maxSpeed":speed_max}
	FileAccess.open("res://evidence/v3/dribble.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("DRIBBLE ",result);w.queue_free();w=null;p=null;ball=null;await process_frame;await create_timer(.25).timeout;quit(0 if passed else 1)
