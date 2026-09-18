extends SkeletonModifier3D
## Analytic two-link contact correction after authored animation, in skeleton space.
var avatar:CharacterBody3D
var anchors={}
var errors={}
var arms_only=false
var contact_weights={}
var contact_samples={}
var target_resets=0

func solve(top_name:String,middle_name:String,end_name:String,target_world:Vector3,pole_world:Vector3,virtual_length=0.0,weight=1.0):
	var sk=get_skeleton()
	var top=sk.find_bone(top_name);var middle=sk.find_bone(middle_name);var end=sk.find_bone(end_name)
	if top<0 or middle<0:return
	var first=sk.get_bone_global_pose(top);var second=sk.get_bone_global_pose(middle)
	var a=first.origin;var b=second.origin
	var c=sk.get_bone_global_pose(end).origin if end>=0 else second*Vector3(0,virtual_length,0)
	var target=c.lerp(sk.to_local(target_world),clampf(weight,0,1));var pole=sk.to_local(pole_world)
	var l1=a.distance_to(b);var l2=b.distance_to(c);var distance=clampf(a.distance_to(target),.025,l1+l2-.002)
	var direction=(target-a).normalized()
	if direction.length_squared()<.9 or l1<.01 or l2<.01:return
	var bend=(pole-a)-direction*(pole-a).dot(direction)
	if bend.length_squared()<.0001:return
	bend=bend.normalized()
	var along=(l1*l1+distance*distance-l2*l2)/(2*distance)
	var elbow=a+direction*along+bend*sqrt(maxf(0,l1*l1-along*along))
	first.basis=Basis(Quaternion((b-a).normalized(),(elbow-a).normalized()))*first.basis
	sk.set_bone_global_pose(top,first)
	second=sk.get_bone_global_pose(middle)
	c=sk.get_bone_global_pose(end).origin if end>=0 else second*Vector3(0,virtual_length,0)
	var goal=a+direction*distance
	second.basis=Basis(Quaternion((c-second.origin).normalized(),(goal-second.origin).normalized()))*second.basis
	sk.set_bone_global_pose(middle,second)
	var achieved=sk.get_bone_global_pose(end).origin if end>=0 else sk.get_bone_global_pose(middle)*Vector3(0,virtual_length,0)
	errors[top_name]=sk.to_global(achieved).distance_to(target_world)

func _process_modification_with_delta(delta:float):
	if not is_instance_valid(avatar) or not avatar.is_inside_tree():return
	var sk=get_skeleton()
	errors.clear();contact_samples.clear()
	var world=avatar.get_parent()
	if avatar.holding!="" and world.objects.has(avatar.holding) and avatar.posture not in ["lying","sleeping"]:
		var item=world.objects[avatar.holding];var kind=world.definitions[avatar.holding].kind
		var authored=world.manifest.assets.get(kind,{}).get("anchors",{})
		var base=item.global_position+item.global_basis*Vector3.UP*float({"chair":.55,"table":.78,"low_table":.42,"floor_lamp":.85}.get(kind,0))
		for side in ["L","R"]:
			if kind in ["marker","laser","gun"] and side=="L":continue
			var sign=-1.0 if side=="L" else 1.0
			var contact=base+avatar.global_basis*Vector3(sign*.13,0,0)
			var grip_key="grip_left" if side=="L" else "grip_right"
			if authored.has(grip_key):contact=item.global_transform*world.vec(authored[grip_key])
			if kind in ["marker","laser"]:contact=base
			elif kind=="gun":contact=base+item.global_basis*Vector3(0,-.12,.05)
			solve("UpperArm."+side,"Forearm."+side,"",contact,avatar.global_transform*Vector3(sign*.6,1.0,.15),.24)
	if not arms_only and avatar.posture=="seated" and world.objects.has(avatar.seated):
		var seat=world.objects[avatar.seated];var spec=world.seat_contacts.contact(world,seat,avatar.seat_index)
		if not spec.is_empty():
			for side in ["L","R"]:
				var goal=seat.global_transform*world.vec(spec.feet[side])
				var pole=seat.global_transform*(world.vec(spec.pelvis)+Vector3(-.12 if side=="L" else .12,-.1,-.7))
				var weight=move_toward(float(contact_weights.get(side,0)),1.0,delta*5)
				contact_weights[side]=weight
				solve("Thigh."+side,"Shin."+side,"Foot."+side,goal,pole,0.0,weight)
				var foot=sk.find_bone("Foot."+side)
				var foot_pose=sk.get_bone_global_pose(foot)
				foot_pose.basis=foot_pose.basis.slerp(sk.get_bone_global_rest(foot).basis,weight)
				sk.set_bone_global_pose(foot,foot_pose)
				var result=sk.to_global(sk.get_bone_global_pose(foot).origin)
				contact_samples[side]={"weight":weight,"target":[goal.x,goal.y,goal.z],"foot":[result.x,result.y,result.z],"error":result.distance_to(goal),"seat":avatar.seated,"slot":avatar.seat_index}
			anchors.clear();return
	if arms_only or avatar.seated!="" or not avatar.motion_graph.grounded or avatar.get_meta("ko",false):anchors.clear();contact_weights.clear();return
	for side in ["L","R"]:
		var foot=sk.find_bone("Foot."+side)
		if foot<0:continue
		var at=sk.to_global(sk.get_bone_global_pose(foot).origin)
		var desired=avatar.motion_graph.contact_weight(side)
		var weight=move_toward(float(contact_weights.get(side,0)),desired,delta*12)
		contact_weights[side]=weight
		if weight<.01:anchors.erase(side);continue
		var excluded=[avatar.get_rid()]
		if world.objects.has(avatar.holding):excluded.append(world.objects[avatar.holding].get_rid())
		var q=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.25,at-Vector3.UP*.28,1|4,excluded)
		var hit=avatar.get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or hit.normal.y<.72:anchors.erase(side);continue
		var floor_goal=Vector3(at.x,hit.position.y+.09,at.z)
		if absf(at.y-floor_goal.y)>.16:anchors.erase(side);continue
		if not anchors.has(side):anchors[side]=floor_goal;target_resets+=1
		var goal:Vector3=anchors[side]
		# Release overstretched plants instead of snapping a fully weighted target.
		if Vector2(at.x-goal.x,at.z-goal.z).length()>.28 or absf(goal.y-floor_goal.y)>.10:
			contact_weights[side]=move_toward(weight,0,delta*18)
			if contact_weights[side]<.02:anchors.erase(side)
			continue
		var pole=avatar.global_transform*Vector3(-.12 if side=="L" else .12,.5,-.8)
		solve("Thigh."+side,"Shin."+side,"Foot."+side,goal,pole,0.0,weight)
		var result=sk.to_global(sk.get_bone_global_pose(foot).origin)
		contact_samples[side]={"weight":weight,"authoredWeight":desired,"target":[goal.x,goal.y,goal.z],"foot":[result.x,result.y,result.z],"error":result.distance_to(goal)}
