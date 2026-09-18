extends Node3D
## Host-owned cars; AnimatableBody3D supplies platform velocity exactly once.
var world
var campus
var cars={}
var floors=[]
var serial=0
var material:StandardMaterial3D
var panel_material:StandardMaterial3D

func setup(owner_world,building):
	world=owner_world;campus=building;floors=campus.data.floors
	process_physics_priority=-20
	material=StandardMaterial3D.new();material.albedo_color=Color("d8b68d");material.roughness=.76
	panel_material=StandardMaterial3D.new();panel_material.albedo_color=Color("819b7e");panel_material.roughness=.7
	for spec in campus.data.lifts:
		var body=AnimatableBody3D.new();body.name="Cabin_"+spec.id;body.collision_layer=1;body.collision_mask=0;body.sync_to_physics=true
		add_child(body);body.position=Vector3(spec.x,0,spec.z)
		part(body,Vector3(0,-.10,0),Vector3(spec.width,.20,spec.depth),material)
		part(body,Vector3(0,1.3,-spec.depth*.5),Vector3(spec.width,2.6,.12),panel_material)
		for side in [-1,1]:part(body,Vector3(side*spec.width*.5,1.3,0),Vector3(.12,2.6,spec.depth),panel_material)
		part(body,Vector3(0,2.65,0),Vector3(spec.width,.12,spec.depth),material)
		var console=StaticBody3D.new();console.set_meta("object_id","lift-console-"+spec.id);body.add_child(console)
		part(console,Vector3(spec.width*.5-.15,1.15,.65),Vector3(.12,.65,.4),material)
		var leaves=[]
		for side in [-1,1]:
			var leaf=AnimatableBody3D.new();leaf.collision_layer=1;body.add_child(leaf);part(leaf,Vector3.ZERO,Vector3(spec.width*.5,2.45,.10),panel_material);leaves.append(leaf)
		var landings={}
		for floor in floors:
			var pair=[]
			for side in [-1,1]:
				var leaf=AnimatableBody3D.new();leaf.collision_layer=1;add_child(leaf);part(leaf,Vector3.ZERO,Vector3(spec.width*.5,2.5,.10),panel_material);pair.append(leaf)
			landings[floor.id]=pair
		cars[spec.id]={"spec":spec,"body":body,"leaves":leaves,"landings":landings,"floor":"1F","target":"1F","state":"IDLE","queue":[],"open":0.0,"elapsed":0.0,"tripId":0,"reason":"","remoteY":0.0}
		pose(cars[spec.id])

func part(parent:Node3D,point:Vector3,size:Vector3,mat:Material):
	var mesh=MeshInstance3D.new();var box=BoxMesh.new();box.size=size;mesh.mesh=box;mesh.material_override=mat;mesh.position=point;parent.add_child(mesh)
	var shape=CollisionShape3D.new();var bounds=BoxShape3D.new();bounds.size=size;shape.shape=bounds;shape.position=point;parent.add_child(shape)

func floor_y(id:String) -> float:
	for floor in floors:
		if floor.id==id:return float(floor.y)
	return NAN

func occupants(car) -> Array:
	var result=[]
	for p in world.players.values():
		var v=p.global_position-car.body.global_position
		if absf(v.x)<float(car.spec.width)*.5-.10 and absf(v.z)<float(car.spec.depth)*.5-.05 and v.y>-.15 and v.y<2.55:result.append(p.actor_id)
	return result

func request(actor:String,lift_id:String,target_floor:String) -> String:
	if not world.host or not cars.has(lift_id) or not world.players.has(actor) or is_nan(floor_y(target_floor)):return "잘못된 승강기 요청입니다."
	var car=cars[lift_id];var p=world.players[actor]
	var inside=occupants(car).has(actor)
	var call_at=Vector3(car.spec.x+car.spec.width*.5+.3,floor_y(target_floor)+1.2,-33.04)
	if not inside and p.eye().distance_to(call_at)>2.8:return "승강기 홀 버튼이나 차내 패널에서 선택하세요."
	if target_floor==car.floor and car.state in ["IDLE","OPEN","CLOSING"]:
		car.state="OPENING";car.elapsed=0.0;return ""
	if not car.queue.has(target_floor) and not(car.target==target_floor and car.state in ["MOVING","ARRIVING","LEVELING"]):car.queue.append(target_floor)
	return ""

func obstruction(car) -> bool:
	var front=car.body.global_position+Vector3(0,0,float(car.spec.depth)*.5)
	for p in world.players.values():
		var v=p.global_position-front
		if absf(v.x)<float(car.spec.width)*.5+.28 and absf(v.z)<.55 and v.y>-.25 and v.y<2.5:return true
	for id in world.objects:
		var ob=world.objects[id];var delta=ob.global_position-front
		var size=world.placement_size(world.definitions[id].kind)
		if absf(delta.x)<float(car.spec.width)*.5+size.x*.5 and absf(delta.z)<.23+size.z*.5 and delta.y+size.y>0 and delta.y<2.5:return true
	return false

