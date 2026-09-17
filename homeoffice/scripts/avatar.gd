extends CharacterBody3D

var actor_id = ""
var command = {"x":0.0,"z":0.0,"yaw":0.0,"pitch":0.0,"jump":false,"run":false,"seq":0}
var last_input_ms = 0
var ack = 0
var seated = ""
var seat_yaw = 0.0
var holding = ""
var local_player = false
var standing: Node3D
var sitting: Node3D
var skeleton: Skeleton3D
var camera: Camera3D
var gait = 0.0
var remote_gesture=""
var remote_target = Vector3.ZERO
var remote_yaw = 0.0
var predicted = []

func _ready():
	collision_layer=2
	collision_mask=1|4
	floor_snap_length=.22
	floor_max_angle=deg_to_rad(46)
	var shape=CollisionShape3D.new()
	var capsule=CapsuleShape3D.new()
	capsule.radius=.27
	capsule.height=1.75
	shape.shape=capsule
	shape.position.y=.88
	add_child(shape)
	standing=load("res://assets/characters/male-animated-v3.glb").instantiate()
	standing.rotation.y=PI
	add_child(standing)
	skeleton=find_skeleton(standing)
	sitting=load("res://assets/characters/male-seated-v3.glb").instantiate()
	sitting.rotation.y=PI
	add_child(sitting)
	sitting.visible=false
	camera=Camera3D.new()
	camera.position.y=1.62
	camera.fov=75
	camera.near=.06
	add_child(camera)
	camera.current=local_player
	standing.visible=not local_player

func find_skeleton(n:Node) -> Skeleton3D:
	if n is Skeleton3D:return n
	for child in n.get_children():
		var found=find_skeleton(child)
		if found:return found
	return null

func eye() -> Vector3:
	return global_position+Vector3(0,1.25 if seated!="" else 1.62,0)

func direction() -> Vector3:
	return Basis.from_euler(Vector3(float(command.pitch),float(command.yaw),0))*Vector3.FORWARD

func simulate(dt:float):
	var look_yaw=float(command.yaw)
	var movement=Basis(Vector3.UP,look_yaw)*Vector3(float(command.x),0,float(command.z)).limit_length(1)
	if seated!="":rotation.y=seat_yaw
	elif not command.get("third",false) or command.get("aim",false) or holding!="":rotation.y=lerp_angle(rotation.y,look_yaw,1-exp(-dt*18))
	elif movement.length()>.05:rotation.y=lerp_angle(rotation.y,atan2(-movement.x,-movement.z),1-exp(-dt*14))
	camera.rotation.y=float(command.yaw)-rotation.y
	camera.rotation.x=float(command.pitch)
	camera.position.y=move_toward(camera.position.y,1.25 if seated!="" else 1.62,dt*3)
	if seated!="":
		velocity=Vector3.ZERO
		return
	var move=Vector3(float(command.x),0,float(command.z)).limit_length(1)
	move=Basis(Vector3.UP,look_yaw)*move
	var speed=5.2 if command.run else 3.1
	velocity.x=move_toward(velocity.x,move.x*speed,dt*22)
	velocity.z=move_toward(velocity.z,move.z*speed,dt*22)
	if not is_on_floor():velocity.y-=18*dt
	elif command.jump:velocity.y=6
	command.jump=false
	move_and_slide()
	if position.y < -4:position=Vector3(1,0,3)
	ack=int(command.seq)

func animate(dt:float):
	standing.visible=not local_player and seated==""
	sitting.visible=not local_player and seated!=""
	gait+=dt*minf(Vector2(velocity.x,velocity.z).length()*3,14)
	if skeleton and seated=="":
		var amplitude=minf(Vector2(velocity.x,velocity.z).length()*.16,.65)
		for side in ["L","R"]:
			var phase=gait+(PI if side=="R" else 0)
			pose("Thigh."+side,Vector3.RIGHT,sin(phase)*amplitude)
			pose("Shin."+side,Vector3.RIGHT,maxf(0,-sin(phase))*.45*amplitude)
			pose("UpperArm."+side,Vector3.RIGHT,-.85 if holding!="" else -sin(phase)*amplitude*.6)
			pose("Forearm."+side,Vector3.RIGHT,-.35 if holding!="" else -.05)

func pose(bone:String,axis:Vector3,angle:float):
	var id=skeleton.find_bone(bone)
	if id>=0:
		# Godot bone pose is a local transform; preserve the imported rest basis.
		skeleton.set_bone_pose_rotation(id,skeleton.get_bone_rest(id).basis.get_rotation_quaternion()*Quaternion(axis,angle))

func state() -> Dictionary:
	return {"id":actor_id,"p":[position.x,position.y,position.z],"v":[velocity.x,velocity.y,velocity.z],"yaw":rotation.y,"lookYaw":command.yaw,"pitch":command.pitch,"seat":seated,"seatYaw":seat_yaw,"hold":holding,"ack":ack}
