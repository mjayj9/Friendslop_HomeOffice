extends SkeletonModifier3D
## Analytic two-link contact correction after authored animation, in skeleton space.
var avatar:CharacterBody3D
var anchors={}
var errors={}
var arms_only=false

func solve(top_name:String,middle_name:String,end_name:String,target_world:Vector3,pole_world:Vector3,virtual_length=0.0):
	var sk=get_skeleton()
	var top=sk.find_bone(top_name);var middle=sk.find_bone(middle_name);var end=sk.find_bone(end_name)
	if top<0 or middle<0:return
	var first=sk.get_bone_global_pose(top);var second=sk.get_bone_global_pose(middle)
	var a=first.origin;var b=second.origin
	var c=sk.get_bone_global_pose(end).origin if end>=0 else second*Vector3(0,virtual_length,0)
	var target=sk.to_local(target_world);var pole=sk.to_local(pole_world)
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

func _process_modification_with_delta(_delta:float):
	if not is_instance_valid(avatar) or not avatar.is_inside_tree():return
	var sk=get_skeleton()
	var world=avatar.get_parent()
	if avatar.holding!="" and world.objects.has(avatar.holding) and avatar.posture not in ["lying","sleeping"]:
		var item=world.objects[avatar.holding];var kind=world.definitions[avatar.holding].kind
		var base=item.global_position+item.global_basis*Vector3.UP*float({"chair":.55,"table":.78,"low_table":.42,"floor_lamp":.85}.get(kind,0))
		for side in ["L","R"]:
			if kind in ["marker","laser","gun"] and side=="L":continue
			var sign=-1.0 if side=="L" else 1.0
			var contact=base+avatar.global_basis*Vector3(sign*.13,0,0)
			if kind in ["marker","laser"]:contact=base
			elif kind=="gun":contact=base+item.global_basis*Vector3(0,-.12,.05)
			solve("UpperArm."+side,"Forearm."+side,"",contact,avatar.global_transform*Vector3(sign*.6,1.0,.15),.24)
	if arms_only or avatar.seated!="" or absf(avatar.velocity.y)>.5 or avatar.get_meta("ko",false):anchors.clear();return
	for side in ["L","R"]:
		var foot=sk.find_bone("Foot."+side)
		if foot<0:continue
		var at=sk.to_global(sk.get_bone_global_pose(foot).origin)
		var q=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.28,at-Vector3.UP*.35,1|4,[avatar.get_rid()])
		var hit=avatar.get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or hit.normal.y<.65:anchors.erase(side);continue
		var goal=Vector3(at.x,hit.position.y+.09,at.z)
		if at.y-goal.y>.19:anchors.erase(side);continue
		if not anchors.has(side) or Vector2(at.x-anchors[side].x,at.z-anchors[side].z).length()>.33 or absf(goal.y-anchors[side].y)>.15:anchors[side]=goal
		goal=anchors[side]
		var pole=avatar.global_transform*Vector3(-.12 if side=="L" else .12,.5,-.8)
		solve("Thigh."+side,"Shin."+side,"Foot."+side,goal,pole)
