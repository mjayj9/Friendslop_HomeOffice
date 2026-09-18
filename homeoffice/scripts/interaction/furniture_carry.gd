extends RefCounted
## Hand sockets define height; the whole collider envelope defines body clearance.
## Furniture keeps collision with its carrier and every other body.
const KINDS=["chair","table","low_table"]
var traces={}

func bounds(body:RigidBody3D) -> AABB:
	var result=AABB();var first=true
	for child in body.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			var box=child.transform*AABB(-child.shape.size*.5,child.shape.size)
			result=box if first else result.merge(box);first=false
	return result

func target(world,p,body:RigidBody3D) -> Dictionary:
	var kind=world.definitions[p.holding].kind
	var sockets=world.manifest.assets[kind].get("anchors",{})
	var left=world.vec(sockets.grip_left);var right=world.vec(sockets.grip_right)
	var grip=(left+right)*.5
	var box=bounds(body)
	var basis=Basis(Vector3.UP,float(p.command.yaw))
	var forward=basis*Vector3.FORWARD
	var separation=maxf(.35,box.end.z)+.27+.08
	var origin=p.global_position+forward*separation+Vector3.UP*(p.eye().y-p.global_position.y-.42-grip.y)
	var wanted=Transform3D(basis,origin)
	var space=p.get_world_3d().direct_space_state
	var shape=BoxShape3D.new();shape.size=box.size
	var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.margin=.025
	query.exclude=[body.get_rid()];query.collision_mask=1|2|4
	query.transform=Transform3D(body.global_basis,body.global_transform*box.get_center())
	query.motion=wanted*box.get_center()-query.transform.origin
	var travel=space.cast_motion(query)
	var fraction=travel[0] if travel.size()>0 else 0.0
	var safe_origin=body.global_position+(origin-body.global_position)*fraction
	# Check the destination orientation too; sweeping translation alone misses chair backs.
	query.motion=Vector3.ZERO;query.transform=Transform3D(basis,Transform3D(basis,safe_origin)*box.get_center())
	var blocked=not space.intersect_shape(query,1).is_empty()
	var rotation=body.global_basis if blocked else basis
	if blocked:safe_origin=body.global_position
	var result={"position":safe_origin,"basis":rotation,"blocked":blocked or fraction<.999}
	traces[p.actor_id]={"objectId":p.holding,"volume":world.arr(box.size),"clearance":separation-box.end.z-.27,"fraction":fraction,"blocked":result.blocked,"left":world.arr(body.global_transform*left),"right":world.arr(body.global_transform*right)}
	return result
