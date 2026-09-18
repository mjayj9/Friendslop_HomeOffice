extends "res://scripts/avatar.gd"

const Appearance=preload("res://scripts/wardrobe/appearance.gd")
var appearance_profile=Appearance.defaults()

func set_appearance(profile:Dictionary):
	appearance_profile=profile.duplicate(true)
	for visual in [standing,sitting,lying,hands]:
		if is_instance_valid(visual):Appearance.apply(visual,appearance_profile)

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
var motion_graph=preload("res://scripts/player/motion_graph.gd").new()
var camera_rig=preload("res://scripts/player/camera_rig.gd").new()

func aim_point() -> Vector3:
	return camera_rig.aim_point(self)

func aim_direction() -> Vector3:
	return (aim_point()-eye()).normalized()

func _ready():
	super._ready()
	for n in standing.find_children("*","AnimationPlayer",true,false):animator=n;break
	if animator:
		var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/animation-manifest-v5.json"))
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
	motion_graph.setup(self)

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
		if posture=="seated":
			collider.shape.height=.9;collider.position.y=.97
			var seating_world=get_parent();var item=seating_world.objects.get(seated)
			if item and not seating_world.seat_contacts.contact(seating_world,item,seat_index).is_empty():position=seating_world.seat_contacts.origin(seating_world,item,seat_index)
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
	standing.visible=not local_player or camera_rig.third_person or sleeping
	sitting.visible=false
	lying.visible=false
	hands.visible=local_player and not camera_rig.third_person and holding!="" and not sleeping
	if hands.visible and hand_skeleton:
		for side in ["L","R"]:
			for part in ["UpperArm.","Forearm."]:
				var index=hand_skeleton.find_bone(part+side)
				if index>=0:hand_skeleton.set_bone_pose_rotation(index,hand_skeleton.get_bone_rest(index).basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,-1.0 if part=="UpperArm." else -.45))
	contact_ik.active=standing.visible and motion_graph.debug_mode!="animation_only"
	hand_ik.active=hands.visible and motion_graph.debug_mode!="animation_only"
	motion_graph.update(dt)
	if local_player:camera_rig.update(self,dt,sleeping)

func state() -> Dictionary:
	var s=super.state()
	s.grounded=is_on_floor() or seated!=""
	s.actionStamp=int(get_meta("gesture_until",0))
	s.displayName=nickname
	s.posture=posture
	s.seatIndex=seat_index
	s.crouch=crouching
	s.activity=String(get_meta("activity",""))
	s.dribble=bool(get_meta("dribble",false));s.dribbleLeft=bool(get_meta("dribble_left",false))
	s.gesture=String(get_meta("gesture","")) if Time.get_ticks_msec()<int(get_meta("gesture_until",0)) else ""
	return s