func _physics_process(dt):
	if not world or not world.ready_to_play or world.frozen:return
	for car in cars.values():
		if not world.host:
			car.body.position.y=move_toward(car.body.position.y,float(car.remoteY),maxf(.03,dt*2.4));pose(car);continue
		car.elapsed+=dt
		match car.state:
			"IDLE":
				if not car.queue.is_empty():car.target=car.queue.pop_front();car.state="CLOSING";car.elapsed=0.0
			"OPENING":
				car.open=move_toward(float(car.open),1.0,dt*1.2)
				if car.open>=1.0:car.state="OPEN";car.elapsed=0.0
			"OPEN":
				if car.elapsed>5.0 and not car.queue.is_empty():car.target=car.queue.pop_front();car.state="CLOSING";car.elapsed=0.0
			"CLOSING":
				if obstruction(car):
					if car.target!=car.floor and not car.queue.has(car.target):car.queue.push_front(car.target)
					car.state="OPENING";car.elapsed=0.0;car.reason="문 앞의 사람과 물건을 확인하고 다시 엽니다."
				elif occupants(car).size()>(4 if car.spec.id=="passenger" else 8):car.state="HOLD";car.reason="설계 탑승 인원 초과 · 일부 하차하세요."
				else:
					car.open=move_toward(float(car.open),0.0,dt*1.2)
					if car.open<=0.0:
						if car.target==car.floor:car.state="IDLE"
						elif not campus.floor_ready(car.target):car.state="HOLD";car.reason="도착층 준비를 기다립니다."
						else:serial+=1;car.tripId=serial;car.state="MOVING";car.elapsed=0.0;car.reason=""
			"MOVING","ARRIVING":
				var target_y=floor_y(car.target);var distance=absf(target_y-car.body.position.y)
				if distance<.5:car.state="ARRIVING"
				car.body.position.y=move_toward(car.body.position.y,target_y,dt*(1.65 if distance>.5 else maxf(.24,distance*2.8)))
				if is_equal_approx(car.body.position.y,target_y):car.floor=car.target;car.state="LEVELING";car.elapsed=0.0
			"LEVELING":
				if car.elapsed>.35 and campus.floor_ready(car.floor):car.state="OPENING";car.elapsed=0.0
			"HOLD":
				if occupants(car).size()>(4 if car.spec.id=="passenger" else 8):car.open=move_toward(float(car.open),1.0,dt)
				elif campus.floor_ready(car.target):car.state="CLOSING";car.reason=""
		pose(car)

func pose(car):
	for index in [0,1]:
		var side=-1 if index==0 else 1
		var x=side*(float(car.spec.width)*.25+float(car.spec.width)*.55*float(car.open))
		car.leaves[index].position=Vector3(x,1.25,float(car.spec.depth)*.5)
		for floor in floors:
			var opening=float(car.open) if floor.id==car.floor and absf(car.body.position.y-float(floor.y))<.015 else 0.0
			car.landings[floor.id][index].position=Vector3(float(car.spec.x)+side*(float(car.spec.width)*.25+float(car.spec.width)*.55*opening),float(floor.y)+1.25,-33.17)

func snapshot() -> Dictionary:
	var result={}
	for key in cars:
		var c=cars[key];result[key]={"floor":c.floor,"target":c.target,"state":c.state,"queue":c.queue.duplicate(),"y":c.body.position.y,"open":c.open,"elapsed":c.elapsed,"tripId":c.tripId,"reason":c.reason,"occupants":occupants(c)}
	return result

func restore(values:Dictionary,handoff=false):
	for key in cars:
		if not values.has(key):continue
		var value=values[key];var c=cars[key]
		if not value is Dictionary or is_nan(floor_y(String(value.get("floor","")))) or is_nan(floor_y(String(value.get("target","")))):continue
		if value.get("state") not in ["IDLE","ARRIVING","OPENING","OPEN","CLOSING","MOVING","LEVELING","HOLD","FAULT"]:continue
		c.floor=value.floor;c.target=value.target;c.state=value.state;c.open=clampf(float(value.get("open",0)),0,1);c.elapsed=maxf(0,float(value.get("elapsed",0)));c.remoteY=clampf(float(value.get("y",0)),-3.6,21.6);c.tripId=int(value.get("tripId",0));serial=maxi(serial,c.tripId)
		c.queue=[]
		for target in value.get("queue",[]):
			if not is_nan(floor_y(String(target))) and not c.queue.has(target):c.queue.append(target)
		if handoff or absf(c.body.position.y-c.remoteY)>2:c.body.position.y=c.remoteY
		pose(c)
