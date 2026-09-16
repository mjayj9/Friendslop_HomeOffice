extends "res://scripts/avatar.gd"

var nickname="친구"
var name_label:Label3D
var lying:Node3D
var hands:Node3D
var hand_skeleton:Skeleton3D
var posture="standing"
var seat_index=0
var crouching=false
var contact_ik
var hand_ik
var previous_speed=0.0
var previous_yaw=0.0
var grounded_before=true
var motion_until=0
var motion_clip=""
var animator:AnimationPlayer
var last_clip=""
var previous_posture="standing"
var transition_until=0
var transition_clip=""
var sleep_blend=0.0
var collider:CollisionShape3D

func _ready():
	super._ready()
	for n in standing.find_children("*","AnimationPlayer",true,false):animator=n;break
	if animator:
		var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/animation-manifest-v3.json"))
		for clip in manifest.clips:
			if animator.has_animation(clip.name):animator.get_animation(clip.name).loop_mode=Animation.LOOP_LINEAR if clip.loop else Animation.LOOP_NONE
	contact_ik=load("res://scripts/player/contact_ik.gd").new();contact_ik.avatar=self;skeleton.add_child(contact_ik)
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
	lying=load("res://assets/characters/male-lying-v3.glb").instantiate()
	add_child(lying)
	lying.visible=false
	hands=load("res://assets/characters/male-arms-v3.glb").instantiate()
	hands.rotation.y=PI
	add_child(hands)
	hand_skeleton=find_skeleton(hands)
	hand_ik=load("res://scripts/player/contact_ik.gd").new();hand_ik.avatar=self;hand_ik.arms_only=true;hand_skeleton.add_child(hand_ik)
	hands.visible=false

func eye() -> Vector3:
	var h=.92 if posture in ["lying","sleeping"] else (1.25 if seated!="" else (1.10 if crouching else 1.62))
	return global_position+Vector3(0,h,0)

func simulate(dt:float):
	if get_meta("ko",false):command.x=0;command.z=0;command.jump=false
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
	var world=get_parent()
	var burden=1.0
	if holding!="" and world.definitions.has(holding):burden=.55 if world.definitions[holding].kind in ["table","chair","low_table","floor_lamp"] else 1.0
	command.x*=burden;command.z*=burden
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
			if not test_move(raised,desired):
				raised.origin+=desired
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
	var now=Time.get_ticks_msec()
	name_label.text=nickname
	name_label.pixel_size=.0018
	name_label.visible=not local_player
	var sleeping=posture in ["lying","sleeping"]
	standing.visible=not local_player or sleeping
	sitting.visible=false
	lying.visible=false
	hands.visible=local_player and holding!="" and not sleeping
	if hands.visible and hand_skeleton:
		for side in ["L","R"]:
			for part in ["UpperArm.","Forearm."]:
				var index=hand_skeleton.find_bone(part+side)
				if index>=0:hand_skeleton.set_bone_pose_rotation(index,hand_skeleton.get_bone_rest(index).basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,-1.0 if part=="UpperArm." else -.45))
	contact_ik.active=standing.visible
	hand_ik.active=hands.visible
	var speed=Vector2(velocity.x,velocity.z).length()
	var clip="idle"
	if seated!="":clip="sleep_idle" if sleeping else "sit_idle"
	elif crouching:clip="crouch"
	elif speed>.15:clip="run" if speed>3.5 else "walk"
	elif holding!="":clip="carry"
	var local_velocity=global_basis.inverse()*Vector3(velocity.x,0,velocity.z)
	if clip in ["walk","run"]:
		if absf(local_velocity.x)>absf(local_velocity.z)*1.2:clip+="_right" if local_velocity.x>0 else "_left"
		elif local_velocity.z>.2:clip+="_back"
	if speed>.2 and previous_speed<.1:motion_clip="start";motion_until=now+180
	if speed<.1 and previous_speed>.3:motion_clip="stop";motion_until=now+230
	if not is_on_floor() and absf(velocity.y)>.5:clip="jump" if velocity.y>1 else "air"
	elif not grounded_before:motion_clip="land";motion_until=now+220
	if speed<.12 and absf(angle_difference(previous_yaw,rotation.y))>.015 and seated=="":clip="turn_left" if angle_difference(previous_yaw,rotation.y)>0 else "turn_right"
	if now<motion_until and seated=="":clip=motion_clip
	grounded_before=is_on_floor();previous_speed=speed;previous_yaw=rotation.y
	var world=get_parent()
	if holding!="" and world.definitions.has(holding):
		var kind=world.definitions[holding].kind
		if kind=="shield":clip="shield"
		elif kind=="gun" and speed<.2:clip="aim"
		elif kind in ["chair","table","low_table","floor_lamp"] and speed<.2:clip="carry_heavy"
	if get_meta("dribble",false):clip="dribble_left" if get_meta("dribble_left",false) else "dribble"

	var activity=String(get_meta("activity",""))
	if activity=="book":clip="book_read"
	elif activity=="broadcast":clip="broadcast"
	elif activity in ["report","documents","brainstorm","mindmap","meeting"] and seated!="":clip="work"
	var gesture=String(get_meta("gesture","")) if now<int(get_meta("gesture_until",0)) else remote_gesture
	if gesture!="":clip=gesture
	if posture!=previous_posture:
		if sleeping:transition_clip="sleep_enter";transition_until=now+1400
		elif previous_posture in ["lying","sleeping"]:transition_clip="wake";transition_until=now+1200
		elif seated!="":transition_clip="sit_enter";transition_until=now+900
		else:transition_clip="sit_exit";transition_until=now+800
		previous_posture=posture
	if now<transition_until:clip=transition_clip
	if animator:
		var name="v3_"+clip
		if not animator.has_animation(name):
			for candidate in animator.get_animation_list():
				if String(candidate).ends_with(name):name=candidate;break
		if name!=last_clip and animator.has_animation(name):animator.play(name,.12);last_clip=name
		animator.speed_scale=clampf(speed/(5.2 if clip=="run" else 3.1),.45,1.6) if clip.begins_with("walk") or clip.begins_with("run") else 1.0
	if local_player:
		sleep_blend=move_toward(sleep_blend,1.0 if sleeping else 0.0,dt*1.8)
		var near=eye()
		var desired=global_position+global_basis*Vector3(1.8,1.9,2.2)
		var q=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.9,desired,1|4,[get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():desired=hit.position+hit.normal*.18
		if sleep_blend>.001:
			camera.global_position=near.lerp(desired,sleep_blend)
			camera.look_at(global_position+Vector3(0,.75,0))
		else:camera.position=Vector3(0,eye().y-global_position.y,0)

func state() -> Dictionary:
	var s=super.state()
	s.displayName=nickname
	s.posture=posture
	s.seatIndex=seat_index
	s.crouch=crouching
	s.activity=String(get_meta("activity",""))
	s.dribble=bool(get_meta("dribble",false));s.dribbleLeft=bool(get_meta("dribble_left",false))
	s.gesture=String(get_meta("gesture","")) if Time.get_ticks_msec()<int(get_meta("gesture_until",0)) else ""
	return s
