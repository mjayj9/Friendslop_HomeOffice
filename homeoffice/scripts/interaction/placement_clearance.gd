extends RefCounted
## Reserve real approach/exit volumes even when a door leaf happens to be open.
func valid(world,p,kind:String,point:Vector3,angle:float,move_id:String="") -> bool:
	var size=world.placement_size(kind)
	var transform=Transform3D(Basis(Vector3.UP,angle),point)
	var volume=AABB(Vector3(-size.x*.5,.025,-size.z*.5),size-Vector3(0,.025,0))
	var world_volume=transform*volume
	# The wardrobe's gallery doorway, lounge opening and fitting approach stay usable.
	for reserve in [AABB(Vector3(-6.0,3.6,-1.2),Vector3(2,2.5,2.4)),AABB(Vector3(-10.7,3.6,-.85),Vector3(1.5,2.5,1.9)),AABB(Vector3(-9.3,3.6,-2.8),Vector3(1.2,2.2,3.2))]:
		if world_volume.intersects(reserve):return false
	for door in world.doors.values():
		var relative=door.global_transform.affine_inverse()*transform*volume
		var width=float(door.get_meta("definition").width)
		if relative.intersects(AABB(Vector3(-.35,0,-1.0),Vector3(width+.7,2.5,2.0))):return false
	for object_id in world.objects:
		if object_id==move_id:continue
		var other_kind=world.definitions[object_id].kind
		if other_kind not in ["chair","sofa","bed"]:continue
		var seat=world.objects[object_id]
		var relative=seat.global_transform.affine_inverse()*transform*volume
		var reserved=AABB(Vector3(-.45,0,-1.15),Vector3(.9,1.8,.7))
		if other_kind=="sofa":reserved=AABB(Vector3(-1.3,0,-1.35),Vector3(2.6,1.8,.8))
		if other_kind=="bed":reserved=AABB(Vector3(.65,0,-.8),Vector3(.65,1.8,1.6))
		if relative.intersects(reserved):return false
	var excluded=[p.get_rid()]
	if world.objects.has(move_id):excluded.append(world.objects[move_id].get_rid())
	# Four footprint samples reject a preview balanced on a corner or a narrow edge.
	for x in [-.4,.4]:
		for z in [-.4,.4]:
			var corner=transform*Vector3(size.x*x,0,size.z*z)
			var query=PhysicsRayQueryParameters3D.create(corner+Vector3.UP*.1,corner-Vector3.UP*.12,1|4,excluded)
			var hit=p.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.normal.y<.85 or absf(hit.position.y-point.y)>.08:return false
	return true
