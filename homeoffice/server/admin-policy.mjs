import {randomBytes,randomUUID,scrypt as derive,timingSafeEqual,sign} from 'node:crypto';
import {promisify} from 'node:util';
const scrypt=promisify(derive),keyOptions={N:32768,r:8,p:1,maxmem:64*1024*1024};
export const ROOM_IDS=['living','dining','kitchen','pantry','meeting','resources','free','utility','bath_ground','sleep','reading','bath_upper','game','arcade','basketball','football',...Array.from({length:8},(_,i)=>`office-${i+1}`)];
const validSession=s=>typeof s==='string'&&/^[A-Za-z0-9_-]{8,100}$/.test(s);
export class PolicyError extends Error{constructor(status,message){super(message);this.status=status;}}
function insist(ok,status,message){if(!ok)throw new PolicyError(status,message);}
export async function hashPin(pin){insist(typeof pin==='string'&&/^\d{4,12}$/.test(pin),400,'PIN은 숫자 4~12자리입니다.');const salt=randomBytes(16);return {salt:salt.toString('base64'),hash:Buffer.from(await scrypt(pin,salt,32,keyOptions)).toString('base64')};}
async function matches(pin,record){if(typeof pin!=='string'||!/^\d{4,12}$/.test(pin)||!record)return false;return timingSafeEqual(Buffer.from(await scrypt(pin,Buffer.from(record.salt,'base64'),32,keyOptions)),Buffer.from(record.hash,'base64'));}
// Memory adapter is only for tests. The server entry point supplies an atomic private disk adapter.
export function memoryStore(){let state={rooms:{},sessions:{}};return {read:async()=>structuredClone(state),write:async value=>{state=structuredClone(value);}};}
export function createAdminPolicy({verifyIdentity,adminIds,privateKey,store,now=Date.now}){
 let serial=Promise.resolve();const attempts=new Map();
 const exclusive=fn=>{const job=serial.then(fn,fn);serial=job.catch(()=>{});return job;};
 function envelope(payload){const encoded=Buffer.from(JSON.stringify(payload)).toString('base64url');return {payload:encoded,signature:sign('sha256',Buffer.from(encoded),{key:privateKey,dsaEncoding:'ieee-p1363'}).toString('base64url')};}
 function view(data,session,challenge){const current=data.sessions[session]||{revision:0,locks:{},broadcasters:{}};return envelope({v:1,kind:'room-policy',session,challenge,issuedAt:now(),expiresAt:now()+30000,revision:current.revision,rooms:Object.fromEntries(ROOM_IDS.map(zone=>[zone,{locked:!!current.locks[zone],configured:!!data.rooms[zone]}])),broadcasters:Object.fromEntries(Object.entries(current.broadcasters).filter(([,expires])=>expires>now())),administrators:Object.fromEntries(Object.entries(current.administrators||{}).filter(([,lease])=>lease.expiresAt>now()).map(([actor,lease])=>[actor,lease.expiresAt]))});}
 function validateContext(session,challenge){insist(validSession(session),400,'세션 형식 오류');insist(typeof challenge==='string'&&/^[A-Za-z0-9_-]{16,100}$/.test(challenge),400,'요청 nonce 형식 오류');}
 async function identity(token){let user;try{user=await verifyIdentity(token);}catch{throw new PolicyError(401,'로그인이 필요합니다.');}insist(user?.id&&adminIds.has(user.id),403,'등록된 운영 관리자 계정이 필요합니다.');return user;}
 function rate(uid){const at=now();for(const[key,value]of attempts)if(at-value.at>900000)attempts.delete(key);const current=attempts.get(uid)||{at,count:0};if(at-current.at>900000){current.at=at;current.count=0;}insist(current.count<5,429,'PIN 시도 제한입니다. 15분 후 다시 시도하세요.');current.count++;attempts.set(uid,current);}
 return {
  bootstrap:pin=>exclusive(async()=>{const data=await store.read();for(const zone of ROOM_IDS)if(!data.rooms[zone])data.rooms[zone]=await hashPin(pin);await store.write(data);}),
  state:async({session,challenge})=>{validateContext(session,challenge);return view(await store.read(),session,challenge);},
  command:async({token,session,challenge,zone,operation,pin,newPin,revision,actor})=>{
   validateContext(session,challenge);const user=await identity(token);
   insist(ROOM_IDS.includes(zone),400,'이 공간은 잠글 수 없습니다.');insist(['lock','unlock','keep-open','set-pin','broadcast-authorize','broadcast-revoke'].includes(operation),400,'지원하지 않는 관리 동작');
   insist(Number.isSafeInteger(revision)&&revision>=0,400,'정책 버전 오류');
   return exclusive(async()=>{
    rate(user.id);const data=await store.read(),current=data.sessions[session]||{revision:0,locks:{},broadcasters:{},nonces:[]};
    insist(current.revision===revision,409,'다른 관리 변경이 있습니다. 새 상태를 확인하세요.');insist(!current.nonces.includes(challenge),409,'이미 처리된 요청입니다.');
    insist(await matches(pin,data.rooms[zone]),403,'PIN이 일치하지 않습니다.');
    if(operation==='set-pin')data.rooms[zone]=await hashPin(newPin);
    else if(operation.startsWith('broadcast-')){insist(zone==='utility'&&typeof actor==='string'&&/^[A-Za-z0-9_-]{1,100}$/.test(actor),400,'방송실/참가자 정보 오류');if(operation==='broadcast-authorize')current.broadcasters[actor]=now()+10*60000;else delete current.broadcasters[actor];}
    else current.locks[zone]=operation==='lock';
    current.revision++;current.nonces=[...current.nonces.slice(-127),challenge];data.sessions[session]=current;
    // Bound memory/disk growth without silently evicting active policies.
    insist(Object.keys(data.sessions).length<=512,503,'관리 서비스 세션 보관 한도입니다. 운영자 정리가 필요합니다.');
    await store.write(data);attempts.delete(user.id);return view(data,session,challenge);
   });
  },
  bindActor:async({token,session,challenge,actor})=>{
   validateContext(session,challenge);const user=await identity(token);
   insist(typeof actor==='string'&&/^[A-Za-z0-9_-]{1,100}$/.test(actor),400,'참가자 ID 형식 오류');
   return exclusive(async()=>{const data=await store.read(),current=data.sessions[session]||{revision:0,locks:{},broadcasters:{},nonces:[]};
    current.administrators=Object.fromEntries(Object.entries(current.administrators||{}).filter(([,v])=>v.expiresAt>now()));
    const prior=current.administrators[actor];insist(!prior||prior.uid===user.id,409,'다른 계정에 연결된 참가자입니다.');
    insist(Object.keys(current.administrators).length<8||prior,409,'관리 참가자 한도입니다.');
    current.administrators[actor]={uid:user.id,expiresAt:now()+30000};current.revision++;data.sessions[session]=current;
    insist(Object.keys(data.sessions).length<=512,503,'관리 세션 한도입니다.');await store.write(data);return view(data,session,challenge);
   });
  },
  identify:async token=>{await identity(token);return {administrator:true};}
 };
}
