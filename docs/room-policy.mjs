export const ROOM_LABELS={living:'거실',dining:'식당',kitchen:'주방',pantry:'팬트리',meeting:'회의실',resources:'자료·토론',free:'자유 작업방',utility:'방송·다용도실',bath_ground:'1층 욕실',sleep:'수면실',reading:'독서실',bath_upper:'2층 욕실',game:'사격 공간',arcade:'공룡 러너',basketball:'농구장',football:'축구장',...Object.fromEntries(Array.from({length:8},(_,i)=>[`office-${i+1}`,`개인실 ${i+1}`]))};
const bytes=value=>Uint8Array.from(atob(value.replace(/-/g,'+').replace(/_/g,'/')),c=>c.charCodeAt(0));
export function createPolicyVerifier({publicKey,clock=Date.now}){
 let key,revision=-1,session='',latest=null;
 return {reset(){revision=-1;session='';latest=null;},current:()=>latest,
  async accept(envelope,{expectedSession,challenge}){
   if(!envelope||typeof envelope.payload!=='string'||envelope.payload.length>18000||typeof envelope.signature!=='string'||envelope.signature.length>100)throw Error('관리 서명 형식 오류');
   key??=await crypto.subtle.importKey('jwk',publicKey,{name:'ECDSA',namedCurve:'P-256'},false,['verify']);
   if(!await crypto.subtle.verify({name:'ECDSA',hash:'SHA-256'},key,bytes(envelope.signature),new TextEncoder().encode(envelope.payload)))throw Error('관리 서명이 유효하지 않습니다.');
   const p=JSON.parse(new TextDecoder().decode(bytes(envelope.payload))),at=clock();
   if(p.v!==1||p.kind!=='room-policy'||p.session!==expectedSession||p.challenge!==challenge||!Number.isSafeInteger(p.revision)||p.revision<0||!Number.isFinite(p.issuedAt)||!Number.isFinite(p.expiresAt)||p.issuedAt>at+5000||p.expiresAt<=at||p.expiresAt-p.issuedAt>30000)throw Error('만료되었거나 다른 세션의 관리 응답입니다.');
   if(session===p.session&&p.revision<revision)throw Error('이전 관리 정책은 적용할 수 없습니다.');
   if(!p.rooms||Object.keys(p.rooms).length!==Object.keys(ROOM_LABELS).length||Object.keys(p.rooms).some(zone=>!ROOM_LABELS[zone]||typeof p.rooms[zone]?.locked!=='boolean'||typeof p.rooms[zone]?.configured!=='boolean'))throw Error('방별 정책 형식 오류');
   if(!p.broadcasters||Object.entries(p.broadcasters).some(([id,expiry])=>!/^[A-Za-z0-9_-]{1,100}$/.test(id)||!Number.isFinite(expiry)||expiry>p.issuedAt+10*60000))throw Error('방송 관리자 임대 형식 오류');
   if(p.administrators!==undefined&&(!p.administrators||typeof p.administrators!=='object'||Array.isArray(p.administrators)||Object.keys(p.administrators).length>8||Object.entries(p.administrators).some(([id,expiry])=>!/^[A-Za-z0-9_-]{1,100}$/.test(id)||!Number.isFinite(expiry)||expiry>p.issuedAt+30000)))throw Error('관리자 참가자 임대 형식 오류');
   session=p.session;revision=p.revision;latest=p;return p;
  }
 };
}
