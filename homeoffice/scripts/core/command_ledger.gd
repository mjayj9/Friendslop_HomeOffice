extends RefCounted
## Epoch-scoped idempotency. Identity comes from the transport, never from payload authority.
var replies={}
const LIMIT=128

func inspect(actor:String,m:Dictionary,epoch:String) -> Dictionary:
	if m.get("actor")!=actor or m.get("epoch")!=epoch:return {"valid":false,"reason":"세션 또는 사용자 정보가 다릅니다."}
	var key=m.get("requestId")
	if not key is String or key.length()<1 or key.length()>100:return {"valid":false,"reason":"요청 ID 형식이 올바르지 않습니다."}
	if not m.get("seq") is int and not m.get("seq") is float:return {"valid":false,"reason":"요청 순서가 없습니다."}
	if not is_finite(float(m.seq)) or float(m.seq)<0 or float(m.seq)>1e12 or float(m.seq)!=floorf(float(m.seq)):return {"valid":false,"reason":"요청 순서가 올바르지 않습니다."}
	if not m.get("targetId","") is String or String(m.get("targetId","")).length()>100 or not m.get("data",{}) is Dictionary:return {"valid":false,"reason":"대상 또는 입력 형식이 올바르지 않습니다."}
	if JSON.stringify(m.get("data",{})).length()>16384:return {"valid":false,"reason":"명령 데이터가 너무 큽니다."}
	var bucket=replies.get(epoch+"|"+actor,{})
	return {"valid":true,"cached":bucket.get(key,{})}

func remember(actor:String,epoch:String,key:String,result:Dictionary):
	var bucket=replies.get(epoch+"|"+actor,{})
	bucket[key]=result.duplicate(true)
	while bucket.size()>LIMIT:bucket.erase(bucket.keys()[0])
	replies[epoch+"|"+actor]=bucket

func clear():replies.clear()
