extends RefCounted
## Receives only policies verified by the browser against the pinned service public key.
## Host simulation is not a confidential server. Locks control entry, not document secrecy.
var locks={}
var revision=-1
func apply_policy(policy:Dictionary):
	if int(policy.get("revision",-1))<revision:return
	revision=int(policy.get("revision",-1));locks=policy.get("locks",{}).duplicate(true)
func reset():
	locks.clear();revision=-1
func blocks_entry(from_zone:String,to_zone:String) -> bool:
	return from_zone!=to_zone and bool(locks.get(to_zone,false)) and to_zone not in ["hall","upper_hall","personal-gallery","garden"]
func guard(world,player,before:Vector3):
	if blocks_entry(world.zone_at(before),world.zone_at(player.position)):
		player.position=before;player.velocity.x=0;player.velocity.z=0
		if Time.get_ticks_msec()>int(player.get_meta("lock_notice_until",0)):
			world.reject(player.actor_id,"잠긴 방입니다. 관리자가 열면 누구나 들어갈 수 있습니다.")
			player.set_meta("lock_notice_until",Time.get_ticks_msec()+2500)
