extends RefCounted
## Model-space contacts. The retained 13-bone sit clip has Hips at Y=.44.
## This contract does not claim body-shape fitting or finger contact.
const SIT_HIPS=Vector3(0,.44,0)

func slots(world,kind:String) -> Array:
	return world.manifest.assets.get(kind,{}).get("seatContacts",[])

func contact(world,item,index:int) -> Dictionary:
	var entries=slots(world,String(item.get_meta("kind","")))
	return entries[index] if index>=0 and index<entries.size() else {}

func origin(world,item,index:int) -> Vector3:
	var spec=contact(world,item,index)
	return item.global_transform*(world.vec(spec.pelvis)-SIT_HIPS) if not spec.is_empty() else item.position

func select_slot(world,item,p) -> int:
	var entries=slots(world,String(item.get_meta("kind","")))
	if entries.is_empty():return -1
	var local=item.to_local(p.position)
	# Approach from the front. Looking through the back cannot teleport into a seat.
	if local.z>-.48:return -1
	var chosen=-1;var nearest=100.0
	for i in entries.size():
		var d=absf(local.x-float(entries[i].pelvis[0]))
		if d<nearest:chosen=i;nearest=d
	if chosen<0 or item.get_meta("seats",{}).has(str(chosen)):return -1
	var goal=item.global_transform*world.vec(entries[chosen].approach)
	if p.position.distance_to(goal)>1.6:return -1
	var query=PhysicsShapeQueryParameters3D.new();var shape=CapsuleShape3D.new()
	shape.radius=.27;shape.height=1.75;query.shape=shape
	query.transform.origin=p.position+Vector3.UP*.9;query.motion=goal-p.position
	query.collision_mask=1|2|4;query.exclude=[p.get_rid()]
	var cast=world.get_world_3d().direct_space_state.cast_motion(query)
	if cast.size()>0 and cast[0]<.98:return -1
	# Check the occupied upper body without turning off furniture collision.
	shape=CapsuleShape3D.new();shape.radius=.27;shape.height=.9;query.shape=shape
	query.transform.origin=origin(world,item,chosen)+Vector3.UP*.97;query.motion=Vector3.ZERO
	if not world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return -1
	return chosen

func exits(world,item,index:int) -> Array:
	var spec=contact(world,item,index)
	return spec.get("exits",[])
