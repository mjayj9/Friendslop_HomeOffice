extends RefCounted
var token=""
var stored_id=""
var uv=Vector2.ZERO
var inside=false
var snap=true
var last_report=""

func handle(world,e:Dictionary):
	var phase=String(e.get("phase",""));var id=String(e.get("token",""))
	if phase=="begin":
		if id.length()!=36:return
		world.end_build();token=id;stored_id=String(e.get("unplacedId",""));inside=false;world.begin_build(String(e.get("kind","")));return
	if token=="" or id!=token:return
	if phase=="move":
		uv=Vector2(float(e.get("u",-1)),float(e.get("v",-1)))
		inside=bool(e.get("inside",false)) and uv.is_finite() and uv.x>=0 and uv.y>=0 and uv.x<=1 and uv.y<=1
		snap=bool(e.get("snap",true));world.build_angle=float(e.get("angle",0));update(world)
	elif phase=="rotate":world.build_angle=float(e.get("angle",0));update(world)
	elif phase in ["drop","cancel"]:
		if phase=="drop":
			update(world)
			if inside and world.build_valid:
				world.request_action("place",{"kind":world.build_kind,"p":world.arr(world.build_point),"yaw":world.build_angle,"objectId":"","placementId":token,"unplacedId":stored_id})
		world.end_build();token="";inside=false

func update(world):
	if token=="" or world.build_kind=="" or not world.players.has(world.local_id):return
	var p=world.players[world.local_id];var reason="공간 위로 끌어 놓으세요."
	world.build_valid=false;world.build_preview.visible=inside
	if inside:
		var screen=uv*world.get_viewport().get_visible_rect().size
		var origin=p.camera.project_ray_origin(screen);var direction=p.camera.project_ray_normal(screen)
		var excluded=[p.get_rid()]
		if world.objects.has(p.holding):excluded.append(world.objects[p.holding].get_rid())
		var ray=PhysicsRayQueryParameters3D.create(origin,origin+direction*15,1|4,excluded)
		var hit=p.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty():reason="설치할 지지면이 없습니다."
		elif hit.normal.y<.85:reason="평평한 지지면 위에 놓으세요."
		else:
			var point:Vector3=hit.position
			if snap:point.x=snappedf(point.x,.25);point.z=snappedf(point.z,.25)
			world.build_point=point
			world.build_valid=world.placement_ok(p,world.build_kind,point,world.build_angle)
			reason="놓으면 설치됩니다." if world.build_valid else "거리·충돌·출입구·좌석·관리 구역을 확인하세요."
		world.build_preview.position=world.build_point+Vector3.UP*world.placement_offset(world.build_kind);world.build_preview.rotation.y=world.build_angle
		for node in world.build_preview.find_children("*","MeshInstance3D",true,false):node.material_override.albedo_color=Color(.25,.9,.65,.48) if world.build_valid else Color(1,.25,.18,.48)
	var report=JSON.stringify({"valid":world.build_valid,"reason":reason,"point":world.arr(world.build_point),"yaw":world.build_angle,"token":token})
	if report!=last_report and world.bridge:world.bridge.placement_feedback(report);last_report=report
