extends Node3D
var world
var entries={}
func setup(owner_world):
	world=owner_world
	var wood=StandardMaterial3D.new();wood.albedo_color=Color("bc875f");wood.roughness=.8
	var glass=StandardMaterial3D.new();glass.albedo_color=Color(.65,.78,.72,.24);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.roughness=.32
	var specs=[{"id":"council","p":[15.85,3.6,-22.6],"admin":false},{"id":"moss","p":[26.15,3.6,-22.6],"admin":false},{"id":"clay","p":[26.35,3.6,-24],"admin":false},{"id":"seminar","p":[16.55,3.6,-24],"admin":false},{"id":"operations","p":[15.85,14.4,-22.6],"admin":true},{"id":"broadcast","p":[26.45,14.4,-24],"admin":true}]
	for floor in world.campus.data.floors:
		for index in [0,1]:specs.append({"id":"wc-"+floor.id+"-"+str(index),"p":[33.1,float(floor.y),(-35.8 if index==0 else -32.8)+.7],"admin":false,"width":1.4,"yaw":PI*.5,"open":false})
	for spec in specs:
		var width=float(spec.get("width",1.7));var hinge=Basis(Vector3.UP,float(spec.get("yaw",0)));var half=width*.5
		var body=AnimatableBody3D.new();body.name="CampusDoor_"+spec.id;body.position=world.vec(spec.p);body.set_meta("object_id","campus-door-"+spec.id);add_child(body)
		world.collision(body,Vector3(half,1.2,0),Vector3(width,2.4,.09))
		for part in [[Vector3(half,.32,0),Vector3(width,.64,.12)],[Vector3(half,2.33,0),Vector3(width,.14,.12)],[Vector3(.05,1.48,0),Vector3(.10,1.6,.12)],[Vector3(width-.05,1.48,0),Vector3(.10,1.6,.12)]]:mesh(body,part[0],part[1],wood)
		mesh(body,Vector3(half,1.48,0),Vector3(width-.2,1.6,.04),wood if spec.id.begins_with("wc-") else glass)
		var button=StaticBody3D.new();button.position=body.position+hinge*Vector3(-.19,1.2,.11);button.set_meta("object_id","campus-door-"+spec.id);add_child(button);world.collision(button,Vector3.ZERO,Vector3(.17,.32,.18));mesh(button,Vector3.ZERO,Vector3(.17,.32,.18),wood)
		entries[spec.id]={"body":body,"button":button,"spec":spec,"open":spec.get("open",not spec.admin)};body.rotation.y=float(spec.get("yaw",0))+(opening_angle(spec.id) if entries[spec.id].open else 0.0)
		if spec.admin:world.make_label("운영 관리자 전용",body.position+Vector3(.85,2.65,.12),0,.025)
func mesh(parent,point,size,material):
	var view=MeshInstance3D.new();var box=BoxMesh.new();box.size=size;view.mesh=box;view.position=point;view.material_override=material;parent.add_child(view)
func action(actor:String,id:String) -> String:
	if not entries.has(id) or not world.players.has(actor):return "문을 확인하세요."
	var entry=entries[id];var p=world.players[actor]
	if p.eye().distance_to(world.vec(entry.spec.p)+Basis(Vector3.UP,float(entry.spec.get("yaw",0)))*Vector3(float(entry.spec.get("width",1.7))*.5,1.2,0))>3.6:return "문 가까이에서 사용하세요."
	if entry.spec.admin and not world.room_access.is_administrator(actor):return "운영 관리자 신원 확인이 필요합니다."
	if entry.open:
		var width=float(entry.spec.get("width",1.7));var sweep=Transform3D(Basis(Vector3.UP,float(entry.spec.get("yaw",0))),world.vec(entry.spec.p))*AABB(Vector3(-.3,0,-width-.3 if opening_angle(entry.spec.id)>0 else -.3),Vector3(width+.6,2.5,width+.6))
		for avatar in world.players.values():
			if sweep.has_point(avatar.position+Vector3.UP*.6):return "문이 움직일 공간에서 한 걸음 물러나세요."
		for object_id in world.objects:
			if sweep.has_point(world.objects[object_id].position+Vector3.UP*.3):return "문 가까이의 물건을 먼저 치워 주세요."
	entry.open=not entry.open;world.revision+=1;return ""
func snapshot() -> Dictionary:
	var result={}
	for id in entries:result[id]=entries[id].open
	return result
func restore(value:Dictionary):
	for id in entries:
		if value.get(id) is bool:entries[id].open=value[id]
func clearance(volume:AABB) -> bool:
	for entry in entries.values():
		if volume.intersects(AABB(world.vec(entry.spec.p)+Vector3(-.25,0,-1),Vector3(2.2,2.5,2.9))):return false
	return true
func opening_angle(id:String) -> float:return PI*.5 if id in ["clay","seminar","broadcast"] else -PI*.5
func _physics_process(dt):
	for entry in entries.values():entry.body.rotation.y=move_toward(entry.body.rotation.y,float(entry.spec.get("yaw",0))+(opening_angle(entry.spec.id) if entry.open else 0.0),dt*1.5)
