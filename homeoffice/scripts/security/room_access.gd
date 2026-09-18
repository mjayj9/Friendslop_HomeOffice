extends RefCounted
## Room locks and ADMIN_ONLY courts are distinct. Only browser-verified short leases
## populate administrators; host identity, nicknames, saved files and open doors do not.
const ADMIN_ONLY=["basketball","football"]
var locks={}
var administrators={}
var policy_expires_at=0.0
var revision=-1

func apply_policy(policy:Dictionary):
	if int(policy.get("revision",-1))<revision:return
	revision=int(policy.get("revision",-1))
	locks=policy.get("locks",{}).duplicate(true)
	administrators=policy.get("administrators",{}).duplicate(true)
	policy_expires_at=float(policy.get("expiresAt",0))

func reset():
	locks.clear();administrators.clear();policy_expires_at=0;revision=-1

func is_administrator(actor:String) -> bool:
	var now=Time.get_unix_time_from_system()*1000.0
	return actor!="" and policy_expires_at>now and float(administrators.get(actor,0))>now

func blocks_entry(from_zone:String,to_zone:String,actor:String="") -> bool:
	if to_zone in ADMIN_ONLY:return not is_administrator(actor)
	return from_zone!=to_zone and bool(locks.get(to_zone,false)) and to_zone not in ["hall","upper_hall","personal-gallery","garden"]

func restricted_zone(world,point:Vector3,margin=0.0) -> String:
	# Extruded XZ volumes cover jumps, elevated spawns and restored positions.
	for room in world.layout.rooms:
		if room.id not in ADMIN_ONLY:continue
		var r=room.rect
		if point.x>=r[0]-margin and point.x<=r[2]+margin and point.z>=r[1]-margin and point.z<=r[3]+margin:return room.id
	return ""

func guard(world,player,before:Vector3):
	var restricted=restricted_zone(world,player.position,.28)
	var denied=restricted!="" and not is_administrator(player.actor_id)
	if denied:
		var safe=before if restricted_zone(world,before,.3)=="" else player.get_meta("last_public_position",world.vec(world.layout.spawn))
		if restricted_zone(world,safe,.3)!="":safe=world.vec(world.layout.spawn)
		if player.seated!="":world.clear_seat(player)
		if player.holding!="" and world.definitions.get(player.holding,{}).get("kind","") in ADMIN_ONLY:world.release(player,false)
		player.position=safe;player.velocity=Vector3.ZERO
	elif blocks_entry(world.zone_at(before),world.zone_at(player.position),player.actor_id):
		denied=true;player.position=before;player.velocity.x=0;player.velocity.z=0
	else:
		if restricted=="":player.set_meta("last_public_position",player.position)
		return
	if denied and Time.get_ticks_msec()>int(player.get_meta("lock_notice_until",0)):
		world.reject(player.actor_id,"농구·축구는 운영 관리자 전용입니다. 관리자 신원 확인이 필요합니다." if restricted!="" else "잠긴 방입니다. 관리자가 열면 입장할 수 있습니다.")
		player.set_meta("lock_notice_until",Time.get_ticks_msec()+2500)
