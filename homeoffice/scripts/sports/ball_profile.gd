extends RefCounted
## Metres/kg. Initial gameplay calibration, not a certified sports simulation.
const BASKETBALL_RADIUS=.12
const FOOTBALL_RADIUS=.11
const RIM_INNER_RADIUS=.225

static func radius(kind:String) -> float:
	return BASKETBALL_RADIUS if kind=="basketball" else FOOTBALL_RADIUS

static func configure(body:RigidBody3D,kind:String):
	body.mass=.62 if kind=="basketball" else .43
	body.continuous_cd=true
	body.linear_damp=.08
	body.angular_damp=.15
	var material=PhysicsMaterial.new()
	material.friction=.68
	material.bounce=.72 if kind=="basketball" else .48
	body.physics_material_override=material

static func shot(direction:Vector3,charge:float) -> Vector3:
	var flat=Vector3(direction.x,0,direction.z).normalized()
	var angle=clampf(atan2(direction.y,Vector2(direction.x,direction.z).length()),.35,1.15)
	var speed=lerpf(5.5,10.8,clampf(charge,0,1))
	return (flat*cos(angle)+Vector3.UP*sin(angle))*speed

static func basket_crossing(previous:Vector3,current:Vector3,centre:Vector3) -> bool:
	if previous.y<=centre.y or current.y>centre.y:return false
	var at=previous.lerp(current,(centre.y-previous.y)/(current.y-previous.y))
	return Vector2(at.x-centre.x,at.z-centre.z).length()<=RIM_INNER_RADIUS-BASKETBALL_RADIUS
