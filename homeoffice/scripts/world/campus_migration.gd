extends RefCounted
## Work on a copy. Keep identifiers, furniture state and contents even when placement is unsafe.
func prepare(world,source:Dictionary) -> Dictionary:
	var next=source.duplicate(true)
	next.unplaced=next.get("unplaced",[]).duplicate(true)
	var blocked={}
	for item in next.objects:
		if int(source.get("campusVersion",0))<1:world.campus.migrate_personal(item)
		var point=world.vec(item.p)
		var size=world.placement_size(item.kind)
		var bounds=Transform3D(Basis(Vector3.UP,float(item.yaw)),point)*AABB(Vector3(-size.x*.5,.06,-size.z*.5),size-Vector3(0,.07,0))
		if point.x+size.x*.5<10 or point.x-size.x*.5>36 or point.z+size.z*.5< -38 or point.z-size.z*.5> -14:continue
		if not world.campus.placement_clear(bounds):blocked[item.id]=true;continue
		for shape in world.campus.data.collisions:
			if shape.has("points") or not shape.has("size"):continue
			var shape_size=world.vec(shape.size)
			if shape_size.y<.26:continue
			if bounds.intersects(AABB(world.vec(shape.position)-shape_size*.5,shape_size)):blocked[item.id]=true;break
	# A storage relationship migrates as one group so its references remain valid.
	var changed=true
	while changed:
		changed=false
		for item in next.objects:
			var related=item.state.get("contents",[]).duplicate();related.append(item.id)
			if related.any(func(id):return blocked.has(id)):
				for id in related:
					if not blocked.has(id):blocked[id]=true;changed=true
	var placed=[]
	for item in next.objects:
		if blocked.has(item.id):next.unplaced.append(item)
		else:placed.append(item)
	next.objects=placed
	if int(source.get("campusVersion",0))<1:
		var ids={}
		for item in next.objects+next.unplaced:ids[item.id]=true
		for item in world.campus.data.furniture:
			if ids.has(item.id) or next.objects.size()+next.unplaced.size()>=256:continue
			next.objects.append({"id":item.id,"kind":item.kind,"p":item.p,"yaw":item.yaw,"state":{}})
	next.campusVersion=1
	return next

func place_stored(world,p,data:Dictionary) -> String:
	var id=String(data.get("unplacedId",""));var item={}
	for candidate in world.unplaced:
		if candidate.id==id:item=candidate;break
	if item.is_empty() or data.get("kind")!=item.kind:return "보관한 사물이 없거나 종류가 다릅니다."
	for candidate in world.unplaced:
		if candidate.state.get("contents",[]).has(id):return "수납함을 먼저 배치하면 내용물도 함께 돌아옵니다."
	if not data.get("p") is Array or data.p.size()!=3:return "설치 위치가 올바르지 않습니다."
	var point=world.vec(data.p);var angle=float(data.get("yaw",0))
	if not point.is_finite() or not is_finite(angle) or not world.placement_ok(p,item.kind,point,angle):return "지지면·출입구·충돌을 확인하세요."
	var restoring=[id]+item.state.get("contents",[])
	if world.objects.size()+restoring.size()>256:return "가구 한도를 초과합니다."
	for stored in world.unplaced.duplicate(true):
		if not restoring.has(stored.id):continue
		stored.p=world.arr(point+Vector3.UP*world.placement_offset(stored.kind));stored.yaw=angle
		world.spawn_object(stored)
	world.unplaced=world.unplaced.filter(func(o):return not restoring.has(o.id));world.revision+=1
	return ""
