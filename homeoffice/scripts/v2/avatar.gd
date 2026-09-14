extends "res://scripts/avatar.gd"

var nickname="친구"
var name_label:Label3D
var lying:Node3D
var hands:Node3D
var hand_skeleton:Skeleton3D
var posture="standing"
var seat_index=0
var crouching=false
var collider:CollisionShape3D

func _ready():
	super._ready()
	for n in get_children():
		if n is CollisionShape3D:collider=n
	name_label=Label3D.new()
	name_label.font=load("res://assets/fonts/NotoSansKR-game.ttf")
	name_label.font_size=40;name_label.pixel_size=.003
	name_label.position.y=2.0;name_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test=false;name_label.visible=not local_player
	add_child(name_label)
	camera.far=125
	command.crouch=false
	lying=load("res://assets/characters/male-lying.glb").instantiate()
	add_child(lying)
	lying.visible=false
	hands=load("res://assets/characters/male-arms.glb").instantiate()
	hands.rotation.y=PI
	add_child(hands)
	hand_skeleton=find_skeleton(hands)
	hands.visible=false

func eye() -> Vector3:
	var h=.92 if posture in ["lying","sleeping"] else (1.25 if seated!="" else (1.10 if crouching else 1.62))
	return global_position+Vector3(0,h,0)

func simulate(dt:float):
	var want=bool(command.get("crouch",false))
	if not want and crouching:
		var query=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,global_position+Vector3.UP*1.77,1,[get_rid()])
		want=not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	crouching=want
	collider.shape.height=1.2 if crouching else 1.75
	collider.position.y=.61 if crouching else .88
	if seated!="":
		rotation.y=seat_yaw
		camera.rotation=Vector3(float(command.pitch),float(command.yaw)-rotation.y,0)
		camera.position.y=move_toward(camera.position.y,eye().y-global_position.y,dt*4)
		velocity=Vector3.ZERO
		ack=int(command.seq)
		return
	var original_x=command.x
	var original_z=command.z
	if crouching:command.x*=.55;command.z*=.55
	var falling_speed=velocity.y
	var before=global_position
	var was_floor=is_on_floor()
	super.simulate(dt)
	var desired=Basis(Vector3.UP,float(command.yaw))*Vector3(float(command.x),0,float(command.z)).limit_length(1)*dt*(5.2 if command.run else 3.1)
	if was_floor and desired.length()>.001 and Vector2(position.x-before.x,position.z-before.z).length()<desired.length()*.7:
		var up=Vector3.UP*.25
		var raised=global_transform
		raised.origin=before
		if not test_move(raised,up):
			raised.origin+=up
			if not test_move(raised,desired*2):
				raised.origin+=desired*2
				var landing=KinematicCollision3D.new()
				if test_move(raised,-Vector3.UP*.28,landing) and landing.get_normal().y>.70:
					global_position=raised.origin+landing.get_travel()
	for i in range(get_slide_collision_count()):
		var hit=get_slide_collision(i)
		var body=hit.get_collider()
		if not was_floor and falling_speed < -3 and hit.get_normal().y>.7 and body and body.get_meta("kind","")=="sofa":velocity.y=clampf(-falling_speed*.38,1.0,4.0)
		if body is RigidBody3D and body.get_meta("owner","")=="":
			var force=-hit.get_normal()
			force.y=0
			body.apply_central_impulse(force.limit_length(1)*minf(body.mass,1.5)*dt*7)
	command.x=original_x
	command.z=original_z
	if crouching:camera.position.y=1.10
	if position.y < -.9:position=Vector3(-1.8,.05,10.6)

func animate(dt:float):
	super.animate(dt)
	name_label.text=nickname
	lying.visible=not local_player and posture in ["lying","sleeping"]
	hands.visible=local_player and holding!="" and not posture in ["lying","sleeping"]
	if hands.visible and hand_skeleton:
		for side in ["L","R"]:
			var upper=hand_skeleton.find_bone("UpperArm."+side)
			var fore=hand_skeleton.find_bone("Forearm."+side)
			if upper>=0:hand_skeleton.set_bone_pose_rotation(upper,Quaternion(Vector3.RIGHT,-1.12))
			if fore>=0:hand_skeleton.set_bone_pose_rotation(fore,Quaternion(Vector3.RIGHT,-.40))
	standing.rotation.x=0
	standing.position=Vector3.ZERO
	if posture in ["lying","sleeping"]:
		standing.visible=false
		sitting.visible=false
	elif crouching:
		standing.position.y=-.35
		if skeleton:
			pose("Thigh.L",Vector3.RIGHT,-.65)
			pose("Thigh.R",Vector3.RIGHT,-.65)
			pose("Shin.L",Vector3.RIGHT,1.1)
			pose("Shin.R",Vector3.RIGHT,1.1)

func state() -> Dictionary:
	var s=super.state()
	s.displayName=nickname
	s.posture=posture
	s.seatIndex=seat_index
	s.crouch=crouching
	return s
