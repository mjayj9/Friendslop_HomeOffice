extends RefCounted
## Simplified two-team play: blue attacks +X, orange attacks -X. Every basket is 2 points.
var teams={"basketball":{},"football":{},"tag":{}}
var ball_states={}
func assign(game:String,ids:Array):
	teams[game]={}
	for i in ids.size():teams[game][ids[i]]=i%2
func team(game:String,id:String) -> int:return int(teams.get(game,{}).get(id,-1))
func register_ball(id:String,kind:String):
	ball_states[id]={"state":"LOOSE_BALL","kind":kind,"matchBall":id==kind,"lastTouch":""}
func transition(id:String,state:String,toucher=""):
	if not ball_states.has(id):return
	ball_states[id].state=state
	if toucher!="":ball_states[id].lastTouch=toucher
func snapshot() -> Dictionary:return {"teams":teams.duplicate(true),"balls":ball_states.duplicate(true),"rules":"청팀은 +X 골대, 주황팀은 -X 골대를 공격합니다. 농구는 모두 2점, 축구는 1점. 자유 연습에는 팀 제한이 없습니다."}
func restore(value:Dictionary):
	teams=value.get("teams",{"basketball":{},"football":{},"tag":{}}).duplicate(true)
	ball_states=value.get("balls",{}).duplicate(true)
