extends RefCounted
## Narrow repair for the V2 low-table collider defect; no entity deletion or role import.
var adjustments=[]

func prepare_restore(world, saved:Dictionary) -> Dictionary:
	var restored=saved.duplicate(true)
	adjustments.clear()
	for table in restored.objects:
		if table.kind!="low_table":continue
		var point=world.vec(table.p)
		var query=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.5,point-Vector3.UP*.08,1)
		var hit=world.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.normal.y<.98:continue
		var lift=hit.position.y-point.y
		# Old top-only collider settled its underside 0.38 m above its buried origin.
		if lift<.34 or lift>.41:continue
		var shifted=[]
		for item in restored.objects:
			if item.kind not in ["book","marker","plate","pan","ingredient","meal","laser"]:continue
			var at=world.vec(item.p)
			var local=Basis(Vector3.UP,-float(table.yaw))*(at-point)
			if absf(local.x)>.84 or absf(local.z)>.41 or local.y<.44 or local.y>.69:continue
			item.p[1]+=lift;shifted.append(item.id)
		table.p[1]+=lift
		adjustments.append({"objectId":table.id,"fromY":point.y,"toY":table.p[1],"supportedItems":shifted,"reason":"V2 low_table lacked leg collision shapes"})
	return restored
