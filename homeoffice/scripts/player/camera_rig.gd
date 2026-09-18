extends RefCounted
## Camera owns view distance/mode only. Motor and tool direction use validated look input.
var third_person=true
var distance=3.2
var aiming=false
var actual_distance=0.0
var initialized=false
var last_sleeping=false

var profile="HOME"
var saved_view={}

func activity_profile(next:String):
	if next==profile:return
	var sports=next in ["BASKETBALL","FOOTBALL"]
	var was_sports=profile in ["BASKETBALL","FOOTBALL"]
	if sports and not was_sports:
		saved_view={"third":third_person,"distance":distance}
	if sports:
		third_person=true;distance=4.2 if next=="BASKETBALL" else 4.6
	elif was_sports and not saved_view.is_empty():
		third_person=saved_view.third;distance=saved_view.distance;saved_view.clear()
	profile=next;initialized=false

func toggle():
	third_person=not third_person
	initialized=false

func zoom(steps:float):
	distance=clampf(distance+steps*.35,.9,5.0)

func view_basis(p) -> Basis:
	return Basis.from_euler(Vector3(float(p.command.pitch),float(p.command.yaw),0))

func position_for(p,third:bool,zoom_distance:float,aim:bool) -> Vector3:
	var pivot=p.eye()
	if not third:return pivot
	var basis=view_basis(p)
	var offset=basis*Vector3(.42 if aim else 0.0,.12,minf(zoom_distance,1.8) if aim else zoom_distance)
	var sphere=SphereShape3D.new();sphere.radius=.18
	var query=PhysicsShapeQueryParameters3D.new()
	query.shape=sphere;query.transform=Transform3D(Basis.IDENTITY,pivot)
	query.motion=offset;query.collision_mask=1|4;query.margin=.03
	var excluded=[p.get_rid()]
	var held=p.get_parent().objects.get(p.holding) if p.holding!="" else null
	if held:excluded.append(held.get_rid())
	query.exclude=excluded
	var result=p.get_world_3d().direct_space_state.cast_motion(query)
	return pivot+offset*(result[0] if result.size()>0 else 0.0)

func aim_point(p,max_distance=30.0) -> Vector3:
	var origin=position_for(p,bool(p.command.get("third",false)),float(p.command.get("zoom",3.2)),bool(p.command.get("aim",false)))
	var direction=view_basis(p)*Vector3.FORWARD
	var excluded=[p.get_rid()]
	var held=p.get_parent().objects.get(p.holding) if p.holding!="" else null
	if held:excluded.append(held.get_rid())
	var query=PhysicsRayQueryParameters3D.create(origin,origin+direction*max_distance,1|2|4,excluded)
	return p.get_world_3d().direct_space_state.intersect_ray(query).get("position",origin+direction*max_distance)

func update(p,dt:float,sleeping:bool):
	if p.get_parent().bridge:p.camera.fov=clampf(float(p.get_parent().bridge.camera_fov()),55,95)
	var use_third=third_person or sleeping
	var desired=position_for(p,use_third,2.6 if sleeping else distance,aiming and not sleeping)
	var target_distance=p.eye().distance_to(desired)
	# Contract immediately toward blockers; ease outward only. Never interpolate through walls.
	if not initialized or sleeping!=last_sleeping:actual_distance=target_distance;initialized=true
	elif target_distance<actual_distance:actual_distance=target_distance
	else:actual_distance=lerpf(actual_distance,target_distance,1-exp(-dt*10))
	last_sleeping=sleeping
	p.camera.global_position=p.eye()+(desired-p.eye()).normalized()*actual_distance
	p.camera.global_basis=view_basis(p)
	if sleeping and actual_distance>.2:p.camera.look_at(p.global_position+Vector3.UP*.65)
	p.standing.visible=use_third and actual_distance>.58
	p.hands.visible=not p.standing.visible and p.holding!="" and not sleeping

func diagnostics() -> Dictionary:
	return {"mode":"third" if third_person else "first","zoom":distance,"actualDistance":actual_distance,"aiming":aiming,"profile":profile}
