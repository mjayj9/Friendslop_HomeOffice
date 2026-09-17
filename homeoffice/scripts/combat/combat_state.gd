extends RefCounted
## Host-owned damage and scoring. Callers validate actors, ownership, cooldown and rays.
const MAX_HP=100
const DAMAGE=25
const RESPAWN_MS=3000
const PROTECTION_MS=2000
const COMBO_IDLE_MS=10000
const COMBO_DECAY_PER_SECOND=8.0
var fighters={}

func add(id:String):
	if not fighters.has(id):fighters[id]={"hp":MAX_HP,"kills":0,"deaths":0,"meter":0.0,"koUntil":0,"protectedUntil":0,"lastKill":0}

func reset():fighters.clear()

func alive(id:String) -> bool:
	return not fighters.has(id) or fighters[id].hp>0

func damage(attacker:String,victim:String,now:int) -> Dictionary:
	add(attacker);add(victim)
	var a=fighters[attacker];var v=fighters[victim]
	if attacker==victim or not alive(attacker) or not alive(victim) or now<v.protectedUntil:return {"accepted":false,"reason":"protected"}
	v.hp=maxi(0,v.hp-DAMAGE)
	var ko=v.hp==0
	if ko:
		v.deaths+=1;v.koUntil=now+RESPAWN_MS;v.meter=0
		a.kills+=1;a.meter=minf(100,a.meter+25);a.lastKill=now
	return {"accepted":true,"ko":ko,"hp":v.hp,"attacker":attacker,"victim":victim}

func advance(now:int,dt:float) -> Array:
	var respawns=[]
	for id in fighters:
		var s=fighters[id]
		if s.hp==0 and now>=s.koUntil:
			s.hp=MAX_HP;s.koUntil=0;s.protectedUntil=now+PROTECTION_MS;respawns.append(id)
		if now-s.lastKill>COMBO_IDLE_MS:s.meter=maxf(0,s.meter-COMBO_DECAY_PER_SECOND*dt)
	return respawns

func snapshot(now:int) -> Dictionary:
	var out={}
	for id in fighters:
		var s=fighters[id]
		out[id]={"hp":s.hp,"maxHp":MAX_HP,"kills":s.kills,"deaths":s.deaths,"meter":s.meter,"respawnMs":maxi(0,s.koUntil-now),"protectedMs":maxi(0,s.protectedUntil-now),"meterIdleMs":maxi(0,COMBO_IDLE_MS-(now-s.lastKill))}
	return out

func restore(view:Dictionary,now:int):
	fighters.clear()
	for id in view:
		var s=view[id]
		add(id)
		fighters[id]={"hp":int(s.hp),"kills":int(s.kills),"deaths":int(s.deaths),"meter":float(s.meter),"koUntil":now+int(s.respawnMs) if int(s.hp)==0 else 0,"protectedUntil":now+int(s.protectedMs),"lastKill":now-COMBO_IDLE_MS+int(s.get("meterIdleMs",0))}
